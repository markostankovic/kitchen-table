/// Recipe search for the meal plan's picker (D53).
///
/// Lives in `core/` for the same reason `core/ingredients/` does (D43):
/// `features/meal_plan/presentation/` may not import
/// `features/recipes/application/`, and duplicating `RecipeRepository`'s
/// search logic here would be D33's mistake made again one phase after D43
/// undid it. `core/` is outside the feature rule entirely (`_featureOf`
/// only matches `lib/features/<x>/<layer>/`), which is what lets this file
/// reach into `features/recipes/data/`. It deliberately does not name a
/// Supabase or drift type, so both stay confined to their sanctioned spots
/// (rule 1, D64).
///
/// A separate provider from `recipeRepositoryProvider` rather than reusing
/// it: `RecipeRepository` is a stateless wrapper over its two datasources,
/// so a second instance costs nothing beyond one extra `AppDatabase`
/// reference (already `keepAlive`, so no second connection), and it keeps
/// this file's dependency on the recipes feature to its `data/` and
/// `domain/` layers only, not its `application/`.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/recipes/data/local_recipe_datasource.dart';
import '../../features/recipes/data/recipe_repository.dart';
import '../../features/recipes/data/remote_recipe_datasource.dart';
import '../../features/recipes/domain/recipe.dart';
import '../db/app_database.dart';
import '../household/current_household.dart';
import '../refresh/data_revision.dart';
import '../supabase/supabase_client.dart';

part 'recipe_picker_providers.g.dart';

@Riverpod(keepAlive: true)
RecipeRepository plannableRecipeSource(Ref ref) => RecipeRepository(
  RemoteRecipeDataSource(ref.watch(supabaseClientProvider)),
  LocalRecipeDataSource(ref.watch(appDatabaseProvider)),
);

/// Recipes the cook can drop into a slot, searchable the same way the recipe
/// list is -- diacritic- and case-insensitive, via `TextNormalizer`.
///
/// One answer, not two emissions (`RecipeRepository.searchOnce`): a bottom
/// sheet has no "showing your saved copy" line to drive, and adding a
/// recipe to a slot needs the network regardless (D54), so there is
/// nothing here for a second, fresher emission to improve on mid-pick.
///
/// Watches [recipesRevisionProvider] so a recipe created moments ago (from
/// this screen or the recipes tab) shows up without a manual refresh.
@riverpod
Future<List<Recipe>> plannableRecipes(Ref ref, {String query = ''}) async {
  ref.watch(recipesRevisionProvider);

  final String? householdId =
      await ref.watch(currentHouseholdIdProvider.future);
  if (householdId == null) return const <Recipe>[];

  return ref
      .watch(plannableRecipeSourceProvider)
      .searchOnce(householdId: householdId, query: query);
}
