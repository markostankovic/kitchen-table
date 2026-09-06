/// Household data access. The only place in this feature that touches Supabase
/// (CLAUDE.md rule 1).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_failure.dart';
import '../domain/household.dart';

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

  Household _toHousehold(Map<String, dynamic> row) {
    final String? deletedAt = row['deleted_at'] as String?;
    return Household(
      id: row['id'] as String,
      name: row['name'] as String,
      createdBy: row['created_by'] as String,
      deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt),
    );
  }
}
