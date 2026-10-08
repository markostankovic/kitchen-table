import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// The mustard `{name}?` pill under an unmatched ingredient line, with `Tap to
/// confirm` beside it (`docs/DESIGN_SYSTEM.md` § Ingredient lines).
///
/// It offers the search's top candidate for a line that did not clear the
/// `auto_accept` bar. Tapping it **confirms** that candidate as the cook's own
/// match (D7: `manual`); choosing a different one is the open line's preview,
/// not this. Both the closed rows and the open line draw it, which is why it
/// has a file of its own.
///
/// Two people, as everywhere on these lines (D86): the `{name}?` wrapper and
/// the hint are chrome and follow the reader; [name] is the catalog's name in
/// the recipe's language, as the search returned it.
///
/// Drawn [AppSizes.tag] tall on a stadium, with a 48dp hit area. A `Wrap`, so
/// at 360dp in Serbian the hint drops under the pill instead of overflowing.
class IngredientSuggestionPill extends StatelessWidget {
  const IngredientSuggestionPill({
    required this.name,
    required this.onConfirm,
    super.key,
  });

  final String name;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);

    // Material + InkWell rather than an ActionChip: the chip theme's 8dp
    // radius and 40dp height would both need overriding.
    final Widget pill = Material(
      color: scheme.secondaryContainer,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('ingredientSuggestionPill'),
        onTap: onConfirm,
        child: SizedBox(
          height: AppSizes.tag,
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              right: AppSpacing.md,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // The chip theme's icon size.
                Icon(
                  Icons.check,
                  size: 18,
                  color: scheme.onSecondaryContainer,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    l10n.ingredientSuggestionLabel(name),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSecondaryContainer,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Wrap(
      spacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        // The drawing is 32 tall; the hit area is not (AppSizes.tag). A tap
        // in the 8dp above or below the pill still confirms.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onConfirm,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.target),
            child: Align(widthFactor: 1, heightFactor: 1, child: pill),
          ),
        ),
        Text(
          l10n.ingredientSuggestionConfirmHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
