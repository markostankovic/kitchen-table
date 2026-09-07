-- Migration 8 -- recipes, their ingredient lines and their steps
-- (Phase 1c, first slice).
--
-- The first tables in this project that hold what the product is actually for.
-- They also switch on two things Phase 1b built but could not exercise:
-- search_ingredients finally has a caller, and merge_ingredients' repoint step
-- -- guarded by to_regclass because recipe_ingredients did not exist -- starts
-- doing work. supabase/tests/merge_ingredients_test.sql already lists
-- recipe_ingredients in its `known` array for exactly this moment.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D35 (photo upload moves to Phase 2, but
-- image_path ships now), D36 (replace_recipe_lines).

-- ---------------------------------------------------------------------------
-- recipes
-- ---------------------------------------------------------------------------
-- Household-scoped in the D24 sense -- it carries a household_id -- so it gets
-- the full rule 4 treatment: updated_at with a trigger, deleted_at, no hard
-- deletes.
--
-- This table holds the ORIGINAL language only. Every other locale lives in
-- recipe_translations (Phase 3), and ingredient lines are never translated per
-- recipe -- they render from the catalog, which is the whole point of D1.

create table recipes (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  title text not null check (length(trim(title)) > 0),
  -- The third instance of the stored-generated-column pattern, after
  -- unit_names.normalized_name and ingredient_names.normalized_name. Migration
  -- 1's header names this column specifically: replacing normalize_text()
  -- without rebuilding this column leaves the search index silently stale.
  title_normalized text generated always as (normalize_text(title)) stored,
  description text,
  servings int check (servings is null or servings > 0),
  prep_minutes int check (prep_minutes is null or prep_minutes >= 0),
  cook_minutes int check (cook_minutes is null or cook_minutes >= 0),
  original_locale text not null check (original_locale in ('sr','en')),
  source_type text not null
    check (source_type in ('manual','url_import','ocr','ai_generated')),
  source_url text,
  source_attribution text,
  -- Anything AI-produced stays 'draft' until a human marks it tested
  -- (docs/ROADMAP.md, standing rules). Manual entry may start either way.
  status text not null default 'draft' check (status in ('draft','tested')),
  -- One value, deliberately (D16): imported cookbook and web content is
  -- permanently household-scoped and there is no public path. The column and
  -- its check exist so that adding one later is a migration with a name,
  -- rather than a semantic change to rows that never declared their intent.
  visibility text not null default 'household'
    check (visibility in ('household')),
  -- A Supabase Storage object path. The bucket, the policies and the picker
  -- are Phase 2 (D35) -- the column ships now so that slice is a feature and
  -- not a migration against existing rows.
  image_path text,
  tags text[] not null default '{}',
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create trigger recipes_set_updated_at
  before update on recipes
  for each row execute function set_updated_at();

-- Trigram, not btree: the recipe list searches with ilike '%term%', and a
-- leading wildcard makes a btree index useless. pg_trgm is already installed
-- (migration 1) for exactly this class of query.
create index recipes_title_normalized_idx
  on recipes using gin (title_normalized gin_trgm_ops);

create index recipes_household_id_idx on recipes (household_id);

comment on table recipes is
  'A recipe in its original language. Other locales live in '
  'recipe_translations (Phase 3); ingredient lines are never translated per '
  'recipe -- they render from the catalog (D1).';

-- ---------------------------------------------------------------------------
-- recipe_ingredients
-- ---------------------------------------------------------------------------
-- CLAUDE.md rule 3 is enforced here and not by convention: raw_text is NOT
-- NULL, always. Every structured column beside it is nullable, because a
-- failed parse or an unmatched ingredient is a supported state, not a bug --
-- the line still renders, exactly as the cook wrote it.
--
-- No deleted_at and no updated_at, per D24: no household_id, so rule 4 does
-- not reach this table. It cascades with its recipe, and a soft-deleted
-- recipe's lines are already unreachable.

create table recipe_ingredients (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references recipes(id) on delete cascade,
  position int not null,
  section text,
  -- HARD RULE (CLAUDE.md rule 3). Structured fields are an enhancement on top
  -- of this string, never a replacement for it.
  raw_text text not null check (length(trim(raw_text)) > 0),
  -- Nullable, and named exactly this. merge_ingredients() repoints it with a
  -- dynamic `update %I set ingredient_id = $1 where ingredient_id = $2`, and
  -- merge_ingredients_test.sql fails any table that references ingredients(id)
  -- without being handled there. Null means "not matched", which is normal.
  ingredient_id uuid references ingredients(id),
  -- Integer fractions, never floats (rule 5). 1 1/2 is (3, 2), not 1.5.
  qty_num int,
  qty_den int check (qty_den is null or qty_den > 0),
  -- Ranges: `2-3 kašike` fills the max pair as well.
  qty_max_num int,
  qty_max_den int check (qty_max_den is null or qty_max_den > 0),
  unit_code text references units(code),
  note text,
  is_optional boolean not null default false,
  -- Match provenance (D7). This is the genuinely expensive-to-retrofit thing:
  -- without it, an improved matcher can never be re-run over old rows, because
  -- a human decision is indistinguishable from an old machine guess.
  match_method text
    check (match_method in ('exact','alias','fuzzy','llm','manual')),
  match_confidence numeric,
  matched_at timestamptz,
  -- A quantity is either absent or has both halves. A numerator with no
  -- denominator is not a fraction, it is a bug that renders as a number.
  constraint recipe_ingredients_qty_pair
    check ((qty_num is null) = (qty_den is null)),
  constraint recipe_ingredients_qty_max_pair
    check ((qty_max_num is null) = (qty_max_den is null)),
  -- A range needs a lower bound to be a range.
  constraint recipe_ingredients_qty_max_needs_qty
    check (qty_max_num is null or qty_num is not null)
);

create index recipe_ingredients_recipe_id_position_idx
  on recipe_ingredients (recipe_id, position);

create index recipe_ingredients_ingredient_id_idx
  on recipe_ingredients (ingredient_id);

comment on table recipe_ingredients is
  'One line of a recipe''s ingredient list. raw_text is NOT NULL always '
  '(CLAUDE.md rule 3); everything structured beside it is an enhancement and '
  'may be null. Quantities are integer fractions (rule 5).';

-- ---------------------------------------------------------------------------
-- recipe_steps
-- ---------------------------------------------------------------------------

create table recipe_steps (
  id uuid primary key default gen_random_uuid(),
  recipe_id uuid not null references recipes(id) on delete cascade,
  position int not null,
  text text not null check (length(trim(text)) > 0),
  timer_seconds int check (timer_seconds is null or timer_seconds > 0)
);

create index recipe_steps_recipe_id_position_idx
  on recipe_steps (recipe_id, position);

comment on table recipe_steps is
  'Ordered preparation steps, in the recipe''s original language.';

-- ---------------------------------------------------------------------------
-- ingredient_display_names
-- ---------------------------------------------------------------------------
-- The set-returning wrapper over ingredient_display_name(uuid, text).
--
-- Recipe detail renders a matched line from the catalog rather than from
-- raw_text -- that hop is D1's payoff, and it is what makes one shopping list
-- read `brašno` whether the recipe said `brašna` or `flour`. Doing it needs
-- the display-name fallback chain for a whole recipe's worth of ingredient
-- ids, and PostgREST cannot call a scalar function per embedded row.
--
-- Reimplementing the chain client-side was the alternative, and it would have
-- put a second definition of "which name wins" in Dart, out of reach of the
-- SQL tests. The chain stays defined once (migration 4).

create or replace function ingredient_display_names(
  ids uuid[],
  loc text default 'sr'
)
returns table (ingredient_id uuid, display_name text)
language sql
stable
security invoker
set search_path = public
as $$
  select i.id, ingredient_display_name(i.id, loc)
  from ingredients i
  where i.id = any(ids)
    and i.deleted_at is null;
$$;

comment on function ingredient_display_names(uuid[], text) is
  'Display names for a set of ingredients, in one round trip. Wraps '
  'ingredient_display_name() so the fallback chain stays defined once.';

-- ---------------------------------------------------------------------------
-- replace_recipe_lines
-- ---------------------------------------------------------------------------
-- Saving an edited recipe replaces its whole line list and step list. That is
-- three statements -- two deletes and two inserts -- and PostgREST gives the
-- client no way to run them in one transaction. Without this function a failed
-- save leaves a recipe with its old lines deleted and its new ones missing,
-- which is worse than a save that did not happen.
--
-- security invoker, so RLS still decides who may write. The function is
-- convenience and atomicity, not authority -- it holds no privilege the caller
-- does not already have, and every statement inside it is checked by the same
-- policies a direct write would hit.
--
-- The parameter is `recipe`, not `recipe_id`: recipe_id is a column of both
-- child tables, and a plpgsql parameter sharing a name with a column in the
-- same statement is an ambiguity error (D30, learned the hard way in
-- merge_ingredients).
--
-- position is assigned from array order rather than read from the JSON. The
-- client already sends the lines in the order it displays them, and deriving
-- the column here means a duplicated or missing position is not expressible.

create or replace function replace_recipe_lines(
  recipe           uuid,
  ingredient_lines jsonb default '[]'::jsonb,
  steps            jsonb default '[]'::jsonb
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  -- Fail loudly rather than silently writing nothing. Without this, a caller
  -- who cannot see the recipe gets a successful no-op: the deletes match no
  -- rows and the inserts are refused row by row.
  if not exists (select 1 from recipes r where r.id = recipe) then
    raise exception 'recipe not found or not visible' using errcode = '42501';
  end if;

  delete from recipe_ingredients ri where ri.recipe_id = recipe;
  delete from recipe_steps rs where rs.recipe_id = recipe;

  insert into recipe_ingredients (
    recipe_id, position, section, raw_text, ingredient_id,
    qty_num, qty_den, qty_max_num, qty_max_den,
    unit_code, note, is_optional,
    match_method, match_confidence, matched_at
  )
  select
    recipe,
    (e.ord - 1)::int,
    nullif(btrim(e.line ->> 'section'), ''),
    e.line ->> 'raw_text',
    (e.line ->> 'ingredient_id')::uuid,
    (e.line ->> 'qty_num')::int,
    (e.line ->> 'qty_den')::int,
    (e.line ->> 'qty_max_num')::int,
    (e.line ->> 'qty_max_den')::int,
    nullif(btrim(e.line ->> 'unit_code'), ''),
    nullif(btrim(e.line ->> 'note'), ''),
    coalesce((e.line ->> 'is_optional')::boolean, false),
    nullif(btrim(e.line ->> 'match_method'), ''),
    (e.line ->> 'match_confidence')::numeric,
    (e.line ->> 'matched_at')::timestamptz
  from jsonb_array_elements(ingredient_lines) with ordinality as e(line, ord);

  insert into recipe_steps (recipe_id, position, text, timer_seconds)
  select
    recipe,
    (e.ord - 1)::int,
    e.step ->> 'text',
    (e.step ->> 'timer_seconds')::int
  from jsonb_array_elements(steps) with ordinality as e(step, ord);

  -- Touch the parent so its updated_at moves. The children carry no lifecycle
  -- columns of their own (D24), so without this a recipe whose entire
  -- ingredient list changed looks untouched to Phase 2's delta fetch and the
  -- Drift cache never re-reads it.
  update recipes set updated_at = now() where id = recipe;
end;
$$;

comment on function replace_recipe_lines(uuid, jsonb, jsonb) is
  'Replaces a recipe''s ingredient lines and steps in one transaction, and '
  'touches the parent''s updated_at. security invoker -- RLS still decides.';

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
-- Membership only, with no deleted_at clause anywhere (D23): the Phase 2 delta
-- fetch has to see tombstones in order to evict them from the Drift cache, so
-- soft-deleted rows are filtered in data/, not here.

alter table recipes enable row level security;

create policy recipes_select on recipes for select
  using (is_household_member(household_id));
create policy recipes_insert on recipes for insert
  with check (is_household_member(household_id));
create policy recipes_update on recipes for update
  using (is_household_member(household_id))
  with check (is_household_member(household_id));
-- No DELETE policy: deletion is a soft delete, which is an UPDATE (rule 4).

-- The child tables have no household_id of their own, so they check membership
-- through their parent with an exists subquery (docs/DATA_MODEL.md).
--
-- Unlike every other table so far, these two DO get a DELETE policy. That is
-- not a breach of rule 4: D24 scopes "no hard deletes" to tables carrying a
-- household_id, and editing a recipe means replacing its line list. A
-- tombstoned ingredient line would be a row nothing reads, on a table with no
-- deleted_at column to hold it.

alter table recipe_ingredients enable row level security;

create policy recipe_ingredients_select on recipe_ingredients for select
  using (exists (select 1 from recipes r
                 where r.id = recipe_ingredients.recipe_id
                   and is_household_member(r.household_id)));
create policy recipe_ingredients_insert on recipe_ingredients for insert
  with check (exists (select 1 from recipes r
                      where r.id = recipe_ingredients.recipe_id
                        and is_household_member(r.household_id)));
create policy recipe_ingredients_update on recipe_ingredients for update
  using (exists (select 1 from recipes r
                 where r.id = recipe_ingredients.recipe_id
                   and is_household_member(r.household_id)))
  with check (exists (select 1 from recipes r
                      where r.id = recipe_ingredients.recipe_id
                        and is_household_member(r.household_id)));
create policy recipe_ingredients_delete on recipe_ingredients for delete
  using (exists (select 1 from recipes r
                 where r.id = recipe_ingredients.recipe_id
                   and is_household_member(r.household_id)));

alter table recipe_steps enable row level security;

create policy recipe_steps_select on recipe_steps for select
  using (exists (select 1 from recipes r
                 where r.id = recipe_steps.recipe_id
                   and is_household_member(r.household_id)));
create policy recipe_steps_insert on recipe_steps for insert
  with check (exists (select 1 from recipes r
                      where r.id = recipe_steps.recipe_id
                        and is_household_member(r.household_id)));
create policy recipe_steps_update on recipe_steps for update
  using (exists (select 1 from recipes r
                 where r.id = recipe_steps.recipe_id
                   and is_household_member(r.household_id)))
  with check (exists (select 1 from recipes r
                      where r.id = recipe_steps.recipe_id
                        and is_household_member(r.household_id)));
create policy recipe_steps_delete on recipe_steps for delete
  using (exists (select 1 from recipes r
                 where r.id = recipe_steps.recipe_id
                   and is_household_member(r.household_id)));
