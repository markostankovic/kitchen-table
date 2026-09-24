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
  -- phase6-part3c: delete_household gets its own household and its own
  -- owner/adult pair, so it does not interfere with hid (used by the D23
  -- assertion and by teardown).
  user_d uuid := '44444444-4444-4444-4444-444444444444';
  user_e uuid := '55555555-5555-5555-5555-555555555555';

  hid       uuid;
  hid2      uuid;
  hid3      uuid;
  invite2   uuid;
  n         int;
  failures  int := 0;
  got_error boolean;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  delete from households where created_by in (user_a, user_b, user_c, user_d, user_e);
  delete from auth.users where id in (user_a, user_b, user_c, user_d, user_e);

  insert into auth.users (id, email) values
    (user_a, 'a@example.com'),
    (user_b, 'b@example.com'),
    (user_c, 'c@example.com'),
    (user_d, 'd@example.com'),
    (user_e, 'e@example.com');

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
  -- D112: rename is open to any member, not just the owner -- B (adult) and
  -- A (owner) can both rename the household they belong to.
  ---------------------------------------------------------------------------
  -- B's JWT is still active from the block above.
  update households set name = 'Renamed by B' where id = hid;
  get diagnostics n = row_count;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'B (adult) could not rename the household, row_count=%', n;
  end if;

  select count(*) into n
    from households where id = hid and name = 'Renamed by B';
  if n <> 1 then
    failures := failures + 1;
    raise warning 'B (adult) renamed the household but the name did not stick';
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  update households set name = 'Renamed by A' where id = hid;
  get diagnostics n = row_count;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'A (owner) could not rename the household, row_count=%', n;
  end if;

  select count(*) into n
    from households where id = hid and name = 'Renamed by A';
  if n <> 1 then
    failures := failures + 1;
    raise warning 'A (owner) renamed the household but the name did not stick';
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
  -- phase6-part3b: remove_household_member / leave_household
  ---------------------------------------------------------------------------
  -- Membership at this point: A (owner), B (adult). C is not a member.

  -- An adult cannot remove anyone -- not even the owner.
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);
  got_error := false;
  begin
    perform remove_household_member(user_a);
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning
      'adult B was able to remove a member; remove_household_member must '
      'be owner-only';
  end if;

  -- The owner cannot remove themselves.
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);
  got_error := false;
  begin
    perform remove_household_member(user_a);
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'owner A was able to remove themselves';
  end if;

  -- The owner can remove an adult.
  perform remove_household_member(user_b);
  select count(*) into n
    from household_members where household_id = hid and user_id = user_b;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'owner A could not remove adult B';
  end if;

  -- The owner cannot leave. Guarded on role alone (settled during planning):
  -- since only the owner removes, and the owner can neither be removed nor
  -- leave, the owner row always survives, which collapses "the last member
  -- may not leave" into this single check.
  got_error := false;
  begin
    perform leave_household();
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'owner A was able to leave their own household';
  end if;

  -- Re-add B (service role) so leaving can be exercised.
  perform set_config('role', 'postgres', true);
  insert into household_members (household_id, user_id, role)
  values (hid, user_b, 'adult');

  -- An adult can leave.
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);
  perform leave_household();
  select count(*) into n
    from household_members where household_id = hid and user_id = user_b;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'adult B could not leave the household';
  end if;

  -- A non-member can call neither.
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_c, 'role', 'authenticated')::text, true);
  got_error := false;
  begin
    perform remove_household_member(user_a);
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'non-member C was able to call remove_household_member';
  end if;

  got_error := false;
  begin
    perform leave_household();
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'non-member C was able to call leave_household';
  end if;

  ---------------------------------------------------------------------------
  -- phase6-part3c: delete_household
  ---------------------------------------------------------------------------
  -- A fresh household -- D owner, E adult -- kept separate from hid so this
  -- section does not interfere with the D23 assertion below (which
  -- soft-deletes hid by hand) or with teardown (which deletes by
  -- created_by).
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_d, 'role', 'authenticated')::text, true);
  select create_household('Delete Test Household') into hid2;

  perform set_config('role', 'postgres', true);
  insert into household_members (household_id, user_id, role)
  values (hid2, user_e, 'adult');

  insert into household_invites (household_id, code, created_by, expires_at)
  values (hid2, '777777', user_d, now() + interval '7 days')
  returning id into invite2;

  -- A non-member cannot call it.
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_c, 'role', 'authenticated')::text, true);
  got_error := false;
  begin
    perform delete_household();
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'non-member C was able to call delete_household';
  end if;

  -- An adult member cannot delete -- the load-bearing assertion: it is the
  -- whole reason this is an RPC and not the column-blind households_update
  -- policy (D112).
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_e, 'role', 'authenticated')::text, true);
  got_error := false;
  begin
    perform delete_household();
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning
      'adult E was able to delete the household; delete_household must be '
      'owner-only';
  end if;

  -- The owner can, with other members still present -- no last-member count
  -- (see the migration's own comment).
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_d, 'role', 'authenticated')::text, true);
  perform delete_household();

  perform set_config('role', 'postgres', true);

  select count(*) into n
    from households where id = hid2 and deleted_at is not null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'delete_household did not stamp households.deleted_at';
  end if;

  -- Zero membership rows remain, the owner's own included.
  select count(*) into n from household_members where household_id = hid2;
  if n <> 0 then
    failures := failures + 1;
    raise warning
      'delete_household left % membership row(s) for the deleted household, '
      'want 0', n;
  end if;

  -- Every previously-live invite is revoked.
  select count(*) into n
    from household_invites
    where household_id = hid2 and (revoked_at is null or revoked_by is null);
  if n <> 0 then
    failures := failures + 1;
    raise warning
      'delete_household left a live invite for the deleted household';
  end if;

  -- The ex-owner, now memberless, can still create a fresh household -- proof
  -- that delete is a real exit and not a dead end.
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_d, 'role', 'authenticated')::text, true);
  select create_household('Fresh After Delete') into hid3;

  select count(*) into n
    from household_members where household_id = hid3 and user_id = user_d
      and role = 'owner';
  if n <> 1 then
    failures := failures + 1;
    raise warning
      'ex-owner D could not create_household() after deleting their own -- '
      'delete_household is a trap, not a real exit';
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
  delete from households where created_by in (user_a, user_b, user_c, user_d, user_e);
  delete from auth.users where id in (user_a, user_b, user_c, user_d, user_e);

  if failures > 0 then
    raise exception '% household RLS assertion(s) failed', failures;
  end if;

  raise notice 'household RLS: all assertions passed';
end
$$;
