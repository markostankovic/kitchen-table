-- RLS/behaviour test: leftovers, the reorder RPC (Phase 2, part 3).
--
-- Covers the two functions migration 15 added: meal_plan_entries_leftover_
-- source (D55's derived recipe_id, and the refusals around it) and
-- reorder_meal_plan_entry (D57's within-slot renumbering).
--
-- Same now()-is-transaction-time caveat as rls_meal_plans_test.sql applies to
-- the touch-trigger assertion below; the same freeze/backdate dance is used.
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from the other test files (every single-hex-repeat
-- pattern 1-9/a-f is already taken, and so are a1a1.../b2b2... from
-- rls_meal_plans_test.sql; this file uses c3c3.../d4d4...).

do $$
declare
  user_a uuid := 'c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3';
  user_b uuid := 'd4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4';

  hid_a     uuid;
  hid_b     uuid;
  recipe_a  uuid;
  plan_a    uuid;
  plan_b    uuid;
  plan_next uuid;

  source_entry   uuid;
  note_entry     uuid;
  leftover_entry uuid;
  e1 uuid;
  e2 uuid;
  e3 uuid;

  week_1 date := date '2026-06-01';

  n            int;
  pos          int;
  rid          uuid;
  ts_before    timestamptz;
  ts_after     timestamptz;
  got_error    boolean;
  got_sqlstate text;
  failures     int := 0;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  delete from meal_plans where household_id in (
    select id from households where created_by in (user_a, user_b));
  delete from recipes where title like 'zzz mpl recipe%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  insert into auth.users (id, email) values
    (user_a, 'mplfovers-a@example.com'),
    (user_b, 'mplfovers-b@example.com');

  ---------------------------------------------------------------------------
  -- A creates a household, a recipe, and a plan with a recipe entry to be
  -- the leftover source, plus a note entry to test the refusal against.
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select create_household('zzz mpl household a') into hid_a;

  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid_a, 'zzz mpl recipe sarma', 'sr', 'manual', user_a)
  returning id into recipe_a;

  select ensure_meal_plan(hid_a, week_1) into plan_a;

  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_a, week_1, 'dinner', 'recipe', recipe_a)
  returning id into source_entry;

  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 note)
  values (plan_a, week_1, 'breakfast', 'note', 'zzz mpl buy bread')
  returning id into note_entry;

  ---------------------------------------------------------------------------
  -- meal_plan_entries_leftover_source: recipe_id is derived, not trusted
  ---------------------------------------------------------------------------

  -- A client sending a DIFFERENT recipe_id must be overridden by the trigger,
  -- not merely tolerated -- this is the derivation itself, not the happy path.
  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 leftover_of_entry_id, recipe_id)
  values (plan_a, week_1 + 1, 'lunch', 'leftover', source_entry,
          '00000000-0000-0000-0000-000000000000')
  returning id, recipe_id into leftover_entry, rid;

  if rid is distinct from recipe_a then
    failures := failures + 1;
    raise warning
      'leftover recipe_id was %, expected % (source''s own) -- client value was not overridden',
      rid, recipe_a;
  end if;

  delete from meal_plan_entries where id = leftover_entry;

  -- A leftover pointing at a note is refused.
  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   leftover_of_entry_id)
    values (plan_a, week_1 + 1, 'lunch', 'leftover', note_entry);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a leftover pointing at a note entry was accepted';
  end if;

  -- A leftover pointing at another leftover is refused (no chains).
  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 leftover_of_entry_id)
  values (plan_a, week_1 + 1, 'lunch', 'leftover', source_entry)
  returning id into leftover_entry;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   leftover_of_entry_id)
    values (plan_a, week_1 + 2, 'lunch', 'leftover', leftover_entry);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a leftover pointing at another leftover was accepted (a chain)';
  end if;

  -- A leftover pointing at an invisible entry is refused with 23503.
  got_error := false;
  got_sqlstate := null;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   leftover_of_entry_id)
    values (plan_a, week_1 + 2, 'lunch', 'leftover',
            '00000000-0000-0000-0000-000000000000');
  exception when others then
    got_error := true;
    got_sqlstate := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a leftover pointing at a non-existent entry was accepted';
  elsif got_sqlstate <> '23503' then
    failures := failures + 1;
    raise warning
      'a leftover with an invisible source raised sqlstate % instead of 23503',
      got_sqlstate;
  end if;

  -- Deleting the source cascades to the leftover (migration 14's FK).
  delete from meal_plan_entries where id = source_entry;
  select count(*) into n from meal_plan_entries where id = leftover_entry;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'deleting a leftover''s source did not cascade-delete it';
  end if;

  ---------------------------------------------------------------------------
  -- Cross-week leftover: source in this week's plan, leftover in next week's
  ---------------------------------------------------------------------------
  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_a, week_1 + 6, 'dinner', 'recipe', recipe_a)
  returning id into source_entry;

  select ensure_meal_plan(hid_a, week_1 + 7) into plan_next;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   leftover_of_entry_id)
    values (plan_next, week_1 + 8, 'lunch', 'leftover', source_entry)
    returning id into leftover_entry;
  exception when others then got_error := true;
  end;
  if got_error then
    failures := failures + 1;
    raise warning
      'a leftover in the following week''s plan, pointing at this week''s entry, was refused';
  end if;

  if not exists (select 1 from meal_plan_entries
                 where id = leftover_entry and recipe_id = recipe_a) then
    failures := failures + 1;
    raise warning 'the cross-week leftover did not carry the source''s recipe_id';
  end if;

  ---------------------------------------------------------------------------
  -- reorder_meal_plan_entry
  ---------------------------------------------------------------------------
  delete from meal_plan_entries where meal_plan_id = plan_a and slot = 'snack';

  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_a, week_1 + 3, 'snack', 'recipe', recipe_a)
  returning id into e1;
  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_a, week_1 + 3, 'snack', 'recipe', recipe_a)
  returning id into e2;
  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_a, week_1 + 3, 'snack', 'recipe', recipe_a)
  returning id into e3;
  -- e1=0, e2=1, e3=2 at this point (tail assignment).

  -- Also seed a sibling slot to prove it stays untouched.
  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_a, week_1 + 3, 'lunch', 'recipe', recipe_a);

  perform reorder_meal_plan_entry(e3, 0);

  select position into pos from meal_plan_entries where id = e3;
  if pos <> 0 then
    failures := failures + 1;
    raise warning 'moving the last entry to 0 landed it at %, expected 0', pos;
  end if;

  select position into pos from meal_plan_entries where id = e1;
  if pos <> 1 then
    failures := failures + 1;
    raise warning 'sibling e1 ended at %, expected 1 after the splice', pos;
  end if;

  select position into pos from meal_plan_entries where id = e2;
  if pos <> 2 then
    failures := failures + 1;
    raise warning 'sibling e2 ended at %, expected 2 after the splice', pos;
  end if;

  -- Order is now e3, e1, e2 (positions 0, 1, 2). Assert no duplicate and no
  -- gap across the whole group.
  select count(distinct position) into n from meal_plan_entries
    where meal_plan_id = plan_a and entry_date = week_1 + 3 and slot = 'snack';
  if n <> 3 then
    failures := failures + 1;
    raise warning
      'snack group has % distinct positions after reorder, expected 3', n;
  end if;

  -- Clamping: a negative target lands at 0, an overlarge one at the tail.
  perform reorder_meal_plan_entry(e2, -5);
  select position into pos from meal_plan_entries where id = e2;
  if pos <> 0 then
    failures := failures + 1;
    raise warning 'reordering to -5 landed at %, expected clamp to 0', pos;
  end if;

  perform reorder_meal_plan_entry(e2, 99);
  select position into pos from meal_plan_entries where id = e2;
  if pos <> 2 then
    failures := failures + 1;
    raise warning 'reordering to 99 landed at %, expected clamp to 2 (tail)', pos;
  end if;

  -- The sibling lunch slot must be untouched by any of the above.
  select count(*) into n from meal_plan_entries
    where meal_plan_id = plan_a and entry_date = week_1 + 3 and slot = 'lunch'
      and position <> 0;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'reordering the snack slot disturbed positions in the lunch slot';
  end if;

  -- The touch trigger fires on the reorder's UPDATE -- freeze and backdate,
  -- same reasoning as rls_meal_plans_test.sql (now() is transaction time).
  perform set_config('role', 'postgres', true);
  execute 'alter table meal_plans disable trigger meal_plans_set_updated_at';
  perform set_config('role', 'authenticated', true);
  update meal_plans set updated_at = timestamptz '2020-01-01' where id = plan_a;
  perform set_config('role', 'postgres', true);
  execute 'alter table meal_plans enable trigger meal_plans_set_updated_at';
  perform set_config('role', 'authenticated', true);

  select updated_at into ts_before from meal_plans where id = plan_a;
  perform reorder_meal_plan_entry(e1, 0);
  select updated_at into ts_after from meal_plans where id = plan_a;
  if ts_after <= ts_before then
    failures := failures + 1;
    raise warning 'reordering an entry did not move the plan''s updated_at';
  end if;

  if not has_function_privilege('authenticated',
       'reorder_meal_plan_entry(uuid,int)', 'execute') then
    failures := failures + 1;
    raise warning 'authenticated cannot execute reorder_meal_plan_entry';
  end if;

  if has_function_privilege('anon',
       'reorder_meal_plan_entry(uuid,int)', 'execute') then
    failures := failures + 1;
    raise warning 'anon can execute reorder_meal_plan_entry';
  end if;

  ---------------------------------------------------------------------------
  -- B is in no household and must be refused, not silently no-op'd
  ---------------------------------------------------------------------------
  select create_household('zzz mpl household b') into hid_b;
  select ensure_meal_plan(hid_b, week_1) into plan_b;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  got_error := false;
  got_sqlstate := null;
  begin
    perform reorder_meal_plan_entry(e1, 1);
  exception when others then
    got_error := true;
    got_sqlstate := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'B reordered an entry belonging to another household''s plan';
  elsif got_sqlstate <> '42501' then
    failures := failures + 1;
    raise warning
      'reorder_meal_plan_entry refused a non-member with sqlstate % instead of 42501',
      got_sqlstate;
  end if;

  -- A leftover pointing at A's entry, written from B's own household's plan,
  -- must be refused: the visibility guard is is_household_member for free.
  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   leftover_of_entry_id)
    values (plan_b, week_1, 'snack', 'leftover', e1);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning
      'B linked a leftover to an entry from a household B does not belong to';
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  delete from meal_plans where household_id in (hid_a, hid_b);
  delete from recipes where title like 'zzz mpl recipe%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  if failures > 0 then
    raise exception '% meal plan leftover/reorder assertion(s) failed', failures;
  end if;

  raise notice 'meal plan leftovers/reorder: all assertions passed';
end
$$;
