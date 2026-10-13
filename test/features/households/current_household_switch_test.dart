// multi-household-b (D169) -- CurrentHousehold.switchTo is the one way to
// change households, and currentHouseholdIdProvider (D52) follows it.
//
// A ProviderContainer over a two-household fake repository: no widget, no
// Supabase, no Drift. The repository's own selection rules are proved in
// household_repository_offline_test.dart; this proves the provider wiring.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/household/current_household.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/domain/household_member.dart';
import 'package:kitchen_table/features/households/domain/household_membership.dart';

import '../../helpers/fake_household_repository.dart';

const Household _home = Household(id: 'home', name: 'Home', createdBy: 'u1');
const Household _weekend =
    Household(id: 'weekend', name: 'Weekend', createdBy: 'u2');

ProviderContainer _container(FakeHouseholdRepository repo) {
  final ProviderContainer container = ProviderContainer(
    overrides: [
      householdRepositoryProvider.overrideWithValue(repo),
      currentUserIdProvider.overrideWith(
        (Ref ref) => Stream<String?>.value('u1'),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Lets `currentUserIdProvider`'s stream deliver its value before the first
/// read, the way the app's auth state has long since arrived by the time
/// anything switches.
Future<void> _signedIn(ProviderContainer container) async {
  container.listen(currentUserIdProvider, (_, _) {});
  await container.read(currentUserIdProvider.future);
}

void main() {
  test('with no selection, the oldest household is current', () async {
    final ProviderContainer container = _container(
      FakeHouseholdRepository(<Household>[_home, _weekend]),
    );
    await _signedIn(container);

    expect(await container.read(currentHouseholdIdProvider.future), 'home');
  });

  test('switchTo(B) makes currentHouseholdIdProvider yield B', () async {
    final FakeHouseholdRepository repo =
        FakeHouseholdRepository(<Household>[_home, _weekend]);
    final ProviderContainer container = _container(repo);
    await _signedIn(container);
    container.listen(currentHouseholdIdProvider, (_, _) {});
    expect(await container.read(currentHouseholdIdProvider.future), 'home');

    await container
        .read(currentHouseholdProvider.notifier)
        .switchTo('weekend');

    expect(repo.selectCalls, <String>['weekend']);
    expect(
      await container.read(currentHouseholdIdProvider.future),
      'weekend',
    );
  });

  test('myHouseholdsProvider lists every membership, in join order',
      () async {
    final ProviderContainer container = _container(
      FakeHouseholdRepository(<Household>[_home, _weekend]),
    );
    await _signedIn(container);

    final List<HouseholdMembership> mine =
        await container.read(myHouseholdsProvider.future);
    expect(
      mine.map((HouseholdMembership m) => m.household.id),
      <String>['home', 'weekend'],
    );
    expect(
      mine.map((HouseholdMembership m) => m.role),
      <HouseholdRole>[HouseholdRole.owner, HouseholdRole.adult],
    );
  });

  test('householdByIdProvider finds one of yours, and null otherwise',
      () async {
    final ProviderContainer container = _container(
      FakeHouseholdRepository(<Household>[_home, _weekend]),
    );
    await _signedIn(container);

    expect(
      await container.read(householdByIdProvider('weekend').future),
      _weekend,
    );
    expect(
      await container.read(householdByIdProvider('elsewhere').future),
      isNull,
    );
  });

  test('myHouseholdsProvider picks up a household added by a switch',
      () async {
    final FakeHouseholdRepository repo =
        FakeHouseholdRepository(<Household>[_home]);
    final ProviderContainer container = _container(repo);
    await _signedIn(container);
    container.listen(myHouseholdsProvider, (_, _) {});
    expect(await container.read(myHouseholdsProvider.future), hasLength(1));

    final String joined = await repo.redeemInvite('123456');
    await container.read(currentHouseholdProvider.notifier).switchTo(joined);

    expect(
      (await container.read(myHouseholdsProvider.future))
          .map((HouseholdMembership m) => m.household.id),
      <String>['home', joined],
    );
  });
}
