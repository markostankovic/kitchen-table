// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'translation_review_draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TranslationReviewDraft _$TranslationReviewDraftFromJson(
  Map<String, dynamic> json,
) => _TranslationReviewDraft(
  locale: json['locale'] as String,
  sourceLocale: json['sourceLocale'] as String,
  sourceTitle: json['sourceTitle'] as String,
  sourceDescription: json['sourceDescription'] as String?,
  sourceNotes: json['sourceNotes'] as String?,
  sourceSteps:
      (json['sourceSteps'] as List<dynamic>?)
          ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <RecipeStep>[],
  title: json['title'] as String,
  description: json['description'] as String?,
  notes: json['notes'] as String?,
  steps:
      (json['steps'] as List<dynamic>?)
          ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <RecipeStep>[],
);

Map<String, dynamic> _$TranslationReviewDraftToJson(
  _TranslationReviewDraft instance,
) => <String, dynamic>{
  'locale': instance.locale,
  'sourceLocale': instance.sourceLocale,
  'sourceTitle': instance.sourceTitle,
  'sourceDescription': instance.sourceDescription,
  'sourceNotes': instance.sourceNotes,
  'sourceSteps': instance.sourceSteps,
  'title': instance.title,
  'description': instance.description,
  'notes': instance.notes,
  'steps': instance.steps,
};
