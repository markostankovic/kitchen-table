import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_monogram_tile.dart';

void main() {
  testWidgets('renders the letter at the given size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: AppMonogramTile(letter: 'Š', size: 72)),
      ),
    );

    expect(find.text('Š'), findsOneWidget);
    expect(
      tester.getSize(find.byType(AppMonogramTile)),
      const Size.square(72),
    );
  });

  testWidgets('sits on secondaryContainer, not on primary', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: AppMonogramTile(letter: 'P', size: 40)),
      ),
    );

    // A column of these in `primary`'s green would make a list of recipes
    // read as a list of actions.
    final BoxDecoration decoration =
        tester.widget<Container>(find.byType(Container)).decoration!
            as BoxDecoration;
    expect(decoration.color, theme.colorScheme.secondaryContainer);
    expect(
      tester.widget<Text>(find.text('P')).style?.color,
      theme.colorScheme.onSecondaryContainer,
    );
  });

  testWidgets('takes the style it is given rather than guessing from size', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = AppTheme.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: AppMonogramTile(
            letter: 'Š',
            size: 72,
            textStyle: theme.textTheme.headlineSmall,
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('Š')).style?.fontSize,
      theme.textTheme.headlineSmall?.fontSize,
    );
  });
}
