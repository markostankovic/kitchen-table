-- Migration 11 -- save_imported_recipe() (Phase 1d, third slice).
--
-- D37's flagged revisit, arriving exactly where it said it would. That
-- decision ruled that a new recipe is `create()` then `saveLines()` from the
-- client, with no create_recipe RPC, and ended: "Revisit if import (1d) needs
-- to write a recipe and its lines as one unit from the server side, where the
-- argument is different."
--
-- It does, and it is. For manual entry the two-step is safe because the draft
-- keeps the id it was given, so a failed second step is fixed by pressing Save
-- again. An import has a third step -- marking the job done -- and no such
-- anchor: a failure between them leaves an orphan recipe AND a job still in
-- needs_review, so pressing Save again creates a SECOND recipe from the same
-- import. That is the case D37 said would justify a function, and this is it.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D44.

-- ---------------------------------------------------------------------------
-- save_imported_recipe
-- ---------------------------------------------------------------------------
-- security definer, and the reason is the same one finish_import_job gives:
-- import_jobs has no UPDATE policy at all (D39), so an invoker-rights function
-- could not mark the job done. A definer bypasses RLS, so the membership check
-- is written out by hand -- the rule _shared/auth.ts states for the
-- service-role client, applied in SQL.
--
-- It composes rather than reimplements. replace_recipe_lines (D36) already
-- knows how to turn the two JSON arrays into rows, and finish_import_job
-- (migration 10) already knows what completing a job means, including refusing
-- one that is not awaiting review. Copying either would be a second definition
-- of a rule that is already tested.
--
-- The parameter is `job`, not `job_id`, for the same reason as migration 10:
-- recipe_id is a column of import_jobs and D30's ambiguity error was learned
-- once already.

create or replace function save_imported_recipe(
  job              uuid,
  recipe           jsonb,
  ingredient_lines jsonb default '[]'::jsonb,
  steps            jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  caller       uuid := auth.uid();
  household    uuid;
  job_status   text;
  new_recipe   uuid;
begin
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  -- The explicit predicate. is_household_member() reads auth.uid(), which a
  -- SECURITY DEFINER context does not change -- it comes from the JWT claim,
  -- not from the current role -- so this is the same question the SELECT
  -- policy asks.
  select j.household_id, j.status
    into household, job_status
  from import_jobs j
  where j.id = job
    and j.deleted_at is null
    and is_household_member(j.household_id);

  if household is null then
    raise exception 'import job not found or not visible'
      using errcode = '42501';
  end if;

  -- Checked here as well as inside finish_import_job, so a job in the wrong
  -- state is refused BEFORE a recipe is inserted. Without this the insert
  -- would happen, finish_import_job would raise, the transaction would roll
  -- back -- correct, but only by accident of ordering.
  if job_status <> 'needs_review' then
    raise exception 'import job is not awaiting review' using errcode = '22023';
  end if;

  -- household_id comes from the JOB, never from the payload. The client has
  -- no business naming a household, and this is the one place a definer
  -- function could be talked into writing into somebody else's.
  --
  -- status is forced to 'draft' rather than read: anything AI-produced is
  -- draft until a human marks it tested (docs/ROADMAP.md, standing rules), and
  -- an import is AI-produced by definition. A cook who wants it tested says so
  -- on the recipe screen afterwards.
  insert into recipes (
    household_id, title, description, servings, prep_minutes, cook_minutes,
    original_locale, source_type, source_url, source_attribution,
    status, tags, created_by
  )
  values (
    household,
    recipe ->> 'title',
    nullif(btrim(coalesce(recipe ->> 'description', '')), ''),
    (recipe ->> 'servings')::int,
    (recipe ->> 'prep_minutes')::int,
    (recipe ->> 'cook_minutes')::int,
    coalesce(recipe ->> 'original_locale', 'sr'),
    coalesce(recipe ->> 'source_type', 'url_import'),
    nullif(btrim(coalesce(recipe ->> 'source_url', '')), ''),
    nullif(btrim(coalesce(recipe ->> 'source_attribution', '')), ''),
    'draft',
    coalesce(
      (select array_agg(value::text) from jsonb_array_elements_text(
         coalesce(recipe -> 'tags', '[]'::jsonb)) as value),
      '{}'::text[]
    ),
    caller
  )
  returning id into new_recipe;

  perform replace_recipe_lines(new_recipe, ingredient_lines, steps);
  perform finish_import_job(job, new_recipe);

  return new_recipe;
end;
$$;

comment on function save_imported_recipe(uuid, jsonb, jsonb, jsonb) is
  'Creates a recipe from a reviewed import, writes its lines and steps, and '
  'marks the job done -- in one transaction (D44). security definer, because '
  'import_jobs has no UPDATE policy (D39); membership is checked inline.';

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
-- For clients: the confirm screen is the only caller. anon is revoked
-- explicitly because Supabase's default privileges grant it EXECUTE unless it
-- is named -- the lesson merge_ingredients learned the hard way (D30).

revoke execute on function save_imported_recipe(uuid, jsonb, jsonb, jsonb)
  from public, anon;
grant execute on function save_imported_recipe(uuid, jsonb, jsonb, jsonb)
  to authenticated, service_role;
