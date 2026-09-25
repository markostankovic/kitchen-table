# D119 — The recipes surface's component vocabulary: six shared widgets, a heart for favourite, and a titleless detail app bar
**Status:** active
**Touches:** lib/core/widgets/app_badge.dart, lib/core/widgets/app_meta_row.dart, lib/core/widgets/app_monogram_tile.dart, lib/core/widgets/app_stat_strip.dart, lib/core/widgets/app_search_field.dart, lib/core/recipes/widgets/recipe_card.dart, lib/core/ingredients/widgets/ingredient_line_row.dart, lib/features/recipes/presentation/, docs/DESIGN_SYSTEM.md, docs/design/MIGRATION_PLAN.md

**Decided.** Phase 7 Part 3 builds the recipes surface out of seven shared
widgets rather than screen-private ones. `AppBadge`, `AppMetaRow`/`AppMetaItem`,
`AppMonogramTile`, `AppStatStrip` and `AppSearchField` go in
`lib/core/widgets/` (generic, subject-free); `RecipeCard` and
`IngredientLineRow` go in the `core/<feature>/widgets/` middle ground D43/D53
created, because they know their subject and two features need them.

Four calls inside that:

1. **`AppMetaRow` is the fix for the Serbian meta-line defect**, and it is
   structural. Each fact is its own `Row(mainAxisSize: min)` inside a `Wrap`,
   so an item is indivisible and wraps whole; there are no separators.
2. **`AppSearchField` is promoted above `MIGRATION_PLAN.md`'s widget table**,
   which did not list it. It owns the decoration and the clear button but
   **not** the debounce — the list and the picker sheet key different
   providers and each keeps its own `Timer`.
3. **Favourite is a heart, and a star is a rating.** `Icons.favorite` in
   `KitchenColors.favorite` replaces `Icons.star` for favouriting everywhere
   in the app, and the Favorites filter chip loses its star avatar.
4. **The detail screen's app bar carries no title.** The recipe's name sits in
   the body at `headlineSmall`, and the bar keeps only the back button and the
   three actions.

**Why.** The meta row is the whole reason this slice exists. A ` · `-joined
run breaks wherever the line runs out, so Serbian split `30 min` from
`priprema` across two lines; Part 2 resolved it by accident, dropping the
subtitle 14pt → 12pt, and two points of font size is not a fix for a language
that runs 12% longer on average and 4x longer on short strings. Only
indivisible items hold for every string.

`AppSearchField` clears § Components' bar on its own terms — generic, and with
a second consumer *today*, not on a promise: both search boxes needed the same
three corrections (stadium, sans input, sans hint), and one widget is the only
thing that keeps them from drifting apart again, as they already had.

The heart resolves a collision the old screen lived with: a star in the app
bar meant favourite while five stars a few pixels below meant a rating. One
glyph, two meanings, on one screen.

The titleless bar is about saying the name once. `headlineSmall` is what
§ Type reserves for a recipe's own title, and a bar repeating it in
`titleLarge` is the same words twice in two sizes.

**Rejected.** Putting `RecipeCard` and `IngredientLineRow` in
`core/widgets/` — rejected; they know what a recipe and an ingredient line
are, which is exactly the line § Where a component lives draws.
`IngredientLineRow` taking a `RecipeIngredient` — rejected; the import review
screen renders `RecipeDraftLine`s, a different type carrying the same five
facts, so the row takes **primitives** and slice 5 reuses it instead of
forking it. `AppSearchField` owning the debounce — rejected, see above. A
dashed-border package for the unmatched marker — rejected, CLAUDE.md rule 8; a
~25-line `CustomPainter` strokes eight arcs. `package:characters` for the
monogram's first letter — rejected, same rule: every letter this app displays
is Latin. The mock's circular buttons floating over a full-bleed photo —
rejected; an arbitrary photo in two brightnesses gives no contrast guarantee
behind an icon, and the favourite toggle must stay reachable at any scroll
position. The mock's combined `3 h 30 min` stat — rejected; the app has no
hour/minute formatter and inventing one merges two facts into one, so prep and
cook stay two items with their existing strings. Replacing the FAB with the
mock's bare `+` in the app bar — rejected; four import routes need a menu.

**Consequences.** A screen that wants a meta line uses `AppMetaRow` and does
not join strings with a separator; that is now a review comment. A recipe with
no photo always shows a monogram tile, including when an image errors, so the
list keeps one alignment down its left edge. The detail screen's photo well
renders whether or not there is a photo — a missing picture is not a failure
state (rule 3's spirit), which is why `broken_image_outlined` is gone. After
this slice the only two `Icons.star` in `lib/` are both ratings, and a star
used for favouriting anywhere is a regression. `AppStatColumn.value` is a
`Widget`, not a `String`, because one column is five stars and a control —
which is what D120 then had to make fit.
