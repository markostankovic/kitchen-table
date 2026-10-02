# D138 — Recipe list per the design round: the add menu hangs off an app-bar `+`, the empty state sits on a card, the result count always shows
**Status:** active — amends D119's rejection of the app-bar `+`
**Touches:** lib/features/recipes/presentation/recipe_list_screen.dart, lib/core/widgets/app_empty_state.dart, lib/core/theme/app_theme.dart, test/features/recipes/recipe_screens_test.dart, test/core/widgets/app_empty_state_test.dart, docs/DESIGN_SYSTEM.md

**Decided.** The user settled three calls for frames 04–06 of round
`sync-design-initial` (2026-10-02).
1. **The add entry is a `+` `IconButton` in `AppBar.actions`.** It anchors
   the same `MenuAnchor` and the same four `MenuItemButton`s (new, link,
   paste, photo) with their leading `_outlined` icons, even though the
   bundle's `Menu` has no icon slot. No screen has a FAB now.
   `floatingActionButtonTheme` stays in the theme as a guard against part
   2's 1.94:1 invisible FAB.
2. **`AppEmptyState(card: true)`** puts the same column on a
   `KitchenColors.card` panel, radius `AppRadii.md`, inset `lg`,
   top-aligned, padded `xxl` / `xl`. It is still a `ListView` so that
   `RefreshIndicator` works. It is opt-in so that callers move one slice at
   a time. The recipe list uses it for both its empty states. The shopping
   list adopts it in `phase7-sync-shopping-list` (frame 19). Import review
   has no frame and stays bare.
3. **The result count shows above every non-empty list**, not only a
   narrowed one, in `bodyMedium` `onSurfaceVariant`. It is item 0 of the
   list, so it scrolls away with it.
4. **Menu items are `bodyMedium` w400** through a new `menuButtonTheme`
   (text style only), matching `popupMenuTheme`.
5. The vertical rhythm follows the bundle: 4 / 12 / 16 / 12 / 24.

**Why.**
- D119 rejected the bare `+` because "four import routes need a menu". The
  design's `+` *is* a menu anchor, so that reason no longer holds.
- Without the FAB, the list's bottom `xxl` clearance had nothing to clear.
- A carded panel reads as a region of the screen rather than a void, and
  it matches frames 05 and 19.

**Rejected.**
- **The bundle's multi-select tags** (frames 04–05 show `Favorites` +
  `Lenten`, and `Cakes` + `Lenten`). That would change the provider and the
  repository, not the visuals. D102's single tag plus a Favorites toggle
  stands.
- Making the card the default for `AppEmptyState`: it would restyle the
  shopping list and import review outside their own slices.
- `Card` for the panel: `DecoratedBox` carries no `Material` ink or margin.
- Dropping the menu's leading icons to match the bundle.

**Consequences.** `alignmentOffset` on the `MenuAnchor` was left at its
default. Whether the menu clears the right edge without covering the `+`
is for the device walk.
