/// Category grouping and the clipboard export, shared between the screen and
/// [formatShoppingListAsText] so the on-screen ORDER and the exported text's
/// order cannot drift apart (D105, amended). Neither side renders the
/// category label any more -- [categoryLabel] survives only as
/// [groupByCategory]'s sort key, not as user-visible text.
///
/// A plain library, not `domain/` -- it imports the generated
/// `AppLocalizations`, which imports Flutter, and rule 7 keeps `domain/`
/// pure Dart.
library;

import '../../../core/l10n/generated/app_localizations.dart';
import '../../ingredients/domain/unit_catalog.dart';
import '../domain/format_item_quantity.dart';
import '../domain/shopping_item.dart';
import '../domain/shopping_list.dart';

/// The `ingredients.category` code for an item the catalog never assigned
/// one -- a sentinel distinct from any real code (never entered as a category
/// in `supabase/seeds/ingredients.csv`), so the uncategorised bucket is no
/// longer keyed by the literal display string `'Other'`, which used to be
/// both a display string and a map key at once.
const String uncategorisedCategory = '_uncategorised';

/// A category code's localized label, in [l10n]'s own locale -- [l10n] is
/// always looked up from `list.locale` here (never the reader's), on the
/// two-locale rule. Neither the screen nor the clipboard export renders this
/// label any more; it exists purely as [groupByCategory]'s sort key, so that
/// items still group and order the same way a heading would have implied,
/// just without the heading itself. An unrecognised code (not one of the ten
/// `supabase/seeds/ingredients.csv` knows, and not [uncategorisedCategory])
/// falls through to itself rather than vanishing or being folded into
/// "Other" -- a category the catalog adds later must still sort somewhere
/// stable. No `default` arm for the known ten, so a new one compiles only
/// once it has a label here.
String categoryLabel(String code, AppLocalizations l10n) => switch (code) {
      'produce' => l10n.categoryProduce,
      'fruit' => l10n.categoryFruit,
      'dairy' => l10n.categoryDairy,
      'meat' => l10n.categoryMeat,
      'fish' => l10n.categoryFish,
      'pantry' => l10n.categoryPantry,
      'spice' => l10n.categorySpice,
      'bakery' => l10n.categoryBakery,
      'beverage' => l10n.categoryBeverage,
      'nuts' => l10n.categoryNuts,
      uncategorisedCategory => l10n.categoryOther,
      _ => code,
    };

class CategoryGroup {
  const CategoryGroup({
    required this.code,
    required this.label,
    required this.items,
  });

  final String code;
  final String label;
  final List<ShoppingItem> items;
}

/// Groups by `ingredients.category`, with uncategorised items last under a
/// neutral heading rather than being dropped or shuffled in. Sorted by the
/// LOCALIZED label, not the raw code, so the order reads correctly in
/// whichever language [l10n] is.
List<CategoryGroup> groupByCategory(
  List<ShoppingItem> items,
  AppLocalizations l10n,
) {
  final Map<String, List<ShoppingItem>> groups =
      <String, List<ShoppingItem>>{};
  for (final ShoppingItem item in items) {
    groups
        .putIfAbsent(
            item.category ?? uncategorisedCategory, () => <ShoppingItem>[])
        .add(item);
  }

  final List<CategoryGroup> result = <CategoryGroup>[
    for (final MapEntry<String, List<ShoppingItem>> entry in groups.entries)
      CategoryGroup(
        code: entry.key,
        label: categoryLabel(entry.key, l10n),
        items: entry.value,
      ),
  ];
  result.sort((CategoryGroup a, CategoryGroup b) {
    if (a.code == uncategorisedCategory) return 1;
    if (b.code == uncategorisedCategory) return -1;
    return a.label.compareTo(b.label);
  });
  return result;
}

/// The current to-buy list as plain text, ready for the clipboard.
///
/// One item per line, no heading, no dash prefix, no blank line between
/// category blocks -- a cook pasting this into a notes app (Google Keep and
/// similar) wants a plain list, not a dash that shows up as literal text in
/// the paste. Items still come out grouped by category (uncategorised last),
/// via the same [groupByCategory] the screen uses; only the visible heading
/// is gone, not the ordering (D105, amended).
///
/// [l10n] must be looked up from `list.locale` (`lookupAppLocalizations`),
/// never the reader's ambient locale -- this is the document, same rule as
/// `_ListBody` (D94, D86). Staples (`list.probablyHave`) are never included:
/// this is what a cook takes into a shop, and the pantry is not part of
/// that. An item whose every contributing line produced no quantity
/// (`unmatchedLines`, never summed) pastes as a bare name with no amount --
/// a deliberate consequence (D105), not a bug.
String formatShoppingListAsText(
  ShoppingList list,
  UnitCatalog units,
  AppLocalizations l10n,
) {
  final StringBuffer buffer = StringBuffer();
  final List<CategoryGroup> groups = groupByCategory(list.toBuy, l10n);

  for (final CategoryGroup group in groups) {
    for (final ShoppingItem item in group.items) {
      final String quantities = item.quantities
          .map((ItemQuantity q) =>
              formatItemQuantity(q, units, locale: list.locale))
          .join(' + ');
      buffer.writeln(
        quantities.isEmpty
            ? item.displayName
            : '${item.displayName}: $quantities',
      );
    }
  }

  return buffer.toString().trimRight();
}
