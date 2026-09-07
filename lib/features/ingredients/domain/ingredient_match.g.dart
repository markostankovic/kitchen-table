// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient_match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IngredientMatch _$IngredientMatchFromJson(Map<String, dynamic> json) =>
    _IngredientMatch(
      ingredientId: json['ingredientId'] as String,
      displayName: json['displayName'] as String,
      matchedName: json['matchedName'] as String,
      matchedLocale: json['matchedLocale'] as String,
      matchMethod: $enumDecode(_$MatchMethodEnumMap, json['matchMethod']),
      confidence: (json['confidence'] as num).toDouble(),
      autoAccept: json['autoAccept'] as bool,
      isVerified: json['isVerified'] as bool? ?? false,
      isHouseholdAlias: json['isHouseholdAlias'] as bool? ?? false,
    );

Map<String, dynamic> _$IngredientMatchToJson(_IngredientMatch instance) =>
    <String, dynamic>{
      'ingredientId': instance.ingredientId,
      'displayName': instance.displayName,
      'matchedName': instance.matchedName,
      'matchedLocale': instance.matchedLocale,
      'matchMethod': _$MatchMethodEnumMap[instance.matchMethod]!,
      'confidence': instance.confidence,
      'autoAccept': instance.autoAccept,
      'isVerified': instance.isVerified,
      'isHouseholdAlias': instance.isHouseholdAlias,
    };

const _$MatchMethodEnumMap = {
  MatchMethod.exact: 'exact',
  MatchMethod.alias: 'alias',
  MatchMethod.fuzzy: 'fuzzy',
  MatchMethod.llm: 'llm',
  MatchMethod.manual: 'manual',
};
