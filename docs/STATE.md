# State — 2026-09-21

**Branch:** `main`
**Last shipped:** Phase 5 part 5 (`42dbe70`) — export the shopping list to
the clipboard. `ShoppingListScreen`'s AppBar gains a copy action beside
regenerate: `Clipboard.setData` with a plain-text to-buy list, confirmed
with a SnackBar, on `household_screen.dart`'s existing invite-code-copy
pattern. The screen's private grouping helpers moved into a new
`shopping_list_text.dart` so the export and the on-screen order share one
definition (`groupByCategory`) instead of two that could drift; the
exported text is built from the list's own `list.locale`
(`lookupAppLocalizations`), the same document/chrome split D94 already
drew, not the reader's ambient locale. No schema change, no migration, no
new package. Verified with the full automated suite (`dart analyze`,
`check_layers`, `deno check`/`lint`/`fmt`, `flutter test` including the new
`shopping_list_text_test.dart`) and installed as a release build against
hosted on the physical Galaxy S25 (`RFCY61SRQ3B`) — the install succeeded,
but the on-device walk itself (generate a list, tap copy, confirm the
SnackBar, paste elsewhere) was handed to the user to run by hand and had
not been confirmed back as of this entry.
**In flight:** none
**Next:** Phase 5 Part 6 — translating from the editor. See
`docs/ROADMAP.md`.
**Latest decision:** D105

**Part 5's own device-walk loop is open**, the same shape Part 3 left open
before Part 4 closed it: the app installed cleanly on the physical Galaxy
S25 against hosted, but nobody has confirmed back that copying an actual
generated list, seeing the SnackBar, and pasting the text elsewhere all
work on-device. A future session should close this before trusting the
copy feature beyond what `shopping_list_text_test.dart` and
`shopping_list_screen_test.dart` already cover.

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
local. (Parts 2 through 5 carried no migration, so this did not recur.)

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
