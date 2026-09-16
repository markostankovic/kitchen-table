## D73 — The ingredient-name cache and its sync live in `features/recipes/data/`, not `features/ingredients/data/`, until a second caller exists

**Decided.** `LocalRecipeDataSource` holds the read/write/resolve methods
for `IngredientNameCache`, and `RemoteRecipeDataSource`/`RecipeRepository`
hold the delta fetch of `ingredient_names` and the best-effort background
sync that keeps it warm. `IngredientRepository` and
`LocalIngredientDataSource` (`features/ingredients/data/`) are untouched by
this part.

**Why.** `ingredient_display_names` has exactly one caller in the whole
codebase: `RecipeRepository`. Putting the offline version in
`features/ingredients/data/` — the seemingly natural home — would need
`RecipeRepository` to call into it, and `tool/check_layers.dart` forbids
`features/recipes/data/` from importing `features/ingredients/data/`
directly (D33): that is the exact wall Phase 1c hit before D43 moved the
catalog to `core/ingredients/`. `core/` cannot absorb this instead: the
checker restricts `package:drift` to `data/` and `core/db/`, and
`package:supabase_flutter` to `data/` and `core/supabase/`, so a
cross-feature `core/` helper could hold the cache *read* (drift only) but
never the network *sync* (supabase_flutter) — splitting one round trip
across two files and two owners, for a boundary with no second caller to
justify it yet.

D43's own precedent is the better fit, read literally: Phase 1c's ingredient
catalog datasource was duplicated once, with a note that a third caller
should reopen the decision. There has never been a first duplication here —
only one caller has ever existed — so there is nothing to deduplicate yet.
The moment a second feature needs `ingredient_display_names` (Phase 3's
translated recipe view is the likely candidate), that is the signal to
extract this into `core/ingredients/`, exactly as D43 describes, and not a
moment before.

**Rejected.**
- Building the sync in `features/ingredients/data/` and having
  `RecipeRepository` call it directly — the forbidden cross-feature `data/`
  import D33 already ruled out.
- A `core/ingredients/` helper split across a drift-only read and a
  supabase-only write — legal per file, but two files and two owners for
  one round trip nobody but recipes has ever asked for.
- Waiting to build recipe-detail offline resolution until the ingredients
  feature "properly" owns it — blocks a Phase 2 Done-when item on an
  abstraction Phase 2 does not need yet.
