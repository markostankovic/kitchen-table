-- Migration 2 -- identity and households (Phase 1a).
--
-- profiles, households, household_members, with their triggers and RLS
-- policies in this same migration -- never a follow-up (docs/ROADMAP.md,
-- "Standing rules").
--
-- household_invites is deliberately NOT here. Its only writer is the
-- create-invite / redeem-invite Edge Functions, so the table lands with them.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
-- Per-user, not household-scoped: no household_id, so no deleted_at (D24).

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  locale text not null default 'sr' check (locale in ('sr', 'en')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger profiles_set_updated_at
  before update on profiles
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------------
-- households
-- ---------------------------------------------------------------------------
-- Household-scoped root: gets deleted_at and the updated_at trigger (D24).

create table households (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) > 0),
  created_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create trigger households_set_updated_at
  before update on households
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------------
-- household_members
-- ---------------------------------------------------------------------------
-- A child join table: cascades with its parent, so no deleted_at and no
-- updated_at (D24). Consequence: removing a member is a hard delete. Revisit
-- if revocation ever needs to be auditable.

create table household_members (
  household_id uuid not null references households(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  role text not null check (role in ('owner', 'adult')),
  created_at timestamptz not null default now(),
  primary key (household_id, user_id)
);

-- The primary key already serves household_id lookups. This covers the other
-- direction -- "which households is this user in" -- which the auth redirect
-- asks on every launch.
create index household_members_user_id_idx on household_members (user_id);

-- ---------------------------------------------------------------------------
-- Membership helper
-- ---------------------------------------------------------------------------
-- SECURITY DEFINER is load-bearing, not incidental. household_members' own
-- SELECT policy calls this function; if it ran as the caller it would consult
-- that same policy and recurse infinitely. Running as owner bypasses RLS and
-- breaks the cycle (docs/DATA_MODEL.md, "RLS pattern").
--
-- It leaks nothing: it only ever answers "is the *caller* a member".

create or replace function is_household_member(hid uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from household_members
    where household_id = hid and user_id = auth.uid()
  );
$$;

comment on function is_household_member(uuid) is
  'Is the calling user a member of this household? SECURITY DEFINER to avoid '
  'RLS recursion on household_members.';

-- ---------------------------------------------------------------------------
-- Profile creation
-- ---------------------------------------------------------------------------
-- A database trigger rather than a client-side upsert after sign-in: there
-- must be no window in which a signed-in user has no profile row, because
-- households.created_by references it.
--
-- Email OTP carries no display name, so seed it from the email local-part and
-- let the user change it later.

create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(nullif(split_part(coalesce(new.email, ''), '@', 1), ''), 'user')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ---------------------------------------------------------------------------
-- Creating a household
-- ---------------------------------------------------------------------------
-- Inserting the household and the creator's membership must be atomic -- a
-- household with no members is unreachable by RLS and orphaned forever. So
-- there is no INSERT policy on either table and this RPC is the only path.
--
-- An RPC rather than an Edge Function: ARCHITECTURE.md reserves Edge Functions
-- for anything granting access to household data, but this is the creator
-- admitting themselves, not inviting anyone else. No secret, no trust boundary
-- crossed.

create or replace function create_household(household_name text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  new_id uuid;
  caller uuid := auth.uid();
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  if household_name is null or length(trim(household_name)) = 0 then
    raise exception 'household name required' using errcode = '22023';
  end if;

  insert into households (name, created_by)
  values (trim(household_name), caller)
  returning id into new_id;

  insert into household_members (household_id, user_id, role)
  values (new_id, caller, 'owner');

  return new_id;
end;
$$;

comment on function create_household(text) is
  'Creates a household and the caller''s owner membership atomically. The '
  'only path -- neither table has an INSERT policy.';

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
-- Membership only. No `deleted_at is null` anywhere (D23): the Phase 2 delta
-- fetch must be able to see tombstones in order to evict them from the Drift
-- cache, so soft-deleted rows are filtered in data/, not here.
--
-- No DELETE policy on any table: deletion is a soft delete, which is an
-- UPDATE.

alter table profiles enable row level security;

-- No INSERT policy: handle_new_user() creates the row as SECURITY DEFINER.
-- Co-member visibility (needed by the member list) arrives with the invites
-- slice; until then a user sees only themselves.
create policy profiles_select_own on profiles for select
  using (id = auth.uid());
create policy profiles_update_own on profiles for update
  using (id = auth.uid())
  with check (id = auth.uid());

alter table households enable row level security;

-- No INSERT policy: create_household() is the only path, see above.
create policy households_select on households for select
  using (is_household_member(id));
create policy households_update on households for update
  using (is_household_member(id))
  with check (is_household_member(id));

alter table household_members enable row level security;

-- No INSERT/UPDATE policy: memberships are written by create_household() and,
-- from the next slice, by the invite Edge Functions under the service role.
create policy household_members_select on household_members for select
  using (is_household_member(household_id));
