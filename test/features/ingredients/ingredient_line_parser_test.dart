// Tier 1 of the ingredient matcher, driven entirely by
// test/fixtures/ingredient_lines.json.
//
// The fixture is the contract, exactly as test/fixtures/normalization.json is
// for normalize_text (D5, D31). Phase 1d's Deno parser will be asserted
// against this same file, so a case added here constrains every
// implementation rather than just this one.
//
// The unit lexicon comes from test/fixtures/unit_aliases.json, which
// tool/gen_unit_alias_sql.dart also turns into a SQL test asserting the
// database agrees. So a unit code asserted here is a unit code that exists.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/ingredients/domain/ingredient_line_parser.dart';
import 'package:kitchen_table/features/ingredients/domain/parsed_ingredient_line.dart';
import 'package:kitchen_table/features/ingredients/domain/quantity.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';

UnitCatalog _catalogFromFixture() {
  final Map<String, dynamic> raw = jsonDecode(
      File('test/fixtures/unit_aliases.json').readAsStringSync())
      as Map<String, dynamic>;

  final Map<String, String> aliases = <String, String>{
    for (final MapEntry<String, dynamic> e in raw.entries)
      if (!e.key.startsWith('_')) e.key: e.value as String,
  };

  return UnitCatalog(units: const <Unit>[], aliases: aliases);
}

void main() {
  final IngredientLineParser parser =
      IngredientLineParser(_catalogFromFixture());

  final List<dynamic> fixture = jsonDecode(
      File('test/fixtures/ingredient_lines.json').readAsStringSync())
      as List<dynamic>;

  final List<Map<String, dynamic>> cases = <Map<String, dynamic>>[
    for (final Map<String, dynamic> entry
        in fixture.cast<Map<String, dynamic>>())
      if (!entry.containsKey('_comment')) entry,
  ];

  test('the fixture actually has cases', () {
    expect(cases.length, greaterThanOrEqualTo(25));
  });

  for (final Map<String, dynamic> c in cases) {
    final String raw = c['raw'] as String;

    test('parses "$raw"', () {
      final ParsedIngredientLine got = parser.parse(raw);

      // Rule 3, asserted on every single case: raw_text survives untouched,
      // whatever else the parser did or failed to do.
      expect(got.rawText, raw, reason: 'rawText must be the line as written');

      final List<dynamic>? qty = c['qty'] as List<dynamic>?;
      if (qty == null) {
        expect(got.quantity, isNull);
      } else {
        expect(got.quantity, isNotNull, reason: 'expected a quantity');
        expect(got.quantity!.numerator, qty[0]);
        expect(got.quantity!.denominator, qty[1]);
      }

      final List<dynamic>? qtyMax = c['qtyMax'] as List<dynamic>?;
      if (qtyMax == null) {
        expect(got.quantity?.isRange ?? false, isFalse);
      } else {
        expect(got.quantity!.isRange, isTrue);
        expect(got.quantity!.maxNumerator, qtyMax[0]);
        expect(got.quantity!.maxDenominator, qtyMax[1]);
      }

      expect(got.unitCode, c['unit'] as String?);
      expect(got.name, c['name'] as String?);
      expect(got.note, c['note'] as String?);
      expect(got.isOptional, (c['optional'] as bool?) ?? false);
    });
  }

  test('an empty lexicon still parses everything but the unit', () {
    // Rule 3 again, from the other direction: the lexicon is injected, and a
    // client that has not fetched it yet must degrade rather than fail.
    final IngredientLineParser bare = IngredientLineParser(UnitCatalog.empty());
    final ParsedIngredientLine got = bare.parse('2 kašike ulja, zagrejano');

    expect(got.rawText, '2 kašike ulja, zagrejano');
    expect(got.quantity, Quantity.whole(2));
    expect(got.unitCode, isNull);
    expect(got.name, 'kašike ulja');
    expect(got.note, 'zagrejano');
  });

  test('an empty line is a supported state', () {
    final ParsedIngredientLine got = parser.parse('   ');
    expect(got.rawText, '   ');
    expect(got.name, isNull);
    expect(got.quantity, isNull);
  });
}
