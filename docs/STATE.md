# State — 2026-09-21

**Branch:** `main`
**Last shipped:** Phase 5 part 6 (`d7dcb81`) — translating from the editor.
`RecipeEditScreen`'s AppBar gains its first action, a translate
`IconButton`, shown exactly when `RecipeDraft.canTranslate` holds. One tap
validates the form, saves the draft (`RecipeEditor.saveAndTranslate` calls
`save()` first — there is no dirty-tracking machinery, and `save()` is the
only thing that mints an id for a brand-new recipe), translates the id it
returns, and shows a snackbar naming the target language; a failure lands
on the same `_error` surface `_submit()` already renders. The target
locale follows `draft.originalLocale`, not the reader's ambient locale —
the mirror image of D86's read-side exception. `otherLocale()` and
`canTranslateInto()`, new pure functions in `recipe_translation.dart`, are
now the one definition behind D85's "never offered again" guard;
`RecipeDetail.canTranslate` and the new `RecipeDraft.canTranslate` both
call it instead of each restating the rule. No migration, no schema
change, no new package. Verified with the full automated suite (`dart
analyze`, `check_layers`, `deno check`/`lint`/`fmt`/`test`, `flutter test`
— 534 tests, including new pure-domain and widget cases) and installed as
a release build against hosted on the physical Galaxy S25 (`RFCY61SRQ3B`)
— the install succeeded, but the on-device walk itself (tap Translate,
confirm the snackbar, confirm Review replaces Translate afterward) was
handed to the user to run by hand and had not been confirmed back as of
this entry.
**In flight:** none
**Next:** Phase 5 Part 6 was the roadmap's last planned slice — no Phase 6
exists yet. Next session should either close one of the two open
device-walk loops below or plan a new slice with `/plan-slice`.
**Latest decision:** D106

**Part 6's own device-walk loop is open**, the same shape Part 5 left open
before this part started: the release build installed and launched
cleanly on the physical Galaxy S25 against hosted, but nobody has
confirmed back that tapping Translate from the editor actually saves,
calls the Edge Function, and shows Review instead of Translate afterward
on a real device. A future session should close this before trusting the
feature beyond what `recipe_draft_test.dart` and
`recipe_edit_screen_test.dart` already cover.

**Part 5's own device-walk loop is also still open.** The shopping list's
clipboard-copy action installed cleanly on the same device, but copying an
actual generated list, seeing the SnackBar, and pasting the text elsewhere
have not been confirmed back either. Two device-walk loops are now open at
once — a future session should close both, not just the newest one.

**This Flutter SDK's `flutter_test` does not stub the clipboard channel.**
Discovered in Part 5: an unmocked call to `Clipboard.setData` (or
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
in place.** Confirmed again in Part 6: switching from `make run-hosted`
(debug) to a release install, or back, always needs the other variant
uninstalled first — `adb install -r` alone fails with
`INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Uninstalling clears app data, so
Google sign-in has to happen again afterward. `adb install` is also
ambiguous whenever the Android emulator is attached alongside the physical
device (Part 5's finding) — install by serial, `adb -s <serial> install`.

**Known gap from Part 2, not fixed:** the filter row — Favorites chip
included — only renders once the tag vocabulary is non-empty or a filter is
already selected (the slice's own spec). A household with zero tags
therefore has no way to reach the Favorites filter at all right now. Recorded
in D102's Consequences. A future session should decide whether the Favorites
chip deserves to render on its own regardless of tag vocabulary.

**A slice with a migration needs `make db-push`, not just `make
db-reset`, before testing against hosted.** Phase 5 part 1's own
release-build walk hit it directly: migration 19 was applied locally and
the code shipped querying the new columns, but hosted was still on
migration 18, so the hosted recipe list 400'd with a generic "Nešto je
pošlo naopako." — no Dart stack trace reaches logcat in a release build, so
this took a direct `information_schema.columns` query against hosted to
diagnose. Fixed with `supabase db push`. Any future slice touching a
migration should push it to hosted before a device walk, not just reset
local. (Parts 2 through 6 carried no migration, so this did not recur.)

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
