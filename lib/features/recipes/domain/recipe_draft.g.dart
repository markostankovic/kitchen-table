// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeDraft _$RecipeDraftFromJson(Map<String, dynamic> json) => _RecipeDraft(
  source: json['source'] == null
      ? null
      : Recipe.fromJson(json['source'] as Map<String, dynamic>),
  title: json['title'] as String? ?? '',
  description: json['description'] as String?,
  servings: (json['servings'] as num?)?.toInt(),
  prepMinutes: (json['prepMinutes'] as num?)?.toInt(),
  cookMinutes: (json['cookMinutes'] as num?)?.toInt(),
  originalLocale: json['originalLocale'] as String? ?? 'sr',
  status:
      $enumDecodeNullable(_$RecipeStatusEnumMap, json['status']) ??
      RecipeStatus.draft,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  imagePath: json['imagePath'] as String?,
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => RecipeDraftLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <RecipeDraftLine>[],
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => RecipeDraftStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <RecipeDraftStep>[],
);

Map<String, dynamic> _$RecipeDraftToJson(_RecipeDraft instance) =>
    <String, dynamic>{
      'source': instance.source,
      'title': instance.title,
      'description': instance.description,
      'servings': instance.servings,
      'prepMinutes': instance.prepMinutes,
      'cookMinutes': instance.cookMinutes,
      'originalLocale': instance.originalLocale,
      'status': _$RecipeStatusEnumMap[instance.status]!,
      'tags': instance.tags,
      'imagePath': instance.imagePath,
      'lines': instance.lines,
      'steps': instance.steps,
    };

const _$RecipeStatusEnumMap = {
  RecipeStatus.draft: 'draft',
  RecipeStatus.tested: 'tested',
};

_RecipeDraftLine _$RecipeDraftLineFromJson(Map<String, dynamic> json) =>
    _RecipeDraftLine(
      localId: (json['localId'] as num).toInt(),
      rawText: json['rawText'] as String,
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

Map<String, dynamic> _$RecipeDraftLineToJson(_RecipeDraftLine instance) =>
    <String, dynamic>{
      'localId': instance.localId,
      'rawText': instance.rawText,
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

_RecipeDraftStep _$RecipeDraftStepFromJson(Map<String, dynamic> json) =>
    _RecipeDraftStep(
      localId: (json['localId'] as num).toInt(),
      text: json['text'] as String,
      timerSeconds: (json['timerSeconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RecipeDraftStepToJson(_RecipeDraftStep instance) =>
    <String, dynamic>{
      'localId': instance.localId,
      'text': instance.text,
      'timerSeconds': instance.timerSeconds,
    };
