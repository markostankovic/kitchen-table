import 'package:freezed_annotation/freezed_annotation.dart';

part 'household_invite.freezed.dart';
part 'household_invite.g.dart';

/// A six-digit code that admits one person to a household.
///
/// No `deletedAt` and no `updatedAt` (D25). An invite is append-only: created
/// once, stamped dead once, and `usedAt` is its lifecycle column.
///
/// No `token` either. The column exists so Phase 4's public invite links do
/// not need a migration, but nothing reads it yet and the Edge Functions
/// deliberately never return it.
@freezed
abstract class HouseholdInvite with _$HouseholdInvite {
  const factory HouseholdInvite({
    required String id,
    required String householdId,
    required String code,
    required String createdBy,
    required DateTime createdAt,
    required DateTime expiresAt,
    String? usedBy,
    DateTime? usedAt,
  }) = _HouseholdInvite;

  factory HouseholdInvite.fromJson(Map<String, dynamic> json) =>
      _$HouseholdInviteFromJson(json);
}
