import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/features/shopping_list/domain/rational.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_item.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_list.dart';
import 'package:kitchen_table/features/shopping_list/presentation/shopping_list_text.dart';

final UnitCatalog _units = UnitCatalog(
  units: <Unit>[
    const Unit(code: 'g', family: UnitFamily.mass, toBase: 1, toBaseExact: '1', isMetric: true),
    const Unit(code: 'kg', family: UnitFamily.mass, toBase: 1000, toBaseExact: '1000', isMetric: true),
    const Unit(code: 'ml', family: UnitFamily.volume, toBase: 1, toBaseExact: '1', isMetric: true),
    const Unit(code: 'l', family: UnitFamily.volume, toBase: 1000, toBaseExact: '1000', isMetric: true),
    const Unit(code: 'kom', family: UnitFamily.count, toBase: 1, toBaseExact: '1'),
  ],
  aliases: <String, String>{},
  displayNames: <String, String>{
    'g|sr': 'g',
    'kg|sr': 'kg',
    'ml|sr': 'ml',
    'l|sr': 'l',
    'kom|sr': 'kom',
    'kom|en': 'pc',
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

ShoppingList _list(List<ShoppingItem> items, {String locale = 'sr'}) =>
    ShoppingList(
      id: 'l1',
      dateFrom: DateTime(2026, 7, 6),
      dateTo: DateTime(2026, 7, 12),
      locale: locale,
      generatedAt: DateTime(2026, 7, 5),
      updatedAt: DateTime(2026, 7, 5),
      items: items,
    );

void main() {
  final AppLocalizations sr = lookupAppLocalizations(const Locale('sr'));
  final AppLocalizations en = lookupAppLocalizations(const Locale('en'));

  test('renders category headings and items in the LIST locale, not the '
      'reader\'s (D94/D86, same direction as the screen)', () {
    final String text = formatShoppingListAsText(
      _list(<ShoppingItem>[
        _item('mleko', id: 'i-mleko', category: 'dairy',
            quantities: <ItemQuantity>[_q(500, UnitFamily.volume, 'ml')]),
      ], locale: 'sr'),
      _units,
      sr,
    );

    expect(text, contains('Mlečni proizvodi'));
    expect(text, contains('- mleko: 500 ml'));
  });

  test('a list with locale "en" formats in English even when built with the '
      'en localizations, independent of any reader-side locale', () {
    final String text = formatShoppingListAsText(
      _list(<ShoppingItem>[
        _item('eggs', id: 'i-eggs', category: 'dairy',
            quantities: <ItemQuantity>[_q(6, UnitFamily.count, 'kom')]),
      ], locale: 'en'),
      _units,
      en,
    );

    expect(text, contains('Dairy'));
    expect(text, contains('- eggs: 6 pc'));
  });

  test('uncategorised items sort last', () {
    final String text = formatShoppingListAsText(
      _list(<ShoppingItem>[
        _item('nešto', id: 'i-x', category: null),
        _item('brašno', id: 'i-b', category: 'pantry'),
      ]),
      _units,
      sr,
    );

    expect(text.indexOf('Ostava'), lessThan(text.indexOf('Ostalo')));
  });

  test('two quantity families on one item join with " + ", never converted',
      () {
    final String text = formatShoppingListAsText(
      _list(<ShoppingItem>[
        _item('brašno', quantities: <ItemQuantity>[
          _q(300, UnitFamily.mass, 'g'),
          _q(480, UnitFamily.volume, 'ml'),
        ]),
      ]),
      _units,
      sr,
    );

    expect(text, contains('- brašno: 300 g + 480 ml'));
  });

  test('an item with no quantities renders as a bare name, no colon', () {
    final String text = formatShoppingListAsText(
      _list(<ShoppingItem>[
        _item('so', id: null, unmatched: <String>['so po ukusu']),
      ]),
      _units,
      sr,
    );

    expect(text.split('\n').last, '- so');
    expect(text, isNot(contains('- so:')));
  });

  test('pantry staples are absent from the exported text entirely', () {
    final String text = formatShoppingListAsText(
      _list(<ShoppingItem>[
        _item('brašno',
            quantities: <ItemQuantity>[_q(500, UnitFamily.mass, 'g')]),
        _item('so', id: 'i-so', staple: true,
            quantities: <ItemQuantity>[_q(5, UnitFamily.mass, 'g')]),
      ]),
      _units,
      sr,
    );

    expect(text, isNot(contains('so')));
  });

  test('blank line between category blocks, none trailing', () {
    final String text = formatShoppingListAsText(
      _list(<ShoppingItem>[
        _item('mleko', id: 'i-mleko', category: 'dairy'),
        _item('luk', id: 'i-luk', category: 'produce'),
      ]),
      _units,
      sr,
    );

    expect(text, isNot(endsWith('\n')));
    expect(text, contains('\n\n'));
  });
}
