import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/theme/kitchen_colors.dart';
import 'package:kitchen_table/core/widgets/app_empty_state.dart';

void main() {
  testWidgets('shows the icon and title, no body or action by default', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing here yet',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('shows the body text and action when given', (
    WidgetTester tester,
  ) async {
    bool pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing here yet',
            body: 'Add your first item to get started.',
            action: FilledButton(
              onPressed: () => pressed = true,
              child: const Text('Add item'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Add your first item to get started.'), findsOneWidget);
    await tester.tap(find.text('Add item'));
    expect(pressed, isTrue);
  });

  testWidgets('renders inside a scrollable so RefreshIndicator still works', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {},
            child: const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Nothing here yet',
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets('card: true sets the state on a KitchenColors.card panel', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: AppEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Nothing here yet',
            card: true,
          ),
        ),
      ),
    );

    final Color card = theme.extension<KitchenColors>()!.card;
    expect(
      find.ancestor(
        of: find.text('Nothing here yet'),
        matching: find.byWidgetPredicate(
          (Widget w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == card,
        ),
      ),
      findsOneWidget,
    );
    expect(find.byType(Scrollable), findsWidgets);
  });
}
