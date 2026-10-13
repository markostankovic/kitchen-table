// phase9-import-save-to -- the import review's "Saves to X" condition, the
// tab header's rule (D171) for a named household.
//
// Providers are overridden rather than mocked (household_tab_title_test.dart's
// precedent), so CLAUDE.md rule 8 is never triggered.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/error/app_failure.dart';
import 'package:kitchen_table/core/household/current_household.dart';
import 'package:kitchen_table/core/supabase/supabase_client.dart';
import 'package:kitchen_table/features/households/application/household_providers.dart';
import 'package:kitchen_table/features/households/domain/household.dart';
import 'package:kitchen_table/features/households/domain/household_membership.dart';

import '../../helpers/fake_household_repository.dart';
import '../../helpers/fixed_current_household.dart';

const Household _mira = Household(id: 'mira', name: 'Kod Mire', createdBy: 'u1');
const Household _weekend = Household(
  id: 'weekend',
  name: 'Porodica Stanković – vikendica',
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

Future<String?> _nameOf(FakeHouseholdRepository repo, String id) async {
  final ProviderContainer container = ProviderContainer(
    // No retry: a retried myHouseholds goes back to loading, and the offline
    // case would wait on it forever instead of reading the failure once.
    retry: (_, _) => null,
    overrides: [
      householdRepositoryProvider.overrideWithValue(repo),
      currentUserIdProvider.overrideWith(
        (Ref ref) => Stream<String?>.value('u1'),
      ),
      currentHouseholdProvider.overrideWith(
        () => FixedCurrentHousehold(() => repo.fetchCurrent(userId: 'u1')),
      ),
    ],
  );
  addTearDown(container.dispose);
  // myHouseholds reads the user id's `.value`, so it must have arrived first,
  // as it has long before any review opens.
  container.listen(currentUserIdProvider, (_, _) {});
  await container.read(currentUserIdProvider.future);
  // Listened, so the autoDispose family is not disposed mid-read.
  container.listen(householdNameAmongManyProvider(id), (_, _) {});
  return container.read(householdNameAmongManyProvider(id).future);
}

void main() {
  test('one household gives null', () async {
    expect(
      await _nameOf(FakeHouseholdRepository(<Household>[_mira]), 'mira'),
      isNull,
    );
  });

  test('2+ households give the named one, current or not', () async {
    final FakeHouseholdRepository repo = FakeHouseholdRepository(<Household>[
      _mira,
      _weekend,
    ]);
    expect(await _nameOf(repo, 'mira'), _mira.name);
    expect(await _nameOf(repo, 'weekend'), _weekend.name);
  });

  test('an id not among them gives null', () async {
    expect(
      await _nameOf(
        FakeHouseholdRepository(<Household>[_mira, _weekend]),
        'elsewhere',
      ),
      isNull,
    );
  });

  test('an AppFailure (offline) gives null', () async {
    expect(
      await _nameOf(_OfflineRepo(<Household>[_mira, _weekend]), 'mira'),
      isNull,
    );
  });
}
