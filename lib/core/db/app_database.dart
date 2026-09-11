/// The offline read cache (D12, Phase 2 part 5; widened in part 6a, D72).
///
/// This file and `data/` are the only places `drift` may be imported
/// (CLAUDE.md rule 1, `tool/check_layers.dart`) -- the same exemption
/// `core/supabase/supabase_client.dart` has for `supabase_flutter`, for the
/// same reason: this database is inherently shared across features (D64), so
/// its home cannot be any one feature's `data/` without every other feature
/// importing across the boundary the checker exists to hold.
///
/// The schema here is deliberately NOT a mirror of Postgres
/// (docs/ARCHITECTURE.md, "Offline (Phase 2)"). Each table holds the
/// server's own wire shape as one JSON blob, plus the columns a query
/// actually needs -- `household_id` to scope by, `updated_at` for the delta
/// fetch. What goes inside the blob and how it decodes is entirely the
/// feature's business, in its own `data/` datasource (D65).
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'cache_guard.dart';

part 'app_database.g.dart';

/// The household's current shopping list -- the same "most recently
/// generated live one" that `ShoppingListRepository.fetchLatest` reads.
///
/// `data` holds the server's own wire shape (rows plus embedded items,
/// see `features/shopping_list/data/dto/shopping_list_dto.dart`), so the
/// same decoder that reads a PostgREST response reads a cache hit -- one
/// definition, not a second serialization (D65).
///
/// No `deleted_at` column (D68): a soft delete on the server is a hard
/// delete here. The cache's job is to answer "what would the server show
/// me right now", and the server's own SELECT never returns a tombstone
/// to the UI (D23 keeps tombstones visible to the repository, not to the
/// screen) -- so the cache has nothing to remember once a row is gone,
/// only somewhere to stop having it.
class ShoppingListCache extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  DateTimeColumn get generatedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};

  /// "A household only ever has one live list at a time" is a claim this
  /// feature's `data/` makes in several doc comments; this is what turns it
  /// from a claim into a constraint. `LocalShoppingListDataSource.evict`
  /// runs before every write that could otherwise violate it, so this should
  /// never actually fire -- if it ever does, `cacheWrite` logs and swallows
  /// the violation rather than corrupting `readLatest`'s `getSingleOrNull`.
  @override
  List<Set<Column>> get uniqueKeys => <Set<Column>>[
    <Column<Object>>{householdId},
  ];
}

/// The whole unit lexicon -- always exactly one row.
///
/// `units` and `unit_names` carry no `household_id`, no `updated_at` and no
/// `deleted_at` (docs/DATA_MODEL.md: "two dozen immutable reference rows
/// that only a migration writes, refetched wholesale and cached for a
/// session"). There is nothing to key by and nothing to evict -- a
/// successful network fetch always replaces this one row outright.
class UnitCatalogCache extends Table {
  TextColumn get id => text()();
  DateTimeColumn get fetchedAt => dateTime()();
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};
}

/// The single row [UnitCatalogCache] ever holds.
const String unitCatalogCacheKey = 'units';

/// One global `ingredient_names` row -- household-scoped aliases are never
/// cached, only `household_id is null` rows (Phase 2 part 6a, D72).
///
/// A household alias exists to help ONE household's matcher find an
/// ingredient; it never wins `ingredient_display_name`'s fallback chain,
/// which reads global rows only (migration 4). So only the rows that chain
/// can ever pick belong here -- caching aliases too would cache data that
/// [DisplayNameChain] is defined to ignore.
///
/// [ingredientId], [name], [locale], [isDisplayName] and [createdAt] are
/// extracted -- every field [DisplayNameChain.resolve] needs, so resolving a
/// batch of ids never has to decode `data` on the hot path. `data` still
/// carries the whole row for anything that later wants more than the chain
/// does (Phase 2's admin screen, say), on [ShoppingListCache]'s own
/// precedent of keeping the wire shape even where a query only needs part
/// of it.
class IngredientNameCache extends Table {
  TextColumn get id => text()();
  TextColumn get ingredientId => text()();
  TextColumn get name => text()();
  TextColumn get locale => text()();
  BoolColumn get isDisplayName => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};
}

/// One recipe -- list and detail rendered from the same row (Phase 2 part
/// 6a). `data` carries the wire shape `RecipeRepository` already reads:
/// the recipe's own columns plus embedded `recipe_ingredients` and
/// `recipe_steps` (`dto/recipe_dto.dart`).
///
/// No `imageUrl` in the blob -- it is a signed URL resolved at read time
/// with a 1-hour TTL and never persisted online either (D48); a cached
/// recipe carries `imagePath` and a null `imageUrl`, a state the UI already
/// renders as a placeholder.
class RecipeCache extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text()();
  TextColumn get titleNormalized => text()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get data => text()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};
}

/// A per-(entity, scope) delta-fetch watermark (D72, closing D71's
/// deferral). [scope] is a household id for household-scoped entities, or
/// [globalSyncScope] for reference data with no household of its own --
/// one row per entity per scope, so fetching one household's recipes can
/// never move the ingredient name catalog's watermark or vice versa.
///
/// [syncedAt] must only ever be advanced to the max(`updated_at`) of rows a
/// fetch actually received, never to `DateTime.now()` -- D71's own warning
/// made concrete. The server's clock and the phone's differ, and a local
/// clock would silently drop every row written in the gap between "the
/// fetch started" and "the fetch's own wall-clock stamp". A missing
/// watermark means "fetch everything", which costs a refetch and nothing
/// else -- the same drop-and-recreate tolerance D71 built the rest of this
/// database on. See `sync_watermark.dart`.
class SyncWatermarks extends Table {
  TextColumn get entity => text()();
  TextColumn get scope => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{entity, scope};
}

/// [SyncWatermarks.scope] for an entity with no household of its own -- the
/// ingredient name catalog today.
const String globalSyncScope = '_global';

@DriftDatabase(
  tables: <Type>[
    ShoppingListCache,
    UnitCatalogCache,
    IngredientNameCache,
    RecipeCache,
    SyncWatermarks,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Pass an in-memory executor under test; production code should use
  /// [AppDatabase.new] with no argument.
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _defaultConnection());

  static QueryExecutor _defaultConnection() => driftDatabase(
        name: 'kitchen_table_cache',
        native: const DriftNativeOptions(
          // Not Documents (user-visible, iCloud-backed on iOS) and not the
          // OS cache directory (may be purged precisely when a cook needs it
          // most, standing in a supermarket).
          databaseDirectory: getApplicationSupportDirectory,
        ),
      );

  /// A cache's honest migration strategy is drop-and-refetch, not a
  /// migration history (D71). Supabase is the truth (D12); the cost of a
  /// wrong guess at this schema is one refetch, and every design choice in
  /// this file is allowed to rely on that -- this database can be deleted
  /// at any moment with no data loss.
  ///
  /// Bumped to 2 in part 6a for [IngredientNameCache], [RecipeCache] and
  /// [SyncWatermarks] -- one version bump for the whole part, not one per
  /// table, on the same "ship it now, there is no irreversibility here"
  /// argument D71 made for the table shapes themselves.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) => m.createAll(),
        onUpgrade: (Migrator m, int from, int to) async {
          for (final TableInfo<Table, dynamic> table in allTables) {
            await m.deleteTable(table.actualTableName);
          }
          await m.createAll();
        },
      );

  /// Drops every household-scoped row -- the shopping list, cached recipes,
  /// and any watermark that is not [globalSyncScope].
  ///
  /// Called on sign-out, and must never block it or surface a failure of its
  /// own -- a corrupt cache file is not a reason to fail signing out, so this
  /// uses [cacheWrite] rather than letting a drift exception propagate.
  /// [UnitCatalogCache], [IngredientNameCache] and the global watermark row
  /// are deliberately not touched here -- global reference data, readable by
  /// any authenticated user, and wiping it would put `3 clove` (or a raw
  /// ingredient id where a Serbian name belongs) back on the very first
  /// offline session after the next person signs in (D70).
  Future<void> clearHouseholdCache() =>
      cacheWrite('household clear', () => transaction(() async {
            await delete(shoppingListCache).go();
            await delete(recipeCache).go();
            await (delete(syncWatermarks)
                  ..where((SyncWatermarks t) => t.scope.equals(globalSyncScope).not()))
                .go();
          }));
}

/// `keepAlive`: this owns an open SQLite connection, and reopening it per
/// listener would thrash the file. Never invalidated -- the sign-out wipe
/// above is an explicit call, not a provider rebuild, so two connections can
/// never race over the same file.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final AppDatabase db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
