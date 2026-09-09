-- Migration 13 -- the recipe-images bucket (Phase 2, part 1).
--
-- D35 moved this out of Phase 1c and left `recipes.image_path` sitting
-- unwritten and unread since migration 8. This gives it a bucket, so a recipe
-- can finally carry a photo of the dish.
--
-- NEVER EDIT THIS FILE ONCE APPLIED (CLAUDE.md).
--
-- Decisions taken in this file: D48.

-- ---------------------------------------------------------------------------
-- The path convention
-- ---------------------------------------------------------------------------
--
--     recipe-images/{household_id}/{name}.jpg
--
-- The same shape as import-uploads (D46): the first segment is the household
-- id, and that IS the access control -- every policy below reads it through
-- the existing `storage_path_household(text)`. Nothing else in the path is
-- trusted or parsed.
--
-- A second bucket rather than reusing import-uploads, deliberately (D48): an
-- import upload is an input to a job that finishes, a dish photo is part of a
-- recipe that persists, and D46 already said every policy should name its
-- bucket precisely so "Phase 2's recipe images" would not inherit them.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'recipe-images',
  'recipe-images',
  -- Private, not public (D48). The bucket also holds photos attached to `ocr`
  -- and `url_import` recipes, which D16 makes permanently household-scoped --
  -- a public bucket would put those behind an unauthenticated URL, exactly the
  -- path D16 says does not exist. Served through signed URLs instead.
  false,
  -- 5 MB. The client downscales to ~1200px before uploading -- this dish photo
  -- is only ever looked at, never read by a model -- so this is a backstop
  -- against a mistake, smaller than import-uploads' 10 MB because a cookbook
  -- page needs more headroom than a plated dinner.
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
)
on conflict (id) do nothing;

-- storage_path_household(text) already exists (migration 12, D46) and is
-- already granted to authenticated and service_role. It is not redefined
-- here: a second definition in a second migration is how the two copies of
-- the same function drift apart.

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
-- storage.objects already has RLS enabled (Supabase does that) -- this adds
-- policies only. Every policy is scoped to this bucket by name, the same
-- discipline as import-uploads: a policy that forgot the bucket_id clause
-- would grant the same access across every bucket, this one included.

create policy recipe_images_insert on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'recipe-images'
    and is_household_member(storage_path_household(name))
  );

create policy recipe_images_select on storage.objects for select
  to authenticated
  using (
    bucket_id = 'recipe-images'
    and is_household_member(storage_path_household(name))
  );

create policy recipe_images_delete on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'recipe-images'
    and is_household_member(storage_path_household(name))
  );

-- No UPDATE policy, deliberately, same instinct as import-uploads (D46) and
-- ai_usage (D38). Replacing a recipe's photo writes a new object under a new
-- name -- the editor does this in `RecipeEditor.save()` -- and the old object
-- is deleted afterwards rather than overwritten in place.
