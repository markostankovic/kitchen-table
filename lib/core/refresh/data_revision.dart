/// Cross-feature "this changed" signals.
///
/// `ref.invalidate(recipeListProvider)` is the obvious way to refresh a list
/// after a write, and it is what `RecipeEditor.save()` did while recipes was
/// the only feature that wrote a recipe. Phase 1d added a second: the import
/// confirm screen (D8) also creates recipes, and `features/import/` may not
/// import `features/recipes/application/` -- cross-feature imports go through
/// `domain/` only.
///
/// So the signal moves to `core/`, where both can reach it, for the same
/// reason `currentUserIdProvider` lives there. A counter rather than a stream
/// of events: nothing needs to know WHAT changed, only that the answer it is
/// holding is old.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'data_revision.g.dart';

/// Bumped whenever a recipe is created, edited or deleted.
///
/// `keepAlive` because it outlives every screen that watches it -- that is the
/// entire point. It is an int, so keeping it costs nothing.
@Riverpod(keepAlive: true)
class RecipesRevision extends _$RecipesRevision {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}

/// Bumped whenever a meal plan entry is added, moved, edited or removed.
///
/// One consumer today -- `MealPlanEditor` re-reading the visible week after
/// its own writes -- but the reason this lives here rather than inside
/// `features/meal_plan/application/` is the same one `RecipesRevision` was
/// moved here for: a later Phase 2 part's shopping list aggregates a week's
/// entries and will need to know when that week has changed, and
/// `features/shopping_list/` may not import `features/meal_plan/application/`.
@Riverpod(keepAlive: true)
class MealPlanRevision extends _$MealPlanRevision {
  @override
  int build() => 0;

  void bump() => state = state + 1;
}
