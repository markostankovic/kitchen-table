# State — 2026-09-24

**Branch:** `main`
**Last shipped:** Phase 7 part 1 (`e61e9a8`) — the design foundation.
`app_theme.dart` replaces the Phase 0 `fromSeed` stub with deliberate
`ThemeData` for both brightnesses: the same seed (`0xFF7A5C3E`) but explicit
colour roles, an explicit `TextTheme`, and five component themes
(`AppBarTheme`, `ChipThemeData`, `FilledButtonThemeData`,
`ListTileThemeData`, `InputDecorationTheme`). Dark mode pins `tertiary`/
`onTertiary` explicitly (D117) because the generated value read too close to
`secondary` at the width `import_review_screen.dart` draws its "needs
attention" marker at; light mode keeps the generated value. `app_spacing.dart`
names the spacing scale already de-facto in the codebase (4/8/12/16/24/32).
`lib/core/widgets/` gained its first three real widgets — `AppErrorView`,
`AppSectionHeading`, `AppEmptyState` — each replacing two or three
disagreeing private duplicates, all deleted. `docs/DESIGN.md`'s Colour, Type
and Spacing sections are filled in and match the code. Verified with `dart
analyze` (clean), `flutter test` (584/584, including 8 new tests), `dart run
tool/check_layers.dart` (OK), and `l10n-check` (green, no new ARB keys).
`pubspec.yaml` unchanged, no migration, no Edge Function — presentation-only,
so `make test-sql` and the Deno suite were not run. **The device walk did not
happen** — no physical Galaxy device was attached in the session that built
this slice, only an emulator, and CLAUDE.md's "running the app" specifically
means the physical device. Neither this slice's own `sr`/`en` × light/dark
walk nor any of the seven older loops it had planned to fold in actually ran;
all eight stay open below.
**In flight:** none
**Next:** Phase 7's remaining parts are per-surface (recipe list and detail,
meal plan, shopping list, household and settings, auth and onboarding) and
independent of each other — plan whichever is highest-value next with
`/plan-slice`. Before picking one, consider closing some of the eight open
device-walk loops below first, since `docs/DESIGN.md` § Both languages and §
Light and dark both assume a working device in hand, and none of the parts
after Part 1 have one confirmed yet.
**Latest decision:** D117

**Eight device-walk loops are open — none closed by Phase 7 part 1.** In
order of age:

- **Phase 5 part 5** — copy a generated shopping list, see the SnackBar,
  paste the text somewhere else. Not confirmed on a real device.
- **Phase 5 part 6** — Translate from the editor saves, calls the Edge
  Function, and shows Review instead of Translate afterward. Not confirmed.
- **Phase 6 part 1a** — a `Posno`/`Lenten` pair shows the translated chip on
  both list and detail when the language is switched; a second untranslated
  tag still reads as typed; tapping a translated chip still narrows the
  list. Not confirmed.
- **Phase 6 part 1b** — saving a recipe with a brand-new Serbian tag mints
  its English pair; the chip relabels on a language switch; saving again
  makes no second model call (`ai_usage` rows or the function log). Not
  confirmed.
- **Phase 6 part 2** — typing a tag's spelling in either language narrows
  the list; a title match and a tag match appear together for one query; a
  chip tap still narrows by whole token only; a household with recipes but
  no tags still shows the Favorites chip. Not confirmed.
- **Phase 6 part 3b** — with a second account joined: owner sees Remove on
  the other member's row and no Leave on their own; the adult sees Leave on
  their own and no Remove on the owner's; both write through and the row
  disappears; Leave lands the now-memberless account on
  `CreateHouseholdRoute` with no restart. Needs a second Google account.
- **Phase 6 part 3c** — on a throwaway household: the owner sees the Delete
  row and an adult does not; the confirm dialog names the household;
  confirming lands the ex-owner on `CreateHouseholdRoute` with no restart;
  creating a new household afterward works. Needs a throwaway household —
  the signed-in device account has real recipes.
- **Phase 7 part 1** — `sr`/`en` × light/dark across recipe list, recipe
  detail, meal plan, shopping list, household, settings: nothing truncates,
  wraps badly or overflows in Serbian; nothing is unreadable in dark.

All eight need `make install-hosted` on the physical Galaxy device — not the
emulator, not `flutter run`, not the local stack (CLAUDE.md). A future
session should close as many as it reasonably can in one sitting rather than
walking one loop at a time; 3b and 3c's second-account/throwaway-household
setup can close both together.

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

**A dialog-local `TextEditingController` should never be manually
disposed.** Confirmed again in Phase 6 part 3a: calling `controller.dispose()`
right after `Navigator.pop()` closes a `showDialog` races the dialog's exit
animation and throws "Tried to build dirty widget in the wrong build scope"
under `pumpAndSettle` in widget tests. `recipe_picker_sheet.dart`'s own
`_promptForNote` dialog already left its local controller undisposed for
this reason; `household_screen.dart`'s rename dialog follows the same
precedent rather than disposing.

**A debug-signed and a release-signed APK can never overwrite each other
in place.** Switching from `make run-hosted` (debug) to a release install,
or back, always needs the other variant uninstalled first — `adb install -r`
alone fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Uninstalling clears
app data, so Google sign-in has to happen again afterward. `adb install` is
also ambiguous whenever the Android emulator is attached alongside the
physical device — install by serial, `adb -s <serial> install`.

**A slice with a migration needs `make db-push`, not just `make
db-reset`, before testing against hosted.** Phase 5 part 1's own
release-build walk hit it directly: migration 19 was applied locally and
the code shipped querying the new columns, but hosted was still on an
older migration, so the hosted recipe list 400'd with a generic "Nešto je
pošlo naopako." — no Dart stack trace reaches logcat in a release build, so
this took a direct `information_schema.columns` query against hosted to
diagnose. Phase 6 parts 3b and 3c both pushed their own migration in the
same slice that wrote it, closing the loop this note used to ask for.

**Driving a real device blind by pixel coordinates is unreliable —
`uiautomator dump` gives exact bounds instead.** `adb shell uiautomator
dump /sdcard/ui.xml` followed by `adb pull` and grepping `bounds="..."` off
`content-desc` attributes gives exact tap targets for any adb-driven
verification — Flutter's semantics tree exposes labeled, bounded elements
this way even though there's no native View hierarchy.

**Local sign-in requires a device that can hold a Google account.** The
Android emulator cannot add one at all — Google's device-integrity gating —
so it stays useful for UI work and useless for exercising sign-in. A
physical device's silent credential restore can sign in with no visible tap
at all, which is worth knowing when a screenshot shows the recipe list with
no sign-in step in between.

**Google-only sign-in means no App Store submission.** Guideline 4.8
requires an equivalent privacy-preserving login option; Apple sign-in was
dropped from the roadmap outright, not deferred. Personal signing and
TestFlight are unaffected.

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
