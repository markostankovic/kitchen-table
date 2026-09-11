/// Reads and advances a [SyncWatermarks] row -- one per (entity, scope),
/// D72. This is the piece D71 deferred: "the decisions that matter ... are
/// only answerable with a real multi-row fetch in front of them." The
/// ingredient name catalog and recipes are that fetch.
///
/// Every method goes through [cacheOrElse]/[cacheWrite] (D69): a watermark
/// read that fails is treated as "no watermark", which means a full fetch --
/// slower, never wrong. A watermark write that fails costs one more full
/// fetch next time and nothing else.
library;

import 'package:drift/drift.dart';

import 'app_database.dart';
import 'cache_guard.dart';

class SyncWatermarkStore {
  const SyncWatermarkStore(this._db);

  final AppDatabase _db;

  /// The last successful sync time for [entity]/[scope], or null if none has
  /// ever completed (or the read itself failed) -- either way, the caller's
  /// correct move is to fetch everything.
  Future<DateTime?> read({
    required String entity,
    required String scope,
  }) => cacheOrElse('sync_watermark read ($entity/$scope)', () async {
    final SyncWatermark? row = await (_db.select(_db.syncWatermarks)
          ..where(
            (SyncWatermarks t) => t.entity.equals(entity) & t.scope.equals(scope),
          ))
        .getSingleOrNull();
    // Drift round-trips a DateTime column through a local-time epoch
    // conversion, so what comes back has the right instant but `isUtc:
    // false` -- and `DateTime.==` treats a UTC and a local DateTime at the
    // identical instant as unequal. Every watermark this store ever writes
    // is UTC (see [advance]), so normalising back on the way out is always
    // correct, never a guess.
    return row?.syncedAt.toUtc();
  }, null);

  /// Advances the watermark to [syncedAt] -- the max(`updated_at`) of the
  /// rows a fetch actually received, computed by the caller. Never pass
  /// `DateTime.now()`: the server's clock and the phone's differ, and a
  /// local clock silently drops every row written in the gap between "the
  /// fetch started" and "the fetch's own wall-clock stamp" (D71).
  ///
  /// A caller whose delta came back empty should not call this at all --
  /// there is nothing to advance to, and leaving the watermark where it was
  /// is correct, not a missed update.
  Future<void> advance({
    required String entity,
    required String scope,
    required DateTime syncedAt,
  }) => cacheWrite(
    'sync_watermark advance ($entity/$scope)',
    () => _db
        .into(_db.syncWatermarks)
        .insertOnConflictUpdate(
          SyncWatermarksCompanion.insert(
            entity: entity,
            scope: scope,
            syncedAt: syncedAt.toUtc(),
          ),
        ),
  );
}
