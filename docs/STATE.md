# State — 2026-09-25

**Branch:** `main`
**Last shipped:** Phase 7 part 2 (`b74552c`) — the Garden tokens. The seed is
gone: `app_theme.dart` now returns one of two `const ColorScheme` values with
every role written out from the Claude Design export, `surfaceTint`
transparent in both to kill Material's elevation tint app-wide. Literata is
bundled under `assets/fonts/` (weights 400/600, CLAUDE.md rule 8 — no font
package) and carries everything a person reads; UI furniture stays on the
platform sans. `AppRadii`, `AppSizes` and `AppDurations` join `AppSpacing`,
and `KitchenColors` lands as the app's first `ThemeExtension` — twelve members,
each an alias of a role, so there is no second palette. Five component themes
became seventeen. D118 supersedes D117 on both counts (no seed; dark
`tertiary` is now the palette's `#FF9569`), while keeping D117's constraint
that `tertiary` is signal-only and has to read at 3px. The three shared
widgets the repaint changed were retuned — the offline banner is now a calm
inset card, not an `errorContainer` strip — two nav glyphs swapped, and
`placeholder_screen.dart` deleted. **No screen file under `lib/features/**`
was edited**, by design. `docs/DESIGN.md` is now a pointer at
`docs/DESIGN_SYSTEM.md`, which describes the code rather than the target.
Verified with `dart analyze` (clean), `flutter test` (587/587), `check_layers`
(OK), `l10n-check` (green, no new ARB key), and a full device walk on the
physical Galaxy across `sr`/`en` × light/dark on all six surfaces. `make
check` is green except the pre-existing `seed-check`. No `supabase/` file
touched, so `make test-sql` and the Deno suite were not run.
**In flight:** none
**Next:** Phase 7's remaining parts are per-surface — recipe list and detail,
meal plan, shopping list, household and settings, auth and onboarding — and
independent of each other; `docs/design/MIGRATION_PLAN.md` § 4 sequences them
as slices 2–7. Plan whichever is highest-value with `/plan-slice-ui`. The
tokens are settled ground now, so these are layout and component slices, not
colour ones. Four defects part 2's walk surfaced are listed below and each
belongs to one of those slices — the shopping list's week-header wrap and its
still-untranslated strings would make the shopping-list slice the
highest-value next.
**Latest decision:** D118

**Nine device-walk loops are open — none closed yet.** Phase 7 part 2's
walk ran on the physical Galaxy (2026-09-25) and resolved one of part 1's two
defects; the other stands, and the repaint found four more. In
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
- **Phase 7 part 1** — walked on the physical Galaxy across `sr`/`en` ×
  light/dark on recipe list, recipe detail, meal plan, shopping list,
  household, settings. Two defects found, loop stays open:
  - ~~Recipe list card's meta line wraps badly in Serbian~~ — **resolved by
    Phase 7 part 2**, incidentally rather than deliberately. Part 2's
    `ListTileThemeData` sets `subtitleTextStyle` to `bodySmall` (12);
    before that the subtitle fell through to Material's `bodyMedium` (14).
    Two points narrower is enough: `4 porcije · 10 min priprema · 10 min
    kuvanja · ★ 5` now sits on one line in both languages and brightnesses.
    Re-confirmed on the device 2026-09-25.
  - The shopping list screen (`Lista`/`List` tab) leaves several UI strings
    untranslated when the app language is Serbian: the "Generated Thu, Sep
    24 for Mon, Sep 21 – Sun, Sep 27" line, the "Probably have (N)" section
    header, and its "Cupboard staples" subtitle all render in English.
    `test/core/l10n/arb_parity_test.dart` only checks that ARB keys exist on
    both sides, so it didn't catch this — worth checking whether these
    strings are hardcoded rather than routed through `AppLocalizations`, or
    whether the `sr` ARB entries are simply missing. (Ingredient names
    themselves — bread, milk, egg, flour — were also English, but that's
    recipe data, not a UI string, and out of scope here.) **Still present
    after Phase 7 part 2** — the repaint changed nothing about it.

- **Phase 7 part 2** — walked on the physical Galaxy 2026-09-25 across
  `sr`/`en` × light/dark on recipe list, recipe detail, meal plan, shopping
  list, household and settings. The tokens themselves are sound: Literata
  renders every Serbian Latin diacritic in both weights (`č ć ž š đ Č Ć Ž Š
  Đ`, checked against real recipe copy, no tofu), nothing truncates or
  overflows in Serbian, both brightnesses are legible throughout, and the
  offline banner reads calm in both. Four things stay open:
  - The shopping list's week-range header wraps badly. In Serbian `pon 21.
    sep – ned 27. sep` breaks across **three** lines with `sep` orphaned on
    the last; English `Mon, Sep 21 – Sun, Sep 27` takes two. It shares a row
    with the `Ova nedelja`/`Sledeća` buttons and the calendar icon, and
    `titleMedium` going 17pt sans → 18pt Literata is what pushed it over.
    Nothing clips — it wraps, it does not overflow. The shopping list slice
    owns it.
  - The global offline banner is now calm grey, but the **per-screen**
    "Showing your saved copy — no connection." line is still drawn in
    `error` crimson, and the two appear on screen together on the shopping
    list. MIGRATION_PLAN § 2.1 settled that offline is calm; part 2 only
    restyled the global banner (`core/net/offline_banner.dart`), so the
    per-screen lines on the shopping list and meal plan still contradict it.
  - The FAB has **no `FloatingActionButtonThemeData`** — it was not in part
    2's component list, so it takes Material's defaults
    (`primaryContainer`/`onPrimaryContainer`). In light that lands on a
    bright mint square that reads well; in dark `primaryContainer`
    (`#1D511E`) sits at 1.94:1 against the surface and the FAB recedes into
    the ground. The `+` glyph itself is fine (7.60:1), so this is presence,
    not legibility. `docs/DESIGN_SYSTEM.md` § Shape already says the FAB is
    `AppRadii.lg`, so the theme has somewhere to go.
  - The search field's hint and input text render in **Literata**, because
    Flutter's `InputDecoration` takes `bodyLarge` and part 2 made that role
    the serif. A search box is UI furniture, not reading text, so by § Type's
    own rule it should be the platform sans. Cosmetic, legible, but wrong on
    the rule.

  Not verified: the 3px paprika review marker on `import_review_screen.dart`
  in dark (D117's constraint, now carried by `tertiary` `#FF9569`). Reaching
  that screen needs a real import — an AI parse on the hosted quota and an
  `import_jobs` row — and that was deliberately skipped rather than spend it.
  The value measures 8.44:1 against the dark surface, well clear of the
  generated value D117 rejected, but nobody has looked at it at 3px.

All nine need `make install-hosted` on the physical Galaxy device — not the
emulator, not `flutter run`, not the local stack (CLAUDE.md). A future
session should close as many as it reasonably can in one sitting rather than
walking one loop at a time; 3b and 3c's second-account/throwaway-household
setup can close both together. Phase 7 part 2's own walk (2026-09-25) proved
the device loop works end to end — release build, both languages, both
brightnesses, airplane mode for the offline banner — so the older loops are
blocked on nothing but someone sitting down with the phone.

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
