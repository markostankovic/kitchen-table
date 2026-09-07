-- Migration 6 -- merge_ingredients() (Phase 1b, third slice).
--
-- Duplicates in an accreted catalog are not an exception, they are the steady
-- state (D1): the tail auto-creates unverified rows, and two spellings of one
-- thing will arrive weeks apart. So merging is routine tooling, built on day
-- one, not a migration written in a panic later.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).

-- ---------------------------------------------------------------------------
-- merge_ingredients
-- ---------------------------------------------------------------------------
-- Repoints everything that references `source` at `target`, retires `source`,
-- and records the fact. Idempotent in the only sense that matters: it refuses
-- to run twice on the same source, because the second call finds it already
-- soft-deleted.
--
-- ON THE TABLES THAT DO NOT EXIST YET (D30)
--
-- docs/DATA_MODEL.md's step 1 is "update recipe_ingredients set ingredient_id
-- = target". recipe_ingredients arrives in Phase 1c and household_pantry_prefs
-- in Phase 2. Both are handled here anyway, behind a to_regclass() guard and a
-- dynamic EXECUTE, so this function is correct today and needs no rewrite when
-- they land -- which matters because the 1c roadmap entry does not mention
-- merge_ingredients at all, so a rewrite is exactly what would be forgotten.
--
-- The guard is deliberately an explicit list rather than a pg_constraint walk
-- that discovers referencing tables at runtime. A walk would never go stale,
-- but it would have to guess a conflict strategy per table and would silently
-- sweep in tables nobody considered. What keeps the list current is the FK
-- coverage assertion in supabase/tests/merge_ingredients_test.sql, which fails
-- the moment a new foreign key to ingredients(id) appears that this function
-- does not name. Same move as tool/check_layers.dart: encode the invariant in
-- a test rather than trust a future session to remember.
--
-- ON NAMES: NOTHING IS EVER DELETED
--
-- DATA_MODEL words step 2 as "on conflict, drop the duplicate name row". That
-- step is unreachable, and the reason is worth writing down. ingredient_names_
-- unique is total and spans the whole table, not one ingredient -- so a given
-- (normalized_name, locale, scope) already resolves to exactly ONE ingredient,
-- globally. Two ingredients cannot share an alias, therefore a merge cannot
-- produce a duplicate one, therefore there is nothing to drop. The repoint is
-- a plain UPDATE and CLAUDE.md rule 4 is satisfied without an exception.
--
-- What CAN collide is one_display_name_per_locale, since both ingredients may
-- have their own display name for the same locale. Those are demoted, not
-- deleted: the string stays matchable, it just stops being the one shown back.
--
-- ON THE PARAMETER NAMES
--
-- docs/DATA_MODEL.md writes the signature as merge_ingredients(source, target).
-- `source` is unusable: it is also a column of ingredient_names (curated / llm
-- / user), and a plpgsql parameter sharing a name with a column of a table in
-- the same statement is an ambiguity error -- which this function raised on
-- its first run, in the name-repointing UPDATE. Hence the longer names. Do not
-- shorten them back to match the doc; the doc is being corrected instead.

create or replace function merge_ingredients(
  source_ingredient uuid,
  target_ingredient uuid,
  actor             uuid default auth.uid()
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  tbl text;
begin
  -------------------------------------------------------------------------
  -- Guards
  -------------------------------------------------------------------------
  if source_ingredient is null or target_ingredient is null then
    raise exception 'merge_ingredients: source and target are both required'
      using errcode = '22023';
  end if;

  if source_ingredient = target_ingredient then
    raise exception 'merge_ingredients: % is both source and target', source_ingredient
      using errcode = '22023';
  end if;

  if not exists (
    select 1 from ingredients where id = source_ingredient and deleted_at is null
  ) then
    raise exception
      'merge_ingredients: source % does not exist or was already merged away',
      source_ingredient using errcode = '23503';
  end if;

  if not exists (
    select 1 from ingredients where id = target_ingredient and deleted_at is null
  ) then
    raise exception
      'merge_ingredients: target % does not exist or was already merged away',
      target_ingredient using errcode = '23503';
  end if;

  -- D3, one level. Re-parenting the source's children onto a target that is
  -- itself a child would make grandchildren. The table's trigger would catch
  -- it, but as a confusing failure halfway through the merge rather than a
  -- refusal to start.
  if exists (select 1 from ingredients where id = target_ingredient and parent_id is not null)
     and exists (select 1 from ingredients where parent_id = source_ingredient) then
    raise exception
      'merge_ingredients: % has children and % has a parent; merging would '
      'create a second level (D3)', source_ingredient, target_ingredient
      using errcode = '23514';
  end if;

  -------------------------------------------------------------------------
  -- Tables that simply repoint (Phase 1c, Phase 2)
  -------------------------------------------------------------------------
  foreach tbl in array array['recipe_ingredients', 'shopping_list_items'] loop
    if to_regclass('public.' || tbl) is not null then
      execute format(
        'update %I set ingredient_id = $1 where ingredient_id = $2', tbl)
        using target_ingredient, source_ingredient;
    end if;
  end loop;

  -------------------------------------------------------------------------
  -- household_pantry_prefs (Phase 2) -- primary key (household_id, ingredient_id)
  -------------------------------------------------------------------------
  -- A blind repoint violates that key whenever a household happens to have a
  -- preference for both ingredients. The source's row is redundant in that case
  -- (the household already expressed the same preference about the surviving
  -- concept), so it goes. This table is a join table with no deleted_at, on
  -- the household_members precedent in D24, so the delete is a hard one.
  if to_regclass('public.household_pantry_prefs') is not null then
    execute '
      delete from household_pantry_prefs s
      where s.ingredient_id = $2
        and exists (
          select 1 from household_pantry_prefs t
          where t.household_id = s.household_id
            and t.ingredient_id = $1)'
      using target_ingredient, source_ingredient;

    execute '
      update household_pantry_prefs
      set ingredient_id = $1
      where ingredient_id = $2'
      using target_ingredient, source_ingredient;
  end if;

  -------------------------------------------------------------------------
  -- Children
  -------------------------------------------------------------------------
  update ingredients set parent_id = target_ingredient where parent_id = source_ingredient;

  -------------------------------------------------------------------------
  -- Names
  -------------------------------------------------------------------------
  -- Demote first, while the rows still belong to the source. Afterwards they
  -- are indistinguishable from the target's own.
  update ingredient_names s
  set is_display_name = false
  where s.ingredient_id = source_ingredient
    and s.is_display_name
    and s.household_id is null
    and s.deleted_at is null
    and exists (
      select 1 from ingredient_names t
      where t.ingredient_id = target_ingredient
        and t.locale = s.locale
        and t.is_display_name
        and t.household_id is null
        and t.deleted_at is null);

  update ingredient_names
  set ingredient_id = target_ingredient
  where ingredient_id = source_ingredient;

  -------------------------------------------------------------------------
  -- Retire the source and record it
  -------------------------------------------------------------------------
  -- Soft delete, never a hard one (rule 4). The tombstone is also what Phase
  -- 2's delta fetch needs in order to evict the merged-away ingredient from
  -- the Drift cache (D12/D23).
  --
  -- `key` is deliberately left in place. Nulling it would let the next run of
  -- the catalog seed insert a brand new row under that key and quietly undo
  -- the merge; the seed's own `deleted_at is null` guards depend on the key
  -- still being here to match against.
  update ingredients set deleted_at = now() where id = source_ingredient;

  insert into ingredient_merges (source_id, target_id, merged_by)
  values (source_ingredient, target_ingredient, actor);
end;
$$;

comment on function merge_ingredients(uuid, uuid, uuid) is
  'Repoints every reference from source_ingredient to target_ingredient, retires source_ingredient, and writes '
  'an ingredient_merges row. Service role / operator only.';

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
-- This one is load-bearing, and it is a trap with two floors.
--
-- Floor one: Postgres grants EXECUTE on a new function to PUBLIC by default,
-- and PostgREST exposes everything in the public schema as an RPC endpoint. A
-- SECURITY DEFINER function that retires ingredients, reachable by any signed-
-- in user, would be a data-destruction endpoint shipped by omission -- and D32
-- has just finished establishing that clients have no write path here at all.
--
-- Floor two, and this is the one that actually bit: `revoke ... from public`
-- is NOT sufficient on Supabase. The platform ships
--
--     alter default privileges in schema public
--       grant all on functions to postgres, anon, authenticated, service_role;
--
-- so anon and authenticated hold EXECUTE in their own right, not through
-- PUBLIC, and revoking PUBLIC leaves both grants standing. The first run of
-- supabase/tests/merge_ingredients_test.sql called this function successfully
-- as `authenticated` with the PUBLIC revoke already in place. Every role has
-- to be named. Any future SECURITY DEFINER function that is not meant for
-- clients needs this same three-role revoke -- and a test that proves it,
-- because nothing else will.
--
-- There is no admin UI in Phase 1b; this is an operator tool. Granting it to
-- `authenticated` is Phase 2's admin-screen decision, not this migration's.

revoke execute on function merge_ingredients(uuid, uuid, uuid)
  from public, anon, authenticated;
grant execute on function merge_ingredients(uuid, uuid, uuid) to service_role;
