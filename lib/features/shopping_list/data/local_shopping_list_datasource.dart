/// Shopping list access to the offline cache. The other half of
/// `ShoppingListRepository`'s Remote/Local split (D64) -- table and column
/// members come from [AppDatabase] itself, so nothing here needs its own
/// `package:drift` import to stay within CLAUDE.md rule 1 / `core/db/`
/// (`tool/check_layers.dart` cares about the boundary this file sits inside,
/// not about which file spells the import).
///
/// Every method is wrapped in [cacheOrElse]/[cacheWrite]: a cache failure is
/// a miss, never a read failure or a write failure (D69).
library;

import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/db/cache_guard.dart';
import '../domain/shopping_list.dart';
import 'dto/shopping_list_dto.dart';

class LocalShoppingListDataSource {
  const LocalShoppingListDataSource(this._db);

  final AppDatabase _db;

  /// The household's cached list, or null on a miss -- no row cached yet, or
  /// a cache failure of any kind.
  Future<ShoppingList?> readLatest({required String householdId}) =>
      cacheOrElse('shopping_list read', () async {
        final ShoppingListCacheData? row = await (_db.select(
          _db.shoppingListCache,
        )..where((t) => t.householdId.equals(householdId))).getSingleOrNull();
        if (row == null) return null;
        return shoppingListFromWire(
          jsonDecode(row.data) as Map<String, dynamic>,
        );
      }, null);

  /// Replaces the household's cached list with [list]: deletes whatever row
  /// this household already has, then inserts the new one, in one
  /// transaction.
  ///
  /// Deliberately not `insertOnConflictUpdate` on its own -- that resolves a
  /// conflict on the PRIMARY KEY (the list's own `id`), so a genuine
  /// regeneration (a new `id` replacing an old one, the ordinary case
  /// `ShoppingListRepository.watchLatest` writes through on every successful
  /// network read) would try to INSERT a second row for a household that
  /// already has one, tripping [ShoppingListCache.uniqueKeys] instead of
  /// replacing anything. Delete-then-insert makes "one row per household"
  /// this method's own guarantee, not a discipline every caller has to keep
  /// (D66).
  Future<void> upsertLatest({
    required String householdId,
    required ShoppingList list,
  }) => cacheWrite('shopping_list write', () => _db.transaction(() async {
    await (_db.delete(
      _db.shoppingListCache,
    )..where((t) => t.householdId.equals(householdId))).go();
    await _db
        .into(_db.shoppingListCache)
        .insert(
          ShoppingListCacheCompanion.insert(
            id: list.id,
            householdId: householdId,
            generatedAt: list.generatedAt,
            updatedAt: list.updatedAt,
            data: jsonEncode(list.toWire()),
          ),
        );
  }));

  /// Drops the cached list with this id, by primary key. Called whenever the
  /// server has retired a list -- `ShoppingListRepository.softDelete`, and
  /// `watchLatest` reconciling a cache hit against a network read that came
  /// back with nothing -- so an offline read afterwards can never serve a
  /// list the server no longer has.
  Future<void> evict(String id) => cacheWrite('shopping_list evict', () async {
    await (_db.delete(_db.shoppingListCache)..where((t) => t.id.equals(id))).go();
  });
}
