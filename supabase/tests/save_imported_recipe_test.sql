-- Test: save_imported_recipe (Phase 1d, D44).
--
-- The function D37 said to write only if import needed a recipe and its lines
-- as one unit from the server side. What is worth asserting is therefore not
-- that it inserts a row -- it is that the three steps travel together, that it
-- refuses every job it should, and that household_id comes from the JOB rather
-- than from the payload a client sent.
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from the other test files (3/4).

do $$
declare
  user_3 uuid := '33333333-3333-3333-3333-333333333333';
  user_4 uuid := '44444444-4444-4444-4444-444444444444';

  hid_3     uuid;
  hid_4     uuid;
  job_3     uuid;
  job_4     uuid;
  job_bad   uuid;
  rid       uuid;
  brasno    uuid;
  n         int;
  txt       text;
  failures  int := 0;
  got_error boolean;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  delete from import_jobs
    where household_id in (select id from households
                           where created_by in (user_3, user_4));
  delete from recipes where title like 'zzz saved%';
  delete from households where created_by in (user_3, user_4);
  delete from auth.users where id in (user_3, user_4);

  insert into auth.users (id, email) values
    (user_3, 'save-3@example.com'),
    (user_4, 'save-4@example.com');

  select id into brasno from ingredients where key = 'brasno';

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_3, 'role', 'authenticated')::text, true);
  select create_household('zzz saved household three') into hid_3;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_4, 'role', 'authenticated')::text, true);
  select create_household('zzz saved household four') into hid_4;

  perform set_config('role', 'postgres', true);

  insert into import_jobs (household_id, created_by, kind, status, result)
  values (hid_3, user_3, 'text', 'needs_review', '{}'::jsonb)
  returning id into job_3;

  insert into import_jobs (household_id, created_by, kind, status, result)
  values (hid_4, user_4, 'text', 'needs_review', '{}'::jsonb)
  returning id into job_4;

  -- A job that has not been read yet.
  insert into import_jobs (household_id, created_by, kind, status)
  values (hid_3, user_3, 'text', 'processing')
  returning id into job_bad;

  ---------------------------------------------------------------------------
  -- The happy path: recipe, lines, steps and the job, all in one call
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_3, 'role', 'authenticated')::text, true);

  select save_imported_recipe(
    job_3,
    jsonb_build_object(
      'title', 'zzz saved Šargarepa torta',
      'original_locale', 'sr',
      'source_type', 'url_import',
      'source_url', 'https://example.com/zzz',
      'source_attribution', 'Example Cookbook',
      'servings', 4,
      'tags', jsonb_build_array('kolač', 'zzz')
    ),
    jsonb_build_array(
      jsonb_build_object('raw_text', '200 g šargarepe',
        'ingredient_id', brasno, 'qty_num', 200, 'qty_den', 1,
        'unit_code', 'g', 'match_method', 'llm', 'match_confidence', 0.8),
      jsonb_build_object('raw_text', 'za posluživanje')
    ),
    jsonb_build_array(
      jsonb_build_object('text', 'Zagrejati rernu.'),
      jsonb_build_object('text', 'Pomešati sve.', 'timer_seconds', 300)
    )
  ) into rid;

  if rid is null then
    failures := failures + 1;
    raise warning 'save_imported_recipe returned null';
  end if;

  -- household_id came from the JOB. Nothing in the payload named one, and
  -- nothing in the payload may.
  select count(*) into n from recipes
   where id = rid and household_id = hid_3 and created_by = user_3;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'recipe not scoped to the job''s household';
  end if;

  -- Anything AI-produced is draft until a human marks it tested.
  select status into txt from recipes where id = rid;
  if txt <> 'draft' then
    failures := failures + 1;
    raise warning 'imported recipe saved as `%`, expected draft', txt;
  end if;

  select source_type into txt from recipes where id = rid;
  if txt <> 'url_import' then
    failures := failures + 1;
    raise warning 'source_type wrong: %', txt;
  end if;

  -- Attribution is stored, per the standing rules -- an import that loses
  -- where it came from is the one thing D16 will not have.
  select source_attribution into txt from recipes where id = rid;
  if txt is distinct from 'Example Cookbook' then
    failures := failures + 1;
    raise warning 'source_attribution not stored: %', txt;
  end if;

  select count(*) into n from recipe_ingredients where recipe_id = rid;
  if n <> 2 then
    failures := failures + 1;
    raise warning 'expected 2 ingredient lines, got %', n;
  end if;

  -- Rule 3: the unmatched line still landed, with its raw_text intact.
  select count(*) into n from recipe_ingredients
   where recipe_id = rid and raw_text = 'za posluživanje'
     and ingredient_id is null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the unmatched line did not survive (rule 3)';
  end if;

  -- D7: the machine tier's provenance is carried through, not flattened.
  select match_method into txt from recipe_ingredients
   where recipe_id = rid and raw_text = '200 g šargarepe';
  if txt is distinct from 'llm' then
    failures := failures + 1;
    raise warning 'match_method not preserved: %', txt;
  end if;

  select count(*) into n from recipe_steps where recipe_id = rid;
  if n <> 2 then
    failures := failures + 1;
    raise warning 'expected 2 steps, got %', n;
  end if;

  -- And the job is done, pointing at the recipe -- the third of the three
  -- steps that had to travel with the other two.
  select count(*) into n from import_jobs
   where id = job_3 and status = 'done' and recipe_id = rid;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the job was not completed by save_imported_recipe';
  end if;

  ---------------------------------------------------------------------------
  -- Refusals
  ---------------------------------------------------------------------------
  -- Another household's job. The whole reason the function is definer is that
  -- RLS is not behind it, so this is the assertion that matters most.
  got_error := false;
  begin
    perform save_imported_recipe(job_4,
      jsonb_build_object('title', 'zzz saved stolen', 'original_locale', 'sr'));
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'saved a recipe from another household''s job';
  end if;

  select count(*) into n from recipes where title = 'zzz saved stolen';
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a recipe was left behind by the refused call';
  end if;

  -- A job that has not been read yet.
  got_error := false;
  begin
    perform save_imported_recipe(job_bad,
      jsonb_build_object('title', 'zzz saved early', 'original_locale', 'sr'));
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'saved a job that was not awaiting review';
  end if;

  -- Nothing inserted: the status guard runs BEFORE the insert, so this does
  -- not depend on the transaction rolling back to be true.
  select count(*) into n from recipes where title = 'zzz saved early';
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a recipe was inserted for a job not awaiting review';
  end if;

  -- The same job twice. finish_import_job refuses a job already done, and
  -- that refusal has to take the second recipe with it -- otherwise the retry
  -- this function exists to prevent creates a duplicate after all.
  got_error := false;
  begin
    perform save_imported_recipe(job_3,
      jsonb_build_object('title', 'zzz saved twice', 'original_locale', 'sr'));
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'saved the same import job twice';
  end if;

  select count(*) into n from recipes where title = 'zzz saved twice';
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a duplicate recipe survived the second save (D44)';
  end if;

  ---------------------------------------------------------------------------
  -- anon may not call it
  ---------------------------------------------------------------------------
  perform set_config('role', 'anon', true);
  perform set_config('request.jwt.claims', null, true);

  got_error := false;
  begin
    perform save_imported_recipe(job_4,
      jsonb_build_object('title', 'zzz saved anon', 'original_locale', 'sr'));
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'anon can execute save_imported_recipe';
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  delete from import_jobs where household_id in (hid_3, hid_4);
  delete from recipes where title like 'zzz saved%';
  delete from households where id in (hid_3, hid_4);
  delete from auth.users where id in (user_3, user_4);

  if failures > 0 then
    raise exception '% save_imported_recipe assertion(s) failed', failures;
  end if;
  raise notice 'save_imported_recipe: all assertions passed';
end
$$;
