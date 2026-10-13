import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/device_preferences.dart';
import '../../../core/net/network_status.dart';
import '../../../core/supabase/supabase_client.dart';
import '../data/household_repository.dart';
import '../data/local_household_datasource.dart';
import '../data/remote_household_datasource.dart';
import '../domain/household.dart';
import '../domain/household_invite.dart';
import '../domain/household_member.dart';
import '../domain/household_membership.dart';

part 'household_providers.g.dart';

@Riverpod(keepAlive: true)
HouseholdRepository householdRepository(Ref ref) => HouseholdRepository(
  RemoteHouseholdDataSource(ref.watch(supabaseClientProvider)),
  LocalHouseholdDataSource(ref.watch(appDatabaseProvider)),
  DevicePreferenceStore(ref.watch(appDatabaseProvider)),
);

/// The caller's current household, or null if they have not created one.
///
/// "Current" is the household last selected on this device, else the oldest
/// (`HouseholdRepository.fetchCurrent`, D169). [switchTo] changes it.
///
/// Watches `currentUserIdProvider` from `core/` rather than the auth feature's
/// own provider: a different user has a different household, and a signed-out
/// one has none -- but reaching into `features/auth/application/` would be the
/// cross-feature import CLAUDE.md forbids.
///
/// `keepAlive` is justified: the router's redirect reads this on every
/// navigation to decide whether onboarding is finished.
///
/// Passes [userId] into `fetchCurrent` rather than letting the repository
/// read `Supabase.instance.client.auth.currentUser` itself (Phase 2 part 7,
/// D87, D88): `currentUserIdProvider` is already the one definition of "who
/// is signed in" this app keeps, and a second one inside `data/` would be
/// exactly the duplication that provider exists to prevent. Reports
/// reachability into `networkStatusProvider`, on the three screen providers'
/// own precedent (`RecipeList`, `MealPlanEditor`, `CurrentShoppingList`) --
/// this is what makes the global offline banner reachable on a COLD start at
/// all: today its three producers all sit behind this same gate.
@Riverpod(keepAlive: true)
class CurrentHousehold extends _$CurrentHousehold {
  @override
  Future<Household?> build() async {
    final String? userId = ref.watch(currentUserIdProvider).value;
    if (userId == null) return null;
    final NetworkStatus status = ref.read(networkStatusProvider.notifier);
    return ref.watch(householdRepositoryProvider).fetchCurrent(
      userId: userId,
      onReachable: status.reportReachable,
      onUnreachable: status.reportUnreachable,
    );
  }

  /// Makes [householdId] the current household on this device, and waits
  /// for the re-read (D169).
  ///
  /// The one way to change households. The router's
  /// `ref.listen(currentHouseholdProvider…)` and every
  /// `currentHouseholdIdProvider` watcher follow it, so every screen
  /// provider re-keys without being told. Create and join call it with the
  /// new id; the Households list does.
  Future<void> switchTo(String householdId) async {
    final String? userId = ref.read(currentUserIdProvider).value;
    if (userId == null) return;
    await ref
        .read(householdRepositoryProvider)
        .select(userId: userId, householdId: householdId);
    ref.invalidateSelf();
    await future;
  }
}

/// Every household the caller belongs to, in the order they joined, with
/// their role in it and its member count -- the Households list.
///
/// Its own membership query (`fetchMemberships`), not `fetchCurrent`'s
/// oldest-first rows: that order is D169's fallback and stays as it is.
/// Network-only, like `fetchMine` (D88 caches the current row only).
///
/// Watches [currentHouseholdProvider] only to refresh after create, join,
/// leave, delete, rename or a switch -- each of those re-reads it.
@riverpod
Future<List<HouseholdMembership>> myHouseholds(Ref ref) async {
  final String? userId = ref.watch(currentUserIdProvider).value;
  if (userId == null) return const <HouseholdMembership>[];
  await ref.watch(currentHouseholdProvider.future);
  return ref.watch(householdRepositoryProvider).fetchMemberships(
    userId: userId,
  );
}

/// [householdId], if it is one of the caller's households, else null -- the
/// Household screen's header, which may show a household other than the
/// current one.
@riverpod
Future<Household?> householdById(Ref ref, String householdId) async {
  final List<HouseholdMembership> mine = await ref.watch(
    myHouseholdsProvider.future,
  );
  for (final HouseholdMembership m in mine) {
    if (m.household.id == householdId) return m.household;
  }
  return null;
}

/// Everyone in [householdId], for the member list.
///
/// Display names depend on `profiles_select_co_member`; without that policy
/// every co-member renders as unknown.
@riverpod
Future<List<HouseholdMember>> householdMembers(Ref ref, String householdId) =>
    ref.watch(householdRepositoryProvider).fetchMembers(householdId);

/// [householdId]'s invite codes that can still be redeemed, newest first.
@riverpod
Future<List<HouseholdInvite>> liveInvites(Ref ref, String householdId) =>
    ref.watch(householdRepositoryProvider).fetchLiveInvites(householdId);
