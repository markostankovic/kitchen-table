import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_field_label.dart';

void main() {
  testWidgets('shows its text in titleSmall', (WidgetTester tester) async {
    final ThemeData theme = AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: AppFieldLabel(text: 'Title')),
      ),
    );

    final Text text = tester.widget<Text>(find.text('Title'));
    expect(text.style?.fontSize, theme.textTheme.titleSmall?.fontSize);
    expect(text.style?.fontWeight, theme.textTheme.titleSmall?.fontWeight);
    expect(text.style?.fontFamily, theme.textTheme.titleSmall?.fontFamily);
  });
}
