// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Recipe _$RecipeFromJson(Map<String, dynamic> json) => _Recipe(
  id: json['id'] as String,
  householdId: json['householdId'] as String,
  title: json['title'] as String,
  originalLocale: json['originalLocale'] as String,
  sourceType: $enumDecode(_$RecipeSourceTypeEnumMap, json['sourceType']),
  status: $enumDecode(_$RecipeStatusEnumMap, json['status']),
  createdBy: json['createdBy'] as String,
  description: json['description'] as String?,
  servings: (json['servings'] as num?)?.toInt(),
  prepMinutes: (json['prepMinutes'] as num?)?.toInt(),
  cookMinutes: (json['cookMinutes'] as num?)?.toInt(),
  sourceUrl: json['sourceUrl'] as String?,
  sourceAttribution: json['sourceAttribution'] as String?,
  imagePath: json['imagePath'] as String?,
  imageUrl: json['imageUrl'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  deletedAt: json['deletedAt'] == null
      ? null
      : DateTime.parse(json['deletedAt'] as String),
);

Map<String, dynamic> _$RecipeToJson(_Recipe instance) => <String, dynamic>{
  'id': instance.id,
  'householdId': instance.householdId,
  'title': instance.title,
  'originalLocale': instance.originalLocale,
  'sourceType': _$RecipeSourceTypeEnumMap[instance.sourceType]!,
  'status': _$RecipeStatusEnumMap[instance.status]!,
  'createdBy': instance.createdBy,
  'description': instance.description,
  'servings': instance.servings,
  'prepMinutes': instance.prepMinutes,
  'cookMinutes': instance.cookMinutes,
  'sourceUrl': instance.sourceUrl,
  'sourceAttribution': instance.sourceAttribution,
  'imagePath': instance.imagePath,
  'imageUrl': instance.imageUrl,
  'tags': instance.tags,
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'deletedAt': instance.deletedAt?.toIso8601String(),
};

const _$RecipeSourceTypeEnumMap = {
  RecipeSourceType.manual: 'manual',
  RecipeSourceType.urlImport: 'urlImport',
  RecipeSourceType.ocr: 'ocr',
  RecipeSourceType.aiGenerated: 'aiGenerated',
};

const _$RecipeStatusEnumMap = {
  RecipeStatus.draft: 'draft',
  RecipeStatus.tested: 'tested',
};
