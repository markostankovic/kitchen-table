-- Phase 9 slice B. The three membership RPCs stop picking the caller's oldest
-- membership; the client names the household (D168's reasoning, applied to
-- RPCs).
--
-- remove_household_member, leave_household and delete_household each looked
-- the caller's household up as their oldest membership. That only
-- named the right household while redeem-invite rejected a second
-- membership, and that guard goes in this slice. So each now takes the
-- household as its first parameter and checks the caller's membership of
-- THAT household. The zero-argument overloads are dropped, not kept for old
-- builds: keeping them would be the same lingering fallback D168 set out to
-- end.
--
-- revoke_invite keeps its signature (the invite already names its household)
-- but loses the same oldest-membership lookup: it now checks that the caller
-- is a member of the invite's own household.
--
-- Bodies are otherwise copied from migrations 22 and 23
-- (20260921150000_member_removal_and_invite_revocation.sql,
-- 20260924100000_delete_household.sql), which stay untouched.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).

drop function remove_household_member(uuid);
drop function leave_household();
drop function delete_household();

-- ---------------------------------------------------------------------------
-- Removing a member
-- ---------------------------------------------------------------------------
-- Owner-only, an RPC rather than a DELETE policy (migration 22's reasoning).
--
-- No grant execute: like create_household(), this relies on the default
-- PUBLIC grant and guards on auth.uid() is null instead of a role grant. Not
-- an omission.
--
-- security definer bypasses RLS, so every query here carries its own explicit
-- predicate, and the membership check comes before anything keyed on
-- target_household (D31).

create function remove_household_member(target_household uuid, target_user uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller uuid := auth.uid();
  caller_role text;
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select role into caller_role
  from household_members
  where user_id = caller and household_id = target_household;

  if caller_role is null then
    raise exception 'not a member of that household' using errcode = '22023';
  end if;

  if caller_role <> 'owner' then
    raise exception 'only the owner can remove a member' using errcode = '22023';
  end if;

  if target_user = caller then
    raise exception 'the owner cannot remove themselves' using errcode = '22023';
  end if;

  delete from household_members
  where household_id = target_household and user_id = target_user;
end;
$$;

comment on function remove_household_member(uuid, uuid) is
  'Owner removes a member from the named household. Hard delete, no audit '
  'trail (D24). The only path -- household_members has no write policy.';

-- ---------------------------------------------------------------------------
-- Leaving a household
-- ---------------------------------------------------------------------------
-- Guarded on role alone (migration 22): the owner can neither be removed nor
-- leave, so the owner row always survives.

create function leave_household(target_household uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller uuid := auth.uid();
  caller_role text;
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select role into caller_role
  from household_members
  where user_id = caller and household_id = target_household;

  if caller_role is null then
    raise exception 'not a member of that household' using errcode = '22023';
  end if;

  if caller_role = 'owner' then
    raise exception 'the owner cannot leave -- remove every other member first' using errcode = '22023';
  end if;

  delete from household_members
  where household_id = target_household and user_id = caller;
end;
$$;

comment on function leave_household(uuid) is
  'Caller leaves the named household. The owner may not call this -- remove '
  'every other member first, or delete the household. The only path -- '
  'household_members has no write policy.';

-- ---------------------------------------------------------------------------
-- Deleting a household
-- ---------------------------------------------------------------------------
-- Owner-only, enforced here rather than by narrowing households_update
-- (D112 / D116, migration 23's reasoning).

create function delete_household(target_household uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller uuid := auth.uid();
  caller_role text;
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select role into caller_role
  from household_members
  where user_id = caller and household_id = target_household;

  if caller_role is null then
    raise exception 'not a member of that household' using errcode = '22023';
  end if;

  if caller_role <> 'owner' then
    raise exception 'only the owner can delete the household' using errcode = '22023';
  end if;

  -- No `and deleted_at is null` predicate: a membership only ever exists for
  -- a live household (the delete below guarantees it), so the guard would
  -- only let this half-run on an unreachable state (migration 23).
  update households
  set deleted_at = now()
  where id = target_household;

  -- A live code must not outlive its household (migration 23, D25).
  update household_invites
  set revoked_at = now(), revoked_by = caller
  where household_id = target_household
    and used_at is null
    and revoked_at is null;

  -- Every row, the caller's included (D24). The caller's memberships of
  -- other households are untouched.
  delete from household_members
  where household_id = target_household;
end;
$$;

comment on function delete_household(uuid) is
  'Owner deletes the named household: stamps deleted_at, revokes every live '
  'invite code, and hard-deletes every membership row so no one is stranded. '
  'The only path -- households_update stays column-blind on purpose (D112).';

-- ---------------------------------------------------------------------------
-- Revoking an invite
-- ---------------------------------------------------------------------------
-- Any member of the invite's household (migration 22). Same signature, so
-- `create or replace`; only the lookup changes.

create or replace function revoke_invite(invite_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller uuid := auth.uid();
  invite_household uuid;
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select household_id into invite_household
  from household_invites
  where id = invite_id;

  -- One message for "no such invite" and "not your household's invite", as
  -- before: a non-member learns nothing about which ids exist.
  if invite_household is null or not exists (
    select 1 from household_members
    where user_id = caller and household_id = invite_household
  ) then
    raise exception 'no such invite' using errcode = '22023';
  end if;

  update household_invites
  set revoked_at = now(), revoked_by = caller
  where id = invite_id and used_at is null and revoked_at is null;
end;
$$;

comment on function revoke_invite(uuid) is
  'Any member of the invite''s household revokes a live invite code. The '
  'only path -- household_invites has no write policy.';
