// phase9-household-switcher -- the tab header's household line and the
// switch sheet it opens.
//
// Providers are overridden rather than mocked (households_screen_test.dart's
// own precedent), so CLAUDE.md rule 8 is never triggered.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/household/widgets/household_tab_title.dart';
import 'package:kitchen_table/core/l10n/app_locale.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations.dart';
import 'package:kitchen_table/core/l10n/generated/app_localizations_sr.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/core/theme/app_spacing.dart';
import 'package:kitchen_table/core/theme/app_theme.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/domain/household_membership.dart';

import '../../helpers/fake_household_repository.dart';
import '../../helpers/fixed_current_household.dart';

final AppLocalizations sr = AppLocalizationsSr();

const String _longName = 'Porodica Stanković – vikendica';
const String _title = 'Recepti';
const String _householdsPage = 'HOUSEHOLDS PAGE';

const Household _mira = Household(id: 'mira', name: 'Kod Mire', createdBy: 'u2');
const Household _weekend = Household(
  id: 'weekend',
  name: _longName,
  createdBy: 'u1',
);

/// `myHouseholds` fails as it does offline.
class _OfflineRepo extends FakeHouseholdRepository {
  _OfflineRepo(super.households);

  @override
  Future<List<HouseholdMembership>> fetchMemberships({
    required String userId,
  }) async => throw const NetworkFailure(message: 'offline');
}

Future<void> _pump(
  WidgetTester tester,
  FakeHouseholdRepository repo, {
  Locale locale = const Locale('sr'),
}) async {
  final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          appBar: AppBar(
            titleSpacing: AppSpacing.sm,
            title: const HouseholdTabTitle(title: _title),
            actions: <Widget>[
              IconButton(icon: const Icon(Icons.copy_outlined), onPressed: () {}),
              IconButton(
                icon: const Icon(Icons.refresh_outlined),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/settings/households',
        builder: (_, _) => const Scaffold(body: Text(_householdsPage)),
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
          () => FixedCurrentHousehold(() => repo.fetchCurrent(userId: 'u1')),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: appSupportedLocales,
        locale: locale,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _header => find.descendant(
  of: find.byType(AppBar),
  matching: find.byType(HouseholdTabTitle),
);

Finder _rowRadio(String name, IconData icon) => find.descendant(
  of: find.ancestor(of: find.text(name).last, matching: find.byType(InkWell)),
  matching: find.byIcon(icon),
);

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.text(_title));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('one household shows only the title', (
    WidgetTester tester,
  ) async {
    await _pump(tester, FakeHouseholdRepository(<Household>[_mira]));

    expect(find.text(_title), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(
      find.descendant(of: _header, matching: find.byType(InkWell)),
      findsNothing,
    );
    // Still at x 16: titleSpacing sm plus the widget's own sm.
    expect(tester.getTopLeft(find.text(_title)).dx, AppSpacing.lg);
  });

  testWidgets('myHouseholds failing gives the one-household look', (
    WidgetTester tester,
  ) async {
    await _pump(tester, _OfflineRepo(<Household>[_mira, _weekend]));

    expect(find.text(_title), findsOneWidget);
    expect(find.text('Kod Mire'), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsNothing);
  });

  testWidgets('two households show the name and the ▾', (
    WidgetTester tester,
  ) async {
    await _pump(tester, FakeHouseholdRepository(<Household>[_mira, _weekend]));

    expect(find.text(_title), findsOneWidget);
    expect(find.text('Kod Mire'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(tester.getTopLeft(find.text(_title)).dx, AppSpacing.lg);
  });

  testWidgets('the title keeps the bar\'s titleLarge with two households', (
    WidgetTester tester,
  ) async {
    await _pump(tester, FakeHouseholdRepository(<Household>[_mira, _weekend]));

    final TextStyle titleLarge =
        Theme.of(tester.element(find.byType(AppBar))).textTheme.titleLarge!;
    final TextStyle rendered = tester
        .renderObject<RenderParagraph>(find.text(_title))
        .text
        .style!;
    expect(rendered.fontSize, titleLarge.fontSize);
    expect(rendered.fontWeight, titleLarge.fontWeight);
  });

  testWidgets('a long name ellipsizes on one line at 360 wide', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final FakeHouseholdRepository repo = FakeHouseholdRepository(
      <Household>[_mira, _weekend],
    )..selected['u1'] = 'weekend';
    await _pump(tester, repo);

    expect(tester.takeException(), isNull);
    final Text name = tester.widget<Text>(find.text(_longName));
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
  });

  testWidgets('a tap opens the sheet: both rows, one checked, no gear, Manage', (
    WidgetTester tester,
  ) async {
    await _pump(tester, FakeHouseholdRepository(<Household>[_mira, _weekend]));
    await _openSheet(tester);

    expect(find.text(sr.switchHouseholdSheetTitle), findsOneWidget);
    expect(find.text(_longName), findsOneWidget);
    // Kod Mire is in the header and in the sheet.
    expect(find.text('Kod Mire'), findsNWidgets(2));
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    expect(_rowRadio('Kod Mire', Icons.radio_button_checked), findsOneWidget);
    expect(_rowRadio(_longName, Icons.radio_button_unchecked), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text(sr.manageHouseholdsAction), findsOneWidget);
  });

  testWidgets('picking the other row switches, closes, and says Now in X', (
    WidgetTester tester,
  ) async {
    final FakeHouseholdRepository repo = FakeHouseholdRepository(
      <Household>[_mira, _weekend],
    );
    await _pump(tester, repo);
    await _openSheet(tester);

    await tester.tap(find.text(_longName));
    await tester.pumpAndSettle();

    expect(repo.selectCalls, <String>['weekend']);
    expect(find.text(sr.switchHouseholdSheetTitle), findsNothing);
    expect(find.text(sr.nowInHousehold(_longName)), findsOneWidget);
    expect(find.text(sr.undoSnackbarAction), findsOneWidget);
    expect(tester.widget<SnackBar>(find.byType(SnackBar)).persist, isFalse,
        reason: 'it auto-dismisses, like every Undo snackbar here');
  });

  testWidgets('Undo switches back to the previous household', (
    WidgetTester tester,
  ) async {
    final FakeHouseholdRepository repo = FakeHouseholdRepository(
      <Household>[_mira, _weekend],
    );
    await _pump(tester, repo);
    await _openSheet(tester);
    await tester.tap(find.text(_longName));
    await tester.pumpAndSettle();

    await tester.tap(find.text(sr.undoSnackbarAction));
    await tester.pumpAndSettle();

    expect(repo.selectCalls, <String>['weekend', 'mira']);
  });

  testWidgets('Manage households opens the Households route', (
    WidgetTester tester,
  ) async {
    await _pump(tester, FakeHouseholdRepository(<Household>[_mira, _weekend]));
    await _openSheet(tester);

    await tester.tap(find.text(sr.manageHouseholdsAction));
    await tester.pumpAndSettle();

    expect(find.text(_householdsPage), findsOneWidget);
  });
}
