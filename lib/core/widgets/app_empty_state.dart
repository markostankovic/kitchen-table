import 'package:flutter/material.dart';

import '../theme/app_sizes.dart';
import '../theme/app_spacing.dart';

/// A centered "nothing here" state: icon, title, optional body, optional
/// action.
///
/// Phase 7 Part 1 replaces two `_EmptyState` widgets that had already drifted
/// apart -- `shopping_list_screen.dart`'s had an icon, a title, a body and a
/// button; `recipe_list_screen.dart`'s had text only. This is built on the
/// fuller shape. It renders inside a scrollable `ListView` rather than a bare
/// `Column`, so it still works as the `data` case of an `AsyncValue.when`
/// wrapped in a `RefreshIndicator` -- pull-to-refresh needs something
/// scrollable underneath it even when there is nothing to show.
///
/// Which icon, which strings and whether there is an action are all the
/// caller's call: this widget does not know what a recipe or a shopping list
/// is. On [action], the design (`docs/DESIGN_SYSTEM.md` § Components) asks
/// for **at most one, and tonal** (`FilledButton.tonal`): an empty state is
/// an invitation, and a full-emphasis button on a screen with nothing on it
/// shouts. Enforcing that is the callers' business, in the slices that own
/// those screens, not this widget's.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    this.body,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? bodyText = body;
    final Widget? actionWidget = action;
    return ListView(
      children: <Widget>[
        const SizedBox(height: AppSpacing.xxl),
        Center(
          child: Icon(
            icon,
            size: AppSizes.emptyStateIcon,
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (bodyText != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                bodyText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
        ],
        if (actionWidget != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          Center(child: actionWidget),
        ],
      ],
    );
  }
}
