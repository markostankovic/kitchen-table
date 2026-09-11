import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/household/current_household.dart';
import '../../../core/ingredients/ingredient_catalog_providers.dart';
import '../../../core/net/network_status.dart';
import '../../../core/recipes/recipe_picker_providers.dart';
import '../../../core/refresh/data_revision.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../ingredients/domain/unit_catalog.dart';
import '../../meal_plan/domain/meal_plan_entry.dart';
import '../../meal_plan/domain/plan_week.dart';
import '../../recipes/domain/recipe_ingredient.dart';
import '../data/local_shopping_list_datasource.dart';
import '../data/remote_shopping_list_datasource.dart';
import '../data/shopping_list_repository.dart';
import '../domain/aggregate_shopping_list.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_list.dart';

part 'shopping_list_providers.g.dart';

@Riverpod(keepAlive: true)
ShoppingListRepository shoppingListRepository(Ref ref) => ShoppingListRepository(
  RemoteShoppingListDataSource(ref.watch(supabaseClientProvider)),
  LocalShoppingListDataSource(ref.watch(appDatabaseProvider)),
);

/// The date range the next list will cover.
///
/// Starts as the current week, which is the range a cook wants nine times out
/// of ten. Not a family, on `VisibleWeek`'s precedent (D54): there is exactly
/// one range being shopped for at a time, so a family would model something
/// that does not exist, and a non-family is a one-line override in a test.
///
/// Deliberately NOT derived from `visibleWeekProvider`. Paging the Plan tab to
/// look at next month should not silently change what the List tab is about to
/// generate -- the two tabs answer different questions, and a range that moves
/// under the cook because they glanced elsewhere is the kind of surprise a
/// snapshot document should not have.
@riverpod
class ShoppingRange extends _$ShoppingRange {
  @override
  ({DateTime from, DateTime to}) build() {
    final PlanWeek week = PlanWeek.of(DateTime.now());
    return (from: week.start, to: week.end);
  }

  void setWeek(PlanWeek week) => state = (from: week.start, to: week.end);

  void setRange({required DateTime from, required DateTime to}) =>
      state = (from: from, to: to.isBefore(from) ? from : to);

  void thisWeek() => setWeek(PlanWeek.of(DateTime.now()));

  void nextWeek() => setWeek(PlanWeek.of(DateTime.now()).next);
}

/// The household's current list, and the actions that change it.
///
/// `build()` yields null rather than constructing a repository call when
/// there is no household, so a household-less caller never touches
/// `Supabase.instance.client` -- the shell's tab loop relies on exactly this
/// to render the List tab under test.
///
/// A `Stream`, not a `Future` (Phase 2 part 5, D67): `watchLatest` emits a
/// cache hit immediately, then the network's answer, and a `StreamNotifier`
/// is what lets the second emission be part of the provider's own lifecycle
/// -- cancelled on dispose, routed into `AsyncValue` with no hand-rolled
/// `state = ...` after `build()` returns. The provider's value type is
/// unchanged (`ShoppingList?`), so every existing consumer of
/// `AsyncValue<ShoppingList?>` -- the screen, its test -- is untouched in
/// shape; staleness is a separate signal, `networkStatusProvider`.
///
/// Watches [mealPlanRevisionProvider] as well as its own: a list is a snapshot
/// of a plan, and the plan changing is the single most useful reason to tell
/// the cook their list is out of date.
@riverpod
class CurrentShoppingList extends _$CurrentShoppingList {
  @override
  Stream<ShoppingList?> build() async* {
    ref.watch(shoppingListRevisionProvider);
    ref.watch(mealPlanRevisionProvider);

    final String? householdId = await ref.watch(
      currentHouseholdIdProvider.future,
    );
    if (householdId == null) {
      yield null;
      return;
    }

    final NetworkStatus status = ref.read(networkStatusProvider.notifier);
    yield* ref
        .watch(shoppingListRepositoryProvider)
        .watchLatest(
          householdId: householdId,
          onReachable: status.reportReachable,
          onUnreachable: status.reportUnreachable,
        );
  }

  /// Generates a list for the current range, retiring whatever it replaces.
  ///
  /// The order matters: aggregate first, save second, retire third. A failure
  /// anywhere in the first two leaves the cook with the list they already had,
  /// which is strictly better than leaving them with none.
  Future<void> generate() async {
    final String? householdId = await ref.read(
      currentHouseholdIdProvider.future,
    );
    if (householdId == null) {
      throw const NotFoundFailure(message: 'You are not in a household yet.');
    }

    final ShoppingListRepository repository = ref.read(
      shoppingListRepositoryProvider,
    );
    final ({DateTime from, DateTime to}) range = ref.read(
      shoppingRangeProvider,
    );

    final List<MealPlanEntry> entries = await repository.fetchEntriesInRange(
      householdId: householdId,
      from: range.from,
      to: range.to,
    );

    final List<ShoppingItem> items = await _aggregate(
      entries,
      repository,
      householdId,
    );

    // Only point at a plan when the range is exactly one existing week.
    // A multi-week or partial range spans no single plan row, and
    // `meal_plan_id` is nullable precisely so it can say so honestly rather
    // than name whichever week happened to come first.
    final String? planId = await _planIdFor(householdId, range, repository);

    final ShoppingList? previous = state.value;

    await repository.save(
      householdId: householdId,
      mealPlanId: planId,
      dateFrom: range.from,
      dateTo: range.to,
      locale: 'sr',
      items: items,
    );

    if (previous != null) await repository.softDelete(previous.id);

    ref.read(shoppingListRevisionProvider.notifier).bump();
  }

  /// Retires the current list without generating another.
  Future<void> discard() async {
    final ShoppingList? current = state.value;
    if (current == null) return;
    await ref.read(shoppingListRepositoryProvider).softDelete(current.id);
    ref.read(shoppingListRevisionProvider.notifier).bump();
  }

  /// Records or clears "we always have this" for one ingredient.
  ///
  /// Does NOT rewrite the list on screen. The snapshot is what it was when it
  /// was generated (D13); the override takes effect on the next generation,
  /// and the screen says so rather than silently rearranging a document the
  /// cook is reading in a shop.
  Future<void> setPantryPref({
    required String ingredientId,
    required bool? alwaysHave,
  }) async {
    final String? householdId = await ref.read(
      currentHouseholdIdProvider.future,
    );
    if (householdId == null) {
      throw const NotFoundFailure(message: 'You are not in a household yet.');
    }
    await ref
        .read(shoppingListRepositoryProvider)
        .setPantryPref(
          householdId: householdId,
          ingredientId: ingredientId,
          alwaysHave: alwaysHave,
        );
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  /// Pulls together everything the pure aggregator needs, then runs it.
  ///
  /// Two round trips for the whole range regardless of how many recipes it
  /// names: one for the lines, one for the pantry overrides. The unit catalog
  /// is already in memory -- `unitCatalogProvider` is `keepAlive` and fetched
  /// once per session.
  Future<List<ShoppingItem>> _aggregate(
    List<MealPlanEntry> entries,
    ShoppingListRepository repository,
    String householdId,
  ) async {
    final List<String> recipeIds = entries
        .where((MealPlanEntry e) => !e.isLeftover && e.recipeId != null)
        .map((MealPlanEntry e) => e.recipeId!)
        .toSet()
        .toList(growable: false);

    final List<RecipeIngredient> lines = await ref
        .read(plannableRecipeSourceProvider)
        .fetchLinesForRecipes(recipeIds);

    final Map<String, bool> prefs = await repository.fetchPantryPrefs(
      householdId: householdId,
    );

    final UnitCatalog units = await ref.read(unitCatalogProvider.future);

    final Map<String, List<RecipeIngredient>> byRecipe =
        <String, List<RecipeIngredient>>{};
    for (final RecipeIngredient line in lines) {
      final String? recipeId = line.recipeId;
      if (recipeId == null) continue;
      byRecipe.putIfAbsent(recipeId, () => <RecipeIngredient>[]).add(line);
    }

    final List<PlannedRecipe> planned = <PlannedRecipe>[
      for (final MealPlanEntry entry in entries)
        (
          entry: entry,
          recipeServings: entry.recipeServings,
          lines: byRecipe[entry.recipeId] ?? const <RecipeIngredient>[],
        ),
    ];

    return aggregateShoppingList(
      planned: planned,
      units: units,
      pantryPrefs: prefs,
    );
  }

  Future<String?> _planIdFor(
    String householdId,
    ({DateTime from, DateTime to}) range,
    ShoppingListRepository repository,
  ) async {
    final PlanWeek week = PlanWeek.of(range.from);
    if (week.start != range.from || week.end != range.to) return null;
    return repository.findPlanId(householdId: householdId, week: week);
  }
}
