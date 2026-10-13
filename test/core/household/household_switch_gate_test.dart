// phase9-household-switch-loading -- when a tab is between a household
// switch and its data.
//
// A real `switchTo` over a fake repository whose `fetchCurrent` can be held
// open, and a stand-in tab provider keyed on `currentHouseholdIdProvider`
// whose own answer can be held too.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/household/current_household.dart';
import 'package:kitchen_table/core/household/widgets/household_switch_gate.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';

import '../../helpers/household_switch_harness.dart';

const Household _home = Household(id: 'home', name: 'Home', createdBy: 'u1');
const Household _weekend =
    Household(id: 'weekend', name: 'Weekend', createdBy: 'u2');

/// While set, the stand-in tab provider waits on it after the household id.
Completer<void>? _dataHold;

final FutureProvider<String?> _tabData = FutureProvider<String?>((
  Ref ref,
) async {
  final String? id = await ref.watch(currentHouseholdIdProvider.future);
  final Completer<void>? hold = _dataHold;
  if (hold != null) await hold.future;
  return id;
});

/// [dataNeverLoading] stands in for a tab whose data has already arrived
/// (a cache emission) while the switch itself is still in flight.
Future<ProviderContainer> _pump(
  WidgetTester tester,
  HeldHouseholdRepository repo, {
  bool dataNeverLoading = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: householdSwitchOverrides(repo),
      child: MaterialApp(
        home: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? _) {
            final AsyncValue<String?> data = ref.watch(_tabData);
            return HouseholdSwitchGate(
              dataLoading: !dataNeverLoading && data.isLoading,
              builder: (BuildContext context, bool awaiting) => Text(
                awaiting ? 'awaiting' : 'data ${data.value}',
              ),
            );
          },
        ),
      ),
    ),
  );
  final ProviderContainer container = ProviderScope.containerOf(
    tester.element(find.byType(Text)),
  );
  // Signed in, as the app's header keeps it: `switchTo` reads the user id.
  container.listen(currentUserIdProvider, (_, _) {});
  await tester.pumpAndSettle();
  return container;
}

void main() {
  tearDown(() => _dataHold = null);

  testWidgets('no switch, never awaiting', (WidgetTester tester) async {
    await _pump(tester, HeldHouseholdRepository(<Household>[_home, _weekend]));

    expect(find.text('data home'), findsOneWidget);
  });

  testWidgets('awaiting from the switch\'s start until the new data', (
    WidgetTester tester,
  ) async {
    final HeldHouseholdRepository repo =
        HeldHouseholdRepository(<Household>[_home, _weekend]);
    final ProviderContainer container = await _pump(tester, repo);

    repo.currentHold = Completer<void>();
    _dataHold = Completer<void>();
    final Future<void> switching =
        container.read(currentHouseholdProvider.notifier).switchTo('weekend');
    await tester.pump();
    expect(find.text('awaiting'), findsOneWidget);

    // The switch resolves; the tab's own data is still loading.
    repo.currentHold!.complete();
    await switching;
    await tester.pump();
    expect(container.read(householdSwitchPendingProvider), isFalse);
    expect(find.text('awaiting'), findsOneWidget);

    _dataHold!.complete();
    await tester.pumpAndSettle();
    expect(find.text('data weekend'), findsOneWidget);
  });

  testWidgets('data that beats the switch\'s return still waits for it', (
    WidgetTester tester,
  ) async {
    final HeldHouseholdRepository repo =
        HeldHouseholdRepository(<Household>[_home, _weekend]);
    final ProviderContainer container = await _pump(
      tester,
      repo,
      dataNeverLoading: true,
    );

    repo.currentHold = Completer<void>();
    final Future<void> switching =
        container.read(currentHouseholdProvider.notifier).switchTo('weekend');
    await tester.pump();
    expect(find.text('awaiting'), findsOneWidget);

    repo.currentHold!.complete();
    await switching;
    await tester.pumpAndSettle();
    expect(find.text('data weekend'), findsOneWidget);
  });

  testWidgets('a failed switch stops awaiting though nothing reloads', (
    WidgetTester tester,
  ) async {
    final HeldHouseholdRepository repo =
        HeldHouseholdRepository(<Household>[_home, _weekend])
          ..selectFailure = const NetworkFailure(message: 'offline');
    final ProviderContainer container = await _pump(tester, repo);

    final Future<void> switching =
        container.read(currentHouseholdProvider.notifier).switchTo('weekend');
    final Future<void> failed = expectLater(
      switching,
      throwsA(isA<NetworkFailure>()),
    );
    await tester.pumpAndSettle();
    await failed;
    expect(find.text('data home'), findsOneWidget);
  });
}
