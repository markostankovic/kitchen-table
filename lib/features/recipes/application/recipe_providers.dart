import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import '../domain/recipe_detail.dart';

part 'recipe_providers.g.dart';

@Riverpod(keepAlive: true)
RecipeRepository recipeRepository(Ref ref) =>
    RecipeRepository(ref.watch(supabaseClientProvider));

/// Not `keepAlive`: one entry per query string, and the family would grow
/// without bound as somebody types. The screen debounces.
@riverpod
Future<List<Recipe>> recipeList(Ref ref, {String query = ''}) =>
    ref.watch(recipeRepositoryProvider).search(query);

/// One recipe with its lines and steps, names resolved from the catalog.
@riverpod
Future<RecipeDetail> recipeDetail(Ref ref, String recipeId,
        {String locale = 'sr'}) =>
    ref.watch(recipeRepositoryProvider).fetchDetail(recipeId, locale: locale);
