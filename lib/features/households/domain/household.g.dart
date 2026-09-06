// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Household _$HouseholdFromJson(Map<String, dynamic> json) => _Household(
  id: json['id'] as String,
  name: json['name'] as String,
  createdBy: json['createdBy'] as String,
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
);

Map<String, dynamic> _$HouseholdToJson(_Household instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdBy': instance.createdBy,
      'deletedAt': instance.deletedAt?.toIso8601String(),
    };
