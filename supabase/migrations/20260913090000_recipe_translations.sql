-- Migration 17 -- recipe_translations (Phase 3, part 2).
--
-- Every other locale of a recipe's title, description and steps.
-- `recipes` and `recipe_steps` have named this table since migration 8 and
-- never had one: this is what closes that forward reference. Ingredient
-- lines are never translated per recipe -- they render from the bilingual
-- catalog at read time, which is the whole point of D1 -- so this table has
-- no ingredient shape at all.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D78 (a child table in the D24 sense that
-- nonetheless keeps created_at/updated_at, and the touch trigger that hands
-- it to the existing recipe delta fetch).

-- ---------------------------------------------------------------------------
-- recipe_translations
-- ---------------------------------------------------------------------------
-- No household_id, so D24 governs and rule 4's "no hard deletes" does not
-- reach this table: it cascades with its recipe, and a soft-deleted recipe's
-- translations are already unreachable. There is deliberately no
-- deleted_at -- a translation is regenerable from the original at any time,
-- so removing one is a hard delete, the same call recipe_ingredients and
-- recipe_steps made, and it gets a DELETE policy for the same reason.
--
-- Unlike those two child tables, this one DOES keep created_at and
-- updated_at. A recipe_step has no life after it is written; a translation
-- does -- part 3's review flow reads and stamps it, and a re-translation
-- overwrites the same row in place rather than being deleted and
-- re-inserted. docs/DATA_MODEL.md's original sketch already gave it both
-- columns without saying why; this comment is that reasoning, the same
-- correction D49 and D59 each wrote out in prose for their own tables.

create table recipe_translations (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references recipes(id) on delete cascade,
  locale text not null check (locale in ('sr','en')),
  title text not null check (length(trim(title)) > 0),
  description text,
  -- [{position, text}], on recipe_steps's own shape rather than a child
  -- table of its own -- a translation is produced and replaced as one whole
  -- document by save_recipe_translation below, never edited line by line
  -- from the client (part 3's review flow edits this jsonb in place).
  steps jsonb not null default '[]',
  -- Anything AI-produced stays 'draft' -- or here, unreviewed -- until a
  -- human marks it tested (docs/ROADMAP.md, standing rules). reviewed_by and
  -- reviewed_at are written by nothing in this part: part 3's review flow is
  -- what sets them, on save_recipe_translation's own precedent of shipping a
  -- column ahead of its writer (D35, D51).
  is_machine_generated boolean not null default true,
  reviewed_by uuid references profiles(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Total, not partial: there is no deleted_at to qualify it against, and one
  -- recipe has at most one row per locale, live or not -- there is no "not
  -- live" state for this row to be in.
  unique (recipe_id, locale)
);

create trigger recipe_translations_set_updated_at
  before update on recipe_translations
  for each row execute function set_updated_at();

-- No separate index on recipe_id: the unique constraint above already leads
-- with it, meal_plans's own reasoning for week_start.

comment on table recipe_translations is
  'Every locale of a recipe other than its original (recipes.original_locale). '
  'A child table in the D24 sense -- no household_id, no deleted_at, hard '
  'delete allowed -- but keeps created_at/updated_at because a translation, '
  'unlike a step, is reviewed and re-generated in place (D78).';

-- ---------------------------------------------------------------------------
-- recipe_translations_touch_recipe
-- ---------------------------------------------------------------------------
-- security invoker is correct and safe, on meal_plan_entries_touch_plan's own
-- argument: the child's own insert/update/delete policies and the parent's
-- update policy all reduce to the same is_household_member(household_id), so
-- this trigger holds no privilege the caller does not already have.
--
-- This is the load-bearing piece for offline: RemoteRecipeDataSource's delta
-- fetch reads recipes where updated_at > watermark, and recipe_dto.dart caches
-- the whole PostgREST row -- translations embedded and all -- verbatim. Without
-- this trigger, translating a recipe would leave its own updated_at untouched
-- and the change would never reach a device's cache.

create or replace function recipe_translations_touch_recipe()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  update recipes
  set updated_at = now()
  where id = coalesce(new.recipe_id, old.recipe_id);
  return coalesce(new, old);
end;
$$;

comment on function recipe_translations_touch_recipe() is
  'Touches the parent recipe''s updated_at on any translation insert, update '
  'or delete, so a recipe whose translation changed does not look untouched '
  'to the Phase 2 delta fetch (mirrors meal_plan_entries_touch_plan).';

create trigger recipe_translations_touch_recipe
  after insert or update or delete on recipe_translations
  for each row execute function recipe_translations_touch_recipe();

-- ---------------------------------------------------------------------------
-- save_recipe_translation
-- ---------------------------------------------------------------------------
-- The upsert-and-validate step translate-recipe needs, on
-- replace_recipe_lines's and save_shopping_list's own precedent: security
-- invoker, so this holds no privilege the caller does not already have under
-- RLS, and the function exists for atomicity and validation, not authority.
--
-- Parameters are `recipe` and `loc`, never `recipe_id` or `locale`: both are
-- column names on this table, and a plpgsql parameter sharing a name with a
-- column in the same statement is an ambiguity error (D30, learned the hard
-- way in merge_ingredients). The remaining parameters are prefixed `new_`
-- for the same reason.

create or replace function save_recipe_translation(
  recipe          uuid,
  loc             text,
  new_title       text,
  new_description text,
  new_steps       jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  translation_id uuid;
  source_locale  text;
begin
  -- Fail loudly rather than silently writing nothing, replace_recipe_lines's
  -- own guard: without this, a caller who cannot see the recipe gets a
  -- successful no-op instead of a refusal.
  select r.original_locale into source_locale
  from recipes r
  where r.id = recipe;

  if source_locale is null then
    raise exception 'recipe not found or not visible' using errcode = '42501';
  end if;

  if loc not in ('sr', 'en') then
    raise exception 'locale must be sr or en' using errcode = '22023';
  end if;

  -- Translating a recipe into the language it is already written in is the
  -- nearest thing this schema has to a second recipe row, which the Phase 3
  -- Done-when rules out by name.
  if loc = source_locale then
    raise exception 'locale matches the recipe''s own original_locale'
      using errcode = '22023';
  end if;

  -- do update, not do nothing: `do nothing returning id` returns no row on
  -- conflict, which here is the common case (re-translating an existing
  -- locale) -- the same trap ensure_meal_plan's own comment names. Clearing
  -- the review columns on a re-translation is correct: the new prose has not
  -- been seen by anyone yet, machine-generated exactly like a first pass.
  insert into recipe_translations (
    recipe_id, locale, title, description, steps,
    is_machine_generated, reviewed_by, reviewed_at
  )
  values (recipe, loc, new_title, new_description, new_steps, true, null, null)
  on conflict (recipe_id, locale) do update
    set title = excluded.title,
        description = excluded.description,
        steps = excluded.steps,
        is_machine_generated = true,
        reviewed_by = null,
        reviewed_at = null
  returning id into translation_id;

  return translation_id;
end;
$$;

comment on function save_recipe_translation(uuid, text, text, text, jsonb) is
  'Upserts one locale of a recipe''s translation, refusing an unknown locale '
  'or the recipe''s own original_locale. security invoker -- RLS still '
  'decides who may write.';

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
-- Membership only, through the parent recipe, with no deleted_at clause
-- anywhere (D23) -- there is none on this table to begin with. Copied
-- verbatim from recipe_steps's own four policies (migration 8): same shape,
-- same parent, same reasoning.

alter table recipe_translations enable row level security;

create policy recipe_translations_select on recipe_translations for select
  using (exists (select 1 from recipes r
                 where r.id = recipe_translations.recipe_id
                   and is_household_member(r.household_id)));
create policy recipe_translations_insert on recipe_translations for insert
  with check (exists (select 1 from recipes r
                      where r.id = recipe_translations.recipe_id
                        and is_household_member(r.household_id)));
create policy recipe_translations_update on recipe_translations for update
  using (exists (select 1 from recipes r
                 where r.id = recipe_translations.recipe_id
                   and is_household_member(r.household_id)))
  with check (exists (select 1 from recipes r
                      where r.id = recipe_translations.recipe_id
                        and is_household_member(r.household_id)));
create policy recipe_translations_delete on recipe_translations for delete
  using (exists (select 1 from recipes r
                 where r.id = recipe_translations.recipe_id
                   and is_household_member(r.household_id)));

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
-- anon named explicitly -- Supabase's default privileges grant it EXECUTE
-- unless it is named, the lesson merge_ingredients and save_imported_recipe
-- both record (D30).

revoke execute on function
  save_recipe_translation(uuid, text, text, text, jsonb) from public, anon;
grant execute on function
  save_recipe_translation(uuid, text, text, text, jsonb)
  to authenticated, service_role;
