/// Recipe access to the offline cache -- the Local half of
/// `RecipeRepository`'s split (Phase 2 part 6a, on
/// `LocalShoppingListDataSource`'s precedent, D64).
///
/// Also holds the global ingredient-name cache -- `IngredientNameCache` and
/// its watermark -- even though the table itself lives in the shared
/// `AppDatabase`. **This is a deliberate ownership choice, D73, not an
/// oversight**: `ingredient_display_names` has exactly one caller today
/// (`RecipeRepository`), and `tool/check_layers.dart` forbids
/// `features/recipes/data/` from importing `features/ingredients/data/`
/// directly (D33) -- the same wall Phase 1c hit before D43 moved the
/// catalog to `core/ingredients/`. `core/` cannot hold this either: it may
/// import `package:drift` only from `data/` or `core/db/`, and
/// `supabase_flutter` only from `data/` or `core/supabase/`, so a
/// cross-feature `core/` helper could do the resolve but never the sync.
/// Rather than split one round trip across two files for a rule with no
/// second caller to justify it, the whole thing stays here, self-contained,
/// on D43's own precedent: **a third caller is the signal to move it to
/// `core/ingredients/`, not the first one.**
///
/// Every method is wrapped in [cacheOrElse]/[cacheWrite]: a cache failure is
/// a miss, never a read failure or a write failure (D69).
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/cache_guard.dart';
import '../../../core/db/sync_watermark.dart';
import '../../../core/text/text_normalizer.dart';
import '../../ingredients/domain/display_name_chain.dart';
import '../domain/recipe.dart';
import 'dto/recipe_dto.dart';

/// The delta-fetch entity name recipes are cached under (D72).
const String recipeSyncEntity = 'recipes';

/// The delta-fetch entity name the global ingredient name catalog is cached
/// under (D72, D73).
const String ingredientNamesSyncEntity = 'ingredient_names';

class LocalRecipeDataSource {
  LocalRecipeDataSource(this._db) : _watermark = SyncWatermarkStore(_db);

  final AppDatabase _db;
  final SyncWatermarkStore _watermark;

  // -- Recipes -------------------------------------------------------------

  Future<DateTime?> readRecipesWatermark(String householdId) =>
      _watermark.read(entity: recipeSyncEntity, scope: householdId);

  Future<void> advanceRecipesWatermark(
    String householdId,
    DateTime syncedAt,
  ) => _watermark.advance(
    entity: recipeSyncEntity,
    scope: householdId,
    syncedAt: syncedAt,
  );

  /// Every cached, non-deleted recipe for [householdId], newest-`updatedAt`
  /// first -- deliberately not the server's `created_at` ordering, because
  /// the cache does not carry that column; the visible difference is a
  /// recipe that was just edited moving to the top of an offline list,
  /// which is a reasonable reading of "recent" rather than a bug.
  Future<List<Recipe>> readAll({required String householdId}) =>
      cacheOrElse('recipe readAll', () async {
        final List<RecipeCacheData> rows = await (_db.select(
          _db.recipeCache,
        )..where((RecipeCache t) => t.householdId.equals(householdId))
              ..orderBy(<
                  OrderingTerm Function(RecipeCache)>[
                (RecipeCache t) => OrderingTerm.desc(t.updatedAt),
              ]))
            .get();
        return rows
            .map(
              (RecipeCacheData row) =>
                  recipeFromWire(jsonDecode(row.data) as Map<String, dynamic>),
            )
            .toList();
      }, const <Recipe>[]);

  /// One cached recipe's full wire row (recipe fields plus embedded lines
  /// and steps), or null on a miss -- including the honest miss of a row
  /// that IS cached but only from a list-level sync that never embedded
  /// lines and steps (checked by the caller via [hasEmbeddedLines]).
  Future<Map<String, dynamic>?> readOne(String id) =>
      cacheOrElse('recipe readOne', () async {
        final RecipeCacheData? row = await (_db.select(
          _db.recipeCache,
        )..where((RecipeCache t) => t.id.equals(id))).getSingleOrNull();
        if (row == null) return null;
        return jsonDecode(row.data) as Map<String, dynamic>;
      }, null);

  /// Replaces every named row wholesale -- an upsert keyed on the primary
  /// key (`id`), unlike [ShoppingListCache]'s delete-then-insert: a recipe's
  /// id never changes underneath it the way a regenerated shopping list's
  /// does, so there is no second row to collide with (D66's dance is not
  /// needed here).
  Future<void> upsertMany({
    required String householdId,
    required List<Map<String, dynamic>> rows,
  }) => cacheWrite('recipe upsert', () async {
    await _db.batch((Batch batch) {
      batch.insertAllOnConflictUpdate(
        _db.recipeCache,
        <RecipeCacheCompanion>[
          for (final Map<String, dynamic> row in rows)
            RecipeCacheCompanion.insert(
              id: row['id'] as String,
              householdId: householdId,
              titleNormalized: TextNormalizer.normalize(row['title'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
              data: jsonEncode(row),
            ),
        ],
      );
    });
  });

  Future<void> evict(String id) => cacheWrite('recipe evict', () async {
    await (_db.delete(_db.recipeCache)..where((RecipeCache t) => t.id.equals(id))).go();
  });

  // -- Ingredient names (D73) ------------------------------------------

  Future<DateTime?> readNamesWatermark() => _watermark.read(
    entity: ingredientNamesSyncEntity,
    scope: globalSyncScope,
  );

  Future<void> advanceNamesWatermark(DateTime syncedAt) => _watermark.advance(
    entity: ingredientNamesSyncEntity,
    scope: globalSyncScope,
    syncedAt: syncedAt,
  );

  Future<void> upsertNames(List<Map<String, dynamic>> rows) =>
      cacheWrite('ingredient_names upsert', () async {
        await _db.batch((Batch batch) {
          batch.insertAllOnConflictUpdate(
            _db.ingredientNameCache,
            <IngredientNameCacheCompanion>[
              for (final Map<String, dynamic> row in rows)
                IngredientNameCacheCompanion.insert(
                  id: row['id'] as String,
                  ingredientId: row['ingredient_id'] as String,
                  name: row['name'] as String,
                  locale: row['locale'] as String,
                  isDisplayName: row['is_display_name'] as bool,
                  createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
                  updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
                  data: jsonEncode(row),
                ),
            ],
          );
        });
      });

  Future<void> evictName(String id) =>
      cacheWrite('ingredient_names evict', () async {
        await (_db.delete(
          _db.ingredientNameCache,
        )..where((IngredientNameCache t) => t.id.equals(id))).go();
      });

  /// The winning display name for every id in [ingredientIds] that has one
  /// cached, via [DisplayNameChain] -- the same chain
  /// `ingredient_display_name()` runs in Postgres, ported for exactly this
  /// call (D72). An id with nothing cached for it is simply absent from the
  /// result; the caller falls back to `raw_text` (rule 3), not an error.
  Future<Map<String, String>> resolveDisplayNames(
    List<String> ingredientIds,
    String locale,
  ) => cacheOrElse('ingredient_names resolve', () async {
    if (ingredientIds.isEmpty) return const <String, String>{};

    final List<IngredientNameCacheData> rows = await (_db.select(
      _db.ingredientNameCache,
    )..where((IngredientNameCache t) => t.ingredientId.isIn(ingredientIds)))
        .get();

    final Map<String, List<IngredientNameRow>> byIngredient =
        <String, List<IngredientNameRow>>{};
    for (final IngredientNameCacheData row in rows) {
      (byIngredient[row.ingredientId] ??= <IngredientNameRow>[]).add(
        IngredientNameRow(
          name: row.name,
          locale: row.locale,
          isDisplayName: row.isDisplayName,
          createdAt: row.createdAt.toUtc(),
        ),
      );
    }

    final Map<String, String> resolved = <String, String>{};
    for (final MapEntry<String, List<IngredientNameRow>> entry
        in byIngredient.entries) {
      final String? winner = DisplayNameChain.resolve(entry.value, locale);
      if (winner != null) resolved[entry.key] = winner;
    }
    return resolved;
  }, const <String, String>{});
}
