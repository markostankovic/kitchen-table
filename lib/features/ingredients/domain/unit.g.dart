// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Unit _$UnitFromJson(Map<String, dynamic> json) => _Unit(
  code: json['code'] as String,
  family: $enumDecode(_$UnitFamilyEnumMap, json['family']),
  toBase: (json['toBase'] as num).toDouble(),
  isMetric: json['isMetric'] as bool? ?? false,
);

Map<String, dynamic> _$UnitToJson(_Unit instance) => <String, dynamic>{
  'code': instance.code,
  'family': _$UnitFamilyEnumMap[instance.family]!,
  'toBase': instance.toBase,
  'isMetric': instance.isMetric,
};

const _$UnitFamilyEnumMap = {
  UnitFamily.mass: 'mass',
  UnitFamily.volume: 'volume',
  UnitFamily.count: 'count',
  UnitFamily.other: 'other',
};
