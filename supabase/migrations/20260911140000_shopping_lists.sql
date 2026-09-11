-- Migration 16 -- the shopping list (Phase 2, part 4).
--
-- A week's meal plan aggregates into a list. The aggregation itself runs on
-- the client, in Dart (docs/ARCHITECTURE.md's client/edge split: "pure
-- aggregation over rows the client can already read"), so nothing in this
-- file computes anything. What it provides is somewhere to put the answer,
-- the access control around it, and one function that writes a list and its
-- items in a single transaction.
--
-- These three tables have been referenced by applied code since Phase 1b:
-- merge_ingredients (migration 6) already repoints shopping_list_items and
-- already reconciles household_pantry_prefs, both behind to_regclass()
-- guards, and supabase/tests/merge_ingredients_test.sql already names them in
-- its `known` array. Creating them here does not need that function changed;
-- it makes two dormant branches reachable for the first time, and the test
-- file grows positive assertions for them rather than only the FK-coverage
-- check that has been standing guard.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D59 (shopping_lists carries updated_at, which
-- docs/DATA_MODEL.md's sketch omitted, and household_pantry_prefs deliberately
-- carries no lifecycle columns at all), D61 (generation is one security
-- invoker RPC rather than an insert followed by an insert).

-- ---------------------------------------------------------------------------
-- shopping_lists
-- ---------------------------------------------------------------------------
-- Household-scoped in the D24 sense -- it carries a household_id -- so it gets
-- the full rule 4 treatment: updated_at with a trigger, deleted_at, no hard
-- deletes.
--
-- docs/DATA_MODEL.md's sketch gives this table deleted_at but no updated_at.
-- That is the same omission D49 corrected in the meal_plans sketch, and for
-- the same reason: rule 4 is not a rule about which columns a table happens to
-- need, it is a rule about every table carrying a household_id, and Phase 2's
-- delta fetch reads updated_at to decide what to re-download. A snapshot that
-- is never edited after generation still gets soft-deleted when it is
-- regenerated, and that write has to be visible to the cache.
--
-- meal_plan_id is nullable and carries no ON DELETE: a list generated from a
-- week is a record of what was bought for, and it outlives the plan. It is
-- nullable because D59's range picker can span a range that is not one plan's
-- week -- see the date_from/date_to pair below.
--
-- locale is stored, not derived at read time. display_name on each item was
-- resolved from the catalog at generation time (D1), so the list is already a
-- document in one language; remembering which one is what stops a list
-- generated in Serbian rendering half-translated after a Phase 3 locale
-- toggle.

create table shopping_lists (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  meal_plan_id uuid references meal_plans(id),
  date_from date not null,
  date_to date not null,
  locale text not null check (locale in ('sr','en')),
  generated_at timestamptz not null default now(),
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  -- A single day is a legal range (date_from = date_to). An inverted one is
  -- not, and it is worth refusing here rather than producing an empty list
  -- that looks like "nothing planned" instead of "you asked backwards".
  constraint shopping_lists_date_range check (date_to >= date_from)
);

create trigger shopping_lists_set_updated_at
  before update on shopping_lists
  for each row execute function set_updated_at();

-- The list screen's only query: this household's most recent live list.
create index shopping_lists_household_generated_idx
  on shopping_lists (household_id, generated_at desc);

comment on table shopping_lists is
  'One generated shopping list -- a snapshot, not a live document (D13). '
  'Regenerating soft-deletes the previous list and writes a new one.';

-- ---------------------------------------------------------------------------
-- shopping_list_items
-- ---------------------------------------------------------------------------
-- A child table in the D24 sense: no household_id, no created_at, no
-- updated_at, no deleted_at. It cascades with its list and carries no
-- lifecycle of its own, exactly like recipe_ingredients and
-- meal_plan_entries.
--
-- ingredient_id is nullable and has no ON DELETE: a line the catalog could not
-- match still becomes an item (rule 3 -- raw_text always renders), and a
-- matched one survives a merge because merge_ingredients repoints it.
--
-- display_name is resolved at generation time and stored, not joined at read
-- time. That is what makes a list readable from the Drift cache in a
-- supermarket with no signal (D12), which is the entire reason the cache
-- exists -- a list that needs a join against the catalog to render is a list
-- that does not render offline.
--
-- quantities is one entry per unit family, never a single number:
--   [{"family":"mass","amount_num":800,"amount_den":1,"unit":"g"},
--    {"family":"volume","amount_num":480,"amount_den":1,"unit":"ml"}]
-- D9 sums within a family and never across one. The amount is carried as an
-- integer pair rather than a number for the same reason recipe quantities are
-- (rule 5): a third of a cup is a third of a cup, and a week's worth of them
-- has to land on an exact figure. docs/DATA_MODEL.md sketched this as a plain
-- `amount`, which would have put a float back in the one place the rule was
-- written to keep it out of (D60).
--
-- unmatched_lines holds the raw_text of every line that contributed to this
-- item without resolving to a quantity -- an unparsed line, or a measure in
-- the 'other' family (prstohvat, po ukusu), which migration 4's own comment
-- says is "not a quantity" and is "carried through as a note and never
-- summed".

create table shopping_list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references shopping_lists(id) on delete cascade,
  ingredient_id uuid references ingredients(id),
  display_name text not null check (length(trim(display_name)) > 0),
  category text,
  position int not null default 0,
  is_pantry_staple boolean not null default false,
  quantities jsonb not null default '[]'::jsonb,
  unmatched_lines jsonb not null default '[]'::jsonb,
  constraint shopping_list_items_quantities_is_array
    check (jsonb_typeof(quantities) = 'array'),
  constraint shopping_list_items_unmatched_is_array
    check (jsonb_typeof(unmatched_lines) = 'array')
);

create index shopping_list_items_list_position_idx
  on shopping_list_items (list_id, position);

-- merge_ingredients repoints this column, and does so with a bare
-- `update ... where ingredient_id = source`. Without this index that is a
-- sequential scan of every item ever generated.
create index shopping_list_items_ingredient_id_idx
  on shopping_list_items (ingredient_id)
  where ingredient_id is not null;

comment on table shopping_list_items is
  'One line of a generated list. display_name and quantities are resolved at '
  'generation time so the list renders offline with no catalog join (D12).';

-- ---------------------------------------------------------------------------
-- household_pantry_prefs
-- ---------------------------------------------------------------------------
-- "We always have this" / "no, we never do", per household, overriding
-- ingredients.is_pantry_staple in BOTH directions. Five ingredients are
-- flagged globally by the seed (so, ulje, secer, voda, biber); every
-- household disagrees with that list somewhere.
--
-- No deleted_at, no updated_at, and a hard delete. This is not a fresh call:
-- migration 6 already wrote the reasoning down when it taught
-- merge_ingredients how to reconcile this table -- "a join table with no
-- deleted_at, on the household_members precedent in D24, so the delete is a
-- hard one". Clearing a preference is returning to the global default, not
-- recording that you once held an opinion.
--
-- The composite primary key is what merge_ingredients has to work around: a
-- blind repoint violates it whenever a household has a preference for both
-- the source and the target ingredient, which is why that function deletes
-- the redundant source row before updating.

create table household_pantry_prefs (
  household_id uuid not null references households(id) on delete cascade,
  ingredient_id uuid not null references ingredients(id) on delete cascade,
  always_have boolean not null,
  created_at timestamptz not null default now(),
  primary key (household_id, ingredient_id)
);

comment on table household_pantry_prefs is
  'Per-household override of ingredients.is_pantry_staple, in both '
  'directions. A join table (D24): hard delete, no lifecycle columns.';

-- ---------------------------------------------------------------------------
-- save_shopping_list
-- ---------------------------------------------------------------------------
-- The parent and its items in one transaction. Without this the client would
-- insert the list, then insert the items, and a failure between the two would
-- leave a headless list -- a generated shopping list with nothing on it,
-- indistinguishable from a week with nothing planned. That is D36's argument
-- for replace_recipe_lines and D44's for save_imported_recipe, arriving a
-- third time.
--
-- security invoker, so RLS still decides who may write (D36: the function is
-- atomicity, not authority). The membership check below is therefore not the
-- access control -- the INSERT policies are. It exists so that a caller who
-- cannot see the household gets a refusal rather than a successful no-op,
-- the same guard replace_recipe_lines opens with.
--
-- position is assigned from array order rather than read from the JSON, for
-- the reason replace_recipe_lines gives: the client already sends the items
-- in the order it means to display them, and deriving the column here makes a
-- duplicated or missing position inexpressible.

create or replace function save_shopping_list(
  household  uuid,
  plan       uuid,
  from_date  date,
  to_date    date,
  loc        text,
  items      jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  list_id uuid;
begin
  if not is_household_member(household) then
    raise exception 'household not found or not visible' using errcode = '42501';
  end if;

  insert into shopping_lists (
    household_id, meal_plan_id, date_from, date_to, locale, created_by
  )
  values (household, plan, from_date, to_date, loc, auth.uid())
  returning id into list_id;

  insert into shopping_list_items (
    list_id, ingredient_id, display_name, category, position,
    is_pantry_staple, quantities, unmatched_lines
  )
  select
    list_id,
    (e.item ->> 'ingredient_id')::uuid,
    e.item ->> 'display_name',
    nullif(btrim(e.item ->> 'category'), ''),
    (e.ord - 1)::int,
    coalesce((e.item ->> 'is_pantry_staple')::boolean, false),
    coalesce(e.item -> 'quantities', '[]'::jsonb),
    coalesce(e.item -> 'unmatched_lines', '[]'::jsonb)
  from jsonb_array_elements(items) with ordinality as e(item, ord);

  return list_id;
end;
$$;

comment on function save_shopping_list(uuid, uuid, date, date, text, jsonb) is
  'Writes a generated list and all its items in one transaction, assigning '
  'position from array order. security invoker -- RLS still decides.';

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
-- Membership only, with no deleted_at clause anywhere (D23): the Phase 2 delta
-- fetch has to see tombstones in order to evict them from the Drift cache, so
-- soft-deleted rows are filtered in data/, not here.

alter table shopping_lists enable row level security;

create policy shopping_lists_select on shopping_lists for select
  using (is_household_member(household_id));
create policy shopping_lists_insert on shopping_lists for insert
  with check (is_household_member(household_id));
create policy shopping_lists_update on shopping_lists for update
  using (is_household_member(household_id))
  with check (is_household_member(household_id));
-- No DELETE policy: deletion is a soft delete, which is an UPDATE (rule 4).
-- Regenerating a list sets deleted_at on the old one.

-- shopping_list_items has no household_id of its own, so it checks membership
-- through its parent with an exists subquery, exactly as meal_plan_entries
-- does (migration 14) and for the same reason.
--
-- Unlike shopping_lists, this table DOES get a DELETE policy. Not a breach of
-- rule 4: D24 scopes "no hard deletes" to tables carrying a household_id, and
-- these rows cascade with their list. A tombstoned item would be a row nothing
-- reads, on a table with no deleted_at column to hold it.

alter table shopping_list_items enable row level security;

create policy shopping_list_items_select on shopping_list_items for select
  using (exists (select 1 from shopping_lists l
                 where l.id = shopping_list_items.list_id
                   and is_household_member(l.household_id)));
create policy shopping_list_items_insert on shopping_list_items for insert
  with check (exists (select 1 from shopping_lists l
                      where l.id = shopping_list_items.list_id
                        and is_household_member(l.household_id)));
create policy shopping_list_items_update on shopping_list_items for update
  using (exists (select 1 from shopping_lists l
                 where l.id = shopping_list_items.list_id
                   and is_household_member(l.household_id)))
  with check (exists (select 1 from shopping_lists l
                      where l.id = shopping_list_items.list_id
                        and is_household_member(l.household_id)));
create policy shopping_list_items_delete on shopping_list_items for delete
  using (exists (select 1 from shopping_lists l
                 where l.id = shopping_list_items.list_id
                   and is_household_member(l.household_id)));

-- household_pantry_prefs carries its own household_id, so it checks directly.
-- It gets a DELETE policy because clearing a preference is a real removal
-- (see the table comment above).

alter table household_pantry_prefs enable row level security;

create policy household_pantry_prefs_select on household_pantry_prefs for select
  using (is_household_member(household_id));
create policy household_pantry_prefs_insert on household_pantry_prefs for insert
  with check (is_household_member(household_id));
create policy household_pantry_prefs_update on household_pantry_prefs for update
  using (is_household_member(household_id))
  with check (is_household_member(household_id));
create policy household_pantry_prefs_delete on household_pantry_prefs for delete
  using (is_household_member(household_id));

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

revoke execute on function
  save_shopping_list(uuid, uuid, date, date, text, jsonb) from public, anon;
grant execute on function
  save_shopping_list(uuid, uuid, date, date, text, jsonb)
  to authenticated, service_role;
