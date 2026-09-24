import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_section_heading.dart';

void main() {
  testWidgets('shows its text in titleMedium', (WidgetTester tester) async {
    final ThemeData theme = AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: AppSectionHeading(text: 'Ingredients')),
      ),
    );

    expect(find.text('Ingredients'), findsOneWidget);
    final Text text = tester.widget<Text>(find.text('Ingredients'));
    expect(text.style?.fontSize, theme.textTheme.titleMedium?.fontSize);
    expect(text.style?.fontWeight, theme.textTheme.titleMedium?.fontWeight);
  });
}
