import 'package:freezed_annotation/freezed_annotation.dart';

part 'household.freezed.dart';
part 'household.g.dart';

/// A household -- the unit all recipe and planning data is scoped to.
///
/// [deletedAt] is carried into the domain deliberately. RLS returns
/// soft-deleted rows (D23) so the Phase 2 cache can evict them; repositories
/// filter for normal reads, but the field has to survive the boundary for the
/// sync path to ever use it.
@freezed
abstract class Household with _$Household {
  const factory Household({
    required String id,
    required String name,
    required String createdBy,
    DateTime? deletedAt,
  }) = _Household;

  factory Household.fromJson(Map<String, dynamic> json) =>
      _$HouseholdFromJson(json);
}
