/// Shopping list access to Supabase. The only file in this feature that
/// imports `supabase_flutter` (CLAUDE.md rule 1) -- `ShoppingListRepository`
/// composes this with `LocalShoppingListDataSource` rather than talking to
/// Supabase itself, on `docs/ARCHITECTURE.md`'s "Offline (Phase 2)" split.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_failure.dart';
import '../../meal_plan/domain/meal_plan_entry.dart';
import '../../meal_plan/domain/meal_slot.dart';
import '../../meal_plan/domain/plan_week.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_list.dart';
import 'dto/shopping_item_dto.dart';
import 'dto/shopping_list_dto.dart';

/// The columns of `meal_plan_entries` the aggregation needs.
///
/// Narrower than `MealPlanRepository`'s own list, and a duplicate of it: the
/// shopping list never renders a note's text or an entry's position, it only
/// needs to know what was planned, when, whether it was a leftover, and for
/// how many people, and this feature may not import `meal_plan/data/`.
/// `recipes(servings)` comes along because the scale factor is
/// `entry.servings / recipe.servings` and the second half is a recipe fact.
const String _entryColumns = '''
id, meal_plan_id, entry_date, slot, position, entry_kind, recipe_id,
leftover_of_entry_id, note, servings, recipes(title, servings)''';

class RemoteShoppingListDataSource {
  const RemoteShoppingListDataSource(this._client);

  final SupabaseClient _client;

  /// The household's current list -- the most recently generated live one.
  ///
  /// Returns null when there is none, which is the empty state the screen
  /// shows rather than an error: a household that has never generated a list
  /// is not a household with a missing one.
  Future<ShoppingList?> fetchLatest({required String householdId}) =>
      runGuarded(() async {
        final Map<String, dynamic>? row = await _client
            .from('shopping_lists')
            .select(
              '$shoppingListColumns, shopping_list_items($shoppingListItemColumns)',
            )
            .eq('household_id', householdId)
            .isFilter('deleted_at', null)
            .order('generated_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (row == null) return null;
        return shoppingListFromWire(row);
      });

  /// Writes a generated list and all its items in one transaction.
  ///
  /// One RPC rather than an insert followed by an insert: a failure between
  /// the two would leave a headless list, which on screen is indistinguishable
  /// from a week with nothing planned. Same argument as `replace_recipe_lines`
  /// (D36) and `save_imported_recipe` (D44).
  ///
  /// `position` is not sent. The function derives it from array order, so a
  /// duplicated or missing position is not expressible.
  Future<String> save({
    required String householdId,
    String? mealPlanId,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String locale,
    required List<ShoppingItem> items,
  }) => runGuarded(() async {
    final dynamic id = await _client.rpc<dynamic>(
      'save_shopping_list',
      params: <String, dynamic>{
        'household': householdId,
        'plan': mealPlanId,
        'from_date': isoDateOf(dateFrom),
        'to_date': isoDateOf(dateTo),
        'loc': locale,
        'items': items
            .map((ShoppingItem i) => i.toWire())
            .toList(growable: false),
      },
    );
    return id as String;
  });

  /// Retires a list. A soft delete (rule 4) -- `shopping_lists` carries a
  /// `household_id` and has no DELETE policy at all, so a hard delete would
  /// silently match zero rows.
  Future<void> softDelete(String id) => runGuarded(() async {
    await _client
        .from('shopping_lists')
        .update(<String, dynamic>{
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  });

  /// The household's pantry overrides, as ingredient id -> always_have.
  ///
  /// A map rather than a list of rows because that is how the aggregator
  /// consumes it, and because "does this household have an opinion about this
  /// ingredient" is a lookup, not a scan.
  Future<Map<String, bool>> fetchPantryPrefs({required String householdId}) =>
      runGuarded(() async {
        final List<Map<String, dynamic>> rows = await _client
            .from('household_pantry_prefs')
            .select('ingredient_id, always_have')
            .eq('household_id', householdId);

        return <String, bool>{
          for (final Map<String, dynamic> row in rows)
            row['ingredient_id'] as String: row['always_have'] as bool,
        };
      });

  /// Records or clears "we always have this".
  ///
  /// Passing null removes the row rather than storing a third state: the
  /// absence of an override IS the third state, and it means "defer to the
  /// catalog". A hard delete, on the join-table precedent D24 set for
  /// `household_members` and migration 6 already applied to this table.
  Future<void> setPantryPref({
    required String householdId,
    required String ingredientId,
    required bool? alwaysHave,
  }) => runGuarded(() async {
    if (alwaysHave == null) {
      await _client
          .from('household_pantry_prefs')
          .delete()
          .eq('household_id', householdId)
          .eq('ingredient_id', ingredientId);
      return;
    }

    await _client.from('household_pantry_prefs').upsert(<String, dynamic>{
      'household_id': householdId,
      'ingredient_id': ingredientId,
      'always_have': alwaysHave,
    }, onConflict: 'household_id,ingredient_id');
  });

  /// Every planned entry in a date range, across however many weeks it spans.
  ///
  /// Scoped through a `meal_plans!inner` embed rather than left to RLS, for
  /// the reason `MealPlanRepository.countRecipeInSlot` gives: RLS would also
  /// match entries in any OTHER household the caller belongs to, and a
  /// shopping list that quietly includes the in-laws' week is worse than one
  /// that fails.
  Future<List<MealPlanEntry>> fetchEntriesInRange({
    required String householdId,
    required DateTime from,
    required DateTime to,
  }) => runGuarded(() async {
    final List<Map<String, dynamic>> rows = await _client
        .from('meal_plan_entries')
        .select('$_entryColumns, meal_plans!inner(household_id, deleted_at)')
        .gte('entry_date', isoDateOf(from))
        .lte('entry_date', isoDateOf(to))
        .eq('meal_plans.household_id', householdId)
        .isFilter('meal_plans.deleted_at', null);

    return rows.map(_toEntry).toList(growable: false);
  });

  /// The plan id a list generated for [week] should point at, if one exists.
  ///
  /// Deliberately a read, so it never creates a week row: `ensure_meal_plan`
  /// is for write paths only (D50), and generating a shopping list for a week
  /// nobody has planned must not bring that week into existence.
  Future<String?> findPlanId({
    required String householdId,
    required PlanWeek week,
  }) => runGuarded(() async {
    final Map<String, dynamic>? row = await _client
        .from('meal_plans')
        .select('id')
        .eq('household_id', householdId)
        .eq('week_start', week.isoDate)
        .isFilter('deleted_at', null)
        .maybeSingle();
    return row?['id'] as String?;
  });

  MealPlanEntry _toEntry(Map<String, dynamic> row) {
    final Map<String, dynamic>? recipe =
        row['recipes'] as Map<String, dynamic>?;
    return MealPlanEntry(
      id: row['id'] as String,
      mealPlanId: row['meal_plan_id'] as String,
      entryDate: parseIsoDate(row['entry_date'] as String),
      slot: MealSlot.values.byName(row['slot'] as String),
      position: row['position'] as int,
      entryKind: MealEntryKind.values.byName(row['entry_kind'] as String),
      recipeId: row['recipe_id'] as String?,
      leftoverOfEntryId: row['leftover_of_entry_id'] as String?,
      note: row['note'] as String?,
      servings: row['servings'] as int?,
      recipeTitle: recipe?['title'] as String?,
      recipeServings: recipe?['servings'] as int?,
    );
  }
}
