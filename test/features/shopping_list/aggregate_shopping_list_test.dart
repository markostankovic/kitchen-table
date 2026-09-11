import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/ingredients/domain/quantity.dart';
import 'package:kitchen_table/features/ingredients/domain/unit.dart';
import 'package:kitchen_table/features/ingredients/domain/unit_catalog.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_plan_entry.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_slot.dart';
import 'package:kitchen_table/features/recipes/domain/recipe_ingredient.dart';
import 'package:kitchen_table/features/shopping_list/domain/aggregate_shopping_list.dart';
import 'package:kitchen_table/features/shopping_list/domain/rational.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_item.dart';

/// The seeded units this file needs, with their real `to_base` values.
final UnitCatalog _units = UnitCatalog(
  units: <Unit>[
    const Unit(code: 'g', family: UnitFamily.mass, toBase: 1, toBaseExact: '1', isMetric: true),
    const Unit(code: 'kg', family: UnitFamily.mass, toBase: 1000, toBaseExact: '1000', isMetric: true),
    const Unit(code: 'ml', family: UnitFamily.volume, toBase: 1, toBaseExact: '1', isMetric: true),
    const Unit(code: 'dl', family: UnitFamily.volume, toBase: 100, toBaseExact: '100', isMetric: true),
    // A čaša is NOT a šolja -- 200 ml against 240. Migration 4 says aliasing
    // them would "quietly lose 40 ml in every sum".
    const Unit(code: 'cup', family: UnitFamily.volume, toBase: 240, toBaseExact: '240'),
    const Unit(code: 'glass', family: UnitFamily.volume, toBase: 200, toBaseExact: '200'),
    const Unit(code: 'kom', family: UnitFamily.count, toBase: 1, toBaseExact: '1'),
    const Unit(code: 'pinch', family: UnitFamily.other, toBase: 1, toBaseExact: '1'),
  ],
  aliases: <String, String>{},
);

int _position = 0;

RecipeIngredient _line(
  String rawText, {
  String? ingredientId,
  String? displayName,
  Quantity? quantity,
  String? unitCode,
  bool isPantryStaple = false,
  String? category,
}) =>
    RecipeIngredient(
      position: _position++,
      rawText: rawText,
      ingredientId: ingredientId,
      displayName: displayName,
      quantity: quantity,
      unitCode: unitCode,
      isPantryStaple: isPantryStaple,
      category: category,
    );

MealPlanEntry _entry({
  String? recipeId = 'r1',
  MealEntryKind kind = MealEntryKind.recipe,
  int? servings,
}) =>
    MealPlanEntry(
      id: 'e${_position++}',
      mealPlanId: 'p1',
      entryDate: DateTime(2026, 7, 6),
      slot: MealSlot.dinner,
      position: 0,
      entryKind: kind,
      recipeId: recipeId,
      servings: servings,
    );

PlannedRecipe _meal(
  List<RecipeIngredient> lines, {
  MealPlanEntry? entry,
  int? recipeServings,
}) =>
    (
      entry: entry ?? _entry(),
      recipeServings: recipeServings,
      lines: lines,
    );

ItemQuantity _only(ShoppingItem item) => item.quantities.single;

void main() {
  setUp(() => _position = 0);

  group('summing within a family', () {
    test('one ingredient from two recipes becomes one line', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(<RecipeIngredient>[
            _line('200 g brašna',
                ingredientId: 'i-brasno',
                displayName: 'brašno',
                quantity: Quantity.whole(200),
                unitCode: 'g'),
          ]),
          _meal(<RecipeIngredient>[
            _line('0.3 kg brasno',
                ingredientId: 'i-brasno',
                displayName: 'brašno',
                quantity: Quantity.fraction(3, 10),
                unitCode: 'kg'),
          ]),
        ],
        units: _units,
      );

      expect(items, hasLength(1));
      expect(items.single.displayName, 'brašno');
      expect(_only(items.single).amount, Rational(500, 1));
      expect(_only(items.single).unitCode, 'g');
    });

    test('thirds of a cup sum to an exact cup, not 239.99998 ml', () {
      // The case rule 5 exists for, and the one a double gets wrong.
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: List<PlannedRecipe>.generate(
          3,
          (_) => _meal(<RecipeIngredient>[
            _line('1/3 šolje mleka',
                ingredientId: 'i-mleko',
                displayName: 'mleko',
                quantity: Quantity.fraction(1, 3),
                unitCode: 'cup'),
          ]),
        ),
        units: _units,
      );

      expect(_only(items.single).amount, Rational(240, 1));
      expect(_only(items.single).amount.denominator, 1);
    });

    test('a čaša and a šolja stay 40 ml apart', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(<RecipeIngredient>[
            _line('1 šolja vode',
                ingredientId: 'i-voda',
                quantity: Quantity.whole(1),
                unitCode: 'cup'),
            _line('1 čaša vode',
                ingredientId: 'i-voda',
                quantity: Quantity.whole(1),
                unitCode: 'glass'),
          ]),
        ],
        units: _units,
      );

      expect(_only(items.single).amount, Rational(440, 1));
    });
  });

  group('across families (D9)', () {
    test('mass and volume of one ingredient stay separate entries', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(<RecipeIngredient>[
            _line('300 g brašna',
                ingredientId: 'i-brasno',
                quantity: Quantity.whole(300),
                unitCode: 'g'),
            _line('4 dl brašna',
                ingredientId: 'i-brasno',
                quantity: Quantity.whole(4),
                unitCode: 'dl'),
          ]),
        ],
        units: _units,
      );

      final ShoppingItem item = items.single;
      expect(item.quantities, hasLength(2));
      expect(
        item.quantities
            .firstWhere((ItemQuantity q) => q.family == UnitFamily.mass)
            .amount,
        Rational(300, 1),
      );
      expect(
        item.quantities
            .firstWhere((ItemQuantity q) => q.family == UnitFamily.volume)
            .amount,
        Rational(400, 1),
      );
    });

    test('a bare number with no unit counts as pieces', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(<RecipeIngredient>[
            _line('3 jaja',
                ingredientId: 'i-jaje', quantity: Quantity.whole(3)),
          ]),
        ],
        units: _units,
      );

      expect(_only(items.single).family, UnitFamily.count);
      expect(_only(items.single).amount, Rational(3, 1));
    });
  });

  group('rule 3: a line that cannot be summed still renders', () {
    test('an unparsed line is carried through verbatim', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(<RecipeIngredient>[_line('so po ukusu')]),
        ],
        units: _units,
      );

      expect(items.single.displayName, 'so po ukusu');
      expect(items.single.quantities, isEmpty);
      // Not repeated underneath itself -- the name already IS the raw line.
      expect(items.single.unmatchedLines, isEmpty);
    });

    test('the other family is never summed', () {
      // `prstohvat` is not a quantity -- migration 4 says so. Summing would
      // produce "4 prstohvata", which nobody buys.
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(<RecipeIngredient>[
            _line('prstohvat soli',
                ingredientId: 'i-so',
                displayName: 'so',
                quantity: Quantity.whole(1),
                unitCode: 'pinch'),
          ]),
        ],
        units: _units,
      );

      expect(items.single.quantities, isEmpty);
      expect(items.single.unmatchedLines, <String>['prstohvat soli']);
    });

    test('unmatched lines group by normalized raw text, not by spelling', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(<RecipeIngredient>[_line('Šargarepa')]),
          _meal(<RecipeIngredient>[_line('sargarepa')]),
        ],
        units: _units,
      );

      expect(items, hasLength(1));
      // The first spelling becomes the name; the second survives as the one
      // line that still says something the name does not.
      expect(items.single.displayName, 'Šargarepa');
      expect(items.single.unmatchedLines, <String>['sargarepa']);
    });

    test('a matched line keeps its structure even beside an unmatched one', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(<RecipeIngredient>[
            _line('200 g šećera',
                ingredientId: 'i-secer',
                displayName: 'šećer',
                quantity: Quantity.whole(200),
                unitCode: 'g'),
            _line('malo šećera', ingredientId: 'i-secer', displayName: 'šećer'),
          ]),
        ],
        units: _units,
      );

      expect(_only(items.single).amount, Rational(200, 1));
      expect(items.single.unmatchedLines, <String>['malo šećera']);
    });
  });

  group('leftovers and notes', () {
    test('a leftover buys nothing', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(
            <RecipeIngredient>[
              _line('200 g brašna',
                  ingredientId: 'i-brasno',
                  quantity: Quantity.whole(200),
                  unitCode: 'g'),
            ],
            entry: _entry(kind: MealEntryKind.leftover),
          ),
        ],
        units: _units,
      );

      expect(items, isEmpty);
    });

    test('a note contributes nothing', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(
            <RecipeIngredient>[],
            entry: _entry(kind: MealEntryKind.note, recipeId: null),
          ),
        ],
        units: _units,
      );

      expect(items, isEmpty);
    });
  });

  group('scaling by servings', () {
    test('doubling the servings doubles the quantities', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(
            <RecipeIngredient>[
              _line('250 g brašna',
                  ingredientId: 'i-brasno',
                  quantity: Quantity.whole(250),
                  unitCode: 'g'),
            ],
            entry: _entry(servings: 8),
            recipeServings: 4,
          ),
        ],
        units: _units,
      );

      expect(_only(items.single).amount, Rational(500, 1));
    });

    test('scaling a fraction stays exact', () {
      // 2/3 of a 240 ml cup scaled by 3/2 is exactly one cup. A double would
      // land near it; this has to land on it.
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(
            <RecipeIngredient>[
              _line('2/3 šolje mleka',
                  ingredientId: 'i-mleko',
                  quantity: Quantity.fraction(2, 3),
                  unitCode: 'cup'),
            ],
            entry: _entry(servings: 3),
            recipeServings: 2,
          ),
        ],
        units: _units,
      );

      expect(_only(items.single).amount, Rational(240, 1));
    });

    test('halving the servings halves the quantities', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(
            <RecipeIngredient>[
              _line('1 kg krompira',
                  ingredientId: 'i-krompir',
                  quantity: Quantity.whole(1),
                  unitCode: 'kg'),
            ],
            entry: _entry(servings: 2),
            recipeServings: 4,
          ),
        ],
        units: _units,
      );

      expect(_only(items.single).amount, Rational(500, 1));
    });

    test('a recipe with no serving count of its own is never scaled', () {
      // There is nothing to scale FROM, and guessing would change a quantity
      // the cook never asked to change.
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(
            <RecipeIngredient>[
              _line('250 g brašna',
                  ingredientId: 'i-brasno',
                  quantity: Quantity.whole(250),
                  unitCode: 'g'),
            ],
            entry: _entry(servings: 8),
          ),
        ],
        units: _units,
      );

      expect(_only(items.single).amount, Rational(250, 1));
    });
  });

  group('pantry staples', () {
    RecipeIngredient salt({bool staple = true}) => _line(
          '1 kašičica soli',
          ingredientId: 'i-so',
          displayName: 'so',
          quantity: Quantity.whole(5),
          unitCode: 'g',
          isPantryStaple: staple,
        );

    test('the catalog flag is carried through by default', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[_meal(<RecipeIngredient>[salt()])],
        units: _units,
      );
      expect(items.single.isPantryStaple, isTrue);
    });

    test('a household override un-flags a global staple', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[_meal(<RecipeIngredient>[salt()])],
        units: _units,
        pantryPrefs: <String, bool>{'i-so': false},
      );
      expect(items.single.isPantryStaple, isFalse);
    });

    test('a household override flags a non-staple', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[
          _meal(<RecipeIngredient>[salt(staple: false)])
        ],
        units: _units,
        pantryPrefs: <String, bool>{'i-so': true},
      );
      expect(items.single.isPantryStaple, isTrue);
    });

    test('a staple is never dropped from the snapshot, only flagged', () {
      final List<ShoppingItem> items = aggregateShoppingList(
        planned: <PlannedRecipe>[_meal(<RecipeIngredient>[salt()])],
        units: _units,
      );
      expect(items, hasLength(1));
      expect(_only(items.single).amount, Rational(5, 1));
    });
  });
}
