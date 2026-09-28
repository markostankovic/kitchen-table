# D126 — The household and sign-in vocabulary: a filled logo-less 52dp Google button, circular all-mustard avatars, Leave in the bottom destructive slot, text-button destructive confirms, and no colours on the filled-button theme
**Status:** active
**Touches:** lib/features/auth/presentation/sign_in_screen.dart, lib/features/auth/presentation/settings_screen.dart, lib/features/households/presentation/household_screen.dart, lib/core/widgets/app_monogram_tile.dart, lib/core/theme/app_sizes.dart, lib/core/theme/app_theme.dart, docs/DESIGN_SYSTEM.md

**Decided.** Phase 7 part 8 settles five points where the reference PNGs or
the old code disagreed with the design system:

1. **The Google button is filled `primary`, 52dp, with no logo.** It is
   `AppSizes.signInButton`, which is deliberately not `field` even though
   both are 52.
2. **Avatars are circles, and all mustard** (`AppMonogramTile(circular:
   true)`, `secondaryContainer`, `AppSizes.avatar` 40). The role is in the
   subtitle text, so the owner is not colour-coded. A circle is a person
   and a square is a thing.
3. **Leave moves from the adult's own row to the bottom destructive slot**,
   which the owner's Delete already uses. Only one of the two ever renders.
   A member row gets a `⋮` only where the owner can remove someone else.
   D115's gating is unchanged: absent, not disabled.
4. **Destructive confirms are `TextButton`s in `destructive`** (Remove,
   Leave, Delete household, and Discard import from D123). They are never a
   filled button.
5. **`filledButtonTheme` sets no colours.** Material 3's defaults give
   filled `primary`/`onPrimary` and tonal
   `secondaryContainer`/`onSecondaryContainer`. A theme style applies to
   every variant, so setting `primary` there made every tonal button green.

**Why.**
- The PNG's outlined G-mark button needs an asset and an SVG package the
  repo does not have (rule 8). § Buttons says a screen's one action is its
  filled button.
- The reference's green owner avatar would put the role in two places, and
  green is reserved for actions.
- A leave icon on your own row sat among informational rows, while the
  owner's equally final Delete was already at the bottom.
- A filled crimson confirm would be the loudest thing on the screen, for
  the action least worth encouraging.
- The walk found the tonal Copy rendering filled green. Import review's
  `Open recipe` had been green unnoticed since D123.

**Rejected.**
- An outlined Google button with a logo.
- A green owner avatar.
- Square avatars.
- Leave as an icon on the member row.
- A per-row overflow for the adult too.
- Filled destructive confirms.
- Overriding tonal colours at each call site instead of fixing the theme.
- `AppEmptyState` for the empty invites line, which is too heavy for one
  sentence.

**Consequences.**
- The household screen has no filled button: Create invite code is
  outlined and Copy is tonal.
- Every `FilledButton.tonal` in the app is now mustard, including import
  review's AlreadySaved action. A light/dark theme test pins both variants.
- The tooltip keys became label keys: `copyCodeButton`,
  `revokeInviteButton`, `leaveHouseholdButton` and `removeMemberMenuItem`.
