# D168 — Edge Functions take an explicit household, checked by membership, with a legacy fallback
**Status:** active
**Touches:** supabase/functions/_shared/auth.ts, supabase/functions/_shared/http.ts, supabase/functions/{import-text,import-url,import-photo,create-invite,translate-tags}/index.ts, lib/features/import/data/import_repository.dart, lib/features/recipes/data/remote_recipe_datasource.dart, lib/features/households/data/remote_household_datasource.dart, lib/core/supabase/supabase_failure.dart

**Decided.** `multi-household-a`, 2026-10-13. The first step to one account
in several households.
1. **The client names the household.** import-text, import-url,
   import-photo, create-invite and translate-tags take `householdId` in the
   body (hand-built camelCase, not Zod). `requireHousehold` checks it with
   `assertMember` before any quota, job row or read keyed on it (D31). A
   non-member gets 403 `not_a_member`, and a non-UUID gets 400
   `invalid_household`.
2. **Legacy fallback, temporary.** A body with *no* `householdId` falls back
   to `resolveHousehold` (the caller's oldest membership), so an APK already
   on a phone keeps working whichever ships first. A body *with* one never
   falls back. Delete `resolveHousehold` and the fallback in slice B.
   **Removed in `multi-household-b` (D169 #4):** no id is now a 400
   `invalid_household`, and `resolveHousehold` is gone.
3. **Which id the client sends.** Imports send `currentHouseholdIdProvider`
   (D52). Tag translation sends the saved recipe's own `householdId` (D107).
   Create-invite sends the household the screen shows. The photo screen
   reads the id once, for both the upload prefix (D46) and the job.
4. **`invalid_household` maps onto `not_a_member`'s arm**
   (`UnauthorizedFailure`, `signInAgain`, server message ignored). It only
   comes from a client bug.

**Why.**
- Once a user can be in two households, "oldest membership wins" picks the
  wrong one for half of them. Only the client knows which one is being
  looked at.
- "The client may not name a household it doesn't belong to" was the reason
  for resolving server-side. `assertMember` upholds that just as well, and
  `loadJobForCaller` already trusted it for job ids.
- Functions deploy to hosted at once, but phones update when someone
  installs an APK. Without the fallback, the deploy would break every
  installed build.

**Rejected.**
- A per-user "selected household" column read server-side: a second source
  of "which household" next to the client's, and two devices on one account
  would fight over it.
- Requiring the id immediately: it breaks installed builds until they are
  replaced.
- Validating the id with Zod / `make types`: these bodies are hand-built
  everywhere else (`ImportRepository`), and one string isn't a schema.

**Consequences.** Until slice B (now shipped, D169), a function's household
could come from two places. Any new household-scoped function should call `requireHousehold`,
never `resolveHousehold`.
