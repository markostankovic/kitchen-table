import 'package:freezed_annotation/freezed_annotation.dart';

import 'shopping_item.dart';

part 'shopping_list.freezed.dart';

/// A generated shopping list -- a snapshot, not a live document (D13).
///
/// There is no per-item checked state here and there never will be: D13 ruled
/// it out, and that is the single decision that removes offline writes, the
/// outbox and last-write-wins reasoning from the whole app (D12). Regenerating
/// soft-deletes this and writes a new one.
///
/// Pure Dart (rule 7).
@freezed
abstract class ShoppingList with _$ShoppingList {
  const ShoppingList._();

  const factory ShoppingList({
    required String id,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String locale,
    required DateTime generatedAt,

    /// From the `shopping_lists` row. Not read by anything in this part --
    /// the shopping list has no delta fetch, its "sync" is `.limit(1)` on
    /// one row -- but every household-scoped cache table carries this
    /// truthfully from day one (D71) so a later delta fetch has something to
    /// compare against instead of a field that has always lied.
    required DateTime updatedAt,
    String? mealPlanId,
    @Default(<ShoppingItem>[]) List<ShoppingItem> items,
  }) = _ShoppingList;

  bool get isEmpty => items.isEmpty;

  /// The items a cook still has to buy -- everything not flagged as already in
  /// the cupboard.
  List<ShoppingItem> get toBuy => items
      .where((ShoppingItem i) => !i.isPantryStaple)
      .toList(growable: false);

  /// Pantry staples, rendered collapsed under "Probably have" rather than
  /// hidden. Nothing is ever missing from the snapshot itself -- the flag
  /// changes where a line appears, never whether it exists.
  List<ShoppingItem> get probablyHave =>
      items.where((ShoppingItem i) => i.isPantryStaple).toList(growable: false);
}
