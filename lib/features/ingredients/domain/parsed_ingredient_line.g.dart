// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parsed_ingredient_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ParsedIngredientLine _$ParsedIngredientLineFromJson(
  Map<String, dynamic> json,
) => _ParsedIngredientLine(
  rawText: json['rawText'] as String,
  quantity: json['quantity'] == null
      ? null
      : Quantity.fromJson(json['quantity'] as Map<String, dynamic>),
  unitCode: json['unitCode'] as String?,
  name: json['name'] as String?,
  note: json['note'] as String?,
  isOptional: json['isOptional'] as bool? ?? false,
);

Map<String, dynamic> _$ParsedIngredientLineToJson(
  _ParsedIngredientLine instance,
) => <String, dynamic>{
  'rawText': instance.rawText,
  'quantity': instance.quantity,
  'unitCode': instance.unitCode,
  'name': instance.name,
  'note': instance.note,
  'isOptional': instance.isOptional,
};
