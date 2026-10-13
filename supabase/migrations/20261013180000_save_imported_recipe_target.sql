-- Phase 9 slice C. save_imported_recipe takes an optional target household
-- (D175, on D168's reasoning).
--
-- Migration 11 took household_id from the job, never from the payload, so a
-- definer function could not be talked into writing into a household the
-- caller is not in. With more than one household, an import shared from the
-- browser may belong somewhere other than the job's household, so the review
-- can now name a target. The rule's spirit stands: the job's household is
-- still the default, and a named target is accepted only when the caller is
-- a member of THAT household -- checked before anything keyed on it (D31).
-- "The client may not name a household it doesn't belong to" is upheld by the
-- membership check, not by refusing to let the client name one (D168).
--
-- The new parameter defaults to null, which keeps installed builds working:
-- PostgREST resolves their four-named-argument call onto this five-argument
-- function, and phones update later (D168). It is a new signature, so the old
-- function is dropped rather than overloaded (D153) and the grants are
-- re-stated, because a drop takes them with it.
--
-- The body is otherwise copied from
-- 20261006100000_recipe_structure.sql, which stays untouched.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).

drop function save_imported_recipe(uuid, jsonb, jsonb, jsonb);

create function save_imported_recipe(
  job              uuid,
  recipe           jsonb,
  ingredient_lines jsonb default '[]'::jsonb,
  steps            jsonb default '[]'::jsonb,
  target_household uuid default null
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
  -- state is refused BEFORE a recipe is inserted.
  if job_status <> 'needs_review' then
    raise exception 'import job is not awaiting review' using errcode = '22023';
  end if;

  -- A named target only when the caller belongs to it (D31, D175). 42501, the
  -- job visibility check's code: this only happens on a race (the caller left
  -- that household mid-review) or a client bug.
  if target_household is not null
     and not is_household_member(target_household) then
    raise exception 'not a member of that household' using errcode = '42501';
  end if;

  household := coalesce(target_household, household);

  -- household_id comes from the job, or from a target the caller was just
  -- checked to belong to; status is forced to 'draft' (migration 11 gives
  -- both reasons in full).
  insert into recipes (
    household_id, title, description, notes, servings, prep_minutes,
    cook_minutes, original_locale, source_type, source_url,
    source_attribution, status, tags, created_by
  )
  values (
    household,
    recipe ->> 'title',
    nullif(btrim(coalesce(recipe ->> 'description', '')), ''),
    nullif(btrim(coalesce(recipe ->> 'notes', '')), ''),
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

comment on function save_imported_recipe(uuid, jsonb, jsonb, jsonb, uuid) is
  'Creates a recipe (with its notes) from a reviewed import, writes its lines '
  'and steps, and marks the job done -- in one transaction (D44). The recipe '
  'goes to the job''s household, or to target_household when the caller is a '
  'member of it (D175). security definer, because import_jobs has no UPDATE '
  'policy (D39); membership is checked inline.';

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
-- anon named explicitly -- Supabase's default privileges grant it EXECUTE
-- unless it is named (D30).

revoke execute on function
  save_imported_recipe(uuid, jsonb, jsonb, jsonb, uuid)
  from public, anon;
grant execute on function
  save_imported_recipe(uuid, jsonb, jsonb, jsonb, uuid)
  to authenticated, service_role;
