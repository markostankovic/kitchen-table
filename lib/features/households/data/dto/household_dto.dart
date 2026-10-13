/// The wire shape of one `households` row.
///
/// [householdFromWire] is the single decoder for both a fresh PostgREST
/// response and a cache hit (D65, D88) -- there is no separate `toWire()`
/// encoder here, on `recipe_dto.dart`'s own precedent rather than
/// `unit_catalog_dto.dart`'s: a household row is never built up from a
/// domain object before being cached, only ever read off the wire and
/// stored as-is (`jsonEncode` of exactly what `RemoteHouseholdDataSource
/// .fetchMineRows` returned).
library;

import '../../domain/household.dart';
import '../../domain/household_member.dart';
import '../../domain/household_membership.dart';

Household householdFromWire(Map<String, dynamic> row) {
  final String? deletedAt = row['deleted_at'] as String?;
  return Household(
    id: row['id'] as String,
    name: row['name'] as String,
    createdBy: row['created_by'] as String,
    deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt),
  );
}

/// A `household_members.role` value. The one mapping, shared by
/// [membershipFromWire] and `RemoteHouseholdDataSource`'s member rows.
HouseholdRole householdRoleFromWire(String role) =>
    HouseholdRole.values.byName(role);

/// One of the caller's own `household_members` rows, with its household
/// embedded and that household's member ids nested under it
/// (`RemoteHouseholdDataSource.fetchMembershipRows`). The member count is the
/// nested list's length.
HouseholdMembership membershipFromWire(Map<String, dynamic> row) {
  final Map<String, dynamic> household =
      row['households'] as Map<String, dynamic>;
  final List<dynamic> members =
      household['household_members'] as List<dynamic>? ?? const <dynamic>[];
  return HouseholdMembership(
    household: householdFromWire(household),
    role: householdRoleFromWire(row['role'] as String),
    memberCount: members.length,
  );
}
