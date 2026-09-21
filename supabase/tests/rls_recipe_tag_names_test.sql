-- RLS/behaviour test: recipe_tag_names (Phase 6, part 1a).
--
-- Covers the table migration 21 added: its three policies (select, insert,
-- update -- copied verbatim from ingredient_names_select, plus the two write
-- policies 1b's translate-tags Edge Function will use), the trigger-
-- maintained updated_at, and the total unique index on
-- (tag_key, locale, coalesce(household_id, ...)).
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from the other test files (every single-hex-repeat
-- pattern 1-9/a-f is taken, as are a1a1.../b2b2..., c3c3.../d4d4...,
-- a7a7.../b8b8..., e5e5.../f6f6... and c9c9.../dadada...; this file uses
-- e2e2.../f3f3...).

do $$
declare
  user_a uuid := 'e2e2e2e2-e2e2-e2e2-e2e2-e2e2e2e2e2e2';
  user_b uuid := 'f3f3f3f3-f3f3-f3f3-f3f3-f3f3f3f3f3f3';

  hid_a uuid;
  hid_b uuid;
  row_id       uuid;
  global_id    uuid;

  n            int;
  got_error    boolean;
  ts_before    timestamptz;
  ts_after     timestamptz;
  failures     int := 0;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  delete from recipe_tag_names where name like 'zzz tag%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  insert into auth.users (id, email) values
    (user_a, 'tagnames-a@example.com'),
    (user_b, 'tagnames-b@example.com');

  ---------------------------------------------------------------------------
  -- A creates a household
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select create_household('zzz tag household a') into hid_a;

  ---------------------------------------------------------------------------
  -- B creates a second household, to prove isolation
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);
  select create_household('zzz tag household b') into hid_b;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  ---------------------------------------------------------------------------
  -- A member can insert and update its own household's rows
  ---------------------------------------------------------------------------
  insert into recipe_tag_names (tag_key, name, locale, household_id, source)
  values ('posno', 'zzz tag Lenten', 'en', hid_a, 'user')
  returning id into row_id;

  if row_id is null then
    failures := failures + 1;
    raise warning 'member insert into its own household returned no id';
  end if;

  update recipe_tag_names set name = 'zzz tag Lenten, revised'
  where id = row_id;

  select count(*) into n from recipe_tag_names
    where id = row_id and name = 'zzz tag Lenten, revised';
  if n <> 1 then
    failures := failures + 1;
    raise warning 'member update on its own household''s row did not apply';
  end if;

  ---------------------------------------------------------------------------
  -- A member cannot insert or update a global row (household_id null)
  ---------------------------------------------------------------------------
  got_error := false;
  begin
    insert into recipe_tag_names (tag_key, name, locale, household_id, source)
    values ('posno', 'zzz tag global attempt', 'sr', null, 'user');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a member inserted a global (household_id null) row';
  end if;

  ---------------------------------------------------------------------------
  -- A member cannot insert or update household B's rows
  ---------------------------------------------------------------------------
  got_error := false;
  begin
    insert into recipe_tag_names (tag_key, name, locale, household_id, source)
    values ('posno', 'zzz tag hijack', 'sr', hid_b, 'user');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'A inserted a row into household B';
  end if;

  ---------------------------------------------------------------------------
  -- Seed a global row as postgres, to test read-only global visibility
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  insert into recipe_tag_names (tag_key, name, locale, household_id, source)
  values ('kolac', 'zzz tag Cake', 'en', null, 'curated')
  returning id into global_id;
  perform set_config('role', 'authenticated', true);

  ---------------------------------------------------------------------------
  -- Both members can read the global row; only A can read A's row
  ---------------------------------------------------------------------------
  select count(*) into n from recipe_tag_names where id = global_id;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'A cannot read the global row';
  end if;

  select count(*) into n from recipe_tag_names where id = row_id;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'A cannot read its own row';
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  select count(*) into n from recipe_tag_names where id = global_id;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'B cannot read the global row';
  end if;

  select count(*) into n from recipe_tag_names where id = row_id;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'B (a non-member) can read household A''s row';
  end if;

  got_error := false;
  begin
    update recipe_tag_names set name = 'zzz tag hijacked'
    where id = row_id;
  exception when others then got_error := true;
  end;
  -- RLS filters rather than raises on a no-match UPDATE, so also assert the
  -- row is untouched rather than relying on an exception.
  select count(*) into n from recipe_tag_names
    where id = row_id and name = 'zzz tag hijacked';
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a non-member updated household A''s row';
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  ---------------------------------------------------------------------------
  -- The unique index rejects a second row for the same
  -- (tag_key, locale, household)
  ---------------------------------------------------------------------------
  got_error := false;
  begin
    insert into recipe_tag_names (tag_key, name, locale, household_id, source)
    values ('posno', 'zzz tag Lenten, again', 'en', hid_a, 'user');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning
      'a second row for the same (tag_key, locale, household) was accepted';
  end if;

  -- A different locale for the same tag_key/household is a distinct row and
  -- must be accepted.
  insert into recipe_tag_names (tag_key, name, locale, household_id, source)
  values ('posno', 'zzz tag Posno', 'sr', hid_a, 'user');

  select count(*) into n from recipe_tag_names
    where tag_key = 'posno' and household_id = hid_a;
  if n <> 2 then
    failures := failures + 1;
    raise warning
      'expected 2 rows (en + sr) for posno/household A, found %', n;
  end if;

  ---------------------------------------------------------------------------
  -- The trigger moves updated_at
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  execute 'alter table recipe_tag_names disable trigger recipe_tag_names_set_updated_at';
  perform set_config('role', 'authenticated', true);
  update recipe_tag_names set updated_at = timestamptz '2020-01-01'
    where id = row_id;
  perform set_config('role', 'postgres', true);
  execute 'alter table recipe_tag_names enable trigger recipe_tag_names_set_updated_at';
  perform set_config('role', 'authenticated', true);

  select updated_at into ts_before from recipe_tag_names where id = row_id;
  update recipe_tag_names set name = 'zzz tag Lenten, touched' where id = row_id;
  select updated_at into ts_after from recipe_tag_names where id = row_id;

  if ts_after <= ts_before then
    failures := failures + 1;
    raise warning
      'updating a row did not move updated_at (% -> %)', ts_before, ts_after;
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  set local role postgres;
  delete from recipe_tag_names where name like 'zzz tag%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  if failures > 0 then
    raise exception 'rls_recipe_tag_names_test: % assertion(s) failed', failures;
  end if;
  raise notice 'rls_recipe_tag_names_test: all assertions passed';
end;
$$;
