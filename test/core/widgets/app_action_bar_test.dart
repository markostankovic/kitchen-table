import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_spacing.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_action_bar.dart';

Future<void> _pump(WidgetTester tester, {String? error}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        bottomNavigationBar: AppActionBar(
          error: error,
          child: FilledButton(onPressed: () {}, child: const Text('Save')),
        ),
      ),
    ),
  );
}

BoxDecoration _decoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(AppActionBar),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  final ColorScheme colors = AppTheme.light().colorScheme;
  final TextTheme text = AppTheme.light().textTheme;

  testWidgets('sits on surface with a top hairline in outlineVariant', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    final BoxDecoration decoration = _decoration(tester);
    expect(decoration.color, colors.surface);
    final Border border = decoration.border! as Border;
    expect(border.top.color, colors.outlineVariant);
    expect(border.top.width, 1);
    expect(border.bottom, BorderSide.none);
  });

  testWidgets('lays its child out full width, inside the lg gutters', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    final double bar = tester.getSize(find.byType(AppActionBar)).width;
    final double button = tester.getSize(find.byType(FilledButton)).width;
    expect(button, bar - 2 * AppSpacing.lg);
  });

  testWidgets('shows no error line without an error', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    expect(
      find.descendant(
        of: find.byType(AppActionBar),
        matching: find.byType(Text),
      ),
      findsOneWidget, // the button's own label
    );
  });

  testWidgets('shows the error above the child in bodySmall error', (
    WidgetTester tester,
  ) async {
    await _pump(tester, error: 'Could not save.');

    final Text line = tester.widget<Text>(find.text('Could not save.'));
    expect(line.style?.color, colors.error);
    expect(line.style?.fontSize, text.bodySmall?.fontSize);
    expect(
      tester.getTopLeft(find.text('Could not save.')).dy,
      lessThan(tester.getTopLeft(find.byType(FilledButton)).dy),
    );
  });
}
