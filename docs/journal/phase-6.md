# Journal — Phase 6

Verbatim build history for Phase 6 — Tags in two languages, findable by tag, and a household you can edit — moved out of `docs/ROADMAP.md` so the roadmap stays a forward-looking index. Nothing here is authoritative going forward -- see `docs/decisions/` for standing rules, `docs/STATE.md` for current status.

---

## Phase 6 — Tags in two languages, findable by tag, and a household you can edit

### Part 1a — Tags carry a sr/en pair

**Status: complete** (`b22a327`). Decisions taken during it: D107–D108.

Part 1 of the roadmap's own wording turned out to be two slices' worth of
work, split in the planning session on Phase 2 part 6a/6b's precedent: 1a
is the table, its RLS, the cache, the resolution rule and the rendering;
1b -- a dedicated `translate-tags` Edge Function -- is next. A tag typed in
one language now renders in the reader's own language on both the recipe
list's filter chips and the detail screen's chips; a tag with no pair
renders exactly as typed; the editor's tags field always shows exactly
what was typed, translated or not; filtering keeps matching across both
spellings unchanged. Nothing in this slice writes a translation -- pairs
are inserted by hand to verify the read path; minting them is 1b's job.

- **Migration 21, `recipe_tag_names`** -- `ingredient_names`' shape, not
  `recipe_translations`'s (D107): `tag_key` is the normalized *original*
  spelling, exactly `RecipeTag.key`, with a generated `normalized_name`
  column that nothing in 1a reads yet (Part 2's "typing a tag's name
  narrows the list" will need it, and migrations are append-only) and a
  total unique index on `(tag_key, locale, coalesce(household_id, ...))`.
  Three RLS policies land in this one migration -- select (global-or-
  member, `ingredient_names_select` verbatim), insert and update (member-
  owned rows only) -- so 1b's Edge Function costs no second migration for
  its write path.
- **`RecipeTagNameCache`** (Drift schema 6→7) departs from
  `IngredientNameCache`'s watermark-and-delta sync on purpose (D108): one
  household's tag vocabulary is a handful of rows, so
  `LocalRecipeDataSource.replaceTagNames` deletes and reinserts the whole
  cached set per household, `UnitCatalogCache`'s "a fetch replaces the row
  outright" reasoning scaled up from one row to a small set. Wiped on
  sign-out alongside `RecipeCache` and friends, since it is household-
  scoped.
- **`RecipeRepository.fetchTagLabels`** is network-first with a cache
  fallback on `NetworkFailure`, `fetchDetail`'s own shape (D74), not
  `watchList`'s two-emission stream -- this is a single lookup, not a
  sync. `RemoteRecipeDataSource.fetchTagNames` fetches every locale, not
  just the reader's, since the table is tiny and caching both means
  switching language offline still works.
- **`RecipeTag.relabelled`** is a pure static beside `vocabularyOf`, not a
  second signature on it, per the roadmap's own open question: `key` never
  changes, only `label`, so a translated chip still filters exactly like
  the as-typed one did and `RecipeRepository._filtered` needed no change
  at all. The list screen's `_FilterRow` relabels *before* the "selected
  tag fell out of the vocabulary" branch, so a synthesised chip for a
  still-selected but now-missing tag is translated too. The detail
  screen's chips render `recipe.tags` directly (original spellings), so
  the lookup there is per-tag rather than through `relabelled`. The
  editor's comma-joined field is untouched, deliberately -- round-tripping
  a cook's own words through translation would silently rewrite them.

**How it was verified.** `dart run build_runner build -d` then `dart
analyze` -- clean (one incidental fix: a hand-written fake
`RemoteRecipeDataSource` in `recipe_repository_offline_test.dart` needed
the new `fetchTagNames` method stubbed). `make db-reset` then `make
test-sql` -- all green, including the new
`rls_recipe_tag_names_test.sql` (member read/write, non-member denial,
global-row visibility, the unique-index rejection, the `updated_at`
trigger). `flutter test` -- 544 tests, including new pure-domain cases for
`RecipeTag.relabelled` and new widget cases across the list, detail and
edit screens (a translated chip, a tag with no pair falling back to as-
typed, a translated chip still narrowing the list by its unchanged key,
and the edit screen's tags field never relabelling). `make check` ran
green through `test`/`test-functions` before stopping at the pre-existing,
unrelated `seed-check` failure tracked since `c8be2bc` (`docs/STATE.md`);
`test-sql` and `l10n-check`, which that same chain never reached, were
already confirmed green independently above.

Hand-inserting a `Posno`/`Lenten` pair against local and walking the
language switch, and pushing migration 21 to hosted (`make db-push`) for a
device install on the Galaxy S25, were both handed to the user to run by
hand and had not been confirmed back as of this entry.

---

### Part 1b — `translate-tags`, the writer of the pair

**Status: complete** (`a247d1c`). Decisions taken during it: D109.

The writer 1a's read path was built for. Saving a recipe with a tag nobody
has translated yet now results in that tag carrying both spellings shortly
afterward, with no user action beyond the save; a tag already paired costs
no model call on a later save; a translation failure never blocks or rolls
back the save that triggered it. No migration -- migration 21 already
granted `recipe_tag_names` the insert/update RLS this needed, on purpose.

- **`translate-tags/index.ts`** resolves the household from the caller's
  own membership, `create-invite`'s own shape -- no household id in the
  body, so a client can never name a household it might not belong to. It
  reads the household's tag vocabulary through the **caller's** client
  (RLS decides, `translate-recipe`'s own reasoning), groups by
  `normalizeText()` the same way `RecipeTag.vocabularyOf` does in Dart, and
  diffs it against *every* existing `recipe_tag_names` row for the
  household -- deliberately unfiltered by `deleted_at`, since the unique
  index is total and a soft-deleted row still occupies its slot. Nothing to
  do returns before `checkQuota` and before any model call
  (`match-ingredients`'/`translate-recipe`'s own stated property).
- **`_shared/translate_tags.ts`** is `translate.ts`'s counterpart for
  vocabulary: `TRANSLATE_TAGS_SYSTEM_PROMPT`, a pure `alignTags` that
  refuses a reply whose key set isn't exactly the requested one
  (`alignSteps`'s own exact stance -- a plain `Error`, converted to a
  billed `AiFailure` by the caller), and `translateTags` wrapping
  `callStructured` with one call for the whole batch, capped at
  `MAX_TAGS_PER_CALL` (50) so the prompt stays bounded.
- **D109** (this slice): both locales are always requested together per
  tag, and an alive row -- `curated`, `user`, or an earlier `llm` pair --
  is never overwritten; only a missing slot is inserted and only a
  soft-deleted one is revived, as a plain insert or an update-by-id, never
  a PostgREST upsert -- `recipe_tag_names_unique` is an expression index
  (`coalesce(household_id, '000...')`) that no `onConflict` clause can
  match. `RecipeEditor.save()` is the only trigger (`ImportConfirm.
  saveImported` is deliberately left alone -- `features/import/` may not
  reach `RecipeRepository`, and the function diffs the household's whole
  vocabulary anyway, so the next editor save delivers the same pairs at no
  extra cost), and it fires `RecipeRepository.translateTagsBestEffort()`
  unawaited rather than awaited, on `_syncNamesBestEffort`'s
  never-throws/always-logged precedent -- `revision` and `repository` are
  captured into locals before the call so the callback never touches `ref`
  after the editor disposes, bumping `recipesRevisionProvider` only when a
  row was actually written.
- **`tagLabels`** now watches `recipesRevisionProvider` as its first line,
  `RecipeList.build`'s own precedent two providers up -- a pair minted
  after the save that triggered it has no other way to reach the chips
  already on screen.

**How it was verified.** `dart analyze` -- clean. `make lint-functions` --
clean (typecheck, lint, format). `make test-functions` -- 161 passed,
including the new `translate_tags_test.ts` (`alignTags`: exact match sorted
by key, a missing/extra/duplicated key each throw, the empty batch, and a
guard on the prompt's own key-echo and Latin-script sentences). `flutter
test` -- 546 tests, including two new `translateTagsBestEffort` cases (a
successful call returns `true`, a throwing remote returns `false` rather
than propagating). `make test-sql` -- all green (no migration in this
slice, so no schema drift to check). `make check` was not run directly --
it still stops at the pre-existing, unrelated `seed-check` failure tracked
since `c8be2bc` (`docs/STATE.md`); the four checks above were run
individually instead, matching the slice's own acceptance criteria.

Migration 21 was pushed to hosted (`make db-push`), `translate-tags` was
deployed (`supabase functions deploy translate-tags`), and a release build
against hosted was installed on the physical Galaxy S25 (targeted by serial
since the Android emulator was also attached). The manual walk itself --
saving a recipe with a brand-new Serbian tag, confirming the chip relabels
when switching the app's language to English, and confirming a second save
makes no second model call -- was handed to the user to run by hand and had
not been confirmed back as of this entry.

---

### Part 2 — Tags from the search box

**Status: complete** (`d73e34f`). Decisions taken during it: D110–D111.

Typing in the recipe list's search field now finds recipes by tag as well as
by title, case- and diacritic-insensitively, matching any known spelling of
the tag -- the spelling as typed on the recipe, plus every locale's row in
`recipe_tag_names`. Folded in D102's open consequence at the same time: the
Favorites chip is now reachable from a household with no tags at all. One
predicate changed, one visibility rule changed; no SQL, no migration, no new
package -- matching the slice's own scope exactly.

- **`RecipeFilter.apply`** (`lib/features/recipes/domain/recipe_filter.dart`,
  new) is `RecipeRepository._filtered`'s logic extracted to a pure-Dart file,
  `RecipeTag`'s own shape (static helpers over `List<Recipe>`, no Flutter or
  Supabase import). `query` now matches when the normalized title contains
  the term OR any tag does, under its own spelling or any spelling in
  `spellingsByKey` (D110); `tag` and `favoritesOnly` are unchanged --
  whole-token, AND-composed.
- **`RecipeRepository.watchList`** resolves the `tagKey -> {normalized
  spellings}` map once per call, only when `query` is non-empty, from
  `_local.readTagNames` -- local cache only, reusing `fetchTagLabels`'s
  existing `_tagLabelsByLocale` grouping helper via a new `_spellingsByKey`
  wrapper -- and reuses the same map for both the cached and post-sync
  emissions (D67's rule, unchanged: whatever the predicate becomes applies
  identically to both). A cold tag-name cache degrades silently to as-typed
  matching, since `readTagNames` already swallows its own errors.
- **`_FilterRow`** (`recipe_list_screen.dart`) now watches
  `recipeListProvider()` (the unfiltered list) instead of the tag vocabulary
  to decide whether to render, closing D102's own named gap (D111). The
  "filter already selected" clause keeps the row from disappearing under an
  in-flight reload.
- `recipeTagsProvider` was deliberately left untouched, per the slice's own
  settled answer: chips still reflect the unfiltered list, so widening back
  out from a narrowed query is always possible.

**How it was verified.** `dart analyze` -- clean. `flutter test` -- 558
tests (546 before this slice, plus 12 new: eight pure-Dart `RecipeFilter`
cases, two `RecipeRepository.watchList` offline cases against a real
in-memory `AppDatabase` -- a translated-spelling match and a cold-cache
degrade -- and two widget cases on the list screen -- typing a tag narrows
the list, and a tagless household still shows Favorites). One pre-existing
widget test (`a favorited, rated recipe shows a star and the rating`) needed
its finder scoped to the recipe's own `ListTile`, since the now-always-
visible Favorites chip carries a second star icon as its avatar. `make
check` stopped at the same pre-existing, unrelated `seed-check` failure
tracked since `c8be2bc` (`docs/STATE.md`); `dart analyze` and `flutter test`
ran green ahead of it, and nothing in this slice touches SQL or Edge
Functions, so `test-sql`/`test-functions` had nothing new to exercise.

A release build against hosted was installed and launched on the physical
Galaxy device (by serial, since the Android emulator was also attached) in
the same sitting, specifically so 1b's already-minted `posno`/`lenten` pair
would be on hand to demonstrate translated-spelling search. The manual walk
itself -- typing `posno` and `lent` and confirming both find the same
recipe in each app language, confirming a title match and a tag match both
appear together, confirming a chip tap still narrows by whole token, and
confirming the Favorites chip on a tagless household -- was handed to the
user to run by hand and had not been confirmed back as of this entry, so it
joins the other three open device-walk loops rather than closing any of
them.

---

### Part 3a — Rename the household, and who is allowed to

**Status: complete** (`94448b2`). Decisions taken during it: D112.

The household record has been create-only since Phase 1a -- named once at
creation, never touched again. The household screen's name row now carries
a trailing edit icon that opens a dialog with a single text field, wired to
a new narrow `name`-only write; saving invalidates `currentHouseholdProvider`
and re-awaits it so the new name shows without an app restart. No migration:
`households_update`'s RLS already permitted any member to rename, not just
the owner, so this slice only built the client affordance and the RLS
assertion that stance had never actually had (D112).

- **`RemoteHouseholdDataSource.rename`** is a bare
  `.from('households').update({'name': name}).eq('id', id)`, mirroring
  `setFavorite`/`setRating`'s precedent
  (`remote_recipe_datasource.dart:416-430`) rather than the twelve-arg DTO
  shape `docs/ROADMAP.md` part 3a had guessed at -- no `toWire()` was
  needed, and `fetchMineRows`'s column list already included `name`, so the
  confirming re-fetch needed no change either.
- **`HouseholdRepository.rename`** trims the name and delegates, but
  deliberately does *not* `_local.clearAll()` the way `create` and
  `redeemInvite` do (D88) -- there is no household change to guard against
  on a rename, so clearing would only leave a cold cache to rethrow offline
  for no benefit. An offline confirming re-fetch after a successful rename
  serves the old cached name until the next successful read.
- **`HouseholdScreen._rename`** copies `create_household_screen.dart`'s
  `_submit` shape nearly verbatim (trim, validate, invalidate-then-re-await)
  and `recipe_detail_screen.dart`'s dialog shell, swapping the confirmation
  `Text` for a `TextFormField`. A failure surfaces as a `SnackBar`, not the
  screen's existing `_failure` field, which belongs to the invite button and
  renders under it. The dialog's local `TextEditingController` is
  deliberately never disposed, `recipe_picker_sheet.dart`'s own
  `_promptForNote` precedent -- disposing it right after `Navigator.pop()`
  races the dialog's exit animation and throws in widget tests.
- **D112** (this slice): rename stays open to any member, on `create-invite`'s
  own "owner and adult are both trusted adults" stance; owner-only is left
  for 3c, where a destructive action makes the distinction matter. The
  client writes only `name`, even though `households_update` is column-blind
  and would also accept `deleted_at` or `created_by`.

**How it was verified.** `dart analyze` -- clean. `flutter test` -- 564
tests, including two new repository cases (`rename` delegates with a
trimmed name; a `NetworkFailure` propagates rather than falling back to
cache) and a new widget test file (`household_screen_test.dart`: the edit
icon opens the dialog, Save writes the trimmed name and the row shows it, an
empty field is refused and writes nothing, Cancel writes nothing). `make
gen` regenerated `lib/core/l10n/generated/` for the three new ARB keys.
`make test-sql` -- green against a fresh `supabase db reset` (no migration
in this slice), including the new member-level rename assertions in
`rls_household_test.sql` for both an `adult` and the `owner`. `make check`
ran lint, lint-functions, test and test-functions clean before stopping at
the same pre-existing, unrelated `seed-check` failure tracked since
`c8be2bc` (`docs/STATE.md`).

A release build against hosted was installed on the physical Galaxy device
(by serial, alongside the Android emulator) and the manual walk was run and
confirmed in the same sitting -- unlike the four device-walk loops still
open from earlier Phase 6/5 parts, this one does not join them. Tapping the
edit icon opened the dialog pre-filled with the current name; clearing the
field and tapping Save kept the dialog open with "Enter a name." and wrote
nothing; typing a name and tapping Cancel left the row unchanged; typing
"Renamed Household" and tapping Save updated the row immediately (no
restart) and showed the "Household renamed." SnackBar; force-stopping and
relaunching the app confirmed the new name had actually persisted on
hosted, not just echoed locally.

---

### Part 3b — Members and invites

**Status: complete** (`1fcf196`). Decisions taken during it: D113, D114,
D115.

`household_members` and `household_invites` were SELECT-only RLS with no
write policy of any kind (D26) — every row on the household screen past the
copy button was read-only. This slice adds the three writes a household
actually needs: an owner removing another member, any member leaving a
household they don't own, and any member revoking a live invite code. All
three go through new `SECURITY DEFINER` RPCs mirroring `create_household()`;
neither table gained a write policy.

- **Migration 22** (`20260921150000_member_removal_and_invite_revocation.sql`)
  adds `remove_household_member(target_user)`, `leave_household()`, and
  `revoke_invite(invite_id)`, all resolving "the caller's household" with
  the same `order by created_at limit 1` tiebreak
  `resolveHousehold()` in `_shared/auth.ts` uses, cross-referenced in both
  places. None carries a `grant execute` — like `create_household()`, each
  relies on the default PUBLIC grant and guards on `auth.uid() is null`
  instead. `household_invites` gains `revoked_at`/`revoked_by`
  (D114), mirroring `used_at`/`used_by`'s paired-stamp shape exactly, and
  the partial unique index is rebuilt to exclude both dead-row kinds.
- **D113** (this slice): removal is owner-only; leaving is guarded on role
  alone, since the owner can neither be removed nor leave, so the owner row
  always survives and "last member" collapses into "the owner." Closes the
  roadmap's "DELETE policy or an RPC" fork in favour of the RPC. Auditable
  membership revocation (D24's deferred question) stays deferred — removal
  is still a hard delete with no trace; `docs/decisions/OPEN.md` now names
  the likely answer (a log table) for whoever picks it up.
- **D114** (this slice): invite revocation closes D25's named follow-up.
  Revoking releases the code for reuse, on `used_at`'s own precedent, which
  reopens D25's trap deliberately — a revoked row keeps its code, so the
  same six digits can be re-minted for a *different* household while the
  old row still carries it. `redeem-invite`'s peek and claim both needed a
  `revoked_at is null` clause the index rebuild forces; without it a
  revoked row and a live re-mint of the same code both match the peek and
  `.maybeSingle()` throws. `invite_revoked` is a genuinely reachable
  failure (a code can be revoked while someone is reading it), so it's the
  one new refusal in this slice that got a real `FailureCode` and both ARB
  sentences.
- **D115** (this slice): every other RPC refusal (not-owner, can't-remove-
  self, owner-can't-leave, not-a-member, wrong-household) raises plain
  unlocalized prose on purpose. The household screen gates every affordance
  that could trigger one — an owner never sees Leave on their own row, a
  non-owner never sees Remove on anyone else's — so the RPC guards are a
  backstop for a stale list or a second device, not a reachable path. Named
  as its own decision so 3c doesn't have to re-derive the same stance for
  delete.
- **`HouseholdScreen`** gives each member row a role-gated trailing widget
  (own row + adult → leave; own row + owner → nothing, the affordance is
  absent rather than disabled; another member's row + owner → remove;
  otherwise nothing) and each invite row a `Row` of Copy + Revoke. Remove
  and Leave both get a confirm `AlertDialog` first — the roadmap had
  assigned "the first destructive-action copy" to 3c, but it landed here
  instead, and 3c inherits the pattern. Revoke gets no confirm: cheap, and
  undone by minting another code. `_leave` invalidates
  `currentHouseholdProvider` and re-awaits it; the existing router redirect
  (unchanged) sends the now-memberless caller to `CreateHouseholdRoute` with
  no new routing.
- **`HouseholdRepository.leaveHousehold`** calls `_local.clearAll()` after
  the remote call, on `create`/`redeemInvite`'s own D88 precedent — this is
  precisely the case that precedent describes, guarding against a network
  blip on the confirming re-fetch resurrecting the household just left.
  `removeMember`/`revokeInvite` are thin pass-throughs with nothing to
  clear.

**How it was verified.** `dart analyze` — clean. `flutter test` — all
suites green, including two new repository cases
(`household_repository_offline_test.dart`: a successful `leaveHousehold`
clears the cache the way `create`/`redeemInvite` do) and new widget
coverage in `household_screen_test.dart` (owner sees Remove and no Leave;
an adult sees Leave and no Remove; confirming Remove/Leave calls the
repository and shows its SnackBar; cancelling either calls nothing; Revoke
fires immediately with no dialog). `test/core/supabase/supabase_failure_test.dart`
passes with `invite_revoked` mapped. `make gen` regenerated
`lib/core/l10n/generated/` for the new ARB keys and the `HouseholdInvite`
freezed model. `make test-sql` — green against a fresh `supabase db reset`,
with new assertions in `rls_household_test.sql` (an adult cannot remove
anyone; the owner can remove an adult; the owner cannot remove themselves;
the owner cannot leave; an adult can leave; a non-member can call neither)
and `rls_invites_test.sql` (a non-member cannot revoke; a member of a
*different* household cannot revoke this one's code; a member of the
invite's own household can; a revoked code no longer matches
`redeem-invite`'s claim `UPDATE`; the same code can be re-minted for a
different household once revoked — D25's trap, now intended behaviour,
asserted directly). `make check` ran lint, lint-functions, test and
test-functions clean before stopping at the same pre-existing, unrelated
`seed-check` failure tracked since `c8be2bc` (`docs/STATE.md`).

Migration 22 was pushed to hosted and `redeem-invite` redeployed in this
same slice, on `docs/STATE.md`'s own standing note about migration 21
sitting unpushed for a full slice. A release build against hosted was
installed and launched on the physical Galaxy device (by serial) and
verified live in the same sitting: the owner's own row showed no trailing
button, the invite row showed both Copy and the new Revoke button, and
tapping Revoke removed the code from the list immediately (no confirm
dialog, as designed) with the "Code revoked." SnackBar, round-tripping
through the real RPC and the rebuilt index on hosted Postgres. Remove and
Leave were not exercised live — the household being tested against had only
one member (the owner), so neither affordance had a second row to act on;
that needs a second account joined through an invite code first.

---
