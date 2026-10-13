// Router and shell behaviour.
//
// Covers Phase 0's "app navigates between four blank tabs" and Phase 1a's
// centralized auth redirect (docs/ARCHITECTURE.md, "Routing").
//
// Providers are overridden rather than mocked -- Riverpod's own override
// mechanism means no mocking package, so CLAUDE.md rule 8 is never triggered.

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/db/app_database.dart';
import 'package:kitchen_table/core/db/device_preferences.dart';
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
import 'package:kitchen_table/features/households/domain/household_membership.dart';
import 'package:kitchen_table/features/meal_plan/application/meal_plan_providers.dart';
import 'package:kitchen_table/features/meal_plan/domain/meal_plan_week.dart';
import 'package:kitchen_table/features/meal_plan/domain/plan_week.dart';
import 'package:kitchen_table/features/shopping_list/application/shopping_list_providers.dart';
import 'package:kitchen_table/features/shopping_list/domain/shopping_list.dart';
import 'package:kitchen_table/main.dart';

import '../../helpers/fixed_current_household.dart';

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
  AppDatabase? db,
  MealPlanEditor Function()? mealPlanEditor,
  CurrentShoppingList Function()? shoppingList,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserIdProvider.overrideWith((Ref ref) => Stream<String?>.value(userId)),
        currentHouseholdProvider.overrideWith(
            () => FixedCurrentHousehold(() async => household)),
        authStateProvider.overrideWith(
            (Ref ref) => Stream<AppUser?>.value(userId == null ? null : _user)),
        ownProfileProvider.overrideWith((Ref ref) async => profile),
        // Without these three the household screen reaches the real
        // repository, and so Supabase.instance.client, which throws. One
        // household, so Settings keeps its one-household row.
        householdMembersProvider.overrideWith(
          (Ref ref, String householdId) async => _members,
        ),
        liveInvitesProvider.overrideWith(
          (Ref ref, String householdId) async => _invites,
        ),
        myHouseholdsProvider.overrideWith(
          (Ref ref) async => <HouseholdMembership>[
            if (household != null)
              HouseholdMembership(
                household: household,
                role: HouseholdRole.owner,
                memberCount: _members.length,
              ),
          ],
        ),
        if (networkStatus != null)
          networkStatusProvider.overrideWithValue(networkStatus),
        if (db != null) appDatabaseProvider.overrideWithValue(db),
        if (mealPlanEditor != null)
          mealPlanEditorProvider.overrideWith(mealPlanEditor),
        if (shoppingList != null)
          currentShoppingListProvider.overrideWith(shoppingList),
      ],
      child: const KitchenTableApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Captured calls, kept off the notifiers: `riverpod_lint`'s
/// `avoid_public_notifier_properties` forbids public fields on a `Notifier`
/// subclass (the arrangement `shopping_list_screen_test.dart` uses).
class _Counts {
  int planBuilds = 0;
  int listBuilds = 0;
  int generates = 0;
}

/// Each `build()` is one re-read of the Plan tab.
class _CountingMealPlanEditor extends MealPlanEditor {
  _CountingMealPlanEditor(this.counts);

  final _Counts counts;

  @override
  Stream<MealPlanWeek> build() async* {
    counts.planBuilds++;
    yield MealPlanWeek.empty(PlanWeek.of(DateTime(2026, 10, 5)));
  }
}

/// Each `build()` is one re-read of the List tab; a tab switch must never
/// reach `generate()` or `regenerateCurrent()` (D147, D149).
class _CountingShoppingList extends CurrentShoppingList {
  _CountingShoppingList(this.counts);

  final _Counts counts;

  @override
  Stream<ShoppingList?> build() async* {
    counts.listBuilds++;
    yield null;
  }

  @override
  Future<void> generate() async => counts.generates++;

  @override
  Future<void> regenerateCurrent() async => counts.generates++;
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  ));
  await tester.pumpAndSettle();
}

/// Settings' household row, by the household's name (Phase 7 part 9b --
/// there is no fixed "Household" label on it any more).
Future<void> _openHousehold(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Test Household'),
    100,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.text('Test Household'));
  await tester.pumpAndSettle();
}

void main() {
  group('auth redirect', () {
    testWidgets('signed out lands on sign-in', (WidgetTester tester) async {
      await pumpApp(tester, userId: null, household: null);
      // No profile exists before sign-in, so the pre-auth default (Serbian,
      // D77) is what renders here regardless of any profile fixture.
      expect(find.text(sr.signInWithGoogle), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing,
          reason: 'onboarding routes sit outside the shell');
    });

    testWidgets('signed in without a household lands on onboarding',
        (WidgetTester tester) async {
      await pumpApp(tester, household: null);
      expect(find.text(sr.createHouseholdTitle), findsOneWidget);
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
                () => FixedCurrentHousehold(
                  () async => throw const NetworkFailure(),
                ),
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
        expect(find.text(sr.createHouseholdTitle), findsNothing);
        expect(find.text(sr.signInWithGoogle), findsNothing);
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

  // Phase 8 part 3 (D149): switching to a tab re-reads it; re-tapping the
  // current tab does not.
  group('refresh on tab switch', () {
    testWidgets('switching onto Plan rebuilds its provider once per switch',
        (WidgetTester tester) async {
      final _Counts counts = _Counts();
      await pumpApp(tester,
          mealPlanEditor: () => _CountingMealPlanEditor(counts));

      await _tapTab(tester, sr.navPlan);
      expect(counts.planBuilds, 1);

      await _tapTab(tester, sr.navRecipes);
      expect(counts.planBuilds, 1, reason: 'leaving Plan does not re-read it');

      await _tapTab(tester, sr.navPlan);
      expect(counts.planBuilds, 2);
    });

    testWidgets('switching onto List rebuilds it and never generates',
        (WidgetTester tester) async {
      final _Counts counts = _Counts();
      await pumpApp(tester, shoppingList: () => _CountingShoppingList(counts));

      await _tapTab(tester, sr.navList);
      expect(counts.listBuilds, 1);

      await _tapTab(tester, sr.navRecipes);
      await _tapTab(tester, sr.navList);
      expect(counts.listBuilds, 2);
      expect(counts.generates, 0);
    });

    testWidgets('re-tapping the current tab does not rebuild its provider',
        (WidgetTester tester) async {
      final _Counts counts = _Counts();
      await pumpApp(
        tester,
        mealPlanEditor: () => _CountingMealPlanEditor(counts),
        shoppingList: () => _CountingShoppingList(counts),
      );

      await _tapTab(tester, sr.navPlan);
      await _tapTab(tester, sr.navPlan);
      expect(counts.planBuilds, 1);

      await _tapTab(tester, sr.navList);
      await _tapTab(tester, sr.navList);
      expect(counts.listBuilds, 1);
      expect(counts.generates, 0);
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

      await _openHousehold(tester);

      expect(find.widgetWithText(AppBar, sr.householdScreenTitle),
          findsOneWidget);
      // The Settings screen underneath is offstage, so this finds only the
      // household screen's own header.
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
      await _openHousehold(tester);

      expect(find.text('Ana'), findsOneWidget);
      // The caller is the owner, so their own row carries `· vi`.
      expect(find.text(sr.householdMemberYou(sr.householdRoleOwner)),
          findsOneWidget);
      expect(find.text(sr.householdRoleAdult), findsOneWidget);
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

  // Phase 7 part 9b: the grouped Settings screen.
  group('settings layout', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(sr.navSettings),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('renders in Serbian at 360x780 without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await pumpApp(tester);
      await openSettings(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(sr.appearanceSectionTitle), findsOneWidget);
      expect(find.text(sr.themeSubtitle), findsOneWidget);
      expect(find.text(sr.signedInWithGoogle), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(sr.signOut),
        100,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(sr.householdMemberCount(2)), findsOneWidget);
      expect(find.text(sr.accountSectionTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sign-out is a neutral OutlinedButton, not error-coloured',
        (WidgetTester tester) async {
      await pumpApp(tester);
      await openSettings(tester);
      await tester.scrollUntilVisible(
        find.text(sr.signOut),
        100,
        scrollable: find.byType(Scrollable).last,
      );

      final Finder button = find.ancestor(
        of: find.text(sr.signOut),
        matching: find.byWidgetPredicate((Widget w) => w is OutlinedButton),
      );
      expect(button, findsOneWidget);
      final ColorScheme scheme =
          Theme.of(tester.element(button)).colorScheme;
      final Color? fg = tester
          .widget<ButtonStyleButton>(button)
          .style
          ?.foregroundColor
          ?.resolve(<WidgetState>{});
      expect(fg, scheme.onSurface);
      expect(fg, isNot(scheme.error));
    });

    testWidgets('the theme segment writes the device store',
        (WidgetTester tester) async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await pumpApp(tester, db: db);
      await openSettings(tester);

      await tester.tap(find.text(sr.themeDark));
      await tester.pumpAndSettle();

      expect(await DevicePreferenceStore(db).read(themeModeKey), 'dark');
      final MaterialApp app =
          tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
    });

    testWidgets('the language labels are never translated',
        (WidgetTester tester) async {
      await pumpApp(
        tester,
        profile: const Profile(
          id: 'u1',
          displayName: 'Marko',
          locale: AppLocale.en,
        ),
      );
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(en.navSettings),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Srpski'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text(en.themeLight), findsOneWidget);
    });
  });

  group('onboarding', () {
    testWidgets('can reach the join-by-code screen',
        (WidgetTester tester) async {
      await pumpApp(tester, household: null);

      await tester.tap(find.text(sr.haveInviteCodeButton));
      await tester.pumpAndSettle();

      expect(find.text(sr.joinHouseholdTitle), findsOneWidget,
          reason: 'the redirect must treat /join-household as an onboarding '
              'route, or it bounces straight back to /create-household');
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('can get back to creating a household',
        (WidgetTester tester) async {
      await pumpApp(tester, household: null);

      await tester.tap(find.text(sr.haveInviteCodeButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(sr.createHouseholdInsteadButton));
      await tester.pumpAndSettle();

      expect(find.text(sr.createHouseholdTitle), findsOneWidget);
    });
  });
}
