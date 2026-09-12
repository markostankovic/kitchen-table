/// Meal plan access to the offline cache -- the Local half of
/// `MealPlanRepository`'s split (Phase 2 part 6b, on
/// `LocalRecipeDataSource`'s precedent, D64).
///
/// Every method is wrapped in [cacheOrElse]/[cacheWrite]: a cache failure is
/// a miss, never a read failure or a write failure (D69).
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/cache_guard.dart';
import '../../../core/db/sync_watermark.dart';
import '../domain/meal_plan_week.dart';
import '../domain/plan_week.dart';
import 'dto/meal_plan_week_dto.dart';

/// The delta-fetch entity name meal plan weeks are cached under (D72, D75).
/// One watermark per household, covering every week that household has ever
/// written into -- not one per `(household, week)`, see D75.
const String mealPlanSyncEntity = 'meal_plans';

class LocalMealPlanDataSource {
  LocalMealPlanDataSource(this._db) : _watermark = SyncWatermarkStore(_db);

  final AppDatabase _db;
  final SyncWatermarkStore _watermark;

  Future<DateTime?> readWeeksWatermark(String householdId) =>
      _watermark.read(entity: mealPlanSyncEntity, scope: householdId);

  Future<void> advanceWeeksWatermark(
    String householdId,
    DateTime syncedAt,
  ) => _watermark.advance(
    entity: mealPlanSyncEntity,
    scope: householdId,
    syncedAt: syncedAt,
  );

  /// One cached week, or null on a miss. A miss is ambiguous on its own --
  /// "never synced" and "synced, genuinely empty" look identical from this
  /// method alone -- which is why [MealPlanRepository.watchWeek] checks
  /// [readWeeksWatermark] itself rather than asking this to decide (D75).
  Future<MealPlanWeek?> readWeek({
    required String householdId,
    required PlanWeek week,
  }) =>
      cacheOrElse('meal_plan read', () async {
        final MealPlanWeekCacheData? row = await (_db.select(
          _db.mealPlanWeekCache,
        )..where(
              (MealPlanWeekCache t) =>
                  t.householdId.equals(householdId) &
                  t.weekStart.equals(week.isoDate),
            ))
            .getSingleOrNull();
        if (row == null) return null;
        return mealPlanWeekFromWire(
          jsonDecode(row.data) as Map<String, dynamic>,
        );
      }, null);

  /// Replaces every named row wholesale -- an upsert keyed on the primary
  /// key (`id`), on [LocalRecipeDataSource.upsertMany]'s precedent: a plan's
  /// id never changes underneath it (`ensure_meal_plan`'s `on conflict ...
  /// do update ... returning id` guarantees that), so there is no second row
  /// to collide with and [ShoppingListCache]'s delete-then-insert dance is
  /// not needed here.
  Future<void> upsertMany({
    required String householdId,
    required List<Map<String, dynamic>> rows,
  }) => cacheWrite('meal_plan upsert', () async {
    await _db.batch((Batch batch) {
      batch.insertAllOnConflictUpdate(
        _db.mealPlanWeekCache,
        <MealPlanWeekCacheCompanion>[
          for (final Map<String, dynamic> row in rows)
            MealPlanWeekCacheCompanion.insert(
              id: row['id'] as String,
              householdId: householdId,
              weekStart: row['week_start'] as String,
              updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
              data: jsonEncode(row),
            ),
        ],
      );
    });
  });

  Future<void> evict(String id) => cacheWrite('meal_plan evict', () async {
    await (_db.delete(
      _db.mealPlanWeekCache,
    )..where((MealPlanWeekCache t) => t.id.equals(id))).go();
  });
}
