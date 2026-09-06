import 'package:freezed_annotation/freezed_annotation.dart';

part 'household_member.freezed.dart';
part 'household_member.g.dart';

/// Roles a member can hold. Matches the `role` check constraint.
enum HouseholdRole { owner, adult }

/// Someone's membership of a household.
///
/// No `deletedAt`: this is a child join table, so removal is a hard delete
/// (D24).
@freezed
abstract class HouseholdMember with _$HouseholdMember {
  const factory HouseholdMember({
    required String householdId,
    required String userId,
    required HouseholdRole role,
  }) = _HouseholdMember;

  factory HouseholdMember.fromJson(Map<String, dynamic> json) =>
      _$HouseholdMemberFromJson(json);
}
