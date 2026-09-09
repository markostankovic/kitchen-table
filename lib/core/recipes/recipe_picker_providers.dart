/// Recipe search for the meal plan's picker (D53).
///
/// Lives in `core/` for the same reason `core/ingredients/` does (D43):
/// `features/meal_plan/presentation/` may not import
/// `features/recipes/application/`, and duplicating `RecipeRepository.search`
/// here -- its `title_normalized` predicate, its `deleted_at` filter, its
/// `TextNormalizer` hop -- would be D33's mistake made again one phase after
/// D43 undid it. `core/` is outside the feature rule entirely (`_featureOf`
/// only matches `lib/features/<x>/<layer>/`), which is what lets this file
/// reach into `features/recipes/data/`. It deliberately does not name a
/// Supabase type, so `supabase_flutter` stays confined to `data/` and
/// `core/supabase/` (rule 1).
///
/// A separate provider from `recipeRepositoryProvider` rather than reusing
/// it: `RecipeRepository` is a stateless wrapper over the client, so a second
/// instance costs nothing, and it keeps this file's dependency on the recipes
/// feature to its `data/` and `domain/` layers only, not its `application/`.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/recipes/data/recipe_repository.dart';
import '../../features/recipes/domain/recipe.dart';
import '../refresh/data_revision.dart';
import '../supabase/supabase_client.dart';

part 'recipe_picker_providers.g.dart';

@Riverpod(keepAlive: true)
RecipeRepository plannableRecipeSource(Ref ref) =>
    RecipeRepository(ref.watch(supabaseClientProvider));

/// Recipes the cook can drop into a slot, searchable the same way the recipe
/// list is -- diacritic- and case-insensitive, via `title_normalized`.
///
/// Watches [recipesRevisionProvider] so a recipe created moments ago (from
/// this screen or the recipes tab) shows up without a manual refresh.
@riverpod
Future<List<Recipe>> plannableRecipes(Ref ref, {String query = ''}) {
  ref.watch(recipesRevisionProvider);
  return ref.watch(plannableRecipeSourceProvider).search(query);
}
