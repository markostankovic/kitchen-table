// AppFormattableField's own job (D166, promoted by D167): pointing the
// toolbar's notifier at its controller while focused, reporting toolbar
// edits as well as typed ones, and dropping an empty pair on blur. The
// editor's and import review's tests cover it in place.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/widgets/app_formattable_field.dart';
import 'package:kitchen_table/core/widgets/rich_text_editing_controller.dart';

void main() {
  late ValueNotifier<RichTextEditingController?> active;
  late List<String> reported;

  setUp(() {
    active = ValueNotifier<RichTextEditingController?>(null);
    reported = <String>[];
  });
  tearDown(() => active.value = null);

  Future<void> pump(WidgetTester tester, {String initial = 'Umesiti'}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                AppFormattableField(
                  initialValue: initial,
                  style: null,
                  activeFormatting: active,
                  onChanged: reported.add,
                ),
                const TextField(key: Key('other')),
              ],
            ),
          ),
        ),
      );

  testWidgets('focus points the notifier at its controller, and blur lets go',
      (WidgetTester tester) async {
    await pump(tester);
    expect(active.value, isNull);

    await tester.showKeyboard(find.byType(AppFormattableField));
    await tester.pump();
    expect(active.value, isNotNull);
    expect(active.value!.text, 'Umesiti');

    await tester.showKeyboard(find.byKey(const Key('other')));
    await tester.pump();
    expect(active.value, isNull);
  });

  testWidgets('typed and programmatic edits are both reported, once each', (
    WidgetTester tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(AppFormattableField), 'Umesiti testo');
    await tester.pump();
    expect(reported, <String>['Umesiti testo']);

    active.value!.text = '**Umesiti** testo';
    await tester.pump();
    expect(reported, <String>['Umesiti testo', '**Umesiti** testo']);
  });

  testWidgets('blur drops a still-empty pair', (WidgetTester tester) async {
    await pump(tester, initial: '');
    await tester.showKeyboard(find.byType(AppFormattableField));
    await tester.pump();
    active.value!.toggleBold();
    await tester.pump();
    expect(reported.last, '****');

    await tester.showKeyboard(find.byKey(const Key('other')));
    await tester.pump();
    expect(reported.last, '');
  });
}
