import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/meal_plan/widgets/meal_slot_picker_sheet.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_slot.dart';

Future<void> _pumpOpener(
  WidgetTester tester,
  ValueSetter<MealSlotPick?> onPicked,
) async {
  // The sheet's 14 rows do not all fit the default 800x600 test surface --
  // without this, rows below the fold are not built at all (`meal_plan_screen
  // _test.dart`'s own reason for the same call).
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: appSupportedLocales,
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async => onPicked(await showMealSlotPicker(context)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('offers exactly 14 days and defaults to dinner',
      (WidgetTester tester) async {
    await _pumpOpener(tester, (_) {});

    expect(find.byType(ListTile), findsNWidgets(14));
    final ChoiceChip dinnerChip =
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Dinner'));
    expect(dinnerChip.selected, isTrue);
  });

  testWidgets('the first day row carries the today label',
      (WidgetTester tester) async {
    await _pumpOpener(tester, (_) {});

    expect(find.widgetWithText(Chip, 'today'), findsOneWidget);
  });

  testWidgets('tapping a day returns a MealSlotPick carrying that date and '
      "the sheet's default slot", (WidgetTester tester) async {
    MealSlotPick? picked;
    await _pumpOpener(tester, (MealSlotPick? p) => picked = p);

    final DateTime now = DateTime.now();
    final DateTime expected = DateTime(now.year, now.month, now.day + 3);

    await tester.tap(find.byType(ListTile).at(3));
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.date, expected);
    expect(picked!.slot, MealSlot.dinner);
  });

  testWidgets('selecting a slot chip changes the tapped slot',
      (WidgetTester tester) async {
    MealSlotPick? picked;
    await _pumpOpener(tester, (MealSlotPick? p) => picked = p);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Breakfast'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    final DateTime now = DateTime.now();
    expect(picked, isNotNull);
    expect(picked!.date, DateTime(now.year, now.month, now.day));
    expect(picked!.slot, MealSlot.breakfast);
  });
}
