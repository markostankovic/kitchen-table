/// Writing a meal plan entry from outside `features/meal_plan/` (D103).
///
/// Lives in `core/` for the same reason `core/recipes/recipe_picker_providers
/// .dart` does (D53, D43/D33): `features/recipes/presentation/` may not
/// import `features/meal_plan/application/`, and duplicating
/// `MealPlanRepository`'s write logic there would be D33's mistake made
/// again. `core/` sits outside the feature rule entirely (`_featureOf` only
/// matches `lib/features/<name>/<layer>/`), which is what lets this file
/// reach into `features/meal_plan/data/` while naming neither
/// `supabase_flutter` nor a `Map<String, dynamic>` itself (rule 1, D64).
///
/// This is not `MealPlanEditor` reused from a second screen. Two reasons,
/// both load-bearing:
///
///  1. `MealPlanEditor._write` derives the destination week from
///     `visibleWeekProvider` -- correct for the Plan tab's own week grid, but
///     from the recipe screen there is no visible week at all, and
///     `ensure_meal_plan`'s `meal_plan_entries_before_write` trigger (D50,
///     migration 14) refuses an `entry_date` outside whatever week that
///     provider happens to hold. [MealPlanWriter.addRecipe] derives the week
///     from the chosen date instead, `PlanWeek.of(entryDate)` -- the same
///     rule `MealPlanEditor.addLeftover` already carved out for a leftover's
///     destination (D56).
///  2. `mealPlanEditorProvider` is `autoDispose`. Reading its `.notifier` from
///     a screen that never watches it risks the notifier being torn down
///     mid-`await`, and rebuilding it here would fire a pointless
///     `watchWeek` network fetch the recipe screen has no use for.
///     `keepAlive` on both providers below is what avoids that -- not
///     decoration.
library;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/meal_plan/data/local_meal_plan_datasource.dart';
import '../../features/meal_plan/data/meal_plan_repository.dart';
import '../../features/meal_plan/data/remote_meal_plan_datasource.dart';
import '../../features/meal_plan/domain/meal_slot.dart';
import '../../features/meal_plan/domain/plan_week.dart';
import '../../features/meal_plan/domain/snack_variety.dart';
import '../db/app_database.dart';
import '../error/app_failure.dart';
import '../household/current_household.dart';
import '../refresh/data_revision.dart';
import '../supabase/supabase_client.dart';

part 'meal_plan_writer.g.dart';

@Riverpod(keepAlive: true)
MealPlanRepository mealPlanWriteSink(Ref ref) => MealPlanRepository(
  RemoteMealPlanDataSource(ref.watch(supabaseClientProvider)),
  LocalMealPlanDataSource(ref.watch(appDatabaseProvider)),
);

/// Writes one meal plan entry from a screen that holds no visible week.
///
/// `keepAlive`, and never watched by its caller -- see the file header for
/// why an `autoDispose` notifier is the wrong shape here.
@Riverpod(keepAlive: true)
class MealPlanWriter extends _$MealPlanWriter {
  @override
  void build() {}

  /// How many snack-slot entries already carry [recipeId] in the window
  /// centred on [entryDate] -- `MealPlanEditor.snackRepeatCount`'s own body,
  /// copied rather than shared, since the two notifiers have no common
  /// ancestor and this one may not import `features/meal_plan/application/`.
  Future<int> snackRepeatCount({
    required String recipeId,
    required DateTime entryDate,
  }) async {
    final String? householdId =
        await ref.read(currentHouseholdIdProvider.future);
    if (householdId == null) return 0;

    final ({DateTime from, DateTime to}) window =
        varietyWindowAround(entryDate);
    return ref.read(mealPlanWriteSinkProvider).countRecipeInSlot(
          householdId: householdId,
          recipeId: recipeId,
          slot: MealSlot.snack,
          from: window.from,
          to: window.to,
        );
  }

  /// Adds [recipeId] to [slot] on [entryDate], deriving the destination week
  /// from [entryDate] itself (D56) rather than any visible week -- there is
  /// none here.
  Future<void> addRecipe({
    required DateTime entryDate,
    required MealSlot slot,
    required String recipeId,
  }) async {
    final String? householdId =
        await ref.read(currentHouseholdIdProvider.future);
    if (householdId == null) {
      throw const NotFoundFailure(
        message: 'You are not in a household yet.',
        code: FailureCode.noHousehold,
      );
    }

    await ref.read(mealPlanWriteSinkProvider).addRecipeEntry(
          householdId: householdId,
          week: PlanWeek.of(entryDate),
          entryDate: entryDate,
          slot: slot,
          recipeId: recipeId,
        );
    ref.read(mealPlanRevisionProvider.notifier).bump();
  }
}
