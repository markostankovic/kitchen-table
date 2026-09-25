import 'package:flutter/material.dart';

import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

/// A short label in a hairline outline -- `Nacrt` / `Draft`, and whatever
/// later needs the same weight.
///
/// Deliberately *not* a `Chip`. A chip in this app is a control: it is 40dp
/// high, it can be selected, and a filter row is made of them. A badge is a
/// statement about the thing it sits on and nothing taps it, so it is small,
/// tight (radius 4, the tightest step there is) and outlined rather than
/// filled -- a fill would give it more voice than the title it sits beside.
///
/// It knows no subject: what the label says is the caller's business.
class AppBadge extends StatelessWidget {
  const AppBadge({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xs),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
