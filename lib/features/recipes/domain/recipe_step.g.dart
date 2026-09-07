// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipeStep _$RecipeStepFromJson(Map<String, dynamic> json) => _RecipeStep(
  position: (json['position'] as num).toInt(),
  text: json['text'] as String,
  timerSeconds: (json['timerSeconds'] as num?)?.toInt(),
  id: json['id'] as String?,
);

Map<String, dynamic> _$RecipeStepToJson(_RecipeStep instance) =>
    <String, dynamic>{
      'position': instance.position,
      'text': instance.text,
      'timerSeconds': instance.timerSeconds,
      'id': instance.id,
    };
