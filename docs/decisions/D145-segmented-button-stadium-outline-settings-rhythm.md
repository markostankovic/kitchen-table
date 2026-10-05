# D145 — Segmented buttons are an outlined stadium app-wide; Settings' rhythm and secondary lines step up
**Status:** active
**Touches:** lib/core/theme/app_theme.dart, lib/features/auth/presentation/settings_screen.dart, test/core/theme/app_theme_test.dart, docs/DESIGN_SYSTEM.md

**Decided.** For frame 20 of round `sync-design-initial` (2026-10-05):
1. **`segmentedButtonTheme` is a `const StadiumBorder()`** with an
   `outline` stroke (was `outlineVariant`) and an `onSurface` unselected
   label and icon (was `onSurfaceVariant`). It applies **app-wide**, to all
   six `SegmentedButton`s: settings ×2, the meal-plan view toggle, the
   editor ×2 and the shopping list's range bar. The selected
   `secondaryContainer` / `onSecondaryContainer`, the 48dp height and
   `labelLarge` are unchanged. The user chose all three changes, app-wide.
2. **Settings' group header → card gap is `md`** (was `sm`).
3. **The profile and household rows put `lg` after the avatar / home icon**
   (was `md`).
4. **Settings' secondary lines are `bodyMedium` `onSurfaceVariant`** (were
   `bodySmall`): the theme's "this app only" line, `Prijavljeni ste Google
   nalogom` (and the profile card's loading and error lines, which share
   its path), and `2 člana`.

**Why.**
- The stadium matches every other button in the app (`full`). The
  `outline` stroke is the one the outlined and neutral buttons already use.
  The muted unselected label read as disabled next to the mustard segment.
- One theme serves every toggle. A settings-only override would leave two
  segmented-button styles in the app.
- The frame's looser rhythm and larger secondary lines make the screen
  easier to scan, and the household row lands at the frame's ~72dp.

**Rejected** (seen in the frame, not adopted):
- **The 56dp `primaryContainer` profile avatar.** D126 #2: avatars are
  40dp mustard circles, and green is for actions.
- **The 16/24 email and subtitle size.** It is not a type role.
- **Filled `light_mode` / `dark_mode` glyphs.** The icon set is out of the
  round's scope.
- **The `login` glyph on Sign out.** `logout` is the right meaning.
- **The account group's −8 pull-up under the hairline**, the 2px title →
  description gap and list padding of 4 / 24. All are off the spacing scale.
- **`AppRadii` for the stadium.** A stadium is a shape, not a radius.

**Consequences.** The narrow consumers (the range bar's three ~109dp
segments at 360dp, the editor's toggles) kept their layout. The 360dp tests
and the emulator walk found no clipping at the rounded ends.
