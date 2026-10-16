-- Deleting a recipe takes it off the meal plan.
--
-- A recipe delete is a soft delete (rule 4): it stamps recipes.deleted_at and
-- touches nothing else, so every meal_plan_entries row pointing at the recipe
-- lived on and the Plan tab kept showing a recipe the household had thrown
-- away. This trigger removes those entries the moment the stamp lands.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).

-- ---------------------------------------------------------------------------
-- recipes_clear_plan_entries
-- ---------------------------------------------------------------------------
-- A real delete, not a soft one: meal_plan_entries carries no deleted_at of
-- its own (D24, D49), and this is the same removal removeEntry already does.
--
-- Leftovers go too, by two routes that agree: a leftover's recipe_id is
-- derived from its source (D55), so the where clause matches it directly, and
-- leftover_of_entry_id's on delete cascade would take it anyway.
--
-- Every week this changes is seen by the delta fetch for free:
-- meal_plan_entries_touch_plan fires on delete and moves the parent plan's
-- updated_at, so other devices drop the entries on their next sync.
--
-- security invoker is enough, for the reason meal_plan_entries_touch_plan's
-- header gives: the caller could stamp the recipe only as a member of its
-- household, and meal_plan_entries_delete reduces to that same membership.
--
-- Only the null -> not-null transition fires it. Re-stamping an already
-- deleted recipe finds nothing, and clearing deleted_at (no restore UI today)
-- does not bring the entries back.

create or replace function recipes_clear_plan_entries()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  delete from meal_plan_entries where recipe_id = new.id;
  return new;
end;
$$;

comment on function recipes_clear_plan_entries() is
  'Removes every meal plan entry (and so every leftover) for a recipe when '
  'it is soft-deleted, so a deleted recipe never stays planned.';

create trigger recipes_clear_plan_entries
  after update of deleted_at on recipes
  for each row
  when (old.deleted_at is null and new.deleted_at is not null)
  execute function recipes_clear_plan_entries();
