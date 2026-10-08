import 'package:flutter/material.dart';

/// A heading that groups the rows after it ("Za testo", "Fil"): a step
/// heading in the method (D153), or an ingredient section's heading (D156).
///
/// Both read the same, `titleSmall` in `primary`; only the gaps differ, and
/// the caller passes them on top of whatever the neighbouring rows already
/// pad. In the method it sits flush with the disc column, not the text
/// column, so it reads as above the steps rather than one of them. The row
/// above already ends in `xl`, so `sm` on top puts it 32 below; first in the
/// method, it takes none.
///
/// Shared by the recipe detail and the ingredient lines editor (the recipe
/// editor and import review), which is why it left the detail screen. Its
/// home is `core/recipes/`, not `core/ingredients/`: it is about a recipe's
/// structure, steps included, not about ingredients.
class RecipeGroupHeading extends StatelessWidget {
  const RecipeGroupHeading({
    required this.text,
    required this.top,
    required this.bottom,
    super.key,
  });

  final String text;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: bottom),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
