import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// A short label that qualifies the thing it sits on, in one of two looks.
///
/// - **Outlined** (the default): an `outline` hairline and no fill --
///   `Nacrt` / `Draft`.
/// - **Tonal** ([tonal]): a `surfaceContainerHighest` fill and no border,
///   usually with a [leading] icon -- `Mašinski prevod` / `Machine
///   translation`.
///
/// Both are 24 tall (`xs` + a 16dp `labelMedium` line + `xs`), radius 4, the
/// label in `labelMedium` `onSurfaceVariant`.
///
/// Deliberately *not* a `Chip`. A chip in this app is a control: it is 40dp
/// high, it can be selected, and a filter row is made of them. A badge is a
/// statement about the thing it sits on and nothing taps it, so it is small,
/// tight (radius 4, the tightest step there is) and quiet -- a hairline or
/// the faintest tonal fill, never a colour with more voice than the title it
/// sits beside.
///
/// It knows no subject: what the label says, and what [leading] shows, is the
/// caller's business. [leading] is laid out at `AppSizes.iconInMeta` square;
/// the caller passes a widget sized for it.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tonal = false,
    this.leading,
    super.key,
  });

  final String label;
  final bool tonal;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget text = Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xs),
        color: tonal ? theme.colorScheme.surfaceContainerHighest : null,
        border: tonal ? null : Border.all(color: theme.colorScheme.outline),
      ),
      child: leading == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox.square(
                  dimension: AppSizes.iconInMeta,
                  child: leading,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(child: text),
              ],
            ),
    );
  }
}
