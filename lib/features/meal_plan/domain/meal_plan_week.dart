import 'meal_plan_entry.dart';
import 'meal_slot.dart';
import 'plan_week.dart';

/// One week's worth of entries, aggregated so the screen has exactly one
/// [AsyncValue] to handle -- the direct analogue of `RecipeDetail` bundling a
/// recipe with its lines and steps.
///
/// [planId] is null for a week nothing has ever been written into: D50 rules
/// that the `meal_plans` row itself is created lazily, on the first write, so
/// an empty week the cook is only browsing is not an error, it is
/// [MealPlanWeek.empty].
///
/// A plain class, not freezed -- like [PlanWeek], this has no wire
/// representation of its own; it is assembled in `MealPlanRepository` from a
/// plan row and its embedded entries.
///
/// Pure Dart (CLAUDE.md rule 7).
class MealPlanWeek {
  const MealPlanWeek({
    required this.week,
    required this.planId,
    required this.entries,
  });

  factory MealPlanWeek.empty(PlanWeek week) => MealPlanWeek(
        week: week,
        planId: null,
        entries: const <MealPlanEntry>[],
      );

  final PlanWeek week;
  final String? planId;
  final List<MealPlanEntry> entries;

  bool get isEmpty => entries.isEmpty;
  int get entryCount => entries.length;

  /// The entries in one slot of one day, in display order.
  ///
  /// Filters on the calendar day rather than trusting every entry to fall
  /// inside [week] -- defensive against a row `meal_plan_entries_before_write`
  /// would have refused, so a bug elsewhere shows as a missing tile rather
  /// than a tile in the wrong week.
  List<MealPlanEntry> entriesFor(DateTime day, MealSlot slot) {
    final List<MealPlanEntry> matches = entries
        .where((MealPlanEntry e) =>
            e.slot == slot &&
            e.entryDate.year == day.year &&
            e.entryDate.month == day.month &&
            e.entryDate.day == day.day)
        .toList(growable: false);
    matches.sort(
        (MealPlanEntry a, MealPlanEntry b) => a.position.compareTo(b.position));
    return matches;
  }
}
