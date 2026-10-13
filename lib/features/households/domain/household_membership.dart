import 'package:freezed_annotation/freezed_annotation.dart';

import 'household.dart';
import 'household_member.dart';

part 'household_membership.freezed.dart';

/// One household the caller belongs to, with the caller's own role in it and
/// how many people it has -- one row of the Households list.
///
/// No `fromJson`: the wire is decoded in `data/dto/household_dto.dart`'s
/// `membershipFromWire`, on `householdFromWire`'s precedent.
@freezed
abstract class HouseholdMembership with _$HouseholdMembership {
  const factory HouseholdMembership({
    required Household household,
    required HouseholdRole role,
    required int memberCount,
  }) = _HouseholdMembership;
}
