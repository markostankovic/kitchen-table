/// Meal plan data access. The only place in this feature that touches
/// Supabase (CLAUDE.md rule 1).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_failure.dart';
import '../domain/meal_plan_entry.dart';
import '../domain/meal_plan_week.dart';
import '../domain/meal_slot.dart';
import '../domain/plan_week.dart';

/// The columns one entry carries, plus the `recipes` embed that resolves
/// [MealPlanEntry.recipeTitle] / [MealPlanEntry.recipeServings] at read time
/// -- never persisted (D53). No `MealPlanRepository` search for recipes; the
/// picker reads `RecipeRepository` directly through `core/recipes/`, so this
/// feature never duplicates that query.
const String _entryColumns = '''
id, meal_plan_id, entry_date, slot, position, entry_kind, recipe_id,
leftover_of_entry_id, note, servings, recipes(title, servings)''';

class MealPlanRepository {
  const MealPlanRepository(this._client);

  final SupabaseClient _client;

  /// The household's plan for [week], or an empty one if nothing has ever
  /// been written into it. D50 rules that the `meal_plans` row is created
  /// lazily, on the first write -- so a week the cook is only browsing is not
  /// an error, it is [MealPlanWeek.empty].
  ///
  /// `deleted_at` is filtered here rather than left to RLS (D23): the policy
  /// keeps returning a soft-deleted plan's row so the Phase 2 delta fetch can
  /// evict it, but a soft delete does not cascade to `meal_plan_entries` --
  /// only a hard delete does -- so without this filter a cleared week would
  /// still show its old entries.
  Future<MealPlanWeek> fetchWeek({
    required String householdId,
    required PlanWeek week,
  }) =>
      runGuarded(() async {
        final Map<String, dynamic>? row = await _client
            .from('meal_plans')
            .select('id, meal_plan_entries($_entryColumns)')
            .eq('household_id', householdId)
            .eq('week_start', week.isoDate)
            .isFilter('deleted_at', null)
            .maybeSingle();

        if (row == null) return MealPlanWeek.empty(week);

        final List<MealPlanEntry> entries =
            (row['meal_plan_entries'] as List<dynamic>? ?? <dynamic>[])
                .cast<Map<String, dynamic>>()
                .map(_toEntry)
                .toList(growable: false);

        return MealPlanWeek(
          week: week,
          planId: row['id'] as String,
          entries: entries,
        );
      });

  /// Adds a recipe to one slot of one day.
  ///
  /// [entryDate] must fall inside [week] -- `meal_plan_entries_before_write`
  /// (migration 14) refuses it otherwise. `position` is never sent: the
  /// server assigns it at the tail of the slot (D49), the same argument D36
  /// already made for `recipe_ingredients.position`.
  Future<void> addRecipeEntry({
    required String householdId,
    required PlanWeek week,
    required DateTime entryDate,
    required MealSlot slot,
    required String recipeId,
  }) =>
      runGuarded(() async {
        final String planId =
            await _ensurePlan(householdId: householdId, week: week);
        await _client.from('meal_plan_entries').insert(<String, dynamic>{
          'meal_plan_id': planId,
          'entry_date': isoDateOf(entryDate),
          'slot': slot.name,
          'entry_kind': MealEntryKind.recipe.name,
          'recipe_id': recipeId,
        });
      });

  /// Adds a note to one slot of one day.
  ///
  /// Explicit and separate from [addRecipeEntry] rather than one method that
  /// infers `entry_kind` from which argument came in non-null -- that is
  /// exactly the bug 1d part 5 shipped once already:
  /// `ImportRepository.saveImported` derived `source_type` from whether a
  /// source URL was present, and a photographed page silently recorded as
  /// `manual`. Two explicit methods make that class of mistake unwritable.
  Future<void> addNoteEntry({
    required String householdId,
    required PlanWeek week,
    required DateTime entryDate,
    required MealSlot slot,
    required String note,
  }) =>
      runGuarded(() async {
        final String planId =
            await _ensurePlan(householdId: householdId, week: week);
        await _client.from('meal_plan_entries').insert(<String, dynamic>{
          'meal_plan_id': planId,
          'entry_date': isoDateOf(entryDate),
          'slot': slot.name,
          'entry_kind': MealEntryKind.note.name,
          'note': note.trim(),
        });
      });

  /// Moves an existing entry to a different day and/or slot.
  ///
  /// `position` is recomputed server-side at the tail of the destination slot
  /// (D49) -- within-slot reordering is a known limitation of that trigger,
  /// written down there, and is not offered by this slice's UI either.
  Future<void> moveEntry({
    required String entryId,
    required DateTime entryDate,
    required MealSlot slot,
  }) =>
      runGuarded(() async {
        await _client.from('meal_plan_entries').update(<String, dynamic>{
          'entry_date': isoDateOf(entryDate),
          'slot': slot.name,
        }).eq('id', entryId);
      });

  /// Removes an entry. A real delete, not a soft one -- `meal_plan_entries`
  /// carries no `deleted_at` of its own (D24, D49); it cascades with its
  /// plan, and this is the same removal a cascade would eventually do.
  Future<void> removeEntry(String entryId) => runGuarded(() async {
        await _client.from('meal_plan_entries').delete().eq('id', entryId);
      });

  /// Marks leftovers of [sourceEntryId] in one slot of one day.
  ///
  /// [week] is the week containing [entryDate], not necessarily the week the
  /// source entry sits in (D56) -- Sunday dinner's leftovers landing on
  /// Monday lunch is the commonest leftover there is, and that is a
  /// different `meal_plans` row. `_ensurePlan` creates it on this first write
  /// into it, the same lazy-creation path any other write already takes.
  ///
  /// `recipe_id` is deliberately NOT sent -- `meal_plan_entries_leftover_
  /// source` (migration 15) derives it from the source entry server-side
  /// (D55), so a client value could never disagree with it anyway.
  Future<void> addLeftoverEntry({
    required String householdId,
    required PlanWeek week,
    required DateTime entryDate,
    required MealSlot slot,
    required String sourceEntryId,
  }) =>
      runGuarded(() async {
        final String planId =
            await _ensurePlan(householdId: householdId, week: week);
        await _client.from('meal_plan_entries').insert(<String, dynamic>{
          'meal_plan_id': planId,
          'entry_date': isoDateOf(entryDate),
          'slot': slot.name,
          'entry_kind': MealEntryKind.leftover.name,
          'leftover_of_entry_id': sourceEntryId,
        });
      });

  /// Moves an entry to [newPosition] within its own slot, via
  /// `reorder_meal_plan_entry` (D57). `meal_plan_entries_before_write`
  /// cannot express this -- it always lands an insert or a cross-slot move at
  /// the tail of the destination group (D49) -- so this is a separate RPC,
  /// not a plain `update` like [moveEntry].
  Future<void> reorderEntry({
    required String entryId,
    required int newPosition,
  }) =>
      runGuarded(() async {
        await _client.rpc<void>(
          'reorder_meal_plan_entry',
          params: <String, dynamic>{
            'entry': entryId,
            'new_position': newPosition,
          },
        );
      });

  /// How many times [recipeId] already occupies [slot] between [from] and
  /// [to], inclusive -- the snack variety check's raw count
  /// (`snack_variety.dart` turns it into a warn/don't-warn decision).
  ///
  /// Scoped to [householdId] and to visible plans explicitly, through the
  /// `meal_plans!inner` embed: RLS alone would also count a slot in any
  /// *other* household the caller belongs to, and a soft-deleted week's
  /// entries live on past its plan's `deleted_at` (D23) -- the same reason
  /// [fetchWeek] filters `deleted_at` in `data/` rather than trusting the
  /// policy to. Matching on `recipe_id` alone (not `entry_kind`) counts a
  /// leftover as an occurrence of its source recipe too, which is correct --
  /// migration 15 derives `recipe_id` onto every leftover row (D55), so this
  /// needs no join to know that.
  Future<int> countRecipeInSlot({
    required String householdId,
    required String recipeId,
    required MealSlot slot,
    required DateTime from,
    required DateTime to,
  }) =>
      runGuarded(() async {
        final List<Map<String, dynamic>> rows = await _client
            .from('meal_plan_entries')
            .select('id, meal_plans!inner(household_id, deleted_at)')
            .eq('recipe_id', recipeId)
            .eq('slot', slot.name)
            .gte('entry_date', isoDateOf(from))
            .lte('entry_date', isoDateOf(to))
            .eq('meal_plans.household_id', householdId)
            .isFilter('meal_plans.deleted_at', null);
        return rows.length;
      });

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  /// Creates the household's plan for [week] if this is the first write into
  /// it, or returns its existing id (D50). Called only from a write path
  /// above -- never from [fetchWeek].
  Future<String> _ensurePlan({
    required String householdId,
    required PlanWeek week,
  }) async {
    final dynamic id = await _client.rpc<dynamic>(
      'ensure_meal_plan',
      params: <String, dynamic>{
        'household': householdId,
        'week': week.isoDate,
      },
    );
    return id as String;
  }

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
