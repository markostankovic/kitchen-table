-- Migration 18 -- review_recipe_translation (Phase 3, part 3).
--
-- The writer migration 17 named and left unwritten: reviewed_by and
-- reviewed_at shipped on recipe_translations with nothing setting them,
-- on recipes.image_path's and leftover_of_entry_id's own precedent (D35,
-- D51). This closes that forward reference.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D82 (a separate writer, never a flag on
-- save_recipe_translation) and D83 (what a review records, and who it
-- records it as).

-- ---------------------------------------------------------------------------
-- review_recipe_translation
-- ---------------------------------------------------------------------------
-- save_recipe_translation is the wrong door for this: its own `on conflict`
-- deliberately wipes is_machine_generated/reviewed_by/reviewed_at on every
-- re-translation, because a fresh machine pass has not been seen by anyone.
-- A review wants the opposite of that on the same row, so it is a sibling
-- function, not a parameter added to the existing one.
--
-- Unlike its sibling, this function UPDATEs and never INSERTs -- review edits
-- prose that already exists; there is no client-facing way to hand-author a
-- translation that was never machine-produced, and this function is not it.
--
-- security invoker, no new RLS policy: recipe_translations_update (migration
-- 17) already carries both `using` and `with check` over the same
-- membership-through-parent predicate a review write needs. This function
-- holds no privilege the caller does not already have; it exists for
-- validation and provenance, not authority.
--
-- Parameters are `recipe`/`loc`/`new_*`, never the column names, for the same
-- reason migration 17 gives (D30): a plpgsql parameter sharing a name with a
-- column in the same statement is an ambiguity error.

create or replace function review_recipe_translation(
  recipe          uuid,
  loc             text,
  new_title       text,
  new_description text,
  new_steps       jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  caller         uuid := auth.uid();
  translation_id uuid;
  source_locale  text;
  old_steps      jsonb;
  old_positions  int[];
  new_positions  int[];
begin
  -- Unlike save_recipe_translation, this function writes an identity, so it
  -- must refuse an anonymous caller rather than let reviewed_by land null --
  -- create_ingredient and link_ingredient_alias open the same way.
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  -- Fail loudly rather than silently writing nothing, save_recipe_translation's
  -- own guard: without this, a caller who cannot see the recipe gets a
  -- successful no-op instead of a refusal.
  select r.original_locale into source_locale
  from recipes r
  where r.id = recipe;

  if source_locale is null then
    raise exception 'recipe not found or not visible' using errcode = '42501';
  end if;

  if loc not in ('sr', 'en') then
    raise exception 'locale must be sr or en' using errcode = '22023';
  end if;

  if loc = source_locale then
    raise exception 'locale matches the recipe''s own original_locale'
      using errcode = '22023';
  end if;

  if length(trim(coalesce(new_title, ''))) = 0 then
    raise exception 'translation title required' using errcode = '22023';
  end if;

  -- recipe_steps.text carries a check constraint; this jsonb column carries
  -- no such thing, so this function is the only place a blank translated
  -- step can be caught.
  if exists (
    select 1 from jsonb_array_elements(new_steps) as e(value)
    where length(trim(coalesce(e.value ->> 'text', ''))) = 0
  ) then
    raise exception 'step text required' using errcode = '22023';
  end if;

  -- The row must already exist -- review edits, it never creates. Reading
  -- its own `steps` here does two jobs at once: it answers "does a
  -- translation exist for this locale" and it gives the position guard below
  -- something to check against.
  select steps into old_steps
  from recipe_translations
  where recipe_id = recipe and locale = loc;

  if old_steps is null then
    raise exception 'no translation to review for this locale'
      using errcode = '22023';
  end if;

  -- Position is an alignment key, not an ordering (D80): a reviewer may edit
  -- a step's TEXT but may not add, drop or renumber one. alignSteps already
  -- tied this row's positions to the recipe's own recipe_steps at write
  -- time, so the row itself -- not recipe_steps -- is the nearer and cheaper
  -- authority to check a human edit against; a review is by definition
  -- editing the document that was opened.
  --
  -- This is NOT rule 6's fourth cross-language pair: alignSteps validates a
  -- MODEL's answer against a source it was given, and this validates a
  -- HUMAN's edit against the row they opened. Same arithmetic, different
  -- inputs and different failure modes -- there is no fixture that could be
  -- meaningful for both, which is why there is no
  -- test/fixtures/step_positions.json to go with this.
  select array_agg((e.value ->> 'position')::int order by (e.value ->> 'position')::int)
  into old_positions
  from jsonb_array_elements(old_steps) as e(value);

  select array_agg((e.value ->> 'position')::int order by (e.value ->> 'position')::int)
  into new_positions
  from jsonb_array_elements(new_steps) as e(value);

  if old_positions is distinct from new_positions then
    raise exception
      'translated steps must match the recipe''s own step positions'
      using errcode = '22023';
  end if;

  -- A plain update, not an upsert -- the existence check above already ruled
  -- out the insert path. updated_at is left to recipe_translations_set_updated_at
  -- and the parent's updated_at to recipe_translations_touch_recipe (both
  -- migration 17); a third writer here would only risk disagreeing with them.
  update recipe_translations
  set title = btrim(new_title),
      description = nullif(btrim(coalesce(new_description, '')), ''),
      steps = new_steps,
      is_machine_generated = false,
      -- auth.uid(), never a parameter -- RLS would happily let a member
      -- write any uuid here; this assignment is what makes the column mean
      -- something (D7's argument, and why link_ingredient_alias hardcodes
      -- source = 'user').
      reviewed_by = caller,
      reviewed_at = now()
  where recipe_id = recipe and locale = loc
  returning id into translation_id;

  -- Belt-and-suspenders on the existence check above: under RLS an update
  -- that matches nothing is indistinguishable from one that was refused,
  -- the trap replace_recipe_lines's own comment names. Reaching this with a
  -- null id would mean the row was deleted between the select and the
  -- update -- not reachable through normal use, but silence here would be
  -- worse than the exception.
  if translation_id is null then
    raise exception 'no translation to review for this locale'
      using errcode = '22023';
  end if;

  return translation_id;
end;
$$;

comment on function review_recipe_translation(uuid, text, text, text, jsonb) is
  'Records a human review of one locale of a recipe''s translation: edits '
  'title/description/step text in place, refuses to add, drop or renumber a '
  'step, and stamps is_machine_generated = false, reviewed_by = auth.uid(), '
  'reviewed_at = now(). Updates only -- never creates a translation row. '
  'security invoker -- RLS still decides who may write.';

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
-- anon named explicitly -- Supabase's default privileges grant it EXECUTE
-- unless it is named (D30). Granted to service_role on every other function
-- in this project regardless of whether anything server-side actually calls
-- it (create_ingredient and link_ingredient_alias have no server caller
-- either) -- and checked empirically here: service_role already has EXECUTE
-- on every public-schema function by Supabase's own platform default, so
-- withholding this grant would not have restricted anything and would only
-- have made this function inconsistent with its sibling for no real effect.

revoke execute on function
  review_recipe_translation(uuid, text, text, text, jsonb) from public, anon;
grant execute on function
  review_recipe_translation(uuid, text, text, text, jsonb)
  to authenticated, service_role;
