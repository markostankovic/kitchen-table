/// Household data access. The only place in this feature that touches Supabase
/// (CLAUDE.md rule 1).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/supabase/supabase_failure.dart';
import '../domain/household.dart';
import '../domain/household_invite.dart';
import '../domain/household_member.dart';

class HouseholdRepository {
  const HouseholdRepository(this._client);

  final SupabaseClient _client;

  /// Households the caller belongs to, excluding soft-deleted ones.
  ///
  /// The `deleted_at` filter is applied *here*, not in the RLS policy: the
  /// policy must keep returning tombstones so the Phase 2 delta fetch can
  /// evict them from the cache (D23).
  Future<List<Household>> fetchMine() => runGuarded(() async {
        final List<Map<String, dynamic>> rows = await _client
            .from('households')
            .select('id, name, created_by, deleted_at')
            .isFilter('deleted_at', null)
            .order('created_at');

        return rows.map(_toHousehold).toList();
      });

  /// The caller's current household, or null if they have none yet.
  ///
  /// Multi-household support is not on the roadmap; until it is, "current"
  /// means the first one they joined.
  Future<Household?> fetchCurrent() async {
    final List<Household> mine = await fetchMine();
    return mine.isEmpty ? null : mine.first;
  }

  /// Creates a household and the caller's owner membership, atomically.
  ///
  /// Goes through the `create_household` RPC because neither table has an
  /// INSERT policy -- a household without members would be orphaned beyond
  /// the reach of RLS.
  Future<String> create(String name) => runGuarded(() async {
        final dynamic id = await _client.rpc<dynamic>(
          'create_household',
          params: <String, dynamic>{'household_name': name},
        );
        return id as String;
      });

  /// Members of [householdId], with their display names.
  ///
  /// One round trip: PostgREST embeds `profiles` through the
  /// `household_members.user_id` foreign key. A left embed on purpose -- with
  /// `!inner`, a member whose profile `profiles_select_co_member` failed to
  /// return would vanish from the list rather than show up as unknown.
  Future<List<HouseholdMember>> fetchMembers(String householdId) =>
      runGuarded(() async {
        final List<Map<String, dynamic>> rows = await _client
            .from('household_members')
            .select('household_id, user_id, role, profiles(display_name)')
            .eq('household_id', householdId)
            .order('created_at');

        return rows.map(_toMember).toList();
      });

  /// Invite codes for [householdId] that can still be redeemed.
  ///
  /// The `used_at` / `expires_at` filters live here rather than in the RLS
  /// policy, which checks membership only (D23).
  Future<List<HouseholdInvite>> fetchLiveInvites(String householdId) =>
      runGuarded(() async {
        final List<Map<String, dynamic>> rows = await _client
            .from('household_invites')
            .select('id, household_id, code, created_by, created_at, '
                'expires_at, used_by, used_at')
            .eq('household_id', householdId)
            .isFilter('used_at', null)
            .gt('expires_at', DateTime.now().toUtc().toIso8601String())
            .order('created_at', ascending: false);

        return rows.map(_toInvite).toList();
      });

  /// Mints a new six-digit code for the caller's household.
  ///
  /// An Edge Function because only the service role may write
  /// `household_invites` (docs/ARCHITECTURE.md, client/edge split). The
  /// household is resolved server-side, so there is nothing to send.
  Future<HouseholdInvite> createInvite() => runGuarded(() async {
        // The session token rides along automatically -- supabase_flutter
        // routes the functions client through AuthHttpClient.
        final FunctionResponse res =
            await _client.functions.invoke('create-invite');

        final Object? data = res.data;
        if (data is! Map<String, dynamic>) {
          throw const UnknownFailure(
              message: 'The server sent an unexpected reply.');
        }
        return _fromInviteResponse(data);
      });

  /// Joins the household behind [code].
  ///
  /// An Edge Function because it writes `household_members`, which no client
  /// may. Returns nothing: the caller invalidates the current-household
  /// provider and the router's redirect does the rest.
  Future<void> redeemInvite(String code) => runGuarded(() async {
        await _client.functions.invoke(
          'redeem-invite',
          body: <String, dynamic>{'code': code.trim()},
        );
      });

  Household _toHousehold(Map<String, dynamic> row) {
    final String? deletedAt = row['deleted_at'] as String?;
    return Household(
      id: row['id'] as String,
      name: row['name'] as String,
      createdBy: row['created_by'] as String,
      deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt),
    );
  }

  HouseholdMember _toMember(Map<String, dynamic> row) {
    final Object? profile = row['profiles'];
    return HouseholdMember(
      householdId: row['household_id'] as String,
      userId: row['user_id'] as String,
      role: HouseholdRole.values.byName(row['role'] as String),
      displayName: profile is Map<String, dynamic>
          ? profile['display_name'] as String?
          : null,
    );
  }

  /// A row read straight from `household_invites` (snake_case).
  HouseholdInvite _toInvite(Map<String, dynamic> row) => HouseholdInvite(
        id: row['id'] as String,
        householdId: row['household_id'] as String,
        code: row['code'] as String,
        createdBy: row['created_by'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        expiresAt: DateTime.parse(row['expires_at'] as String),
        usedBy: row['used_by'] as String?,
        usedAt: row['used_at'] == null
            ? null
            : DateTime.parse(row['used_at'] as String),
      );

  /// An Edge Function reply, which is camelCase because it is a hand-built
  /// JSON body rather than a Postgres row. Mapped by hand for the same reason
  /// [_toInvite] is: the generated `fromJson` expects camelCase, so using it
  /// for one shape and not the other would leave two paths into one model.
  HouseholdInvite _fromInviteResponse(Map<String, dynamic> body) =>
      HouseholdInvite(
        id: body['id'] as String,
        householdId: body['householdId'] as String,
        code: body['code'] as String,
        createdBy: body['createdBy'] as String,
        createdAt: DateTime.parse(body['createdAt'] as String),
        expiresAt: DateTime.parse(body['expiresAt'] as String),
      );
}
