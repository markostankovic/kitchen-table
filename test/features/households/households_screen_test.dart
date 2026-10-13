// phase9-household-list -- the Households screen: every household the
// caller belongs to, in join order; a row switches, its gear manages.
//
// Providers are overridden rather than mocked (household_screen_test.dart's
// own precedent), so CLAUDE.md rule 8 is never triggered.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/data/household_repository.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/domain/household_member.dart';
import 'package:kitchen_table/features/households/domain/household_membership.dart';
import 'package:kitchen_table/features/households/presentation/households_screen.dart';

import '../../helpers/fixed_current_household.dart';

final AppLocalizations sr = AppLocalizationsSr();

const String _longName = 'Porodica Stanković – vikendica';

const List<HouseholdMembership> _mine = <HouseholdMembership>[
  HouseholdMembership(
    household: Household(id: 'mira', name: 'Kod Mire', createdBy: 'u2'),
    role: HouseholdRole.adult,
    memberCount: 2,
  ),
  HouseholdMembership(
    household: Household(id: 'weekend', name: _longName, createdBy: 'u1'),
    role: HouseholdRole.owner,
    memberCount: 1,
  ),
];

/// `implements`, the house style: every unstubbed member throws by omission.
class _FakeRepo implements HouseholdRepository {
  String selected = 'mira';
  final List<String> selectCalls = <String>[];

  @override
  Future<List<HouseholdMembership>> fetchMemberships({
    required String userId,
  }) async => _mine;

  @override
  Future<void> select({
    required String userId,
    required String householdId,
  }) async {
    selectCalls.add(householdId);
    selected = householdId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

const String _managePrefix = 'MANAGE ';

Future<void> _pump(WidgetTester tester, _FakeRepo repo) async {
  final GoRouter router = GoRouter(
    initialLocation: '/settings/households',
    routes: <RouteBase>[
      GoRoute(
        path: '/settings/households',
        builder: (_, _) => const HouseholdsScreen(),
      ),
      GoRoute(
        path: '/settings/household/:householdId',
        builder: (_, GoRouterState state) => Scaffold(
          body: Text('$_managePrefix${state.pathParameters['householdId']}'),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        householdRepositoryProvider.overrideWithValue(repo),
        currentUserIdProvider.overrideWith(
          (Ref ref) => Stream<String?>.value('u1'),
        ),
        currentHouseholdProvider.overrideWith(
          () => FixedCurrentHousehold(
            () async => _mine
                .map((HouseholdMembership m) => m.household)
                .firstWhere((Household h) => h.id == repo.selected),
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

Finder _rowRadio(String name, IconData icon) => find.descendant(
  of: find.ancestor(of: find.text(name), matching: find.byType(InkWell)),
  matching: find.byIcon(icon),
);

void main() {
  testWidgets('rows render in the order given', (WidgetTester tester) async {
    await _pump(tester, _FakeRepo());

    expect(find.text(sr.householdsScreenTitle), findsOneWidget);
    expect(find.text(sr.householdsIntro), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Kod Mire')).dy,
      lessThan(tester.getTopLeft(find.text(_longName)).dy),
    );
  });

  testWidgets('exactly one checked radio, on the current row', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _FakeRepo());

    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(_rowRadio('Kod Mire', Icons.radio_button_checked), findsOneWidget);
    expect(_rowRadio(_longName, Icons.radio_button_unchecked), findsOneWidget);
  });

  testWidgets('the Serbian meta reads members · role', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _FakeRepo());

    expect(find.text('2 člana · Član'), findsOneWidget);
    expect(find.text('1 član · Vlasnik'), findsOneWidget);
  });

  testWidgets('a long name renders whole, never ellipsized', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, _FakeRepo());

    expect(tester.takeException(), isNull);
    final Text name = tester.widget<Text>(find.text(_longName));
    expect(name.maxLines, isNull);
    expect(name.overflow, isNull);
  });

  testWidgets('tapping a non-current row switches to it', (
    WidgetTester tester,
  ) async {
    final _FakeRepo repo = _FakeRepo();
    await _pump(tester, repo);

    await tester.tap(find.text(_longName));
    await tester.pumpAndSettle();

    expect(repo.selectCalls, <String>['weekend']);
    expect(_rowRadio(_longName, Icons.radio_button_checked), findsOneWidget);
  });

  testWidgets('tapping the current row does nothing', (
    WidgetTester tester,
  ) async {
    final _FakeRepo repo = _FakeRepo();
    await _pump(tester, repo);

    await tester.tap(find.text('Kod Mire'));
    await tester.pumpAndSettle();

    expect(repo.selectCalls, isEmpty);
  });

  testWidgets("the gear's tooltip names the household, and it opens it", (
    WidgetTester tester,
  ) async {
    await _pump(tester, _FakeRepo());

    expect(find.byTooltip('Upravljajte: Kod Mire'), findsOneWidget);
    expect(find.byTooltip('Upravljajte: $_longName'), findsOneWidget);

    await tester.tap(find.byTooltip('Upravljajte: $_longName'));
    await tester.pumpAndSettle();

    expect(find.text('${_managePrefix}weekend'), findsOneWidget);
  });
}
