-- Migration 15 -- leftovers, the snack variety check, and within-slot
-- reordering (Phase 2, part 3).
--
-- Migration 14 shipped meal_plan_entries with leftover_of_entry_id, its
-- self-FK, its index and the 'leftover' branch of the entry_kind check --
-- all unreachable (D51). This migration is what makes them reachable: a
-- trigger that derives recipe_id onto a leftover row so it needs no join to
-- be found by the variety check or by Phase 2's next part, the shopping
-- list, and the RPC D49 named for within-slot reordering, which
-- meal_plan_entries_before_write cannot express.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D55 (a leftover's recipe_id is derived by
-- trigger, never sent by the client -- this is what closes D51), D56 (a
-- leftover's destination is a date, not a slot in the visible week, and may
-- land in a plan row that does not exist yet), D57 (within-slot order is an
-- RPC that renumbers the whole group, and why it does not fight
-- meal_plan_entries_before_write), D58 (the snack variety window is centred
-- on the candidate date, not trailing, and the check is advisory).

-- ---------------------------------------------------------------------------
-- meal_plan_entries_leftover_source
-- ---------------------------------------------------------------------------
-- Migration 14 left the 'leftover' branch of the entry_kind check
-- deliberately loose -- it requires only leftover_of_entry_id, not recipe_id
-- -- precisely so this migration could denormalise recipe_id onto the row
-- without rewriting that constraint. Deriving it here, rather than trusting
-- whatever the client sends, is what makes the denormalisation safe: a
-- leftover's recipe_id cannot disagree with its source's, so the drift the
-- loose check permits is simply not expressible. The same move
-- ensure_meal_plan already makes for the plan id and
-- meal_plan_entries_before_write already makes for position (D49, D50).
--
-- A second, additively-named trigger rather than a `create or replace` of
-- meal_plan_entries_before_write: that function's own comment in migration
-- 14 describes exactly three invariants, and folding a fourth in would make
-- that file's prose a lie the moment this one is applied -- and it can never
-- be edited back true (CLAUDE.md). Trigger execution order is alphabetical
-- by name, so meal_plan_entries_before_write still runs first; the two are
-- independent in practice (position assignment and the week-boundary guard
-- never read recipe_id or leftover_of_entry_id's source row), so the
-- ordering does not actually matter, but it is worth writing down rather
-- than leaving to be rediscovered.
--
-- The before-write trigger already refuses a leftover_of_entry_id that does
-- not exist (invariant 3 there). This trigger re-reads that same row anyway,
-- because it needs its columns -- entry_kind and recipe_id -- not merely its
-- existence. The extra lookup is one index hit against
-- meal_plan_entries_pkey and is not worth avoiding by threading the row
-- through session state between two independently-reasoned-about triggers.

create or replace function meal_plan_entries_leftover_source()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
declare
  src record;
begin
  if new.entry_kind <> 'leftover' then
    return new;
  end if;

  if new.id is not null and new.id = new.leftover_of_entry_id then
    raise exception 'a leftover cannot point at itself' using errcode = '23514';
  end if;

  select e.entry_kind, e.recipe_id into src
  from meal_plan_entries e
  where e.id = new.leftover_of_entry_id;

  if src is null then
    raise exception 'leftover source not found or not visible'
      using errcode = '23503';
  end if;

  if src.entry_kind <> 'recipe' then
    raise exception 'a leftover must point at a recipe entry, not another leftover or a note'
      using errcode = '23514';
  end if;

  new.recipe_id := src.recipe_id;
  return new;
end;
$$;

comment on function meal_plan_entries_leftover_source() is
  'Derives recipe_id onto a leftover row from its source entry (D55), and '
  'refuses a source that is not itself an entry_kind = ''recipe'' row -- no '
  'leftover-of-leftover chains. Runs alongside, not instead of, '
  'meal_plan_entries_before_write (migration 14).';

create trigger meal_plan_entries_leftover_source
  before insert or update on meal_plan_entries
  for each row execute function meal_plan_entries_leftover_source();

-- ---------------------------------------------------------------------------
-- reorder_meal_plan_entry
-- ---------------------------------------------------------------------------
-- D49 named this RPC and explained why the before-write trigger cannot do
-- its job: that trigger always lands an insert or a cross-slot move at the
-- tail of the destination group, and within-slot reordering needs the
-- opposite -- an explicit target position, applied to a group that does not
-- change membership.
--
-- security invoker, guarded the same way ensure_meal_plan is: a non-member
-- update would otherwise match zero rows under RLS and look like a silent
-- no-op rather than a refusal, so the entry is looked up first and a missing
-- row raises 42501 before anything is written.
--
-- Renumbers the whole (meal_plan_id, entry_date, slot) group in one
-- statement, splicing the moving row into new_position among its current
-- siblings ordered by their existing position, rather than swapping two
-- rows. A swap would preserve whatever gap or duplicate already exists in
-- that group's position values; D49 rejected a unique index on position
-- specifically so two concurrent inserts into an empty slot do not collide,
-- so gaps and (briefly) duplicates are legal and this RPC must tolerate them
-- on the way in. It leaves the group 0..n-1 with no gap on the way out.
--
-- Does not fight meal_plan_entries_before_write: that trigger reassigns
-- position only on INSERT, or on UPDATE when entry_date or slot actually
-- changed (migration 14). A reorder changes neither, so the before-write
-- trigger's tail-assignment branch never fires here -- the update this RPC
-- issues is exactly the "note text or servings changed" case that trigger
-- was written to leave position alone for. This is the one fact that makes
-- the RPC work at all, and it is not obvious from reading either function on
-- its own.
--
-- new_position is clamped into [0, n-1] rather than raising on an
-- out-of-range value: asking to move the last chip further down is a
-- no-op, not a mistake worth surfacing as an error.
--
-- meal_plan_entries_touch_plan (migration 14) fires per updated row and
-- moves meal_plans.updated_at on its own; nothing extra is needed for the
-- Phase 2 delta fetch to see a reordered week as changed.

create or replace function reorder_meal_plan_entry(
  entry       uuid,
  new_position int
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare
  target_plan uuid;
  target_date date;
  target_slot text;
  group_size  int;
  clamped     int;
begin
  select e.meal_plan_id, e.entry_date, e.slot
  into target_plan, target_date, target_slot
  from meal_plan_entries e
  where e.id = entry;

  if target_plan is null then
    raise exception 'meal plan entry not found or not visible'
      using errcode = '42501';
  end if;

  select count(*) into group_size
  from meal_plan_entries e
  where e.meal_plan_id = target_plan
    and e.entry_date = target_date
    and e.slot = target_slot;

  clamped := greatest(0, least(new_position, group_size - 1));

  with others as (
    -- Every sibling except the moving row, renumbered 0..n-2 by their
    -- current relative order.
    select e.id, row_number() over (order by e.position) - 1 as rn
    from meal_plan_entries e
    where e.meal_plan_id = target_plan
      and e.entry_date = target_date
      and e.slot = target_slot
      and e.id <> entry
  ),
  spliced as (
    -- Splice the moving row back in at `clamped`, shifting anything at or
    -- past that index up by one.
    select id, case when rn >= clamped then rn + 1 else rn end as final_position
    from others
    union all
    select entry, clamped
  )
  update meal_plan_entries e
  set position = spliced.final_position
  from spliced
  where e.id = spliced.id
    and e.position is distinct from spliced.final_position;
end;
$$;

comment on function reorder_meal_plan_entry(uuid, int) is
  'Moves entry to new_position (clamped to the group''s bounds) within its '
  'own (meal_plan_id, entry_date, slot) group, renumbering every sibling to '
  '0..n-1 (D57). Does not change entry_date or slot -- use moveEntry / an '
  'update for that.';

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

revoke execute on function reorder_meal_plan_entry(uuid, int) from public, anon;
grant execute on function reorder_meal_plan_entry(uuid, int)
  to authenticated, service_role;
