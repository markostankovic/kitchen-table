/// The offline read cache (D12, Phase 2 part 5).
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
/// actually needs -- `household_id` to scope by, `updated_at` for a later
/// delta fetch. What goes inside the blob and how it decodes is entirely the
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

@DriftDatabase(tables: <Type>[ShoppingListCache, UnitCatalogCache])
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
  @override
  int get schemaVersion => 1;

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

  /// Drops every household-scoped row.
  ///
  /// Called on sign-out, and must never block it or surface a failure of its
  /// own -- a corrupt cache file is not a reason to fail signing out, so this
  /// uses [cacheWrite] rather than letting a drift exception propagate.
  /// [UnitCatalogCache] is deliberately not touched here -- it is global
  /// reference data, readable by any authenticated user, and wiping it would
  /// put `3 clove` back on the very first offline session after the next
  /// person signs in (D70).
  Future<void> clearHouseholdCache() =>
      cacheWrite('household clear', () => transaction(() async {
            await delete(shoppingListCache).go();
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
