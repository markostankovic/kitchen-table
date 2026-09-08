// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parsed_recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ParsedRecipe _$ParsedRecipeFromJson(Map<String, dynamic> json) =>
    _ParsedRecipe(
      cookMinutes: (json['cookMinutes'] as num?)?.toInt(),
      description: json['description'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>)
          .map((e) => ParsedIngredientLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      originalLocale: $enumDecode(
        _$ParsedLocaleEnumMap,
        json['originalLocale'],
      ),
      prepMinutes: (json['prepMinutes'] as num?)?.toInt(),
      servings: (json['servings'] as num?)?.toInt(),
      sourceAttribution: json['sourceAttribution'] as String?,
      sourceUrl: json['sourceUrl'] as String?,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => ParsedStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      title: json['title'] as String,
    );

Map<String, dynamic> _$ParsedRecipeToJson(_ParsedRecipe instance) =>
    <String, dynamic>{
      'cookMinutes': instance.cookMinutes,
      'description': instance.description,
      'ingredients': instance.ingredients,
      'originalLocale': _$ParsedLocaleEnumMap[instance.originalLocale]!,
      'prepMinutes': instance.prepMinutes,
      'servings': instance.servings,
      'sourceAttribution': instance.sourceAttribution,
      'sourceUrl': instance.sourceUrl,
      'steps': instance.steps,
      'title': instance.title,
    };

const _$ParsedLocaleEnumMap = {ParsedLocale.EN: 'en', ParsedLocale.SR: 'sr'};

_ParsedIngredientLine _$ParsedIngredientLineFromJson(
  Map<String, dynamic> json,
) => _ParsedIngredientLine(
  autoAccept: json['autoAccept'] as bool,
  displayName: json['displayName'] as String?,
  ingredientId: json['ingredientId'] as String?,
  isOptional: json['isOptional'] as bool,
  matchConfidence: (json['matchConfidence'] as num?)?.toDouble(),
  matchMethod: $enumDecodeNullable(
    _$ParsedMatchMethodEnumMap,
    json['matchMethod'],
  ),
  name: json['name'] as String?,
  note: json['note'] as String?,
  quantity: json['quantity'] == null
      ? null
      : ParsedQuantity.fromJson(json['quantity'] as Map<String, dynamic>),
  rawText: json['rawText'] as String,
  section: json['section'] as String?,
  unitCode: json['unitCode'] as String?,
);

Map<String, dynamic> _$ParsedIngredientLineToJson(
  _ParsedIngredientLine instance,
) => <String, dynamic>{
  'autoAccept': instance.autoAccept,
  'displayName': instance.displayName,
  'ingredientId': instance.ingredientId,
  'isOptional': instance.isOptional,
  'matchConfidence': instance.matchConfidence,
  'matchMethod': _$ParsedMatchMethodEnumMap[instance.matchMethod],
  'name': instance.name,
  'note': instance.note,
  'quantity': instance.quantity,
  'rawText': instance.rawText,
  'section': instance.section,
  'unitCode': instance.unitCode,
};

const _$ParsedMatchMethodEnumMap = {
  ParsedMatchMethod.ALIAS: 'alias',
  ParsedMatchMethod.EXACT: 'exact',
  ParsedMatchMethod.FUZZY: 'fuzzy',
  ParsedMatchMethod.LLM: 'llm',
};

_ParsedQuantity _$ParsedQuantityFromJson(Map<String, dynamic> json) =>
    _ParsedQuantity(
      den: (json['den'] as num).toInt(),
      maxDen: (json['maxDen'] as num?)?.toInt(),
      maxNum: (json['maxNum'] as num?)?.toInt(),
      num: (json['num'] as num).toInt(),
    );

Map<String, dynamic> _$ParsedQuantityToJson(_ParsedQuantity instance) =>
    <String, dynamic>{
      'den': instance.den,
      'maxDen': instance.maxDen,
      'maxNum': instance.maxNum,
      'num': instance.num,
    };

_ParsedStep _$ParsedStepFromJson(Map<String, dynamic> json) => _ParsedStep(
  text: json['text'] as String,
  timerSeconds: (json['timerSeconds'] as num?)?.toInt(),
);

Map<String, dynamic> _$ParsedStepToJson(_ParsedStep instance) =>
    <String, dynamic>{
      'text': instance.text,
      'timerSeconds': instance.timerSeconds,
    };
