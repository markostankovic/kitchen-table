-- Behaviour test: soft-deleting a recipe takes it off the meal plan.
--
-- Covers recipes_clear_plan_entries (migration 20261016100000): the recipe's
-- entries and their leftovers go, other recipes' entries and notes stay, the
-- plan's updated_at moves, and an unrelated recipe update removes nothing.
--
-- Same now()-is-transaction-time caveat as rls_meal_plans_test.sql applies to
-- the touch-trigger assertion below; the same freeze/backdate dance is used.
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from the other test files (this file uses e1e1...).

do $$
declare
  user_a uuid := 'e1e1e1e1-e1e1-e1e1-e1e1-e1e1e1e1e1e1';

  hid_a      uuid;
  recipe_del uuid;
  recipe_keep uuid;
  plan_a     uuid;
  plan_next  uuid;

  del_entry      uuid;
  del_entry_next uuid;
  leftover_entry uuid;
  keep_entry     uuid;
  note_entry     uuid;

  week_1 date := date '2026-06-01';

  n         int;
  ts_before timestamptz;
  ts_after  timestamptz;
  failures  int := 0;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  delete from meal_plans where household_id in (
    select id from households where created_by = user_a);
  delete from recipes where title like 'zzz rdcp recipe%';
  delete from households where created_by = user_a;
  delete from auth.users where id = user_a;

  insert into auth.users (id, email) values (user_a, 'rdcp-a@example.com');

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select create_household('zzz rdcp household a') into hid_a;

  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid_a, 'zzz rdcp recipe sarma', 'sr', 'manual', user_a)
  returning id into recipe_del;

  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid_a, 'zzz rdcp recipe pasulj', 'sr', 'manual', user_a)
  returning id into recipe_keep;

  select ensure_meal_plan(hid_a, week_1) into plan_a;
  select ensure_meal_plan(hid_a, week_1 + 7) into plan_next;

  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_a, week_1, 'dinner', 'recipe', recipe_del)
  returning id into del_entry;

  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_next, week_1 + 9, 'lunch', 'recipe', recipe_del)
  returning id into del_entry_next;

  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 leftover_of_entry_id)
  values (plan_a, week_1 + 1, 'lunch', 'leftover', del_entry)
  returning id into leftover_entry;

  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_a, week_1 + 2, 'dinner', 'recipe', recipe_keep)
  returning id into keep_entry;

  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 note)
  values (plan_a, week_1, 'breakfast', 'note', 'zzz rdcp buy bread')
  returning id into note_entry;

  ---------------------------------------------------------------------------
  -- An update that does not stamp deleted_at removes nothing
  ---------------------------------------------------------------------------
  update recipes set rating = 4 where id = recipe_del;

  select count(*) into n from meal_plan_entries
  where id in (del_entry, del_entry_next, leftover_entry);
  if n <> 3 then
    failures := failures + 1;
    raise warning 'rating a recipe removed % of its 3 plan entries', 3 - n;
  end if;

  ---------------------------------------------------------------------------
  -- Soft-deleting the recipe clears it from every week
  ---------------------------------------------------------------------------
  -- Freeze and backdate so the touch-trigger assertion can see a change,
  -- same reasoning as rls_meal_plans_test.sql (now() is transaction time).
  perform set_config('role', 'postgres', true);
  execute 'alter table meal_plans disable trigger meal_plans_set_updated_at';
  perform set_config('role', 'authenticated', true);
  update meal_plans set updated_at = timestamptz '2020-01-01'
  where id in (plan_a, plan_next);
  perform set_config('role', 'postgres', true);
  execute 'alter table meal_plans enable trigger meal_plans_set_updated_at';
  perform set_config('role', 'authenticated', true);

  select updated_at into ts_before from meal_plans where id = plan_next;

  update recipes set deleted_at = now() where id = recipe_del;

  select count(*) into n from meal_plan_entries where recipe_id = recipe_del;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'soft-deleting a recipe left % of its plan entries behind', n;
  end if;

  select count(*) into n from meal_plan_entries where id = leftover_entry;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'soft-deleting a recipe left its leftover entry behind';
  end if;

  select count(*) into n from meal_plan_entries
  where id in (keep_entry, note_entry);
  if n <> 2 then
    failures := failures + 1;
    raise warning
      'soft-deleting one recipe removed % unrelated entries (another recipe, a note)',
      2 - n;
  end if;

  select updated_at into ts_after from meal_plans where id = plan_next;
  if ts_after <= ts_before then
    failures := failures + 1;
    raise warning
      'clearing a deleted recipe''s entries did not move the plan''s updated_at';
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  delete from meal_plans where household_id = hid_a;
  delete from recipes where title like 'zzz rdcp recipe%';
  delete from households where created_by = user_a;
  delete from auth.users where id = user_a;

  if failures > 0 then
    raise exception '% recipe delete / plan assertion(s) failed', failures;
  end if;

  raise notice 'recipe delete clears plan: all assertions passed';
end
$$;
