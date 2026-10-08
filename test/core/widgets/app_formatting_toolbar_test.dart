import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_sizes.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_formatting_toolbar.dart';
import 'package:kitchen_table/core/widgets/rich_text_editing_controller.dart';

Future<void> _pump(
  WidgetTester tester,
  RichTextEditingController controller, {
  VoidCallback? onHideKeyboard,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Column(
          children: <Widget>[
            TextField(controller: controller, autofocus: true),
            const Spacer(),
            AppFormattingToolbar(
              controller: controller,
              onHideKeyboard: onHideKeyboard ?? () {},
              boldTooltip: 'Bold',
              italicTooltip: 'Italic',
              bulletListTooltip: 'Bulleted list',
              numberedListTooltip: 'Numbered list',
              hideKeyboardTooltip: 'Hide keyboard',
            ),
          ],
        ),
      ),
    ),
  );
}

IconButton _button(WidgetTester tester, String tooltip) => tester.widget(
  find.ancestor(of: find.byTooltip(tooltip), matching: find.byType(IconButton)),
);

void main() {
  testWidgets('five buttons with their tooltips, 48 tall', (
    WidgetTester tester,
  ) async {
    final RichTextEditingController controller = RichTextEditingController();
    addTearDown(controller.dispose);
    await _pump(tester, controller);

    for (final String tooltip in <String>[
      'Bold',
      'Italic',
      'Bulleted list',
      'Numbered list',
      'Hide keyboard',
    ]) {
      expect(find.byTooltip(tooltip), findsOneWidget);
    }
    expect(
      tester.getSize(find.byType(AppFormattingToolbar)).height,
      AppSizes.target,
    );
    expect(find.byKey(const Key('formattingToolbarPill')), findsNothing);
  });

  testWidgets('the active toggle sits on a secondaryContainer pill, and '
      'italic is disabled inside bold', (WidgetTester tester) async {
    final ColorScheme colors = AppTheme.light().colorScheme;
    final RichTextEditingController controller = RichTextEditingController();
    addTearDown(controller.dispose);
    controller.value = const TextEditingValue(
      text: '**ab**',
      selection: TextSelection.collapsed(offset: 3),
    );
    await _pump(tester, controller);

    final Finder pill = find.byKey(const Key('formattingToolbarPill'));
    expect(pill, findsOneWidget);
    final ShapeDecoration decoration =
        tester.widget<DecoratedBox>(pill).decoration as ShapeDecoration;
    expect(decoration.color, colors.secondaryContainer);
    expect(decoration.shape, const StadiumBorder());
    expect(tester.getSize(pill), const Size(40, 32));
    expect(
      find.descendant(
        of: find.ancestor(of: pill, matching: find.byType(Stack)),
        matching: find.byIcon(Icons.format_bold),
      ),
      findsOneWidget,
    );
    expect(_button(tester, 'Bold').color, colors.onSecondaryContainer);
    expect(_button(tester, 'Italic').onPressed, isNull);
  });

  testWidgets('tapping bold wraps the selection and keeps it selected', (
    WidgetTester tester,
  ) async {
    final RichTextEditingController controller = RichTextEditingController();
    addTearDown(controller.dispose);
    controller.value = const TextEditingValue(
      text: 'Umesi testo',
      selection: TextSelection(baseOffset: 6, extentOffset: 11),
    );
    await _pump(tester, controller);

    await tester.tap(find.byTooltip('Bold'));
    await tester.pump();

    expect(controller.text, 'Umesi **testo**');
    expect(
      controller.selection,
      const TextSelection(baseOffset: 8, extentOffset: 13),
    );
    expect(find.byKey(const Key('formattingToolbarPill')), findsOneWidget);
  });

  testWidgets('a list toggle lights up and back off', (
    WidgetTester tester,
  ) async {
    final RichTextEditingController controller = RichTextEditingController();
    addTearDown(controller.dispose);
    controller.value = const TextEditingValue(
      text: 'so',
      selection: TextSelection.collapsed(offset: 2),
    );
    await _pump(tester, controller);

    await tester.tap(find.byTooltip('Numbered list'));
    await tester.pump();
    expect(controller.text, '1. so');
    expect(find.byKey(const Key('formattingToolbarPill')), findsOneWidget);

    await tester.tap(find.byTooltip('Numbered list'));
    await tester.pump();
    expect(controller.text, 'so');
    expect(find.byKey(const Key('formattingToolbarPill')), findsNothing);
  });

  testWidgets('hide-keyboard calls back', (WidgetTester tester) async {
    final RichTextEditingController controller = RichTextEditingController();
    addTearDown(controller.dispose);
    int hidden = 0;
    await _pump(tester, controller, onHideKeyboard: () => hidden++);

    await tester.tap(find.byTooltip('Hide keyboard'));
    expect(hidden, 1);
  });
}
