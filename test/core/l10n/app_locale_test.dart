// D91: Serbian is always Latin script. `appLocaleProvider` must never
// collapse back to a bare `Locale('sr')`, and the locale it returns must
// resolve Flutter's own Material chrome to the Latin bundle, not the
// Cyrillic one `Locale('sr')` alone would pick.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/features/auth/application/auth_providers.dart';
import 'package:kitchen_table/features/auth/domain/profile.dart';

void main() {
  group('appLocaleProvider', () {
    test('a Serbian profile resolves to Latin-scripted Serbian', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          ownProfileProvider.overrideWith(
            (Ref ref) async => const Profile(
              id: 'u1',
              displayName: 'Marko',
              locale: AppLocale.sr,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      // ownProfileProvider is async; let it settle before reading appLocale.
      await container.read(ownProfileProvider.future);
      final Locale locale = container.read(appLocaleProvider);

      expect(locale.languageCode, 'sr');
      expect(locale.scriptCode, 'Latn');
      expect(locale, srLatn);
    });

    test('falls back to Latin-scripted Serbian with no profile', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          ownProfileProvider.overrideWith((Ref ref) async => null),
        ],
      );
      addTearDown(container.dispose);

      await container.read(ownProfileProvider.future);
      expect(container.read(appLocaleProvider), srLatn);
    });

    test('an English profile resolves to a bare Locale(en)', () async {
      final ProviderContainer container = ProviderContainer(
        overrides: [
          ownProfileProvider.overrideWith(
            (Ref ref) async => const Profile(
              id: 'u1',
              displayName: 'Marko',
              locale: AppLocale.en,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(ownProfileProvider.future);
      expect(container.read(appLocaleProvider), const Locale('en'));
    });
  });

  group('appSupportedLocales', () {
    test('resolves srLatn to itself, not the scriptless Locale(sr)', () {
      // basicLocaleListResolution -- what MaterialApp uses -- prefers an
      // exact match over a languageCode-only one. If appSupportedLocales
      // dropped the scripted entry, a device or test requesting sr_Latn
      // would resolve to whatever bare `sr` entry came first instead.
      final Locale resolved = basicLocaleListResolution(
        <Locale>[srLatn],
        appSupportedLocales,
      );
      expect(resolved, srLatn);
    });
  });

  testWidgets(
      'Serbian Material chrome renders Latin script, not Cyrillic',
      (WidgetTester tester) async {
    // The regression this whole part exists to fix: Locale('sr') alone
    // resolves to Flutter's Cyrillic MaterialLocalizationSr bundle.
    await tester.pumpWidget(
      MaterialApp(
        locale: srLatn,
        supportedLocales: appSupportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        home: Builder(
          builder: (BuildContext context) {
            final MaterialLocalizations material =
                MaterialLocalizations.of(context);
            return Text(material.pasteButtonLabel);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nalepi'), findsOneWidget);
    expect(find.text('Налепи'), findsNothing);
  });
}
