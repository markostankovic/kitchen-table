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

### Slice B — Client selection and switching

**Status: complete** (`48728cf`). Decisions taken during it: D169.

The second of three slices. It ends every remaining "oldest membership
wins" pick and gives the client a real, remembered choice. Planned with
`/plan-slice`, then built, deployed, walked on the Galaxy and closed on
2026-10-13. With one household nothing changes for the user. Nothing in the
app can reach Join while you're already in a household until slice C, so
the second-household paths are proved by tests, not on the device. One
migration, no package, no new l10n key.

- **Client (D169 #1–2).**
  - `device_preferences.dart` gains `selectedHouseholdKey(userId)` →
    `'selected_household.<userId>'`.
  - `HouseholdRepository` takes a `DevicePreferenceStore` as a third
    dependency. `fetchCurrent` picks the row whose `id` matches the
    selection, else `rows.first`, and writes that row through, as before
    (D88). The new `select(userId:, householdId:)` writes the preference,
    then `_local.clearCurrent(userId)`, so an offline switch errors rather
    than serving the old household.
  - `redeemInvite` returns the joined id, which the function already sent.
    `removeMember`, `leaveHousehold` and `deleteHousehold` take the
    household id and send `target_household`.
  - `currentHousehold` became `class CurrentHousehold`, with the same
    `build()`. The generated name is unchanged, so every `watch`/`.future`
    call site compiled as it was. `switchTo(id)` calls `select`, then
    `invalidateSelf()` and `await future`.
  - New `myHouseholdsProvider` lists every household for slice C. It
    watches `currentHouseholdProvider` so it refreshes after create, join,
    leave, delete or a switch. Nothing reads it yet.
  - Create and join call `switchTo(newId)` in place of invalidate + re-read.
    `HouseholdScreen` passes the shown household's `h.id` to remove, leave
    and delete; `_removeMember` gets it threaded through `_members` →
    `_memberRow` → `_memberTrailing`.
  - `already_in_household` is gone from `supabase_failure.dart`, from
    `FailureCode.inviteAlreadyUsed`'s doc and from the sr ARB description
    (l10n regenerated).
- **SQL (D169 #3).** Migration `20261013120000_household_rpcs_take_a_household.sql`
  drops the zero-argument `remove_household_member(uuid)`,
  `leave_household()` and `delete_household()`. It recreates them as
  `(target_household, target_user)`, `(target_household)` and
  `(target_household)`. Each looks the caller's role up in *that* household
  and raises `'not a member of that household'` (22023, so the client's
  mapping is unchanged). Bodies otherwise copied from migrations 22 and 23.
- **Edge Functions (D169 #4).** `resolveHousehold` and the fallback are
  deleted. `requireHousehold` treats an absent `householdId` as the same
  400 `invalid_household` as a malformed one, so D168 is complete.
  `redeem-invite` drops the `memberOf.size > 0` → 409 block and keeps
  `memberOf` for the idempotent `alreadyMember` paths. Header comments in
  create-invite, translate-tags and `http.ts` no longer describe a fallback.
- **Tests:**
  - `rls_household_test.sql`: every call passes the household. A new
    two-household block puts C as adult of X (the older membership) and
    owner of Y. Non-member E can call none of the three on X.
    `delete_household(X)` by C raises. `leave_household(X)` removes only
    the X row and leaves Y untouched. `delete_household(Y)` stamps only Y
    and keeps the X membership.
  - `rls_invites_test.sql`: `delete_household(hid)`, and the revoke case
    below.
  - `auth_test.ts`: the two legacy cases become "no id is a 400, never a
    fallback". The fake lost its `order`/`limit`.
  - `household_repository_offline_test`: selected wins and is cached; no
    selection → oldest; stale selection → oldest; one user's selection
    doesn't steer another; `select` stores and is read back; `select`
    clears the cache so a following offline read rethrows; `redeemInvite`
    returns the id; leave/delete forward the id.
  - `current_household_switch_test` (new): oldest by default,
    `switchTo('weekend')` makes `currentHouseholdIdProvider` yield it, and
    `myHouseholdsProvider` lists both and picks up a joined one.
  - `onboarding_screens_test`: create and join end on the new id (an
    existing household present, so only a real switch passes).
    `household_screen_test`: the shown id reaches remove, leave and delete.
  - Two helpers in `test/helpers/`: `FixedCurrentHousehold` (a
    notifier can't take the old `(Ref ref) async =>` override) and
    `FakeHouseholdRepository` (an in-memory two-household repository).

**Differs from the plan.**
- **`revoke_invite` had the same lookup** and the slice didn't list it.
  With a second membership, revoking a code from your newer household would
  have been refused. The same migration `create or replace`s it with an
  unchanged signature, checking membership of the invite's own household
  (one `'no such invite'` message for both misses, as before).
  `rls_invites_test.sql` now has D (owner of hid2, older) join hid as an
  adult and revoke hid's code.
- **An unlistened provider is paused (Riverpod 3).** In the onboarding
  widget tests `switchTo` read `currentUserIdProvider` as still loading and
  silently did nothing. Awaiting `.future` instead hung, for the same
  reason. The app is unaffected, because the router always listens to
  `currentHouseholdProvider`. The slice's `.value` read stays, and the test
  listens the way the router does (`listenLikeTheRouter`).
- `recipe_editor.g.dart`'s hash changed on regeneration; committed as
  generated output.

**How it was verified.**
- `dart analyze` is clean, `check_layers` passes, and `flutter test` passes
  **1046/1046**. The Deno function tests pass 172/172, and
  `lint-functions` is clean. `make check` is green except the known
  `seed-check`. `make test-sql` passes all 20 files, and `make l10n-check`
  passes once the regenerated file was committed.
- `resolveHousehold` appears nowhere in `supabase/functions`.
  `already_in_household` appears nowhere in `lib`, `test` or
  `supabase/functions`. `order by created_at` doesn't appear in the new
  migration.
- **Deployed.** Marko confirmed only the Galaxy has the app and that it
  would get the new APK at once. The session's `db push` was refused by
  the permission check, after a `--dry-run` that listed only
  `20261013120000`. Marko ran `make db-push`, `make functions-deploy` and
  `make install-hosted`. The session confirmed the Galaxy's
  `lastUpdateTime` matched the APK's build minute.
- **Walk, observed from the session** (Galaxy SM-S931B, `ANDROID_SERIAL`
  pinned because the emulator was attached; sr, light; the app's own
  language toggle, restored to English afterwards):
  - a cold start lands on Recipes (9) in "Renamed Household", 2 members;
  - Plan and List load from it (the list generated Oct 12);
  - a paste import made a job that reached review with 3/3 matched, and
    was then discarded (still 9 recipes);
  - Create invite code minted 543613, and Opozovi revoked it ("Kod
    opozvan."), which also exercised the new `revoke_invite` on hosted;
  - after a force-stop and relaunch it was still the same household;
  - logcat showed no Flutter errors and no `invalid_household`,
    `not_a_member` or `22023`.

  Leave, delete and the second-household paths were not walked. They are
  covered by `make test-sql` and the provider tests, and slice C has the UI.
