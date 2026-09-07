// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_ingredient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeIngredient _$RecipeIngredientFromJson(Map<String, dynamic> json) =>
    _RecipeIngredient(
      position: (json['position'] as num).toInt(),
      rawText: json['rawText'] as String,
      id: json['id'] as String?,
      section: json['section'] as String?,
      ingredientId: json['ingredientId'] as String?,
      displayName: json['displayName'] as String?,
      quantity: json['quantity'] == null
          ? null
          : Quantity.fromJson(json['quantity'] as Map<String, dynamic>),
      unitCode: json['unitCode'] as String?,
      note: json['note'] as String?,
      isOptional: json['isOptional'] as bool? ?? false,
      matchMethod: $enumDecodeNullable(
        _$MatchMethodEnumMap,
        json['matchMethod'],
      ),
      matchConfidence: (json['matchConfidence'] as num?)?.toDouble(),
      matchedAt: json['matchedAt'] == null
          ? null
          : DateTime.parse(json['matchedAt'] as String),
    );

Map<String, dynamic> _$RecipeIngredientToJson(_RecipeIngredient instance) =>
    <String, dynamic>{
      'position': instance.position,
      'rawText': instance.rawText,
      'id': instance.id,
      'section': instance.section,
      'ingredientId': instance.ingredientId,
      'displayName': instance.displayName,
      'quantity': instance.quantity,
      'unitCode': instance.unitCode,
      'note': instance.note,
      'isOptional': instance.isOptional,
      'matchMethod': _$MatchMethodEnumMap[instance.matchMethod],
      'matchConfidence': instance.matchConfidence,
      'matchedAt': instance.matchedAt?.toIso8601String(),
    };

const _$MatchMethodEnumMap = {
  MatchMethod.exact: 'exact',
  MatchMethod.alias: 'alias',
  MatchMethod.fuzzy: 'fuzzy',
  MatchMethod.llm: 'llm',
  MatchMethod.manual: 'manual',
};
