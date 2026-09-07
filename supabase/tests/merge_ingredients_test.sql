-- Test: merge_ingredients() (Phase 1b, third slice).
--
-- The second half of the roadmap's "done when" for 1b: `merge_ingredients`
-- correctly repoints rows. Everything the function promises is asserted here,
-- including the two refusals and the grant, because a merge that half-runs is
-- worse than one that will not start.
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from the other test files (1/2/3, a/b/c/d, 4/5).

do $$
declare
  user_a uuid := '66666666-6666-6666-6666-666666666666';

  src       uuid;
  tgt       uuid;
  kid       uuid;
  parented  uuid;
  orphan    uuid;

  hid       uuid;
  rid       uuid;

  n         int;
  failures  int := 0;
  got_error boolean;
  fk_tables text[];
  known     text[] := array[
    -- Tables merge_ingredients names. `ingredients` is the parent_id self-
    -- reference, handled by the re-parent step.
    'ingredients',
    'ingredient_names',
    'recipe_ingredients',
    'shopping_list_items',
    'household_pantry_prefs'
  ];
  unhandled text[];
begin
  ---------------------------------------------------------------------------
  -- Setup
  ---------------------------------------------------------------------------
  -- Households first: it cascades to recipes and on to recipe_ingredients,
  -- whose ingredient_id has no ON DELETE and would otherwise block the
  -- ingredient delete on the next line.
  delete from households where created_by = user_a;
  update ingredients set parent_id = null where key like 'zzz\_merge\_%';
  delete from ingredients where key like 'zzz\_merge\_%';
  delete from ingredient_merges where merged_by = user_a;
  delete from auth.users where id = user_a;

  insert into auth.users (id, email) values (user_a, 'merge-a@example.com');

  insert into ingredients (key, category, default_unit_family, is_verified)
  values ('zzz_merge_source', 'pantry', 'mass', false) returning id into src;

  insert into ingredients (key, category, default_unit_family, is_verified)
  values ('zzz_merge_target', 'pantry', 'mass', true) returning id into tgt;

  insert into ingredients (key, parent_id) values ('zzz_merge_child', src)
  returning id into kid;

  -- Both carry a Serbian display name, so the merge has to demote one.
  insert into ingredient_names
    (ingredient_id, name, locale, is_display_name, source)
  values
    (src, 'zzz merge izvor',  'sr', true,  'curated'),
    (src, 'zzz merge izvora', 'sr', false, 'curated'),
    (src, 'zzz merge source', 'en', true,  'curated'),
    (tgt, 'zzz merge meta',   'sr', true,  'curated'),
    (tgt, 'zzz merge target', 'en', true,  'curated');

  ---------------------------------------------------------------------------
  -- A recipe line pointing at the source
  ---------------------------------------------------------------------------
  -- Until Phase 1c this section could not exist. recipe_ingredients had no
  -- table, so the function's to_regclass-guarded repoint step was skipped and
  -- the FK-coverage assertion at the end passed vacuously. Both are live now,
  -- and the roadmap's "merge_ingredients correctly repoints rows" is finally
  -- asserted against the row type the step was written for.
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select create_household('zzz merge household') into hid;

  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid, 'zzz merge recipe', 'sr', 'manual', user_a)
  returning id into rid;

  insert into recipe_ingredients (recipe_id, position, raw_text, ingredient_id,
                                  match_method, match_confidence)
  values (rid, 0, 'zzz merge izvora', src, 'alias', 1.0);

  perform set_config('role', 'postgres', true);

  ---------------------------------------------------------------------------
  -- Refusals, before anything has been changed
  ---------------------------------------------------------------------------
  got_error := false;
  begin
    perform merge_ingredients(src, src);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'merging an ingredient into itself was accepted';
  end if;

  got_error := false;
  begin
    perform merge_ingredients(src, gen_random_uuid());
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'merging into a nonexistent target was accepted';
  end if;

  -- D3: source has a child, so a target that is itself a child would produce
  -- a grandchild.
  insert into ingredients (key) values ('zzz_merge_parent') returning id into orphan;
  insert into ingredients (key, parent_id) values ('zzz_merge_parented', orphan)
  returning id into parented;

  got_error := false;
  begin
    perform merge_ingredients(src, parented);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a merge that would create a grandchild was accepted (D3)';
  end if;

  ---------------------------------------------------------------------------
  -- The grant. PostgREST exposes public-schema functions, so an ungranted
  -- SECURITY DEFINER merge would be a destruction endpoint.
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  got_error := false;
  begin
    perform merge_ingredients(src, tgt);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'authenticated was able to call merge_ingredients';
  end if;

  perform set_config('role', 'postgres', true);

  ---------------------------------------------------------------------------
  -- The real merge
  ---------------------------------------------------------------------------
  perform merge_ingredients(src, tgt, user_a);

  select count(*) into n from ingredient_names where ingredient_id = src;
  if n <> 0 then
    failures := failures + 1;
    raise warning '% name row(s) still point at the merged-away source', n;
  end if;

  -- Nothing is deleted: all three of source's names survive on the target.
  select count(*) into n
  from ingredient_names where ingredient_id = tgt and deleted_at is null;
  if n <> 5 then
    failures := failures + 1;
    raise warning 'target has % live name(s) after the merge, expected 5', n;
  end if;

  -- ...but only one of them is the Serbian display name.
  select count(*) into n
  from ingredient_names
  where ingredient_id = tgt and locale = 'sr'
    and is_display_name and household_id is null and deleted_at is null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'target has % sr display name(s) after the merge, expected 1', n;
  end if;

  -- The surviving display name is the target's own, not the source's.
  if (select name from ingredient_names
      where ingredient_id = tgt and locale = 'sr' and is_display_name
        and deleted_at is null) <> 'zzz merge meta' then
    failures := failures + 1;
    raise warning 'the wrong sr display name survived the merge';
  end if;

  select count(*) into n from ingredients where id = kid and parent_id = tgt;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the source''s child was not re-parented onto the target';
  end if;

  select count(*) into n
  from ingredients where id = src and deleted_at is not null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the source ingredient was not soft-deleted';
  end if;

  -- The point of the whole function: a recipe line that referred to the
  -- retired ingredient now refers to the surviving one.
  select count(*) into n
  from recipe_ingredients where recipe_id = rid and ingredient_id = tgt;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the recipe line was not repointed onto the target';
  end if;

  -- ...and nothing about what the cook wrote, or about how the line was
  -- matched, was rewritten along the way (rule 3, D7).
  select count(*) into n
  from recipe_ingredients
  where recipe_id = rid and raw_text = 'zzz merge izvora'
    and match_method = 'alias' and match_confidence = 1.0;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the merge rewrote raw_text or the match provenance';
  end if;

  -- Rule 4: soft delete, so the row is still there.
  select count(*) into n from ingredients where id = src;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the source ingredient was hard-deleted (rule 4)';
  end if;

  -- The key stays, or the next catalog seed would resurrect it.
  if (select key from ingredients where id = src) is distinct from 'zzz_merge_source' then
    failures := failures + 1;
    raise warning 'the source ingredient lost its key during the merge';
  end if;

  select count(*) into n from ingredient_merges
   where source_id = src and target_id = tgt and merged_by = user_a;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the merge was not recorded in ingredient_merges';
  end if;

  -- Merging the same source twice must refuse rather than write a second
  -- audit row claiming a merge that did nothing.
  got_error := false;
  begin
    perform merge_ingredients(src, tgt, user_a);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'an already-merged source was merged a second time';
  end if;

  ---------------------------------------------------------------------------
  -- FK coverage: the guard against Phase 1c forgetting
  ---------------------------------------------------------------------------
  -- merge_ingredients names the referencing tables explicitly, including two
  -- that do not exist yet. If a later phase adds a foreign key to
  -- ingredients(id) from a table the function does not handle, that reference
  -- would survive a merge pointing at a retired ingredient -- silently. This
  -- turns "someone forgot in 1c" into a red test.
  select coalesce(array_agg(distinct cl.relname), '{}')
  into fk_tables
  from pg_constraint c
  join pg_class cl on cl.oid = c.conrelid
  join pg_class rf on rf.oid = c.confrelid
  join pg_namespace ns on ns.oid = cl.relnamespace
  where c.contype = 'f'
    and rf.relname = 'ingredients'
    and ns.nspname = 'public';

  select array_agg(t) into unhandled
  from unnest(fk_tables) as t
  where t <> all (known);

  if unhandled is not null then
    failures := failures + 1;
    raise warning
      'table(s) % reference ingredients(id) but merge_ingredients does not '
      'handle them -- add them to the function AND to `known` here',
      unhandled;
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  delete from ingredient_merges where merged_by = user_a;
  delete from households where created_by = user_a;
  update ingredients set parent_id = null where key like 'zzz\_merge\_%';
  delete from ingredient_names where ingredient_id in
    (select id from ingredients where key like 'zzz\_merge\_%');
  delete from ingredients where key like 'zzz\_merge\_%';
  delete from auth.users where id = user_a;

  if failures > 0 then
    raise exception '% merge_ingredients test(s) failed.', failures;
  end if;

  raise notice 'merge_ingredients: all checks passed';
end
$$;
