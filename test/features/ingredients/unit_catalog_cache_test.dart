// Phase 2 part 5 -- proves the two bugs the unit catalog cache exists to
// prevent are actually dead, not just plausible:
//
// 1. `to_base` surviving as the exact string PostgREST sent, never rounded
//    through a `double` (D60's guarantee, extended to the cache).
// 2. A catalog rebuilt from a cache hit renders count-family units in their
//    Serbian spelling, not their raw code -- `formatItemQuantity` finding no
//    `kg`/`l` rung on an empty catalog is exactly what
//    `shopping_list_screen.dart`'s old `?? UnitCatalog.empty()` fallback
//    produced offline before this part existed.
//
// Fixture rows, not the real seed: this asserts the round trip is correct,
// not that the seed migration is -- that is the emulator's job.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/features/ingredients/data/dto/unit_catalog_dto.dart';
import 'package:kitchen_table/features/ingredients/data/local_ingredient_datasource.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/features/shopping_list/domain/format_item_quantity.dart';
import 'package:kitchen_table/features/shopping_list/domain/rational.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_item.dart';

final List<Map<String, dynamic>> _unitRows = <Map<String, dynamic>>[
  <String, dynamic>{
    'code': 'g',
    'family': 'mass',
    'to_base': '1',
    'is_metric': true,
  },
  <String, dynamic>{
    'code': 'kg',
    'family': 'mass',
    // The exact decimal PostgREST would send for a value that does not fit
    // a double cleanly -- the string is what must survive, not "close to".
    'to_base': '1000',
    'is_metric': true,
  },
  <String, dynamic>{
    'code': 'oz',
    'family': 'mass',
    'to_base': '28.349523125',
    'is_metric': false,
  },
  <String, dynamic>{
    'code': 'clove',
    'family': 'count',
    'to_base': '1',
    'is_metric': false,
  },
];

final List<Map<String, dynamic>> _nameRows = <Map<String, dynamic>>[
  <String, dynamic>{
    'unit_code': 'g',
    'name': 'g',
    'locale': 'sr',
    'is_display_name': true,
  },
  <String, dynamic>{
    'unit_code': 'kg',
    'name': 'kg',
    'locale': 'sr',
    'is_display_name': true,
  },
  <String, dynamic>{
    'unit_code': 'clove',
    'name': 'čen',
    'locale': 'sr',
    'is_display_name': true,
  },
  <String, dynamic>{
    'unit_code': 'clove',
    'name': 'cen',
    'locale': 'sr',
    'is_display_name': false,
  },
];

void main() {
  late AppDatabase db;
  late LocalIngredientDataSource local;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    local = LocalIngredientDataSource(db);
  });

  tearDown(() => db.close());

  test('a miss returns null', () async {
    expect(await local.readUnitCatalog(), isNull);
  });

  test('round trip keeps to_base as the exact string, not a double', () async {
    await local.writeUnitCatalog((unitRows: _unitRows, nameRows: _nameRows));

    final UnitCatalogRows read = (await local.readUnitCatalog())!;

    final Map<String, dynamic> oz = read.unitRows.firstWhere(
      (Map<String, dynamic> r) => r['code'] == 'oz',
    );
    expect(oz['to_base'], '28.349523125');
  });

  test(
    'a catalog rebuilt from the cache renders kg and čen, not g and clove',
    () async {
      await local.writeUnitCatalog((unitRows: _unitRows, nameRows: _nameRows));
      final UnitCatalogRows cached = (await local.readUnitCatalog())!;

      // The real production decoder, not a hand-rolled copy of it: this is
      // what proves the cache round trip is correct, not merely plausible.
      final UnitCatalog catalog = unitCatalogFromRows(cached);

      // 1200 g scales to 1.2 kg through the cached catalog exactly as it
      // would online -- the bug shopping_list_screen.dart's old
      // `?? UnitCatalog.empty()` fallback produced.
      final ItemQuantity mass = ItemQuantity(
        family: UnitFamily.mass,
        amount: Rational(1200, 1),
        unitCode: 'g',
      );
      expect(formatItemQuantity(mass, catalog), '1.2 kg');

      // The count unit's Serbian display name, not its raw code.
      expect(catalog.displayName('clove', locale: 'sr'), 'čen');
    },
  );
}
