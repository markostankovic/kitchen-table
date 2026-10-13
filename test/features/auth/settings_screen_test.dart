// phase9-household-list -- Settings' household row: with one household it
// is exactly as before and opens that household; with more, the header and
// subtitle say so and it opens the Households list.
//
// currentHouseholdSummaryProvider is overridden directly: Settings reads
// household facts only through it (D52).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/core/household/current_household.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/features/auth/application/auth_providers.dart';
import 'package:kitchen_table/features/auth/domain/app_user.dart';
import 'package:kitchen_table/features/auth/domain/profile.dart';
import 'package:kitchen_table/features/auth/presentation/settings_screen.dart';

final AppLocalizations sr = AppLocalizationsSr();

const String _openedPrefix = 'OPENED ';

Future<void> _pump(WidgetTester tester, {required int others}) async {
  final AppDatabase db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final GoRouter router = GoRouter(
    initialLocation: '/settings',
    routes: <RouteBase>[
      GoRoute(
        path: '/settings',
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/households',
        builder: (_, _) => const Scaffold(body: Text('${_openedPrefix}list')),
      ),
      GoRoute(
        path: '/settings/household/:householdId',
        builder: (_, GoRouterState state) => Scaffold(
          body: Text('$_openedPrefix${state.pathParameters['householdId']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authStateProvider.overrideWith(
          (Ref ref) => Stream<AppUser?>.value(
            const AppUser(id: 'u1', email: 'a@example.com'),
          ),
        ),
        ownProfileProvider.overrideWith(
          (Ref ref) async => const Profile(id: 'u1', displayName: 'Marko'),
        ),
        currentHouseholdSummaryProvider.overrideWith(
          (Ref ref) async => (
            id: 'h1',
            name: 'Kod Mire',
            memberCount: 2,
            otherHouseholdCount: others,
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        locale: const Locale('sr'),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapRow(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Kod Mire'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Kod Mire'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('one household: Domaćinstvo, 2 člana, opens the household', (
    WidgetTester tester,
  ) async {
    await _pump(tester, others: 0);

    expect(find.text('Domaćinstvo'), findsOneWidget);
    expect(find.text('Domaćinstva'), findsNothing);
    expect(find.text('2 člana'), findsOneWidget);

    await _tapRow(tester);
    expect(find.text('${_openedPrefix}h1'), findsOneWidget);
  });

  testWidgets(
    'two households: Domaćinstva, 2 člana · još 1 domaćinstvo, opens the list',
    (WidgetTester tester) async {
      await _pump(tester, others: 1);

      expect(find.text('Domaćinstva'), findsOneWidget);
      expect(find.text('Domaćinstvo'), findsNothing);
      expect(find.text('2 člana · još 1 domaćinstvo'), findsOneWidget);

      await _tapRow(tester);
      expect(find.text('${_openedPrefix}list'), findsOneWidget);
    },
  );
}
