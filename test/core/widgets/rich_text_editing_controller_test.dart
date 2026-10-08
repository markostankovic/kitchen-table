import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/text/rich_text_editing.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/rich_text_editing_controller.dart';

/// A `BuildContext` under the app theme, for `buildTextSpan`.
Future<BuildContext> _context(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (BuildContext context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return captured;
}

/// The leaf spans, each with the root style merged under its own.
List<(String, TextStyle)> _leaves(TextSpan root) => <(String, TextStyle)>[
  if (root.text != null && root.text!.isNotEmpty)
    (root.text!, root.style ?? const TextStyle()),
  for (final InlineSpan child in root.children ?? const <InlineSpan>[])
    if (child is TextSpan)
      (child.text!, (root.style ?? const TextStyle()).merge(child.style)),
];

void main() {
  const TextStyle base = TextStyle(fontSize: 14, height: 20 / 14);

  testWidgets('the span spells out the text exactly', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await _context(tester);
    for (final String text in <String>[
      '',
      'Zagrej rernu.',
      '**a** *b*',
      '- a\n- b',
      '1. a\n12. **b**\n',
      '****',
      '**a *b* c**',
      'a **b',
      '\n\n',
      'Šargarepa **torta**\n\n- so *po* ukusu',
    ]) {
      final RichTextEditingController controller = RichTextEditingController(
        text: text,
      );
      for (final bool withComposing in <bool>[false, true]) {
        expect(
          controller
              .buildTextSpan(
                context: context,
                style: base,
                withComposing: withComposing,
              )
              .toPlainText(),
          text,
          reason: text,
        );
      }
      controller.dispose();
    }
  });

  testWidgets('bold is w600, italic italic, markers onSurfaceVariant, and '
      'no size ever changes', (WidgetTester tester) async {
    final BuildContext context = await _context(tester);
    final ColorScheme colors = AppTheme.light().colorScheme;
    final RichTextEditingController controller = RichTextEditingController(
      text: '- a **b** *c*',
    );
    addTearDown(controller.dispose);

    final List<(String, TextStyle)> leaves = _leaves(
      controller.buildTextSpan(
        context: context,
        style: base,
        withComposing: false,
      ),
    );
    final Map<String, TextStyle> byText = <String, TextStyle>{
      for (final (String text, TextStyle style) in leaves) text: style,
    };

    expect(byText['b']!.fontWeight, FontWeight.w600);
    expect(byText['b']!.fontWeight, isNot(FontWeight.w700));
    expect(byText['c']!.fontStyle, FontStyle.italic);
    for (final String marker in <String>['- ', '**', '*']) {
      expect(byText[marker]!.color, colors.onSurfaceVariant, reason: marker);
    }
    expect(byText['a ']!.color, isNull);
    for (final (_, TextStyle style) in leaves) {
      expect(style.fontSize, 14);
      expect(style.letterSpacing, isNull);
    }
  });

  testWidgets('the composing underline survives inside a bold run', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await _context(tester);
    final RichTextEditingController controller = RichTextEditingController();
    addTearDown(controller.dispose);
    controller.value = const TextEditingValue(
      text: 'a **testo** b',
      selection: TextSelection.collapsed(offset: 8),
      // `tes` of `testo`.
      composing: TextRange(start: 4, end: 7),
    );

    final TextSpan span = controller.buildTextSpan(
      context: context,
      style: base,
      withComposing: true,
    );
    expect(span.toPlainText(), 'a **testo** b');
    final Map<String, TextStyle> byText = <String, TextStyle>{
      for (final (String text, TextStyle style) in _leaves(span)) text: style,
    };
    expect(byText['tes']!.fontWeight, FontWeight.w600);
    expect(byText['tes']!.decoration, TextDecoration.underline);
    expect(byText['to']!.fontWeight, FontWeight.w600);
    expect(byText['to']!.decoration, isNull);
  });

  group('the pending pair', () {
    test('dropPendingPair takes an empty pair back out', () {
      final RichTextEditingController controller = RichTextEditingController();
      addTearDown(controller.dispose);
      controller.value = const TextEditingValue(
        text: 'a  b',
        selection: TextSelection.collapsed(offset: 2),
      );

      controller.toggleBold();
      expect(controller.text, 'a **** b');
      expect(controller.selection, const TextSelection.collapsed(offset: 4));
      expect(controller.formatState.bold, isTrue);
      expect(controller.formatState.italicEnabled, isFalse);

      controller.dropPendingPair();
      expect(controller.text, 'a  b');
      expect(controller.selection, const TextSelection.collapsed(offset: 2));
      expect(controller.formatState.bold, isFalse);
    });

    test('the caret leaving it takes it out', () {
      final RichTextEditingController controller = RichTextEditingController();
      addTearDown(controller.dispose);
      controller.value = const TextEditingValue(
        text: 'ab ',
        selection: TextSelection.collapsed(offset: 3),
      );

      controller.toggleItalic();
      expect(controller.text, 'ab **');
      controller.selection = const TextSelection.collapsed(offset: 0);
      expect(controller.text, 'ab ');
      expect(controller.selection, const TextSelection.collapsed(offset: 0));
    });

    test('typing into it keeps it', () {
      final RichTextEditingController controller = RichTextEditingController();
      addTearDown(controller.dispose);
      controller.toggleBold();
      expect(controller.text, '****');
      controller.value = const TextEditingValue(
        text: '**x**',
        selection: TextSelection.collapsed(offset: 3),
      );
      controller.dropPendingPair();
      expect(controller.text, '**x**');
    });

    test('tapping bold again takes it out', () {
      final RichTextEditingController controller = RichTextEditingController();
      addTearDown(controller.dispose);
      controller
        ..toggleBold()
        ..toggleBold();
      expect(controller.text, '');
    });
  });

  group('RichListFormatter', () {
    final RichListFormatter formatter = RichListFormatter();

    test('Enter in an item continues the list', () {
      final TextEditingValue out = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1. a',
          selection: TextSelection.collapsed(offset: 4),
        ),
        const TextEditingValue(
          text: '1. a\n',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      expect(out.text, '1. a\n2. ');
      expect(out.selection, const TextSelection.collapsed(offset: 8));
      expect(out.composing, TextRange.empty);
    });

    test('a paste passes through', () {
      const TextEditingValue pasted = TextEditingValue(
        text: '- a\nb',
        selection: TextSelection.collapsed(offset: 5),
      );
      expect(
        formatter.formatEditUpdate(
          const TextEditingValue(
            text: '- a',
            selection: TextSelection.collapsed(offset: 3),
          ),
          pasted,
        ),
        pasted,
      );
    });
  });

  test('formatState reads the selection', () {
    final RichTextEditingController controller = RichTextEditingController();
    addTearDown(controller.dispose);
    controller.value = const TextEditingValue(
      text: '- *ab*',
      selection: TextSelection.collapsed(offset: 4),
    );
    expect(
      controller.formatState,
      const RichFormatState(italic: true, bullet: true, boldEnabled: false),
    );
  });
}
