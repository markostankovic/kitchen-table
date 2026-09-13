-- RLS/behaviour test: recipe_translations and save_recipe_translation
-- (Phase 3, part 2).
--
-- Covers the table migration 17 added, its four policies (copied verbatim
-- from recipe_steps's own shape), the touch trigger that hands a translated
-- recipe to the existing delta fetch, and the one function that writes this
-- table. The closing block also asserts the phase's own Done-when in the one
-- place a SQL suite can reach it: a Serbian recipe reading correctly in
-- English, ingredient names included, without a second recipe row existing.
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from the other test files (every single-hex-repeat
-- pattern 1-9/a-f is taken, as are a1a1.../b2b2..., c3c3.../d4d4... and
-- e5e5.../f6f6...; this file uses a7a7.../b8b8...).

do $$
declare
  user_a uuid := 'a7a7a7a7-a7a7-a7a7-a7a7-a7a7a7a7a7a7';
  user_b uuid := 'b8b8b8b8-b8b8-b8b8-b8b8-b8b8b8b8b8b8';

  hid_a       uuid;
  hid_b       uuid;
  recipe_a    uuid;
  recipe_b    uuid;
  brasno      uuid;
  translation_id  uuid;
  translation_tmp uuid;

  n            int;
  txt          text;
  got_error    boolean;
  got_sqlstate text;
  ts_before    timestamptz;
  ts_after     timestamptz;
  failures     int := 0;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  delete from recipes where title like 'zzz translate%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  insert into auth.users (id, email) values
    (user_a, 'translate-a@example.com'),
    (user_b, 'translate-b@example.com');

  select id into brasno from ingredients where key = 'brasno';
  if brasno is null then
    failures := failures + 1;
    raise warning 'seed ingredient `brasno` missing -- catalog seed did not run';
  end if;

  ---------------------------------------------------------------------------
  -- A creates a household and a Serbian recipe with one matched ingredient
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select create_household('zzz translate household a') into hid_a;

  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid_a, 'zzz translate recipe', 'sr', 'manual', user_a)
  returning id into recipe_a;

  insert into recipe_ingredients (recipe_id, position, raw_text, ingredient_id,
                                  qty_num, qty_den, match_method)
  values (recipe_a, 0, '200 g brašna', brasno, 200, 1, 'exact');

  ---------------------------------------------------------------------------
  -- B creates a second household, to prove isolation
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);
  select create_household('zzz translate household b') into hid_b;
  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid_b, 'zzz translate recipe b', 'en', 'manual', user_b)
  returning id into recipe_b;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  ---------------------------------------------------------------------------
  -- save_recipe_translation: the happy path, and the upsert-on-conflict shape
  ---------------------------------------------------------------------------
  select save_recipe_translation(
    recipe_a, 'en', 'zzz translated title', 'a translated description',
    jsonb_build_array(
      jsonb_build_object('position', 0, 'text', 'Mix the flour.'),
      jsonb_build_object('position', 1, 'text', 'Bake it.')
    )
  ) into translation_id;

  if translation_id is null then
    failures := failures + 1;
    raise warning 'save_recipe_translation returned null';
  end if;

  select count(*) into n from recipe_translations where recipe_id = recipe_a;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'expected 1 translation row, found %', n;
  end if;

  -- Re-translating the same locale updates in place -- do update, not a
  -- second row (unique (recipe_id, locale) plus the on-conflict clause).
  select save_recipe_translation(
    recipe_a, 'en', 'zzz translated title, revised', 'revised description',
    jsonb_build_array(jsonb_build_object('position', 0, 'text', 'Mix it well.'))
  ) into translation_tmp;

  if translation_tmp <> translation_id then
    failures := failures + 1;
    raise warning 're-translating changed the row''s id -- expected an update in place';
  end if;

  select count(*) into n from recipe_translations where recipe_id = recipe_a;
  if n <> 1 then
    failures := failures + 1;
    raise warning 're-translating created a second row, found %', n;
  end if;

  select title into txt from recipe_translations where id = translation_id;
  if txt <> 'zzz translated title, revised' then
    failures := failures + 1;
    raise warning 're-translation did not overwrite the title, got `%`', txt;
  end if;

  ---------------------------------------------------------------------------
  -- Refusals
  ---------------------------------------------------------------------------
  -- An unknown locale is refused, 22023 like create_ingredient's own locale
  -- check.
  got_error := false;
  got_sqlstate := null;
  begin
    perform save_recipe_translation(recipe_a, 'de', 'x', null, '[]'::jsonb);
  exception when others then
    got_error := true;
    got_sqlstate := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'locale ''de'' was accepted -- only sr and en are legal';
  elsif got_sqlstate <> '22023' then
    failures := failures + 1;
    raise warning 'locale ''de'' raised %, expected 22023', got_sqlstate;
  end if;

  -- Translating into the recipe's own original_locale is refused -- the
  -- nearest thing this schema has to a second recipe row.
  got_error := false;
  got_sqlstate := null;
  begin
    perform save_recipe_translation(recipe_a, 'sr', 'x', null, '[]'::jsonb);
  exception when others then
    got_error := true;
    got_sqlstate := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'translating into the recipe''s own original_locale was accepted';
  elsif got_sqlstate <> '22023' then
    failures := failures + 1;
    raise warning 'own-locale translation raised %, expected 22023', got_sqlstate;
  end if;

  -- A foreign or nonexistent recipe id is refused as not found/visible.
  got_error := false;
  got_sqlstate := null;
  begin
    perform save_recipe_translation(recipe_b, 'sr', 'x', null, '[]'::jsonb);
  exception when others then
    got_error := true;
    got_sqlstate := sqlstate;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'A translated a recipe belonging to household B';
  elsif got_sqlstate <> '42501' then
    failures := failures + 1;
    raise warning 'foreign recipe raised %, expected 42501', got_sqlstate;
  end if;

  ---------------------------------------------------------------------------
  -- B cannot see or write A's translation
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  select count(*) into n from recipe_translations where id = translation_id;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a non-member can see household A''s recipe translation';
  end if;

  got_error := false;
  begin
    insert into recipe_translations (recipe_id, locale, title)
    values (recipe_a, 'sr', 'zzz hijacked');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a non-member inserted a translation on household A''s recipe';
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  ---------------------------------------------------------------------------
  -- The parent touch trigger (D78) -- now() is transaction time, so freeze
  -- and backdate recipes.updated_at by hand rather than compare two
  -- identical timestamps, the same dance rls_meal_plans_test.sql uses for
  -- meal_plan_entries_touch_plan.
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  execute 'alter table recipes disable trigger recipes_set_updated_at';
  perform set_config('role', 'authenticated', true);
  update recipes set updated_at = timestamptz '2020-01-01' where id = recipe_a;
  perform set_config('role', 'postgres', true);
  execute 'alter table recipes enable trigger recipes_set_updated_at';
  perform set_config('role', 'authenticated', true);

  select updated_at into ts_before from recipes where id = recipe_a;

  perform save_recipe_translation(
    recipe_a, 'en', 'zzz touched title', null, '[]'::jsonb);

  select updated_at into ts_after from recipes where id = recipe_a;
  if ts_after <= ts_before then
    failures := failures + 1;
    raise warning
      'translating a recipe did not move recipes.updated_at (% -> %)',
      ts_before, ts_after;
  end if;

  -- now() is fixed for the whole transaction, so the write above already
  -- consumed that frozen value -- backdate again before checking the delete.
  perform set_config('role', 'postgres', true);
  execute 'alter table recipes disable trigger recipes_set_updated_at';
  perform set_config('role', 'authenticated', true);
  update recipes set updated_at = timestamptz '2020-01-01' where id = recipe_a;
  perform set_config('role', 'postgres', true);
  execute 'alter table recipes enable trigger recipes_set_updated_at';
  perform set_config('role', 'authenticated', true);

  select updated_at into ts_before from recipes where id = recipe_a;
  delete from recipe_translations where id = translation_id;
  select updated_at into ts_after from recipes where id = recipe_a;
  if ts_after <= ts_before then
    failures := failures + 1;
    raise warning 'deleting a translation did not move recipes.updated_at';
  end if;

  ---------------------------------------------------------------------------
  -- Cascade shape and hard delete (D24/D78: no deleted_at on this table)
  ---------------------------------------------------------------------------
  if not exists (
    select 1 from pg_constraint c
    join pg_class cl on cl.oid = c.conrelid
    where cl.relname = 'recipe_translations'
      and c.contype = 'f'
      and c.confrelid = 'recipes'::regclass
      and c.confdeltype = 'c'
  ) then
    failures := failures + 1;
    raise warning 'recipe_translations.recipe_id is not ON DELETE CASCADE';
  end if;

  select save_recipe_translation(
    recipe_a, 'en', 'zzz for hard delete', null, '[]'::jsonb)
  into translation_tmp;
  delete from recipe_translations where id = translation_tmp;
  select count(*) into n from recipe_translations where id = translation_tmp;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a hard delete of a translation left a row behind';
  end if;

  ---------------------------------------------------------------------------
  -- Grants
  ---------------------------------------------------------------------------
  if not has_function_privilege('authenticated',
       'save_recipe_translation(uuid,text,text,text,jsonb)', 'execute') then
    failures := failures + 1;
    raise warning 'authenticated cannot execute save_recipe_translation';
  end if;

  if has_function_privilege('anon',
       'save_recipe_translation(uuid,text,text,text,jsonb)', 'execute') then
    failures := failures + 1;
    raise warning 'anon can execute save_recipe_translation';
  end if;

  ---------------------------------------------------------------------------
  -- The phase's own Done-when: a recipe entered in Serbian reads correctly
  -- in English, ingredient names included, without a second recipe row
  -- existing.
  ---------------------------------------------------------------------------
  perform save_recipe_translation(
    recipe_a, 'en', 'zzz translated title, final', 'the final description',
    jsonb_build_array(jsonb_build_object('position', 0, 'text', 'Mix the flour.'))
  );

  select title into txt from recipe_translations
    where recipe_id = recipe_a and locale = 'en';
  if txt <> 'zzz translated title, final' then
    failures := failures + 1;
    raise warning 'the English translation did not read back, got `%`', txt;
  end if;

  select display_name into txt from ingredient_display_names(array[brasno], 'en');
  if txt <> 'flour' then
    failures := failures + 1;
    raise warning 'ingredient_display_names(en) gave `%`, expected `flour`', txt;
  end if;

  select count(*) into n from recipes where title like 'zzz translate recipe';
  if n <> 1 then
    failures := failures + 1;
    raise warning
      'expected exactly one recipe row for the translated recipe, found %', n;
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  set local role postgres;
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  if failures > 0 then
    raise exception 'rls_recipe_translations_test: % assertion(s) failed', failures;
  end if;
  raise notice 'rls_recipe_translations_test: all assertions passed';
end;
$$;
