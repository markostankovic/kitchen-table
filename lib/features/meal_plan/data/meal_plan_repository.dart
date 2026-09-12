/// Meal plan data access, composed from a Remote half (Supabase) and a
/// Local half (the Drift cache) -- `docs/ARCHITECTURE.md`'s "Offline
/// (Phase 2)" split, the fourth outing after the shopping list, the unit
/// catalog and recipes (Phase 2 part 6b).
///
/// This file itself imports neither `supabase_flutter` nor `drift`: rule 1's
/// "the only place `supabase_flutter` may be imported" now belongs to
/// [RemoteMealPlanDataSource], and [LocalMealPlanDataSource] is the drift
/// half. This class only orchestrates the two.
library;

import '../../../core/error/app_failure.dart';
import '../domain/meal_plan_week.dart';
import '../domain/meal_slot.dart';
import '../domain/plan_week.dart';
import 'local_meal_plan_datasource.dart';
import 'remote_meal_plan_datasource.dart';

class MealPlanRepository {
  const MealPlanRepository(this._remote, this._local);

  final RemoteMealPlanDataSource _remote;
  final LocalMealPlanDataSource _local;

  /// The household's plan for [week], cache immediately then the network --
  /// the same shape `RecipeRepository.watchList` established (D67, D74),
  /// widened from one row to a whole household's meal-plan history so
  /// paging between weeks stays instant and correct offline (D75).
  ///
  /// The watermark is per-household, not per-week (D75): once
  /// [LocalMealPlanDataSource.readWeeksWatermark] is non-null, a full sync
  /// has happened, so a cache miss for the requested week is an
  /// authoritative "this week is empty" (D50's lazily-created plan row),
  /// not "we never looked" -- the same distinction a cold cache and a truly
  /// empty household draw for `RecipeRepository.watchList`.
  ///
  /// A cache hit outlives a [NetworkFailure]; a cold cache does not -- an
  /// honest "no connection, and nothing saved yet" beats an empty week that
  /// implies nothing was ever planned (matches
  /// `RecipeRepository.watchList`'s own rule).
  Stream<MealPlanWeek> watchWeek({
    required String householdId,
    required PlanWeek week,
    void Function()? onReachable,
    void Function()? onUnreachable,
  }) async* {
    final DateTime? since = await _local.readWeeksWatermark(householdId);
    final MealPlanWeek? cached = await _local.readWeek(
      householdId: householdId,
      week: week,
    );

    if (cached != null) {
      yield cached;
    } else if (since != null) {
      // A watermark exists: the household has been fully synced at least
      // once, so an absent week is genuinely empty, not merely unseen.
      yield MealPlanWeek.empty(week);
    }

    try {
      final List<Map<String, dynamic>> changed = await _remote
          .fetchChangedSince(householdId: householdId, since: since);

      if (changed.isNotEmpty) {
        await _applyWeekDelta(householdId, changed, since);
      }

      onReachable?.call();
      final MealPlanWeek fresh =
          await _local.readWeek(householdId: householdId, week: week) ??
              MealPlanWeek.empty(week);
      yield fresh;
    } on NetworkFailure catch (e) {
      onUnreachable?.call();
      // Something was already emitted above -- either a cache hit, or (with
      // a live watermark) an authoritative empty week -- so this can return
      // quietly rather than error the stream.
      if (cached != null || since != null) return;
      throw NetworkFailure(
        message: 'No connection, and no saved plan on this phone yet.',
        cause: e.cause,
      );
    }
  }

  /// Adds a recipe to one slot of one day. Online-only (D12).
  Future<void> addRecipeEntry({
    required String householdId,
    required PlanWeek week,
    required DateTime entryDate,
    required MealSlot slot,
    required String recipeId,
  }) => _remote.addRecipeEntry(
    householdId: householdId,
    week: week,
    entryDate: entryDate,
    slot: slot,
    recipeId: recipeId,
  );

  /// Adds a note to one slot of one day. Online-only (D12).
  Future<void> addNoteEntry({
    required String householdId,
    required PlanWeek week,
    required DateTime entryDate,
    required MealSlot slot,
    required String note,
  }) => _remote.addNoteEntry(
    householdId: householdId,
    week: week,
    entryDate: entryDate,
    slot: slot,
    note: note,
  );

  /// Moves an existing entry to a different day and/or slot. Online-only
  /// (D12).
  Future<void> moveEntry({
    required String entryId,
    required DateTime entryDate,
    required MealSlot slot,
  }) => _remote.moveEntry(entryId: entryId, entryDate: entryDate, slot: slot);

  /// Sets how many people one planned meal is for, or clears the override.
  /// Online-only (D12).
  Future<void> setEntryServings({
    required String entryId,
    required int? servings,
  }) => _remote.setEntryServings(entryId: entryId, servings: servings);

  /// Removes an entry. Online-only (D12).
  Future<void> removeEntry(String entryId) => _remote.removeEntry(entryId);

  /// Marks leftovers of [sourceEntryId] in one slot of one day. Online-only
  /// (D12).
  Future<void> addLeftoverEntry({
    required String householdId,
    required PlanWeek week,
    required DateTime entryDate,
    required MealSlot slot,
    required String sourceEntryId,
  }) => _remote.addLeftoverEntry(
    householdId: householdId,
    week: week,
    entryDate: entryDate,
    slot: slot,
    sourceEntryId: sourceEntryId,
  );

  /// Moves an entry to [newPosition] within its own slot. Online-only (D12).
  Future<void> reorderEntry({
    required String entryId,
    required int newPosition,
  }) => _remote.reorderEntry(entryId: entryId, newPosition: newPosition);

  /// How many times [recipeId] already occupies [slot] between [from] and
  /// [to] -- the snack variety check's raw count. Always online, checked
  /// immediately before a write (D12).
  Future<int> countRecipeInSlot({
    required String householdId,
    required String recipeId,
    required MealSlot slot,
    required DateTime from,
    required DateTime to,
  }) => _remote.countRecipeInSlot(
    householdId: householdId,
    recipeId: recipeId,
    slot: slot,
    from: from,
    to: to,
  );

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  /// Applies a household's delta onto the cache: partitions the changed
  /// rows into alive and tombstoned, upserts the survivors, evicts the
  /// tombstones, and advances the watermark to the max `updated_at` actually
  /// received -- never `DateTime.now()` (D72). Mirrors
  /// `RecipeRepository._applyRecipeDelta` exactly, one entity later.
  Future<void> _applyWeekDelta(
    String householdId,
    List<Map<String, dynamic>> changed,
    DateTime? since,
  ) async {
    DateTime maxUpdated = since ?? DateTime.utc(1970);
    final List<Map<String, dynamic>> alive = <Map<String, dynamic>>[];
    final List<String> tombstoned = <String>[];

    for (final Map<String, dynamic> row in changed) {
      final DateTime updatedAt =
          DateTime.parse(row['updated_at'] as String).toUtc();
      if (updatedAt.isAfter(maxUpdated)) maxUpdated = updatedAt;

      if (row['deleted_at'] != null) {
        tombstoned.add(row['id'] as String);
      } else {
        alive.add(row);
      }
    }

    if (alive.isNotEmpty) {
      await _local.upsertMany(householdId: householdId, rows: alive);
    }
    for (final String id in tombstoned) {
      await _local.evict(id);
    }
    await _local.advanceWeeksWatermark(householdId, maxUpdated);
  }
}
