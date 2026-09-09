-- Test: the recipe-images bucket (Phase 2, part 1, D48).
--
-- WHAT THIS FILE DOES NOT DO, and why.
--
-- Supabase installs a trigger that refuses direct INSERT and DELETE on
-- storage.objects -- "Direct deletion from storage tables is not allowed. Use
-- the Storage API instead" -- even for `postgres`. So a SQL test cannot upload
-- an object into one household's prefix and try to read it as another; the
-- platform will not let it set the fixture up.
--
-- Rather than pretend otherwise, this file asserts the two things SQL CAN see
-- -- the bucket's configuration and the policy set. `storage_path_household`
-- is not re-asserted here: it is shared with import-uploads and every branch
-- of it is already covered by rls_storage_test.sql, and a second copy of that
-- coverage would just be two tests that can only ever agree or both be wrong
-- together. The policies themselves are exercised against the real Storage
-- API, which is the only way they can be, and the commit that adds them
-- records that run.
--
-- Run: make test-sql

do $$
declare
  r         record;
  n         int;
  failures  int := 0;
begin
  ---------------------------------------------------------------------------
  -- The bucket
  ---------------------------------------------------------------------------
  select public, file_size_limit, allowed_mime_types into r
    from storage.buckets where id = 'recipe-images';

  if not found then
    failures := failures + 1;
    raise warning 'the recipe-images bucket does not exist';
  else
    -- Private, because the bucket also holds photos attached to ocr and
    -- url_import recipes, which D16 makes permanently household-scoped, and
    -- D48 chose signed URLs over a public bucket for that reason.
    if r.public then
      failures := failures + 1;
      raise warning 'the recipe-images bucket is PUBLIC (D48)';
    end if;

    if r.file_size_limit is null or r.file_size_limit > 5242880 then
      failures := failures + 1;
      raise warning 'file_size_limit is %, expected at most 5 MB',
        r.file_size_limit;
    end if;

    -- An allowed_mime_types of null means "anything", which in a bucket the
    -- client uploads to means a PDF or a video lands where a photo was meant.
    if r.allowed_mime_types is null
       or not ('image/jpeg' = any(r.allowed_mime_types)) then
      failures := failures + 1;
      raise warning 'allowed_mime_types does not restrict to images: %',
        r.allowed_mime_types;
    end if;
  end if;

  ---------------------------------------------------------------------------
  -- The policy set
  ---------------------------------------------------------------------------
  -- RLS is already asserted ON for storage.objects by rls_storage_test.sql --
  -- it is a table-level setting, not a per-bucket one, so re-checking it here
  -- would just be the same fact under a second name.

  select count(*) into n from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname in ('recipe_images_insert', 'recipe_images_select',
                        'recipe_images_delete');
  if n <> 3 then
    failures := failures + 1;
    raise warning 'expected 3 recipe_images policies, found %', n;
  end if;

  -- No UPDATE policy, deliberately: replacing a recipe's photo writes a new
  -- object under a new name (RecipeEditor.save()), rather than editing this
  -- one in place.
  select count(*) into n from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname like 'recipe_images_%' and cmd = 'UPDATE';
  if n <> 0 then
    failures := failures + 1;
    raise warning 'an UPDATE policy appeared on recipe-images';
  end if;

  -- Every policy must name the bucket. One that forgot would grant the same
  -- access across every bucket, import-uploads included.
  select count(*) into n from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname like 'recipe_images_%'
     and coalesce(qual, '') || coalesce(with_check, '') not like '%recipe-images%';
  if n <> 0 then
    failures := failures + 1;
    raise warning '% recipe_images policy(ies) do not scope to the bucket', n;
  end if;

  -- And every policy must actually consult membership through the shared
  -- helper, not reimplement the household check.
  select count(*) into n from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname like 'recipe_images_%'
     and coalesce(qual, '') || coalesce(with_check, '')
         not like '%is_household_member(storage_path_household%';
  if n <> 0 then
    failures := failures + 1;
    raise warning '% recipe_images policy(ies) do not check membership via '
      'storage_path_household', n;
  end if;

  if failures > 0 then
    raise exception '% recipe-images assertion(s) failed', failures;
  end if;
  raise notice 'recipe-images bucket: all assertions passed';
end
$$;
