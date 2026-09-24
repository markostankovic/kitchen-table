import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    testWidgets('both brightnesses build a working app', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const Scaffold(body: Text('hello')),
        ),
      );

      expect(find.text('hello'), findsOneWidget);
    });

    test('roles this slice decided are set, not left to fromSeed', () {
      final ThemeData light = AppTheme.light();
      final ThemeData dark = AppTheme.dark();

      // A bare ColorScheme.fromSeed leaves ThemeData.textTheme at the
      // Material default (fontSize 14 for bodyMedium); the deliberate scale
      // sets a different value.
      expect(light.textTheme.titleMedium?.fontSize, 17);
      expect(light.textTheme.titleMedium?.fontWeight, FontWeight.w600);
      expect(dark.textTheme.titleMedium?.fontSize, 17);

      expect(light.appBarTheme.elevation, 0);
      expect(dark.appBarTheme.elevation, 0);

      expect(
        light.chipTheme.selectedColor,
        light.colorScheme.secondaryContainer,
      );
      expect(light.inputDecorationTheme.filled, isTrue);
    });

    test('light and dark differ where they should', () {
      final ThemeData light = AppTheme.light();
      final ThemeData dark = AppTheme.dark();

      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(light.colorScheme.surface, isNot(dark.colorScheme.surface));
      expect(light.colorScheme.primary, isNot(dark.colorScheme.primary));

      // The dark tertiary override this slice made -- pinned because
      // fromSeed's own generated value read too close to secondary at the
      // width it is drawn at (docs/DESIGN.md § Colour).
      expect(dark.colorScheme.tertiary, const Color(0xFFE7C17E));
      expect(light.colorScheme.tertiary, isNot(const Color(0xFFE7C17E)));
    });
  });
}
