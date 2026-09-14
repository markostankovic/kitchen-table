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

Household householdFromWire(Map<String, dynamic> row) {
  final String? deletedAt = row['deleted_at'] as String?;
  return Household(
    id: row['id'] as String,
    name: row['name'] as String,
    createdBy: row['created_by'] as String,
    deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt),
  );
}
