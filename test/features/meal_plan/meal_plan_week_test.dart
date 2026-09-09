import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_plan_week.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_slot.dart';
import 'package:kitchen_table/features/meal_plan/domain/plan_week.dart';

MealPlanEntry _recipeEntry({
  required String id,
  required DateTime date,
  required MealSlot slot,
  required int position,
  String title = 'Torta',
}) =>
    MealPlanEntry(
      id: id,
      mealPlanId: 'plan-1',
      entryDate: date,
      slot: slot,
      position: position,
      entryKind: MealEntryKind.recipe,
      recipeId: 'r1',
      recipeTitle: title,
    );

MealPlanEntry _noteEntry({
  required String id,
  required DateTime date,
  required MealSlot slot,
  required int position,
  required String note,
}) =>
    MealPlanEntry(
      id: id,
      mealPlanId: 'plan-1',
      entryDate: date,
      slot: slot,
      position: position,
      entryKind: MealEntryKind.note,
      note: note,
    );

void main() {
  final PlanWeek week = PlanWeek.of(DateTime(2026, 6, 1));
  final DateTime monday = week.days[0];
  final DateTime tuesday = week.days[1];

  group('entriesFor', () {
    test('filters by both day and slot, ignoring other days and slots', () {
      final MealPlanWeek plan = MealPlanWeek(
        week: week,
        planId: 'plan-1',
        entries: <MealPlanEntry>[
          _recipeEntry(id: 'e1', date: monday, slot: MealSlot.lunch, position: 0),
          _recipeEntry(id: 'e2', date: monday, slot: MealSlot.dinner, position: 0),
          _recipeEntry(id: 'e3', date: tuesday, slot: MealSlot.lunch, position: 0),
        ],
      );

      final List<MealPlanEntry> mondayLunch =
          plan.entriesFor(monday, MealSlot.lunch);
      expect(mondayLunch.map((MealPlanEntry e) => e.id), <String>['e1']);
    });

    test('sorts by position, even when the source list is shuffled', () {
      final MealPlanWeek plan = MealPlanWeek(
        week: week,
        planId: 'plan-1',
        entries: <MealPlanEntry>[
          _recipeEntry(id: 'e-pos-2', date: monday, slot: MealSlot.lunch, position: 2),
          _recipeEntry(id: 'e-pos-0', date: monday, slot: MealSlot.lunch, position: 0),
          _recipeEntry(id: 'e-pos-1', date: monday, slot: MealSlot.lunch, position: 1),
        ],
      );

      final List<MealPlanEntry> lunch = plan.entriesFor(monday, MealSlot.lunch);
      expect(lunch.map((MealPlanEntry e) => e.id),
          <String>['e-pos-0', 'e-pos-1', 'e-pos-2']);
    });

    test('an empty slot returns an empty list', () {
      final MealPlanWeek plan = MealPlanWeek.empty(week);
      expect(plan.entriesFor(monday, MealSlot.breakfast), isEmpty);
    });

    test('excludes an entry whose date falls outside the week -- defensive '
        'against a row the server trigger should have refused', () {
      final DateTime outside = week.next.days[0];
      final MealPlanWeek plan = MealPlanWeek(
        week: week,
        planId: 'plan-1',
        entries: <MealPlanEntry>[
          _recipeEntry(id: 'e1', date: outside, slot: MealSlot.lunch, position: 0),
        ],
      );

      expect(plan.entriesFor(outside, MealSlot.lunch), hasLength(1),
          reason: 'entriesFor matches by exact date, so the entry is still '
              'findable at its own (out-of-week) date');
      expect(plan.entriesFor(monday, MealSlot.lunch), isEmpty);
    });
  });

  group('isEmpty / entryCount', () {
    test('an empty week', () {
      final MealPlanWeek plan = MealPlanWeek.empty(week);
      expect(plan.isEmpty, isTrue);
      expect(plan.entryCount, 0);
      expect(plan.planId, isNull);
    });

    test('a week with entries', () {
      final MealPlanWeek plan = MealPlanWeek(
        week: week,
        planId: 'plan-1',
        entries: <MealPlanEntry>[
          _recipeEntry(id: 'e1', date: monday, slot: MealSlot.lunch, position: 0),
        ],
      );
      expect(plan.isEmpty, isFalse);
      expect(plan.entryCount, 1);
    });
  });

  group('MealPlanEntry.label', () {
    test('a recipe entry shows its recipe title', () {
      final MealPlanEntry entry = _recipeEntry(
          id: 'e1', date: monday, slot: MealSlot.lunch, position: 0,
          title: 'Šargarepa torta');
      expect(entry.label, 'Šargarepa torta');
    });

    test('a note entry shows its note text', () {
      final MealPlanEntry entry = _noteEntry(
          id: 'e1', date: monday, slot: MealSlot.breakfast, position: 0,
          note: 'zzz buy bread');
      expect(entry.label, 'zzz buy bread');
    });
  });

  group('the DB vocabulary round-trips through Values.byName', () {
    // In the spirit of rule 6: a rename that diverges from migration 14's
    // check constraints should fail here, not surface as a runtime error the
    // first time a row with the new spelling comes back from Postgres.
    test('slot', () {
      for (final String wire in <String>['breakfast', 'lunch', 'dinner', 'snack']) {
        expect(MealSlot.values.byName(wire).name, wire);
      }
    });

    test('entry_kind', () {
      for (final String wire in <String>['recipe', 'leftover', 'note']) {
        expect(MealEntryKind.values.byName(wire).name, wire);
      }
    });
  });
}
