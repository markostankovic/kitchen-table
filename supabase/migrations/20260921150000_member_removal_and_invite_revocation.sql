-- Migration 22 -- member removal and invite revocation (Phase 6 part 3b).
--
-- household_members and household_invites are SELECT-only RLS with no write
-- policy of any kind (D26). This slice adds three writes -- removing a
-- member, leaving a household, revoking an invite code -- all as
-- SECURITY DEFINER RPCs mirroring create_household(). Neither table gains a
-- write policy.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).

-- ---------------------------------------------------------------------------
-- household_invites: revoked_at / revoked_by
-- ---------------------------------------------------------------------------
-- D25 named this exact cost when it deferred revocation: a revoked_at column
-- AND a rebuild of the partial index predicate, in one migration. This is not
-- a soft delete (CLAUDE.md rule 4 / D25) -- it is a third lifecycle stamp on
-- an append-only table, same shape as used_at.

alter table household_invites add column revoked_at timestamptz;
alter table household_invites add column revoked_by uuid references profiles(id);

-- Same discipline as household_invites_used_together: half a stamp would mean
-- something wrote a column it is not supposed to be able to write alone.
alter table household_invites add constraint household_invites_revoked_together
  check ((revoked_by is null) = (revoked_at is null));

-- TRAP (carried forward from D25, migration 3): you cannot narrow this to
-- `and expires_at > now()` -- now() is STABLE, not IMMUTABLE, and an index
-- predicate must be immutable.
--
-- New predicate: revoking releases the code for reuse, same as using it does.
-- That is the point of revocation -- a killed code should be re-mintable
-- immediately, not squat on its six digits until it expires. The D25 trap
-- this creates (a dead row keeps its code, so the code can be re-minted for a
-- DIFFERENT household while the old row still carries it) is intended
-- behaviour here, and is exactly what forces redeem-invite's revoked_at
-- guards below.
drop index household_invites_code_unused_idx;

create unique index household_invites_code_unused_idx
  on household_invites (code) where used_at is null and revoked_at is null;

-- ---------------------------------------------------------------------------
-- Removing a member
-- ---------------------------------------------------------------------------
-- Owner-only (settled during planning): removal is a hard delete with no
-- audit trail (D24), so it stays confined to the one role trusted with
-- destructive action elsewhere in this schema.
--
-- An RPC rather than a DELETE policy or an Edge Function, mirroring
-- create_household()'s own reasoning: this revokes access rather than
-- granting it, so there is no secret and no trust boundary to cross for an
-- Edge Function to guard. Keeps D26's "neither table has a write policy"
-- literally true and puts every invariant in one enforceable place instead of
-- spread across a policy's USING clause.
--
-- No grant execute: like create_household(), this relies on the default
-- PUBLIC grant and guards on auth.uid() is null instead of a role grant. Not
-- an omission.
--
-- security definer bypasses RLS, so is_household_member() is not doing any
-- work inside this function body -- _shared/auth.ts's own rule for the
-- service client applies identically here: every query carries its own
-- explicit predicate.

create or replace function remove_household_member(target_user uuid)
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

  -- Same ordering resolveHousehold() in supabase/functions/_shared/auth.ts
  -- uses, and for the same reason: it agrees with
  -- HouseholdRepository.fetchCurrent()'s own ordering only while a user is in
  -- one household, which redeem-invite enforces by rejecting a second.
  select household_id, role into caller_household, caller_role
  from household_members
  where user_id = caller
  order by created_at
  limit 1;

  if caller_household is null then
    raise exception 'not a member of any household' using errcode = '22023';
  end if;

  if caller_role <> 'owner' then
    raise exception 'only the owner can remove a member' using errcode = '22023';
  end if;

  if target_user = caller then
    raise exception 'the owner cannot remove themselves' using errcode = '22023';
  end if;

  delete from household_members
  where household_id = caller_household and user_id = target_user;
end;
$$;

comment on function remove_household_member(uuid) is
  'Owner removes a member from their own household. Hard delete, no audit '
  'trail (D24). The only path -- household_members has no write policy.';

-- ---------------------------------------------------------------------------
-- Leaving a household
-- ---------------------------------------------------------------------------
-- Guarded on role alone (settled during planning): the owner can neither be
-- removed nor leave, and only the owner removes, so the owner row always
-- survives. That collapses "the last member may not leave" into "the owner
-- may not leave" -- a separate last-member count is unreachable and would be
-- dead code.
--
-- The exit for a household entirely is 3c's delete; this function does not
-- attempt it.

create or replace function leave_household()
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

  select household_id, role into caller_household, caller_role
  from household_members
  where user_id = caller
  order by created_at
  limit 1;

  if caller_household is null then
    raise exception 'not a member of any household' using errcode = '22023';
  end if;

  if caller_role = 'owner' then
    raise exception 'the owner cannot leave -- remove every other member first' using errcode = '22023';
  end if;

  delete from household_members
  where household_id = caller_household and user_id = caller;
end;
$$;

comment on function leave_household() is
  'Caller leaves their own household. The owner may not call this -- remove '
  'every other member first, or delete the household (3c). The only path -- '
  'household_members has no write policy.';

-- ---------------------------------------------------------------------------
-- Revoking an invite
-- ---------------------------------------------------------------------------
-- Any member, not owner-only (settled during planning): revocation inherits
-- create-invite's "owner and adult are both trusted adults" stance -- if any
-- member can mint a code, any member can kill it.

create or replace function revoke_invite(invite_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  caller uuid := auth.uid();
  caller_household uuid;
  invite_household uuid;
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select household_id into caller_household
  from household_members
  where user_id = caller
  order by created_at
  limit 1;

  if caller_household is null then
    raise exception 'not a member of any household' using errcode = '22023';
  end if;

  select household_id into invite_household
  from household_invites
  where id = invite_id;

  if invite_household is null or invite_household <> caller_household then
    raise exception 'no such invite' using errcode = '22023';
  end if;

  update household_invites
  set revoked_at = now(), revoked_by = caller
  where id = invite_id and used_at is null and revoked_at is null;
end;
$$;

comment on function revoke_invite(uuid) is
  'Any member revokes a live invite code minted by their own household. The '
  'only path -- household_invites has no write policy.';
