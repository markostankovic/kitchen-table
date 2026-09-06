// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HouseholdMember _$HouseholdMemberFromJson(Map<String, dynamic> json) =>
    _HouseholdMember(
      householdId: json['householdId'] as String,
      userId: json['userId'] as String,
      role: $enumDecode(_$HouseholdRoleEnumMap, json['role']),
    );

Map<String, dynamic> _$HouseholdMemberToJson(_HouseholdMember instance) =>
    <String, dynamic>{
      'householdId': instance.householdId,
      'userId': instance.userId,
      'role': _$HouseholdRoleEnumMap[instance.role]!,
    };

const _$HouseholdRoleEnumMap = {
  HouseholdRole.owner: 'owner',
  HouseholdRole.adult: 'adult',
};
