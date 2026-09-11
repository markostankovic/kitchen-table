import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/ingredients/ingredient_catalog_providers.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/features/shopping_list/application/shopping_list_providers.dart';
import 'package:kitchen_table/features/shopping_list/domain/rational.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_item.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_list.dart';
import 'package:kitchen_table/features/shopping_list/presentation/shopping_list_screen.dart';

/// Captured calls, kept off the notifier: `riverpod_lint`'s
/// `avoid_public_notifier_properties` forbids public fields on a `Notifier`
/// subclass, so the spy lives here (the same arrangement
/// `meal_plan_screen_test.dart` uses).
class _Calls {
  int generated = 0;
  ({String ingredientId, bool? alwaysHave})? pantryPref;
}

/// Overridden through Riverpod rather than mocked -- no mocking package, so
/// rule 8 is never triggered. Every write is replaced because a real one
/// would reach `currentHouseholdIdProvider` and on to
/// `Supabase.instance.client`, which this suite deliberately never provides.
class _StubList extends CurrentShoppingList {
  _StubList(this.initial, this.calls, {this.failure});

  final ShoppingList? initial;
  final _Calls calls;
  final AppFailure? failure;

  @override
  Future<ShoppingList?> build() async => initial;

  @override
  Future<void> generate() async {
    calls.generated++;
    final AppFailure? f = failure;
    if (f != null) throw f;
  }

  @override
  Future<void> setPantryPref({
    required String ingredientId,
    required bool? alwaysHave,
  }) async {
    calls.pantryPref = (ingredientId: ingredientId, alwaysHave: alwaysHave);
  }

  @override
  Future<void> discard() async {}
}

/// A range pinned off the clock, so nothing here depends on today's date.
class _PinnedRange extends ShoppingRange {
  @override
  ({DateTime from, DateTime to}) build() =>
      (from: DateTime(2026, 7, 6), to: DateTime(2026, 7, 12));
}

final UnitCatalog _units = UnitCatalog(
  units: <Unit>[
    const Unit(code: 'g', family: UnitFamily.mass, toBase: 1, toBaseExact: '1', isMetric: true),
    const Unit(code: 'kg', family: UnitFamily.mass, toBase: 1000, toBaseExact: '1000', isMetric: true),
    const Unit(code: 'ml', family: UnitFamily.volume, toBase: 1, toBaseExact: '1', isMetric: true),
    const Unit(code: 'dl', family: UnitFamily.volume, toBase: 100, toBaseExact: '100', isMetric: true),
    const Unit(code: 'l', family: UnitFamily.volume, toBase: 1000, toBaseExact: '1000', isMetric: true),
  ],
  aliases: <String, String>{},
  displayNames: <String, String>{
    'g|sr': 'g',
    'kg|sr': 'kg',
    'ml|sr': 'ml',
    'dl|sr': 'dl',
    'l|sr': 'l',
  },
);

ShoppingItem _item(
  String name, {
  String? id = 'i-1',
  String? category = 'pantry',
  bool staple = false,
  List<ItemQuantity> quantities = const <ItemQuantity>[],
  List<String> unmatched = const <String>[],
}) =>
    ShoppingItem(
      ingredientId: id,
      displayName: name,
      category: category,
      isPantryStaple: staple,
      quantities: quantities,
      unmatchedLines: unmatched,
    );

ItemQuantity _q(int amount, UnitFamily family, String code) =>
    ItemQuantity(family: family, amount: Rational(amount, 1), unitCode: code);

ShoppingList _list(List<ShoppingItem> items) => ShoppingList(
      id: 'l1',
      dateFrom: DateTime(2026, 7, 6),
      dateTo: DateTime(2026, 7, 12),
      locale: 'sr',
      generatedAt: DateTime(2026, 7, 5),
      items: items,
    );

Future<_Calls> _pump(
  WidgetTester tester, {
  ShoppingList? initial,
  AppFailure? failure,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final _Calls calls = _Calls();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentShoppingListProvider
            .overrideWith(() => _StubList(initial, calls, failure: failure)),
        shoppingRangeProvider.overrideWith(() => _PinnedRange()),
        unitCatalogProvider.overrideWith((Ref ref) async => _units),
      ],
      child: const MaterialApp(home: ShoppingListScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return calls;
}

void main() {
  testWidgets('titles the tab List whatever the providers do', (tester) async {
    // app_shell_test.dart taps this tab and asserts the title, so it is built
    // outside the AsyncValue.when on purpose.
    await _pump(tester);
    expect(find.text('List'), findsOneWidget);
  });

  testWidgets('with no list, offers to generate one', (tester) async {
    final _Calls calls = await _pump(tester);

    expect(find.text('No list yet.'), findsOneWidget);
    await tester.tap(find.text('Generate list'));
    await tester.pumpAndSettle();

    expect(calls.generated, 1);
  });

  testWidgets('a failure to generate is shown, not swallowed', (tester) async {
    await _pump(tester,
        failure: const NetworkFailure(message: 'You appear to be offline.'));

    await tester.tap(find.text('Generate list'));
    await tester.pumpAndSettle();

    expect(find.text('You appear to be offline.'), findsOneWidget);
  });

  testWidgets('renders an item with its summed quantity', (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('brašno',
            quantities: <ItemQuantity>[_q(1200, UnitFamily.mass, 'g')]),
      ]),
    );

    expect(find.text('brašno'), findsOneWidget);
    expect(find.text('1.2 kg'), findsOneWidget);
  });

  testWidgets('two families on one line are shown side by side, never merged',
      (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('brašno', quantities: <ItemQuantity>[
          _q(300, UnitFamily.mass, 'g'),
          _q(480, UnitFamily.volume, 'ml'),
        ]),
      ]),
    );

    expect(find.text('300 g + 480 ml'), findsOneWidget);
  });

  testWidgets('an unmatched line renders verbatim (rule 3)', (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('so', id: null, unmatched: <String>['so po ukusu']),
      ]),
    );

    expect(find.text('so po ukusu'), findsOneWidget);
  });

  testWidgets('pantry staples are collapsed under Probably have, not hidden',
      (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('brašno',
            quantities: <ItemQuantity>[_q(500, UnitFamily.mass, 'g')]),
        _item('so',
            id: 'i-so',
            staple: true,
            quantities: <ItemQuantity>[_q(5, UnitFamily.mass, 'g')]),
      ]),
    );

    expect(find.text('Probably have (1)'), findsOneWidget);
    // Collapsed: present in the tree as a heading, the item itself not yet
    // rendered.
    expect(find.text('so'), findsNothing);

    await tester.tap(find.text('Probably have (1)'));
    await tester.pumpAndSettle();

    // Expanding shows it -- nothing was ever dropped from the snapshot.
    expect(find.text('so'), findsOneWidget);
  });

  testWidgets('items are grouped by category, with Other last', (tester) async {
    await _pump(
      tester,
      initial: _list(<ShoppingItem>[
        _item('nešto', id: 'i-x', category: null),
        _item('brašno', id: 'i-b', category: 'pantry'),
      ]),
    );

    final double pantryY = tester.getTopLeft(find.text('pantry')).dy;
    final double otherY = tester.getTopLeft(find.text('Other')).dy;
    expect(pantryY, lessThan(otherY));
  });

  testWidgets('long-pressing an item records a pantry override', (tester) async {
    final _Calls calls = await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('brašno', id: 'i-brasno')]),
    );

    await tester.longPress(find.text('brašno'));
    await tester.pumpAndSettle();

    expect(calls.pantryPref?.ingredientId, 'i-brasno');
    expect(calls.pantryPref?.alwaysHave, isTrue);
    // The snapshot is not rearranged under the cook -- it says so instead.
    expect(find.textContaining('next time you generate'), findsOneWidget);
  });

  testWidgets('an unmatched item cannot be given a pantry override',
      (tester) async {
    // There is no ingredient id to hang the preference off.
    final _Calls calls = await _pump(
      tester,
      initial: _list(<ShoppingItem>[_item('so po ukusu', id: null)]),
    );

    await tester.longPress(find.text('so po ukusu'));
    await tester.pumpAndSettle();

    expect(calls.pantryPref, isNull);
  });

  testWidgets('regenerating is not offered before a list exists',
      (tester) async {
    await _pump(tester);
    expect(find.byTooltip('Regenerate'), findsNothing);
  });

  testWidgets('regenerating is offered once a list exists', (tester) async {
    await _pump(tester, initial: _list(<ShoppingItem>[_item('brašno')]));
    expect(find.byTooltip('Regenerate'), findsOneWidget);
  });
}
