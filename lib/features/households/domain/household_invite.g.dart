// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_invite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HouseholdInvite _$HouseholdInviteFromJson(Map<String, dynamic> json) =>
    _HouseholdInvite(
      id: json['id'] as String,
      householdId: json['householdId'] as String,
      code: json['code'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      usedBy: json['usedBy'] as String?,
      usedAt: json['usedAt'] == null
          ? null
          : DateTime.parse(json['usedAt'] as String),
    );

Map<String, dynamic> _$HouseholdInviteToJson(_HouseholdInvite instance) =>
    <String, dynamic>{
      'id': instance.id,
      'householdId': instance.householdId,
      'code': instance.code,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'usedBy': instance.usedBy,
      'usedAt': instance.usedAt?.toIso8601String(),
    };
