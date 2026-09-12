// Phase 2 part 6b -- the meal plan week cache round trip. Deliberately not a
// widget test: this has no Flutter dependency, and the claim is about what a
// real drift database round-trips, not about anything a screen renders.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/features/meal_plan/data/local_meal_plan_datasource.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_slot.dart';
import 'package:kitchen_table/features/meal_plan/domain/plan_week.dart';

Map<String, dynamic> _entryRow(
  String id, {
  required String entryDate,
  String slot = 'lunch',
  int position = 0,
  String entryKind = 'note',
  String? recipeId,
  String? leftoverOfEntryId,
  String? note = 'zzz note',
  int? servings,
  Map<String, dynamic>? recipe,
}) => <String, dynamic>{
  'id': id,
  'meal_plan_id': 'plan-1',
  'entry_date': entryDate,
  'slot': slot,
  'position': position,
  'entry_kind': entryKind,
  'recipe_id': recipeId,
  'leftover_of_entry_id': leftoverOfEntryId,
  'note': entryKind == 'note' ? note : null,
  'servings': servings,
  'recipes': recipe,
};

Map<String, dynamic> _weekRow(
  String id, {
  String weekStart = '2026-06-01',
  required String updatedAt,
  List<Map<String, dynamic>> entries = const <Map<String, dynamic>>[],
}) => <String, dynamic>{
  'id': id,
  'week_start': weekStart,
  'updated_at': updatedAt,
  'deleted_at': null,
  'meal_plan_entries': entries,
};

void main() {
  late AppDatabase db;
  late LocalMealPlanDataSource local;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = LocalMealPlanDataSource(db);
  });

  tearDown(() => db.close());

  test('a miss returns null, and the watermark reads null', () async {
    expect(
      await local.readWeek(
        householdId: 'h1',
        week: PlanWeek.fromIsoDate('2026-06-01'),
      ),
      isNull,
    );
    expect(await local.readWeeksWatermark('h1'), isNull);
  });

  test(
    'a week with a recipe entry, a note and a leftover round-trips: the '
    'recipe embed and entryDate/slot/position are all intact',
    () async {
      await local.upsertMany(
        householdId: 'h1',
        rows: <Map<String, dynamic>>[
          _weekRow(
            'plan-1',
            updatedAt: '2026-01-01T00:00:00Z',
            entries: <Map<String, dynamic>>[
              _entryRow(
                'e2',
                entryDate: '2026-06-02',
                slot: 'breakfast',
                entryKind: 'note',
                note: 'zzz second',
                position: 0,
              ),
              _entryRow(
                'e1',
                entryDate: '2026-06-01',
                slot: 'lunch',
                entryKind: 'recipe',
                recipeId: 'r1',
                recipe: <String, dynamic>{'title': 'Sarma', 'servings': 4},
                position: 0,
              ),
              _entryRow(
                'e3',
                entryDate: '2026-06-03',
                slot: 'dinner',
                entryKind: 'leftover',
                recipeId: 'r1',
                leftoverOfEntryId: 'e1',
                recipe: <String, dynamic>{'title': 'Sarma', 'servings': 4},
                position: 0,
              ),
            ],
          ),
        ],
      );

      final week = await local.readWeek(
        householdId: 'h1',
        week: PlanWeek.fromIsoDate('2026-06-01'),
      );

      expect(week, isNotNull);
      expect(week!.planId, 'plan-1');
      expect(week.entries.map((e) => e.id).toSet(), <String>{'e1', 'e2', 'e3'});

      final MealPlanEntry recipeEntry =
          week.entries.firstWhere((e) => e.id == 'e1');
      expect(recipeEntry.recipeTitle, 'Sarma');
      expect(recipeEntry.recipeServings, 4);
      expect(recipeEntry.entryDate, DateTime(2026, 6, 1));
      expect(recipeEntry.slot, MealSlot.lunch);

      expect(week.entries.firstWhere((e) => e.id == 'e3').isLeftover, isTrue);
      expect(
        week.entries.firstWhere((e) => e.id == 'e2').entryDate,
        DateTime(2026, 6, 2),
      );
    },
  );

  test(
    'entriesFor sorts entries sharing one slot by position',
    () async {
      await local.upsertMany(
        householdId: 'h1',
        rows: <Map<String, dynamic>>[
          _weekRow(
            'plan-1',
            updatedAt: '2026-01-01T00:00:00Z',
            entries: <Map<String, dynamic>>[
              _entryRow('e-second', entryDate: '2026-06-01', slot: 'lunch', position: 1),
              _entryRow('e-first', entryDate: '2026-06-01', slot: 'lunch', position: 0),
            ],
          ),
        ],
      );

      final week = await local.readWeek(
        householdId: 'h1',
        week: PlanWeek.fromIsoDate('2026-06-01'),
      );

      final ordered = week!.entriesFor(DateTime(2026, 6, 1), MealSlot.lunch);
      expect(ordered.map((e) => e.id), <String>['e-first', 'e-second']);
    },
  );

  test('readWeek is scoped to the household', () async {
    await local.upsertMany(
      householdId: 'h1',
      rows: <Map<String, dynamic>>[_weekRow('p1', updatedAt: '2026-01-01T00:00:00Z')],
    );
    await local.upsertMany(
      householdId: 'h2',
      rows: <Map<String, dynamic>>[_weekRow('p2', updatedAt: '2026-01-01T00:00:00Z')],
    );

    final PlanWeek week = PlanWeek.fromIsoDate('2026-06-01');
    expect((await local.readWeek(householdId: 'h1', week: week))?.planId, 'p1');
    expect((await local.readWeek(householdId: 'h2', week: week))?.planId, 'p2');
  });

  test('readWeek is scoped to the week', () async {
    await local.upsertMany(
      householdId: 'h1',
      rows: <Map<String, dynamic>>[
        _weekRow('p1', weekStart: '2026-06-01', updatedAt: '2026-01-01T00:00:00Z'),
        _weekRow('p2', weekStart: '2026-06-08', updatedAt: '2026-01-01T00:00:00Z'),
      ],
    );

    expect(
      (await local.readWeek(
        householdId: 'h1',
        week: PlanWeek.fromIsoDate('2026-06-01'),
      ))?.planId,
      'p1',
    );
    expect(
      (await local.readWeek(
        householdId: 'h1',
        week: PlanWeek.fromIsoDate('2026-06-08'),
      ))?.planId,
      'p2',
    );
  });

  test('evict removes the row', () async {
    await local.upsertMany(
      householdId: 'h1',
      rows: <Map<String, dynamic>>[_weekRow('p1', updatedAt: '2026-01-01T00:00:00Z')],
    );

    await local.evict('p1');

    expect(
      await local.readWeek(
        householdId: 'h1',
        week: PlanWeek.fromIsoDate('2026-06-01'),
      ),
      isNull,
    );
  });

  test(
    'MealPlanWeekCache.uniqueKeys refuses two rows for one household/week '
    'if something ever writes around upsertMany',
    () async {
      // upsertMany itself never produces this -- it upserts by primary key
      // (id), which never collides for two different plans. This asserts
      // the belt-and-suspenders constraint directly, bypassing the
      // datasource the way a future bug might (`ShoppingListCache`'s own
      // uniqueKeys test makes the identical point).
      await db.into(db.mealPlanWeekCache).insert(
        MealPlanWeekCacheCompanion.insert(
          id: 'p1',
          householdId: 'h1',
          weekStart: '2026-06-01',
          updatedAt: DateTime.utc(2026, 1, 1),
          data: '{}',
        ),
      );

      expect(
        () => db.into(db.mealPlanWeekCache).insert(
          MealPlanWeekCacheCompanion.insert(
            id: 'p2',
            householdId: 'h1',
            weekStart: '2026-06-01',
            updatedAt: DateTime.utc(2026, 1, 1),
            data: '{}',
          ),
        ),
        throwsA(anything),
      );
    },
  );

  test('the watermark reads back exactly what it advanced to', () async {
    await local.advanceWeeksWatermark('h1', DateTime.utc(2026, 3, 4));
    expect(await local.readWeeksWatermark('h1'), DateTime.utc(2026, 3, 4));
  });
}
