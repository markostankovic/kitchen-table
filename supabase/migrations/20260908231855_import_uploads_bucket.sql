-- Migration 12 -- the import-uploads bucket (Phase 1d, fifth slice).
--
-- The first Storage bucket in the project and the first policies on
-- storage.objects. D35 moved photo upload to Phase 2, and that still holds for
-- the recipe's own picture -- `recipes.image_path` is untouched here. This
-- bucket is for something else: the photograph of a cookbook page is an INPUT
-- to an import, not a picture of the dish, and `import_jobs.input_storage_path`
-- has been waiting for it since migration 10.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D46.

-- ---------------------------------------------------------------------------
-- The path convention
-- ---------------------------------------------------------------------------
--
--     import-uploads/{household_id}/{uuid}.jpg
--
-- The first folder segment is the household id, and that is not a filing
-- convenience -- it IS the access control. Every policy below reads it, so a
-- path that does not begin with a household the caller belongs to is not
-- writable, readable or deletable by them. Nothing else in the path is trusted
-- or parsed.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'import-uploads',
  'import-uploads',
  -- Private. A cookbook page is somebody else's copyrighted prose sitting in
  -- one household's account (D16); a public URL to it is exactly the thing
  -- D16 says there is no path to.
  false,
  -- 10 MB. The client downscales before uploading -- a phone's 12-megapixel
  -- original is mostly detail the model cannot use -- so this is a backstop
  -- against a mistake rather than the working size.
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- storage_path_household
-- ---------------------------------------------------------------------------
-- The household id at the front of an object path, or null.
--
-- Why a function rather than `(storage.foldername(name))[1]::uuid` inline in
-- each policy: that cast RAISES on anything that is not a uuid. An exception
-- inside a policy is not a refusal -- it is a 500 -- so a client could turn a
-- denied upload into a server error by naming `hello/world.jpg`. Swallowing
-- the cast failure and returning null is the whole point, because
-- `is_household_member(null)` is already false.
--
-- immutable, so the planner may use it in a policy without re-evaluating it
-- per row.

create or replace function storage_path_household(object_name text)
returns uuid
language plpgsql
immutable
set search_path = public, storage
as $$
declare
  segment text := (storage.foldername(object_name))[1];
begin
  return segment::uuid;
exception when others then
  return null;
end;
$$;

comment on function storage_path_household(text) is
  'The household id in the first segment of a Storage object path, or null if '
  'there is not one. Null rather than an exception, because a policy that '
  'raises returns 500 instead of denying (D46).';

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
-- storage.objects already has RLS enabled -- Supabase does that -- so this
-- adds policies only. There is deliberately no `alter table ... enable row
-- level security` here: asserting it on a table this migration does not own
-- would be noise, and it is already true.
--
-- Every policy is scoped to this bucket by name. A policy that forgot the
-- bucket_id clause would grant the same access across every bucket added
-- later, including Phase 2's recipe images.

create policy import_uploads_insert on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'import-uploads'
    and is_household_member(storage_path_household(name))
  );

create policy import_uploads_select on storage.objects for select
  to authenticated
  using (
    bucket_id = 'import-uploads'
    and is_household_member(storage_path_household(name))
  );

create policy import_uploads_delete on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'import-uploads'
    and is_household_member(storage_path_household(name))
  );

-- No UPDATE policy, deliberately. An uploaded page is immutable: photographing
-- it again is a new object under a new uuid, not an edit of this one. The same
-- instinct as ai_usage having no UPDATE (D38) -- a record of what was actually
-- sent to a model should not be rewritable after the fact.
--
-- Note this is a hard DELETE rather than a soft one, and rule 4 is not
-- breached: D24 scopes "no hard deletes" to tables carrying a household_id,
-- and storage.objects is not ours to add a deleted_at to. A tombstoned blob
-- would also still cost storage, which is the thing deleting it is for.

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
-- storage_path_household is only ever called from inside a policy, where it
-- runs as whoever is being checked -- so `authenticated` needs EXECUTE. anon
-- is revoked explicitly because the platform's default privileges grant it
-- unless it is named (D30, learned in merge_ingredients).

revoke execute on function storage_path_household(text) from public, anon;
grant execute on function storage_path_household(text)
  to authenticated, service_role;
