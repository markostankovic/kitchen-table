// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Ingredient _$IngredientFromJson(Map<String, dynamic> json) => _Ingredient(
  id: json['id'] as String,
  key: json['key'] as String?,
  parentId: json['parentId'] as String?,
  category: json['category'] as String?,
  defaultUnitFamily: $enumDecodeNullable(
    _$UnitFamilyEnumMap,
    json['defaultUnitFamily'],
  ),
  isVerified: json['isVerified'] as bool? ?? false,
  isPantryStaple: json['isPantryStaple'] as bool? ?? false,
);

Map<String, dynamic> _$IngredientToJson(_Ingredient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'parentId': instance.parentId,
      'category': instance.category,
      'defaultUnitFamily': _$UnitFamilyEnumMap[instance.defaultUnitFamily],
      'isVerified': instance.isVerified,
      'isPantryStaple': instance.isPantryStaple,
    };

const _$UnitFamilyEnumMap = {
  UnitFamily.mass: 'mass',
  UnitFamily.volume: 'volume',
  UnitFamily.count: 'count',
  UnitFamily.other: 'other',
};
