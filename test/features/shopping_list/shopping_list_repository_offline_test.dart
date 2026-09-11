// The three cases D66 names, proved against the real
// `ShoppingListRepository.watchLatest` -- a real `LocalShoppingListDataSource`
// over `NativeDatabase.memory()` (no new package, rule 8) and a hand-written
// fake for the network edge (no mocking package, the house style).
//
// Deliberately not a widget test: `ShoppingListRepository` and both
// datasources have no Flutter dependency, and the claim here is about the
// stream this repository produces, not about anything a screen renders.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:kitchen_table/features/meal_plan/domain/plan_week.dart';
import 'package:kitchen_table/features/shopping_list/data/local_shopping_list_datasource.dart';
import 'package:kitchen_table/features/shopping_list/data/remote_shopping_list_datasource.dart';
import 'package:kitchen_table/features/shopping_list/data/shopping_list_repository.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_item.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_list.dart';

ShoppingList _list(String id) => ShoppingList(
  id: id,
  dateFrom: DateTime(2026, 7, 6),
  dateTo: DateTime(2026, 7, 12),
  locale: 'sr',
  generatedAt: DateTime.utc(2026, 7, 5),
  updatedAt: DateTime.utc(2026, 7, 5),
  items: const <ShoppingItem>[],
);

/// Controls exactly one thing -- what `fetchLatest` does -- because that is
/// the only method `watchLatest` calls. `implements` rather than `extends`:
/// every other member throws `UnimplementedError` by omission, which is the
/// point -- a test that accidentally exercised one would fail loudly rather
/// than silently hitting a real `SupabaseClient`.
class _FakeRemote implements RemoteShoppingListDataSource {
  ShoppingList? nextList;
  AppFailure? nextFailure;

  @override
  Future<ShoppingList?> fetchLatest({required String householdId}) async {
    final AppFailure? failure = nextFailure;
    if (failure != null) throw failure;
    return nextList;
  }

  @override
  Future<String> save({
    required String householdId,
    String? mealPlanId,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String locale,
    required List<ShoppingItem> items,
  }) => throw UnimplementedError();

  @override
  Future<void> softDelete(String id) => throw UnimplementedError();

  @override
  Future<Map<String, bool>> fetchPantryPrefs({required String householdId}) =>
      throw UnimplementedError();

  @override
  Future<void> setPantryPref({
    required String householdId,
    required String ingredientId,
    required bool? alwaysHave,
  }) => throw UnimplementedError();

  @override
  Future<List<MealPlanEntry>> fetchEntriesInRange({
    required String householdId,
    required DateTime from,
    required DateTime to,
  }) => throw UnimplementedError();

  @override
  Future<String?> findPlanId({
    required String householdId,
    required PlanWeek week,
  }) => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late _FakeRemote remote;
  late ShoppingListRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    remote = _FakeRemote();
    repository = ShoppingListRepository(remote, LocalShoppingListDataSource(db));
  });

  tearDown(() => db.close());

  test('a cold cache with a successful network read yields the fresh list once', () async {
    remote.nextList = _list('l1');

    final List<ShoppingList?> emitted = await repository
        .watchLatest(householdId: 'h1')
        .toList();

    expect(emitted, <ShoppingList?>[_list('l1')]);
  });

  test('a cold cache with a NetworkFailure rethrows, honestly', () async {
    remote.nextFailure = const NetworkFailure();

    await expectLater(
      repository.watchLatest(householdId: 'h1'),
      emitsError(
        isA<NetworkFailure>().having(
          (NetworkFailure e) => e.message,
          'message',
          contains('no saved list on this phone yet'),
        ),
      ),
    );
  });

  test(
    'a warm cache with a NetworkFailure completes quietly, keeping the cached list',
    () async {
      await LocalShoppingListDataSource(db).upsertLatest(
        householdId: 'h1',
        list: _list('l1'),
      );
      remote.nextFailure = const NetworkFailure();

      final List<ShoppingList?> emitted = await repository
          .watchLatest(householdId: 'h1')
          .toList();

      // Exactly the cached value, and the stream completed -- no error ever
      // reached the caller (D66). This is the "readable in airplane mode"
      // claim, proved without an emulator.
      expect(emitted, <ShoppingList?>[_list('l1')]);
    },
  );

  test(
    'a warm cache with a successful network read yields cached then fresh, and updates the cache',
    () async {
      await LocalShoppingListDataSource(db).upsertLatest(
        householdId: 'h1',
        list: _list('l1'),
      );
      remote.nextList = _list('l2');

      final List<ShoppingList?> emitted = await repository
          .watchLatest(householdId: 'h1')
          .toList();

      expect(emitted, <ShoppingList?>[_list('l1'), _list('l2')]);

      // The cache now holds what the network answered, not what it started
      // with -- read directly, not through watchLatest, so this assertion
      // does not depend on the very method it is checking.
      final ShoppingList? cached = await LocalShoppingListDataSource(
        db,
      ).readLatest(householdId: 'h1');
      expect(cached?.id, 'l2');
    },
  );

  test(
    'a warm cache whose list the server has retired evicts the stale row',
    () async {
      await LocalShoppingListDataSource(db).upsertLatest(
        householdId: 'h1',
        list: _list('l1'),
      );
      remote.nextList = null;

      final List<ShoppingList?> emitted = await repository
          .watchLatest(householdId: 'h1')
          .toList();

      expect(emitted, <ShoppingList?>[_list('l1'), null]);
      expect(
        await LocalShoppingListDataSource(db).readLatest(householdId: 'h1'),
        isNull,
      );
    },
  );

  test('onReachable/onUnreachable report every completed attempt', () async {
    final List<String> events = <String>[];

    remote.nextList = _list('l1');
    await repository
        .watchLatest(
          householdId: 'h1',
          onReachable: () => events.add('reachable'),
          onUnreachable: () => events.add('unreachable'),
        )
        .toList();

    await LocalShoppingListDataSource(db).upsertLatest(
      householdId: 'h2',
      list: _list('l2'),
    );
    remote.nextList = null;
    remote.nextFailure = const NetworkFailure();
    await repository
        .watchLatest(
          householdId: 'h2',
          onReachable: () => events.add('reachable'),
          onUnreachable: () => events.add('unreachable'),
        )
        .toList();

    expect(events, <String>['reachable', 'unreachable']);
  });
}
