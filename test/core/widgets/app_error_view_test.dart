import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_error_view.dart';

void main() {
  testWidgets('shows the message it is given, centered', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: AppErrorView(message: 'Something went wrong'),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    final Text text = tester.widget<Text>(find.text('Something went wrong'));
    expect(text.textAlign, TextAlign.center);
    expect(find.byType(Center), findsWidgets);
  });
}
