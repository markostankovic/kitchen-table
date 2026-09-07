-- Test: create_ingredient() and link_ingredient_alias() (Phase 1c).
--
-- These are the first two functions that let a client write the catalog at
-- all, so the assertions that matter most are the ones about what they REFUSE
-- to do: create a second row for a string the catalog already knows, hijack a
-- string that names something else, or run for a caller who is not signed in.
--
-- The grant block is asserted too. merge_ingredients' migration records why:
-- Supabase's default privileges hand anon and authenticated EXECUTE in their
-- own right, so a revoke that names only PUBLIC silently does nothing, and
-- nothing but a test will catch it.
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from the other test files (9).

do $$
declare
  user_i uuid := '99999999-9999-9999-9999-999999999999';

  made      uuid;
  again     uuid;
  other     uuid;
  dead_ing  uuid;
  linked    boolean;
  n         int;
  failures  int := 0;
  got_error boolean;
begin
  ---------------------------------------------------------------------------
  -- Setup
  ---------------------------------------------------------------------------
  delete from ingredient_names where name like 'zzz create%';
  delete from ingredients where key like 'zzz\_create\_%';
  delete from auth.users where id = user_i;

  insert into auth.users (id, email) values (user_i, 'create-i@example.com');

  ---------------------------------------------------------------------------
  -- Refusals before anything is written
  ---------------------------------------------------------------------------
  -- No session: postgres is not `authenticated` and auth.uid() is null.
  got_error := false;
  begin
    perform create_ingredient('zzz create anon');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'create_ingredient ran without an authenticated caller';
  end if;

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_i, 'role', 'authenticated')::text, true);

  got_error := false;
  begin
    perform create_ingredient('   ');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'a blank ingredient name was accepted';
  end if;

  got_error := false;
  begin
    perform create_ingredient('zzz create bad locale', 'de');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'locale `de` was accepted (only sr and en exist)';
  end if;

  got_error := false;
  begin
    perform create_ingredient('zzz create bad family', 'sr', 'length');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'an unknown unit family was accepted';
  end if;

  ---------------------------------------------------------------------------
  -- Creating
  ---------------------------------------------------------------------------
  select create_ingredient('zzz create Urnebes', 'sr', 'mass') into made;

  select count(*) into n
  from ingredients
  where id = made and not is_verified and key is null
    and default_unit_family = 'mass';
  if n <> 1 then
    failures := failures + 1;
    raise warning
      'the new ingredient is not an unverified, keyless, mass-family row';
  end if;

  -- One global display name, source `user`, spelled as typed.
  select count(*) into n
  from ingredient_names
  where ingredient_id = made and locale = 'sr' and is_display_name
    and household_id is null and source = 'user'
    and name = 'zzz create Urnebes' and deleted_at is null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the display name row is wrong or missing';
  end if;

  -- ...and it is findable by the matcher immediately, which is the whole
  -- point of writing it back.
  select count(*) into n
  from search_ingredients('zzz create urnebes', 'sr', 5)
  where ingredient_id = made;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'a just-created ingredient is not reachable by search';
  end if;

  ---------------------------------------------------------------------------
  -- The exact-match guard
  ---------------------------------------------------------------------------
  -- Same string, different case and diacritics: normalize_text folds both, so
  -- this must return the SAME row rather than create a second one.
  select create_ingredient('ZZZ CREATE URNEBES', 'sr') into again;
  if again <> made then
    failures := failures + 1;
    raise warning
      'the exact-match guard missed: a second row was created for one string';
  end if;

  select count(*) into n from ingredients where id <> made and id in (
    select ingredient_id from ingredient_names
    where normalized_name = normalize_text('zzz create urnebes'));
  if n <> 0 then
    failures := failures + 1;
    raise warning '% extra ingredient(s) exist for the same string', n;
  end if;

  -- The gap this guard deliberately does NOT close, asserted so that closing
  -- it later is a visible change rather than a surprise: the same string in
  -- the other locale is a different row, because `pita` does not mean the
  -- same thing in Serbian and English.
  select create_ingredient('zzz create Urnebes', 'en') into other;
  if other = made then
    failures := failures + 1;
    raise warning
      'the guard now spans locales -- deliberate change, or an accident?';
  end if;

  ---------------------------------------------------------------------------
  -- link_ingredient_alias
  ---------------------------------------------------------------------------
  select link_ingredient_alias(made, 'zzz create urnebesa', 'sr') into linked;
  if not linked then
    failures := failures + 1;
    raise warning 'a fresh alias was refused';
  end if;

  select count(*) into n
  from ingredient_names
  where ingredient_id = made and normalized_name = 'zzz create urnebesa'
    and not is_display_name and household_id is null and source = 'user'
    and deleted_at is null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the alias row is wrong or missing';
  end if;

  -- Writing it again is a no-op, not a duplicate and not an error. The line
  -- editor will call this on every save of every recipe using the word.
  select link_ingredient_alias(made, 'ZZZ Create Urnebesa', 'sr') into linked;
  if not linked then
    failures := failures + 1;
    raise warning 'relinking an alias to its own ingredient returned false';
  end if;

  select count(*) into n
  from ingredient_names where normalized_name = 'zzz create urnebesa';
  if n <> 1 then
    failures := failures + 1;
    raise warning 'relinking created a duplicate: % rows', n;
  end if;

  -- The one that protects everybody else's catalog: the string already names
  -- a different ingredient, so it must be refused -- and refused WITHOUT
  -- raising, or one household's odd wording fails somebody's recipe save.
  select link_ingredient_alias(other, 'zzz create urnebesa', 'sr') into linked;
  if linked then
    failures := failures + 1;
    raise warning 'an alias was hijacked from another ingredient';
  end if;

  select count(*) into n
  from ingredient_names
  where normalized_name = 'zzz create urnebesa' and ingredient_id = made;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the refused link changed the row anyway';
  end if;

  -- A dead alias is reused rather than inserted around: D28's index counts
  -- tombstones, so an insert here would violate it.
  --
  -- Retiring it takes postgres. The catalog has no UPDATE policy for any
  -- client (D32), so this same statement as `authenticated` updates zero rows
  -- and says nothing about it -- which is the correct behaviour of the policy
  -- and a silent no-op for a test that forgets.
  perform set_config('role', 'postgres', true);
  update ingredient_names set deleted_at = now()
   where normalized_name = 'zzz create urnebesa';
  perform set_config('role', 'authenticated', true);

  select link_ingredient_alias(other, 'zzz create urnebesa', 'sr') into linked;
  if not linked then
    failures := failures + 1;
    raise warning 'a retired alias was not resurrected';
  end if;

  select count(*) into n
  from ingredient_names
  where normalized_name = 'zzz create urnebesa'
    and ingredient_id = other and deleted_at is null;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'the resurrected alias did not repoint onto the new owner';
  end if;

  -- Creating over a retired display name gives back what it pointed at,
  -- rather than a second ingredient the index would refuse anyway.
  perform set_config('role', 'postgres', true);
  update ingredient_names set deleted_at = now()
   where ingredient_id = made and locale = 'sr' and is_display_name;
  update ingredients set deleted_at = now() where id = made;
  perform set_config('role', 'authenticated', true);

  select create_ingredient('zzz create urnebes', 'sr') into dead_ing;
  if dead_ing <> made then
    failures := failures + 1;
    raise warning 'creating over a retired string did not resurrect its row';
  end if;

  select count(*) into n
  from ingredients where id = made and deleted_at is null;
  if n <> 1 then
    failures := failures + 1;
    raise warning
      'the name was resurrected but its ingredient was left a tombstone';
  end if;

  -- Linking to a retired ingredient is refused: a live alias pointing at a
  -- tombstone would be returned by search and rendered by nothing.
  perform set_config('role', 'postgres', true);
  update ingredients set deleted_at = now() where id = other;
  perform set_config('role', 'authenticated', true);

  got_error := false;
  begin
    perform link_ingredient_alias(other, 'zzz create nesto', 'sr');
  exception when others then got_error := true;
  end;
  if not got_error then
    failures := failures + 1;
    raise warning 'an alias was linked to a soft-deleted ingredient';
  end if;

  ---------------------------------------------------------------------------
  -- Grants
  ---------------------------------------------------------------------------
  -- These two ARE for clients, unlike merge_ingredients. authenticated keeps
  -- EXECUTE; anon must not have it, and naming PUBLIC alone would not have
  -- taken it away.
  if not has_function_privilege('authenticated',
       'create_ingredient(text,text,text)', 'execute') then
    failures := failures + 1;
    raise warning 'authenticated cannot execute create_ingredient';
  end if;

  if not has_function_privilege('authenticated',
       'link_ingredient_alias(uuid,text,text)', 'execute') then
    failures := failures + 1;
    raise warning 'authenticated cannot execute link_ingredient_alias';
  end if;

  if has_function_privilege('anon',
       'create_ingredient(text,text,text)', 'execute') then
    failures := failures + 1;
    raise warning 'anon can execute create_ingredient';
  end if;

  if has_function_privilege('anon',
       'link_ingredient_alias(uuid,text,text)', 'execute') then
    failures := failures + 1;
    raise warning 'anon can execute link_ingredient_alias';
  end if;

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  perform set_config('role', 'postgres', true);
  delete from ingredient_names where normalized_name like 'zzz create%';
  delete from ingredients where id in (made, other);
  delete from auth.users where id = user_i;

  if failures > 0 then
    raise exception '% catalog write test(s) failed', failures;
  end if;

  raise notice 'create_ingredient / link_ingredient_alias: all checks passed';
end
$$;
