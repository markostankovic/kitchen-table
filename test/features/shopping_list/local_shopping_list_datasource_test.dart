// The first test/features/*/data/ test in the repo (Phase 2 part 5).
//
// Repositories are not otherwise unit-tested in this codebase -- `data/`
// correctness is asserted from the Postgres side and on the emulator. The
// local cache is different: it has no SQL suite to lean on, and the one
// property that matters most -- an exact Rational surviving a JSON round
// trip -- is exactly the kind of thing worth a fast, deterministic test
// rather than only an emulator screenshot.
//
// `NativeDatabase.memory()` needs no new package (rule 8): drift already
// ships it.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/shopping_list/data/local_shopping_list_datasource.dart';
import 'package:kitchen_table/features/shopping_list/domain/rational.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_item.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_list.dart';

/// The exact case part 4's own emulator pass verified: `2 dl` + `⅓ šolje`
/// summed to 280 ml, 200 + 80 exactly -- the reason [Rational] exists at all.
/// `prstohvat soli` carries no quantity and only its raw text, which is rule
/// 3, not a failure. Household scoping is not part of [ShoppingList] itself
/// (the domain model carries no `householdId`, the same way `RecipeIngredient`
/// carries no `deleted_at`) -- it is the key `LocalShoppingListDataSource`
/// reads and writes by, passed alongside the list.
ShoppingList _weekList(String id) => ShoppingList(
  id: id,
  dateFrom: DateTime(2026, 7, 6),
  dateTo: DateTime(2026, 7, 12),
  locale: 'sr',
  // UTC, not local: `ShoppingListWire.toWire()` sends `.toUtc()` and decoding
  // an ISO 8601 string with a `Z` suffix always yields a UTC `DateTime`
  // (exactly what a real `generated_at`/`updated_at` from Postgres does
  // too) -- `DateTime`'s `==` considers `isUtc`, so a local fixture here
  // would fail the round trip for a reason that has nothing to do with the
  // cache.
  generatedAt: DateTime.utc(2026, 7, 5, 9, 30),
  updatedAt: DateTime.utc(2026, 7, 5, 9, 30),
  items: <ShoppingItem>[
    ShoppingItem(
      ingredientId: 'ing-mleko',
      displayName: 'mleko',
      category: 'Mlečni proizvodi',
      quantities: <ItemQuantity>[
        ItemQuantity(
          family: UnitFamily.volume,
          amount: Rational(280, 1),
          unitCode: 'ml',
        ),
      ],
    ),
    const ShoppingItem(
      ingredientId: null,
      displayName: 'so',
      category: null,
      unmatchedLines: <String>['prstohvat soli'],
    ),
  ],
);

void main() {
  late AppDatabase db;
  late LocalShoppingListDataSource local;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = LocalShoppingListDataSource(db);
  });

  tearDown(() => db.close());

  test('a miss returns null', () async {
    expect(await local.readLatest(householdId: 'h1'), isNull);
  });

  test('round trip preserves the list exactly, quantities included', () async {
    final ShoppingList original = _weekList('l1');

    await local.upsertLatest(householdId: 'h1', list: original);
    final ShoppingList? read = await local.readLatest(householdId: 'h1');

    expect(read, original);
    // The exact-rational guarantee (D60), spelled out rather than trusted to
    // freezed equality alone: 280/1, not 279.999... or a rounded double.
    expect(read!.items.first.quantities.single.amount, Rational(280, 1));
    // rule 3: an unmatched line keeps its raw text through the round trip.
    expect(read.items.last.unmatchedLines, <String>['prstohvat soli']);
  });

  test("a household never sees another household's cached list", () async {
    await local.upsertLatest(householdId: 'h1', list: _weekList('l1'));

    expect(await local.readLatest(householdId: 'h2'), isNull);
    expect(await local.readLatest(householdId: 'h1'), isNotNull);
  });

  test('upserting the same id twice leaves one row', () async {
    final ShoppingList v1 = _weekList('l1');
    await local.upsertLatest(householdId: 'h1', list: v1);
    await local.upsertLatest(householdId: 'h1', list: v1);

    final List<ShoppingListCacheData> rows = await db
        .select(db.shoppingListCache)
        .get();
    expect(rows, hasLength(1));
  });

  test('evict removes the row by id', () async {
    await local.upsertLatest(householdId: 'h1', list: _weekList('l1'));

    await local.evict('l1');

    expect(await local.readLatest(householdId: 'h1'), isNull);
  });

  test(
    'upserting a NEW id for a household that already has a row replaces it '
    '-- the ordinary regenerate case, not just a same-id overwrite',
    () async {
      await local.upsertLatest(householdId: 'h1', list: _weekList('l1'));
      await local.upsertLatest(householdId: 'h1', list: _weekList('l2'));

      final ShoppingList? read = await local.readLatest(householdId: 'h1');
      expect(read?.id, 'l2');

      final List<ShoppingListCacheData> rows = await db
          .select(db.shoppingListCache)
          .get();
      expect(rows, hasLength(1));
    },
  );

  test(
    'ShoppingListCache.uniqueKeys refuses two rows for one household '
    'if something ever writes around upsertLatest',
    () async {
      // upsertLatest itself never produces this -- it deletes before it
      // inserts. This asserts the belt-and-suspenders constraint directly,
      // bypassing the datasource the way a future bug might.
      await db
          .into(db.shoppingListCache)
          .insert(
            ShoppingListCacheCompanion.insert(
              id: 'l1',
              householdId: 'h1',
              generatedAt: DateTime.utc(2026, 7, 5),
              updatedAt: DateTime.utc(2026, 7, 5),
              data: '{}',
            ),
          );

      expect(
        () => db
            .into(db.shoppingListCache)
            .insert(
              ShoppingListCacheCompanion.insert(
                id: 'l2',
                householdId: 'h1',
                generatedAt: DateTime.utc(2026, 7, 5),
                updatedAt: DateTime.utc(2026, 7, 5),
                data: '{}',
              ),
            ),
        throwsA(anything),
      );
    },
  );
}
