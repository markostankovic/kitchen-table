-- Migration 21 -- recipe_tag_names (Phase 6, part 1a).
--
-- A tag typed in one language, resolved in the reader's own language. Copies
-- ingredient_names' shape (D1: aliases and translations in one table, keyed
-- on the normalized string), not recipe_translations' -- this is vocabulary
-- translation, not prose translation.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- recipes.tags is text[] with no id per tag, so this table keys on tag_key,
-- the normalized ORIGINAL spelling -- exactly what RecipeTag.key already is
-- and exactly what RecipeRepository._filtered already compares against. A
-- reader taps a chip labelled in their own language whose key is still the
-- original normalized string, so filtering keeps matching across both
-- spellings without _filtered ever changing.
--
-- This slice (1a) only ships the table, its RLS and the read path. 1b adds a
-- dedicated translate-tags Edge Function that writes rows with source =
-- 'llm'; the insert/update policies below exist for it now so 1b costs no
-- second migration.

create table recipe_tag_names (
  id uuid primary key default gen_random_uuid(),
  tag_key text not null,
  name text not null,
  -- Generated and indexed although nothing in 1a reads it. Deliberate, not
  -- drift: Phase 6 part 2's done-when is "typing a tag's name narrows the
  -- list", which has to match the translated spelling too, and migrations
  -- are append-only -- adding this column later would be a second migration
  -- for something already known to be needed.
  normalized_name text generated always as (normalize_text(name)) stored,
  locale text not null check (locale in ('sr','en')),
  household_id uuid references households(id) on delete cascade, -- null = global
  source text not null check (source in ('curated','llm','user')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

comment on table recipe_tag_names is
  'One spelling of one tag in one locale. tag_key is the normalized original '
  'spelling (RecipeTag.key); resolution looks up (tag_key, locale) and falls '
  'back to the as-typed label on a miss. household_id null = global.';

create trigger recipe_tag_names_set_updated_at
  before update on recipe_tag_names
  for each row execute function set_updated_at();

-- Deliberately TOTAL -- no `where deleted_at is null`, on ingredient_names_
-- unique's own reasoning: one string means one thing per locale and scope,
-- forever, so rewriting a retired pair resurrects the row rather than
-- creating a second. The coalesce is how a nullable household_id
-- participates in a unique index at all: NULLs are distinct to Postgres, so
-- without it every global row would be unique against every other and the
-- constraint would do nothing.
create unique index recipe_tag_names_unique
  on recipe_tag_names (
    tag_key,
    locale,
    coalesce(household_id, '00000000-0000-0000-0000-000000000000'::uuid)
  );

create index recipe_tag_names_household_id_idx
  on recipe_tag_names (household_id);

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
-- Global rows are visible to everyone; a household's own pairs only to its
-- members -- ingredient_names_select verbatim. Insert and update are
-- household rows only: nothing writes a global row from a client. These two
-- write policies exist for 1b's translate-tags Edge Function, which goes
-- through the caller's client precisely so RLS is what decides.

alter table recipe_tag_names enable row level security;

create policy recipe_tag_names_select on recipe_tag_names for select
  to authenticated
  using (household_id is null or is_household_member(household_id));

create policy recipe_tag_names_insert on recipe_tag_names for insert
  to authenticated
  with check (is_household_member(household_id));

create policy recipe_tag_names_update on recipe_tag_names for update
  to authenticated
  using (is_household_member(household_id))
  with check (is_household_member(household_id));
