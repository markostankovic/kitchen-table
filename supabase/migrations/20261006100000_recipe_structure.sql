-- Migration 24 -- recipe structure: step kinds and recipe notes (Phase 8,
-- round 2, slice 4).
--
-- A recipe's method can now hold section headings ("Za testo") and inline
-- notes between steps, and a recipe can carry an end note ("Napomena"). This
-- file stores them and carries them through every writer; nothing renders
-- them yet (slices 5, 6 and 9 do).
--
-- The load-bearing risk is silent data loss: once a recipe has a heading or a
-- note, every function that rewrites it must write them back. So each writer
-- below is redefined here, body otherwise unchanged, rather than left to read
-- a payload key it does not know about.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D153.

-- ---------------------------------------------------------------------------
-- Columns
-- ---------------------------------------------------------------------------
-- kind lives on recipe_steps only (D153). A heading or a note is a row in the
-- same ordered list and takes a position like any step, so
-- recipe_translations.steps stays [{position, text}] and a translation's
-- kind is read from the source row at the same position. One authority for
-- structure; a translation is prose over it.
--
-- A blank heading or note is already refused by recipe_steps's own
-- length(trim(text)) > 0 check. A timer only means something on an
-- instruction, so it is refused on anything else.

alter table recipe_steps
  add column kind text not null default 'step'
    check (kind in ('step', 'heading', 'note')),
  add constraint recipe_steps_timer_only_on_step
    check (kind = 'step' or timer_seconds is null);

-- One free-text column each, not a list (D153). The markdown subset (**, *,
-- "- ", "1. ") lives inside the text; nothing here parses it.
alter table recipes add column notes text;
alter table recipe_translations add column notes text;

comment on column recipe_steps.kind is
  'step (an instruction), heading (a section heading inside the method) or '
  'note (an aside between steps). Position is shared across kinds (D153).';
comment on column recipes.notes is
  'The recipe''s end note ("Napomena" / "Notes"), in the original language. '
  'Free text with the markdown subset; null when there is none (D153).';
comment on column recipe_translations.notes is
  'The translated end note. Null when the recipe has none (D153).';

-- ---------------------------------------------------------------------------
-- replace_recipe_lines
-- ---------------------------------------------------------------------------
-- Migration 8's body, with kind carried. Same signature -- kind rides inside
-- the steps jsonb, so `create or replace` is enough. An absent or blank kind
-- is 'step', which is what every caller written before this file sends.
--
-- The comment from migration 8 still holds: security invoker, so RLS still
-- decides who may write; the parameter is `recipe`, not `recipe_id` (D30);
-- position is assigned from array order rather than read from the JSON (D36).

create or replace function replace_recipe_lines(
  recipe           uuid,
  ingredient_lines jsonb default '[]'::jsonb,
  steps            jsonb default '[]'::jsonb
)
returns void
language plpgsql
security invoker
set search_path = public
as $$
begin
  -- Fail loudly rather than silently writing nothing. Without this, a caller
  -- who cannot see the recipe gets a successful no-op: the deletes match no
  -- rows and the inserts are refused row by row.
  if not exists (select 1 from recipes r where r.id = recipe) then
    raise exception 'recipe not found or not visible' using errcode = '42501';
  end if;

  delete from recipe_ingredients ri where ri.recipe_id = recipe;
  delete from recipe_steps rs where rs.recipe_id = recipe;

  insert into recipe_ingredients (
    recipe_id, position, section, raw_text, ingredient_id,
    qty_num, qty_den, qty_max_num, qty_max_den,
    unit_code, note, is_optional,
    match_method, match_confidence, matched_at
  )
  select
    recipe,
    (e.ord - 1)::int,
    nullif(btrim(e.line ->> 'section'), ''),
    e.line ->> 'raw_text',
    (e.line ->> 'ingredient_id')::uuid,
    (e.line ->> 'qty_num')::int,
    (e.line ->> 'qty_den')::int,
    (e.line ->> 'qty_max_num')::int,
    (e.line ->> 'qty_max_den')::int,
    nullif(btrim(e.line ->> 'unit_code'), ''),
    nullif(btrim(e.line ->> 'note'), ''),
    coalesce((e.line ->> 'is_optional')::boolean, false),
    nullif(btrim(e.line ->> 'match_method'), ''),
    (e.line ->> 'match_confidence')::numeric,
    (e.line ->> 'matched_at')::timestamptz
  from jsonb_array_elements(ingredient_lines) with ordinality as e(line, ord);

  insert into recipe_steps (recipe_id, position, text, timer_seconds, kind)
  select
    recipe,
    (e.ord - 1)::int,
    e.step ->> 'text',
    (e.step ->> 'timer_seconds')::int,
    coalesce(nullif(btrim(e.step ->> 'kind'), ''), 'step')
  from jsonb_array_elements(steps) with ordinality as e(step, ord);

  -- Touch the parent so its updated_at moves. The children carry no lifecycle
  -- columns of their own (D24), so without this a recipe whose entire
  -- ingredient list changed looks untouched to Phase 2's delta fetch and the
  -- Drift cache never re-reads it.
  update recipes set updated_at = now() where id = recipe;
end;
$$;

comment on function replace_recipe_lines(uuid, jsonb, jsonb) is
  'Replaces a recipe''s ingredient lines and steps (with their kind) in one '
  'transaction, and touches the parent''s updated_at. security invoker -- '
  'RLS still decides.';

-- ---------------------------------------------------------------------------
-- save_imported_recipe
-- ---------------------------------------------------------------------------
-- Migration 11's body, with recipe.notes written. Same signature -- notes
-- rides inside the recipe jsonb, and step kinds ride inside steps through
-- replace_recipe_lines above, which this still composes rather than copies
-- (D44). household_id still comes from the job, never from the payload.

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
  -- state is refused BEFORE a recipe is inserted.
  if job_status <> 'needs_review' then
    raise exception 'import job is not awaiting review' using errcode = '22023';
  end if;

  -- household_id comes from the JOB, never from the payload; status is forced
  -- to 'draft' (migration 11 gives both reasons in full).
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

comment on function save_imported_recipe(uuid, jsonb, jsonb, jsonb) is
  'Creates a recipe (with its notes) from a reviewed import, writes its lines '
  'and steps, and marks the job done -- in one transaction (D44). security '
  'definer, because import_jobs has no UPDATE policy (D39); membership is '
  'checked inline.';

-- ---------------------------------------------------------------------------
-- save_recipe_translation
-- ---------------------------------------------------------------------------
-- Migration 17's body, with a trailing `new_notes`. The signature changes, so
-- the old function is dropped and recreated rather than overloaded (D153): an
-- overload would make every existing five-argument call ambiguous, whereas a
-- defaulted sixth parameter keeps it resolving. The grants are re-stated on
-- the new signature because a drop takes them with it.
--
-- Parameters stay `recipe`/`loc`/`new_*` (D30).

drop function save_recipe_translation(uuid, text, text, text, jsonb);

create function save_recipe_translation(
  recipe          uuid,
  loc             text,
  new_title       text,
  new_description text,
  new_steps       jsonb default '[]'::jsonb,
  new_notes       text default null
)
returns uuid
language plpgsql
security invoker
set search_path = public
as $$
declare
  translation_id uuid;
  source_locale  text;
begin
  -- Fail loudly rather than silently writing nothing, replace_recipe_lines's
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

  -- do update, not do nothing (migration 17 gives the reason). Clearing the
  -- review columns on a re-translation is correct: the new prose has not
  -- been seen by anyone yet.
  insert into recipe_translations (
    recipe_id, locale, title, description, notes, steps,
    is_machine_generated, reviewed_by, reviewed_at
  )
  values (
    recipe, loc, new_title, new_description,
    nullif(btrim(coalesce(new_notes, '')), ''), new_steps, true, null, null
  )
  on conflict (recipe_id, locale) do update
    set title = excluded.title,
        description = excluded.description,
        notes = excluded.notes,
        steps = excluded.steps,
        is_machine_generated = true,
        reviewed_by = null,
        reviewed_at = null
  returning id into translation_id;

  return translation_id;
end;
$$;

comment on function save_recipe_translation(uuid, text, text, text, jsonb, text) is
  'Upserts one locale of a recipe''s translation, notes included, refusing '
  'an unknown locale or the recipe''s own original_locale. security invoker '
  '-- RLS still decides who may write.';

-- ---------------------------------------------------------------------------
-- review_recipe_translation
-- ---------------------------------------------------------------------------
-- Migration 18's body, with a trailing `new_notes`, dropped and recreated for
-- the same reason as its sibling above.
--
-- A review writes notes = new_notes, blank or absent meaning null (D153). It
-- is a whole-document write like the rest of this function, so a client
-- that does not send the translation's notes back clears them -- the review
-- draft carries them through for exactly that reason, even though the review
-- screen does not edit them yet.

drop function review_recipe_translation(uuid, text, text, text, jsonb);

create function review_recipe_translation(
  recipe          uuid,
  loc             text,
  new_title       text,
  new_description text,
  new_steps       jsonb default '[]'::jsonb,
  new_notes       text default null
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
  -- This function writes an identity, so it must refuse an anonymous caller
  -- rather than let reviewed_by land null.
  if caller is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

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
  -- step (or heading, or note) can be caught.
  if exists (
    select 1 from jsonb_array_elements(new_steps) as e(value)
    where length(trim(coalesce(e.value ->> 'text', ''))) = 0
  ) then
    raise exception 'step text required' using errcode = '22023';
  end if;

  -- The row must already exist -- review edits, it never creates.
  select steps into old_steps
  from recipe_translations
  where recipe_id = recipe and locale = loc;

  if old_steps is null then
    raise exception 'no translation to review for this locale'
      using errcode = '22023';
  end if;

  -- Position is an alignment key, not an ordering (D80): a reviewer may edit
  -- a step's TEXT but may not add, drop or renumber one. Headings and notes
  -- hold positions like any step (D153), so this guard covers them unchanged.
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

  update recipe_translations
  set title = btrim(new_title),
      description = nullif(btrim(coalesce(new_description, '')), ''),
      notes = nullif(btrim(coalesce(new_notes, '')), ''),
      steps = new_steps,
      is_machine_generated = false,
      -- auth.uid(), never a parameter (D83).
      reviewed_by = caller,
      reviewed_at = now()
  where recipe_id = recipe and locale = loc
  returning id into translation_id;

  -- Belt-and-suspenders on the existence check above: under RLS an update
  -- that matches nothing is indistinguishable from one that was refused.
  if translation_id is null then
    raise exception 'no translation to review for this locale'
      using errcode = '22023';
  end if;

  return translation_id;
end;
$$;

comment on function review_recipe_translation(uuid, text, text, text, jsonb, text) is
  'Records a human review of one locale of a recipe''s translation: edits '
  'title/description/notes/step text in place, refuses to add, drop or '
  'renumber a step, and stamps is_machine_generated = false, reviewed_by = '
  'auth.uid(), reviewed_at = now(). Updates only -- never creates a '
  'translation row. security invoker -- RLS still decides who may write.';

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
-- anon named explicitly -- Supabase's default privileges grant it EXECUTE
-- unless it is named (D30). The two translation writers are new signatures,
-- so they need their grants afresh; save_imported_recipe's are re-stated
-- only to keep this file self-describing (create or replace keeps them).

revoke execute on function save_imported_recipe(uuid, jsonb, jsonb, jsonb)
  from public, anon;
grant execute on function save_imported_recipe(uuid, jsonb, jsonb, jsonb)
  to authenticated, service_role;

revoke execute on function
  save_recipe_translation(uuid, text, text, text, jsonb, text)
  from public, anon;
grant execute on function
  save_recipe_translation(uuid, text, text, text, jsonb, text)
  to authenticated, service_role;

revoke execute on function
  review_recipe_translation(uuid, text, text, text, jsonb, text)
  from public, anon;
grant execute on function
  review_recipe_translation(uuid, text, text, text, jsonb, text)
  to authenticated, service_role;
