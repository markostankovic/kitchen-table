import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/ingredients/widgets/ingredient_line_row.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';

Future<void> _pump(WidgetTester tester, IngredientLineRow row) =>
    tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: row),
      ),
    );

void main() {
  testWidgets('the unit rides with the name, the quantity stands alone', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const IngredientLineRow(
        quantity: '½',
        unit: 'kg',
        name: 'mlevenog mesa',
      ),
    );

    // `½ kg mlevenog mesa` is read as one phrase, so unit and name are one
    // run -- a break between them would be a break mid-phrase. The quantity
    // sits in its own column so fractions line up down the list.
    expect(find.text('kg mlevenog mesa'), findsOneWidget);
    expect(find.text('½'), findsOneWidget);
  });

  testWidgets('a line with no quantity or unit still renders its name', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const IngredientLineRow(
        quantity: null,
        unit: null,
        name: 'malo domaćeg sira',
      ),
    );

    expect(find.text('malo domaćeg sira'), findsOneWidget);
  });

  testWidgets('the trailer renders under the name', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const IngredientLineRow(
        quantity: null,
        unit: null,
        name: 'so',
        trailer: 'po ukusu',
      ),
    );

    expect(find.text('po ukusu'), findsOneWidget);
    expect(
      tester.getCenter(find.text('po ukusu')).dy,
      greaterThan(tester.getCenter(find.text('so')).dy),
    );
  });

  testWidgets('a matched line carries no marker', (WidgetTester tester) async {
    await _pump(
      tester,
      const IngredientLineRow(quantity: '200', unit: 'g', name: 'šargarepa'),
    );

    expect(find.byType(Tooltip), findsNothing);
    expect(find.byKey(const Key('unmatchedMarker')), findsNothing);
  });

  // Rule 3, and KitchenColors.unmatched's doc: an unmatched line is a
  // supported outcome, not an error. The marker is quiet and it is never red.
  testWidgets('an unmatched line gets the dashed ring, in outline, and its '
      'tooltip', (WidgetTester tester) async {
    final ThemeData theme = AppTheme.light();
    await _pump(
      tester,
      const IngredientLineRow(
        quantity: null,
        unit: null,
        name: 'malo domaćeg sira',
        isMatched: false,
        unmatchedTooltip: 'Nije povezano sa sastojkom',
      ),
    );

    final Tooltip tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Nije povezano sa sastojkom');
    final Finder marker = find.byKey(const Key('unmatchedMarker'));
    expect(marker, findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsNothing);

    // Not `error`, and not any red: `unmatched` is an alias of `outline`.
    expect(tester.getSize(marker), const Size.square(16));
    expect(theme.colorScheme.error, isNot(theme.colorScheme.outline));
  });

  testWidgets('a flagged line gets the review marker on its leading edge', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = AppTheme.light();
    await _pump(
      tester,
      const IngredientLineRow(
        quantity: '1',
        unit: null,
        name: 'jaje',
        isFlagged: true,
      ),
    );

    final BoxDecoration decoration =
        tester.widget<Container>(find.byType(Container).first).decoration!
            as BoxDecoration;
    final Border border = decoration.border! as Border;
    expect(border.left.width, 3);
    expect(border.left.color, theme.colorScheme.tertiary);
  });
}
