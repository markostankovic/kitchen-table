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
  kind:
      $enumDecodeNullable(_$RecipeStepKindEnumMap, json['kind']) ??
      RecipeStepKind.step,
);

Map<String, dynamic> _$RecipeStepToJson(_RecipeStep instance) =>
    <String, dynamic>{
      'position': instance.position,
      'text': instance.text,
      'timerSeconds': instance.timerSeconds,
      'id': instance.id,
      'kind': _$RecipeStepKindEnumMap[instance.kind]!,
    };

const _$RecipeStepKindEnumMap = {
  RecipeStepKind.step: 'step',
  RecipeStepKind.heading: 'heading',
  RecipeStepKind.note: 'note',
};
