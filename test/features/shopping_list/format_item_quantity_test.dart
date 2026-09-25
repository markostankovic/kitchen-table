import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/features/shopping_list/domain/format_item_quantity.dart';
import 'package:kitchen_table/features/shopping_list/domain/rational.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_item.dart';

final UnitCatalog _units = UnitCatalog(
  units: <Unit>[
    const Unit(code: 'g', family: UnitFamily.mass, toBase: 1, toBaseExact: '1', isMetric: true),
    const Unit(code: 'kg', family: UnitFamily.mass, toBase: 1000, toBaseExact: '1000', isMetric: true),
    const Unit(code: 'ml', family: UnitFamily.volume, toBase: 1, toBaseExact: '1', isMetric: true),
    const Unit(code: 'dl', family: UnitFamily.volume, toBase: 100, toBaseExact: '100', isMetric: true),
    const Unit(code: 'l', family: UnitFamily.volume, toBase: 1000, toBaseExact: '1000', isMetric: true),
    const Unit(code: 'kom', family: UnitFamily.count, toBase: 1, toBaseExact: '1'),
  ],
  aliases: <String, String>{},
  displayNames: <String, String>{
    'g|sr': 'g',
    'kg|sr': 'kg',
    'ml|sr': 'ml',
    'dl|sr': 'dl',
    'l|sr': 'l',
    'kom|sr': 'kom',
    'kom|en': 'pc',
  },
);

ItemQuantity _q(int num, int den, UnitFamily family, String code) =>
    ItemQuantity(family: family, amount: Rational(num, den), unitCode: code);

String _f(ItemQuantity q, {String locale = 'sr'}) =>
    formatItemQuantity(q, _units, locale: locale);

void main() {
  test('a value below the next step up stays where it is', () {
    expect(_f(_q(800, 1, UnitFamily.mass, 'g')), '800 g');
  });

  test('scales up to the largest metric unit that leaves at least 1', () {
    expect(_f(_q(1200, 1, UnitFamily.mass, 'g')), '1.2 kg');
    expect(_f(_q(2500, 1, UnitFamily.volume, 'ml')), '2.5 l');
    // Not 4 dl: a decilitre is a recipe unit, not a shopping one.
    expect(_f(_q(400, 1, UnitFamily.volume, 'ml')), '400 ml');
  });

  test('an exact kilogram reads as a whole number, not 1.00', () {
    expect(_f(_q(1000, 1, UnitFamily.mass, 'g')), '1 kg');
  });

  test('counts never scale -- there is no ladder above one piece', () {
    expect(_f(_q(3, 1, UnitFamily.count, 'kom')), '3 kom');
  });

  test('renders the unit in the reader locale', () {
    expect(_f(_q(3, 1, UnitFamily.count, 'kom'), locale: 'en'), '3 pc');
  });

  test('a fraction that survived the sum rounds only at the last step', () {
    // 1/3 of a litre. The arithmetic stayed exact; only the printing rounds.
    expect(_f(_q(1000, 3, UnitFamily.volume, 'ml')), '333.33 ml');
  });

  test('trailing zeros are trimmed', () {
    expect(_f(_q(1500, 1, UnitFamily.mass, 'g')), '1.5 kg');
  });

  group('formatItemQuantityParts', () {
    ({String number, String unit}) parts(
      ItemQuantity q, {
      String locale = 'sr',
    }) => formatItemQuantityParts(q, _units, locale: locale);

    test('scales exactly as formatItemQuantity does, split in two', () {
      expect(parts(_q(1200, 1, UnitFamily.mass, 'g')), (
        number: '1.2',
        unit: 'kg',
      ));
    });

    test('a count unit never scales', () {
      expect(parts(_q(3, 1, UnitFamily.count, 'kom')), (
        number: '3',
        unit: 'kom',
      ));
    });

    test('spells the unit in the given locale', () {
      expect(parts(_q(3, 1, UnitFamily.count, 'kom')).unit, 'kom');
      expect(parts(_q(3, 1, UnitFamily.count, 'kom'), locale: 'en').unit, 'pc');
    });

    test('formatItemQuantity is the two parts joined -- they cannot drift', () {
      for (final ItemQuantity q in <ItemQuantity>[
        _q(800, 1, UnitFamily.mass, 'g'),
        _q(1200, 1, UnitFamily.mass, 'g'),
        _q(1000, 3, UnitFamily.volume, 'ml'),
        _q(3, 1, UnitFamily.count, 'kom'),
      ]) {
        for (final String locale in <String>['sr', 'en']) {
          final ({String number, String unit}) p = parts(q, locale: locale);
          expect(_f(q, locale: locale), '${p.number} ${p.unit}');
        }
      }
    });
  });
}
