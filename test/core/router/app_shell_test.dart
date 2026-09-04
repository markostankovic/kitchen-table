// Phase 0's last acceptance criterion: "app runs and navigates between four
// blank tabs" (docs/ROADMAP.md).
//
// Automated here so the criterion keeps holding after Phase 0, rather than
// resting on someone having tapped through it once on a device.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/main.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: KitchenTableApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the Recipes tab', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
  });

  testWidgets('shows all four destinations', (WidgetTester tester) async {
    await pumpApp(tester);
    final NavigationBar bar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations, hasLength(4));
  });

  testWidgets('navigates between all four tabs', (WidgetTester tester) async {
    await pumpApp(tester);

    for (final String label in <String>['Plan', 'List', 'Settings', 'Recipes']) {
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(AppBar, label),
        findsOneWidget,
        reason: 'tapping "$label" should show the $label screen',
      );
    }
  });

  testWidgets('preserves the selected tab index', (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('List'),
    ));
    await tester.pumpAndSettle();

    final NavigationBar bar =
        tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 2);
  });
}
