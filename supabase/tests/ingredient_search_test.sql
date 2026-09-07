-- Test: search_ingredients() (Phase 1b, fourth slice).
--
-- The first half of the roadmap's "done when" for 1b.
--
-- ON `cufte`: the roadmap's example reads "typing 'cufte' or 'sargarepa' in a
-- search RPC returns the right ingredient". `sargarepa` is asserted literally
-- below. `cufte` is NOT, because ćufte is a dish and not an ingredient -- it
-- comes from the normalization fixture list in docs/INGREDIENTS.md, which is
-- about normalize_text rather than about the catalog. What that example was
-- pointing at is diacritic-insensitive search, and that is asserted here
-- directly: Latin without diacritics, Latin with them, and Cyrillic all reach
-- the same row.
--
-- Run: make test-sql
--
-- Fixed UUIDs distinct from every other test file (1/2/3, a/b/c/d, 4/5, 6).

do $$
declare
  user_a uuid := '77777777-7777-7777-7777-777777777777';
  user_b uuid := '88888888-8888-8888-8888-888888888888';

  hid_a    uuid;
  carrot   uuid;
  doomed   uuid;
  got      uuid;

  n        int;
  conf     numeric;
  method   text;
  shown    text;
  accept   boolean;
  failures int := 0;
begin
  ---------------------------------------------------------------------------
  -- Setup
  ---------------------------------------------------------------------------
  delete from ingredients where key like 'zzz\_search\_%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  select id into carrot from ingredients where key = 'sargarepa';
  if carrot is null then
    raise exception 'catalog is not seeded -- run `supabase db reset` first';
  end if;

  insert into auth.users (id, email) values
    (user_a, 'search-a@example.com'), (user_b, 'search-b@example.com');

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);
  select create_household('Search Test A') into hid_a;
  perform set_config('role', 'postgres', true);

  ---------------------------------------------------------------------------
  -- Diacritic-insensitive search: three spellings, one row
  ---------------------------------------------------------------------------
  foreach shown in array array['sargarepa', 'šargarepa', 'ШАРГАРЕПА', 'Šargarepa']
  loop
    select ingredient_id, match_method, match_confidence, auto_accept
      into got, method, conf, accept
    from search_ingredients(shown) limit 1;

    if got is distinct from carrot then
      failures := failures + 1;
      raise warning 'search_ingredients(%) did not return šargarepa', shown;
    elsif method <> 'exact' or conf <> 1.0 or not accept then
      failures := failures + 1;
      raise warning 'search_ingredients(%) returned % / % / %',
        shown, method, conf, accept;
    end if;
  end loop;

  ---------------------------------------------------------------------------
  -- Inflection reaches the concept through a seeded alias (D6)
  ---------------------------------------------------------------------------
  select ingredient_id, match_method into got, method
  from search_ingredients('sargarepe') limit 1;
  if got is distinct from carrot or method <> 'alias' then
    failures := failures + 1;
    raise warning 'the genitive `sargarepe` did not resolve as an alias (got %)', method;
  end if;

  select ingredient_id, match_method into got, method
  from search_ingredients('brasna') limit 1;
  if got is distinct from (select id from ingredients where key = 'brasno')
     or method <> 'alias' then
    failures := failures + 1;
    raise warning '`brasna` did not resolve to brašno as an alias';
  end if;

  ---------------------------------------------------------------------------
  -- The wedge: an English string finds the concept and is shown in Serbian
  ---------------------------------------------------------------------------
  select ingredient_id, display_name, matched_locale into got, shown, method
  from search_ingredients('flour', 'sr') limit 1;
  if got is distinct from (select id from ingredients where key = 'brasno') then
    failures := failures + 1;
    raise warning '`flour` did not reach brašno';
  elsif shown <> 'brašno' then
    failures := failures + 1;
    raise warning '`flour` in locale sr displayed as "%", expected brašno', shown;
  end if;

  -- ...and the same in reverse.
  select display_name into shown from search_ingredients('brašno', 'en') limit 1;
  if shown <> 'flour' then
    failures := failures + 1;
    raise warning '`brašno` in locale en displayed as "%", expected flour', shown;
  end if;

  ---------------------------------------------------------------------------
  -- The four-character floor (docs/INGREDIENTS.md: so / soja, luk / luka)
  ---------------------------------------------------------------------------
  -- `so` is a prefix of sočivo, sok od pomorandže and soja sos. Without the
  -- floor every one of them would be offered as a suggestion for "salt".
  select count(*) into n from search_ingredients('so');
  if n <> 1 then
    failures := failures + 1;
    raise warning '`so` returned % rows; the 4-character fuzzy floor is not holding', n;
  end if;
  select ingredient_id into got from search_ingredients('so') limit 1;
  if got is distinct from (select id from ingredients where key = 'so') then
    failures := failures + 1;
    raise warning '`so` did not return salt';
  end if;

  select count(*) into n from search_ingredients('luk');
  if n <> 1 then
    failures := failures + 1;
    raise warning '`luk` returned % rows, expected only the exact hit', n;
  end if;

  ---------------------------------------------------------------------------
  -- Prefix and fuzzy: found, but never auto-accepted on four letters
  ---------------------------------------------------------------------------
  select ingredient_id, match_method, match_confidence, auto_accept
    into got, method, conf, accept
  from search_ingredients('sarg') limit 1;
  if got is distinct from carrot then
    failures := failures + 1;
    raise warning 'the prefix `sarg` did not reach šargarepa -- autocomplete is broken';
  elsif method <> 'fuzzy' then
    failures := failures + 1;
    raise warning 'the prefix `sarg` reported match_method %', method;
  elsif accept then
    failures := failures + 1;
    raise warning 'a four-letter prefix auto-accepted at confidence %', conf;
  elsif conf >= 0.75 then
    failures := failures + 1;
    raise warning 'the prefix arm inflated its confidence to %', conf;
  end if;

  -- A typo is a suggestion, not a decision.
  select ingredient_id, match_confidence, auto_accept into got, conf, accept
  from search_ingredients('sargarpa') limit 1;
  if got is distinct from carrot then
    failures := failures + 1;
    raise warning 'the typo `sargarpa` did not reach šargarepa';
  elsif conf <= 0.4 or accept then
    failures := failures + 1;
    raise warning '`sargarpa` came back at % / auto_accept %', conf, accept;
  end if;

  ---------------------------------------------------------------------------
  -- One row per ingredient, however many of its aliases matched
  ---------------------------------------------------------------------------
  select count(*) into n
  from search_ingredients('sargarep') where ingredient_id = carrot;
  if n <> 1 then
    failures := failures + 1;
    raise warning 'šargarepa came back % times for one query', n;
  end if;

  select count(*) into n from search_ingredients('brasno', 'sr', 3);
  if n > 3 then
    failures := failures + 1;
    raise warning 'max_results was ignored (% rows)', n;
  end if;

  ---------------------------------------------------------------------------
  -- Retired ingredients do not surface
  ---------------------------------------------------------------------------
  insert into ingredients (key, is_verified) values ('zzz_search_doomed', true)
  returning id into doomed;
  insert into ingredient_names (ingredient_id, name, locale, is_display_name, source)
  values (doomed, 'zzz obrisani sastojak', 'sr', true, 'curated'),
         (doomed, 'zzz deleted ingredient', 'en', true, 'curated');

  select count(*) into n from search_ingredients('zzz obrisani sastojak');
  if n <> 1 then
    failures := failures + 1;
    raise warning 'a live test ingredient was not findable before deletion';
  end if;

  update ingredients set deleted_at = now() where id = doomed;

  select count(*) into n from search_ingredients('zzz obrisani sastojak');
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a soft-deleted ingredient is still returned by search';
  end if;

  ---------------------------------------------------------------------------
  -- Household aliases: visible to members only, and they outrank the global
  ---------------------------------------------------------------------------
  -- search_ingredients is SECURITY INVOKER precisely so this needs no
  -- household_id parameter -- the policy already knows.
  insert into ingredient_names
    (ingredient_id, name, locale, household_id, source)
  values (carrot, 'zzz nasa mrkva', 'sr', hid_a, 'user');

  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims',
    json_build_object('sub', user_a, 'role', 'authenticated')::text, true);

  select ingredient_id, is_household_alias into got, accept
  from search_ingredients('zzz nasa mrkva') limit 1;
  if got is distinct from carrot then
    failures := failures + 1;
    raise warning 'a member could not find their own household alias';
  elsif not accept then
    failures := failures + 1;
    raise warning 'a household alias was not flagged as one';
  end if;

  perform set_config('request.jwt.claims',
    json_build_object('sub', user_b, 'role', 'authenticated')::text, true);

  select count(*) into n from search_ingredients('zzz nasa mrkva');
  if n <> 0 then
    failures := failures + 1;
    raise warning 'a non-member found another household''s private alias';
  end if;

  -- The global catalog is unaffected by any of that.
  select ingredient_id into got from search_ingredients('sargarepa') limit 1;
  if got is distinct from carrot then
    failures := failures + 1;
    raise warning 'a non-member lost access to the global catalog';
  end if;

  perform set_config('role', 'postgres', true);

  ---------------------------------------------------------------------------
  -- Teardown
  ---------------------------------------------------------------------------
  delete from ingredient_names where household_id = hid_a;
  delete from ingredients where key like 'zzz\_search\_%';
  delete from households where created_by in (user_a, user_b);
  delete from auth.users where id in (user_a, user_b);

  if failures > 0 then
    raise exception '% search_ingredients test(s) failed.', failures;
  end if;

  raise notice 'search_ingredients: all checks passed';
end
$$;
