import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/theme/kitchen_colors.dart';

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

    test('the palette is the Garden export, written out, not generated', () {
      final ColorScheme light = AppTheme.light().colorScheme;
      final ColorScheme dark = AppTheme.dark().colorScheme;

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);

      // Spot values in each brightness (docs/DESIGN_SYSTEM.md § Colour).
      // These are decisions, not a seed's output -- a wrong one here means
      // someone reintroduced `fromSeed` or mistyped a hex.
      expect(light.primary, const Color(0xFF366A35));
      expect(light.secondary, const Color(0xFF775A0E));
      expect(light.tertiary, const Color(0xFFAC3F25));
      expect(light.surface, const Color(0xFFFFF7EC));
      expect(light.outlineVariant, const Color(0xFFD1C8B8));

      expect(dark.primary, const Color(0xFF9ED498));
      expect(dark.secondary, const Color(0xFFE8C174));
      expect(dark.surface, const Color(0xFF16160F));
      expect(dark.outlineVariant, const Color(0xFF494A3F));

      // Paprika. D117 pinned 0xFFE7C17E here because the generated value read
      // too close to secondary at the 3px width import review draws its
      // marker at; D118 supersedes the value, not the constraint.
      expect(dark.tertiary, const Color(0xFFFF9569));
      expect(dark.tertiary, isNot(dark.secondary));
    });

    test('surfaceTint is transparent in both, killing the elevation tint', () {
      expect(AppTheme.light().colorScheme.surfaceTint, Colors.transparent);
      expect(AppTheme.dark().colorScheme.surfaceTint, Colors.transparent);
    });

    test('the type scale is Literata for reading, sans for furniture', () {
      final TextTheme light = AppTheme.light().textTheme;
      final TextTheme dark = AppTheme.dark().textTheme;

      // The two sizes this slice moved, and are easy to regress.
      expect(light.titleMedium?.fontSize, 18);
      expect(light.titleMedium?.fontWeight, FontWeight.w600);
      expect(light.bodyLarge?.fontSize, 17);
      expect(dark.titleMedium?.fontSize, 18);

      // The serif only ever sits on content a person reads.
      expect(light.displaySmall?.fontFamily, 'Literata');
      expect(light.headlineSmall?.fontFamily, 'Literata');
      expect(light.titleLarge?.fontFamily, 'Literata');
      expect(light.titleMedium?.fontFamily, 'Literata');
      expect(light.bodyLarge?.fontFamily, 'Literata');

      // Furniture is the platform sans. `AppTheme` leaves `fontFamily` null
      // on these roles, which is how a role asks for Roboto / San Francisco;
      // by the time it is a `ThemeData` the platform has filled its own name
      // in (Roboto under the test VM), so what is assertable -- and what
      // actually matters -- is that the serif did not leak onto them. A
      // button label in a serif reads as decoration, which is why
      // labelLarge is in this list.
      expect(light.bodyMedium?.fontFamily, isNot('Literata'));
      expect(light.labelLarge?.fontFamily, isNot('Literata'));
      expect(light.titleSmall?.fontFamily, isNot('Literata'));
      expect(light.bodySmall?.fontFamily, isNot('Literata'));
      expect(light.labelMedium?.fontFamily, isNot('Literata'));
    });

    test('the nav indicator is primary, not Material default', () {
      // M3's own default is secondaryContainer; the design wants a primary
      // pill with the icon knocked out in onPrimary.
      for (final ThemeData theme in <ThemeData>[
        AppTheme.light(),
        AppTheme.dark(),
      ]) {
        expect(
          theme.navigationBarTheme.indicatorColor,
          theme.colorScheme.primary,
        );
        expect(theme.navigationBarTheme.indicatorShape, const StadiumBorder());
      }
    });

    test('KitchenColors is present and every member aliases its role', () {
      for (final ThemeData theme in <ThemeData>[
        AppTheme.light(),
        AppTheme.dark(),
      ]) {
        final KitchenColors? colors = theme.extension<KitchenColors>();
        expect(colors, isNotNull, reason: 'the semantic layer must ride along');

        final ColorScheme scheme = theme.colorScheme;
        final KitchenColors c = colors!;

        // This is the test that keeps the semantic layer honest: every member
        // is an alias of a role, so there is no second palette to drift.
        expect(c.today, scheme.primary);
        expect(c.todayContainer, scheme.primaryContainer);
        expect(c.reviewMarker, scheme.tertiary);
        expect(c.favorite, scheme.tertiary);
        expect(c.rating, scheme.tertiary);
        expect(c.statValue, scheme.tertiary);
        expect(c.leftover, scheme.secondary);
        expect(c.unmatched, scheme.outline);
        expect(c.offline, scheme.surfaceContainerHighest);
        expect(c.onOffline, scheme.onSurface);
        expect(c.docLanguage, scheme.surfaceContainerLow);
        expect(c.destructive, scheme.error);

        // Two load-bearing rules, asserted rather than only commented:
        // neither the offline banner nor an unmatched line is an error.
        expect(c.offline, isNot(scheme.errorContainer));
        expect(c.unmatched, isNot(scheme.error));
      }
    });
  });
}
