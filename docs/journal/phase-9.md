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

### Slice C, part 1 — The list of your households (`phase9-household-list`)

**Status: complete** (`31b685d`). Decisions taken during it: D170.

The first slice of Slice C's design round,
`docs/design/handoffs/2026-10-13-multiple-households/` (§ D2). Planned with
`/plan-slice`, built, walked on the Galaxy and closed on 2026-10-13. With
one household nothing changes. No package, no migration, 7 new l10n keys.

- **Data.** New pure `HouseholdMembership` (`household`, `role`,
  `memberCount`; freezed, no `fromJson`). `RemoteHouseholdDataSource
  .fetchMembershipRows(userId)` reads the caller's `household_members` rows
  in join order with `households!inner(id, name, created_by, deleted_at,
  household_members(user_id))`, filtering `households.deleted_at` in the
  query (D23), retried like `fetchMineRows` (D89). `membershipFromWire`
  reuses `householdFromWire`; the role mapping moved into
  `householdRoleFromWire`, shared with `_toMember`.
  `HouseholdRepository.fetchMemberships(userId:)`; `fetchMine` and
  `fetchCurrent` untouched.
- **Providers.** `myHouseholdsProvider` returns memberships (still watching
  `currentHouseholdProvider` to refresh). New `householdByIdProvider(id)`.
  `householdMembersProvider` and `liveInvitesProvider` became families
  keyed by id. `currentHouseholdSummaryProvider`'s record grew `id` and
  `otherHouseholdCount` (D52; 0 on `AppFailure`). `AppShell._refreshBranch`
  also invalidates `myHouseholdsProvider` for Settings (D149).
- **Routes.** `HouseholdsRoute` (`/settings/households`) and
  `HouseholdRoute(householdId)` (`/settings/household/:householdId`),
  siblings under Settings.
- **Screens.**
  - Settings: with 0 others exactly as before, opening the household by
    `go`. With more, the header is `Domaćinstva`, the subtitle
    `2 člana · još N domaćinstva`, and the row opens the list.
    `_HouseholdRow` takes a finished subtitle and is inert until the summary
    arrives.
  - `HouseholdsScreen`: intro line, one card of `HouseholdRow`s, dividers
    inset 56. A tap calls `switchTo` (every row inert while it runs; the
    current row always); the gear `push`es that household's screen.
  - `HouseholdRow` (feature-private, `onManage`-less mode for the switcher):
    radio, name wrapping with no ellipsis, meta, a `splitDivider` (new
    `AppSizes`, 32) hairline and a 48 gear.
  - `HouseholdScreen(householdId)`: every read keyed by the id. Rename
    awaits `myHouseholdsProvider`. Leave/delete land on onboarding,
    `/settings` (was current) or `/settings/households`.
- **DESIGN_SYSTEM.md**: § Size and motion (`splitDivider`), § Settings (the
  two-household row), § Household (id-scoped screen, the households list).
- **Tests:** `households_screen_test` (order, one checked radio, sr meta
  `2 člana · Član` / `1 član · Vlasnik`, the long name whole at 360, tap
  switches, current tap does nothing, gear tooltip and navigation);
  `settings_screen_test` (new; 0 and 1 others); `household_dto_test` (new;
  role, count, nested `deleted_at`); `household_screen_test` now on a
  `GoRouter` with three new cases (leave current → `/settings`, leave
  non-current → list, not-yours → `noHouseholdYet`);
  `current_household_switch_test` (memberships, `householdByIdProvider`);
  `app_shell_test` family overrides.

**Differs from the plan.**
- **`_isCurrent` reads `currentHouseholdProvider`, not
  `currentHouseholdIdProvider`.** Nothing on the screen watches the id
  provider, so a cold `ref.read` returned loading and every leave counted as
  non-current. The new test caught it.
- **`postgrest-dart`'s `.order()` is descending by default.** The local
  curl check of the new query looked right (raw PostgREST is ascending);
  the device showed the list newest-first. Fixed with `ascending: true`.
  The same default had made `fetchMineRows` (D169's "oldest" fallback) pick
  the **newest** household and `fetchMembers` list newest-first; both fixed
  in this slice at Marko's call (D170 #6). The other two bare `.order()`s
  are harmless: recipe lines are re-sorted client-side, units by `code`.
- `HouseholdRoute` takes the id positionally, on `RecipeDetailRoute`'s
  precedent.

**How it was verified.**
- `dart analyze` and `check_layers` clean; `flutter test` **1063/1063**;
  Deno 172/172; `make test-sql` all green; `make check` green except the
  known `seed-check`. `make l10n-check` only differed by the uncommitted
  regeneration (re-running `gen-l10n` was byte-identical).
- **The membership query on the local stack** (`supabase db reset`, two
  users via the admin API, three households, one soft-deleted with the
  membership left in place): curl with the user's JWT returned join order
  (the older household, joined last, came last), both co-members in the
  nested embed under RLS, and no soft-deleted row.
- **Hosted.** Slice B's migration `20261013120000` turned out **not to be
  on hosted** (`migration list --linked`): Marko's earlier push had stopped
  at its Y/n prompt. Pushed during the walk with `supabase db push --yes`
  and confirmed. Until then every leave, delete and remove-member from the
  slice-B build failed. Marko seeded two households by hand for the walk
  account: `Porodica Stanković – vikendica` (owner) and `Kod Mire` (adult,
  owned by `test-user`).
- **Walk** (`/design-walk settings-households`, Galaxy SM-S931B, 480 dpi,
  hosted release build, installed with `adb -d` since the emulator was
  attached; all four combinations):
  - one household (before the seed): `Domaćinstvo`, `Renamed Household ·
    2 člana`, opens the Household screen, Back to Settings;
  - three households: `Domaćinstva`, `2 člana · još 2 domaćinstva` (en `2
    members · 2 more households`); the long name wraps in the Settings row
    and the list;
  - the list in join order (after the fix), radio `#366A35` on the current
    row, hairline exactly 96px = 32dp, `#494A3F` on `#292923` in dark,
    gears aligned, dividers starting under the names;
  - a tap switched (radio moved), and Recipes followed: 9 recipes for
    Renamed Household, the empty state for Kod Mire;
  - each gear opened that household with the right role: Delete for an
    owner household, Leave for Kod Mire; Back returned to the list;
  - leaving the non-current Kod Mire through its gear landed on the list
    one row shorter, and Settings then read `1 more household`;
  - after the `fetchMembers` fix, Renamed Household lists its owner above
    `test-user`.

  Not walked: the fallback for a device with no saved selection (the Galaxy
  has one), and the offline `otherHouseholdCount → 0` path. Left on hosted:
  the walk account in Renamed Household (current) and vikendica; Kod Mire
  with `test-user` alone. App restored to English/Light.

### Slice C, part 2 — The household switcher (`phase9-household-switcher`)

**Status: complete** (`7dd0d1c`). Decisions taken during it: D171.

Slice 2 of 6 of the design round
`docs/design/handoffs/2026-10-13-multiple-households/` (§ D1 b, D3·1,
D3·3). Planned with `/plan-slice-ui`, built, walked on the Galaxy and closed
on 2026-10-13. With one household, while it isn't known, or offline,
nothing renders differently. No package, no migration, 3 new l10n keys.

- **Header.** New `HouseholdTabTitle` (`core/household/widgets/`) on
  Recipes, Plan and List, each bar setting `titleSpacing: AppSpacing.sm`.
  With 2+ households: a 56 block (`appBar − 2·xs`), radius `md`, padded
  `sm`, the title in the bar's `titleLarge` over the name in `bodyMedium`
  `onSurfaceVariant` (one line, ellipsized) and `expand_more` at
  `iconInButton`. Otherwise the plain title, at x 16 either way. Inert
  while a switch is in flight.
- **Condition.** `householdSwitcherName` in `current_household.dart`, the
  second narrow exception after D52's summary record: the name, or null
  with one household, unknown, or on an `AppFailure` from the
  network-only `myHouseholds`. It reads no members.
- **Sheet.** `showHouseholdSwitchSheet` returns a sealed
  `HouseholdSwitchPick` (`SwitchToHousehold(id, name)` /
  `ManageHouseholds()`) and writes nothing. It is the theme sheet like Add
  meal: drag handle, `titleMedium` title, gearless `HouseholdRow`s in join
  order with no hairlines, a full-width divider, then Manage households
  (`settings_outlined`, `bodyLarge`, `chevron_right`). The caller switches
  through `CurrentHousehold.switchTo` (D169), shows `Now in X.` /
  `Sada ste u domaćinstvu „X“.` with Undo (captured notifier and
  messenger, so it works after the tab rebuilds), or `go`es to
  `HouseholdsRoute`.
- **Shell.** `AppShell` is a `ConsumerStatefulWidget` with a `_stale` set.
  When `currentHouseholdIdProvider`'s `.value` changes between two
  non-null ids, every branch but the current one is marked, and arriving
  on a marked branch passes `goBranch(initialLocation: true)`. That covers
  a switch from the sheet and from the Households list. This closes
  STATE's "a household detail screen survives a switch".
- **Promotion.** `HouseholdRow` `git mv`'d to `core/household/widgets/`
  (only its doc and imports changed). The role `switch` moved to
  `core/household/household_role_label.dart`, shared with
  `households_screen.dart`.
- **DESIGN_SYSTEM.md**: § Navigation (the household line), § Household
  (`HouseholdRow`'s home, the switch sheet), § Menu, snackbar, banner
  (`Now in X.`), § The shared widgets (three rows), § Size and motion (the
  56 is derived).
- **Tests:** `household_tab_title_test` (new, 9: one household plain at x
  16 with no `InkWell`; offline → plain; two → name and ▾; the title keeps
  `titleLarge`; the long name ellipsized at 360 with two actions; the sheet's
  rows, one checked radio, no gear, Manage; a switch closes and shows the
  snackbar with `persist: false`; Undo switches back; Manage lands on the
  route). `app_shell_test` +2: a household change while on Plan sends
  Settings › Household back to Settings; with no change the stack is kept.
  The first fails with the shell fix taken out.

**Differs from the plan.**
- **Undo's previous id reads `currentHouseholdProvider`, not
  `currentHouseholdIdProvider`.** Nothing had read the id provider yet in
  the test, so it was still loading and Undo had no id. This is the same
  cold-`read` trap as D170's `_isCurrent`. With no id, the snackbar shows
  without Undo.
- **The shell drops a branch from `_stale` whenever it becomes current**,
  including by `go` (Manage households), and the tap handler removes
  before checking `reTap`. Otherwise Settings would reset on a later visit
  for no reason.
- **Found on the walk, fixed and re-walked:**
  - the 2+ title rendered in `bodyMedium`. The plan's
    `Material(type: transparency)` resets `DefaultTextStyle` for its
    subtree, so the title now takes `DefaultTextStyle.of(context)` from
    above it. A test pins the rendered size and weight and fails without
    the fix;
  - `Now in X.` never went away. A `SnackBar` with an action persists by
    default in this Flutter, and it sat over the next sheet's Manage row.
    It is now `persist: false`, as D152 does.

**How it was verified.**
- `dart analyze` and `check_layers` clean. `flutter test` **1074/1074**.
  Deno 172/172. `make test-sql` green. `make check` green except the known
  `seed-check`. `l10n-check` passes once committed.
- **Walk** (`/design-walk tab-household-switcher`, Galaxy SM-S931B, hosted
  release build installed with `adb -s`, the emulator also attached), all
  four combinations, sr/light → sr/dark → en/dark → en/light, re-walked
  after each fix:
  - Recipes, Plan and List each show `Renamed Household ▾`, and each
    opens the sheet;
  - the sheet in both brightnesses: green radio on the current row, muted
    meta readable in dark, no gear;
  - a switch to `Porodica Stanković – vikendica` closed the sheet and
    showed the two-line Serbian snackbar with „ “ quotes, and the tab
    re-keyed (List: no list yet; Recipes: empty state);
  - `Poništi` went back with no second snackbar;
  - Manage landed on Settings › Domaćinstva, and a switch there showed no
    snackbar;
  - a recipe detail left open on Recipes was gone after a switch from
    List's sheet and after one from the Domaćinstva list: Recipes opened
    at its root in the new household. Settings, left on the list, came
    back at its root after a sheet switch;
  - airplane mode with a cold start: the plain `Recepti`, at the same size,
    weight and x as Settings' untouched title.

  Not reached:
  - the long name beside List's **two** actions. vikendica has no list,
    so no actions; in Renamed Household the name line ends at 738 px and
    the actions start at 792 px. The 360-wide widget test has both
    actions;
  - a real one-household account. `test-user` on the emulator now shows
    the household line, so it is in more than `Kod Mire`. The offline
    fallback runs the same code path and was compared instead.

  Left on hosted as found. App restored to Srpski / Svetla / Renamed
  Household, airplane mode off. Noticed, not this slice: in dark the
  recipe list's empty-state second line renders large and bold.

### Slice C, part 3 — Between a switch and its data (`phase9-household-switch-loading`)

**Status: complete** (`d95724b`). Decisions taken during it: D172.

Slice 3 of 6 of the design round
`docs/design/handoffs/2026-10-13-multiple-households/` (§ D3·2). Planned
with `/plan-slice-ui`, built, walked on the emulator (and the Galaxy) and
closed on 2026-10-13. Only a switch shows the new state; with one
household, nothing renders differently. No package, no migration, no l10n
key.

- **The signal.** `HouseholdSwitchInFlight` (keepAlive, the target id) in
  `household_providers.dart`. `CurrentHousehold.switchTo` sets it before
  `select` and clears it in a `finally`, so a failed switch clears it too.
  `core/household/current_household.dart` exposes it as two narrow facts,
  `householdSwitchPending` and `householdSwitchTargetName` (from
  `myHouseholds`' still-held `.value`).
- **Header.** `HouseholdTabTitle` shows the target name at once and is
  inert while pending, which replaces its local `_switching`, so Undo and
  the Households list's switch make it inert too. It holds that name until
  `householdSwitcherName` stops loading. Otherwise the old name flashed back
  while `myHouseholds` re-fetched after `switchTo` returned.
- **Gate.** New `HouseholdSwitchGate` (`core/household/widgets/`) wraps each
  tab's whole `Scaffold`, so app-bar actions see it. `awaiting` turns on
  when pending rises and off once pending is false and the tab's own
  `isLoading` is false, checked on both edges.
- **Placeholder.** New `HouseholdSwitchPlaceholder`: one theme card padded
  `lg`, six `AppRadii.xs` bars in `surfaceContainerHighest` (12/16 high,
  `lg` apart, fractional widths, four with a 0.12 amount bar), wrapped in
  `ExcludeSemantics`. Also `HouseholdSwitchProgressBar`, the 4dp
  indeterminate `primary` bar on a `surfaceContainerHighest` track, first
  in the body.
- **Tabs.**
  - Recipes: `+` disabled, `_FilterRow` not built, placeholder for
    `recipes.when`. A switch clears `_tag`.
  - Plan: segments and week bar stay, the 2dp bar is suppressed.
  - List: Copy and Regenerate render disabled whatever `list.value` is, the
    2dp bar is suppressed, `_RangeBar` stays, and `skipLoadingOnReload`
    stays for regenerate.

  This fixed List showing the **old household's list**, with both buttons
  live, through the switch's reload, and Recipes' tag chips leaking the same
  way.
- **DESIGN_SYSTEM.md**: § Navigation (the household line during a switch),
  § Household (new "Between a switch and its data."), § The shared widgets
  (two rows).
- **Tests:**
  - `current_household_switch_test` +2: set before `select`, null after
    success and after an `AppFailure`.
  - `household_tab_title_test` +3: the target name with no frame of the old
    name while `myHouseholds` is held, which fails with the hold removed;
    Undo inert; a failed switch goes back.
  - `household_switch_gate_test` (new, 4): no switch; on from start through
    the data still loading; data that beats the switch waits; a failed
    switch turns it off.
  - The three tab suites, +7: the placeholder and 4dp bar, no old content,
    disabled controls, then the new data; one household keeps the
    spinner / 2dp bar; a switch clears Recipes' tag.
  - New helper `test/helpers/household_switch_harness.dart`
    (`HeldHouseholdRepository`, `householdSwitchOverrides`).

**Differs from the plan.**
- **A derived provider sees only what lasts until a frame.**
  `householdSwitchPending` is recomputed on the frame, so a switch that
  starts and finishes within one frame is never pending. A real one is
  network-first with Drift writes either side, so it always spans frames.
  The in-memory fakes don't, which is why the widget tests hold
  `fetchCurrent` with a `Completer` (D172 Consequences).
- **A tab first built mid-switch starts awaiting**: the gate's initial
  state reads `householdSwitchPending`.
- Tests that call `switchTo` directly listen to `currentUserIdProvider`.
  In the app the header keeps it alive; without it `switchTo` returns early.
- `dart format` churn outside the touched regions was reverted (the repo
  isn't format-clean).

**How it was verified.**
- `dart analyze` clean, `flutter test` **1090/1090**, Deno 172/172,
  `make test-sql` and `l10n-check` green. `make check` green except the
  known `seed-check`.
- **Walk** (`/design-walk tab-household-switch-loading`), hosted release
  build installed by serial on both devices:
  - **The Galaxy** (walk account) switches in under 0.3 s, too fast to
    screenshot the in-between. It showed the end state only: Renamed's
    recipes with nothing of vikendica, and the long Serbian name on one
    line.
  - **The emulator** (`test-user`, Renamed Household / Kod Mire) was
    slowed with `adb emu network delay gprs` / `speed gsm|gprs` and
    captured in `exec-out screencap` bursts, all four combinations
    (sr/light → sr/dark → en/light → en/dark):
    - switching from each of Recipes, Plan and List, the new name was in the
      header from the first frame. The 4dp bar sat flush under the app bar,
      the frame stayed and the flat card showed;
    - Recipes' `+` and List's Copy / Regenerate were visibly disabled, and
      Plan showed no 2dp bar;
    - no old-household content appeared in any frame;
    - Kod Mire's empty states replaced the placeholder, which did not
      linger;
    - in dark, the track and the placeholder bars read on the card;
    - Undo gave the same state back;
    - a switch from Settings › Households put List and Plan into the
      placeholder, then the new data;
    - offline cold start (the one-household stand-in): plain title,
      Recipes' spinner, no placeholder or 4dp bar anywhere.
  - Restored: emulator Srpski / Svetla / Renamed, network normal; Galaxy
    English / Light / vikendica.
  - Noticed, not this slice:
    - the switch sheet's rows turn into a small spinner as it closes
      (`myHouseholds` reloading under it);
    - List's "Next list: …" line is absent while awaiting and then
      appears, nudging the card down a line;
    - an offline cold start came up Serbian with the profile on English;
    - the first `_ListBody` of a session waits on the unit catalog with its
      own spinner.
