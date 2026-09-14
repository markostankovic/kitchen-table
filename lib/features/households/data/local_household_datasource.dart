/// The caller's own current household, cached offline (D87, D88) -- table
/// and column members come from [AppDatabase] itself, so nothing here needs
/// its own `package:drift` import to stay within CLAUDE.md rule 1 / `core/db/`
/// (`local_ingredient_datasource.dart`'s own precedent).
///
/// Every method is wrapped in [cacheOrElse]/[cacheWrite]: a cache failure is
/// a miss, never a read failure or a write failure (D69).
library;

import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/db/cache_guard.dart';

class LocalHouseholdDataSource {
  const LocalHouseholdDataSource(this._db);

  final AppDatabase _db;

  /// [userId]'s cached current household, as the raw wire row -- or null on
  /// a miss, including the honest miss of a user this cache has never seen.
  Future<Map<String, dynamic>?> readCurrent(String userId) =>
      cacheOrElse('household readCurrent', () async {
        final CurrentHouseholdCacheData? row = await (_db.select(
          _db.currentHouseholdCache,
        )..where((CurrentHouseholdCache t) => t.userId.equals(userId)))
            .getSingleOrNull();
        if (row == null) return null;
        return jsonDecode(row.data) as Map<String, dynamic>;
      }, null);

  /// Replaces [userId]'s cached row wholesale. `insertOnConflictUpdate` on
  /// the primary key -- [userId] IS the conflict target, so there is no
  /// second row to collide with and no delete-then-insert dance
  /// ([ShoppingListCache]'s D66 case does not apply here).
  Future<void> writeCurrent(String userId, Map<String, dynamic> row) =>
      cacheWrite('household writeCurrent', () async {
        await _db.into(_db.currentHouseholdCache).insertOnConflictUpdate(
              CurrentHouseholdCacheCompanion.insert(
                userId: userId,
                data: jsonEncode(row),
                fetchedAt: DateTime.now().toUtc(),
              ),
            );
      });

  /// Removes [userId]'s cached row -- called when a fetch succeeds and
  /// answers "no household", so a stale row can never be mistaken for a
  /// current one (`HouseholdRepository.fetchCurrent`'s own null branch).
  Future<void> clearCurrent(String userId) =>
      cacheWrite('household clearCurrent', () async {
        await (_db.delete(_db.currentHouseholdCache)
              ..where((CurrentHouseholdCache t) => t.userId.equals(userId)))
            .go();
      });

  /// Empties the whole table -- called on a successful `create`/
  /// `redeemInvite`, so a network blip on the very next read cannot
  /// resurrect the household the caller just left (D88's own named failure
  /// mode).
  Future<void> clearAll() =>
      cacheWrite('household clearAll', () async {
        await _db.delete(_db.currentHouseholdCache).go();
      });
}
