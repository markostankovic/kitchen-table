/// The wire shape of `meal_plans` plus its embedded `meal_plan_entries` --
/// and the cache's own encoding of that exact shape (Phase 2 part 6b, on
/// `recipe_dto.dart`'s precedent, D65).
///
/// The cache stores the *raw* PostgREST response map verbatim (`jsonEncode`
/// of exactly what the network returned), so there is one decoder for both
/// a fresh read and a cache hit -- no `toWire()` encoder exists here, on
/// `recipe_dto.dart`'s precedent rather than `shopping_list_dto.dart`'s: a
/// meal plan week is never built up from a domain object before being
/// cached, only ever read off the wire and stored as-is.
library;

import '../../domain/meal_plan_entry.dart';
import '../../domain/meal_plan_week.dart';
import '../../domain/meal_slot.dart';
import '../../domain/plan_week.dart';

/// The columns of `meal_plans` a delta fetch names. [weekStart] and
/// [deletedAt] are new here -- `MealPlanRepository.fetchWeek` never needed
/// either before this part: the week was already known from the query, and
/// a soft-deleted plan was filtered server-side rather than surfaced to be
/// evicted (D23's usual argument, now applied to this entity).
const String mealPlanColumns = 'id, week_start, updated_at, deleted_at';

/// The columns one entry carries, plus the `recipes` embed that resolves
/// [MealPlanEntry.recipeTitle] / [MealPlanEntry.recipeServings] at read time
/// -- never persisted (D53). Moved here unchanged from the old
/// `meal_plan_repository.dart` (`_entryColumns`) when the Remote/Local split
/// gave it a home outside the repository file.
const String mealPlanEntryColumns = '''
id, meal_plan_id, entry_date, slot, position, entry_kind, recipe_id,
leftover_of_entry_id, note, servings, recipes(title, servings)''';

/// One entry, decoded identically whether it came straight off the wire or
/// out of a cache blob -- moved here unchanged from the old
/// `MealPlanRepository._toEntry`.
MealPlanEntry mealPlanEntryFromWire(Map<String, dynamic> row) {
  final Map<String, dynamic>? recipe = row['recipes'] as Map<String, dynamic>?;
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

/// A whole week, decoded from a `meal_plans` row carrying an embedded
/// `meal_plan_entries` list -- sorted by `position`, since PostgREST does
/// not promise embed order (`recipe_dto.dart` and `shopping_list_dto.dart`
/// make the same point about their own embeds).
///
/// [row] must carry `week_start` -- the caller is expected to have asked for
/// [mealPlanColumns], not just `id`, the way the old single-file
/// `fetchWeek` did.
MealPlanWeek mealPlanWeekFromWire(Map<String, dynamic> row) {
  final PlanWeek week = PlanWeek.fromIsoDate(row['week_start'] as String);
  final List<MealPlanEntry> entries =
      (row['meal_plan_entries'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>()
          .map(mealPlanEntryFromWire)
          .toList()
        ..sort(
          (MealPlanEntry a, MealPlanEntry b) =>
              a.position.compareTo(b.position),
        );

  return MealPlanWeek(
    week: week,
    planId: row['id'] as String,
    entries: entries,
  );
}
