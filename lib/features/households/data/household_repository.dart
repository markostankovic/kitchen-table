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

import '../../../core/error/app_failure.dart';
import '../domain/household.dart';
import '../domain/household_invite.dart';
import '../domain/household_member.dart';
import 'dto/household_dto.dart';
import 'local_household_datasource.dart';
import 'remote_household_datasource.dart';

class HouseholdRepository {
  const HouseholdRepository(this._remote, this._local);

  final RemoteHouseholdDataSource _remote;
  final LocalHouseholdDataSource _local;

  /// Households the caller belongs to, excluding soft-deleted ones, oldest
  /// first -- the network-only list, used by [fetchCurrent] and by nothing
  /// else today.
  Future<List<Household>> fetchMine() async {
    final List<Map<String, dynamic>> rows = await _remote.fetchMineRows();
    return rows.map(householdFromWire).toList();
  }

  /// The caller's current household, or null if they have none yet.
  ///
  /// Multi-household support is not on the roadmap; until it is, "current"
  /// means the first one they joined -- the same tiebreak [fetchMine]
  /// documents, preserved here by caching the DECIDED row rather than the
  /// row set (D88).
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
      await _local.writeCurrent(userId, rows.first);
      return householdFromWire(rows.first);
    } on NetworkFailure {
      onUnreachable?.call();
      final Map<String, dynamic>? cached = await _local.readCurrent(userId);
      if (cached == null) rethrow;
      return householdFromWire(cached);
    }
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

  /// Mints a new six-digit code for the caller's household.
  Future<HouseholdInvite> createInvite() => _remote.createInvite();

  /// Joins the household behind [code].
  ///
  /// Clears the cached current-household row on success, on [create]'s own
  /// reasoning (D88).
  Future<void> redeemInvite(String code) async {
    await _remote.redeemInvite(code);
    await _local.clearAll();
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
}
