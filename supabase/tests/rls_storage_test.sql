-- Test: the import-uploads bucket and the helper its policies stand on
-- (Phase 1d, D46).
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
-- -- the bucket's configuration and the policy set -- plus every branch of
-- `storage_path_household`, which is the pure function the policies delegate
-- their whole decision to. The policies themselves are exercised against the
-- real Storage API, which is the only way they can be, and the commit that
-- adds them records that run.
--
-- Run: make test-sql

do $$
declare
  r         record;
  got       uuid;
  n         int;
  failures  int := 0;
begin
  ---------------------------------------------------------------------------
  -- The bucket
  ---------------------------------------------------------------------------
  select public, file_size_limit, allowed_mime_types into r
    from storage.buckets where id = 'import-uploads';

  if not found then
    failures := failures + 1;
    raise warning 'the import-uploads bucket does not exist';
  else
    -- Private, because a cookbook page is somebody else's copyrighted prose
    -- and D16 says there is no public path to it.
    if r.public then
      failures := failures + 1;
      raise warning 'the import-uploads bucket is PUBLIC (D16)';
    end if;

    if r.file_size_limit is null or r.file_size_limit > 10485760 then
      failures := failures + 1;
      raise warning 'file_size_limit is %, expected at most 10 MB',
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
  -- storage_path_household -- every branch
  ---------------------------------------------------------------------------
  select storage_path_household(
    '11111111-1111-1111-1111-111111111111/page.jpg') into got;
  if got <> '11111111-1111-1111-1111-111111111111'::uuid then
    failures := failures + 1;
    raise warning 'the household prefix was not read: %', got;
  end if;

  -- Nested paths still key on the FIRST segment, because that is the one the
  -- policies check and the only one that means anything.
  select storage_path_household(
    '11111111-1111-1111-1111-111111111111/2026/page.jpg') into got;
  if got <> '11111111-1111-1111-1111-111111111111'::uuid then
    failures := failures + 1;
    raise warning 'a nested path did not key on the first segment: %', got;
  end if;

  -- The three shapes that would RAISE from a bare ::uuid cast. A policy that
  -- raises answers 500 instead of denying, which is the entire reason this
  -- function exists rather than the cast being written inline.
  select storage_path_household('not-a-uuid/page.jpg') into got;
  if got is not null then
    failures := failures + 1;
    raise warning 'a malformed prefix produced % rather than null', got;
  end if;

  select storage_path_household('page.jpg') into got;
  if got is not null then
    failures := failures + 1;
    raise warning 'a path with no folder produced % rather than null', got;
  end if;

  select storage_path_household('') into got;
  if got is not null then
    failures := failures + 1;
    raise warning 'an empty path produced % rather than null', got;
  end if;

  -- And the reason null is safe to return.
  if is_household_member(null) then
    failures := failures + 1;
    raise warning 'is_household_member(null) is true; the policies are open';
  end if;

  ---------------------------------------------------------------------------
  -- The policy set
  ---------------------------------------------------------------------------
  -- RLS has to be on, or every policy below is decoration. Supabase enables it
  -- on storage.objects; this asserts that rather than assuming it stays true.
  select c.relrowsecurity into r
    from pg_class c join pg_namespace ns on ns.oid = c.relnamespace
   where ns.nspname = 'storage' and c.relname = 'objects';
  if not r.relrowsecurity then
    failures := failures + 1;
    raise warning 'RLS is OFF on storage.objects';
  end if;

  select count(*) into n from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname in ('import_uploads_insert', 'import_uploads_select',
                        'import_uploads_delete');
  if n <> 3 then
    failures := failures + 1;
    raise warning 'expected 3 import_uploads policies, found %', n;
  end if;

  -- No UPDATE policy, deliberately: an uploaded page is immutable, and
  -- re-photographing writes a new object rather than editing this one.
  select count(*) into n from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname like 'import_uploads_%' and cmd = 'UPDATE';
  if n <> 0 then
    failures := failures + 1;
    raise warning 'an UPDATE policy appeared on import-uploads';
  end if;

  -- Every policy must name the bucket. One that forgot would grant the same
  -- access across every bucket added later, including Phase 2's recipe images.
  select count(*) into n from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname like 'import_uploads_%'
     and coalesce(qual, '') || coalesce(with_check, '') not like '%import-uploads%';
  if n <> 0 then
    failures := failures + 1;
    raise warning '% import_uploads policy(ies) do not scope to the bucket', n;
  end if;

  -- And every policy must actually consult membership.
  select count(*) into n from pg_policies
   where schemaname = 'storage' and tablename = 'objects'
     and policyname like 'import_uploads_%'
     and coalesce(qual, '') || coalesce(with_check, '')
         not like '%is_household_member%';
  if n <> 0 then
    failures := failures + 1;
    raise warning '% import_uploads policy(ies) do not check membership', n;
  end if;

  if failures > 0 then
    raise exception '% import-uploads assertion(s) failed', failures;
  end if;
  raise notice 'import-uploads bucket and path helper: all assertions passed';
end
$$;
