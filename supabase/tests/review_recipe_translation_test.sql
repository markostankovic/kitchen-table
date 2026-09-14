-- Function test: review_recipe_translation (Phase 3, part 3).
--
-- A new file rather than an extension of rls_recipe_translations_test.sql:
-- that file is already 342 lines inside one `do $$` block, this project
-- already splits RLS suites from per-function ones (merge_ingredients_test.sql,
-- save_imported_recipe_test.sql), and this suite needs its own fixture left
-- in a reviewed state the existing file's flow does not produce.
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from every other test file (a1a1.../b2b2...,
-- c3c3.../d4d4..., e5e5.../f6f6..., a7a7.../b8b8... are all taken; this file
-- uses c9c9.../dada...).

do $$
declare
  user_a uuid := 'c9c9c9c9-c9c9-c9c9-c9c9-c9c9c9c9c9c9';
  user_b uuid := 'dadadada-dada-dada-dada-dadadadadada';

  hid_a        uuid;
  hid_b        uuid;
  recipe_a     uuid;
  recipe_b     uuid;
  translation_id  uuid;
  translation_tmp uuid;

  n            int;
  txt          text;
  reviewer     uuid;
  reviewed_ts  timestamptz;
  is_machine   boolean;
  steps_out    jsonb;
  got_error    boolean;
  got_code     text;
  ts_before    timestamptz;
  ts_after     timestamptz;
  failures     int := 0;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  delete from recipes where title like 'zzz review%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  insert into auth.users (id, email) values
    (user_a, 'review-a@example.com'),
    (user_b, 'review-b@example.com');

  ---------------------------------------------------------------------------
  -- A creates a household, a Serbian recipe with two steps, and a machine
  -- translation into English -- via save_recipe_translation, the same door
  -- translate-recipe uses, so this suite starts from a realistic row.
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select create_household('zzz review household a') into hid_a;

  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid_a, 'zzz review recipe', 'sr', 'manual', user_a)
  returning id into recipe_a;

  insert into recipe_steps (recipe_id, position, text)
  values (recipe_a, 0, 'Umutiti brašno.'), (recipe_a, 1, 'Ispeći.');

  select save_recipe_translation(
    recipe_a, 'en', 'zzz machine title', 'a machine description',
    jsonb_build_array(
      jsonb_build_object('position', 0, 'text', 'Mix the flour.'),
      jsonb_build_object('position', 1, 'text', 'Bake it.')
    )
  ) into translation_id;

  ---------------------------------------------------------------------------
  -- B creates a second household, to prove isolation
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);
  select create_household('zzz review household b') into hid_b;
  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid_b, 'zzz review recipe b', 'en', 'manual', user_b)
  returning id into recipe_b;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  ---------------------------------------------------------------------------
  -- Happy path: reviewing edits the SAME row, not a second one, and stamps
  -- provenance
  ---------------------------------------------------------------------------
  select review_recipe_translation(
    recipe_a, 'en', 'zzz reviewed title', 'a reviewed description',
    jsonb_build_array(
      jsonb_build_object('position', 0, 'text', 'Whisk the flour well.'),
      jsonb_build_object('position', 1, 'text', 'Bake until golden.')
    )
  ) into translation_tmp;

  if translation_tmp <> translation_id then
    failures := failures + 1;
    raise warning 'review_recipe_translation changed the row''s id -- expected an update in place';
  end if;

  select count(*) into n from recipe_translations where recipe_id = recipe_a;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'expected 1 translation row after review, found %', n;
  end if;

  select title, is_machine_generated, reviewed_by, reviewed_at, steps
    into txt, is_machine, reviewer, reviewed_ts, steps_out
    from recipe_translations where id = translation_id;

  if txt <> 'zzz reviewed title' then
    failures := failures + 1;
    raise warning 'review did not overwrite the title, got `%`', txt;
  end if;
  if is_machine <> false then
    failures := failures + 1;
    raise warning 'is_machine_generated is still true after review';
  end if;
  if reviewer <> user_a then
    failures := failures + 1;
    raise warning 'reviewed_by is %, expected the caller %', reviewer, user_a;
  end if;
  if reviewed_ts is null then
    failures := failures + 1;
    raise warning 'reviewed_at was not stamped';
  end if;
  if steps_out -> 0 ->> 'text' <> 'Whisk the flour well.' then
    failures := failures + 1;
    raise warning 'reviewed step text did not save, got `%`', steps_out;
  end if;

  ---------------------------------------------------------------------------
  -- Refusals -- each checked to leave the row byte-for-byte unchanged
  ---------------------------------------------------------------------------

  -- No translation row for this locale: review edits, it never creates.
  got_error := false; got_code := null;
  begin
    perform review_recipe_translation(recipe_a, 'sr', 'x', null, '[]'::jsonb);
  exception when others then got_error := true; got_code := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'reviewing a locale with no existing translation was accepted';
  elsif got_code <> '22023' then
    failures := failures + 1;
    raise warning 'missing translation raised %, expected 22023', got_code;
  end if;

  -- Unknown locale.
  got_error := false; got_code := null;
  begin
    perform review_recipe_translation(recipe_a, 'de', 'x', null, '[]'::jsonb);
  exception when others then got_error := true; got_code := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'locale ''de'' was accepted';
  elsif got_code <> '22023' then
    failures := failures + 1;
    raise warning 'locale ''de'' raised %, expected 22023', got_code;
  end if;

  -- The recipe's own original_locale.
  got_error := false; got_code := null;
  begin
    perform review_recipe_translation(recipe_a, 'sr', 'zzz x', null,
      jsonb_build_array(jsonb_build_object('position', 0, 'text', 'x')));
  exception when others then got_error := true; got_code := sqlstate;
  end;
  -- Falls through to the "no translation" guard first (sr has no row here),
  -- both 22023, so only the errcode is asserted.
  if not got_error or got_code <> '22023' then
    failures := failures + 1;
    raise warning 'own-locale review raised %, expected 22023', got_code;
  end if;

  -- Blank title.
  got_error := false; got_code := null;
  begin
    perform review_recipe_translation(recipe_a, 'en', '   ', null,
      jsonb_build_array(
        jsonb_build_object('position', 0, 'text', 'x'),
        jsonb_build_object('position', 1, 'text', 'y')
      ));
  exception when others then got_error := true; got_code := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a blank title was accepted';
  elsif got_code <> '22023' then
    failures := failures + 1;
    raise warning 'blank title raised %, expected 22023', got_code;
  end if;

  -- Blank step text.
  got_error := false; got_code := null;
  begin
    perform review_recipe_translation(recipe_a, 'en', 'zzz x', null,
      jsonb_build_array(
        jsonb_build_object('position', 0, 'text', '  '),
        jsonb_build_object('position', 1, 'text', 'y')
      ));
  exception when others then got_error := true; got_code := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a blank step text was accepted';
  elsif got_code <> '22023' then
    failures := failures + 1;
    raise warning 'blank step text raised %, expected 22023', got_code;
  end if;

  -- Dropped step (only position 0 sent).
  got_error := false; got_code := null;
  begin
    perform review_recipe_translation(recipe_a, 'en', 'zzz x', null,
      jsonb_build_array(jsonb_build_object('position', 0, 'text', 'x')));
  exception when others then got_error := true; got_code := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'dropping a step was accepted';
  elsif got_code <> '22023' then
    failures := failures + 1;
    raise warning 'dropped step raised %, expected 22023', got_code;
  end if;

  -- Added step (position 2 not on the row).
  got_error := false; got_code := null;
  begin
    perform review_recipe_translation(recipe_a, 'en', 'zzz x', null,
      jsonb_build_array(
        jsonb_build_object('position', 0, 'text', 'x'),
        jsonb_build_object('position', 1, 'text', 'y'),
        jsonb_build_object('position', 2, 'text', 'z')
      ));
  exception when others then got_error := true; got_code := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'adding a step was accepted';
  elsif got_code <> '22023' then
    failures := failures + 1;
    raise warning 'added step raised %, expected 22023', got_code;
  end if;

  -- Renumbered step (0,1 sent as 0,5).
  got_error := false; got_code := null;
  begin
    perform review_recipe_translation(recipe_a, 'en', 'zzz x', null,
      jsonb_build_array(
        jsonb_build_object('position', 0, 'text', 'x'),
        jsonb_build_object('position', 5, 'text', 'y')
      ));
  exception when others then got_error := true; got_code := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'renumbering a step was accepted';
  elsif got_code <> '22023' then
    failures := failures + 1;
    raise warning 'renumbered step raised %, expected 22023', got_code;
  end if;

  -- The row is unchanged after all of the refusals above.
  select title, is_machine_generated, reviewed_by, steps
    into txt, is_machine, reviewer, steps_out
    from recipe_translations where id = translation_id;
  if txt <> 'zzz reviewed title' or is_machine <> false or reviewer <> user_a
     or steps_out -> 0 ->> 'text' <> 'Whisk the flour well.' then
    failures := failures + 1;
    raise warning 'a refused review call mutated the row anyway';
  end if;

  -- A foreign or nonexistent recipe id.
  got_error := false; got_code := null;
  begin
    perform review_recipe_translation(recipe_b, 'sr', 'zzz x', null, '[]'::jsonb);
  exception when others then got_error := true; got_code := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'A reviewed a translation on household B''s recipe';
  elsif got_code <> '42501' then
    failures := failures + 1;
    raise warning 'foreign recipe raised %, expected 42501', got_code;
  end if;

  ---------------------------------------------------------------------------
  -- B (a non-member of household A) cannot review A's translation
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  got_error := false; got_code := null;
  begin
    perform review_recipe_translation(recipe_a, 'en', 'zzz hijacked', null,
      jsonb_build_array(
        jsonb_build_object('position', 0, 'text', 'x'),
        jsonb_build_object('position', 1, 'text', 'y')
      ));
  exception when others then got_error := true; got_code := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a non-member reviewed household A''s recipe translation';
  elsif got_code <> '42501' then
    failures := failures + 1;
    raise warning 'non-member review raised %, expected 42501', got_code;
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  ---------------------------------------------------------------------------
  -- reviewed_by follows the CALLER, never a client-supplied value: review as
  -- A, confirm reviewed_by = A; add B to household A, review again as B,
  -- confirm reviewed_by moves to B.
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  insert into household_members (household_id, user_id, role)
  values (hid_a, user_b, 'adult');
  perform set_config('role', 'authenticated', true);

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  perform review_recipe_translation(recipe_a, 'en', 'zzz reviewed by b', null,
    jsonb_build_array(
      jsonb_build_object('position', 0, 'text', 'x'),
      jsonb_build_object('position', 1, 'text', 'y')
    ));

  select reviewed_by into reviewer from recipe_translations
    where id = translation_id;
  if reviewer <> user_b then
    failures := failures + 1;
    raise warning 'reviewed_by is %, expected the new caller %', reviewer, user_b;
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  ---------------------------------------------------------------------------
  -- The invalidation invariant: save_recipe_translation over a reviewed row
  -- resets the review. This is the entire justification for two functions.
  ---------------------------------------------------------------------------
  perform save_recipe_translation(
    recipe_a, 'en', 'zzz re-translated title', null,
    jsonb_build_array(jsonb_build_object('position', 0, 'text', 'Mix again.')));

  select is_machine_generated, reviewed_by, reviewed_at
    into is_machine, reviewer, reviewed_ts
    from recipe_translations where id = translation_id;

  if is_machine <> true or reviewer is not null or reviewed_ts is not null then
    failures := failures + 1;
    raise warning
      're-translating a reviewed row did not reset it (machine=%, by=%, at=%)',
      is_machine, reviewer, reviewed_ts;
  end if;

  -- Restore a two-step translation for the trigger check below.
  perform save_recipe_translation(
    recipe_a, 'en', 'zzz retranslated again', null,
    jsonb_build_array(
      jsonb_build_object('position', 0, 'text', 'x'),
      jsonb_build_object('position', 1, 'text', 'y')
    ));

  ---------------------------------------------------------------------------
  -- The touch trigger fires on a review too (migration 17's trigger, not
  -- reimplemented here) -- now() is transaction time, so freeze and backdate
  -- by hand, the same dance rls_recipe_translations_test.sql uses.
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  execute 'alter table recipes disable trigger recipes_set_updated_at';
  perform set_config('role', 'authenticated', true);
  update recipes set updated_at = timestamptz '2020-01-01' where id = recipe_a;
  perform set_config('role', 'postgres', true);
  execute 'alter table recipes enable trigger recipes_set_updated_at';
  perform set_config('role', 'authenticated', true);

  select updated_at into ts_before from recipes where id = recipe_a;

  perform review_recipe_translation(recipe_a, 'en', 'zzz touched by review', null,
    jsonb_build_array(
      jsonb_build_object('position', 0, 'text', 'x'),
      jsonb_build_object('position', 1, 'text', 'y')
    ));

  select updated_at into ts_after from recipes where id = recipe_a;
  if ts_after <= ts_before then
    failures := failures + 1;
    raise warning
      'reviewing a translation did not move recipes.updated_at (% -> %)',
      ts_before, ts_after;
  end if;

  ---------------------------------------------------------------------------
  -- Grants
  ---------------------------------------------------------------------------
  if not has_function_privilege('authenticated',
       'review_recipe_translation(uuid,text,text,text,jsonb)', 'execute') then
    failures := failures + 1;
    raise warning 'authenticated cannot execute review_recipe_translation';
  end if;

  if has_function_privilege('anon',
       'review_recipe_translation(uuid,text,text,text,jsonb)', 'execute') then
    failures := failures + 1;
    raise warning 'anon can execute review_recipe_translation';
  end if;

  -- service_role is granted for consistency with every other function in
  -- this project, not because anything server-side calls this one -- see the
  -- migration's own comment. Not asserted separately here because Supabase's
  -- platform default already grants it regardless of this migration's own
  -- grant statement, so the assertion would prove nothing either way.

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  set local role postgres;
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  if failures > 0 then
    raise exception 'review_recipe_translation_test: % assertion(s) failed', failures;
  end if;
  raise notice 'review_recipe_translation_test: all assertions passed';
end;
$$;
