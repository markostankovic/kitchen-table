/// The wire shape of `shopping_lists` plus its embedded `shopping_list_items`
/// -- and the cache's own encoding of that exact shape (D65, Phase 2 part 5).
///
/// One decoder serves both a PostgREST response and a cache blob: the cache
/// stores precisely the map a network read would otherwise discard, so there
/// is one definition of "what a shopping list looks like on the wire", not a
/// second one for the cache to drift out of step with (rule 6's own
/// argument, applied to a wire shape instead of a normalization function).
///
/// Hand-written, on `shopping_item_dto.dart`'s own precedent: [Rational] is
/// not a JSON type, so [ShoppingItemWire]/[shoppingItemFromWire] already
/// exist there and are reused unchanged below -- nothing here re-serializes
/// a quantity.
library;

import '../../../meal_plan/domain/plan_week.dart' show isoDateOf, parseIsoDate;
import '../../domain/shopping_item.dart';
import '../../domain/shopping_list.dart';
import 'shopping_item_dto.dart';

/// The columns of `shopping_lists` this feature reads and caches.
const String shoppingListColumns = '''
id, meal_plan_id, date_from, date_to, locale, generated_at, updated_at,
deleted_at''';

/// The columns of `shopping_list_items`, in the order the list renders them.
const String shoppingListItemColumns = '''
id, ingredient_id, display_name, category, position, is_pantry_staple,
quantities, unmatched_lines''';

extension ShoppingListWire on ShoppingList {
  /// The same shape a PostgREST embed produces -- what the local cache
  /// stores, and what [shoppingListFromWire] reads back either way.
  ///
  /// [ShoppingItem] carries no `position` of its own; [items] is already in
  /// display order (both [shoppingListFromWire] and the repository's old
  /// `_toList` only ever produced it that way), so the list index re-derives
  /// exactly the ordering a fresh network row would carry.
  Map<String, dynamic> toWire() => <String, dynamic>{
    'id': id,
    'meal_plan_id': mealPlanId,
    'date_from': isoDateOf(dateFrom),
    'date_to': isoDateOf(dateTo),
    'locale': locale,
    'generated_at': generatedAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'shopping_list_items': <Map<String, dynamic>>[
      for (final (int position, ShoppingItem item) in items.indexed)
        <String, dynamic>{...item.toWire(), 'position': position},
    ],
  };
}

/// Decodes one `shopping_lists` row, embedded items and all -- from Supabase
/// or from the cache, indistinguishably.
///
/// PostgREST does not promise embed order, so items are sorted by the
/// `position` column that carries it, exactly as the repository's own
/// `_toList` did before this file existed.
ShoppingList shoppingListFromWire(Map<String, dynamic> row) {
  final List<Map<String, dynamic>> itemRows =
      (row['shopping_list_items'] as List<dynamic>? ?? <dynamic>[])
          .cast<Map<String, dynamic>>()
          .toList()
        ..sort(
          (Map<String, dynamic> a, Map<String, dynamic> b) =>
              (a['position'] as int).compareTo(b['position'] as int),
        );

  return ShoppingList(
    id: row['id'] as String,
    mealPlanId: row['meal_plan_id'] as String?,
    dateFrom: parseIsoDate(row['date_from'] as String),
    dateTo: parseIsoDate(row['date_to'] as String),
    locale: row['locale'] as String,
    generatedAt: DateTime.parse(row['generated_at'] as String),
    updatedAt: DateTime.parse(row['updated_at'] as String),
    items: itemRows.map(shoppingItemFromWire).toList(growable: false),
  );
}
