import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../ingredients/domain/ingredient_line_parser.dart';
import '../../ingredients/domain/ingredient_match.dart';
import '../../ingredients/domain/unit_catalog.dart';
import '../data/ingredient_catalog_datasource.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import '../domain/recipe_detail.dart';

part 'recipe_providers.g.dart';

@Riverpod(keepAlive: true)
RecipeRepository recipeRepository(Ref ref) =>
    RecipeRepository(ref.watch(supabaseClientProvider));

/// See the file header of `data/ingredient_catalog_datasource.dart`: this is
/// the recipes-side copy of catalog access that D33 chose to pay for.
@Riverpod(keepAlive: true)
IngredientCatalogDatasource ingredientCatalogDatasource(Ref ref) =>
    IngredientCatalogDatasource(ref.watch(supabaseClientProvider));

/// Recipes in the caller's household, filtered by [query].
///
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

/// The unit lexicon, fetched once.
///
/// `keepAlive` is justified for the same reason the ingredients feature gives:
/// roughly 120 immutable rows that only a migration changes, read on every
/// ingredient line the user touches. Dropping it when the editor closes would
/// mean a round trip every time it reopens, for data that cannot have changed.
@Riverpod(keepAlive: true)
Future<UnitCatalog> recipeUnitCatalog(Ref ref) =>
    ref.watch(ingredientCatalogDatasourceProvider).fetchUnitCatalog();

/// Tier 1, ready to use: the pure parser with its lexicon already injected, so
/// no screen has to know that parsing depends on a fetch (D31).
@Riverpod(keepAlive: true)
Future<IngredientLineParser> recipeLineParser(Ref ref) async =>
    IngredientLineParser(await ref.watch(recipeUnitCatalogProvider.future));

/// Tiers 2 and 3, for the line editor's autocomplete. Callers debounce.
@riverpod
Future<List<IngredientMatch>> ingredientMatches(
  Ref ref,
  String query, {
  String locale = 'sr',
}) =>
    ref.watch(ingredientCatalogDatasourceProvider).search(query, locale: locale);
