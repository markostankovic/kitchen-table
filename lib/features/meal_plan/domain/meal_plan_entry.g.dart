// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MealPlanEntry _$MealPlanEntryFromJson(Map<String, dynamic> json) =>
    _MealPlanEntry(
      id: json['id'] as String,
      mealPlanId: json['mealPlanId'] as String,
      entryDate: DateTime.parse(json['entryDate'] as String),
      slot: $enumDecode(_$MealSlotEnumMap, json['slot']),
      position: (json['position'] as num).toInt(),
      entryKind: $enumDecode(_$MealEntryKindEnumMap, json['entryKind']),
      recipeId: json['recipeId'] as String?,
      leftoverOfEntryId: json['leftoverOfEntryId'] as String?,
      note: json['note'] as String?,
      servings: (json['servings'] as num?)?.toInt(),
      recipeTitle: json['recipeTitle'] as String?,
      recipeServings: (json['recipeServings'] as num?)?.toInt(),
    );

Map<String, dynamic> _$MealPlanEntryToJson(_MealPlanEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mealPlanId': instance.mealPlanId,
      'entryDate': instance.entryDate.toIso8601String(),
      'slot': _$MealSlotEnumMap[instance.slot]!,
      'position': instance.position,
      'entryKind': _$MealEntryKindEnumMap[instance.entryKind]!,
      'recipeId': instance.recipeId,
      'leftoverOfEntryId': instance.leftoverOfEntryId,
      'note': instance.note,
      'servings': instance.servings,
      'recipeTitle': instance.recipeTitle,
      'recipeServings': instance.recipeServings,
    };

const _$MealSlotEnumMap = {
  MealSlot.breakfast: 'breakfast',
  MealSlot.lunch: 'lunch',
  MealSlot.dinner: 'dinner',
  MealSlot.snack: 'snack',
};

const _$MealEntryKindEnumMap = {
  MealEntryKind.recipe: 'recipe',
  MealEntryKind.leftover: 'leftover',
  MealEntryKind.note: 'note',
};
