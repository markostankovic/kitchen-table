// Phase 7 part 8 -- the sign-in screen's Garden layout.
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

Future<ThemeData> _pump(WidgetTester tester) async {
  final ThemeData theme = AppTheme.light();
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
          .getSize(find.widgetWithText(FilledButton, sr.signInWithGoogle))
          .height,
      AppSizes.signInButton,
    );
  });

  testWidgets('the wordmark is displaySmall in primary', (
    WidgetTester tester,
  ) async {
    final ThemeData theme = await _pump(tester);

    final TextStyle? style = tester
        .widget<Text>(find.text('Kitchen Table'))
        .style;
    expect(style?.color, theme.colorScheme.primary);
    expect(style?.fontSize, theme.textTheme.displaySmall?.fontSize);
  });

  testWidgets('no dev-login button without its build-time defines', (
    WidgetTester tester,
  ) async {
    await _pump(tester);

    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.textContaining('Dev login'), findsNothing);
  });
}
