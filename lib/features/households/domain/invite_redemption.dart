import 'package:freezed_annotation/freezed_annotation.dart';

part 'invite_redemption.freezed.dart';

/// What redeeming an invite code came to: the household behind it, and
/// whether the caller was already a member (`redeem-invite` answers 200 for
/// that too, not an error).
///
/// No `fromJson`: built in `data/` from the function's reply.
@freezed
abstract class InviteRedemption with _$InviteRedemption {
  const factory InviteRedemption({
    required String householdId,
    required String householdName,
    required bool alreadyMember,
  }) = _InviteRedemption;
}
