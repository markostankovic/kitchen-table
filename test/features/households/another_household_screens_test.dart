// phase9-household-create-join-another -- the onboarding create / join
// screens in their in-app "another" mode, pushed from Settings › Households.
//
// Flat routes at the real paths, so the landing's `go` to Recipes and
// Invite's `go` to the new household's screen land somewhere a test can see.
// The list is a stand-in that pushes the forms, so ✕ and Done have something
// to pop back to.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_table/core/household/current_household.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/core/theme/kitchen_colors.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/presentation/create_household_screen.dart';
import 'package:kitchen_table/features/households/presentation/join_household_screen.dart';
import 'package:kitchen_table/features/households/presentation/onboarding_mark.dart';

import '../../helpers/fake_household_repository.dart';
import '../../helpers/household_switch_harness.dart';

final AppLocalizations sr = AppLocalizationsSr();

const Household _home = Household(id: 'home', name: 'Kod kuće', createdBy: 'u1');
const Household _weekend =
    Household(id: 'weekend', name: 'Vikendica', createdBy: 'u2');

const String _listMarker = 'HOUSEHOLDS LIST';
const String _recipesMarker = 'RECIPES ROOT';
const String _householdPrefix = 'HOUSEHOLD ';

Future<void> _pump(
  WidgetTester tester,
  FakeHouseholdRepository repo, {
  required String open,
}) async {
  final GoRouter router = GoRouter(
    initialLocation: '/settings/households',
    routes: <RouteBase>[
      GoRoute(
        path: '/recipes',
        builder: (_, _) => const Scaffold(body: Text(_recipesMarker)),
      ),
      GoRoute(
        path: '/settings/households',
        builder: (_, _) => const Scaffold(body: Text(_listMarker)),
      ),
      GoRoute(
        path: '/settings/household/:householdId',
        builder: (_, GoRouterState state) => Scaffold(
          body: Text(
            '$_householdPrefix${state.pathParameters['householdId']}',
          ),
        ),
      ),
      GoRoute(
        path: '/households/new',
        builder: (_, _) => const CreateHouseholdScreen(another: true),
      ),
      GoRoute(
        path: '/households/join',
        builder: (_, _) => const JoinHouseholdScreen(another: true),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: householdSwitchOverrides(repo),
      child: MaterialApp.router(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        locale: const Locale('sr'),
        routerConfig: router,
      ),
    ),
  );
  // Listens the way app_router.dart's `ref.listen`s do in the app, which
  // keeps `currentUserIdProvider` live underneath `switchTo`.
  _container(tester)
    ..listen(currentUserIdProvider, (_, _) {})
    ..listen(currentHouseholdProvider, (_, _) {});
  await tester.pumpAndSettle();
  unawaited(router.push(open));
  await tester.pumpAndSettle();
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

Future<String?> _currentId(WidgetTester tester) =>
    _container(tester).read(currentHouseholdIdProvider.future);

/// Lets the snackbar's 4 s timer run out, so no timer is left pending.
Future<void> _drainSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  for (final (String name, String path, String title, String body)
      in <(String, String, String, String)>[
        (
          'create',
          '/households/new',
          sr.createAnotherHouseholdTitle,
          sr.createAnotherHouseholdBody(_home.name),
        ),
        (
          'join',
          '/households/join',
          sr.joinAnotherHouseholdTitle,
          sr.joinAnotherHouseholdBody(_home.name),
        ),
      ]) {
    testWidgets('$name: ✕, no mark, the "another" title and body, no '
        'cross-link', (WidgetTester tester) async {
      await _pump(
        tester,
        FakeHouseholdRepository(<Household>[_home]),
        open: path,
      );

      expect(find.byType(CloseButton), findsOneWidget);
      expect(find.byType(OnboardingMark), findsNothing);
      expect(find.text(title), findsOneWidget);
      expect(find.text(body), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('$name: ✕ returns to the list', (WidgetTester tester) async {
      await _pump(
        tester,
        FakeHouseholdRepository(<Household>[_home]),
        open: path,
      );

      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();

      expect(find.text(_listMarker), findsOneWidget);
    });
  }

  testWidgets('create lands on Recipes in the new household, with Invite', (
    WidgetTester tester,
  ) async {
    final FakeHouseholdRepository repo =
        FakeHouseholdRepository(<Household>[_home]);
    await _pump(tester, repo, open: '/households/new');

    await tester.enterText(find.byType(TextFormField), 'Vikendica');
    await tester.tap(
      find.widgetWithText(FilledButton, sr.createHouseholdButton),
    );
    await tester.pumpAndSettle();

    expect(find.text(_recipesMarker), findsOneWidget);
    expect(repo.selectCalls, <String>['created-2']);
    expect(await _currentId(tester), 'created-2');
    expect(find.text(sr.nowInHousehold('Vikendica')), findsOneWidget);

    await tester.tap(find.text(sr.inviteSnackbarAction));
    await tester.pumpAndSettle();

    expect(find.text('${_householdPrefix}created-2'), findsOneWidget);
    await _drainSnackBar(tester);
  });

  testWidgets('join lands on Recipes with Undo, which switches back', (
    WidgetTester tester,
  ) async {
    final FakeHouseholdRepository repo =
        FakeHouseholdRepository(<Household>[_home]);
    await _pump(tester, repo, open: '/households/join');

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.widgetWithText(FilledButton, sr.joinButton));
    await tester.pumpAndSettle();

    expect(find.text(_recipesMarker), findsOneWidget);
    expect(await _currentId(tester), 'joined-123456');
    expect(find.text(sr.nowInHousehold('Joined')), findsOneWidget);

    await tester.tap(find.text(sr.undoSnackbarAction));
    await tester.pumpAndSettle();

    expect(await _currentId(tester), _home.id);
    await _drainSnackBar(tester);
  });

  group('a code for a household already joined', () {
    FakeHouseholdRepository repo() =>
        FakeHouseholdRepository(<Household>[_home, _weekend])
          ..memberCodes['111111'] = _weekend.id
          ..memberCodes['222222'] = _home.id;

    testWidgets('not current: the quiet panel, Switch, and Use another code', (
      WidgetTester tester,
    ) async {
      final FakeHouseholdRepository r = repo();
      await _pump(tester, r, open: '/households/join');

      await tester.enterText(find.byType(TextField), '111111');
      await tester.tap(find.widgetWithText(FilledButton, sr.joinButton));
      await tester.pumpAndSettle();

      final Finder panel = find.text(sr.alreadyMemberOfHousehold('Vikendica'));
      expect(panel, findsOneWidget);
      expect(find.text(_recipesMarker), findsNothing);
      expect(r.households, hasLength(2));

      // Quiet: the card fill and onSurfaceVariant, never error.
      final ThemeData theme = Theme.of(tester.element(panel));
      expect(
        tester.widget<Text>(panel).style?.color,
        theme.colorScheme.onSurfaceVariant,
      );
      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.ancestor(of: panel, matching: find.byType(DecoratedBox)).first,
      );
      expect(
        (box.decoration as BoxDecoration).color,
        theme.extension<KitchenColors>()!.card,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.info_outline)).color,
        theme.colorScheme.onSurfaceVariant,
      );

      expect(
        find.widgetWithText(
          FilledButton,
          sr.switchToHouseholdButton('Vikendica'),
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextButton, sr.useAnotherCodeButton),
        findsOneWidget,
      );
    });

    testWidgets('not current: Switch lands on Recipes with Undo', (
      WidgetTester tester,
    ) async {
      await _pump(tester, repo(), open: '/households/join');

      await tester.enterText(find.byType(TextField), '111111');
      await tester.tap(find.widgetWithText(FilledButton, sr.joinButton));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          FilledButton,
          sr.switchToHouseholdButton('Vikendica'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_recipesMarker), findsOneWidget);
      expect(await _currentId(tester), _weekend.id);
      expect(find.text(sr.nowInHousehold('Vikendica')), findsOneWidget);
      expect(find.text(sr.undoSnackbarAction), findsOneWidget);
      await _drainSnackBar(tester);
    });

    testWidgets('current: Done, which pops without switching', (
      WidgetTester tester,
    ) async {
      final FakeHouseholdRepository r = repo();
      await _pump(tester, r, open: '/households/join');

      await tester.enterText(find.byType(TextField), '222222');
      await tester.tap(find.widgetWithText(FilledButton, sr.joinButton));
      await tester.pumpAndSettle();

      expect(
        find.text(sr.alreadyMemberOfHousehold(_home.name)),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(FilledButton, sr.doneButton));
      await tester.pumpAndSettle();

      expect(find.text(_listMarker), findsOneWidget);
      expect(r.selectCalls, isEmpty);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Use another code empties the field and the panel', (
      WidgetTester tester,
    ) async {
      await _pump(tester, repo(), open: '/households/join');

      await tester.enterText(find.byType(TextField), '111111');
      await tester.tap(find.widgetWithText(FilledButton, sr.joinButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(sr.useAnotherCodeButton));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty);
      expect(find.text(sr.alreadyMemberOfHousehold('Vikendica')), findsNothing);
      expect(find.widgetWithText(FilledButton, sr.joinButton), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
        isTrue,
      );
    });

    testWidgets('editing the field clears the panel', (
      WidgetTester tester,
    ) async {
      await _pump(tester, repo(), open: '/households/join');

      await tester.enterText(find.byType(TextField), '111111');
      await tester.tap(find.widgetWithText(FilledButton, sr.joinButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '11111');
      await tester.pumpAndSettle();

      expect(find.text(sr.alreadyMemberOfHousehold('Vikendica')), findsNothing);
      expect(find.widgetWithText(FilledButton, sr.joinButton), findsOneWidget);
    });
  });
}
