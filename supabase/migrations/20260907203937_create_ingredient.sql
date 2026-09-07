-- Migration 9 -- create_ingredient() and link_ingredient_alias()
-- (Phase 1c, second slice).
--
-- The narrow write path into the catalog that D32 promised and deliberately
-- did not ship a phase early:
--
--   "Phase 1c's 'create a new ingredient' does need a path, and it gets a
--    deliberate one then -- a narrow SECURITY DEFINER RPC on the
--    create_household precedent, which can check for an existing exact match
--    first and so stop two people typing the same new ingredient from creating
--    two rows. What it must not do is inherit a broad INSERT policy written a
--    phase early by someone guessing at its shape."
--
-- These are tiers 4 and 5 of docs/INGREDIENTS.md arriving early, driven by a
-- human rather than a model: the line editor is the confirm screen in effect
-- (D8), and every human decision it records writes back a global alias so the
-- string resolves at tier 2 forever, for every household.
--
-- Both are SECURITY DEFINER because the catalog has no INSERT policy for
-- anyone and is not getting one. The privilege is the point; the guards below
-- are what make it narrow.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D34.

-- ---------------------------------------------------------------------------
-- create_ingredient
-- ---------------------------------------------------------------------------
-- The exact-match guard is the reason this is a function and not an INSERT
-- policy. Two people entering their grandmother's recipe on the same evening
-- both type `urnebes`; a policy would give the catalog two rows for it and a
-- merge to do later. The guard costs one index lookup and removes the whole
-- class.
--
-- The guard mirrors ingredient_names_unique EXACTLY -- (normalized_name,
-- locale, global) -- because a guard narrower than the index it protects
-- raises a constraint violation instead of returning a row, and a guard wider
-- than it silently refuses to create things that would have been fine.
--
-- KNOWN AND DELIBERATE GAP: the guard does not look across locales. Somebody
-- creating `ajvar` in `en` when `ajvar` already exists in `sr` gets a second
-- ingredient. Widening it would mean deciding that a string naming an
-- ingredient in one language names the same one in the other, which is false
-- often enough to matter -- Serbian `pita` is a pie, English `pita` is bread.
-- Cross-locale duplicates are what merge_ingredients is for, and
-- docs/INGREDIENTS.md is explicit that merging is routine rather than
-- exceptional. A wrong merge is reversible by a human; a wrongly-fused
-- ingredient is a silently wrong shopping list.
--
-- New ingredients get key = null. `key` is the curated seed key (D27) and only
-- supabase/seeds/*.csv issues them; a user-created row that claimed one would
-- collide with the next seed run.

create or replace function create_ingredient(
  ingredient_name text,
  loc             text default 'sr',
  unit_family     text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  caller     uuid := auth.uid();
  clean_name text := btrim(coalesce(ingredient_name, ''));
  norm       text;
  existing   uuid;
  new_id     uuid;
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  if length(clean_name) = 0 then
    raise exception 'ingredient name required' using errcode = '22023';
  end if;

  if loc not in ('sr', 'en') then
    raise exception 'locale must be sr or en' using errcode = '22023';
  end if;

  if unit_family is not null
     and unit_family not in ('mass', 'volume', 'count') then
    raise exception 'unit family must be mass, volume or count'
      using errcode = '22023';
  end if;

  norm := normalize_text(clean_name);

  -- Already a live global name for this string in this locale: hand back what
  -- it points at. Idempotent, so a double tap on "create" is harmless.
  select n.ingredient_id into existing
  from ingredient_names n
  where n.normalized_name = norm
    and n.locale = loc
    and n.household_id is null
    and n.deleted_at is null
  limit 1;

  if existing is not null then
    return existing;
  end if;

  -- A retired row for the same string. ingredient_names_unique is TOTAL (D28)
  -- -- it counts tombstones -- so this row would block the insert below, and
  -- resurrecting it is what D28 says re-seeding a retired alias does anyway.
  -- Whatever it already points at wins; creating a second ingredient for a
  -- string the catalog has seen before is the outcome this function exists to
  -- prevent.
  select n.ingredient_id into existing
  from ingredient_names n
  where n.normalized_name = norm
    and n.locale = loc
    and n.household_id is null
    and n.deleted_at is not null
  limit 1;

  if existing is not null then
    update ingredient_names
       set deleted_at = null,
           source = 'user'
     where normalized_name = norm
       and locale = loc
       and household_id is null;

    -- The ingredient itself may have been retired by a merge. Resurrecting
    -- its name without it would leave a live alias pointing at a tombstone,
    -- which every search would then return and no screen could render.
    update ingredients
       set deleted_at = null
     where id = existing
       and deleted_at is not null;

    return existing;
  end if;

  -- Both inserts inside one block, so a concurrent creator that wins the race
  -- rolls this attempt back whole. Without the block, the ingredients row
  -- would survive the failed name insert as an unreachable orphan with no
  -- name in any locale.
  begin
    insert into ingredients (default_unit_family, is_verified)
    values (unit_family, false)
    returning id into new_id;

    insert into ingredient_names
      (ingredient_id, name, locale, is_display_name, household_id, source)
    values (new_id, clean_name, loc, true, null, 'user');
  exception when unique_violation then
    select n.ingredient_id into existing
    from ingredient_names n
    where n.normalized_name = norm
      and n.locale = loc
      and n.household_id is null
    limit 1;

    if existing is null then
      raise;
    end if;
    return existing;
  end;

  return new_id;
end;
$$;

comment on function create_ingredient(text, text, text) is
  'Creates an unverified ingredient with one display name, or returns the '
  'existing one if the string already names something in that locale. The '
  'only client write path into ingredients (D32, D34).';

-- ---------------------------------------------------------------------------
-- link_ingredient_alias
-- ---------------------------------------------------------------------------
-- The write-back half. docs/INGREDIENTS.md: "Every resolution writes back.
-- When tier 3, 4, or 5 resolves a string that wasn't already an alias, insert
-- an ingredient_names row for it. That string now resolves at tier 2 forever,
-- for every household." A human correcting a line on the confirm screen is the
-- strongest version of that signal (D8), so it is the one 1c ships.
--
-- Rows are GLOBAL, not household-scoped. That is deliberate and it is what
-- D32 says: household-scoped alias rows belong to a later "we call it X in
-- this house" feature that does not exist, and writing them here would ship
-- half of it by accident.
--
-- RETURNS BOOLEAN, not void, and the false case is the interesting one.
--
-- A string can already be a live global alias for a DIFFERENT ingredient. The
-- honest answer there is to refuse: `beli luk` naming garlic is not something
-- one household's recipe gets to repoint, and hijacking it would silently
-- change what that word means for everybody. But the recipe line itself is
-- perfectly valid and must still save, so this cannot raise -- it returns
-- false and the caller carries on. Turning that into an exception would make
-- one household's unusual wording fail somebody's recipe save.

create or replace function link_ingredient_alias(
  ingredient uuid,
  alias_name text,
  loc        text default 'sr'
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  caller     uuid := auth.uid();
  clean_name text := btrim(coalesce(alias_name, ''));
  norm       text;
  owner_id   uuid;
  is_dead    boolean;
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  if length(clean_name) = 0 then
    raise exception 'alias name required' using errcode = '22023';
  end if;

  if loc not in ('sr', 'en') then
    raise exception 'locale must be sr or en' using errcode = '22023';
  end if;

  if not exists (
    select 1 from ingredients i
    where i.id = ingredient and i.deleted_at is null
  ) then
    raise exception 'no such ingredient' using errcode = '22023';
  end if;

  norm := normalize_text(clean_name);

  select n.ingredient_id, n.deleted_at is not null
    into owner_id, is_dead
  from ingredient_names n
  where n.normalized_name = norm
    and n.locale = loc
    and n.household_id is null
  limit 1;

  if owner_id is not null then
    if not is_dead then
      -- Already ours: nothing to do, and say so. Already somebody else's:
      -- leave it alone, and say that too.
      return owner_id = ingredient;
    end if;

    -- A tombstone. D28's index counts it, so it has to be reused rather than
    -- inserted around, and re-pointing a retired string is exactly what D28
    -- describes re-seeding as doing.
    update ingredient_names
       set ingredient_id = ingredient,
           name = clean_name,
           deleted_at = null,
           is_display_name = false,
           source = 'user'
     where normalized_name = norm
       and locale = loc
       and household_id is null;

    return true;
  end if;

  begin
    insert into ingredient_names
      (ingredient_id, name, locale, is_display_name, household_id, source)
    values (ingredient, clean_name, loc, false, null, 'user');
  exception when unique_violation then
    -- Somebody inserted the same string between the select and the insert.
    -- Whoever won, the answer to "does this string now point at `ingredient`"
    -- is a fresh read, not this transaction's assumption.
    select n.ingredient_id into owner_id
    from ingredient_names n
    where n.normalized_name = norm
      and n.locale = loc
      and n.household_id is null
    limit 1;

    return owner_id = ingredient;
  end;

  return true;
end;
$$;

comment on function link_ingredient_alias(uuid, text, text) is
  'Records that a string names an ingredient, globally and forever (tier 2 '
  'write-back). Returns false, without raising, when the string already names '
  'a different ingredient.';

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
-- The mirror image of merge_ingredients' grant block, and worth stating
-- plainly so the contrast does not read as an oversight: these two functions
-- ARE for clients. The line editor calls them on every human decision, so
-- `authenticated` keeps its EXECUTE.
--
-- `anon` does not. Both functions refuse a null auth.uid() already, so this is
-- defence in depth rather than the only lock -- but an unauthenticated caller
-- has no business reaching a SECURITY DEFINER function that writes a global
-- table, and the platform's default privileges grant anon EXECUTE unless it
-- is named. merge_ingredients' migration learned that the hard way: revoking
-- PUBLIC alone leaves anon and authenticated holding grants of their own.

revoke execute on function create_ingredient(text, text, text)
  from public, anon;
revoke execute on function link_ingredient_alias(uuid, text, text)
  from public, anon;

grant execute on function create_ingredient(text, text, text)
  to authenticated, service_role;
grant execute on function link_ingredient_alias(uuid, text, text)
  to authenticated, service_role;
