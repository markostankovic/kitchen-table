import 'package:flutter/material.dart';

import '../../../ingredients/domain/ingredient_match.dart';
import '../../../ingredients/domain/unit_catalog.dart';
import '../../domain/recipe_draft.dart';
import 'quantity_format.dart';

/// What the app made of one ingredient line, shown under the field the cook
/// is typing into.
///
/// Three states, all of them legitimate:
///
/// * **matched** -- the line resolved to a catalog ingredient, either because
///   the search said `auto_accept` or because a human picked it.
/// * **suggested** -- there is a candidate but it did not clear the bar, so it
///   is offered rather than applied. Tapping opens the picker.
/// * **no match** -- nothing fits. Not an error and not a blocker: the line
///   saves as `raw_text` and renders exactly as typed (rule 3).
///
/// The bar itself is `auto_accept`, computed in `search_ingredients`. Nothing
/// here compares a confidence to a number; the 0.75 line lives in SQL and has
/// no copy on this side (D31).
class IngredientMatchChip extends StatelessWidget {
  const IngredientMatchChip({
    required this.line,
    required this.units,
    required this.locale,
    required this.suggestion,
    required this.onTap,
    super.key,
  });

  final RecipeDraftLine line;
  final UnitCatalog units;
  final String locale;

  /// The best candidate the search returned, when the line has not resolved
  /// to one. Null when there is nothing to suggest.
  final IngredientMatch? suggestion;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Nothing typed yet, so nothing to say about it.
    if (line.rawText.trim().isEmpty) return const SizedBox.shrink();

    final ColorScheme colors = Theme.of(context).colorScheme;
    final String amount = _amount();

    final (IconData icon, String name, Color? color) = switch (line) {
      // Quantity and unit are rendered even here: tier 1 parses without a
      // catalog, so a line can be structured and unmatched at the same time.
      final RecipeDraftLine l when l.isMatched => (
          Icons.check_circle_outline,
          l.displayName ?? '',
          null,
        ),
      _ when suggestion != null => (
          Icons.help_outline,
          '${suggestion!.displayName}?',
          colors.outline,
        ),
      _ => (Icons.help_outline, 'No match', colors.outline),
    };

    final String label =
        <String>[amount, name].where((String s) => s.isNotEmpty).join(' · ');

    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: color),
        label: Text(label, style: TextStyle(color: color)),
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  /// The quantity as an exact fraction and the unit in the recipe's language.
  /// Never a decimal (rule 5), never a raw unit code.
  String _amount() => <String>[
        if (line.quantity != null) formatQuantity(line.quantity!),
        if (line.unitCode != null)
          units.displayName(line.unitCode!, locale: locale),
      ].join(' ');
}
