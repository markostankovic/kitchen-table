import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/features/import/presentation/import_photo_screen.dart';

void main() {
  testWidgets('Serbian at 360x760 lays out without overflow',
      (WidgetTester tester) async {
    // flutter_test's square-glyph font is wider than the device's, so this
    // guards the Camera / Gallery Wrap against overflow, not its wrapping or
    // whether Read clears the fold -- those are the device walk's job.
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: srLatn,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: appSupportedLocales,
          home: const ImportPhotoScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final AppLocalizationsSr sr = AppLocalizationsSr();
    expect(find.text(sr.takePhotoButton), findsOneWidget);
    expect(find.text(sr.choosePhotoButton), findsOneWidget);
    await tester.scrollUntilVisible(find.text(sr.readRecipeButton), 200);
    expect(tester.takeException(), isNull);
    // Nothing picked yet, so the only filled button is disabled.
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text(sr.readRecipeButton),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });
}
