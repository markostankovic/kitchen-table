-- Migration 7 -- search_ingredients() (Phase 1b, fourth slice).
--
-- Tiers 2 and 3 of docs/INGREDIENTS.md's pipeline: exact normalized equality,
-- then trigram fuzzy. Tier 1 (line parsing) is Dart-side and needs no database
-- (D31). Tier 4 (LLM) and tier 5 (create) arrive in Phase 1d.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).

-- ---------------------------------------------------------------------------
-- search_ingredients
-- ---------------------------------------------------------------------------
-- ONE function, not two. An earlier design split ranking (autocomplete) from
-- policy (auto-accept), but the split put the 0.75 threshold on one side of a
-- boundary and 0.4 on the other. All three constants -- the four-character
-- floor, the 0.4 similarity threshold, and the 0.75 auto-accept line -- live
-- here, and `auto_accept` comes back as a computed boolean. The Dart side
-- therefore never holds a copy of 0.75 that can drift away from this one.
--
-- `language sql`, not plpgsql, on purpose: an output column named
-- `ingredient_id` would collide with ingredient_names.ingredient_id inside a
-- plpgsql body and fail at runtime rather than at create time. SQL-language
-- functions do not expose output parameters as variables, so the whole class
-- of bug is gone. (Part 3 shipped that exact bug and the test caught it.)
--
-- `security invoker` -- the default, stated for emphasis -- so RLS does the
-- household scoping. A member sees their household's private aliases; nobody
-- else does. There is deliberately no household_id parameter: a parameter
-- would be a claim the function has to verify, and the policy already knows.
--
-- ON similarity() RATHER THAN THE % OPERATOR
--
-- `%` reads pg_trgm.similarity_threshold, a session GUC set by set_limit(),
-- which is VOLATILE -- so a function using it could not be STABLE and its
-- results would depend on session state. similarity() takes the threshold as
-- an ordinary comparison instead. The cost is that the GIN trigram index does
-- not serve the fuzzy arm; at catalog scale that is a sequential scan over a
-- few hundred rows and irrelevant. The index still serves the prefix arm's
-- LIKE, and it is what a switch to `%` would need if the catalog ever grows
-- enough to justify one. That is the trade to revisit, not the index.
--
-- ON THE PREFIX ARM
--
-- Autocomplete needs it and fuzzy alone cannot provide it:
-- similarity('sargarepa', 'sarg') is about 0.36, below the 0.4 threshold, so
-- typing four letters of a nine-letter word would return nothing. Prefix hits
-- are reported as match_method 'fuzzy' with their TRUE similarity rather than
-- an invented high confidence -- inflating it would make them auto-accept,
-- and a four-letter prefix is a suggestion for a human, not a decision. They
-- are ranked above ordinary fuzzy hits through an internal tier that never
-- leaves the function, so match_method stays inside D7's vocabulary.

create or replace function search_ingredients(
  search_query     text,
  preferred_locale text default 'sr',
  max_results      int  default 20
)
returns table (
  ingredient_id      uuid,
  display_name       text,
  matched_name       text,
  matched_locale     text,
  is_verified        boolean,
  is_household_alias boolean,
  match_method       text,
  match_confidence   numeric,
  auto_accept        boolean
)
language sql
stable
security invoker
set search_path = public
as $$
  with q as (
    select
      normalize_text(search_query) as nq,
      -- LIKE metacharacters have to be escaped, not hoped away:
      -- normalize_text preserves punctuation, so a query can legitimately
      -- contain % or _ and would otherwise match far too much.
      replace(replace(replace(normalize_text(search_query),
        '\', '\\'), '%', '\%'), '_', '\_') as nq_like
  ),
  candidates as (
    -- Tier 2. `exact` when the string IS the ingredient's display name,
    -- `alias` when it is any other name for it. D7 lists both and this is
    -- what makes them mean different things: the split shows how much the
    -- alias table is actually earning.
    select
      n.ingredient_id,
      n.name          as matched_name,
      n.locale        as matched_locale,
      n.household_id,
      case when n.is_display_name then 'exact' else 'alias' end as match_method,
      1.0::numeric    as match_confidence,
      0               as tier
    from ingredient_names n, q
    where n.deleted_at is null
      and q.nq <> ''
      and n.normalized_name = q.nq

    union all

    -- Tier 3, gated on four characters. docs/INGREDIENTS.md: `so` must not
    -- fuzzy-match `soja`, `luk` must not match `luka`. Short strings hit the
    -- exact tier or go to the LLM in Phase 1d.
    select
      n.ingredient_id,
      n.name,
      n.locale,
      n.household_id,
      'fuzzy',
      round(similarity(n.normalized_name, q.nq)::numeric, 4),
      case when n.normalized_name like q.nq_like || '%' then 1 else 2 end
    from ingredient_names n, q
    where n.deleted_at is null
      and length(q.nq) >= 4
      and n.normalized_name <> q.nq
      and (n.normalized_name like q.nq_like || '%'
           or similarity(n.normalized_name, q.nq) > 0.4)
  ),
  -- One row per ingredient. Without this, brašno comes back three times
  -- because three of its aliases matched.
  best as (
    select distinct on (c.ingredient_id)
      c.ingredient_id,
      c.matched_name,
      c.matched_locale,
      c.household_id,
      c.match_method,
      c.match_confidence,
      c.tier
    from candidates c
    join ingredients i
      on i.id = c.ingredient_id and i.deleted_at is null
    order by
      c.ingredient_id,
      c.tier,
      c.match_confidence desc,
      -- Locale is a TIE-BREAK, never a filter. An English recipe still has to
      -- find brašno through `flour`, and a Serbian user typing `flour` still
      -- has to find it -- that cross-language hop is the product's wedge.
      (c.matched_locale = preferred_locale) desc,
      -- A household's own name for something beats the global one.
      (c.household_id is not null) desc,
      length(c.matched_name)
  )
  select
    b.ingredient_id,
    ingredient_display_name(b.ingredient_id, preferred_locale),
    b.matched_name,
    b.matched_locale,
    i.is_verified,
    b.household_id is not null,
    b.match_method,
    b.match_confidence,
    -- The 0.75 line from docs/INGREDIENTS.md. Exact and alias hits carry 1.0
    -- and clear it by construction, so one comparison covers every tier.
    b.match_confidence >= 0.75
  from best b
  join ingredients i on i.id = b.ingredient_id
  order by
    b.tier,
    b.match_confidence desc,
    (b.matched_locale = preferred_locale) desc,
    i.is_verified desc,
    length(b.matched_name)
  limit max_results;
$$;

comment on function search_ingredients(text, text, int) is
  'Tiers 2-3 of the ingredient matcher: exact/alias, then prefix and trigram '
  'fuzzy above 0.4 for queries of 4+ characters. auto_accept is the 0.75 line. '
  'One row per ingredient, best match wins.';

-- Unlike merge_ingredients, this one IS for clients -- it is the autocomplete
-- behind Phase 1c's ingredient line editor. It reads nothing RLS would not
-- already hand the caller, so Supabase's default grant to anon/authenticated
-- is correct here and is deliberately left in place.
