// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quantity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Quantity _$QuantityFromJson(Map<String, dynamic> json) => _Quantity(
  numerator: (json['numerator'] as num).toInt(),
  denominator: (json['denominator'] as num).toInt(),
  maxNumerator: (json['maxNumerator'] as num?)?.toInt(),
  maxDenominator: (json['maxDenominator'] as num?)?.toInt(),
);

Map<String, dynamic> _$QuantityToJson(_Quantity instance) => <String, dynamic>{
  'numerator': instance.numerator,
  'denominator': instance.denominator,
  'maxNumerator': instance.maxNumerator,
  'maxDenominator': instance.maxDenominator,
};
