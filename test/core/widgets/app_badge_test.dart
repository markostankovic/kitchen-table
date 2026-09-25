import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_badge.dart';

void main() {
  testWidgets('renders its label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: AppBadge(label: 'Nacrt')),
      ),
    );

    expect(find.text('Nacrt'), findsOneWidget);
  });

  testWidgets('is outlined, not filled -- it states, it does not act', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: AppBadge(label: 'Draft')),
      ),
    );

    final BoxDecoration decoration =
        tester
                .widget<Container>(
                  find.ancestor(
                    of: find.text('Draft'),
                    matching: find.byType(Container),
                  ),
                )
                .decoration!
            as BoxDecoration;
    expect(decoration.color, isNull);
    expect(decoration.border, isNotNull);
  });
}
