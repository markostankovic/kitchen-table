// Router and shell behaviour.
//
// Covers Phase 0's "app navigates between four blank tabs" and Phase 1a's
// centralized auth redirect (docs/ARCHITECTURE.md, "Routing").
//
// Providers are overridden rather than mocked -- Riverpod's own override
// mechanism means no mocking package, so CLAUDE.md rule 8 is never triggered.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/features/auth/application/auth_providers.dart';
import 'package:kitchen_table/features/auth/domain/app_user.dart';
import 'package:kitchen_table/features/auth/domain/profile.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/main.dart';

const AppUser _user = AppUser(id: 'u1', email: 'a@example.com');
const Profile _profile = Profile(id: 'u1', displayName: 'Marko');
const Household _household = Household(
  id: 'h1',
  name: 'Test Household',
  createdBy: 'u1',
);

/// Pumps the app with auth state forced to a known shape.
///
/// [userId] null means signed out; [household] null means signed in but not
/// yet onboarded.
Future<void> pumpApp(
  WidgetTester tester, {
  String? userId = 'u1',
  Household? household = _household,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWith((Ref ref) => Stream<String?>.value(userId)),
        currentHouseholdProvider.overrideWith((Ref ref) async => household),
        authStateProvider.overrideWith(
            (Ref ref) => Stream<AppUser?>.value(userId == null ? null : _user)),
        ownProfileProvider.overrideWith((Ref ref) async => _profile),
      ],
      child: const KitchenTableApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('auth redirect', () {
    testWidgets('signed out lands on sign-in', (WidgetTester tester) async {
      await pumpApp(tester, userId: null, household: null);
      expect(find.text('Send code'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing,
          reason: 'onboarding routes sit outside the shell');
    });

    testWidgets('signed in without a household lands on onboarding',
        (WidgetTester tester) async {
      await pumpApp(tester, household: null);
      expect(find.text('Name your household'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('signed in and onboarded lands in the shell',
        (WidgetTester tester) async {
      await pumpApp(tester);
      expect(find.widgetWithText(AppBar, 'Recipes'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  group('shell', () {
    testWidgets('shows all four destinations', (WidgetTester tester) async {
      await pumpApp(tester);
      final NavigationBar bar =
          tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.destinations, hasLength(4));
    });

    testWidgets('navigates between all four tabs',
        (WidgetTester tester) async {
      await pumpApp(tester);

      for (final String label in <String>[
        'Plan',
        'List',
        'Settings',
        'Recipes',
      ]) {
        await tester.tap(find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ));
        await tester.pumpAndSettle();
        expect(
          find.widgetWithText(AppBar, label),
          findsOneWidget,
          reason: 'tapping "$label" should show the $label screen',
        );
      }
    });

    testWidgets('preserves the selected tab index',
        (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('List'),
      ));
      await tester.pumpAndSettle();

      final NavigationBar bar =
          tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 2);
    });
  });

  group('settings', () {
    testWidgets('shows identity and opens the household screen',
        (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Settings'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Marko'), findsOneWidget);
      expect(find.text('a@example.com'), findsOneWidget);

      await tester.tap(find.text('Household'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Household'), findsOneWidget);
      expect(find.text('Test Household'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget,
          reason: 'the household screen is nested inside the Settings tab');
    });
  });
}
