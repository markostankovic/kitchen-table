## D46 — The `import-uploads` bucket, where the path is the access control

**Decided.** One private bucket, 10 MB, images only. Paths are
`import-uploads/{household_id}/{uuid}.jpg`, and every `storage.objects` policy
reads that first segment through `storage_path_household(text)`. Insert, select
and delete are scoped by `is_household_member`. There is no update policy.

**Why private.** A photographed cookbook page is somebody else's copyrighted
prose, and D16 says there is no public path to it.

**Why no update.** An uploaded page is immutable; re-photographing writes a new
object. The same instinct as D38.

**Why a helper function.** `(storage.foldername(name))[1]::uuid` raises on
anything that is not a uuid, and an exception inside a policy is a 500 rather
than a denial — a client could turn a denied upload into a server error by
naming `hello/world.jpg`. The helper swallows the cast failure and returns null,
which `is_household_member` already treats as false.

**Consequence, and a limit on its test.** Supabase refuses direct INSERT and
DELETE on `storage.objects` even for `postgres`, so a SQL test cannot set up the
fixture. `supabase/tests/rls_storage_test.sql` asserts what SQL can see — the
bucket's configuration, the policy set, and every branch of the helper — and
says in its header that the policies themselves are exercised against the real
Storage API instead.

D35 still stands for the recipe's own picture: the photograph of a page is an
*input* to an import, not a picture of the dish, and `recipes.image_path`
remains Phase 2's business.
