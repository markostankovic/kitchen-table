-- RLS test: meal_plans, meal_plan_entries (Phase 2, part 2).
--
-- Covers the two tables and the three functions migration 14 added:
-- ensure_meal_plan (D50's lazy creation and resurrection),
-- meal_plan_entries_before_write (position assignment, the week-boundary
-- guard, and the leftover visibility guard), and meal_plan_entries_touch_plan
-- (the parent updated_at signal the Phase 2 delta fetch needs).
--
-- One thing this file cannot assert honestly without help: the touch trigger
-- sets `updated_at = now()`, and `now()` is TRANSACTION time -- the whole file
-- is one transaction, so a naive "before vs after" comparison would compare
-- two identical timestamps and pass whether or not the trigger ran. The touch
-- assertion below disables the table's own updated_at trigger for one
-- statement, backdates the row by hand, re-enables it, and only then checks
-- that an entry write moved the timestamp forward.
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from the other test files (every single-hex-repeat
-- pattern 1-9/a-f is already taken across them; this file uses a1a1.../b2b2...).

do $$
declare
  user_a uuid := 'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1';
  user_b uuid := 'b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2';

  hid_a        uuid;
  hid_b        uuid;
  recipe_a     uuid;
  plan_a       uuid;
  plan_a_again uuid;
  plan_b       uuid;
  entry_1      uuid;
  entry_2      uuid;
  entry_3      uuid;

  week_1 date := date '2026-06-01';

  n           int;
  pos         int;
  dt          date;
  slt         text;
  ts_before   timestamptz;
  ts_after    timestamptz;
  got_error   boolean;
  got_sqlstate text;
  failures    int := 0;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  delete from meal_plans where household_id in (
    select id from households where created_by in (user_a, user_b));
  delete from recipes where title like 'zzz mp recipe%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  insert into auth.users (id, email) values
    (user_a, 'mealplan-a@example.com'),
    (user_b, 'mealplan-b@example.com');

  ---------------------------------------------------------------------------
  -- A creates a household and a recipe to plan with
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select create_household('zzz mp household a') into hid_a;

  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid_a, 'zzz mp recipe torta', 'sr', 'manual', user_a)
  returning id into recipe_a;

  ---------------------------------------------------------------------------
  -- ensure_meal_plan: idempotent, and its grants
  ---------------------------------------------------------------------------
  select ensure_meal_plan(hid_a, week_1) into plan_a;
  select ensure_meal_plan(hid_a, week_1) into plan_a_again;

  if plan_a is null or plan_a <> plan_a_again then
    failures := failures + 1;
    raise warning 'ensure_meal_plan is not idempotent for the same week';
  end if;

  select count(*) into n from meal_plans where household_id = hid_a;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'ensure_meal_plan created % rows for one week, expected 1', n;
  end if;

  select week_start into dt from meal_plans where id = plan_a;
  if dt <> week_1 then
    failures := failures + 1;
    raise warning 'meal_plans.week_start is %, expected %', dt, week_1;
  end if;

  if not exists (select 1 from meal_plans
                 where id = plan_a and created_by = user_a) then
    failures := failures + 1;
    raise warning 'meal_plans.created_by was not set to the caller';
  end if;

  -- A plain insert of the same (household_id, week_start) must still raise --
  -- the RPC is a convenience, not a relaxation of the constraint underneath.
  got_error := false;
  begin
    insert into meal_plans (household_id, week_start, created_by)
    values (hid_a, week_1, user_a);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a duplicate (household_id, week_start) insert was accepted';
  end if;

  if not has_function_privilege('authenticated',
       'ensure_meal_plan(uuid,date)', 'execute') then
    failures := failures + 1;
    raise warning 'authenticated cannot execute ensure_meal_plan';
  end if;

  if has_function_privilege('anon',
       'ensure_meal_plan(uuid,date)', 'execute') then
    failures := failures + 1;
    raise warning 'anon can execute ensure_meal_plan';
  end if;

  ---------------------------------------------------------------------------
  -- Entry writes and the position trigger
  ---------------------------------------------------------------------------
  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_a, week_1, 'lunch', 'recipe', recipe_a)
  returning id, position into entry_1, pos;
  if pos <> 0 then
    failures := failures + 1;
    raise warning 'first entry in an empty slot got position %, expected 0', pos;
  end if;

  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_a, week_1, 'lunch', 'recipe', recipe_a)
  returning id, position into entry_2, pos;
  if pos <> 1 then
    failures := failures + 1;
    raise warning 'second entry in the same slot got position %, expected 1', pos;
  end if;

  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 note)
  values (plan_a, week_1 + 1, 'breakfast', 'note', 'zzz mp buy bread')
  returning id, position into entry_3, pos;
  if pos <> 0 then
    failures := failures + 1;
    raise warning 'entry in a different slot got position %, expected 0', pos;
  end if;

  -- Moving entry_2 to a fresh slot recomputes its position at the new tail,
  -- not at whatever it held before.
  update meal_plan_entries
  set entry_date = week_1 + 2, slot = 'dinner'
  where id = entry_2;
  select position, entry_date, slot into pos, dt, slt
    from meal_plan_entries where id = entry_2;
  if pos <> 0 or dt <> week_1 + 2 or slt <> 'dinner' then
    failures := failures + 1;
    raise warning
      'moved entry landed at date=%, slot=%, position=% (expected %, dinner, 0)',
      dt, slt, pos, week_1 + 2;
  end if;

  -- An update that does NOT change (entry_date, slot) must not reshuffle the
  -- entry's position within the slot it already sits in.
  update meal_plan_entries set servings = 2 where id = entry_2;
  select position into pos from meal_plan_entries where id = entry_2;
  if pos <> 0 then
    failures := failures + 1;
    raise warning
      'a servings-only update moved position to % -- should be untouched', pos;
  end if;

  ---------------------------------------------------------------------------
  -- Check constraints -- each refusal isolated in its own block
  ---------------------------------------------------------------------------
  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind)
    values (plan_a, week_1, 'lunch', 'recipe');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'entry_kind=recipe with null recipe_id was accepted';
  end if;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind)
    values (plan_a, week_1, 'lunch', 'note');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'entry_kind=note with null note was accepted';
  end if;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind, note)
    values (plan_a, week_1, 'lunch', 'note', '   ');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'entry_kind=note with a blank note was accepted';
  end if;

  -- Exclusivity: a note must not also carry a recipe_id.
  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   note, recipe_id)
    values (plan_a, week_1, 'lunch', 'note', 'zzz mp note', recipe_a);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'entry_kind=note carrying a recipe_id was accepted';
  end if;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   recipe_id)
    values (plan_a, week_1, 'brunch', 'recipe', recipe_a);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'an invalid slot (''brunch'') was accepted';
  end if;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   recipe_id)
    values (plan_a, week_1, 'lunch', 'meal', recipe_a);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'an invalid entry_kind (''meal'') was accepted';
  end if;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   recipe_id, servings)
    values (plan_a, week_1, 'lunch', 'recipe', recipe_a, 0);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'servings=0 was accepted';
  end if;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind)
    values (plan_a, week_1, 'snack', 'leftover');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'entry_kind=leftover with null leftover_of_entry_id was accepted';
  end if;

  -- The leftover branch ships live (D51): pointing at a real, visible entry
  -- must be accepted even though nothing writes this yet.
  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   leftover_of_entry_id)
    values (plan_a, week_1, 'snack', 'leftover', entry_1);
  exception when others then got_error := true;
  end;
  if got_error then
    failures := failures + 1;
    raise warning 'a leftover entry pointing at a visible source was refused';
  end if;
  delete from meal_plan_entries
    where meal_plan_id = plan_a and entry_kind = 'leftover';

  ---------------------------------------------------------------------------
  -- The week-boundary guard
  ---------------------------------------------------------------------------
  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   recipe_id)
    values (plan_a, week_1 - 1, 'lunch', 'recipe', recipe_a);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'an entry_date before week_start was accepted';
  end if;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   recipe_id)
    values (plan_a, week_1 + 7, 'lunch', 'recipe', recipe_a);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'an entry_date on the following Monday was accepted';
  end if;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   recipe_id)
    values (plan_a, week_1 + 6, 'lunch', 'recipe', recipe_a);
  exception when others then got_error := true;
  end;
  if got_error then
    failures := failures + 1;
    raise warning 'an entry_date on the week''s last day (Sunday) was refused';
  end if;
  delete from meal_plan_entries where meal_plan_id = plan_a
    and entry_date = week_1 + 6;

  ---------------------------------------------------------------------------
  -- The parent touch trigger -- now() is transaction time, so freeze and
  -- backdate updated_at by hand rather than compare two identical timestamps.
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  execute 'alter table meal_plans disable trigger meal_plans_set_updated_at';
  perform set_config('role', 'authenticated', true);
  update meal_plans set updated_at = timestamptz '2020-01-01' where id = plan_a;
  perform set_config('role', 'postgres', true);
  execute 'alter table meal_plans enable trigger meal_plans_set_updated_at';
  perform set_config('role', 'authenticated', true);

  select updated_at into ts_before from meal_plans where id = plan_a;

  insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                 recipe_id)
  values (plan_a, week_1, 'dinner', 'recipe', recipe_a);

  select updated_at into ts_after from meal_plans where id = plan_a;
  if ts_after <= ts_before then
    failures := failures + 1;
    raise warning
      'inserting an entry did not move the plan''s updated_at (% -> %)',
      ts_before, ts_after;
  end if;

  -- now() is fixed for the whole transaction, so the insert above already
  -- consumed that frozen value -- backdate again before checking the delete.
  perform set_config('role', 'postgres', true);
  execute 'alter table meal_plans disable trigger meal_plans_set_updated_at';
  perform set_config('role', 'authenticated', true);
  update meal_plans set updated_at = timestamptz '2020-01-01' where id = plan_a;
  perform set_config('role', 'postgres', true);
  execute 'alter table meal_plans enable trigger meal_plans_set_updated_at';
  perform set_config('role', 'authenticated', true);

  select updated_at into ts_before from meal_plans where id = plan_a;

  delete from meal_plan_entries
    where meal_plan_id = plan_a and slot = 'dinner' and entry_date = week_1;
  select updated_at into ts_after from meal_plans where id = plan_a;
  if ts_after <= ts_before then
    failures := failures + 1;
    raise warning 'deleting an entry did not move the plan''s updated_at';
  end if;

  ---------------------------------------------------------------------------
  -- Cascade shape: the FKs a deleted plan or a deleted entry must sweep
  ---------------------------------------------------------------------------
  if not exists (
    select 1 from pg_constraint c
    join pg_class cl on cl.oid = c.conrelid
    where cl.relname = 'meal_plan_entries'
      and c.contype = 'f'
      and c.confrelid = 'meal_plans'::regclass
      and c.confdeltype = 'c'
  ) then
    failures := failures + 1;
    raise warning 'meal_plan_entries.meal_plan_id is not ON DELETE CASCADE';
  end if;

  if not exists (
    select 1 from pg_constraint c
    join pg_class cl on cl.oid = c.conrelid
    where cl.relname = 'meal_plan_entries'
      and c.contype = 'f'
      and c.confrelid = 'meal_plan_entries'::regclass
      and c.confdeltype = 'c'
  ) then
    failures := failures + 1;
    raise warning 'meal_plan_entries.leftover_of_entry_id is not ON DELETE CASCADE';
  end if;

  ---------------------------------------------------------------------------
  -- B is in no household and must see and touch nothing of A's
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  select count(*) into n from meal_plans where id = plan_a;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a non-member can see another household''s meal plan';
  end if;

  select count(*) into n from meal_plan_entries where meal_plan_id = plan_a;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a non-member can read entries through the child table';
  end if;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   recipe_id)
    values (plan_a, week_1, 'lunch', 'recipe', recipe_a);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a non-member inserted an entry onto another household''s plan';
  end if;

  -- ensure_meal_plan must refuse with the membership error (42501), not fall
  -- through to the unique constraint (23505) -- a wrong error code here would
  -- mean the guard is not actually running before the insert.
  got_error := false;
  got_sqlstate := null;
  begin
    perform ensure_meal_plan(hid_a, week_1);
  exception when others then
    got_error := true;
    got_sqlstate := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a non-member called ensure_meal_plan on another household''s plan';
  elsif got_sqlstate <> '42501' then
    failures := failures + 1;
    raise warning
      'ensure_meal_plan refused a non-member with sqlstate % instead of 42501',
      got_sqlstate;
  end if;

  -- Neither the UPDATE nor the DELETE below is expected to raise: the
  -- policy's `using` clause hides the row from B entirely, so both statements
  -- affect zero rows silently, exactly like the recipes test's own
  -- non-member case. The real assertion is the unchanged-state re-check
  -- further down, once A can see the row again.
  update meal_plan_entries set servings = 4 where id = entry_1;
  delete from meal_plan_entries where id = entry_1;

  -- A leftover pointing at A's entry, written from B's own household, must
  -- be refused: the visibility guard is is_household_member for free.
  select create_household('zzz mp household b') into hid_b;
  select ensure_meal_plan(hid_b, week_1) into plan_b;

  -- B's own household planning the SAME calendar week as A must succeed --
  -- the unique constraint is per household, not global. Checked now, while
  -- still impersonating B: RLS would hide hid_b's plan from A below.
  select count(*) into n from meal_plans
    where household_id = hid_b and week_start = week_1;
  if n <> 1 then
    failures := failures + 1;
    raise warning
      'B could not plan the same week_start A already has (unique index too broad?)';
  end if;

  got_error := false;
  begin
    insert into meal_plan_entries (meal_plan_id, entry_date, slot, entry_kind,
                                   leftover_of_entry_id)
    values (plan_b, week_1, 'snack', 'leftover', entry_1);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning
      'B linked a leftover to an entry from a household B does not belong to';
  end if;

  -- The refusals above must not have been silent no-ops.
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  if not exists (select 1 from meal_plan_entries
                 where id = entry_1 and servings is null) then
    failures := failures + 1;
    raise warning 'entry_1.servings was disturbed by B''s update attempt';
  end if;

  if not exists (select 1 from meal_plan_entries where id = entry_1) then
    failures := failures + 1;
    raise warning 'entry_1 was removed by B''s delete attempt';
  end if;

  ---------------------------------------------------------------------------
  -- Soft delete and rule 4, back as A
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  update meal_plans set deleted_at = now() where id = plan_a;

  select count(*) into n from meal_plans where id = plan_a;
  if n <> 1 then
    failures := failures + 1;
    raise warning
      'a soft-deleted meal plan vanished from RLS -- Phase 2 could never evict it';
  end if;

  -- D50: the next write into that week resurrects the same row.
  select ensure_meal_plan(hid_a, week_1) into plan_a_again;
  if plan_a_again <> plan_a then
    failures := failures + 1;
    raise warning
      'ensure_meal_plan created a second row instead of resurrecting the '
      'soft-deleted one';
  end if;

  if exists (select 1 from meal_plans where id = plan_a and deleted_at is not null) then
    failures := failures + 1;
    raise warning 'ensure_meal_plan did not clear deleted_at on resurrection';
  end if;

  select count(*) into n from meal_plans
    where household_id = hid_a and week_start = week_1;
  if n <> 1 then
    failures := failures + 1;
    raise warning
      'resurrecting week_1 left % rows instead of exactly one', n;
  end if;

  -- There is no DELETE policy on meal_plans: a hard delete must remove nothing.
  delete from meal_plans where id = plan_a;
  select count(*) into n from meal_plans where id = plan_a;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'a hard delete of a meal plan succeeded (rule 4)';
  end if;

  -- meal_plan_entries DOES get a delete policy (D24: no household_id of its
  -- own, cascades with its plan) -- a hard delete of an entry must succeed.
  delete from meal_plan_entries where id = entry_3;
  select count(*) into n from meal_plan_entries where id = entry_3;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a hard delete of a meal plan entry was refused';
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  delete from meal_plans where household_id in (hid_a, hid_b);
  delete from recipes where title like 'zzz mp recipe%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  if failures > 0 then
    raise exception '% meal plan RLS assertion(s) failed', failures;
  end if;

  raise notice 'meal plan RLS: all assertions passed';
end
$$;
