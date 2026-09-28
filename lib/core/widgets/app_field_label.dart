import 'package:flutter/material.dart';

/// The label that sits above a form field.
///
/// Phase 7 part 7 promotes this from `recipe_edit_screen.dart`'s private
/// `_FieldLabel` (which used `labelLarge`, a button's role) and from
/// `import_review_screen.dart`'s inline `Text(..., style: titleSmall)`. Every
/// form now labels its fields above them rather than floating the label
/// inside (`docs/DESIGN_SYSTEM.md` § Inputs), in `titleSmall`.
///
/// It owns no padding: the call site writes the `AppSpacing.sm` gap to its
/// field, the same way it writes the `AppSpacing.lg` gap to the next label.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleSmall);
}
