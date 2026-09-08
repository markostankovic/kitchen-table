-- Migration 10 -- import jobs, AI usage and per-household AI caps
-- (Phase 1d, first slice).
--
-- Nothing user-visible ships on top of this migration. It is the substrate the
-- rest of 1d stands on: import_jobs is the queue D14 chose over a synchronous
-- request, and ai_usage / household_ai_limits are D17's "usage limits from day
-- one" -- cheap now, awkward to bolt on later.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D38 (ai_usage is append-only and carries no
-- lifecycle columns), D39 (the client never writes import_jobs; RLS grants
-- SELECT and nothing else), D40 (every household gets a limits row from a
-- trigger, so the caps have exactly one definition -- the column defaults).

-- ---------------------------------------------------------------------------
-- import_jobs
-- ---------------------------------------------------------------------------
-- Household-scoped in the D24 sense, so rule 4 reaches it in full: updated_at
-- with a trigger, deleted_at, no hard deletes. Unlike household_invites (D25)
-- there is no case for an exception here -- `status` genuinely mutates over a
-- job's life, and deleted_at is how somebody dismisses a failed job from the
-- queue without losing the record of what was attempted.
--
-- One row per input. Five photographed cookbook pages are five rows, and the
-- UI shows them as a queue (docs/DATA_MODEL.md).

create table import_jobs (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  created_by uuid not null references profiles(id),
  -- Three kinds, one code path (D14). recipes.source_type has four values and
  -- these three do not map onto it one for one: 'url' -> 'url_import',
  -- 'photo' -> 'ocr', and 'text' -> 'url_import' when the paste carried a
  -- source URL, else 'manual'. That mapping lives in the importers; it is
  -- written here because the alternative is discovering it against an applied
  -- check constraint.
  kind text not null check (kind in ('url','photo','text')),
  input_url text,
  -- For photos. The bucket, its storage.objects policies and the picker are
  -- the last slice of 1d -- the column ships now so that slice is a feature
  -- and not a migration against existing rows, exactly as recipes.image_path
  -- did in 1c (D35).
  input_storage_path text,
  input_text text,
  -- queued -> processing -> needs_review | failed, and needs_review -> done.
  -- 'done' is only ever reached through finish_import_job below, because D8
  -- says no import writes a recipe without a human looking at it first.
  status text not null default 'queued'
    check (status in ('queued','processing','needs_review','failed','done')),
  -- A ParsedRecipe, matching the Zod schema in
  -- supabase/functions/_shared/schema.ts. Deliberately jsonb and deliberately
  -- unconstrained here: the schema is defined once, on the server, in Zod
  -- (D18), and a second definition as a check constraint would drift.
  result jsonb,
  -- The same {error, message} pair the Edge Functions return, persisted so a
  -- failed job can say why days later. error_code reuses the vocabulary in
  -- supabase/functions/_shared/http.ts.
  error_code text,
  error_message text,
  recipe_id uuid references recipes(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create trigger import_jobs_set_updated_at
  before update on import_jobs
  for each row execute function set_updated_at();

create index import_jobs_household_status_idx
  on import_jobs (household_id, status, created_at desc);

comment on table import_jobs is
  'One recipe import, from a URL, a pasted block of text or a photograph. '
  'Every import is a background job (D14): the client creates one and polls, '
  'because a vision model call cannot fit inside an HTTP request.';

-- ---------------------------------------------------------------------------
-- ai_usage
-- ---------------------------------------------------------------------------
-- D38. This table carries household_id, so rule 4 as written would give it
-- updated_at and deleted_at. It gets neither, and the argument is the same
-- shape as D25's for household_invites: the columns would describe something
-- the table does not do.
--
-- ai_usage is an append-only ledger. A row is inserted once, by the service
-- role, immediately after a model call, and is never read for anything except
-- summation. A ledger whose rows can be updated is not a ledger, and a
-- tombstoned cost row is a hole in a cost audit that still bills.
--
-- The consequence, stated so it is a choice and not a surprise: there is no
-- way to correct a mis-recorded row, and no way to hide one. Both are correct
-- for money. If usage ever needs to be reset per billing period, that is a new
-- column recording the period, not a delete.

create table ai_usage (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references households(id) on delete cascade,
  -- Nullable: a scheduled re-matching pass has a household but no user.
  user_id uuid references profiles(id),
  function_name text not null,
  model text not null,
  input_tokens int,
  output_tokens int,
  -- Micro-dollars. bigint, not numeric: a cost is a count of a fixed unit,
  -- and integers sum exactly for the same reason quantities are fractions
  -- (rule 5).
  cost_micros bigint,
  created_at timestamptz not null default now()
);

create index ai_usage_household_created_idx
  on ai_usage (household_id, created_at desc);

comment on table ai_usage is
  'Append-only ledger of model calls, one row per call, written by the service '
  'role only. No updated_at and no deleted_at, deliberately (D38): a cost row '
  'that can be edited or hidden is not an audit trail.';

-- ---------------------------------------------------------------------------
-- household_ai_limits
-- ---------------------------------------------------------------------------
-- The caps checked before every model call (D17). One row per household, so
-- the primary key IS the household id -- which is also why there is no
-- deleted_at: the row has no life independent of the household, and it
-- cascades. updated_at it does get, because caps are meant to be tuned.

create table household_ai_limits (
  household_id uuid primary key references households(id) on delete cascade,
  -- ~$300/month. Deliberately generous to start; the point of shipping the
  -- cap now is that lowering a number is easy and adding a mechanism is not.
  monthly_cost_cap_micros bigint not null default 300000000
    check (monthly_cost_cap_micros >= 0),
  monthly_call_cap int not null default 500
    check (monthly_call_cap >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger household_ai_limits_set_updated_at
  before update on household_ai_limits
  for each row execute function set_updated_at();

comment on table household_ai_limits is
  'Per-household monthly AI caps, both cost and call count (D17). One row per '
  'household, created by a trigger so the column defaults are the only '
  'definition of what the caps start at (D40).';

-- ---------------------------------------------------------------------------
-- Default limits rows
-- ---------------------------------------------------------------------------
-- D40. _shared/usage.ts must not hold a second copy of the default caps, and
-- a `coalesce(limits.cap, 500)` in TypeScript is exactly that copy. So the
-- column defaults stay the single definition and every household is
-- guaranteed a row instead.
--
-- A trigger rather than an edit to create_household(): that function is in an
-- applied migration and applied migrations are not edited (CLAUDE.md). A
-- trigger also catches the paths create_household() is not on -- the seed, a
-- future invite flow, a manual insert in psql.

create or replace function ensure_ai_limits()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into household_ai_limits (household_id)
  values (new.id)
  on conflict (household_id) do nothing;
  return new;
end;
$$;

comment on function ensure_ai_limits() is
  'Gives every new household a row in household_ai_limits, so the caps have '
  'one definition -- the column defaults -- and usage.ts never guesses (D40).';

create trigger households_ensure_ai_limits
  after insert on households
  for each row execute function ensure_ai_limits();

-- Backfill. Idempotent, so a `supabase db reset` and a deploy against a live
-- database both do the right thing.
insert into household_ai_limits (household_id)
  select id from households
  on conflict (household_id) do nothing;

-- ---------------------------------------------------------------------------
-- ai_quota_status
-- ---------------------------------------------------------------------------
-- Both caps and the month window, in one round trip and in SQL.
--
-- The month boundary and the comparison could equally live in TypeScript, and
-- putting them there was the alternative. This is better for one reason: a
-- rule that lives in SQL is assertable by `make test-sql`, and a quota that
-- has never been tested against its own boundary is a quota that fails open
-- the first time it matters.
--
-- security definer, because the caller is the service role reading a table
-- the client may only read for its own household -- and because a quota check
-- that could be evaluated under the caller's RLS would return a different
-- answer depending on who asked.

create or replace function ai_quota_status(household uuid)
returns table (
  calls_this_month        int,
  cost_micros_this_month  bigint,
  monthly_call_cap        int,
  monthly_cost_cap_micros bigint,
  within_caps             boolean
)
language sql
stable
security definer
set search_path = public
as $$
  with window_start as (
    select date_trunc('month', now()) as from_ts
  ),
  spend as (
    select
      count(*)::int                       as calls,
      coalesce(sum(u.cost_micros), 0)::bigint as cost
    from ai_usage u, window_start w
    where u.household_id = household
      and u.created_at >= w.from_ts
  ),
  caps as (
    -- coalesce against the table's own defaults rather than against literals:
    -- the trigger above means a missing row is a bug, but a quota check that
    -- crashes on one would fail OPEN by taking the whole import down, and
    -- there is no reading of D17 where that is the safe direction.
    select
      coalesce(l.monthly_call_cap, 0)          as call_cap,
      coalesce(l.monthly_cost_cap_micros, 0)   as cost_cap
    from (select 1) one
    left join household_ai_limits l on l.household_id = household
  )
  select
    spend.calls,
    spend.cost,
    caps.call_cap,
    caps.cost_cap,
    spend.calls < caps.call_cap and spend.cost < caps.cost_cap
  from spend, caps;
$$;

comment on function ai_quota_status(uuid) is
  'Current calendar month AI spend for a household against both of its caps '
  '(D17). within_caps is computed here so no client or Edge Function holds a '
  'copy of the comparison.';

-- ---------------------------------------------------------------------------
-- finish_import_job / dismiss_import_job
-- ---------------------------------------------------------------------------
-- The client's entire write surface on import_jobs, and the reason there is no
-- UPDATE policy (D39).
--
-- RLS cannot restrict which COLUMNS an update touches. A policy permissive
-- enough to let the confirm screen set recipe_id is permissive enough to let
-- any client set status = 'needs_review' with a hand-written `result`, which
-- would turn the import queue into an arbitrary-JSON store that the confirm
-- screen renders. So the client gets SELECT, and these two functions.
--
-- Both security definer, and NOT security invoker -- which is the opposite of
-- replace_recipe_lines (D36) for a reason worth stating, because the contrast
-- otherwise reads as an inconsistency.
--
-- D36 could be security invoker because recipe_ingredients has INSERT, UPDATE
-- and DELETE policies: RLS was already able to decide, and the function only
-- added a transaction. Here there is deliberately no UPDATE policy at all, so
-- an invoker-rights function would run an UPDATE that matches zero rows and
-- report a job that does not exist. The privilege is the point, not an
-- oversight.
--
-- That makes these the same shape as create_ingredient and link_ingredient_alias
-- (D34): security definer, granted to `authenticated`, with the membership
-- check written out explicitly inside. A definer function bypasses RLS, so
-- every statement in it has to carry its own predicate -- the same rule
-- _shared/auth.ts states for the service-role client, applied in SQL.
--
-- The parameter is `job`, not `job_id`: job_id is not a column here, but
-- recipe_id is, and D30's lesson was learned once already.

create or replace function finish_import_job(job uuid, recipe uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- The explicit predicate. is_household_member() reads auth.uid(), so this
  -- is the same question the SELECT policy asks, asked by hand because the
  -- policy no longer applies.
  if not exists (
    select 1 from import_jobs j
    where j.id = job
      and j.deleted_at is null
      and is_household_member(j.household_id)
  ) then
    raise exception 'import job not found or not visible'
      using errcode = '42501';
  end if;

  -- Guarded rather than unconditional: a job may only be completed from
  -- needs_review. Without this, a retry that lands twice would overwrite the
  -- recipe_id of an already-saved import with a second recipe.
  update import_jobs
  set status = 'done', recipe_id = recipe
  where id = job and status = 'needs_review';

  if not found then
    raise exception 'import job is not awaiting review'
      using errcode = '22023';
  end if;
end;
$$;

comment on function finish_import_job(uuid, uuid) is
  'Marks a reviewed import done and points it at the recipe the confirm '
  'screen saved. security definer, because import_jobs has no UPDATE policy '
  '(D39) -- membership is checked explicitly inside.';

create or replace function dismiss_import_job(job uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update import_jobs
  set deleted_at = now()
  where id = job
    and deleted_at is null
    and is_household_member(household_id);

  if not found then
    raise exception 'import job not found or not visible'
      using errcode = '42501';
  end if;
end;
$$;

comment on function dismiss_import_job(uuid) is
  'Soft-deletes an import job, which is how a failed one leaves the queue '
  '(rule 4 -- no hard deletes). security definer with the membership check '
  'inline, for the same reason finish_import_job is.';

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
-- D39. All three tables are read-only to clients. No deleted_at clause in any
-- policy (D23): tombstones stay visible so Phase 2's delta fetch can evict
-- them from the Drift cache, and data/ does the filtering.

alter table import_jobs enable row level security;

create policy import_jobs_select on import_jobs for select
  using (is_household_member(household_id));
-- No INSERT policy: the job row is created by the import Edge Function on the
-- service role, which resolves the household from the caller's membership.
-- The client has no business naming a household it might not belong to -- the
-- same argument create-invite makes.
-- No UPDATE policy: see finish_import_job above.
-- No DELETE policy: deletion is a soft delete, which is an UPDATE (rule 4).

alter table ai_usage enable row level security;

create policy ai_usage_select on ai_usage for select
  using (is_household_member(household_id));
-- No write policies at all. "Client may read its own household's usage; only
-- the service role writes" (docs/DATA_MODEL.md).

alter table household_ai_limits enable row level security;

create policy household_ai_limits_select on household_ai_limits for select
  using (is_household_member(household_id));
-- No write policies. Raising your own spending cap is not a client operation.
-- When there is a screen for it, it will be an Edge Function or an RPC with an
-- owner check, not a policy.

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
-- Revoking PUBLIC alone is not enough: Supabase's default privileges grant
-- anon and authenticated EXECUTE on new functions unless they are named. That
-- was learned in merge_ingredients (D30) and is repeated here rather than
-- rediscovered.
--
-- ai_quota_status and ensure_ai_limits are service-role/internal: a client
-- reading its own quota can select the two tables directly through the
-- policies above.

revoke execute on function ai_quota_status(uuid)
  from public, anon, authenticated;
grant execute on function ai_quota_status(uuid)
  to service_role;

revoke execute on function ensure_ai_limits()
  from public, anon, authenticated;

-- These two ARE for clients -- the confirm screen calls them on a human
-- decision -- so authenticated keeps EXECUTE and anon does not.
revoke execute on function finish_import_job(uuid, uuid) from public, anon;
revoke execute on function dismiss_import_job(uuid) from public, anon;

grant execute on function finish_import_job(uuid, uuid)
  to authenticated, service_role;
grant execute on function dismiss_import_job(uuid)
  to authenticated, service_role;
