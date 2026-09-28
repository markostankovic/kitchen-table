import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// The bar under a form that holds its save action.
///
/// Phase 7 part 7 lifts this from the import review's `_buildActionBar`
/// (D123) and puts every bottom save button on it: the recipe editor,
/// translation review, and the three import entry screens, which each had a
/// bare padded `SafeArea` of their own.
///
/// On `surface` with a 1dp `outlineVariant` top hairline, not on
/// `surfaceContainer`: that is the nav bar's colour, and the two bars would
/// merge into one block. [error] is an already-localized sentence, shown
/// above the buttons in `bodySmall` `error`.
///
/// [child] is either one `FilledButton`, which the stretch lays out full
/// width, or a `Row` of `Expanded` buttons. Neither the button nor its busy
/// spinner is baked in -- each call site owns those.
class AppActionBar extends StatelessWidget {
  const AppActionBar({required this.child, this.error, super.key});

  final String? error;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? error = this.error;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (error != null) ...<Widget>[
                Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}
