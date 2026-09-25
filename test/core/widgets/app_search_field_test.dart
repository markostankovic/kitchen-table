import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/widgets/app_search_field.dart';

Future<TextEditingController> _pump(
  WidgetTester tester, {
  void Function(String)? onChanged,
}) async {
  final TextEditingController controller = TextEditingController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: AppSearchField(
          controller: controller,
          hintText: 'Pretraži recepte',
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
  return controller;
}

void main() {
  testWidgets('shows the hint and a magnifier', (WidgetTester tester) async {
    await _pump(tester);

    expect(find.text('Pretraži recepte'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  // Phase 7 part 2's device walk: a `TextField` with no `style` falls
  // through to `bodyLarge`, which is Literata. A search box is furniture,
  // not something a person reads.
  testWidgets('the typed text is sans, not the serif', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = AppTheme.light();
    await _pump(tester);

    final TextStyle? style = tester.widget<TextField>(
      find.byType(TextField),
    ).style;
    expect(style?.fontSize, theme.textTheme.bodyMedium?.fontSize);
    expect(style?.fontFamily, isNot('Literata'));
  });

  testWidgets('the hint is sans too', (WidgetTester tester) async {
    final ThemeData theme = AppTheme.light();
    await _pump(tester);

    expect(
      theme.inputDecorationTheme.hintStyle?.fontSize,
      theme.textTheme.bodyMedium?.fontSize,
    );
    expect(theme.inputDecorationTheme.hintStyle?.fontFamily, isNot('Literata'));
  });

  testWidgets('the clear button appears with the first letter, not after '
      'the caller\'s debounce', (WidgetTester tester) async {
    final TextEditingController controller = await _pump(tester);

    expect(find.byIcon(Icons.clear), findsNothing);

    await tester.enterText(find.byType(TextField), 'p');
    await tester.pump();

    expect(find.byIcon(Icons.clear), findsOneWidget);
    expect(controller.text, 'p');
  });

  testWidgets('tapping clear empties the field and reports it', (
    WidgetTester tester,
  ) async {
    final List<String> reported = <String>[];
    final TextEditingController controller = await _pump(
      tester,
      onChanged: reported.add,
    );

    await tester.enterText(find.byType(TextField), 'pita');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(reported.last, isEmpty);
    expect(find.byIcon(Icons.clear), findsNothing);
  });
}
