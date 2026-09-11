import 'package:freezed_annotation/freezed_annotation.dart';

import '../../ingredients/domain/unit.dart';
import 'rational.dart';

part 'shopping_item.freezed.dart';

/// One summed quantity, in one unit family.
///
/// An item holds a list of these rather than a single number because D9 sums
/// within a family and never across one: `brašno — 480 ml + 300 g` is two
/// entries on one line, not a conversion nobody can do without a density.
///
/// [amount] is an exact [Rational] in the family's base unit (g, ml, or one
/// piece); [unitCode] is what it should be RENDERED in, which is not the same
/// thing -- 1200 g is stored as 1200/1 and shown as `1.2 kg`.
@freezed
abstract class ItemQuantity with _$ItemQuantity {
  const ItemQuantity._();

  const factory ItemQuantity({
    required UnitFamily family,

    /// Always in the family's base unit, however [unitCode] renders it.
    required Rational amount,

    /// The `units.code` to display in, chosen at aggregation time.
    required String unitCode,
  }) = _ItemQuantity;
}

/// One line of a generated shopping list.
///
/// [displayName] is resolved from the catalog at generation time and stored,
/// not joined at read time -- that is what lets the list render in a
/// supermarket with no signal (D12), which is the reason the Drift cache
/// exists at all.
///
/// [unmatchedLines] holds the `raw_text` of every contributing line that
/// produced no quantity: an unparsed line, or a measure in the `other` family
/// (`prstohvat`, `po ukusu`), which migration 4 calls "not a quantity" and
/// which is carried through as a note rather than summed. An item may have no
/// quantities at all and only unmatched lines -- that is rule 3, not a
/// failure.
///
/// Pure Dart (rule 7).
@freezed
abstract class ShoppingItem with _$ShoppingItem {
  const ShoppingItem._();

  const factory ShoppingItem({
    /// Null for a line the catalog never matched, which groups by its
    /// normalized raw text instead.
    String? ingredientId,
    required String displayName,
    String? category,
    @Default(false) bool isPantryStaple,
    @Default(<ItemQuantity>[]) List<ItemQuantity> quantities,
    @Default(<String>[]) List<String> unmatchedLines,
  }) = _ShoppingItem;
}
