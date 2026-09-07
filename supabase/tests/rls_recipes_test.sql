-- RLS test: recipes, recipe_ingredients, recipe_steps (Phase 1c).
--
-- The first tables whose child rows are scoped through a parent rather than
-- through their own household_id, so the interesting assertions are the
-- negative ones: a non-member must not reach a line by way of its recipe, and
-- must not be able to attach a line to somebody else's recipe.
--
-- Also covers the two functions the migration added -- ingredient_display_names
-- and replace_recipe_lines -- because both are reachable by any signed-in user
-- and neither may become a way around a policy.
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from the other test files (e/f).

do $$
declare
  user_e uuid := 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
  user_f uuid := 'ffffffff-ffff-ffff-ffff-ffffffffffff';

  hid_e     uuid;
  rid       uuid;
  line_id   uuid;
  brasno    uuid;
  n         int;
  txt       text;
  failures  int := 0;
  got_error boolean;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  delete from recipes where title like 'zzz recipe%';
  delete from households where created_by in (user_e, user_f);
  delete from auth.users where id in (user_e, user_f);

  insert into auth.users (id, email) values
    (user_e, 'recipes-e@example.com'),
    (user_f, 'recipes-f@example.com');

  select id into brasno from ingredients where key = 'brasno';
  if brasno is null then
    failures := failures + 1;
    raise warning 'seed ingredient `brasno` missing -- catalog seed did not run';
  end if;

  ---------------------------------------------------------------------------
  -- E creates a household and a recipe
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_e, 'role', 'authenticated')::text, true);

  select create_household('zzz recipes household') into hid_e;

  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid_e, 'zzz recipe Šargarepa torta', 'sr', 'manual', user_e)
  returning id into rid;

  select count(*) into n from recipes where id = rid;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'E cannot see the recipe they just created';
  end if;

  -- title_normalized is a stored generated column, so the diacritics and the
  -- capital are already folded. This is what the recipe list searches.
  select title_normalized into txt from recipes where id = rid;
  if txt <> 'zzz recipe sargarepa torta' then
    failures := failures + 1;
    raise warning 'title_normalized wrong: expected `zzz recipe sargarepa torta`, got `%`', txt;
  end if;

  ---------------------------------------------------------------------------
  -- Lines and steps, written through replace_recipe_lines
  ---------------------------------------------------------------------------
  perform replace_recipe_lines(
    rid,
    jsonb_build_array(
      jsonb_build_object(
        'raw_text', '200 g šargarepe',
        'ingredient_id', brasno,
        'qty_num', 200, 'qty_den', 1,
        'unit_code', 'g',
        'match_method', 'manual',
        'match_confidence', 1.0),
      jsonb_build_object(
        'raw_text', 'kašika ajvara',
        'is_optional', true,
        'note', 'po želji')
    ),
    jsonb_build_array(
      jsonb_build_object('text', 'Zagrej rernu.'),
      jsonb_build_object('text', 'Peci 40 minuta.', 'timer_seconds', 2400)
    )
  );

  select count(*) into n from recipe_ingredients where recipe_id = rid;
  if n <> 2 then
    failures := failures + 1;
    raise warning 'expected 2 ingredient lines, got %', n;
  end if;

  -- Position comes from array order, not from the payload.
  select count(*) into n
    from recipe_ingredients
   where recipe_id = rid and position = 1 and raw_text = 'kašika ajvara'
     and is_optional and ingredient_id is null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'second line did not land at position 1 with null ingredient_id';
  end if;

  select count(*) into n
    from recipe_steps where recipe_id = rid and position = 1
      and timer_seconds = 2400;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'second step did not land at position 1 with its timer';
  end if;

  -- Replacing is a replace, not an append.
  perform replace_recipe_lines(
    rid,
    jsonb_build_array(jsonb_build_object('raw_text', 'so po ukusu')),
    '[]'::jsonb);

  select count(*) into n from recipe_ingredients where recipe_id = rid;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'replace_recipe_lines appended instead of replacing: % rows', n;
  end if;

  select count(*) into n from recipe_steps where recipe_id = rid;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'replace_recipe_lines left % step(s) behind', n;
  end if;

  ---------------------------------------------------------------------------
  -- rule 3: raw_text is NOT NULL, always
  ---------------------------------------------------------------------------
  got_error := false;
  begin
    insert into recipe_ingredients (recipe_id, position, raw_text)
    values (rid, 9, null);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a null raw_text was accepted (CLAUDE.md rule 3)';
  end if;

  -- rule 5: a numerator without a denominator is not a fraction.
  got_error := false;
  begin
    insert into recipe_ingredients (recipe_id, position, raw_text, qty_num)
    values (rid, 9, 'pola limuna', 1);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'qty_num without qty_den was accepted';
  end if;

  ---------------------------------------------------------------------------
  -- ingredient_display_names renders from the catalog (D1)
  ---------------------------------------------------------------------------
  select display_name into txt
    from ingredient_display_names(array[brasno], 'sr');
  if txt <> 'brašno' then
    failures := failures + 1;
    raise warning 'ingredient_display_names(sr) gave `%`, expected `brašno`', txt;
  end if;

  select display_name into txt
    from ingredient_display_names(array[brasno], 'en');
  if txt <> 'flour' then
    failures := failures + 1;
    raise warning 'ingredient_display_names(en) gave `%`, expected `flour`', txt;
  end if;

  ---------------------------------------------------------------------------
  -- F is in no household and must see and touch nothing
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_f, 'role', 'authenticated')::text, true);

  select count(*) into n from recipes where id = rid;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a non-member can see another household''s recipe';
  end if;

  select count(*) into n from recipe_ingredients where recipe_id = rid;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a non-member can read ingredient lines through the child table';
  end if;

  select count(*) into n from recipe_steps where recipe_id = rid;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a non-member can read steps through the child table';
  end if;

  -- The one that matters: attaching a line to somebody else's recipe.
  got_error := false;
  begin
    insert into recipe_ingredients (recipe_id, position, raw_text)
    values (rid, 5, 'zzz injected line');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a non-member inserted a line onto another household''s recipe';
  end if;

  -- And doing it through the function, which is security invoker precisely so
  -- that this is refused rather than granted.
  got_error := false;
  begin
    perform replace_recipe_lines(
      rid, jsonb_build_array(jsonb_build_object('raw_text', 'zzz injected')),
      '[]'::jsonb);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'replace_recipe_lines let a non-member rewrite a recipe';
  end if;

  -- The refusal must not have been a silent no-op either.
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_e, 'role', 'authenticated')::text, true);
  select count(*) into n from recipe_ingredients where recipe_id = rid;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'E''s line list was disturbed by F''s attempt: % rows', n;
  end if;

  ---------------------------------------------------------------------------
  -- Soft delete: a tombstone stays visible to the policy (D23)
  ---------------------------------------------------------------------------
  update recipes set deleted_at = now() where id = rid;

  select count(*) into n from recipes where id = rid;
  if n <> 1 then
    failures := failures + 1;
    raise warning
      'a soft-deleted recipe vanished from RLS -- Phase 2 could never evict it';
  end if;

  -- There is no DELETE policy, so a hard delete must fail to remove anything.
  delete from recipes where id = rid;
  select count(*) into n from recipes where id = rid;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'a hard delete of a recipe succeeded (rule 4)';
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  delete from recipes where title like 'zzz recipe%';
  delete from households where created_by in (user_e, user_f);
  delete from auth.users where id in (user_e, user_f);

  if failures > 0 then
    raise exception '% recipe RLS assertion(s) failed', failures;
  end if;

  raise notice 'recipe RLS: all assertions passed';
end
$$;
