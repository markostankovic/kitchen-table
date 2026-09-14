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
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_en.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/net/network_status.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/features/auth/application/auth_providers.dart';
import 'package:kitchen_table/features/auth/domain/app_user.dart';
import 'package:kitchen_table/features/auth/domain/profile.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/domain/household_invite.dart';
import 'package:kitchen_table/features/households/domain/household_member.dart';
import 'package:kitchen_table/main.dart';

// Read off the generated classes directly rather than hardcoding literals,
// so a wording change in the ARB files cannot silently desync these
// assertions from what the app actually renders (D77, Phase 3 part 1).
// `_profile`'s locale is `AppLocale.sr` (the domain model's own default), so
// `sr` is what every existing assertion below now expects; `en` is only used
// by the one test that pumps an English profile deliberately.
final AppLocalizations sr = AppLocalizationsSr();
final AppLocalizations en = AppLocalizationsEn();

const AppUser _user = AppUser(id: 'u1', email: 'a@example.com');
const Profile _profile = Profile(id: 'u1', displayName: 'Marko');
const Household _household = Household(
  id: 'h1',
  name: 'Test Household',
  createdBy: 'u1',
);
const List<HouseholdMember> _members = <HouseholdMember>[
  HouseholdMember(
    householdId: 'h1',
    userId: 'u1',
    role: HouseholdRole.owner,
    displayName: 'Marko',
  ),
  HouseholdMember(
    householdId: 'h1',
    userId: 'u2',
    role: HouseholdRole.adult,
    displayName: 'Ana',
  ),
];
final List<HouseholdInvite> _invites = <HouseholdInvite>[
  HouseholdInvite(
    id: 'i1',
    householdId: 'h1',
    code: '482913',
    createdBy: 'u1',
    createdAt: DateTime(2026, 9, 7),
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  ),
];

/// Pumps the app with auth state forced to a known shape.
///
/// [userId] null means signed out; [household] null means signed in but not
/// yet onboarded. [profile] defaults to `AppLocale.sr` -- the domain model's
/// own default -- which is why chrome assertions below expect Serbian unless
/// a test overrides it (D77, Phase 3 part 1).
Future<void> pumpApp(
  WidgetTester tester, {
  String? userId = 'u1',
  Household? household = _household,
  Profile profile = _profile,
  Reachability? networkStatus,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWith((Ref ref) => Stream<String?>.value(userId)),
        currentHouseholdProvider.overrideWith((Ref ref) async => household),
        authStateProvider.overrideWith(
            (Ref ref) => Stream<AppUser?>.value(userId == null ? null : _user)),
        ownProfileProvider.overrideWith((Ref ref) async => profile),
        // Without these two the household screen reaches the real
        // repository, and so Supabase.instance.client, which throws.
        householdMembersProvider.overrideWith((Ref ref) async => _members),
        liveInvitesProvider.overrideWith((Ref ref) async => _invites),
        if (networkStatus != null)
          networkStatusProvider.overrideWithValue(networkStatus),
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
      // No profile exists before sign-in, so the pre-auth default (Serbian,
      // D77) is what renders here regardless of any profile fixture.
      expect(find.text(sr.sendCode), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing,
          reason: 'onboarding routes sit outside the shell');
    });

    testWidgets('signed in without a household lands on onboarding',
        (WidgetTester tester) async {
      await pumpApp(tester, household: null);
      // The household-creation screen is not localized in this part.
      expect(find.text('Name your household'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('signed in and onboarded lands in the shell',
        (WidgetTester tester) async {
      await pumpApp(tester);
      expect(find.widgetWithText(AppBar, sr.navRecipes), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets(
      'a NetworkFailure resolving the household does not force the cook '
      'into onboarding -- the third state D87/D88 must preserve: '
      'AsyncError.hasValue is false, so the redirect returns null (no '
      'override) rather than reading the error as "no household yet" and '
      'sending them to CreateHouseholdRoute, which they could not complete '
      'offline anyway (D12)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              currentUserIdProvider.overrideWith(
                (Ref ref) => Stream<String?>.value('u1'),
              ),
              currentHouseholdProvider.overrideWith(
                (Ref ref) async => throw const NetworkFailure(),
              ),
              authStateProvider.overrideWith(
                (Ref ref) => Stream<AppUser?>.value(_user),
              ),
              ownProfileProvider.overrideWith((Ref ref) async => _profile),
            ],
            child: const KitchenTableApp(),
          ),
        );
        await tester.pumpAndSettle();

        // The redirect returning null leaves go_router at its initial
        // location, inside the shell -- it does not itself navigate
        // anywhere. What matters is what it did NOT do: bounce to
        // onboarding, which reading the error as "no household" would have.
        expect(find.text('Name your household'), findsNothing);
        expect(find.text(sr.sendCode), findsNothing);
      },
    );
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

      // Each tab's own AppBar title shares its ARB key with the nav label
      // (D77), so label and title are still the same string per tab -- just
      // a localized one now instead of a hardcoded English one.
      for (final String label in <String>[
        sr.navPlan,
        sr.navList,
        sr.navSettings,
        sr.navRecipes,
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
        matching: find.text(sr.navList),
      ));
      await tester.pumpAndSettle();

      final NavigationBar bar =
          tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 2);
    });

    testWidgets('renders English chrome for an English profile',
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        profile: const Profile(
            id: 'u1', displayName: 'Marko', locale: AppLocale.en),
      );

      final NavigationBar bar =
          tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(
        bar.destinations
            .cast<NavigationDestination>()
            .map((NavigationDestination d) => d.label),
        <String>[en.navRecipes, en.navPlan, en.navList, en.navSettings],
      );
      expect(find.widgetWithText(AppBar, en.navRecipes), findsOneWidget);
    });
  });

  group('offline banner', () {
    testWidgets('renders on Reachability.offline', (WidgetTester tester) async {
      await pumpApp(tester, networkStatus: Reachability.offline);
      expect(find.text(sr.offlineBannerMessage), findsOneWidget);
    });

    testWidgets('renders nothing on Reachability.unknown (the default -- no '
        'read has completed yet)', (WidgetTester tester) async {
      await pumpApp(tester);
      expect(find.text(sr.offlineBannerMessage), findsNothing);
    });

    testWidgets('renders nothing on Reachability.online',
        (WidgetTester tester) async {
      await pumpApp(tester, networkStatus: Reachability.online);
      expect(find.text(sr.offlineBannerMessage), findsNothing);
    });

    testWidgets('stays visible across a tab switch',
        (WidgetTester tester) async {
      await pumpApp(tester, networkStatus: Reachability.offline);

      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(sr.navSettings),
      ));
      await tester.pumpAndSettle();

      expect(find.text(sr.offlineBannerMessage), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('shows identity and opens the household screen',
        (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(sr.navSettings),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Marko'), findsOneWidget);
      expect(find.text('a@example.com'), findsOneWidget);

      await tester.tap(find.text(sr.householdMenuItem));
      await tester.pumpAndSettle();

      // The household screen itself is not localized in this part.
      expect(find.widgetWithText(AppBar, 'Household'), findsOneWidget);
      expect(find.text('Test Household'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget,
          reason: 'the household screen is nested inside the Settings tab');
    });

    testWidgets('the household screen lists members and live invite codes',
        (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(sr.navSettings),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text(sr.householdMenuItem));
      await tester.pumpAndSettle();

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('owner'), findsOneWidget);
      expect(find.text('adult'), findsOneWidget);
      expect(find.text('482913'), findsOneWidget);
    });

    testWidgets('offers the language toggle, selected on the current locale',
        (WidgetTester tester) async {
      await pumpApp(tester);

      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(sr.navSettings),
      ));
      await tester.pumpAndSettle();

      expect(find.text(sr.languageSectionTitle), findsOneWidget);
      // Language names are never translated (D77) -- both segments read the
      // same regardless of which locale is active.
      final SegmentedButton<AppLocale> toggle =
          tester.widget<SegmentedButton<AppLocale>>(
              find.byType(SegmentedButton<AppLocale>));
      expect(toggle.selected, <AppLocale>{AppLocale.sr});
      expect(find.text('Srpski'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });
  });

  group('onboarding', () {
    testWidgets('can reach the join-by-code screen',
        (WidgetTester tester) async {
      await pumpApp(tester, household: null);

      await tester.tap(find.text('I have an invite code'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your invite code'), findsOneWidget,
          reason: 'the redirect must treat /join-household as an onboarding '
              'route, or it bounces straight back to /create-household');
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('can get back to creating a household',
        (WidgetTester tester) async {
      await pumpApp(tester, household: null);

      await tester.tap(find.text('I have an invite code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create a household instead'));
      await tester.pumpAndSettle();

      expect(find.text('Name your household'), findsOneWidget);
    });
  });
}
