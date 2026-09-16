## D43 — One ingredient catalog, in `core/` — closing D33

**Decided.** `features/ingredients/data/ingredient_repository.dart` is the only
catalog access in the codebase. Its providers and the ingredient line editor
live in `lib/core/ingredients/`. `features/recipes/data/ingredient_catalog_datasource.dart`
is deleted.

**Why.** D33 chose duplication over relaxing the layer rule when Phase 1c needed
`search_ingredients` from the recipes feature, and said what should happen next:
"If a third caller appears, that is the signal to reopen D33 rather than to
write a third copy." Phase 1d's confirm screen is that third caller, arriving
before the predicted one — it needs the line editor, and `features/import/` may
not import `features/recipes/presentation/`.

`core/` is outside the feature rule entirely: `tool/check_layers.dart` derives
layer and feature from `lib/features/<x>/<layer>/` and nothing else. That is not
a loophole being exploited — `core/supabase/` already holds
`currentUserIdProvider` for exactly this reason.

**Why the datasource itself did not move.** `supabase_flutter` is importable
only in `data/` or `core/supabase/` (rule 1). The providers construct the
repository from `supabaseClientProvider` without ever naming a Supabase type,
which is the same move `recipe_providers.dart` already made.

**Compromise worth naming.** `IngredientLineField` still operates on
`RecipeDraftLine`, so `core/` now depends on `features/recipes/domain/`. Legal,
and better than inventing a core-owned line type — that would be a second model
of the same thing to satisfy a naming instinct.

**Consequence.** A second cross-feature channel appeared for the same reason:
`ref.invalidate(recipeListProvider)` worked while recipes was the only feature
that wrote a recipe, and the confirm screen is the second. Both writers now bump
a counter in `core/refresh/data_revision.dart`.
