import 'household_membership.dart';

/// Where the caller lands after leaving [leavingId] (D174): the most recently
/// selected of [mine] other than [leavingId], per [recentIds]; else the first
/// other one in [mine]'s join order; else null.
///
/// [recentIds] may hold stale ids -- households since left or deleted. They
/// match nothing in [mine] and are skipped (D169: never pruned).
HouseholdMembership? nextHouseholdAfter(
  String leavingId,
  List<HouseholdMembership> mine,
  List<String> recentIds,
) {
  for (final String id in recentIds) {
    if (id == leavingId) continue;
    for (final HouseholdMembership m in mine) {
      if (m.household.id == id) return m;
    }
  }
  for (final HouseholdMembership m in mine) {
    if (m.household.id != leavingId) return m;
  }
  return null;
}
