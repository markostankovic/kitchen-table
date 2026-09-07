-- RLS test: household invites (Phase 1a, second slice).
--
-- Covers the invites table's policies, the partial unique index that makes a
-- code single-use, and the conditional UPDATE that redeem-invite issues to
-- claim one. The Edge Functions themselves are glue; this is the part of them
-- that can actually be wrong, so it is tested here rather than by curl.
--
-- Run: make test-sql
--
-- Uses fixed UUIDs, distinct from rls_household_test.sql so the two files do
-- not clean up each other's rows.

do $$
declare
  user_a uuid := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  user_b uuid := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  user_c uuid := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  user_d uuid := 'dddddddd-dddd-dddd-dddd-dddddddddddd';

  hid       uuid;
  hid2      uuid;
  invite    uuid;
  n         int;
  failures  int := 0;
  got_error boolean;
  claimed   boolean;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  -- Order matters: household_invites.created_by / used_by reference profiles
  -- with no ON DELETE action, and profiles cascades from auth.users. Deleting
  -- the households first cascades the invites away; deleting the users first
  -- would be restricted by the surviving invite rows.
  delete from households where created_by in (user_a, user_b, user_c, user_d);
  delete from auth.users where id in (user_a, user_b, user_c, user_d);

  insert into auth.users (id, email) values
    (user_a, 'inv-a@example.com'),
    (user_b, 'inv-b@example.com'),
    (user_c, 'inv-c@example.com'),
    (user_d, 'inv-d@example.com');

  ---------------------------------------------------------------------------
  -- A creates a household; the service role mints an invite for it
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select create_household('Invite Test Household') into hid;

  perform set_config('role', 'postgres', true);

  insert into household_invites (household_id, code, created_by, expires_at)
  values (hid, '111111', user_a, now() + interval '7 days')
  returning id into invite;

  ---------------------------------------------------------------------------
  -- Members can read invites; non-members cannot
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select count(*) into n from household_invites where household_id = hid;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'A cannot see the invite for their own household';
  end if;

  -- A member who did NOT create the invite must still be able to read it:
  -- the household screen re-shows a code generated on another device.
  perform set_config('role', 'postgres', true);
  insert into household_members (household_id, user_id, role)
  values (hid, user_b, 'adult');

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  select count(*) into n from household_invites where household_id = hid;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'member B cannot see an invite they did not create';
  end if;

  -- A prospective member is not a member yet. This is what stops PostgREST
  -- from being an invite-code enumeration endpoint.
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_c, 'role', 'authenticated')::text, true);

  select count(*) into n from household_invites;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'non-member C can see % invite(s)', n;
  end if;

  ---------------------------------------------------------------------------
  -- Clients cannot write invites at all
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  got_error := false;
  begin
    insert into household_invites (household_id, code, created_by, expires_at)
    values (hid, '999999', user_a, now() + interval '7 days');
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a member was able to insert an invite directly; '
                  'household_invites must have no INSERT policy';
  end if;

  -- No UPDATE policy means the row is invisible to the update rather than the
  -- update raising -- so this asserts on row_count, not on an exception.
  update household_invites set used_at = now(), used_by = user_a
    where id = invite;
  get diagnostics n = row_count;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a member was able to redeem an invite client-side';
  end if;

  ---------------------------------------------------------------------------
  -- The partial unique index
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);

  -- A live code is unique.
  got_error := false;
  begin
    insert into household_invites (household_id, code, created_by, expires_at)
    values (hid, '111111', user_a, now() + interval '7 days');
  exception when unique_violation then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a duplicate LIVE code was accepted';
  end if;

  -- ...but once consumed, the code is released. This is the assertion that
  -- proves the `where used_at is null` predicate is right; a refactor that
  -- "simplifies" the index to a plain unique constraint breaks exactly here.
  update household_invites set used_by = user_b, used_at = now()
    where id = invite;

  got_error := false;
  begin
    insert into household_invites (household_id, code, created_by, expires_at)
    values (hid, '111111', user_a, now() + interval '7 days');
  exception when unique_violation then
    got_error := true;
  end;
  if got_error then
    failures := failures + 1;
    raise warning 'a code was still reserved after its invite was consumed';
  end if;

  -- used_by and used_at must move together.
  got_error := false;
  begin
    insert into household_invites
      (household_id, code, created_by, expires_at, used_at)
    values (hid, '444444', user_a, now() + interval '7 days', now());
  exception when check_violation then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'half a redemption stamp was accepted (used_at without used_by)';
  end if;

  ---------------------------------------------------------------------------
  -- The atomic claim, exactly as redeem-invite issues it
  ---------------------------------------------------------------------------
  -- A true two-session race cannot be expressed inside one do-block, but the
  -- guard's semantics are what the concurrency argument rests on: the second
  -- attempt must claim zero rows, not overwrite the first.
  delete from household_invites where household_id = hid;
  insert into household_invites (household_id, code, created_by, expires_at)
  values (hid, '222222', user_a, now() + interval '7 days');

  update household_invites set used_by = user_c, used_at = now()
    where code = '222222' and used_at is null and expires_at > now();
  get diagnostics n = row_count;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the first claim of a live invite affected % rows, want 1', n;
  end if;

  update household_invites set used_by = user_d, used_at = now()
    where code = '222222' and used_at is null and expires_at > now();
  get diagnostics n = row_count;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a second claim of the same invite affected % rows, want 0', n;
  end if;

  select used_by = user_c into claimed
    from household_invites where code = '222222';
  if not claimed then
    failures := failures + 1;
    raise warning 'the losing claimant overwrote used_by';
  end if;

  -- An expired invite fails the claim but stays readable, so the Edge Function
  -- can tell "expired" apart from "never existed" and say so.
  insert into household_invites (household_id, code, created_by, expires_at)
  values (hid, '333333', user_a, now() - interval '1 day');

  update household_invites set used_by = user_c, used_at = now()
    where code = '333333' and used_at is null and expires_at > now();
  get diagnostics n = row_count;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'an expired invite was claimable';
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select count(*) into n from household_invites where code = '333333';
  if n <> 1 then
    failures := failures + 1;
    raise warning 'an expired invite is invisible to a member';
  end if;

  ---------------------------------------------------------------------------
  -- shares_household_with and co-member profile visibility
  ---------------------------------------------------------------------------
  -- D is put in a SEPARATE household, so the co-member counts below prove the
  -- policy matches on shared membership rather than on "is in any household".
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_d, 'role', 'authenticated')::text, true);
  select create_household('Other Household') into hid2;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  if not shares_household_with(user_b) then
    failures := failures + 1;
    raise warning 'A and B share a household but shares_household_with said no';
  end if;

  if shares_household_with(user_c) then
    failures := failures + 1;
    raise warning 'A and non-member C do not share a household but '
                  'shares_household_with said yes';
  end if;

  if shares_household_with(user_d) then
    failures := failures + 1;
    raise warning 'A and D are in different households but '
                  'shares_household_with said yes';
  end if;

  -- A sees own + B. Not C (no household), not D (a different one).
  select count(*) into n from profiles;
  if n <> 2 then
    failures := failures + 1;
    raise warning 'A should see 2 profiles (own + co-member B), saw %', n;
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  delete from households where created_by in (user_a, user_b, user_c, user_d);
  delete from auth.users where id in (user_a, user_b, user_c, user_d);

  if failures > 0 then
    raise exception '% invite RLS assertion(s) failed', failures;
  end if;

  raise notice 'invite RLS: all assertions passed';
end
$$;
