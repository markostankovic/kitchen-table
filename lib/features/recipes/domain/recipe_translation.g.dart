// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_translation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeTranslation _$RecipeTranslationFromJson(Map<String, dynamic> json) =>
    _RecipeTranslation(
      locale: json['locale'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RecipeStep>[],
      isMachineGenerated: json['isMachineGenerated'] as bool? ?? true,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
    );

Map<String, dynamic> _$RecipeTranslationToJson(_RecipeTranslation instance) =>
    <String, dynamic>{
      'locale': instance.locale,
      'title': instance.title,
      'description': instance.description,
      'steps': instance.steps,
      'isMachineGenerated': instance.isMachineGenerated,
      'reviewedBy': instance.reviewedBy,
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
    };
