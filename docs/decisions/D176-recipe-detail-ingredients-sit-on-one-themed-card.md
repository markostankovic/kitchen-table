# D176 — Recipe detail's ingredients sit on one themed card
**Status:** active
**Touches:** lib/features/recipes/presentation/recipe_detail_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.** On recipe detail, the Ingredients heading (with its servings
trailer), every section heading (`RecipeGroupHeading`, D161) and every
`IngredientLineRow` sit on one bare themed `Card` (D134: `KitchenColors.card`
fill, no hairline, radius from the theme). It is the private
`_IngredientsCard`, built in `_RecipeNotesCard`'s shape (D155):
`SizedBox(width: double.infinity)`, then `Card`, then `Padding`, then a
start-aligned `Column`.
- The padding is `fromLTRB(lg, lg, lg, xs)`. The last row already ends in
  its own `sm`, so `xs` closes the card without a second gap. That is the
  canvas's `16 16 4`.
- With no ingredients, the bottom is `lg`, because the plain empty text has
  no trailing padding. The canvas doesn't draw this case.
- Rows stay flush inside the card, 16 in from its edge, not `inset`. D156's
  run logic and last-line-no-divider rule are unchanged.
- The stat strip to the card stays `xl` (24). The card to Steps is `xxl`
  (32), up from `xl`, because the card edge is the boundary now, not a
  last row's own `sm`.
- The recipe editor and import review lists (`IngredientLinesEditor`) stay
  bare.

**Why.** Design round 4 (`docs/design/handoffs/2026-10-16-round-4-recipe-detail-signin/`)
cards the detail's ingredients and leaves the editing lists bare. The
detail is the reading surface, so the card groups the shopping-relevant
block the way the end note's card already groups the note. Reusing the
note card's shape means the light/dark fill is already proven on this
screen.

**Rejected.**
- A shared card widget in `core/widgets/`. It is detail-only, so it doesn't
  clear the bar.
- Changing `IngredientLineRow`'s last-row padding to fit the card. The
  card's `xs` bottom does it without touching a row shared with the
  shopping list and review.
- `inset` rows inside the card. The card padding already gives the 16.
- Carding the editor and review lists to match. The canvas leaves them
  bare.
- Keeping `xl` to Steps. It read as 24 against the card edge where the
  canvas has 32.
