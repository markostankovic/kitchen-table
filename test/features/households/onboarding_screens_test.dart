// Phase 7 part 15 (D137) -- create and join household, top-aligned per the
// design: a headlineSmall title on the left, the buttons pinned to the bottom.
//
// Built on sign_in_screen_test.dart's harness: a ProviderScope and a Serbian
// MaterialApp. Nothing is submitted, so the household repository is never
// read and needs no override.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/theme/app_sizes.dart';
import 'package:kitchen_table/core/theme/app_spacing.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/features/households/presentation/create_household_screen.dart';
import 'package:kitchen_table/features/households/presentation/join_household_screen.dart';

final AppLocalizations sr = AppLocalizationsSr();

const Size _phone = Size(360, 760);

Future<ThemeData> _pump(WidgetTester tester, Widget screen) async {
  tester.view.physicalSize = _phone;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final ThemeData theme = AppTheme.light();
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        locale: const Locale('sr'),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return theme;
}

void main() {
  for (final (String name, Widget screen, String title, String button)
      in <(String, Widget, String, String)>[
        (
          'create',
          const CreateHouseholdScreen(),
          sr.createHouseholdTitle,
          sr.createHouseholdButton,
        ),
        (
          'join',
          const JoinHouseholdScreen(),
          sr.joinHouseholdTitle,
          sr.joinButton,
        ),
      ]) {
    testWidgets('$name: the title is headlineSmall, left-aligned', (
      WidgetTester tester,
    ) async {
      final ThemeData theme = await _pump(tester, screen);

      final Text text = tester.widget<Text>(find.text(title));
      expect(text.style?.fontSize, theme.textTheme.headlineSmall?.fontSize);
      expect(
        text.textAlign == null || text.textAlign == TextAlign.start,
        isTrue,
      );
    });

    testWidgets('$name: the buttons are pinned to the bottom', (
      WidgetTester tester,
    ) async {
      await _pump(tester, screen);

      // The filled button, then `sm`, then the full-width text button, whose
      // bottom sits `xxl` above the screen's -- and nothing scrolls, so that
      // air is on screen rather than below the fold.
      final double filled = tester
          .getBottomLeft(find.widgetWithText(FilledButton, button))
          .dy;
      final double last = tester.getBottomLeft(find.byType(TextButton)).dy;
      expect(_phone.height - last, AppSpacing.xxl);
      expect(last - filled, AppSpacing.sm + AppSizes.button);
      expect(
        tester
            .state<ScrollableState>(
              find
                  .descendant(
                    of: find.byType(CustomScrollView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            )
            .position
            .maxScrollExtent,
        0,
      );
    });

    // The emulator's device walk could not open a full keyboard (Gboard stays
    // in its stylus toolbar), so the keyboard case is checked here: an
    // overflow would fail the pump, and the buttons scroll into reach.
    testWidgets('$name: with the keyboard open, nothing overflows', (
      WidgetTester tester,
    ) async {
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await _pump(tester, screen);

      final Finder filled = find.widgetWithText(FilledButton, button);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.byType(TextButton)).dy,
        lessThanOrEqualTo(_phone.height - 300),
      );
      expect(filled.hitTestable(), findsOneWidget);
    });
  }

  testWidgets('join: the code field has its label', (
    WidgetTester tester,
  ) async {
    await _pump(tester, const JoinHouseholdScreen());

    expect(find.text(sr.inviteCodeFieldLabel), findsOneWidget);
  });
}
