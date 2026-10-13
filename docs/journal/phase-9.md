# Journal — Phase 9

Verbatim build history for Phase 9 — Multiple households — kept out of `docs/ROADMAP.md` so the roadmap stays a forward-looking index. Nothing here is authoritative going forward -- see `docs/decisions/` for standing rules, `docs/STATE.md` for current status.

---

## Phase 9 — Multiple households

### Slice A — Edge Functions take an explicit household

**Status: complete** (`2030b66`). Decisions taken during it: D168.

The first of three slices that let one account belong to several
households. The other two are B (client selection and switching, which also
drops `redeem-invite`'s `already_in_household` guard) and C (the UI, from a
Claude Design round briefed in `docs/design/BRIEF_multiple_households.md`).
Planned with `/plan-slice` (handoff committed in `de44431`), then built,
deployed and closed on 2026-10-13. Nothing changes for the user: with one
household per user the behaviour is identical. No migration, no package and
no new l10n key.

- **Server (D168 #1–3).** `_shared/auth.ts` gains `requireHousehold(service,
  userId, body)`:
  - no `householdId` in the body → `resolveHousehold` (the legacy oldest
    membership), or 404 `no_household`;
  - an id that isn't a UUID-shaped string → 400 `invalid_household`;
  - otherwise `assertMember` → `{ householdId, role }`, with a non-member
    getting 403 `not_a_member` and never the fallback.

  `resolveHousehold`'s doc comment now calls it the legacy fallback, to
  delete in slice B. `_shared/http.ts` gains `readOptionalJsonBody`, where
  an empty body reads as `{}`. import-text, import-url and import-photo read
  the body first and call `requireHousehold` in place of `resolveHousehold`.
  import-photo keeps its `prefix !== householdId` check (D46), now against
  the verified id. create-invite and translate-tags use
  `readOptionalJsonBody`, then `requireHousehold`. The header comments that
  gave "the client may not name a household it doesn't belong to" as the
  reason to resolve server-side now say `assertMember` upholds it.
- **Client.**
  - `ImportRepository.createFromText` / `createFromUrl` / `createFromPhoto`
    and `uploadImportPhoto` take `required String householdId`.
    `uploadImportPhoto`'s own `households … order('created_at')` query, a
    copy D52 had missed, is gone.
  - The three import screens read `currentHouseholdIdProvider.future`
    inside their existing `try … on AppFailure`, so a null id goes through
    `failure_l10n` like any other failure. The photo screen reads it once
    and passes it to both the upload and the job.
  - `translateTags(householdId)` / `translateTagsBestEffort(householdId)`.
    `RecipeEditor.save()` passes `saved.source!.householdId`, the saved
    recipe's own household (D107), and the call stays unawaited and
    never-throws (D109).
  - `createInvite(householdId)`: `HouseholdScreen` passes the household it
    shows (`h.id`), not the provider's.
- **Makefile.** `functions-deploy` now lists `translate-tags`, which it had
  been missing.
- **Tests:**
  - `supabase/functions/_shared/auth_test.ts` (new, 8 cases), on a fake
    service client over `household_members`. `requireHousehold`: member,
    non-member 403, malformed 400 (`""`, `"not-a-uuid"`, `42`, `null`),
    no id → oldest membership, no id and no membership → 404.
    `readOptionalJsonBody`: no body or whitespace → `{}`, an object passes
    through, an array or bad JSON → 400.
  - `household_screen_test`: Create invite code sends the shown household.
  - `recipe_repository_offline_test`: the id is forwarded to
    `translateTags`.
  - `supabase_failure_test`: `invalid_household` added to the slug table.

**Differs from the plan.**
- **`invalid_household` needed a client arm.** `supabase_failure_test`
  parses every `HttpError` slug out of `supabase/functions/**` and failed
  on the new one. It maps onto `not_a_member`'s arm (`UnauthorizedFailure`,
  `signInAgain`, server message ignored): a malformed id is a client bug and
  never something the cook did. No new l10n key (D168 #4).
- **No `dart format` on the touched files.** Run over `import_repository.dart`
  it reflowed the whole file, since the repo isn't format-clean. The edits
  were redone by hand so the diff carries only the change.

**How it was verified.**
- `dart analyze` is clean. `flutter test` passes **1035/1035**. The Deno
  function tests pass 173/173, and `lint-functions` (check, lint, fmt) is
  clean. `make check` is green except the known `seed-check`;
  `make test-sql` and `make l10n-check` pass.
- `resolveHousehold` appears only in `auth.ts` (definition and
  `requireHousehold`'s legacy branch). `order('created_at')` no longer
  appears in `lib/features/import`.
- **Deployed** all eight functions to hosted (`cbajkezfhssrvbdbedqt`) with
  `make functions-deploy`.
- **Legacy path, on the device.** Marko confirmed that the build already
  installed on the Galaxy, which sends no `householdId`, still imports
  against the new functions.
- **New build.** The hosted release APK was installed on the physical Galaxy
  (SM-S931B), pinned with `ANDROID_SERIAL` because the emulator was attached
  too. The walk was for paste, URL and photo imports, a new tag getting its
  pair, and an invite code. Marko did it and closed the slice; it was not
  observed from the session.
