import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_spacing.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_rich_text.dart';

Future<void> _pump(WidgetTester tester, Widget Function(ThemeData) child) {
  final ThemeData theme = AppTheme.light();
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child(theme)),
      ),
    ),
  );
}

/// The style a run with [text] is drawn in, inside the one `Text.rich` that
/// holds it.
TextStyle? _runStyle(WidgetTester tester, String text) {
  for (final Text widget in tester.widgetList<Text>(find.byType(Text))) {
    final TextSpan? root = widget.textSpan as TextSpan?;
    for (final InlineSpan child in root?.children ?? const <InlineSpan>[]) {
      if (child is TextSpan && child.text == text) {
        return (root!.style ?? const TextStyle()).merge(child.style);
      }
    }
  }
  return null;
}

void main() {
  testWidgets('plain one-line text is found by find.text', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      (ThemeData t) =>
          AppRichText('Zagrej rernu.', style: t.textTheme.bodyLarge!),
    );

    expect(find.text('Zagrej rernu.'), findsOneWidget);
  });

  testWidgets('blank text renders nothing', (WidgetTester tester) async {
    await _pump(
      tester,
      (ThemeData t) => AppRichText('  \n ', style: t.textTheme.bodyLarge!),
    );

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('bold is w600, not w700 (D134); italic is true italic; both '
      'keep the base colour', (WidgetTester tester) async {
    await _pump(
      tester,
      (ThemeData t) => AppRichText(
        'a **bold** and *slanted*',
        style: t.textTheme.bodyMedium!.copyWith(
          color: t.colorScheme.onSurfaceVariant,
        ),
      ),
    );
    final ThemeData theme = AppTheme.light();

    expect(find.text('a bold and slanted'), findsOneWidget);
    final TextStyle bold = _runStyle(tester, 'bold')!;
    expect(bold.fontWeight, FontWeight.w600);
    expect(bold.color, theme.colorScheme.onSurfaceVariant);
    final TextStyle italic = _runStyle(tester, 'slanted')!;
    expect(italic.fontStyle, FontStyle.italic);
    expect(italic.color, theme.colorScheme.onSurfaceVariant);
  });

  testWidgets('markers are onSurfaceVariant on onSurface text', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      (ThemeData t) =>
          AppRichText('- a\n\n1. b', style: t.textTheme.bodyLarge!),
    );
    final ThemeData theme = AppTheme.light();

    final BoxDecoration disc =
        tester
                .widget<Container>(find.byKey(const Key('richTextBullet')))
                .decoration!
            as BoxDecoration;
    expect(disc.color, theme.colorScheme.onSurfaceVariant);
    expect(disc.shape, BoxShape.circle);
    expect(
      tester.widget<Text>(find.text('1.')).style!.color,
      theme.colorScheme.onSurfaceVariant,
    );
  });

  testWidgets('md between blocks, xs between items, wrapped item text hangs '
      'at the 20 column', (WidgetTester tester) async {
    await _pump(
      tester,
      (ThemeData t) => SizedBox(
        width: 300,
        child: AppRichText('One\nTwo\n- a\n- b', style: t.textTheme.bodyLarge!),
      ),
    );

    final Rect root = tester.getRect(find.byType(AppRichText));
    expect(tester.getTopLeft(find.text('One')).dy, root.top);
    expect(
      tester.getTopLeft(find.text('Two')).dy -
          tester.getBottomLeft(find.text('One')).dy,
      AppSpacing.md,
    );
    expect(
      tester.getTopLeft(find.text('a')).dy -
          tester.getBottomLeft(find.text('Two')).dy,
      AppSpacing.md,
    );
    expect(
      tester.getTopLeft(find.text('b')).dy -
          tester.getBottomLeft(find.text('a')).dy,
      AppSpacing.xs,
    );
    expect(tester.getBottomLeft(find.text('b')).dy, root.bottom);
    expect(tester.getTopLeft(find.text('a')).dx - root.left, 20);

    // The disc: inset xs, centred on the 28-high first line of bodyLarge.
    final Rect disc = tester.getRect(
      find.byKey(const Key('richTextBullet')).first,
    );
    expect(disc.left - root.left, AppSpacing.xs);
    expect(disc.center.dy, tester.getTopLeft(find.text('a')).dy + 14);
  });

  testWidgets('a list reaching 10. widens its column, shared by every item', (
    WidgetTester tester,
  ) async {
    final String text = <String>[for (int n = 1; n <= 10; n++) '$n. item $n']
        .join('\n');
    await _pump(
      tester,
      (ThemeData t) => SizedBox(
        width: 300,
        child: AppRichText(text, style: t.textTheme.bodyLarge!),
      ),
    );

    final double left = tester.getTopLeft(find.byType(AppRichText)).dx;
    final double indent = tester.getTopLeft(find.text('item 1')).dx - left;
    expect(indent, greaterThan(20));
    expect(tester.getTopLeft(find.text('item 10')).dx - left, indent);
    // The figures themselves end at least xs short of the item text.
    final double figures = tester
        .renderObject<RenderBox>(find.text('10.'))
        .getMaxIntrinsicWidth(double.infinity);
    expect(indent, greaterThanOrEqualTo(figures + AppSpacing.xs));
  });

  testWidgets('renders inside IntrinsicHeight without throwing', (
    WidgetTester tester,
  ) async {
    await _pump(
      tester,
      (ThemeData t) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(width: 32),
            Expanded(
              child: AppRichText(
                'Work it.\n- a\n- b\n1. c',
                style: t.textTheme.bodyLarge!,
              ),
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Work it.'), findsOneWidget);
  });
}
