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
class AppSectionHeading extends StatelessWidget {
  const AppSectionHeading({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
