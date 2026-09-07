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

    /// The member's name, from the embedded `profiles` row rather than from
    /// `household_members` itself.
    ///
    /// Null means `profiles_select_co_member` did not return the profile.
    /// Render that visibly rather than dropping the member, so a policy
    /// regression is noticed instead of silently hiding somebody.
    String? displayName,
  }) = _HouseholdMember;

  factory HouseholdMember.fromJson(Map<String, dynamic> json) =>
      _$HouseholdMemberFromJson(json);
}
