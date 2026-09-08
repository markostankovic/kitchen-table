-- RLS test: import_jobs, ai_usage, household_ai_limits (Phase 1d).
--
-- The interesting assertions here are almost all negative. These are the first
-- three tables in the project that clients may READ and may not WRITE at all
-- (D39), so what needs proving is not that a member can see their jobs -- it is
-- that a member cannot insert one, cannot flip one to 'done' by hand, and
-- cannot raise their own spending cap.
--
-- Also covers the four functions the migration added, because each is
-- reachable by a signed-in user or holds a rule that only lives in SQL:
-- ai_quota_status (both caps and the month window, D17), finish_import_job and
-- dismiss_import_job (the client's entire write surface), and the trigger that
-- guarantees every household a limits row (D40).
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from the other test files (1/2).

do $$
declare
  user_1 uuid := '11111111-1111-1111-1111-111111111111';
  user_2 uuid := '22222222-2222-2222-2222-222222222222';

  hid_1     uuid;
  hid_2     uuid;
  job_1     uuid;
  job_2     uuid;
  rid       uuid;
  n         int;
  cap_calls int;
  cap_cost  bigint;
  ok        boolean;
  failures  int := 0;
  got_error boolean;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  delete from import_jobs
    where household_id in (select id from households
                           where created_by in (user_1, user_2));
  delete from recipes where title like 'zzz import%';
  delete from ai_usage
    where household_id in (select id from households
                           where created_by in (user_1, user_2));
  delete from households where created_by in (user_1, user_2);
  delete from auth.users where id in (user_1, user_2);

  insert into auth.users (id, email) values
    (user_1, 'import-1@example.com'),
    (user_2, 'import-2@example.com');

  ---------------------------------------------------------------------------
  -- Two households, two members who share nothing
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_1, 'role', 'authenticated')::text, true);
  select create_household('zzz import household one') into hid_1;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_2, 'role', 'authenticated')::text, true);
  select create_household('zzz import household two') into hid_2;

  ---------------------------------------------------------------------------
  -- D40: the trigger gave each household a limits row, at the column defaults
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);

  select count(*) into n from household_ai_limits
   where household_id in (hid_1, hid_2);
  if n <> 2 then
    failures := failures + 1;
    raise warning 'households_ensure_ai_limits did not fire: % of 2 rows', n;
  end if;

  select monthly_call_cap, monthly_cost_cap_micros
    into cap_calls, cap_cost
    from household_ai_limits where household_id = hid_1;
  if cap_calls <> 500 or cap_cost <> 300000000 then
    failures := failures + 1;
    raise warning 'default caps wrong: % calls, % micros', cap_calls, cap_cost;
  end if;

  ---------------------------------------------------------------------------
  -- Jobs, inserted as the service role would (there is no client INSERT path)
  ---------------------------------------------------------------------------
  insert into import_jobs (household_id, created_by, kind, input_url, status)
  values (hid_1, user_1, 'url', 'https://example.com/zzz', 'needs_review')
  returning id into job_1;

  insert into import_jobs (household_id, created_by, kind, input_text, status)
  values (hid_2, user_2, 'text', 'zzz other household', 'needs_review')
  returning id into job_2;

  ---------------------------------------------------------------------------
  -- SELECT is scoped by membership
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_1, 'role', 'authenticated')::text, true);

  select count(*) into n from import_jobs where id = job_1;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'member 1 cannot see their own household''s import job';
  end if;

  select count(*) into n from import_jobs where id = job_2;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'member 1 can see another household''s import job';
  end if;

  ---------------------------------------------------------------------------
  -- D39: no client write path on any of the three tables
  ---------------------------------------------------------------------------
  -- A client that could INSERT could name a household it does not belong to,
  -- or hand itself a job whose `result` it wrote.
  got_error := false;
  begin
    insert into import_jobs (household_id, created_by, kind, input_text)
    values (hid_1, user_1, 'text', 'zzz self-served');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a client inserted an import job (D39)';
  end if;

  -- The one that matters most: UPDATE cannot restrict which columns it
  -- touches, so a permissive policy would let any client write `result` and
  -- have the confirm screen render it.
  got_error := false;
  begin
    update import_jobs
       set status = 'needs_review',
           result = '{"title":"zzz forged"}'::jsonb
     where id = job_1;
    -- RLS makes a forbidden UPDATE match zero rows rather than raise, so the
    -- absence of an exception is not the assertion. The value is.
    if exists (select 1 from import_jobs
                where id = job_1 and result is not null) then
      got_error := false;
    else
      got_error := true;
    end if;
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a client wrote import_jobs.result directly (D39)';
  end if;

  got_error := false;
  begin
    update household_ai_limits
       set monthly_cost_cap_micros = 999999999999
     where household_id = hid_1;
    if exists (select 1 from household_ai_limits
                where household_id = hid_1
                  and monthly_cost_cap_micros = 999999999999) then
      got_error := false;
    else
      got_error := true;
    end if;
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a client raised its own AI spending cap (D39)';
  end if;

  got_error := false;
  begin
    insert into ai_usage (household_id, function_name, model)
    values (hid_1, 'zzz-forged', 'zzz-model');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a client wrote the ai_usage ledger (D39)';
  end if;

  -- ai_quota_status is service-role only: a client that could call it could
  -- read another household's spend by passing its id, since the function is
  -- security definer and takes the household as a parameter.
  got_error := false;
  begin
    perform * from ai_quota_status(hid_2);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'authenticated can execute ai_quota_status';
  end if;

  ---------------------------------------------------------------------------
  -- finish_import_job / dismiss_import_job
  ---------------------------------------------------------------------------
  -- Refuses a job the caller cannot see. security invoker is what makes this
  -- true, and it is the whole reason these are not security definer.
  got_error := false;
  begin
    perform finish_import_job(job_2, null);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'finish_import_job accepted another household''s job';
  end if;

  -- The happy path, from needs_review.
  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid_1, 'zzz import saved recipe', 'sr', 'url_import', user_1)
  returning id into rid;

  perform finish_import_job(job_1, rid);

  select count(*) into n from import_jobs
   where id = job_1 and status = 'done' and recipe_id = rid;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'finish_import_job did not complete the job';
  end if;

  -- Not idempotent, deliberately: a retry that landed twice would repoint an
  -- already-saved import at a second recipe.
  got_error := false;
  begin
    perform finish_import_job(job_1, rid);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'finish_import_job completed an already-done job';
  end if;

  -- Soft delete, because rule 4 has no hard deletes.
  perform dismiss_import_job(job_1);
  select count(*) into n from import_jobs
   where id = job_1 and deleted_at is not null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'dismiss_import_job did not set deleted_at';
  end if;

  -- D23: the tombstone stays VISIBLE through RLS. Phase 2's delta fetch has to
  -- see it in order to evict the row from the Drift cache; data/ filters it.
  select count(*) into n from import_jobs where id = job_1;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'a soft-deleted job vanished from RLS (D23)';
  end if;

  ---------------------------------------------------------------------------
  -- ai_quota_status: both caps, and the month window
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);

  -- Inside both caps with no usage at all.
  select within_caps into ok from ai_quota_status(hid_1);
  if not ok then
    failures := failures + 1;
    raise warning 'a household with no usage is already over its caps';
  end if;

  -- Last month's spend must not count against this month. Written as a value
  -- that would blow both caps if the window were ignored.
  insert into ai_usage (household_id, user_id, function_name, model,
                        input_tokens, output_tokens, cost_micros, created_at)
  values (hid_1, user_1, 'zzz-last-month', 'zzz-model',
          1000, 1000, 400000000, date_trunc('month', now()) - interval '1 day');

  select within_caps into ok from ai_quota_status(hid_1);
  if not ok then
    failures := failures + 1;
    raise warning 'last month''s spend counted against this month''s cap';
  end if;

  -- The cost cap, on its own.
  insert into ai_usage (household_id, user_id, function_name, model,
                        cost_micros)
  values (hid_1, user_1, 'zzz-expensive', 'zzz-model', 400000000);

  select within_caps, cost_micros_this_month
    into ok, cap_cost from ai_quota_status(hid_1);
  if ok then
    failures := failures + 1;
    raise warning 'the cost cap did not fire at % micros', cap_cost;
  end if;

  delete from ai_usage where function_name = 'zzz-expensive';

  -- The call cap, on its own: 500 free calls, so lower the cap rather than
  -- inserting 500 rows.
  update household_ai_limits set monthly_call_cap = 1 where household_id = hid_1;

  insert into ai_usage (household_id, user_id, function_name, model,
                        cost_micros)
  values (hid_1, user_1, 'zzz-cheap', 'zzz-model', 1);

  select within_caps into ok from ai_quota_status(hid_1);
  if ok then
    failures := failures + 1;
    raise warning 'the call cap did not fire';
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  delete from import_jobs where household_id in (hid_1, hid_2);
  delete from recipes where title like 'zzz import%';
  delete from ai_usage where household_id in (hid_1, hid_2);
  delete from households where id in (hid_1, hid_2);
  delete from auth.users where id in (user_1, user_2);

  if failures > 0 then
    raise exception '% import/usage assertion(s) failed', failures;
  end if;
  raise notice 'import jobs, AI usage and caps: all assertions passed';
end
$$;
