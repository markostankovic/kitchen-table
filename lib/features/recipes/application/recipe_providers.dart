import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/household/current_household.dart';
import '../../../core/net/network_status.dart';
import '../../../core/refresh/data_revision.dart';
import '../../../core/supabase/supabase_client.dart';
import '../data/local_recipe_datasource.dart';
import '../data/recipe_repository.dart';
import '../data/remote_recipe_datasource.dart';
import '../domain/recipe.dart';
import '../domain/recipe_detail.dart';
import '../domain/recipe_tag.dart';

part 'recipe_providers.g.dart';

@Riverpod(keepAlive: true)
RecipeRepository recipeRepository(Ref ref) => RecipeRepository(
  RemoteRecipeDataSource(ref.watch(supabaseClientProvider)),
  LocalRecipeDataSource(ref.watch(appDatabaseProvider)),
);

/// The household's recipes, matching [query] -- cache immediately, then the
/// network (Phase 2 part 6a, D67's shape widened from one row to many).
///
/// A `Stream`, not a `Future`, on `CurrentShoppingList`'s own precedent:
/// `watchList` emits a cached list immediately, then the network's answer,
/// and a `StreamNotifier` is what lets the second emission be part of the
/// provider's own lifecycle. The value type consumers see
/// (`AsyncValue<List<Recipe>>`) is unchanged from the old `Future`-based
/// provider.
///
/// Still a family, and still not `keepAlive`: one entry per query string,
/// disposed when nothing watches it, exactly as before -- the screen
/// debounces.
///
/// Watches [recipesRevisionProvider] so that any feature can invalidate this
/// without importing it -- which `features/import/` cannot do. `build()`
/// yields an empty list rather than reaching the repository at all when
/// there is no household, so a household-less caller never touches
/// `Supabase.instance.client` (the shell's tab loop relies on exactly this
/// under test, `CurrentShoppingList`'s own reasoning).
@riverpod
class RecipeList extends _$RecipeList {
  @override
  Stream<List<Recipe>> build({
    String query = '',
    String tag = '',
    bool favoritesOnly = false,
  }) async* {
    ref.watch(recipesRevisionProvider);

    final String? householdId = await ref.watch(
      currentHouseholdIdProvider.future,
    );
    if (householdId == null) {
      yield const <Recipe>[];
      return;
    }

    final NetworkStatus status = ref.read(networkStatusProvider.notifier);
    yield* ref
        .watch(recipeRepositoryProvider)
        .watchList(
          householdId: householdId,
          query: query,
          tag: tag,
          favoritesOnly: favoritesOnly,
          onReachable: status.reportReachable,
          onUnreachable: status.reportUnreachable,
        );
  }
}

/// The household's tag vocabulary, derived from the unfiltered recipe list
/// (Phase 5, part 2) so chips don't vanish as the list is narrowed.
///
/// Synchronous on purpose: while [recipeListProvider] is loading or errored
/// there is no data to derive a vocabulary from, `value` is null, and the
/// empty list [RecipeTag.vocabularyOf] gets back is the right rendering for
/// both -- the chip row simply isn't there.
@riverpod
List<RecipeTag> recipeTags(Ref ref) => RecipeTag.vocabularyOf(
      ref.watch(recipeListProvider()).value ?? const <Recipe>[],
    );

/// [locale]'s tag-key -> name map for the current household (Phase 6, part
/// 1a) -- `RecipeTag.relabelled`'s second argument.
///
/// `build()` yields the empty map rather than reaching the repository at
/// all when there is no household, [RecipeList.build]'s own guard shape,
/// for the same reason: a household-less caller must never touch
/// `Supabase.instance.client`.
@riverpod
Future<Map<String, String>> tagLabels(Ref ref, String locale) async {
  // A pair minted by `translate-tags` after the save that triggered it has
  // no other way to reach the chips already on screen -- [RecipeList.build]
  // watches the same provider, two providers up, for the same reason
  // (Phase 6, part 1b).
  ref.watch(recipesRevisionProvider);

  final String? householdId = await ref.watch(
    currentHouseholdIdProvider.future,
  );
  if (householdId == null) return const <String, String>{};

  final Map<String, Map<String, String>> byLocale = await ref
      .watch(recipeRepositoryProvider)
      .fetchTagLabels(householdId);
  return byLocale[locale] ?? const <String, String>{};
}

/// One recipe with its lines and steps, names resolved from the catalog.
///
/// Stays a plain `Future` (D74): network-first with a cache fallback on
/// `NetworkFailure`, the same one-emission shape
/// `IngredientRepository.fetchUnitCatalog()` uses, not the two-emission
/// stream [RecipeList] uses. See `RecipeRepository.fetchDetail`'s own doc
/// comment for why a single recipe differs from the whole list.
@riverpod
Future<RecipeDetail> recipeDetail(Ref ref, String recipeId,
        {String locale = 'sr'}) =>
    ref.watch(recipeRepositoryProvider).fetchDetail(recipeId, locale: locale);
