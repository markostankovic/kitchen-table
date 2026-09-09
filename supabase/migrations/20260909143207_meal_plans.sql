-- Migration 14 -- meal plans and their entries (Phase 2, part 2).
--
-- The first tables in Phase 2 proper. `meal_plans` is one household's week;
-- `meal_plan_entries` is what goes in one of its 28 slots (7 days x 4 slots).
-- The shopping list (a later part) aggregates over a week's entries, and the
-- Drift cache (also later) needs an entity worth caching -- both are why this
-- comes before either.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D49 (meal_plan_entries is a child table in
-- the D24 sense, and its invariants live in triggers, not in the client),
-- D50 (the week row is written on the first write, never on a view), D51
-- (leftover_of_entry_id and the 'leftover' vocabulary ship now, unreachable).

-- ---------------------------------------------------------------------------
-- meal_plans
-- ---------------------------------------------------------------------------
-- Household-scoped in the D24 sense -- it carries a household_id -- so it gets
-- the full rule 4 treatment: updated_at with a trigger, deleted_at, no hard
-- deletes.
--
-- week_start is always a Monday; the client is responsible for that (D53's
-- plan_week.dart is the one place that does date arithmetic). Postgres is not
-- asked to enforce it, the same way it is not asked to validate email
-- addresses -- a check constraint on the day-of-week of a date is a trap for a
-- week whose Monday changes if the definition of "week" ever does.

create table meal_plans (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  week_start date not null,
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  -- Total, not partial on `deleted_at is null` (mirrors D28's reasoning for
  -- ingredient_names): one household has exactly one row per week, live or
  -- dead, forever. ensure_meal_plan() below resurrects a soft-deleted week
  -- into that same row rather than being blocked by it. A partial index would
  -- let a live and a dead row coexist for the same week, which hands the
  -- Phase 2 delta fetch an ambiguous key for the entity D23 exists to let it
  -- evict.
  unique (household_id, week_start)
);

create trigger meal_plans_set_updated_at
  before update on meal_plans
  for each row execute function set_updated_at();

-- No separate index on household_id: the unique constraint above already
-- leads with it, and a second index over the same leading column would only
-- ever be chosen never to be used.

comment on table meal_plans is
  'One household''s week. week_start is always a Monday; the row is created '
  'lazily, on the first write into that week (D50), never on a view.';

-- ---------------------------------------------------------------------------
-- meal_plan_entries
-- ---------------------------------------------------------------------------
-- No household_id, no created_at, no updated_at, no deleted_at (D24, D49):
-- this is a child table exactly like recipe_ingredients and recipe_steps, it
-- cascades with its plan, and a removed entry is genuinely gone rather than
-- tombstoned. What the Phase 2 delta fetch needs is the *plan*'s updated_at
-- moving when anything inside it changes -- that is meal_plan_entries_touch_
-- plan below, doing by trigger what replace_recipe_lines does by hand for
-- recipes, because unlike a recipe's lines there is no single funnel: add,
-- move and remove are separate statements, and a later part adds a fourth.
--
-- position has no default (deliberately -- see the trigger below): column
-- defaults are applied before BEFORE triggers, so a default here would make
-- "the client didn't say" indistinguishable from "the client said 0", and the
-- position-assignment trigger below depends on being able to tell those apart.
--
-- The three entry_kind branches are made EXCLUSIVE, not just an `or` of three
-- possibilities -- a plain `or` would let a 'note' entry also carry a
-- recipe_id. The 'leftover' branch is the one exception: it requires only its
-- own pointer, deliberately loose, because a later part may want recipe_id
-- denormalised onto a leftover row so the variety check can count it, and this
-- file will be unwritable by then (D51). Being permissive on the one branch
-- with no client yet is honest; being permissive on the two branches that
-- already have one would just be sloppy.

create table meal_plan_entries (
  id uuid primary key default gen_random_uuid(),
  meal_plan_id uuid not null references meal_plans(id) on delete cascade,
  entry_date date not null,
  slot text not null check (slot in ('breakfast','lunch','dinner','snack')),
  position int not null,
  entry_kind text not null check (entry_kind in ('recipe','leftover','note')),
  recipe_id uuid references recipes(id),
  -- D51: ships now, unreachable until a later part writes it. on delete
  -- cascade rather than set null -- a null pointer on a 'leftover' row would
  -- violate the check below, so set null would produce a row that only fails
  -- loudly later; cascade means deleting the source takes its leftovers too,
  -- which is the behaviour a cook expects.
  leftover_of_entry_id uuid references meal_plan_entries(id) on delete cascade,
  note text,
  servings int check (servings is null or servings > 0),
  check (
    case entry_kind
      when 'recipe' then
        recipe_id is not null
        and leftover_of_entry_id is null
        and note is null
      when 'note' then
        note is not null and length(trim(note)) > 0
        and recipe_id is null
        and leftover_of_entry_id is null
      when 'leftover' then
        leftover_of_entry_id is not null
    end
  )
);

create index meal_plan_entries_plan_date_slot_idx
  on meal_plan_entries (meal_plan_id, entry_date, slot);

create index meal_plan_entries_recipe_id_idx
  on meal_plan_entries (recipe_id);

-- The self-FK's own cascade would otherwise seq-scan meal_plan_entries on
-- every delete of a row something might point at.
create index meal_plan_entries_leftover_of_entry_id_idx
  on meal_plan_entries (leftover_of_entry_id);

comment on table meal_plan_entries is
  'One slot of one day of a meal_plans week. No lifecycle columns of its own '
  '(D24, D49) -- it cascades with its plan, and removal is a hard delete. '
  'position is assigned by meal_plan_entries_before_write, never by the '
  'client (D49, mirrors D36''s reasoning for recipe lines).';

-- ---------------------------------------------------------------------------
-- meal_plan_entries_before_write
-- ---------------------------------------------------------------------------
-- Three invariants a CHECK constraint cannot express, because each needs
-- either a sibling row or the parent row:
--
--   1. position is the tail of its (meal_plan_id, entry_date, slot) group,
--      assigned here rather than computed client-side (D49) -- a client
--      max()+1 is a read-then-write race, and deriving it here means a
--      duplicate or missing position is not expressible, the same argument
--      D36 already made for recipe_ingredients.position. Reassigned on UPDATE
--      only when the (date, slot) actually changed -- an update to note text
--      or servings must not silently reshuffle the slot it already sits in.
--      Known limitation, written down rather than discovered later:
--      within-slot reordering is NOT expressible by this trigger -- every
--      insert and every move lands at the tail. An explicit reorder RPC is a
--      later part's problem, when something needs it.
--
--   2. entry_date must fall inside its plan's week -- a CHECK constraint
--      cannot reach another table, and an entry filed under the wrong week is
--      invisible in the grid AND wrong in any date-ranged aggregate over it.
--
--   3. leftover_of_entry_id, when set, must point at a row that exists. Under
--      security invoker + RLS this reads as "the source entry must be visible
--      to you", which is the household guard for free -- a foreign key you
--      cannot see is a foreign key you cannot reason about.

create or replace function meal_plan_entries_before_write()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  week_start_date date;
  next_position    int;
begin
  select p.week_start into week_start_date
  from meal_plans p where p.id = new.meal_plan_id;

  if week_start_date is null then
    raise exception 'meal plan not found or not visible' using errcode = '42501';
  end if;

  if new.entry_date < week_start_date or new.entry_date > week_start_date + 6 then
    raise exception 'entry_date is outside its meal plan''s week'
      using errcode = '23514';
  end if;

  if new.leftover_of_entry_id is not null
     and not exists (
       select 1 from meal_plan_entries e where e.id = new.leftover_of_entry_id
     )
  then
    raise exception 'leftover_of_entry_id not found or not visible'
      using errcode = '23503';
  end if;

  if tg_op = 'INSERT'
     or new.entry_date is distinct from old.entry_date
     or new.slot is distinct from old.slot
  then
    select coalesce(max(position) + 1, 0) into next_position
    from meal_plan_entries e
    where e.meal_plan_id = new.meal_plan_id
      and e.entry_date = new.entry_date
      and e.slot = new.slot
      and e.id is distinct from new.id;
    new.position := next_position;
  end if;

  return new;
end;
$$;

comment on function meal_plan_entries_before_write() is
  'Assigns position at the tail of its (plan, date, slot) group, refuses an '
  'entry_date outside the plan''s week, and refuses a leftover_of_entry_id '
  'the caller cannot see.';

create trigger meal_plan_entries_before_write
  before insert or update on meal_plan_entries
  for each row execute function meal_plan_entries_before_write();

-- ---------------------------------------------------------------------------
-- meal_plan_entries_touch_plan
-- ---------------------------------------------------------------------------
-- security invoker is correct and safe: the child's own insert/update/delete
-- policies and the parent's update policy all reduce to the same
-- is_household_member(household_id), so this trigger holds no privilege the
-- caller does not already have.
--
-- Fires on DELETE too, using old.meal_plan_id -- removing the last recipe from
-- a week is a real change to that week and must move updated_at exactly like
-- adding one does. When a household is deleted, deleting its meal_plans row
-- cascades to this table and fires this trigger against an already-deleted
-- parent; the UPDATE simply matches zero rows. Safe, and written down here so
-- it is not rediscovered as a bug.

create or replace function meal_plan_entries_touch_plan()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  update meal_plans
  set updated_at = now()
  where id = coalesce(new.meal_plan_id, old.meal_plan_id);
  return coalesce(new, old);
end;
$$;

comment on function meal_plan_entries_touch_plan() is
  'Touches the parent plan''s updated_at on any entry insert, update or '
  'delete, so a week whose entries changed does not look untouched to the '
  'Phase 2 delta fetch (mirrors replace_recipe_lines''s closing statement).';

create trigger meal_plan_entries_touch_plan
  after insert or update or delete on meal_plan_entries
  for each row execute function meal_plan_entries_touch_plan();

-- ---------------------------------------------------------------------------
-- ensure_meal_plan
-- ---------------------------------------------------------------------------
-- The grid must open on any week without writing a row for it -- browsing a
-- year should not insert 52 empty plans. So the row is created lazily, only
-- from a write path, the first time something is actually put into that week
-- (D50).
--
-- security invoker, guarded by is_household_member raising 42501: without the
-- guard, a non-member's insert against a row it cannot see would fall through
-- to the unique constraint and surface as 23505 -> ConflictFailure ("that
-- already exists"), which is the wrong message for "you are not allowed
-- here".
--
-- `on conflict ... do update set deleted_at = null returning id`, not
-- `do nothing`: `do nothing returning id` returns NO ROW on conflict, which is
-- the common case here (most writes are into a week that already has a plan),
-- so the RPC would return NULL exactly when it matters most. `do update`
-- guarantees a returned row every time, and as a consequence also resurrects
-- a soft-deleted week into its same row rather than being blocked by the
-- total unique index -- a bonus, not the main reason.
--
-- Parameters are `household` and `week`, never `household_id` / `week_start`
-- (D30): a plpgsql parameter sharing a name with a column in the same
-- statement is an ambiguity error, learned the hard way in merge_ingredients
-- and again in replace_recipe_lines.
--
-- No `current_household()` exists anywhere in this schema -- the only
-- definition of "your household" is the client's own query (oldest
-- undeleted household you belong to), and this function is not the place to
-- invent a second one. The caller passes the id it already resolved.

create or replace function ensure_meal_plan(
  household uuid,
  week      date
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  plan_id uuid;
begin
  if not is_household_member(household) then
    raise exception 'household not found or not visible' using errcode = '42501';
  end if;

  insert into meal_plans (household_id, week_start, created_by)
  values (household, week, auth.uid())
  on conflict (household_id, week_start)
  do update set deleted_at = null
  returning id into plan_id;

  return plan_id;
end;
$$;

comment on function ensure_meal_plan(uuid, date) is
  'Returns the id of household''s plan for week, creating it if this is the '
  'first write into that week and resurrecting it if it was soft-deleted '
  '(D50). Call only from a write path -- never from a view.';

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
-- Membership only, with no deleted_at clause anywhere (D23): the Phase 2 delta
-- fetch has to see tombstones in order to evict them from the Drift cache, so
-- soft-deleted rows are filtered in data/, not here.

alter table meal_plans enable row level security;

create policy meal_plans_select on meal_plans for select
  using (is_household_member(household_id));
create policy meal_plans_insert on meal_plans for insert
  with check (is_household_member(household_id));
create policy meal_plans_update on meal_plans for update
  using (is_household_member(household_id))
  with check (is_household_member(household_id));
-- No DELETE policy: deletion is a soft delete, which is an UPDATE (rule 4).

-- meal_plan_entries has no household_id of its own, so it checks membership
-- through its parent with an exists subquery (docs/DATA_MODEL.md).
--
-- Unlike meal_plans, this table DOES get a DELETE policy. Not a breach of
-- rule 4: D24 scopes "no hard deletes" to tables carrying a household_id, and
-- removing an entry from a slot is a real removal, not an edit. A tombstoned
-- entry would be a row nothing reads, on a table with no deleted_at column to
-- hold it (same reasoning as recipe_ingredients / recipe_steps above).

alter table meal_plan_entries enable row level security;

create policy meal_plan_entries_select on meal_plan_entries for select
  using (exists (select 1 from meal_plans p
                 where p.id = meal_plan_entries.meal_plan_id
                   and is_household_member(p.household_id)));
create policy meal_plan_entries_insert on meal_plan_entries for insert
  with check (exists (select 1 from meal_plans p
                      where p.id = meal_plan_entries.meal_plan_id
                        and is_household_member(p.household_id)));
create policy meal_plan_entries_update on meal_plan_entries for update
  using (exists (select 1 from meal_plans p
                 where p.id = meal_plan_entries.meal_plan_id
                   and is_household_member(p.household_id)))
  with check (exists (select 1 from meal_plans p
                      where p.id = meal_plan_entries.meal_plan_id
                        and is_household_member(p.household_id)));
create policy meal_plan_entries_delete on meal_plan_entries for delete
  using (exists (select 1 from meal_plans p
                 where p.id = meal_plan_entries.meal_plan_id
                   and is_household_member(p.household_id)));

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

revoke execute on function ensure_meal_plan(uuid, date) from public, anon;
grant execute on function ensure_meal_plan(uuid, date)
  to authenticated, service_role;
