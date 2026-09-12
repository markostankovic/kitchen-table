// Phase 2 part 6b -- the meal plan's offline behaviour, proved against a
// real MealPlanRepository/LocalMealPlanDataSource over NativeDatabase.memory()
// and a hand-written fake for the network edge (no mocking package, the
// house style, on recipe_repository_offline_test.dart's precedent).

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/features/meal_plan/data/local_meal_plan_datasource.dart';
import 'package:kitchen_table/features/meal_plan/data/meal_plan_repository.dart';
import 'package:kitchen_table/features/meal_plan/data/remote_meal_plan_datasource.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_slot.dart';
import 'package:kitchen_table/features/meal_plan/domain/plan_week.dart';

Map<String, dynamic> _entryRow(
  String id, {
  String entryDate = '2026-06-01',
  String slot = 'lunch',
  int position = 0,
  String entryKind = 'note',
  String? recipeId,
  String? note = 'zzz note',
}) => <String, dynamic>{
  'id': id,
  'meal_plan_id': 'plan-1',
  'entry_date': entryDate,
  'slot': slot,
  'position': position,
  'entry_kind': entryKind,
  'recipe_id': recipeId,
  'leftover_of_entry_id': null,
  'note': entryKind == 'note' ? note : null,
  'servings': null,
  'recipes': recipeId == null ? null : <String, dynamic>{'title': 'Sarma', 'servings': 4},
};

Map<String, dynamic> _row(
  String id, {
  String weekStart = '2026-06-01',
  String updatedAt = '2026-01-01T00:00:00Z',
  String? deletedAt,
  List<Map<String, dynamic>> entries = const <Map<String, dynamic>>[],
}) => <String, dynamic>{
  'id': id,
  'week_start': weekStart,
  'updated_at': updatedAt,
  'deleted_at': deletedAt,
  'meal_plan_entries': entries,
};

/// Controls exactly the one network call `watchWeek` makes.
/// `implements` rather than `extends`: every other member throws by
/// omission, so a test that accidentally reached one fails loudly.
class _FakeRemote implements RemoteMealPlanDataSource {
  List<Map<String, dynamic>> changed = <Map<String, dynamic>>[];
  AppFailure? nextFailure;
  int fetchChangedCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchChangedSince({
    required String householdId,
    DateTime? since,
  }) async {
    fetchChangedCalls++;
    final AppFailure? failure = nextFailure;
    if (failure != null) throw failure;
    return changed;
  }

  @override
  Future<void> addRecipeEntry({
    required String householdId,
    required PlanWeek week,
    required DateTime entryDate,
    required MealSlot slot,
    required String recipeId,
  }) => throw UnimplementedError();

  @override
  Future<void> addNoteEntry({
    required String householdId,
    required PlanWeek week,
    required DateTime entryDate,
    required MealSlot slot,
    required String note,
  }) => throw UnimplementedError();

  @override
  Future<void> moveEntry({
    required String entryId,
    required DateTime entryDate,
    required MealSlot slot,
  }) => throw UnimplementedError();

  @override
  Future<void> setEntryServings({
    required String entryId,
    required int? servings,
  }) => throw UnimplementedError();

  @override
  Future<void> removeEntry(String entryId) => throw UnimplementedError();

  @override
  Future<void> addLeftoverEntry({
    required String householdId,
    required PlanWeek week,
    required DateTime entryDate,
    required MealSlot slot,
    required String sourceEntryId,
  }) => throw UnimplementedError();

  @override
  Future<void> reorderEntry({
    required String entryId,
    required int newPosition,
  }) => throw UnimplementedError();

  @override
  Future<int> countRecipeInSlot({
    required String householdId,
    required String recipeId,
    required MealSlot slot,
    required DateTime from,
    required DateTime to,
  }) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late _FakeRemote remote;
  late MealPlanRepository repository;

  final PlanWeek week = PlanWeek.fromIsoDate('2026-06-01');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    remote = _FakeRemote();
    repository = MealPlanRepository(remote, LocalMealPlanDataSource(db));
  });

  tearDown(() => db.close());

  group('watchWeek', () {
    test('a cold cache with a successful network read yields the fresh week once', () async {
      remote.changed = <Map<String, dynamic>>[
        _row('plan-1', entries: <Map<String, dynamic>>[_entryRow('e1')]),
      ];

      final emitted = await repository
          .watchWeek(householdId: 'h1', week: week)
          .toList();

      expect(emitted.length, 1);
      expect(emitted.single.planId, 'plan-1');
      expect(emitted.single.entries.map((e) => e.id), <String>['e1']);
    });

    test('a cold cache with a NetworkFailure rethrows, honestly', () async {
      remote.nextFailure = const NetworkFailure();

      await expectLater(
        repository.watchWeek(householdId: 'h1', week: week),
        emitsError(
          isA<NetworkFailure>().having(
            (NetworkFailure e) => e.message,
            'message',
            contains('no saved plan on this phone yet'),
          ),
        ),
      );
    });

    test(
      'a warm cache with a NetworkFailure completes quietly, keeping the cached week',
      () async {
        await LocalMealPlanDataSource(db).upsertMany(
          householdId: 'h1',
          rows: <Map<String, dynamic>>[
            _row('plan-1', entries: <Map<String, dynamic>>[_entryRow('e1')]),
          ],
        );
        remote.nextFailure = const NetworkFailure();

        final emitted = await repository
            .watchWeek(householdId: 'h1', week: week)
            .toList();

        expect(emitted.single.planId, 'plan-1');
      },
    );

    test(
      "D75: a live watermark plus a missing week is an authoritative empty "
      "week under a NetworkFailure, not a thrown error",
      () async {
        // Simulate a household that has already been fully synced (a
        // watermark exists) but never wrote into THIS particular week.
        await LocalMealPlanDataSource(db).advanceWeeksWatermark(
          'h1',
          DateTime.utc(2026, 1, 1),
        );
        remote.nextFailure = const NetworkFailure();

        final emitted = await repository
            .watchWeek(householdId: 'h1', week: week)
            .toList();

        expect(emitted.single.isEmpty, isTrue);
        expect(emitted.single.planId, isNull);
      },
    );

    test('a soft-deleted plan in the delta evicts it from the cache', () async {
      await LocalMealPlanDataSource(db).upsertMany(
        householdId: 'h1',
        rows: <Map<String, dynamic>>[
          _row('plan-1', entries: <Map<String, dynamic>>[_entryRow('e1')]),
        ],
      );
      remote.changed = <Map<String, dynamic>>[
        _row(
          'plan-1',
          deletedAt: '2026-02-01T00:00:00Z',
          // A soft delete does not cascade to entries -- they can still be
          // embedded, and must be ignored once the plan itself is evicted.
          entries: <Map<String, dynamic>>[_entryRow('e1')],
        ),
      ];

      final emitted = await repository
          .watchWeek(householdId: 'h1', week: week)
          .toList();

      expect(emitted.last.isEmpty, isTrue);
      expect(
        await LocalMealPlanDataSource(db).readWeek(householdId: 'h1', week: week),
        isNull,
      );
    });

    test(
      'the watermark advances to the max(updated_at) actually received, not now()',
      () async {
        remote.changed = <Map<String, dynamic>>[
          _row('plan-1', weekStart: '2026-06-01', updatedAt: '2020-06-01T00:00:00Z'),
          _row('plan-2', weekStart: '2026-06-08', updatedAt: '2020-01-01T00:00:00Z'),
        ];

        await repository.watchWeek(householdId: 'h1', week: week).toList();

        expect(
          await LocalMealPlanDataSource(db).readWeeksWatermark('h1'),
          DateTime.utc(2020, 6, 1),
        );
      },
    );

    test('onReachable / onUnreachable fire in the right order across two runs', () async {
      final events = <String>[];

      remote.changed = <Map<String, dynamic>>[_row('plan-1')];
      await repository
          .watchWeek(
            householdId: 'h1',
            week: week,
            onReachable: () => events.add('reachable'),
            onUnreachable: () => events.add('unreachable'),
          )
          .toList();

      remote.nextFailure = const NetworkFailure();
      await repository
          .watchWeek(
            householdId: 'h1',
            week: week,
            onReachable: () => events.add('reachable'),
            onUnreachable: () => events.add('unreachable'),
          )
          .toList();

      expect(events, <String>['reachable', 'unreachable']);
    });
  });
}
