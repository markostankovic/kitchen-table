## D53 — The meal plan reads recipes through `core/recipes/`, and an entry carries a title, not a `Recipe`

**Decided.** The slot picker watches `plannableRecipesProvider` in
`lib/core/recipes/recipe_picker_providers.dart`, built over a second
`RecipeRepository` instance rather than the recipes feature's own
`application/` provider. `MealPlanEntry` carries `recipeTitle` /
`recipeServings`, resolved from a PostgREST embed at read time and never
persisted.

**Why.** The alternative was a recipe search method on `MealPlanRepository`,
which would have duplicated `title_normalized ilike`, the `deleted_at`
filter, and the `TextNormalizer` hop — D33's mistake, repeated one phase
after D43 undid it for the ingredient catalog. `core/` is exempt from the
cross-feature rule for the same reason `core/ingredients/` is (D43): a second
feature needed a first feature's read path, and the sanctioned move is
`core/`, not a duplicate. A `Recipe` built from a two-column embed would need
placeholder values for `householdId`, `originalLocale`, `sourceType`,
`status` and `createdBy` — a lie the type system would carry forward exactly
the way `Recipe.imageUrl` and `RecipeIngredient.displayName` already show is
unnecessary: a resolved display field is the established pattern for "read
this from an embed, never write it back."

**Consequence.** The picker gets recipe thumbnails for free from
`_withImageUrls`; the week grid's own tiles deliberately do not carry one —
a second copy of the signed-URL logic is what moving `_withImageUrls` to
`core/` would be for, and no second caller needs it yet.

**Rejected.** Moving `recipeListProvider` itself to `core/` wholesale — a
bigger blast radius than one consumer justifies; if a third caller for the
*list* provider specifically ever appears, that is the signal to revisit,
the same way D33 named for the datasource.
