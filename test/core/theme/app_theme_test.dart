import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/theme/kitchen_colors.dart';
import 'package:kitchen_table/core/theme/kitchen_type.dart';

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

    test('every role is sans', () {
      final TextTheme light = AppTheme.light().textTheme;
      final TextTheme dark = AppTheme.dark().textTheme;

      expect(light.titleMedium?.fontSize, 18);
      expect(light.titleMedium?.fontWeight, FontWeight.w600);
      expect(light.bodyLarge?.fontSize, 18);
      expect(light.bodyLarge?.height, 28 / 18);
      expect(dark.bodyLarge?.fontSize, 18);

      // D134: no serif anywhere, the wordmark included. Every role leaves
      // `fontFamily` null, which ThemeData fills in from the platform's
      // typography (Roboto under the test VM) -- so what is assertable on the
      // built theme is that every role lands on that one face.
      final String? sans = light.bodyMedium?.fontFamily;
      expect(sans, isNot('Literata'));
      for (final TextTheme theme in <TextTheme>[light, dark]) {
        for (final TextStyle? role in <TextStyle?>[
          theme.displaySmall,
          theme.headlineSmall,
          theme.titleLarge,
          theme.titleMedium,
          theme.titleSmall,
          theme.bodyLarge,
          theme.bodyMedium,
          theme.bodySmall,
          theme.labelLarge,
          theme.labelMedium,
        ]) {
          expect(role?.fontFamily, sans);
        }
      }

      expect(light.displaySmall?.fontSize, 32);
      expect(light.displaySmall?.height, 40 / 32);
      expect(light.displaySmall?.fontWeight, FontWeight.w700);
      expect(light.displaySmall?.letterSpacing, 0.5);
      expect(light.headlineSmall?.fontSize, 28);
      expect(light.headlineSmall?.height, 34 / 28);
      expect(light.headlineSmall?.fontWeight, FontWeight.w700);
      expect(light.headlineSmall?.letterSpacing, 0.3);
    });

    test('KitchenType is present: sans w700 recipe names in onSurface', () {
      for (final ThemeData theme in <ThemeData>[
        AppTheme.light(),
        AppTheme.dark(),
      ]) {
        final KitchenType? type = theme.extension<KitchenType>();
        expect(type, isNotNull, reason: 'the recipe titles must ride along');

        final KitchenType t = type!;
        expect(t.recipeTitle.fontFamily, isNull);
        expect(t.recipeTitle.fontSize, 17);
        expect(t.recipeTitle.height, 24 / 17);
        expect(t.recipeTitle.fontWeight, FontWeight.w700);
        expect(t.recipeTitle.letterSpacing, 0.1);
        expect(t.recipeTitle.color, theme.colorScheme.onSurface);

        expect(t.recipeTitleLarge.fontFamily, isNull);
        expect(t.recipeTitleLarge.fontSize, 28);
        expect(t.recipeTitleLarge.height, 34 / 28);
        expect(t.recipeTitleLarge.fontWeight, FontWeight.w700);
        expect(t.recipeTitleLarge.letterSpacing, 0.3);
        expect(t.recipeTitleLarge.color, theme.colorScheme.onSurface);

        expect(t.monogram.fontFamily, isNull);
        expect(t.monogram.fontSize, 30);
        expect(t.monogram.height, 36 / 30);
        expect(t.monogram.fontWeight, FontWeight.w700);
        expect(t.monogram.letterSpacing, 0);
        expect(t.monogram.color, theme.colorScheme.onSurface);
      }
    });

    test('cards have no hairline and a per-brightness fill', () {
      for (final (ThemeData theme, Color fill) in <(ThemeData, Color)>[
        (AppTheme.light(), const Color(0xFFF5EBDF)),
        (AppTheme.dark(), const Color(0xFF292923)),
      ]) {
        final ShapeBorder? shape = theme.cardTheme.shape;
        expect(shape, isA<RoundedRectangleBorder>());
        expect((shape! as RoundedRectangleBorder).side, BorderSide.none);
        expect(theme.cardTheme.color, fill);
        expect(theme.cardTheme.elevation, 0);
        expect(theme.extension<KitchenColors>()!.card, fill);
      }
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
        expect(c.dragHandle, scheme.outline);
        expect(c.dropTarget, scheme.primaryContainer);
        expect(
          c.card,
          scheme.brightness == Brightness.light
              ? scheme.surfaceContainer
              : scheme.surfaceContainerHigh,
        );

        // Two load-bearing rules, asserted rather than only commented:
        // neither the offline banner nor an unmatched line is an error.
        expect(c.offline, isNot(scheme.errorContainer));
        expect(c.unmatched, isNot(scheme.error));
      }
    });

    // The theme once set `primary` on every FilledButton, which painted the
    // tonal variant green as well (Phase 7 part 8's device walk).
    for (final (String name, ThemeData theme) in <(String, ThemeData)>[
      ('light', AppTheme.light()),
      ('dark', AppTheme.dark()),
    ]) {
      testWidgets('$name: filled is primary, tonal is secondaryContainer', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  FilledButton(onPressed: () {}, child: const Text('filled')),
                  FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('tonal'),
                  ),
                ],
              ),
            ),
          ),
        );

        Color? fill(String label) => tester
            .widget<Material>(
              find
                  .descendant(
                    of: find.ancestor(
                      of: find.text(label),
                      matching: find.byWidgetPredicate(
                        (Widget w) => w is FilledButton,
                      ),
                    ),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .color;

        expect(fill('filled'), theme.colorScheme.primary);
        expect(fill('tonal'), theme.colorScheme.secondaryContainer);
      });
    }
  });
}
