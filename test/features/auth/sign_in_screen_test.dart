// Phase 7 part 8 -- the sign-in screen's Garden layout; part 15 (D137) --
// the lockup and the outlined Google button.
//
// Built on household_screen_test.dart's harness: a ProviderScope and a
// Serbian MaterialApp (D77 -- nobody is signed in, so this screen renders
// Serbian in practice). Nothing is tapped, so the auth repository is never
// read and needs no override.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/theme/app_sizes.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/features/auth/presentation/sign_in_screen.dart';

final AppLocalizations sr = AppLocalizationsSr();

Future<ThemeData> _pump(WidgetTester tester, {ThemeData? theme}) async {
  theme ??= AppTheme.light();
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        locale: const Locale('sr'),
        home: const SignInScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return theme;
}

void main() {
  testWidgets('the Google button is 52 tall', (WidgetTester tester) async {
    await _pump(tester);

    expect(
      tester
          .getSize(find.widgetWithText(OutlinedButton, sr.signInWithGoogle))
          .height,
      AppSizes.signInButton,
    );
  });

  for (final (String name, ThemeData Function() theme)
      in <(String, ThemeData Function())>[
        ('light', AppTheme.light),
        ('dark', AppTheme.dark),
      ]) {
    testWidgets('the lockup is the $name image, labelled "Kitchen Table"', (
      WidgetTester tester,
    ) async {
      await _pump(tester, theme: theme());

      final Image lockup = tester.widget<Image>(
        find.byWidgetPredicate(
          (Widget w) => w is Image && w.semanticLabel == 'Kitchen Table',
        ),
      );
      expect(
        (lockup.image as AssetImage).assetName,
        endsWith('lockup_$name.png'),
      );
    });
  }

  testWidgets('the Google button is neutral: lowest fill, outline side', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = await _pump(tester);

    final ButtonStyle? style = tester
        .widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, sr.signInWithGoogle),
        )
        .style;
    const Set<WidgetState> idle = <WidgetState>{};
    expect(
      style?.backgroundColor?.resolve(idle),
      theme.colorScheme.surfaceContainerLowest,
    );
    expect(style?.side?.resolve(idle)?.color, theme.colorScheme.outline);
  });

  testWidgets('no dev-login button without its build-time defines', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    // The Google button is the one OutlinedButton now (D137).
    expect(find.textContaining('Dev login'), findsNothing);
    expect(find.byType(OutlinedButton), findsOneWidget);
  });
}
