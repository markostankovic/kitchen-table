# State — 2026-09-21

**Branch:** `main`
**Last shipped:** Phase 6 part 1a (`b22a327`) — tags carry a sr/en pair.
`recipe_tag_names` (migration 21) keys on the normalized *original*
spelling — exactly `RecipeTag.key` — so a tag typed in one language now
renders in the reader's own language on both the recipe list's filter
chips and the detail screen's chips, a tag with no pair renders exactly as
typed, and `RecipeRepository._filtered` needed no change at all: the key a
chip carries never changes, only its label. `RecipeTagNameCache` (Drift
schema 6→7) departs from `IngredientNameCache`'s watermark-and-delta sync
on purpose — one household's tag vocabulary is a handful of rows, so a
fetch replaces the cached set wholesale, `UnitCatalogCache`'s own
reasoning. The editor's comma-joined tags field is untouched, deliberately.
Nothing in this slice writes a translation pair — that is part 1b, not
built yet, and the roadmap's old single "Part 1" is now split into 1a/1b
on Phase 2 part 6a/6b's precedent. Verified with the full automated suite
(`dart analyze`, `make db-reset` + `make test-sql` including the new
`rls_recipe_tag_names_test.sql`, `flutter test` — 544 tests) — `make
check` stopped at the pre-existing, unrelated `seed-check` failure before
reaching `test-sql`/`l10n-check` in that chain, both already confirmed
green independently. Hand-inserting a pair and walking the language switch
locally, and pushing migration 21 to hosted for a device install, were
both handed to the user and had not been confirmed back as of this entry.
**In flight:** none
**Next:** Three device-walk loops are open at once (below) — close one of
them, or `/plan-slice phase6-part1b` (`translate-tags`, the writer of the
pair the roadmap already scoped).
**Latest decision:** D108

**Phase 6 part 1a's own device-walk loop is open.** The migration applies
cleanly locally and `flutter test` covers the relabelling logic, but nobody
has confirmed against a real device that hand-inserting a `Posno`/`Lenten`
pair and switching the app's language actually shows the translated chip on
both the list and detail screens, that a second untranslated tag still
reads as typed, and that tapping the translated chip still narrows the
list. This needs `make db-push` before the walk (migration 21 has not been
pushed to hosted yet) — see the hosted-migration note below.

**Phase 5 part 6's device-walk loop is also still open** (translating from
the editor, `d7dcb81`) — not to be confused with the new Phase 6 above. The
release build installed and launched cleanly on the physical Galaxy S25
against hosted, but nobody has confirmed back that tapping Translate from
the editor actually saves, calls the Edge Function, and shows Review
instead of Translate afterward on a real device.

**Phase 5 part 5's device-walk loop is also still open.** The shopping
list's clipboard-copy action installed cleanly on the same device, but
copying an actual generated list, seeing the SnackBar, and pasting the
text elsewhere have not been confirmed back either. Three device-walk
loops are now open at once — a future session should close all three, not
just the newest one.

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

**Known gap from Phase 5 part 2, not fixed, and now decided (not yet
built).** The filter row — Favorites chip included — only renders once the
tag vocabulary is non-empty or a filter is already selected (the slice's
own spec). A household with zero tags therefore has no way to reach the
Favorites filter at all right now. Recorded in D102's Consequences; Phase 6
part 2 is where this gets decided and built.

**A slice with a migration needs `make db-push`, not just `make
db-reset`, before testing against hosted.** Phase 5 part 1's own
release-build walk hit it directly: migration 19 was applied locally and
the code shipped querying the new columns, but hosted was still on an
older migration, so the hosted recipe list 400'd with a generic "Nešto je
pošlo naopako." — no Dart stack trace reaches logcat in a release build, so
this took a direct `information_schema.columns` query against hosted to
diagnose. Fixed with `supabase db push`. Phase 6 part 1a also carries a
migration (21) and has **not** been pushed to hosted yet — do this before
that part's own device walk, not just reset local.

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
