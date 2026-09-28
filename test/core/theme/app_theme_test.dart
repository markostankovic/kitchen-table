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

    test('the type scale is sans, bar the wordmark', () {
      final TextTheme light = AppTheme.light().textTheme;
      final TextTheme dark = AppTheme.dark().textTheme;

      expect(light.titleMedium?.fontSize, 18);
      expect(light.titleMedium?.fontWeight, FontWeight.w600);
      expect(light.bodyLarge?.fontSize, 18);
      expect(light.bodyLarge?.height, 28 / 18);
      expect(dark.bodyLarge?.fontSize, 18);

      // D127: Literata reaches a screen only through `displaySmall` or
      // KitchenType. Every other role leaves `fontFamily` null, which the
      // platform fills in (Roboto under the test VM) -- so what is
      // assertable is that the serif did not leak onto it.
      expect(light.displaySmall?.fontFamily, 'Literata');
      for (final TextStyle? role in <TextStyle?>[
        light.headlineSmall,
        light.titleLarge,
        light.titleMedium,
        light.titleSmall,
        light.bodyLarge,
        light.bodyMedium,
        light.bodySmall,
        light.labelLarge,
        light.labelMedium,
      ]) {
        expect(role?.fontFamily, isNot('Literata'));
      }
    });

    test('KitchenType is present: Literata recipe titles in onSurface', () {
      for (final ThemeData theme in <ThemeData>[
        AppTheme.light(),
        AppTheme.dark(),
      ]) {
        final KitchenType? type = theme.extension<KitchenType>();
        expect(type, isNotNull, reason: 'the recipe titles must ride along');

        final KitchenType t = type!;
        expect(t.recipeTitle.fontFamily, 'Literata');
        expect(t.recipeTitle.fontSize, 18);
        expect(t.recipeTitle.height, 24 / 18);
        expect(t.recipeTitle.fontWeight, FontWeight.w600);
        expect(t.recipeTitle.color, theme.colorScheme.onSurface);

        expect(t.recipeTitleLarge.fontFamily, 'Literata');
        expect(t.recipeTitleLarge.fontSize, 26);
        expect(t.recipeTitleLarge.height, 32 / 26);
        expect(t.recipeTitleLarge.fontWeight, FontWeight.w600);
        expect(t.recipeTitleLarge.color, theme.colorScheme.onSurface);
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
