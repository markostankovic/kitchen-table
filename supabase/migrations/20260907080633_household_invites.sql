-- Migration 3 -- household invites (Phase 1a, second slice).
--
-- The table migration 2 deferred, arriving with its only writer: the
-- create-invite / redeem-invite Edge Functions. Also lands the co-member
-- profile visibility that migration 2 left a TODO for -- the member list is
-- unreadable without it.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).

-- ---------------------------------------------------------------------------
-- household_invites
-- ---------------------------------------------------------------------------
-- Household-scoped by D24's definition (it has a household_id), but it gets
-- neither deleted_at nor updated_at. This is a deliberate exception to
-- CLAUDE.md rule 4, recorded as D25:
--
--   * An invite is append-only. It is created once and stamped dead once, and
--     used_at IS the lifecycle column. Rule 4's intent -- no row ever
--     disappears -- is already satisfied.
--   * deleted_at would be a second, overlapping lifecycle axis with no defined
--     interaction with used_at ("soft-deleted but unused"?). Worse, the partial
--     unique index below would have to become
--     `where used_at is null and deleted_at is null`, which would let a
--     soft-deleted code be reissued to a DIFFERENT household while a row still
--     claims it. Fewer axes is more correct here.
--   * deleted_at's other job (D23/D12: tombstones for the Phase 2 Drift delta
--     fetch) does not apply. Invites are not a cached entity, and an invite
--     code is meaningless offline.
--   * updated_at would be written exactly twice in a row's life, and the second
--     write already records its own timestamp in used_at. Nothing would read it.
--
-- There is deliberately no revocation path. Single-use plus the 7-day expiry is
-- the containment; revocation is not in Phase 1a. If it is ever wanted, it is a
-- revoked_at column AND a rebuild of the partial index predicate -- see D25.

create table household_invites (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  code char(6) not null check (code ~ '^[0-9]{6}$'),
  -- For Phase 4's public invite links. Nothing reads or returns it yet; it
  -- exists so that slice is not blocked on a migration (docs/DATA_MODEL.md).
  -- Do not "clean up" as unused.
  token uuid not null default gen_random_uuid(),
  created_by uuid not null references profiles(id),
  expires_at timestamptz not null,
  used_by uuid references profiles(id),
  used_at timestamptz,
  created_at timestamptz not null default now(),
  -- Redemption stamps both columns in one UPDATE. Half a stamp would mean the
  -- Edge Function did something it is not supposed to be able to do.
  constraint household_invites_used_together
    check ((used_by is null) = (used_at is null))
);

comment on table household_invites is
  'Six-digit single-use codes for joining a household. Written only by the '
  'create-invite / redeem-invite Edge Functions under the service role.';

-- Single-use enforcement, and the lookup redeem-invite does. A code is unique
-- only among LIVE invites: once used_at is stamped the code is released and may
-- legitimately be minted again for a different household.
--
-- TRAP: you cannot narrow this to `and expires_at > now()`. now() is STABLE,
-- not IMMUTABLE, and an index predicate must be immutable. The consequence is
-- that an expired, unused invite reserves its code until something deletes it.
-- At family scale that removes single digits from a 10^6 space and the retry
-- loop in create-invite absorbs it. A periodic sweep is the eventual answer.
create unique index household_invites_code_unused_idx
  on household_invites (code) where used_at is null;

-- "Show me this household's live codes", which the household screen asks.
create index household_invites_household_id_idx
  on household_invites (household_id);

-- ---------------------------------------------------------------------------
-- Co-membership helper
-- ---------------------------------------------------------------------------
-- Same reasoning as is_household_member in migration 2: the profiles SELECT
-- policy below has to consult household_members, whose own policy consults
-- membership in turn. An inline `exists (...)` subquery would not actually
-- recurse -- household_members_select calls is_household_member, which is
-- SECURITY DEFINER and breaks the cycle -- but it would depend silently on that
-- other policy staying exactly as it is. SECURITY DEFINER here makes the
-- dependency explicit instead of implicit.
--
-- It discloses nothing beyond the disclosure it gates: it answers only "does
-- the CALLER share a household with this user", which is precisely the fact
-- that justifies showing that user's profile.

create or replace function shares_household_with(other_user uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from household_members mine
    join household_members theirs on theirs.household_id = mine.household_id
    where mine.user_id = auth.uid()
      and theirs.user_id = other_user
  );
$$;

comment on function shares_household_with(uuid) is
  'Does the calling user share a household with this user? SECURITY DEFINER '
  'to avoid RLS recursion between profiles and household_members.';

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------

alter table household_invites enable row level security;

-- No INSERT / UPDATE / DELETE policy. Both invite Edge Functions hold the
-- service role key, which bypasses RLS entirely (docs/ARCHITECTURE.md:
-- "anything granting access to household data is not client logic"). A write
-- policy here would be dead code that reads like a second, weaker way in.
--
-- SELECT is open to members so the household screen can re-show a code the user
-- generated on their other device. It discloses nothing a member does not
-- already have, and a PROSPECTIVE member is not a member yet -- so there is no
-- path to enumerating codes through PostgREST.
--
-- No used_at / expires_at clause: policies check membership only, and the
-- repository filters for live invites (D23).
create policy household_invites_select on household_invites for select
  using (is_household_member(household_id));

-- The visibility migration 2 deferred to this slice. Permissive policies OR
-- together, so profiles_select_own still covers a user who is in no household
-- at all -- this policy is added, not substituted.
create policy profiles_select_co_member on profiles for select
  using (shares_household_with(id));
