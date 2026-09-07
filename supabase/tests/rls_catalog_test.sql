-- RLS and invariant test: the ingredient catalog (Phase 1b, first slice).
--
-- Covers what migration 4 actually asserts and what a future session could
-- plausibly break: the unit seed's locale coverage, D3's one-level trigger in
-- both directions, and the read-only-to-clients rule (D32) on all five tables.
--
-- Run: make test-sql
--
-- Uses fixed UUIDs distinct from rls_household_test.sql (1/2/3) and
-- rls_invites_test.sql (a/b/c/d) so the three files do not clean up each
-- other's rows. Test ingredients are keyed `zzz_test_*` for the same reason --
-- the key column is unique, so a leftover row from a failed run would
-- otherwise poison every later run.

do $$
declare
  user_a uuid := '44444444-4444-4444-4444-444444444444';
  user_b uuid := '55555555-5555-5555-5555-555555555555';

  hid_a      uuid;
  hid_b      uuid;
  ing_parent uuid;
  ing_child  uuid;

  n         int;
  failures  int := 0;
  got_error boolean;
begin
  ---------------------------------------------------------------------------
  -- Setup (as postgres, which bypasses RLS)
  ---------------------------------------------------------------------------
  update ingredients set parent_id = null where key like 'zzz\_test\_%';
  delete from ingredients where key like 'zzz\_test\_%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  insert into auth.users (id, email) values
    (user_a, 'cat-a@example.com'),
    (user_b, 'cat-b@example.com');

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);
  select create_household('Catalog Test A') into hid_a;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);
  select create_household('Catalog Test B') into hid_b;

  perform set_config('role', 'postgres', true);

  insert into ingredients (key, category, default_unit_family, is_verified)
  values ('zzz_test_parent', 'pantry', 'mass', true)
  returning id into ing_parent;

  insert into ingredients (key, parent_id, category, default_unit_family, is_verified)
  values ('zzz_test_child', ing_parent, 'pantry', 'mass', true)
  returning id into ing_child;

  insert into ingredient_names
    (ingredient_id, name, locale, is_display_name, source)
  values (ing_parent, 'zzz test parent', 'sr', true, 'curated');

  -- A household-scoped alias belonging to A. Nothing writes these yet; the
  -- column and its policy exist, so they are tested.
  insert into ingredient_names
    (ingredient_id, name, locale, household_id, source)
  values (ing_parent, 'zzz kucni alias', 'sr', hid_a, 'user');

  ---------------------------------------------------------------------------
  -- Unit seed invariants
  ---------------------------------------------------------------------------
  -- No constraint can express "every unit is reachable in both locales", and
  -- an unreachable unit is a unit the parser can never produce.
  select count(*) into n
  from units u
  where not exists (select 1 from unit_names v
                    where v.unit_code = u.code and v.locale = 'sr')
     or not exists (select 1 from unit_names v
                    where v.unit_code = u.code and v.locale = 'en');
  if n <> 0 then
    failures := failures + 1;
    raise warning '% unit(s) have no name in one of the two locales', n;
  end if;

  select count(*) into n
  from units u
  cross join (values ('sr'), ('en')) as l(loc)
  where not exists (select 1 from unit_names v
                    where v.unit_code = u.code
                      and v.locale = l.loc
                      and v.is_display_name);
  if n <> 0 then
    failures := failures + 1;
    raise warning '% (unit, locale) pair(s) have no display name', n;
  end if;

  -- The conventions the shopping list will sum against. If one of these ever
  -- changes, every historical list silently changes with it.
  select count(*) into n from units
  where (code = 'tbsp'  and to_base <> 15)
     or (code = 'tsp'   and to_base <> 5)
     or (code = 'cup'   and to_base <> 240)
     or (code = 'glass' and to_base <> 200)
     or (code = 'dl'    and to_base <> 100);
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a seeded unit conversion changed (% row(s))', n;
  end if;

  -- čaša and šolja must stay distinct codes, or 40 ml goes missing per cup.
  if (select unit_code from unit_names
      where normalized_name = 'casa' and locale = 'sr')
     = (select unit_code from unit_names
        where normalized_name = 'solja' and locale = 'sr') then
    failures := failures + 1;
    raise warning 'casa and solja resolved to the same unit';
  end if;

  ---------------------------------------------------------------------------
  -- D3: one level of hierarchy, both directions
  ---------------------------------------------------------------------------
  got_error := false;
  begin
    insert into ingredients (key, parent_id) values ('zzz_test_gc', ing_child);
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a grandchild ingredient was accepted (D3)';
  end if;

  -- The other direction: a row that already has children may not acquire one.
  got_error := false;
  begin
    update ingredients set parent_id = ing_child where id = ing_parent;
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a parent with children was given a parent of its own (D3)';
  end if;

  ---------------------------------------------------------------------------
  -- Reads: A is a member of household A
  ---------------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select count(*) into n from units;
  if n = 0 then
    failures := failures + 1;
    raise warning 'authenticated cannot read units';
  end if;

  select count(*) into n from unit_names;
  if n = 0 then
    failures := failures + 1;
    raise warning 'authenticated cannot read unit_names';
  end if;

  select count(*) into n from ingredients where id = ing_parent;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'authenticated cannot read ingredients';
  end if;

  select count(*) into n from ingredient_names
   where ingredient_id = ing_parent and household_id is null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'A cannot read the global alias';
  end if;

  select count(*) into n from ingredient_names
   where ingredient_id = ing_parent and household_id = hid_a;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'A cannot read their own household alias';
  end if;

  -- The audit log is invisible to every client (RLS on, no policy).
  select count(*) into n from ingredient_merges;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'ingredient_merges is readable by authenticated';
  end if;

  ---------------------------------------------------------------------------
  -- Writes: D32 -- the catalog is read-only to clients in Phase 1b
  ---------------------------------------------------------------------------
  got_error := false;
  begin
    insert into ingredients (key) values ('zzz_test_client');
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'authenticated inserted into ingredients (D32)';
  end if;

  got_error := false;
  begin
    insert into ingredient_names (ingredient_id, name, locale, source)
    values (ing_parent, 'zzz client alias', 'sr', 'user');
  exception when others then
    got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'authenticated inserted into ingredient_names (D32)';
  end if;

  -- UPDATE and DELETE with no policy are not errors -- no row passes, so they
  -- silently affect nothing. That is the assertion.
  update ingredients set is_verified = false where id = ing_parent;
  get diagnostics n = row_count;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'authenticated updated % ingredient row(s) (D32)', n;
  end if;

  delete from ingredient_names where ingredient_id = ing_parent;
  get diagnostics n = row_count;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'authenticated deleted % ingredient_names row(s) (D32)', n;
  end if;

  ---------------------------------------------------------------------------
  -- B is in a different household: global yes, A's household alias no
  ---------------------------------------------------------------------------
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  select count(*) into n from ingredient_names
   where ingredient_id = ing_parent and household_id is null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'B cannot read the global alias';
  end if;

  select count(*) into n from ingredient_names
   where ingredient_id = ing_parent and household_id = hid_a;
  if n <> 0 then
    failures := failures + 1;
    raise warning 'B can read household A''s private alias';
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  update ingredients set parent_id = null where key like 'zzz\_test\_%';
  delete from ingredients where key like 'zzz\_test\_%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  if failures > 0 then
    raise exception '% catalog test(s) failed.', failures;
  end if;

  raise notice 'catalog: all checks passed';
end
$$;
