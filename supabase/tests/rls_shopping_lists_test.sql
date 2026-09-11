-- RLS/behaviour test: shopping_lists, shopping_list_items,
-- household_pantry_prefs and save_shopping_list (Phase 2, part 4).
--
-- Covers the three tables migration 16 added, their policies, the one
-- function it added, and two branches of merge_ingredients (migration 6) that
-- have been unreachable since Phase 1b because the tables they name did not
-- exist. Those branches are the reason this file asserts something a pure RLS
-- test would not: merge_ingredients_test.sql has been standing guard over
-- them with an FK-coverage check, but a check that a table is NAMED is not a
-- check that the naming WORKS, and nothing has ever executed them.
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from the other test files (every single-hex-repeat
-- pattern 1-9/a-f is taken, as are a1a1.../b2b2... and c3c3.../d4d4...; this
-- file uses e5e5.../f6f6...).

do $$
declare
  user_a uuid := 'e5e5e5e5-e5e5-e5e5-e5e5-e5e5e5e5e5e5';
  user_b uuid := 'f6f6f6f6-f6f6-f6f6-f6f6-f6f6f6f6f6f6';

  hid_a     uuid;
  hid_b     uuid;
  recipe_a  uuid;
  plan_a    uuid;
  list_a    uuid;
  list_b    uuid;
  list_tmp  uuid;

  ing_src   uuid;
  ing_tgt   uuid;
  item_id   uuid;

  week_1 date := date '2026-07-06';

  n            int;
  pos          int;
  got_error    boolean;
  got_sqlstate text;
  ts_before    timestamptz;
  ts_after     timestamptz;
  txt          text;
  flag         boolean;
  failures     int := 0;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres)
  ---------------------------------------------------------------------------
  -- households cascades to shopping_lists and on to shopping_list_items, and
  -- to household_pantry_prefs. The ingredients below are deleted last because
  -- shopping_list_items.ingredient_id has no ON DELETE and would block them.
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);
  update ingredients set parent_id = null where key like 'zzz\_shop\_%';
  delete from ingredient_names where ingredient_id in
    (select id from ingredients where key like 'zzz\_shop\_%');
  delete from ingredients where key like 'zzz\_shop\_%';

  insert into auth.users (id, email) values
    (user_a, 'shoplist-a@example.com'),
    (user_b, 'shoplist-b@example.com');

  insert into ingredients (key, category, default_unit_family, is_verified)
  values ('zzz_shop_source', 'pantry', 'mass', false) returning id into ing_src;
  insert into ingredients (key, category, default_unit_family, is_verified)
  values ('zzz_shop_target', 'pantry', 'mass', true) returning id into ing_tgt;

  ---------------------------------------------------------------------------
  -- A creates a household, a recipe and a plan to hang a list off
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select create_household('zzz shop household a') into hid_a;

  insert into recipes (household_id, title, original_locale, source_type,
                       created_by)
  values (hid_a, 'zzz shop recipe', 'sr', 'manual', user_a)
  returning id into recipe_a;

  select ensure_meal_plan(hid_a, week_1) into plan_a;

  ---------------------------------------------------------------------------
  -- save_shopping_list: the happy path, and position from array order
  ---------------------------------------------------------------------------
  -- Three items sent deliberately out of any natural order, with the middle
  -- one carrying no ingredient_id at all (rule 3 -- an unmatched line is
  -- still a line).
  select save_shopping_list(
    hid_a, plan_a, week_1, week_1 + 6, 'sr',
    jsonb_build_array(
      jsonb_build_object(
        'ingredient_id', ing_tgt,
        'display_name', 'brasno',
        'category', 'pantry',
        'is_pantry_staple', false,
        'quantities', jsonb_build_array(
          jsonb_build_object('family','mass','amount_num',800,'amount_den',1,'unit','g'),
          jsonb_build_object('family','volume','amount_num',480,'amount_den',1,'unit','ml')),
        'unmatched_lines', jsonb_build_array()),
      jsonb_build_object(
        'display_name', 'prstohvat soli',
        'quantities', jsonb_build_array(),
        'unmatched_lines', jsonb_build_array('prstohvat soli')),
      jsonb_build_object(
        'ingredient_id', ing_src,
        'display_name', 'secer',
        'category', 'pantry',
        'is_pantry_staple', true,
        'quantities', jsonb_build_array(
          jsonb_build_object('family','mass','amount_num',1,'amount_den',3,'unit','g')),
        'unmatched_lines', jsonb_build_array())
    )
  ) into list_a;

  if list_a is null then
    failures := failures + 1;
    raise warning 'save_shopping_list returned null';
  end if;

  select count(*) into n from shopping_list_items where list_id = list_a;
  if n <> 3 then
    failures := failures + 1;
    raise warning 'expected 3 items, found %', n;
  end if;

  -- position comes from array order, not from the JSON (which never sent it).
  select position into pos
  from shopping_list_items where list_id = list_a and display_name = 'brasno';
  if pos <> 0 then
    failures := failures + 1;
    raise warning 'first item got position %, expected 0', pos;
  end if;
  select position into pos
  from shopping_list_items where list_id = list_a and display_name = 'secer';
  if pos <> 2 then
    failures := failures + 1;
    raise warning 'third item got position %, expected 2', pos;
  end if;

  -- No duplicates and no gaps across the group.
  select count(distinct position) into n
  from shopping_list_items where list_id = list_a;
  if n <> 3 then
    failures := failures + 1;
    raise warning 'positions are not distinct across the list (% distinct)', n;
  end if;

  -- created_by is auth.uid(), not anything the caller passed.
  select created_by into txt from shopping_lists where id = list_a;
  if txt::uuid is distinct from user_a then
    failures := failures + 1;
    raise warning 'created_by was %, expected %', txt, user_a;
  end if;

  -- The quantity pair survives as an exact fraction, not a rounded number.
  select (quantities -> 0 ->> 'amount_den')::int into n
  from shopping_list_items where list_id = list_a and display_name = 'secer';
  if n <> 3 then
    failures := failures + 1;
    raise warning 'amount_den came back as %, expected 3 -- the fraction was not preserved', n;
  end if;

  -- An unmatched line keeps its raw text and carries no quantities.
  select unmatched_lines ->> 0 into txt
  from shopping_list_items where list_id = list_a and display_name = 'prstohvat soli';
  if txt is distinct from 'prstohvat soli' then
    failures := failures + 1;
    raise warning 'unmatched line came back as %, expected ''prstohvat soli''', txt;
  end if;

  ---------------------------------------------------------------------------
  -- The date range check
  ---------------------------------------------------------------------------
  got_error := false;
  begin
    perform save_shopping_list(hid_a, null, week_1 + 6, week_1, 'sr', '[]'::jsonb);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'an inverted date range (date_to < date_from) was accepted';
  end if;

  -- A single-day range is legal.
  select save_shopping_list(hid_a, null, week_1, week_1, 'sr', '[]'::jsonb)
  into list_tmp;
  if list_tmp is null then
    failures := failures + 1;
    raise warning 'a single-day range was refused';
  end if;
  update shopping_lists set deleted_at = now() where id = list_tmp;

  -- An unknown locale is refused.
  got_error := false;
  begin
    perform save_shopping_list(hid_a, null, week_1, week_1, 'de', '[]'::jsonb);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'locale ''de'' was accepted -- only sr and en are legal';
  end if;

  ---------------------------------------------------------------------------
  -- The updated_at trigger (D59)
  ---------------------------------------------------------------------------
  -- Same now()-is-transaction-time caveat as rls_meal_plans_test.sql: the
  -- whole file is one transaction, so a naive before/after comparison would
  -- compare two identical timestamps and pass whether or not the trigger
  -- fired. Disable the trigger, backdate by hand, re-enable, then write.
  set local role postgres;
  alter table shopping_lists disable trigger shopping_lists_set_updated_at;
  update shopping_lists set updated_at = now() - interval '1 day' where id = list_a;
  alter table shopping_lists enable trigger shopping_lists_set_updated_at;
  select updated_at into ts_before from shopping_lists where id = list_a;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  update shopping_lists set locale = 'sr' where id = list_a;
  select updated_at into ts_after from shopping_lists where id = list_a;
  if ts_after <= ts_before then
    failures := failures + 1;
    raise warning 'shopping_lists.updated_at did not move on an update (% -> %)',
      ts_before, ts_after;
  end if;

  ---------------------------------------------------------------------------
  -- household_pantry_prefs: a member may override in both directions
  ---------------------------------------------------------------------------
  insert into household_pantry_prefs (household_id, ingredient_id, always_have)
  values (hid_a, ing_tgt, true);

  select always_have into flag from household_pantry_prefs
  where household_id = hid_a and ingredient_id = ing_tgt;
  if flag is not true then
    failures := failures + 1;
    raise warning 'pantry pref did not read back as true';
  end if;

  update household_pantry_prefs set always_have = false
  where household_id = hid_a and ingredient_id = ing_tgt;
  select always_have into flag from household_pantry_prefs
  where household_id = hid_a and ingredient_id = ing_tgt;
  if flag is not false then
    failures := failures + 1;
    raise warning 'pantry pref did not flip to false -- the override is not two-way';
  end if;

  -- Clearing a preference is a hard delete (D24's join-table precedent).
  delete from household_pantry_prefs
  where household_id = hid_a and ingredient_id = ing_tgt;
  select count(*) into n from household_pantry_prefs
  where household_id = hid_a and ingredient_id = ing_tgt;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'pantry pref survived a delete -- expected a hard delete';
  end if;

  ---------------------------------------------------------------------------
  -- B: a non-member sees and touches nothing
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  select create_household('zzz shop household b') into hid_b;

  select count(*) into n from shopping_lists where id = list_a;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a non-member can see household A''s shopping list';
  end if;

  select count(*) into n from shopping_list_items where list_id = list_a;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a non-member can see household A''s list items';
  end if;

  -- save_shopping_list into someone else's household is refused with 42501,
  -- and refused loudly rather than writing nothing and returning an id.
  got_error := false;
  got_sqlstate := null;
  begin
    perform save_shopping_list(hid_a, null, week_1, week_1 + 1, 'sr', '[]'::jsonb);
  exception when others then
    got_error := true;
    got_sqlstate := SQLSTATE;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a non-member generated a list into household A';
  elsif got_sqlstate <> '42501' then
    failures := failures + 1;
    raise warning 'non-member save_shopping_list raised %, expected 42501', got_sqlstate;
  end if;

  -- An item inserted into a list B cannot see is refused by the parent-scoped
  -- policy (0 rows would be a silent no-op, so assert the count did not move).
  got_error := false;
  begin
    insert into shopping_list_items (list_id, display_name)
    values (list_a, 'zzz shop smuggled');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a non-member inserted an item into household A''s list';
  end if;

  -- B cannot write A's pantry preferences. An INSERT that fails a with-check
  -- policy RAISES 42501 -- unlike a select or update, which silently match no
  -- rows -- so this has to be caught rather than counted.
  got_error := false;
  begin
    insert into household_pantry_prefs (household_id, ingredient_id, always_have)
    values (hid_a, ing_tgt, true);
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a non-member wrote household A''s pantry prefs';
  end if;

  -- Nor read them.
  select count(*) into n from household_pantry_prefs where household_id = hid_a;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a non-member can see household A''s pantry prefs';
  end if;

  ---------------------------------------------------------------------------
  -- No DELETE policy on shopping_lists: removal is a soft delete (rule 4)
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  delete from shopping_lists where id = list_a;
  select count(*) into n from shopping_lists where id = list_a;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'a hard delete of a shopping list succeeded -- expected no DELETE policy';
  end if;

  update shopping_lists set deleted_at = now() where id = list_a;
  select count(*) into n
  from shopping_lists where id = list_a and deleted_at is not null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the soft delete did not take';
  end if;

  -- D23: a tombstone stays visible to the caller, so the Phase 2 delta fetch
  -- can evict it. Filtering deleted_at is data/'s job, not RLS's.
  select count(*) into n from shopping_lists where id = list_a;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'a soft-deleted list became invisible -- RLS must not filter deleted_at (D23)';
  end if;

  ---------------------------------------------------------------------------
  -- merge_ingredients: two branches that have never executed
  ---------------------------------------------------------------------------
  -- migration 6 names shopping_list_items and household_pantry_prefs behind
  -- to_regclass() guards. Until this migration those guards were always
  -- false. merge_ingredients_test.sql asserts the tables are NAMED; nothing
  -- has ever asserted the naming works.
  set local role postgres;

  -- A: an item pointing at the source ingredient is repointed at the target.
  select id into item_id from shopping_list_items
  where list_id = list_a and display_name = 'secer';

  -- Both households hold an opinion about the source; only A holds one about
  -- the target. After the merge A's duplicate must collapse to one row and
  -- B's must simply repoint.
  insert into household_pantry_prefs (household_id, ingredient_id, always_have)
  values (hid_a, ing_src, true),
         (hid_a, ing_tgt, false),
         (hid_b, ing_src, true);

  perform merge_ingredients(ing_src, ing_tgt, user_a);

  select ingredient_id into ing_src from shopping_list_items where id = item_id;
  if ing_src is distinct from ing_tgt then
    failures := failures + 1;
    raise warning
      'merge_ingredients did not repoint shopping_list_items (% vs %) -- the to_regclass branch is broken',
      ing_src, ing_tgt;
  end if;

  select count(*) into n from household_pantry_prefs
  where household_id = hid_a and ingredient_id = ing_tgt;
  if n <> 1 then
    failures := failures + 1;
    raise warning
      'household A has % pantry pref rows for the target, expected 1 -- the duplicate did not collapse', n;
  end if;

  -- A's surviving row must be the one it already held about the TARGET
  -- (always_have = false), not the source's opinion overwriting it.
  select always_have into flag from household_pantry_prefs
  where household_id = hid_a and ingredient_id = ing_tgt;
  if flag is not false then
    failures := failures + 1;
    raise warning
      'the surviving pantry pref is the source''s opinion, not the target''s own';
  end if;

  select count(*) into n from household_pantry_prefs
  where household_id = hid_b and ingredient_id = ing_tgt;
  if n <> 1 then
    failures := failures + 1;
    raise warning
      'household B has % pantry pref rows for the target, expected 1 -- a plain repoint', n;
  end if;

  ---------------------------------------------------------------------------
  -- Cascade: items go with their list, lists go with their household
  ---------------------------------------------------------------------------
  delete from shopping_lists where id = list_a;
  select count(*) into n from shopping_list_items where list_id = list_a;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'items survived a hard delete of their list -- expected a cascade';
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  set local role postgres;
  delete from households where created_by in (user_a, user_b);
  delete from ingredient_merges where merged_by in (user_a, user_b);
  update ingredients set parent_id = null where key like 'zzz\_shop\_%';
  delete from ingredient_names where ingredient_id in
    (select id from ingredients where key like 'zzz\_shop\_%');
  delete from ingredients where key like 'zzz\_shop\_%';
  delete from auth.users where id in (user_a, user_b);

  if failures > 0 then
    raise exception 'rls_shopping_lists_test: % assertion(s) failed', failures;
  end if;
  raise notice 'rls_shopping_lists_test: all assertions passed';
end;
$$;
