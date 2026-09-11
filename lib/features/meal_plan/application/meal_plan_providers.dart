import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/household/current_household.dart';
import '../../../core/refresh/data_revision.dart';
import '../../../core/supabase/supabase_client.dart';
import '../data/meal_plan_repository.dart';
import '../domain/meal_plan_week.dart';
import '../domain/meal_slot.dart';
import '../domain/plan_week.dart';
import '../domain/snack_variety.dart';

part 'meal_plan_providers.g.dart';

@Riverpod(keepAlive: true)
MealPlanRepository mealPlanRepository(Ref ref) =>
    MealPlanRepository(ref.watch(supabaseClientProvider));

/// The one week currently on screen.
///
/// Not a family keyed on the week: there is exactly one visible week at a
/// time, the same way there is exactly one signed-in user, so a family would
/// have been modelling something that does not exist. That also makes this
/// provider a one-line override in a test -- a family keyed on
/// `PlanWeek.of(DateTime.now())` would be clock-dependent to stub.
@riverpod
class VisibleWeek extends _$VisibleWeek {
  @override
  PlanWeek build() => PlanWeek.of(DateTime.now());

  void next() => state = state.next;
  void previous() => state = state.previous;
  void today() => state = PlanWeek.of(DateTime.now());
}

/// The visible week's entries, and the writes that change them.
///
/// `build()` resolves the household id before it ever reaches
/// [mealPlanRepositoryProvider], and returns an empty week rather than
/// constructing a repository call when there is none -- a household-less
/// caller never touches `Supabase.instance.client` (the shell's tab loop
/// relies on exactly this to render the Plan tab under test).
///
/// There is no Save: every action here writes immediately (D53). A meal plan
/// is not one document being composed like a recipe draft -- each entry is
/// independent, and putting a recipe in Thursday lunch is complete on its
/// own. D12 already rules out an offline draft buying anything.
@riverpod
class MealPlanEditor extends _$MealPlanEditor {
  @override
  Future<MealPlanWeek> build() async {
    ref.watch(mealPlanRevisionProvider);
    final PlanWeek week = ref.watch(visibleWeekProvider);

    final String? householdId =
        await ref.watch(currentHouseholdIdProvider.future);
    if (householdId == null) return MealPlanWeek.empty(week);

    return ref
        .watch(mealPlanRepositoryProvider)
        .fetchWeek(householdId: householdId, week: week);
  }

  Future<void> addRecipe({
    required DateTime entryDate,
    required MealSlot slot,
    required String recipeId,
  }) =>
      _write((MealPlanRepository repo, String householdId, PlanWeek week) =>
          repo.addRecipeEntry(
            householdId: householdId,
            week: week,
            entryDate: entryDate,
            slot: slot,
            recipeId: recipeId,
          ));

  Future<void> addNote({
    required DateTime entryDate,
    required MealSlot slot,
    required String note,
  }) =>
      _write((MealPlanRepository repo, String householdId, PlanWeek week) =>
          repo.addNoteEntry(
            householdId: householdId,
            week: week,
            entryDate: entryDate,
            slot: slot,
            note: note,
          ));

  Future<void> moveEntry({
    required String entryId,
    required DateTime entryDate,
    required MealSlot slot,
  }) =>
      _write((MealPlanRepository repo, String householdId, PlanWeek week) =>
          repo.moveEntry(entryId: entryId, entryDate: entryDate, slot: slot));

  Future<void> removeEntry(String entryId) =>
      _write((MealPlanRepository repo, String householdId, PlanWeek week) =>
          repo.removeEntry(entryId));

  /// Marks leftovers of [sourceEntryId] on [entryDate] / [slot].
  ///
  /// Deliberately ignores the `week` [_write] supplies (the visible week) and
  /// derives the destination week from [entryDate] instead (D56): a
  /// leftover's week is wherever its date falls, which is routinely NOT the
  /// week on screen -- Sunday dinner's leftovers land on Monday lunch, a
  /// different `meal_plans` row entirely, created lazily by
  /// `MealPlanRepository.addLeftoverEntry` exactly as any other first write
  /// into a week already is (D50). A leftover placed into next week is
  /// invisible until the cook pages the grid forward; that is correct, not a
  /// bug -- the grid shows one week at a time by design (D54).
  Future<void> addLeftover({
    required String sourceEntryId,
    required DateTime entryDate,
    required MealSlot slot,
  }) =>
      _write((MealPlanRepository repo, String householdId, PlanWeek week) =>
          repo.addLeftoverEntry(
            householdId: householdId,
            week: PlanWeek.of(entryDate),
            entryDate: entryDate,
            slot: slot,
            sourceEntryId: sourceEntryId,
          ));

  Future<void> reorderEntry({
    required String entryId,
    required int newPosition,
  }) =>
      _write((MealPlanRepository repo, String householdId, PlanWeek week) =>
          repo.reorderEntry(entryId: entryId, newPosition: newPosition));

  /// How many snack-slot entries already carry [recipeId] in the window
  /// centred on [entryDate] (`snack_variety.dart`) -- the raw count behind
  /// the screen's "already planned N times" warning.
  ///
  /// Not a write: it neither goes through [_write] nor bumps
  /// [mealPlanRevisionProvider]. Returns 0 when there is no household yet,
  /// the same "never touch the client without one" rule [build] follows --
  /// there is nothing to warn about before a household exists.
  Future<int> snackRepeatCount({
    required String recipeId,
    required DateTime entryDate,
  }) async {
    final String? householdId =
        await ref.read(currentHouseholdIdProvider.future);
    if (householdId == null) return 0;

    final ({DateTime from, DateTime to}) window =
        varietyWindowAround(entryDate);
    return ref.read(mealPlanRepositoryProvider).countRecipeInSlot(
          householdId: householdId,
          recipeId: recipeId,
          slot: MealSlot.snack,
          from: window.from,
          to: window.to,
        );
  }

  /// Every action shares this shape: resolve the household, run the
  /// repository call, then bump [mealPlanRevisionProvider], which rebuilds
  /// [build] and is the only refresh this class does. Calling
  /// `ref.invalidateSelf()` on top would refetch twice.
  Future<void> _write(
    Future<void> Function(
      MealPlanRepository repository,
      String householdId,
      PlanWeek week,
    ) action,
  ) async {
    final String? householdId =
        await ref.read(currentHouseholdIdProvider.future);
    if (householdId == null) {
      throw const NotFoundFailure(message: 'You are not in a household yet.');
    }
    final PlanWeek week = ref.read(visibleWeekProvider);
    await action(ref.read(mealPlanRepositoryProvider), householdId, week);
    ref.read(mealPlanRevisionProvider.notifier).bump();
  }
}
