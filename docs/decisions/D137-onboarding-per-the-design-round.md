# D137 — Onboarding per the design round: lockup and a painted illustration on sign-in, an outlined Google button with the official G, top-aligned `headlineSmall` onboarding with the buttons pinned
**Status:** active — amends D124 #2 (placement) and #4 (titles), D126 #1 (the Google button), and `DESIGN_SYSTEM.md` § Logo's "the sign-in screen has no logo"
**Touches:** lib/features/auth/presentation/sign_in_screen.dart, lib/features/auth/presentation/sign_in_illustration.dart, lib/features/households/presentation/create_household_screen.dart, lib/features/households/presentation/join_household_screen.dart, lib/features/households/presentation/onboarding_mark.dart, lib/core/theme/app_sizes.dart, tool/gen_app_icons.py, assets/brand/, pubspec.yaml, docs/DESIGN_SYSTEM.md

**Decided.** The user chose "do per design" for frames 01–03 of round
`sync-design-initial` (2026-10-02).
1. **Sign-in** shows a recipe-card illustration, then the lockup (mark
   plus "Kitchen Table" in Literata), then the tagline. The illustration
   is `SignInIllustration`, a `CustomPainter` in `ColorScheme` roles. The
   lockup is a light or dark PNG, picked by `theme.brightness`. It is
   English in `sr` too, because a brand name is never localized (D77).
2. **The Google button is outlined and neutral.** It is 52dp, filled
   `surfaceContainerLowest`, with an `outline` border, an `onSurface`
   label, and the official Google G at `iconInButton`, not recoloured. So
   sign-in has no filled button, like the household screen.
3. **Create and join are top-aligned and start-aligned.** Each has a 56dp
   mark tile (`OnboardingMark`, `households` only), a `headlineSmall`
   title and a `bodyLarge` subtitle, then the field. The filled button,
   `sm`, and a full-width text-button switcher are pinned to the bottom by
   `SliverFillRemaining(hasScrollBody: false)` and a `Spacer`. The padding
   sits inside it, not in a trailing `SliverPadding`. There is still no
   `AppActionBar`. The join code gets a label (`Pozivni kod` / `Invite
   code`).
4. **Brand images are PNGs written by `make icons`** into `assets/brand/`
   at 1x / 2.0x / 3.0x. The mark tile's corners are baked in at 24/108,
   like the Android legacy icon. The lockup is inlined into a page that
   loads Literata from Google Fonts. The G comes from Google's own
   sign-in assets in `docs/design/google/`.

**Why.**
- D126 rejected the G only because no asset existed, and a raster PNG
  needs no package.
- D124 kept `headlineSmall` for a recipe's title, which went stale when
  titles moved to `KitchenType.recipeTitleLarge` (D127/D134).
- The frames are top-aligned with the actions at thumb height.
- Literata in a PNG is logo artwork, not UI type, so D134's "no serif"
  still holds.

**Rejected.**
- The bundle's raster `recipe-card.png`: it is cream baked into a
  light-mode crop, so it would show as a cream box in dark.
- `flutter_svg` (rule 8).
- `google_fonts` for a text wordmark (rule 8, and D134).
- A `ClipRRect` and a radius token for the mark: the corners are in the PNG.
- The bundle's `KT4-9PX` code example: the real code is 6 digits.

**Consequences.** `displaySmall` has no screen left, but stays in the theme
for text contexts. A trailing `SliverPadding` after `SliverFillRemaining`
pushes the bottom air off-screen, and a widget test guards against that.
Re-run `make icons` (it needs network access) when `docs/design/logo/` or
`docs/design/google/` changes.
