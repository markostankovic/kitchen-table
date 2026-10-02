# D134 — No serif: a recipe's name is sans w700; cards drop their hairline for a per-brightness fill; the meal-plan grip is only a hint
**Status:** active, amended by D140 (the grip is now on every reorderable row, not the meal plan's alone) — supersedes the type half of D127; amends D132's note rule and D118's "bundles Literata"; its letter-spacing values are amended by D136 (positive)
**Touches:** lib/core/theme/kitchen_type.dart, lib/core/theme/kitchen_colors.dart, lib/core/theme/app_theme.dart, lib/core/theme/app_sizes.dart, lib/core/recipes/widgets/recipe_card.dart, lib/features/meal_plan/presentation/meal_plan_screen.dart, pubspec.yaml, docs/DESIGN_SYSTEM.md

**Decided.**
1. **One face, the platform sans.** Literata and `assets/fonts/` are
   deleted. `KitchenType` stays as the semantic layer for "a recipe's
   name", now in sans at **w700**: `recipeTitle` 17/24 −0.1,
   `recipeTitleLarge` 28/34 −0.3, and a new `monogram` 30/36 for the 72dp
   tile. `displaySmall` (the wordmark) is 32/40 w700 −0.5 and
   `headlineSmall` is 28/34 w700 −0.3.
2. **A meal-plan note is `recipeTitle` at w400**, because bold now means a
   recipe's name and a note is not one. A leftover stays bold. This
   amends D132's "a note wears a recipe title's face".
3. **Cards have no hairline.** `CardTheme` is `KitchenColors.card`,
   radius 12, elevation 0, no `side`, no tint. `card` aliases
   `surfaceContainer` in light and `surfaceContainerHigh` in dark. Every
   themed `Card` follows.
4. **Meal entries** sit on `surface`, and a leftover is transparent under
   its dashed border. A trailing `Icons.drag_indicator`
   (`KitchenColors.dragHandle` = `outline`, `AppSizes.grip` 20 in a
   `gripColumn` 40) is **only a hint**: it has no gesture and is excluded
   from semantics. Tap still opens the actions sheet, and long-press
   anywhere still lifts the card.
5. **Drag look.** The lifted card is tilted −1.5° at 1.02, in the card
   fill. It leaves a 1.5dp dashed `outline` placeholder at 60% alpha. A
   hovered slot or collapsed day fills `KitchenColors.dropTarget`
   (`primaryContainer`) and gets a 2dp dashed `primary` outline. All three
   are the one private dashed painter with a `strokeWidth`.

**Why.** It is Claude Design's round-2 handover (2026-09-30). Dark
`surfaceContainer` (`#20201A`) is only +5 tone above the ground and
disappears once there's no border, so dark goes one step higher. The user
made three calls:
- keep tap → actions sheet, over the handover's loose "tap opens the
  recipe";
- the note at w400;
- all themed cards follow the new `CardTheme`, not only the ones in the
  updated frames.

**Rejected.**
- A separate serif-free `KitchenType` rename. The class still means "a
  recipe's name", so its call sites stay put.
- Borrowing `iconInButton` / `avatar` for the grip. They share numbers but
  not meaning (on `emptyStateIcon`'s precedent).
- Making the grip its own drag handle. It would add a second gesture for
  no gain, since long-press anywhere already lifts the card.
- The handover's 18dp `+` icon. `iconInButton` (20) is the one in-button
  icon size.

**Consequences.** In light, the recipe list's cards share the nav bar's
`#F5EBDF`. They never touch, and the walk found them fine. The `List —
offline`, `Review import`, `Household` and `Settings` frames still show the
old bordered card until Claude Design updates them. `DESIGN_SYSTEM.md` is
the source of truth there.
