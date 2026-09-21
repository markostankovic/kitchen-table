import 'package:freezed_annotation/freezed_annotation.dart';

import 'recipe_step.dart';

part 'recipe_translation.freezed.dart';
part 'recipe_translation.g.dart';

/// One locale of a recipe other than its original (Phase 3, part 2).
///
/// `recipes` holds the original-language title, description and steps;
/// every other locale lives here, one row per `(recipeId, locale)`. There is
/// deliberately no `recipeId` field -- a translation always arrives already
/// scoped to the recipe that fetched it (embedded on the same wire row), the
/// same reasoning [RecipeStep] gives for carrying no `recipeId` of its own.
///
/// [isMachineGenerated] and [reviewedBy] exist for a later part (D78): they
/// are read here, but nothing in this part writes [reviewedBy] -- that is
/// part 3's review flow, on `recipes.imagePath`'s own precedent of a field
/// that ships ahead of its writer (D35, D51).
///
/// Pure Dart (rule 7).
@freezed
abstract class RecipeTranslation with _$RecipeTranslation {
  const factory RecipeTranslation({
    required String locale,
    required String title,
    String? description,
    @Default(<RecipeStep>[]) List<RecipeStep> steps,
    @Default(true) bool isMachineGenerated,
    String? reviewedBy,
    DateTime? reviewedAt,
  }) = _RecipeTranslation;

  factory RecipeTranslation.fromJson(Map<String, dynamic> json) =>
      _$RecipeTranslationFromJson(json);
}

/// 'sr' and 'en' are the only two (CLAUDE.md), so the other one is a flip.
String otherLocale(String locale) => locale == 'sr' ? 'en' : 'sr';

/// The one definition of "may this recipe be translated into [target]".
/// D85: once ANY translation exists for a locale -- reviewed or not -- it is
/// never offered again, and this is the only thing enforcing that.
bool canTranslateInto({
  required String originalLocale,
  required String target,
  required Iterable<String> existingLocales,
}) =>
    target != originalLocale && !existingLocales.contains(target);
