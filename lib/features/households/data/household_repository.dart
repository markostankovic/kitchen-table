/// Household data access, composed from a Remote half (Supabase) and a
/// Local half (the Drift cache) -- `docs/ARCHITECTURE.md`'s "Offline (Phase
/// 2)" split, the fourth outing after shopping_list, recipes and meal_plan
/// (Phase 2 part 7, D87-D90).
///
/// D70 declined this split for the similarly small `IngredientRepository`,
/// on the grounds that only one of its six methods was worth caching. That
/// precedent does not transfer here: `IngredientRepository.fetchUnitCatalog`
/// 's own network-first-with-fallback read order has never had a test,
/// because there was never a seam to fake `SupabaseClient` against --
/// `unit_catalog_cache_test.dart` proves the cache round trip, never the
/// repository's own `try`/`on NetworkFailure`. D87 exists precisely because
/// an unverified offline claim shipped; repeating that shape here to fix it
/// would draw the wrong lesson from it. `RemoteHouseholdDataSource
/// .fetchMineRows()` is the seam, and `household_repository_offline_test
/// .dart` is what it is for.
///
/// This file itself imports neither `supabase_flutter` nor `drift`: rule 1's
/// "the only place `supabase_flutter` may be imported" now belongs to
/// `RemoteHouseholdDataSource`, and `LocalHouseholdDataSource` is the drift
/// half. This class only orchestrates the two.
library;

import '../../../core/db/device_preferences.dart';
import '../../../core/error/app_failure.dart';
import '../domain/household.dart';
import '../domain/household_invite.dart';
import '../domain/household_member.dart';
import '../domain/household_membership.dart';
import 'dto/household_dto.dart';
import 'local_household_datasource.dart';
import 'remote_household_datasource.dart';

class HouseholdRepository {
  const HouseholdRepository(this._remote, this._local, this._preferences);

  final RemoteHouseholdDataSource _remote;
  final LocalHouseholdDataSource _local;
  final DevicePreferenceStore _preferences;

  /// Households the caller belongs to, excluding soft-deleted ones, oldest
  /// first -- the network-only list.
  Future<List<Household>> fetchMine() async {
    final List<Map<String, dynamic>> rows = await _remote.fetchMineRows();
    return rows.map(householdFromWire).toList();
  }

  /// Every household [userId] belongs to, with their role and the member
  /// count, in the order they joined -- the network-only Households list.
  /// Not cached, as [fetchMine] is not (D88 caches the current row only).
  Future<List<HouseholdMembership>> fetchMemberships({
    required String userId,
  }) async {
    final List<Map<String, dynamic>> rows =
        await _remote.fetchMembershipRows(userId);
    return rows.map(membershipFromWire).toList();
  }

  /// The caller's current household, or null if they have none yet.
  ///
  /// "Current" is the household [userId] last [select]ed on this device, if
  /// they are still in it; otherwise the oldest, the same order [fetchMine]
  /// documents (D169). A stale selection -- a household since left or
  /// deleted -- needs no cleanup: it simply matches no row. The DECIDED row
  /// is what gets cached, not the row set (D88).
  ///
  /// Network-first with a cache fallback (D70's shape, D88): on success the
  /// chosen row is written through (or the cache cleared, if the caller
  /// genuinely has no household -- the branch that keeps a cache miss
  /// unambiguous). On a [NetworkFailure], [userId]'s cached row answers
  /// instead, and a cold cache rethrows honestly rather than guessing.
  ///
  /// Deliberately NOT cache-first: `CreateHouseholdScreen` and
  /// `JoinHouseholdScreen` both `invalidate` this provider and re-await it
  /// expecting a fresh read, and the router's redirect reads the result
  /// synchronously. A stale cached answer served first would break both.
  ///
  /// Only a [NetworkFailure] falls back -- an [UnauthorizedFailure] or any
  /// other refusal must not serve a stale household, the same policy
  /// `ShoppingListRepository.watchLatest` applies.
  Future<Household?> fetchCurrent({
    required String userId,
    void Function()? onReachable,
    void Function()? onUnreachable,
  }) async {
    try {
      final List<Map<String, dynamic>> rows = await _remote.fetchMineRows();
      onReachable?.call();
      if (rows.isEmpty) {
        await _local.clearCurrent(userId);
        return null;
      }
      final String? selected =
          await _preferences.read(selectedHouseholdKey(userId));
      final Map<String, dynamic> current = rows.firstWhere(
        (Map<String, dynamic> row) => row['id'] == selected,
        orElse: () => rows.first,
      );
      await _local.writeCurrent(userId, current);
      return householdFromWire(current);
    } on NetworkFailure {
      onUnreachable?.call();
      final Map<String, dynamic>? cached = await _local.readCurrent(userId);
      if (cached == null) rethrow;
      return householdFromWire(cached);
    }
  }

  /// Makes [householdId] [userId]'s current household on this device (D169).
  ///
  /// Clears [userId]'s cached current-household row too, on [create]'s own
  /// reasoning (D88): the cached row is the OLD household, so a network blip
  /// on the confirming re-fetch must surface as an error rather than silently
  /// serve the household being switched away from.
  Future<void> select({
    required String userId,
    required String householdId,
  }) async {
    await _preferences.write(selectedHouseholdKey(userId), householdId);
    await _local.clearCurrent(userId);
  }

  /// Creates a household and the caller's owner membership, atomically.
  ///
  /// Clears the cached current-household row on success (D88): without this,
  /// a network blip on the confirming re-fetch right after create/join would
  /// let [fetchCurrent]'s cache fallback resurrect whichever household the
  /// caller had before, rather than correctly failing into onboarding.
  Future<String> create(String name) async {
    final String id = await _remote.create(name);
    await _local.clearAll();
    return id;
  }

  /// Members of [householdId], with their display names.
  Future<List<HouseholdMember>> fetchMembers(String householdId) =>
      _remote.fetchMembers(householdId);

  /// Invite codes for [householdId] that can still be redeemed.
  Future<List<HouseholdInvite>> fetchLiveInvites(String householdId) =>
      _remote.fetchLiveInvites(householdId);

  /// Mints a new six-digit code for [householdId].
  Future<HouseholdInvite> createInvite(String householdId) =>
      _remote.createInvite(householdId);

  /// Joins the household behind [code], and returns its id.
  ///
  /// Clears the cached current-household row on success, on [create]'s own
  /// reasoning (D88).
  Future<String> redeemInvite(String code) async {
    final String id = await _remote.redeemInvite(code);
    await _local.clearAll();
    return id;
  }

  /// Renames a household.
  ///
  /// Deliberately does NOT `_local.clearAll()`, unlike [create] and
  /// [redeemInvite] (D88): those clear to stop a network blip on the
  /// confirming re-fetch from resurrecting a household the caller just left,
  /// which does not apply to a rename -- there is no household change to
  /// guard against. The cache is refreshed by the confirming re-fetch's own
  /// write-through; if that re-fetch fails offline, the cache keeps serving
  /// the old name until the next successful read.
  Future<void> rename(String id, String name) =>
      _remote.rename(id, name.trim());

  /// Removes [userId] from [householdId]. Owner-only, enforced by the RPC.
  Future<void> removeMember(String householdId, String userId) =>
      _remote.removeMember(householdId, userId);

  /// Caller leaves [householdId].
  ///
  /// Clears the cached current-household row on success, on [create] and
  /// [redeemInvite]'s own reasoning (D88) -- this is precisely the case that
  /// reasoning describes: without the clear, a network blip on the confirming
  /// re-fetch could let [fetchCurrent]'s cache fallback resurrect the
  /// household the caller just left.
  Future<void> leaveHousehold(String householdId) async {
    await _remote.leaveHousehold(householdId);
    await _local.clearAll();
  }

  /// Revokes a live invite code.
  Future<void> revokeInvite(String inviteId) =>
      _remote.revokeInvite(inviteId);

  /// Deletes [householdId]. Owner-only, enforced by the RPC.
  ///
  /// Clears the cached current-household row on success, on [create],
  /// [redeemInvite] and [leaveHousehold]'s own reasoning (D88): without the
  /// clear, a network blip on the confirming re-fetch could let
  /// [fetchCurrent]'s cache fallback resurrect the household the caller just
  /// deleted.
  Future<void> deleteHousehold(String householdId) async {
    await _remote.deleteHousehold(householdId);
    await _local.clearAll();
  }
}
