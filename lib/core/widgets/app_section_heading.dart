import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A heading for a section within a screen.
///
/// Phase 7 Part 1 replaces three near-identical private copies of this
/// (`recipe_edit_screen.dart`, `recipe_detail_screen.dart`,
/// `household_screen.dart`) plus inline `titleMedium` headings written out at
/// their own call sites (`import_review_screen.dart`), each disagreeing
/// slightly on text style and padding. This is the one shape they all use
/// now: `titleMedium`, with `AppSpacing.sm` underneath it so the section's
/// content sits close.
///
/// `titleMedium` is 18/24 w600 platform sans (`docs/DESIGN_SYSTEM.md` § Type,
/// D127; part 2 had briefly made it Literata). The 8dp beneath keeps the
/// section's content close; more would start to look like a gap rather than
/// a heading with its section under it.
///
/// An optional [trailing] string sits at the right on the heading's
/// baseline, in `bodyMedium` `onSurfaceVariant` -- a quiet qualifier of the
/// whole section, such as how many it serves. Without it the heading is the
/// bare `Text` it always was.
class AppSectionHeading extends StatelessWidget {
  const AppSectionHeading({required this.text, this.trailing, super.key});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget title = Text(text, style: theme.textTheme.titleMedium);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: trailing == null
          ? title
          : Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: <Widget>[
                Expanded(child: title),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  trailing!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
    );
  }
}
