# State — 2026-09-21

**Branch:** `main`
**Last shipped:** Phase 6 part 2 (`d73e34f`) — tags from the search box.
Typing in the recipe list's search field now finds recipes by tag as well as
by title, case- and diacritic-insensitively, matching any known spelling of
the tag — the spelling on the recipe, plus every locale's row in
`recipe_tag_names`. `RecipeFilter.apply` is the predicate, extracted from
`RecipeRepository._filtered` into a new pure-Dart file so it's unit-testable
without a database; `watchList` resolves the spelling map once per call (only
when `query` is non-empty) from the local tag-name cache and reuses it for
both emissions, degrading silently to as-typed matching on a cold cache. Also
folds in D102's open consequence: `_FilterRow` now renders whenever the
household has any recipe at all, not only when the tag vocabulary is
non-empty, so the Favorites chip is reachable from a household with zero
tags. No migration, no Edge Function, no ARB change. Verified with `dart
analyze` (clean) and `flutter test` (558 passed, 12 new) — `make check`
stopped at the same pre-existing `seed-check` failure noted below, with
nothing else in this slice touching SQL or Edge Functions. A release build
was installed and launched on the physical Galaxy device, timed to land
alongside 1b's already-minted `posno`/`lenten` pair — but the manual walk
itself (typing `posno`/`lent` in each app language, a title-and-tag query
together, a chip tap staying whole-token, Favorites on a tagless household)
was handed to the user to run by hand and had not been confirmed back as of
this entry.
**In flight:** none
**Next:** Five device-walk loops are open at once (below) — close one of
them, or `/plan-slice phase6-part3a` (renaming the household, next up on the
roadmap; unblocked, no dependency on the open loops).
**Latest decision:** D111

**Phase 6 part 2's own device-walk loop is open.** The release build
installed and launched cleanly on the Galaxy device, but nobody has
confirmed against a real device that typing a tag's spelling — in either
app language — actually narrows the list, that a title match and a tag
match appear together for the same query, that a chip tap still narrows by
whole token only, and that a household with recipes but no tags shows the
Favorites chip.

**Phase 6 part 1b's own device-walk loop is open.** The Edge Function
deployed cleanly and the release build installed on the Galaxy device, but
nobody has confirmed against the real device that saving a recipe with a
brand-new Serbian tag actually mints its English pair, that the chip
relabels when the app's language is switched, and that saving again makes
no second model call (checkable via `ai_usage` rows or the function's log).

**Phase 6 part 1a's own device-walk loop is also still open.** Migration 21
is on hosted (pushed as part of 1b's own device walk), so that blocker is
cleared, but nobody has yet confirmed against a real device that
hand-inserting a `Posno`/`Lenten` pair and switching the app's language
actually shows the translated chip on both the list and detail screens,
that a second untranslated tag still reads as typed, and that tapping the
translated chip still narrows the list. Part 1b's own model-minted pairs
should serve this just as well as a hand-inserted one, once its own loop
above is closed.

**Phase 5 part 6's device-walk loop is also still open** (translating from
the editor, `d7dcb81`) — not to be confused with the three Phase 6 loops
above. The release build installed and launched cleanly on the physical
Galaxy device against hosted, but nobody has confirmed back that tapping
Translate from the editor actually saves, calls the Edge Function, and
shows Review instead of Translate afterward on a real device.

**Phase 5 part 5's device-walk loop is also still open.** The shopping
list's clipboard-copy action installed cleanly on the same device, but
copying an actual generated list, seeing the SnackBar, and pasting the
text elsewhere have not been confirmed back either. Five device-walk
loops are now open at once — a future session should close all of them,
not just the newest one.

**This Flutter SDK's `flutter_test` does not stub the clipboard channel.**
Discovered in Phase 5 part 5: an unmocked call to `Clipboard.setData` (or
`Clipboard.getData`) inside a widget test hangs indefinitely instead of
throwing or returning null — confirmed with several minimal reproductions
before touching the real test. Reading `Clipboard.getData` back from the
test body (as opposed to from inside a widget's own callback) hangs the
same way. Any future test touching the clipboard needs a mock
`SystemChannels.platform` handler registered in `setUp`/`tearDown` (see
`shopping_list_screen_test.dart`) — verify the clipboard's actual contents
by testing the pure-Dart formatter directly instead of round-tripping
through `Clipboard.getData`.

**A debug-signed and a release-signed APK can never overwrite each other
in place.** Confirmed again in Phase 5 part 6: switching from `make
run-hosted` (debug) to a release install, or back, always needs the other
variant uninstalled first — `adb install -r` alone fails with
`INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Uninstalling clears app data, so
Google sign-in has to happen again afterward. `adb install` is also
ambiguous whenever the Android emulator is attached alongside the physical
device (Phase 5 part 5's finding) — install by serial, `adb -s <serial>
install`.

**A slice with a migration needs `make db-push`, not just `make
db-reset`, before testing against hosted.** Phase 5 part 1's own
release-build walk hit it directly: migration 19 was applied locally and
the code shipped querying the new columns, but hosted was still on an
older migration, so the hosted recipe list 400'd with a generic "Nešto je
pošlo naopako." — no Dart stack trace reaches logcat in a release build, so
this took a direct `information_schema.columns` query against hosted to
diagnose. Fixed with `supabase db push`. Phase 6 part 1a's own migration
(21) sat unpushed for a full slice before part 1b's device walk finally
pushed it — worth pushing a migration to hosted in the SAME slice that
writes it, next time, rather than letting it wait for whichever later slice
happens to need a device walk first.

**Local sign-in requires a device that can hold a Google account**
(Phase 4 part 3's finding). The Android emulator cannot add one at all —
Google's device-integrity gating — so it stays useful for UI work and
useless for exercising sign-in. A physical device's silent credential
restore can sign in with no visible tap at all, which is worth knowing when
a screenshot shows the recipe list with no sign-in step in between.

**Google-only sign-in means no App Store submission** (Phase 4 part 4).
Guideline 4.8 requires an equivalent privacy-preserving login option;
Apple sign-in was dropped from the roadmap outright, not deferred.
Personal signing and TestFlight are unaffected.

**Not yet watched:** a brand-new Google user landing on
`CreateHouseholdRoute` through `on_auth_user_created`, flagged since Phase 4
part 3. The trigger is unchanged and fires on `auth.users` regardless of
provider, but no slice has watched it fire for a Google-created user yet.
`display_name` will be the email local-part when someone checks —
`handle_new_user()` does `split_part(new.email, '@', 1)` and ignores
Google's `full_name`.

**Known issue, not from this slice:** `make check` fails at `seed-check` and
has since `c8be2bc`. That commit edited one *comment* line in
`supabase/seeds/ingredients.csv`, and `catalogFingerprint()` hashes raw bytes,
so the guard fires on a byte-identical catalog (200 ingredients, 618 names).
Everything else in `make check` is green. Deliberately left for its own slice
— the candidate fix is fingerprinting the parsed rows rather than reverting a
correct comment or emitting a catalog migration for a typo.

Update this file as the last step of closing a slice (`/close-slice`), not
mid-task. If it disagrees with `git log`, trust `git log` and fix this file.
