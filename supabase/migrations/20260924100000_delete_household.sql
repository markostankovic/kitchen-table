-- Migration 23 -- delete a household (Phase 6 part 3c).
--
-- A soft delete of households alone strands every member: their
-- household_members row survives, so resolveHousehold() and the 3b RPCs keep
-- resolving a household the client can no longer see, and redeem-invite's
-- single-household rule locks every ex-member out of ever joining another
-- household. So delete_household() does three things in one
-- SECURITY DEFINER RPC: stamp households.deleted_at, revoke every live invite
-- code for it, and hard-delete every household_members row.
--
-- Household-scoped child rows (recipes, meal plans, shopping lists, import
-- jobs, translations, tags) are deliberately NOT stamped here -- with no
-- members left, is_household_member() makes all of them unreachable, which is
-- what "deleted" already means for them. Cascade-stamping a dozen tables
-- would buy nothing.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).

-- ---------------------------------------------------------------------------
-- Deleting a household
-- ---------------------------------------------------------------------------
-- Owner-only, enforced here rather than by narrowing households_update
-- (D112 explicitly left this question to this slice). households_update's RLS
-- checks membership only, not role, and is column-blind -- an adult could
-- already send deleted_at through it today. Narrowing that policy would be a
-- second, weaker place for the same rule and would break rename, which stays
-- open to any member. So delete goes through a function whose body is the one
-- enforceable place for the owner check.
--
-- No grant execute: like the 3b RPCs, this relies on the default PUBLIC grant
-- and guards on auth.uid() is null instead of a role grant. Not an omission.
--
-- security definer bypasses RLS, so every query here carries its own explicit
-- predicate.

create or replace function delete_household()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller uuid := auth.uid();
  caller_household uuid;
  caller_role text;
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  -- Same ordering resolveHousehold() and the 3b RPCs use, and for the same
  -- reason: it agrees with HouseholdRepository.fetchCurrent()'s own ordering
  -- only while a user is in one household, which redeem-invite enforces by
  -- rejecting a second.
  select household_id, role into caller_household, caller_role
  from household_members
  where user_id = caller
  order by created_at
  limit 1;

  if caller_household is null then
    raise exception 'not a member of any household' using errcode = '22023';
  end if;

  if caller_role <> 'owner' then
    raise exception 'only the owner can delete the household' using errcode = '22023';
  end if;

  -- No `and deleted_at is null` predicate: after this migration a member can
  -- only ever hold a membership in a live household (step below guarantees
  -- it), so a caller resolving to an already-deleted household is
  -- unreachable. Adding the guard here would let the function half-run if
  -- that unreachable state were ever hit -- the same reasoning 3b used to
  -- reject a last-member count on leave_household().
  update households
  set deleted_at = now()
  where id = caller_household;

  -- A live code must not outlive its household. Reuses migration 22's
  -- revoked_at / revoked_by columns and honours the
  -- household_invites_revoked_together check constraint (both columns or
  -- neither). Releases those six digits for reuse, per D25.
  update household_invites
  set revoked_at = now(), revoked_by = caller
  where household_id = caller_household
    and used_at is null
    and revoked_at is null;

  -- Every row, the caller's included. This is the step that makes everyone's
  -- next read resolve to null (household_members is a child join table, hard
  -- delete with no audit trail, D24), and the step that keeps redeem-invite's
  -- "one household per account" rule from becoming a permanent lockout for
  -- every ex-member, the owner included.
  delete from household_members
  where household_id = caller_household;
end;
$$;

comment on function delete_household() is
  'Owner deletes their own household: stamps deleted_at, revokes every live '
  'invite code, and hard-deletes every membership row so no one is stranded. '
  'The only path -- households_update stays column-blind on purpose (D112).';
