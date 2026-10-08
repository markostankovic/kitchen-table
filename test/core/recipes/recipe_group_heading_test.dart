import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/recipes/widgets/recipe_group_heading.dart';
import 'package:kitchen_table/core/theme/app_spacing.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';

/// The heading over a run of steps or ingredient lines (D153, D156): the
/// same `titleSmall` in `primary` everywhere, with the gaps its caller says.
void main() {
  testWidgets('reads titleSmall in primary, with the gaps it is given', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: RecipeGroupHeading(
            text: 'Za testo',
            top: AppSpacing.xl,
            bottom: AppSpacing.xs,
          ),
        ),
      ),
    );

    final Text text = tester.widget<Text>(find.text('Za testo'));
    expect(text.style?.fontSize, theme.textTheme.titleSmall?.fontSize);
    expect(text.style?.fontWeight, theme.textTheme.titleSmall?.fontWeight);
    expect(text.style?.color, theme.colorScheme.primary);

    final Padding padding = tester.widget<Padding>(
      find.ancestor(of: find.text('Za testo'), matching: find.byType(Padding))
          .first,
    );
    expect(
      padding.padding,
      const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.xs),
    );
  });
}
