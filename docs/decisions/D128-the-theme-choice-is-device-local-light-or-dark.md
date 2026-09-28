# D128 — The theme is the app's own Light/Dark choice, stored on the device in Drift, Light by default, with no System option; the launch screen is one brand colour
**Status:** active
**Touches:** lib/core/db/app_database.dart, lib/core/db/device_preferences.dart, lib/core/theme/app_theme_mode.dart, lib/main.dart, lib/features/auth/presentation/settings_screen.dart, android/app/src/main/res/, docs/DESIGN_SYSTEM.md

**Decided.**
1. **Settings → Izgled picks Light or Dark for this app only.** Light is the
   default. There is no System option, so the app stops following the
   phone's dark mode.
2. **The choice is device-local**, in a new Drift `device_preferences` table
   (`key` / `value`, key `theme_mode`), read and written through
   `DevicePreferenceStore` (never throws; a failed read is Light). It is not
   a `profiles` column, and there is no migration.
3. **`device_preferences` is not a cache.** `onUpgrade` skips it when it
   drops tables, so every later schema bump keeps the choice, and
   `clearHouseholdCache()` (sign-out, D70) leaves it too.
4. **`main.dart` awaits `appThemeModeProvider` before `runApp`**, through an
   `UncontrolledProviderScope`, so the first frame is already the right
   theme.
5. **The Android launch screen is flat `primary` green (`#366A35`), no icon,
   the same in both phone modes.** There is no `values-night`; a
   `values-v31` sets Android 12+'s system splash to the same colour.

**Why.**
- The user decided the choice belongs to the phone: how a screen looks is
  about the device in someone's hand, not the person. This is the opposite
  of D77, where the language follows the person because it also picks which
  recipe translation they read.
- Light by default and no System option: the user asked for exactly two
  options. The app's palette is designed light-first.
- Drift is already a dependency (rule 8 rules out `shared_preferences`).
- Point 5 came from the device walk. The stock launch screen followed the
  phone's night mode and flashed white before a Dark cold start. Android
  draws it before any Dart runs, so it can't know the in-app choice. Only a
  colour that belongs to neither theme looks intended in front of both.

**Rejected.**
- A `profiles.theme` column, following D77. It needs a migration, and it
  would carry one phone's choice to another.
- A System option. It was not asked for, and it brings back the question
  this setting exists to answer.
- `shared_preferences` (rule 8).
- A cream or near-black launch screen, or keeping `values-night`. Either
  one flashes the wrong theme for half the cooks.

**Consequences.**
- Signing out and in on a shared phone keeps the previous person's theme.
  That is intended.
- The next Drift bump must keep the `device_preferences` exception in
  `onUpgrade`. `test/core/db/device_preferences_test.dart` fails without it.
- If the brand green changes, `android/app/src/main/res/values/colors.xml`
  has to change too.
- `/design-walk` can't switch brightness with `adb shell cmd uimode` any
  more. Use the in-app toggle.
