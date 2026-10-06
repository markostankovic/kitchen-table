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
  testWidgets('the amount sits right of the name, unit beside the number', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const IngredientLineRow(quantity: '½', unit: 'kg', name: 'mlevenog mesa'),
    );

    // `½ kg` is one amount: number and unit in one run, which never wraps.
    final Finder amount = find.byKey(const Key('ingredientAmount'));
    expect(
      tester
          .widget<RichText>(
            find.descendant(of: amount, matching: find.byType(RichText)),
          )
          .text
          .toPlainText(),
      '½ kg',
    );
    expect(
      tester.getTopLeft(amount).dx,
      greaterThan(tester.getTopRight(find.text('mlevenog mesa')).dx),
    );
  });

  testWidgets('the number is primary, w600; the unit is onSurfaceVariant', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = AppTheme.light();
    await _pump(
      tester,
      const IngredientLineRow(quantity: '200', unit: 'g', name: 'brašna'),
    );

    final TextSpan root =
        tester
                .widget<RichText>(
                  find.descendant(
                    of: find.byKey(const Key('ingredientAmount')),
                    matching: find.byType(RichText),
                  ),
                )
                .text
            as TextSpan;
    final List<TextSpan> spans = <TextSpan>[];
    root.visitChildren((InlineSpan s) {
      if (s is TextSpan && s.text != null) spans.add(s);
      return true;
    });
    final TextSpan number = spans.firstWhere((TextSpan s) => s.text == '200');
    final TextSpan unit = spans.firstWhere((TextSpan s) => s.text == 'g');
    expect(number.style?.color, theme.colorScheme.primary);
    expect(number.style?.fontWeight, FontWeight.w600);
    expect(unit.style?.color, theme.colorScheme.onSurfaceVariant);
  });

  testWidgets('amounts line up on the right edge down a list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(
            children: <Widget>[
              IngredientLineRow(
                quantity: '200',
                unit: 'g',
                name: 'brašna',
                key: Key('a'),
              ),
              IngredientLineRow(
                quantity: '1½',
                unit: null,
                name: 'jaje',
                key: Key('b'),
              ),
            ],
          ),
        ),
      ),
    );

    Finder amountIn(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byKey(const Key('ingredientAmount')),
    );
    expect(
      tester.getTopRight(amountIn('a')).dx,
      tester.getTopRight(amountIn('b')).dx,
    );
  });

  testWidgets('a long Serbian name wraps on the left, clear of the amount, at '
      '360dp', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      const IngredientLineRow(
        quantity: '1,5',
        unit: 'kg',
        name: 'mešano mleveno meso, junetina i svinjetina',
      ),
    );

    final Finder name = find.text('mešano mleveno meso, junetina i svinjetina');
    final Finder amount = find.byKey(const Key('ingredientAmount'));
    expect(tester.takeException(), isNull);
    // Wrapped: taller than one 28dp line.
    expect(tester.getSize(name).height, greaterThan(28));
    // And never touching the amount: the 24dp gap holds.
    expect(
      tester.getTopLeft(amount).dx - tester.getTopRight(name).dx,
      greaterThanOrEqualTo(24),
    );
    // The amount itself stays on one line.
    expect(tester.getSize(amount).height, 28);
  });

  testWidgets('no amount means no gap and no amount widget', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const IngredientLineRow(quantity: null, unit: null, name: 'so'),
    );

    expect(find.byKey(const Key('ingredientAmount')), findsNothing);
    expect(
      tester.getSize(find.byType(Expanded)).width,
      tester.getSize(find.byType(IngredientLineRow)).width,
    );
  });

  testWidgets('the optional label rides inline after the name, muted', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const IngredientLineRow(
        quantity: '1',
        unit: null,
        name: 'limun',
        optionalLabel: 'opciono',
      ),
    );

    expect(find.text('limun · opciono'), findsOneWidget);
  });

  testWidgets('the row is at least 48dp tall', (WidgetTester tester) async {
    await _pump(
      tester,
      const IngredientLineRow(quantity: null, unit: null, name: 'so'),
    );

    expect(
      tester.getSize(find.byType(IngredientLineRow)).height,
      greaterThanOrEqualTo(48),
    );
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

    // Inline after the name, not a trailing column at the row's edge.
    expect(
      tester.getCenter(marker).dx,
      lessThan(tester.getSize(find.byType(IngredientLineRow)).width / 2),
    );

    // Not `error`, and not any red: `unmatched` is an alias of `outline`.
    expect(tester.getSize(marker), const Size.square(16));
    expect(theme.colorScheme.error, isNot(theme.colorScheme.outline));
  });

  testWidgets('a flagged line gets the review marker, as a foreground, on a '
      'tint', (WidgetTester tester) async {
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

    final Container row = tester.widget<Container>(
      find.byType(Container).first,
    );
    expect(
      (row.decoration! as BoxDecoration).color,
      theme.colorScheme.surfaceContainerLow,
    );
    final Border marker =
        (row.foregroundDecoration! as BoxDecoration).border! as Border;
    expect(marker.left.width, 3);
    expect(marker.left.color, theme.colorScheme.tertiary);
  });

  // The detail screen, the shopping list and the meal plan never flag a row,
  // so none of them may pick up the tint or the marker.
  testWidgets('an unflagged line has no tint and no marker', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const IngredientLineRow(quantity: '1', unit: null, name: 'jaje'),
    );

    final Container row = tester.widget<Container>(
      find.byType(Container).first,
    );
    expect((row.decoration! as BoxDecoration).color, isNull);
    expect(row.foregroundDecoration, isNull);
  });

  // The marker is a foreground and takes no layout; the flagged row pads its
  // left edge instead, so the name clears the 3px marker.
  testWidgets('a flagged name clears the marker', (WidgetTester tester) async {
    await _pump(
      tester,
      const IngredientLineRow(
        quantity: '1',
        unit: null,
        name: 'jaje',
        isFlagged: true,
      ),
    );

    expect(tester.getTopLeft(find.text('jaje')).dx, greaterThanOrEqualTo(12));
  });

  // Import review insets every row, so a flagged name lines up with its
  // unflagged neighbours.
  testWidgets('inset rows line up with flagged ones, both edges', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Column(
            children: <Widget>[
              IngredientLineRow(
                quantity: '200',
                unit: 'g',
                name: 'brašna',
                inset: true,
                key: Key('a'),
              ),
              IngredientLineRow(
                quantity: '1',
                unit: null,
                name: 'jaje',
                isFlagged: true,
                inset: true,
                key: Key('b'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('brašna')).dx,
      tester.getTopLeft(find.text('jaje')).dx,
    );
    expect(tester.getTopLeft(find.text('brašna')).dx, 12);
    Finder amountIn(String key) => find.descendant(
      of: find.byKey(Key(key)),
      matching: find.byKey(const Key('ingredientAmount')),
    );
    expect(tester.getTopRight(amountIn('a')).dx, 800 - 12);
    expect(
      tester.getTopRight(amountIn('a')).dx,
      tester.getTopRight(amountIn('b')).dx,
    );
  });

  // The device walk found the ring stranded alone on a second line when the
  // name filled the first exactly. A word joiner forbids that break.
  testWidgets('the ring is glued to the last word of the name', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const IngredientLineRow(
        quantity: null,
        unit: null,
        name: 'komadić rebaraca',
        isMatched: false,
      ),
    );

    final String plain = tester
        .widget<RichText>(
          find
              .descendant(
                of: find.textContaining('komadić rebaraca'),
                matching: find.byType(RichText),
              )
              .first,
        )
        .text
        .toPlainText();
    expect(plain, 'komadić rebaraca\u2060\uFFFC');
  });

  testWidgets('showDivider: false drops the dashed divider; the default '
      'keeps it, in outlineVariant', (WidgetTester tester) async {
    final ThemeData theme = AppTheme.light();
    final Finder divider = find.byKey(const Key('ingredientDivider'));

    await _pump(
      tester,
      const IngredientLineRow(quantity: '1', unit: null, name: 'jaje'),
    );
    expect(divider, findsOneWidget);
    expect(
      tester.renderObject(divider),
      paints..line(color: theme.colorScheme.outlineVariant),
    );
    // Flush rows run the dashes edge to edge.
    expect(tester.getTopLeft(divider).dx, 0);
    expect(tester.getTopRight(divider).dx, 800);
    expect(tester.getSize(divider).height, 1);

    await _pump(
      tester,
      const IngredientLineRow(
        quantity: '1',
        unit: null,
        name: 'jaje',
        showDivider: false,
      ),
    );
    expect(divider, findsNothing);
  });

  // `Review import@1x.png`: the dashes start and end at the text, while the
  // flagged tint still runs the full width.
  testWidgets('an inset row pads its divider md on both sides', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const IngredientLineRow(
        quantity: '1',
        unit: null,
        name: 'jaje',
        isFlagged: true,
        inset: true,
      ),
    );

    final Finder divider = find.byKey(const Key('ingredientDivider'));
    expect(tester.getTopLeft(divider).dx, 12);
    expect(tester.getTopRight(divider).dx, 800 - 12);
    expect(tester.getSize(find.byType(IngredientLineRow)).width, 800);
  });

  // The divider replaced a 1dp border, and must not change row heights.
  testWidgets('a one-line row is still 48dp, divider included', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      const IngredientLineRow(quantity: '1', unit: null, name: 'jaje'),
    );
    final Finder row = find.byType(IngredientLineRow);
    final Finder divider = find.byKey(const Key('ingredientDivider'));
    expect(tester.getSize(row).height, 48);
    expect(tester.getBottomLeft(divider).dy, tester.getBottomLeft(row).dy);
  });

  group('extraAmounts', () {
    String plainOf(WidgetTester tester, Finder f) => tester
        .widget<RichText>(find.descendant(of: f, matching: find.byType(RichText)))
        .text
        .toPlainText();

    testWidgets('stack under the first amount, right edges aligned, each led '
        'by a muted +', (WidgetTester tester) async {
      final ThemeData theme = AppTheme.light();
      await _pump(
        tester,
        const IngredientLineRow(
          quantity: '480',
          unit: 'ml',
          extraAmounts: <({String? quantity, String? unit})>[
            (quantity: '300', unit: 'g'),
            (quantity: '2', unit: 'kom'),
          ],
          name: 'brašno',
        ),
      );

      final Finder first = find.byKey(const Key('ingredientAmount'));
      final Finder extras = find.byKey(const Key('ingredientExtraAmount'));
      expect(plainOf(tester, first), '480 ml');
      expect(extras, findsNWidgets(2));
      expect(plainOf(tester, extras.at(0)), '+ 300 g');
      expect(plainOf(tester, extras.at(1)), '+ 2 kom');

      expect(
        tester.getTopLeft(extras.at(0)).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(first).dy),
      );
      expect(
        tester.getTopLeft(extras.at(1)).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(extras.at(0)).dy),
      );
      expect(tester.getTopRight(extras.at(0)).dx, tester.getTopRight(first).dx);
      expect(tester.getTopRight(extras.at(1)).dx, tester.getTopRight(first).dx);

      final TextSpan root =
          tester
                  .widget<RichText>(
                    find.descendant(
                      of: extras.at(0),
                      matching: find.byType(RichText),
                    ),
                  )
                  .text
              as TextSpan;
      final List<TextSpan> spans = <TextSpan>[];
      root.visitChildren((InlineSpan s) {
        if (s is TextSpan && s.text != null) spans.add(s);
        return true;
      });
      final TextSpan plus = spans.firstWhere((TextSpan s) => s.text == '+ ');
      final TextSpan number = spans.firstWhere((TextSpan s) => s.text == '300');
      expect(plus.style?.color, theme.colorScheme.onSurfaceVariant);
      expect(number.style?.color, theme.colorScheme.primary);
      expect(number.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('extras alone still render, with no first amount widget', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const IngredientLineRow(
          quantity: null,
          unit: null,
          extraAmounts: <({String? quantity, String? unit})>[
            (quantity: '300', unit: 'g'),
          ],
          name: 'brašno',
        ),
      );

      expect(find.byKey(const Key('ingredientAmount')), findsNothing);
      expect(find.byKey(const Key('ingredientExtraAmount')), findsOneWidget);
    });

    testWidgets('none by default', (WidgetTester tester) async {
      await _pump(
        tester,
        const IngredientLineRow(quantity: '1', unit: 'kg', name: 'brašno'),
      );
      expect(find.byKey(const Key('ingredientExtraAmount')), findsNothing);
    });
  });

  group('nameMarker', () {
    testWidgets('renders inline after the name, glued to it', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        const IngredientLineRow(
          quantity: '1',
          unit: 'kg',
          name: 'so',
          nameMarker: Icon(Icons.push_pin_outlined, key: Key('marker')),
        ),
      );

      expect(find.byKey(const Key('marker')), findsOneWidget);
      // The placeholder follows the name and a word joiner, as the ring does.
      final String plain = tester
          .widget<RichText>(
            find
                .descendant(
                  of: find.textContaining('so'),
                  matching: find.byType(RichText),
                )
                .first,
          )
          .text
          .toPlainText();
      expect(plain, 'so⁠￼');
    });

    testWidgets('nothing renders without it', (WidgetTester tester) async {
      await _pump(
        tester,
        const IngredientLineRow(quantity: '1', unit: 'kg', name: 'so'),
      );

      final String plain = tester
          .widget<RichText>(
            find
                .descendant(
                  of: find.text('so'),
                  matching: find.byType(RichText),
                )
                .first,
          )
          .text
          .toPlainText();
      expect(plain, 'so');
    });
  });

  // The 2026-10-06 walk found the ring alone on a fourth line: the word
  // joiner does not stop Flutter breaking before a placeholder when the last
  // word and the ring together overflow. The test font sets every glyph one
  // em (18dp at bodyLarge), so the widths below are exact.
  group('a marker that would not fit takes the last word with it', () {
    Future<void> pumpAt(WidgetTester tester, double width, Widget row) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: width, child: row),
              ),
            ),
          ),
        );

    String plainOfName(WidgetTester tester, String start) => tester
        .widget<RichText>(
          find
              .descendant(
                of: find.textContaining(start),
                matching: find.byType(RichText),
              )
              .first,
        )
        .text
        .toPlainText();

    testWidgets('the ring', (WidgetTester tester) async {
      // `aaaa bbbb` is 162dp; the ring needs `sm` + 16 = 24 more, and 170
      // has room for the name but not both.
      await pumpAt(
        tester,
        170,
        const IngredientLineRow(
          quantity: null,
          unit: null,
          name: 'aaaa bbbb',
          isMatched: false,
        ),
      );

      final Finder ring = find.byKey(const Key('unmatchedMarker'));
      // On the second line beside `bbbb` (72dp, + 8 gap), not alone at its
      // start.
      expect(tester.getTopLeft(ring).dx, greaterThanOrEqualTo(72));
      expect(plainOfName(tester, 'aaaa'), startsWith('aaaa\nbbbb'));
    });

    testWidgets('the name marker', (WidgetTester tester) async {
      await pumpAt(
        tester,
        170,
        const IngredientLineRow(
          quantity: null,
          unit: null,
          name: 'aaaa bbbb',
          nameMarker: Icon(Icons.push_pin_outlined, key: Key('marker')),
        ),
      );

      final Finder marker = find.byKey(const Key('marker'));
      expect(tester.getTopLeft(marker).dx, greaterThanOrEqualTo(72));
      expect(plainOfName(tester, 'aaaa'), startsWith('aaaa\nbbbb'));
    });

    testWidgets('the optional label is the last word when it is there', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        // `aaaa` at 18dp a glyph, ` · bb` at the label's 12: 132dp, with no
        // room for the ring's 24 too.
        140,
        const IngredientLineRow(
          quantity: null,
          unit: null,
          name: 'aaaa',
          optionalLabel: 'bb',
          isMatched: false,
        ),
      );

      expect(plainOfName(tester, 'aaaa'), startsWith('aaaa ·\nbb'));
    });

    testWidgets('a name with room for its marker is left alone', (
      WidgetTester tester,
    ) async {
      await pumpAt(
        tester,
        400,
        const IngredientLineRow(
          quantity: null,
          unit: null,
          name: 'aaaa bbbb',
          isMatched: false,
        ),
      );

      expect(plainOfName(tester, 'aaaa'), 'aaaa bbbb⁠￼');
    });
  });
}
