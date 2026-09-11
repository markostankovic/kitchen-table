/// The wire shapes of `shopping_list_items`'s two jsonb columns.
///
/// In `data/` rather than beside the models because rule 1 is absolute:
/// `Map<String, dynamic>` does not cross out of `data/`, and
/// `tool/check_layers.dart` enforces it. The domain models stay pure Dart
/// (rule 7) and know nothing about how they are stored.
///
/// Hand-written rather than `json_serializable`: [Rational] is not a JSON type,
/// and the column shape is fixed by migration 16 as an integer pair for the
/// same reason `qty_num`/`qty_den` are one (rule 5). Generating this would
/// mean teaching the generator a converter to produce exactly the two lines
/// below.
library;

import '../../../ingredients/domain/unit.dart';
import '../../domain/rational.dart';
import '../../domain/shopping_item.dart';

extension ItemQuantityWire on ItemQuantity {
  Map<String, dynamic> toWire() => <String, dynamic>{
    'family': family.name,
    'amount_num': amount.numerator,
    'amount_den': amount.denominator,
    'unit': unitCode,
  };
}

extension ShoppingItemWire on ShoppingItem {
  Map<String, dynamic> toWire() => <String, dynamic>{
    'ingredient_id': ingredientId,
    'display_name': displayName,
    'category': category,
    'is_pantry_staple': isPantryStaple,
    'quantities': quantities
        .map((ItemQuantity q) => q.toWire())
        .toList(growable: false),
    'unmatched_lines': unmatchedLines,
  };
}

ItemQuantity itemQuantityFromWire(Map<String, dynamic> json) => ItemQuantity(
  family: UnitFamily.values.byName(json['family'] as String),
  amount: Rational(
    (json['amount_num'] as num).toInt(),
    (json['amount_den'] as num).toInt(),
  ),
  unitCode: json['unit'] as String,
);

ShoppingItem shoppingItemFromWire(Map<String, dynamic> json) => ShoppingItem(
  ingredientId: json['ingredient_id'] as String?,
  displayName: json['display_name'] as String,
  category: json['category'] as String?,
  isPantryStaple: json['is_pantry_staple'] as bool? ?? false,
  quantities: (json['quantities'] as List<dynamic>? ?? <dynamic>[])
      .cast<Map<String, dynamic>>()
      .map(itemQuantityFromWire)
      .toList(growable: false),
  unmatchedLines: (json['unmatched_lines'] as List<dynamic>? ?? <dynamic>[])
      .cast<String>()
      .toList(growable: false),
);
