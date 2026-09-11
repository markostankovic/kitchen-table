/// Ingredient catalog access to the offline cache -- table and column
/// members come from [AppDatabase] itself, so nothing here needs its own
/// `package:drift` import to stay within CLAUDE.md rule 1 / `core/db/`.
///
/// Named for the feature, not for `UnitCatalogRows` alone: part 6 widens this
/// file for the ingredient name catalog and search rather than replacing it,
/// the same way `RemoteShoppingListDataSource`/`LocalShoppingListDataSource`
/// hold every read this feature caches.
///
/// Every method is wrapped in [cacheOrElse]/[cacheWrite]: a cache failure is
/// a miss, never a read failure or a write failure (D69).
library;

import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/db/cache_guard.dart';
import 'dto/unit_catalog_dto.dart';

class LocalIngredientDataSource {
  const LocalIngredientDataSource(this._db);

  final AppDatabase _db;

  /// The cached unit lexicon, or null on a miss -- nothing cached yet, or a
  /// cache failure of any kind.
  Future<UnitCatalogRows?> readUnitCatalog() =>
      cacheOrElse('unit_catalog read', () async {
        final UnitCatalogCacheData? row = await (_db.select(
          _db.unitCatalogCache,
        )..where((t) => t.id.equals(unitCatalogCacheKey))).getSingleOrNull();
        if (row == null) return null;
        return unitCatalogRowsFromWire(
          jsonDecode(row.data) as Map<String, dynamic>,
        );
      }, null);

  /// Replaces the one cached row wholesale. There is nothing to evict and
  /// nothing to scope by household -- [UnitCatalogCache] always holds
  /// exactly one row, keyed by [unitCatalogCacheKey].
  Future<void> writeUnitCatalog(UnitCatalogRows rows) =>
      cacheWrite('unit_catalog write', () async {
        await _db
            .into(_db.unitCatalogCache)
            .insertOnConflictUpdate(
              UnitCatalogCacheCompanion.insert(
                id: unitCatalogCacheKey,
                fetchedAt: DateTime.now().toUtc(),
                data: jsonEncode(unitCatalogRowsToWire(rows)),
              ),
            );
      });
}
