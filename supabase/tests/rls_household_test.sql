-- RLS test: identity and households (Phase 1a).
--
-- Phase 1a's acceptance criterion is "two accounts on two devices are in one
-- household, and each can see a row the other created" (docs/ROADMAP.md).
-- That is a statement about RLS, not about devices, so it is tested here
-- rather than by driving two emulators: this is deterministic, runs in a
-- second, and actually covers the negative cases a manual check never would.
--
-- Run: make test-sql
--
-- Uses fixed UUIDs so a run that aborts mid-way is cleaned up by the next one.

do $$
declare
  -- Fixed so cleanup is deterministic across failed runs.
  user_a uuid := '11111111-1111-1111-1111-111111111111';
  user_b uuid := '22222222-2222-2222-2222-222222222222';
  user_c uuid := '33333333-3333-3333-3333-333333333333';

  hid       uuid;
  n         int;
  failures  int := 0;
  got_error boolean;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  delete from households where created_by in (user_a, user_b, user_c);
  delete from auth.users where id in (user_a, user_b, user_c);

  insert into auth.users (id, email) values
    (user_a, 'a@example.com'),
    (user_b, 'b@example.com'),
    (user_c, 'c@example.com');

  -- The on_auth_user_created trigger should have made three profiles.
  select count(*) into n from profiles where id in (user_a, user_b, user_c);
  if n <> 3 then
    failures := failures + 1;
    raise warning 'expected 3 auto-created profiles, got %', n;
  end if;

  -- display_name should be seeded from the email local-part.
  select count(*) into n
    from profiles where id = user_a and display_name = 'a';
  if n <> 1 then
    failures := failures + 1;
    raise warning 'profile display_name not seeded from email local-part';
  end if;

  ---------------------------------------------------------------------------
  -- User A creates a household
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select create_household('Test Household') into hid;

  select count(*) into n from households where id = hid;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'A cannot see the household they just created';
  end if;

  -- create_household must have made A an owner, atomically.
  select count(*) into n
    from household_members where household_id = hid and user_id = user_a
      and role = 'owner';
  if n <> 1 then
    failures := failures + 1;
    raise warning 'create_household did not create the owner membership';
  end if;

  -- Still just A's own profile. profiles_select_co_member is in force by now
  -- (migration 3), but A is in a household with nobody yet, so it adds nothing
  -- to profiles_select_own. B joins further down; the co-member count is
  -- asserted there.
  select count(*) into n from profiles;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'A alone in a household should see 1 profile (own), saw %', n;
  end if;

  ---------------------------------------------------------------------------
  -- A cannot insert a membership directly (no INSERT policy)
  ---------------------------------------------------------------------------
  got_error := false;
  begin
    insert into household_members (household_id, user_id, role)
    values (hid, user_b, 'adult');
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'A was able to insert a membership directly; '
                  'household_members must have no INSERT policy';
  end if;

  ---------------------------------------------------------------------------
  -- Add B as a member (as the service role would)
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);

  insert into household_members (household_id, user_id, role)
  values (hid, user_b, 'adult');

  ---------------------------------------------------------------------------
  -- THE CRITERION: B sees the household and the row A created
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  select count(*) into n from households where id = hid;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'B cannot see the household A created';
  end if;

  select count(*) into n from household_members where household_id = hid;
  if n <> 2 then
    failures := failures + 1;
    raise warning 'B should see both membership rows, saw %', n;
  end if;

  -- Co-member profile visibility (migration 3). Without it the member list
  -- renders every co-member as "Unknown", because the join to profiles returns
  -- nothing. B should now see exactly two profiles: their own, and A's.
  select count(*) into n from profiles;
  if n <> 2 then
    failures := failures + 1;
    raise warning 'B should see 2 profiles (own + co-member A), saw %', n;
  end if;

  select count(*) into n
    from profiles where id = user_a and display_name = 'a';
  if n <> 1 then
    failures := failures + 1;
    raise warning 'B cannot read co-member A''s display_name';
  end if;

  ---------------------------------------------------------------------------
  -- Non-member C sees nothing
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_c, 'role', 'authenticated')::text, true);

  select count(*) into n from households where id = hid;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'non-member C can see the household';
  end if;

  select count(*) into n from household_members where household_id = hid;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'non-member C can see membership rows';
  end if;

  -- C is in no household, so shares_household_with matches nobody and
  -- profiles_select_own is all that applies. If this ever returns 3, the
  -- co-member policy is matching on something other than shared membership.
  select count(*) into n from profiles;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'non-member C should see 1 profile (own), saw %', n;
  end if;

  -- C must not be able to rename someone else's household.
  update households set name = 'Hijacked' where id = hid;
  get diagnostics n = row_count;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'non-member C was able to update the household';
  end if;

  ---------------------------------------------------------------------------
  -- D23: a soft-deleted household stays VISIBLE to members
  ---------------------------------------------------------------------------
  -- The Phase 2 delta fetch evicts cache entries by seeing deleted_at set. If
  -- a policy ever regains `and deleted_at is null`, this is what catches it.
  perform set_config('role', 'postgres', true);
  update households set deleted_at = now() where id = hid;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select count(*) into n from households where id = hid;
  if n <> 1 then
    failures := failures + 1;
    raise warning
      'soft-deleted household is invisible to a member -- Phase 2 delta sync '
      'cannot evict what it cannot see (D23)';
  end if;

  ---------------------------------------------------------------------------
  -- The updated_at trigger overrides whatever the caller supplies
  ---------------------------------------------------------------------------
  -- Note this cannot be tested as `updated_at > created_at`: now() is the
  -- transaction timestamp, so every row written in one transaction shares it.
  -- Instead, hand the trigger a value it must refuse to keep.
  perform set_config('role', 'postgres', true);
  update households set updated_at = timestamptz '2000-01-01' where id = hid;

  select count(*) into n
    from households where id = hid and updated_at = timestamptz '2000-01-01';
  if n <> 0 then
    failures := failures + 1;
    raise warning
      'updated_at trigger did not fire: a caller-supplied value survived';
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  delete from households where created_by in (user_a, user_b, user_c);
  delete from auth.users where id in (user_a, user_b, user_c);

  if failures > 0 then
    raise exception '% household RLS assertion(s) failed', failures;
  end if;

  raise notice 'household RLS: all assertions passed';
end
$$;
