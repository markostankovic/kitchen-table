import 'package:freezed_annotation/freezed_annotation.dart';

import 'recipe.dart';
import 'recipe_ingredient.dart';
import 'recipe_step.dart';
import 'recipe_translation.dart';

part 'recipe_detail.freezed.dart';
part 'recipe_detail.g.dart';

/// A recipe with its lines and steps.
///
/// One aggregate rather than three providers, so the detail screen has one
/// `AsyncValue` to handle instead of three that can each be in a different
/// state -- and so a half-loaded recipe is not a state the UI has to render.
///
/// [readingLocale] and [translations] are Phase 3 part 2's addition. Every
/// getter below is one definition of "which words does this reader see" --
/// [RecipeIngredient.resolvedName]'s pattern one level up -- so the AppBar,
/// the body and any later screen cannot disagree about which locale is on
/// screen. They fall back to the original whenever there is no translation
/// for [readingLocale], which includes the ordinary case of reading a recipe
/// in its own original language.
///
/// Pure Dart (rule 7).
@freezed
abstract class RecipeDetail with _$RecipeDetail {
  const RecipeDetail._();

  const factory RecipeDetail({
    required Recipe recipe,
    required String readingLocale,
    @Default(<RecipeIngredient>[]) List<RecipeIngredient> ingredients,
    @Default(<RecipeStep>[]) List<RecipeStep> steps,
    @Default(<RecipeTranslation>[]) List<RecipeTranslation> translations,
  }) = _RecipeDetail;

  factory RecipeDetail.fromJson(Map<String, dynamic> json) =>
      _$RecipeDetailFromJson(json);

  /// The translation for [readingLocale], or null when there is none -- the
  /// ordinary case for a recipe read in its own original language, and also
  /// the case before anyone has translated it into the other one.
  RecipeTranslation? get translation => translations
      .cast<RecipeTranslation?>()
      .firstWhere((t) => t?.locale == readingLocale, orElse: () => null);

  /// True when [readingLocale] differs from the recipe's own
  /// [Recipe.originalLocale] and no translation has been made yet -- the
  /// enabled condition for the detail screen's *Translate* action.
  bool get canTranslate =>
      readingLocale != recipe.originalLocale && translation == null;

  /// True when the title, description and steps on screen came from a
  /// machine translation rather than the recipe's own original text.
  bool get isShowingMachineTranslation =>
      translation != null && translation!.isMachineGenerated;

  String get displayTitle => translation?.title ?? recipe.title;

  String? get displayDescription => translation != null
      ? translation!.description
      : recipe.description;

  /// [steps] in [readingLocale] when a translation exists, [steps]
  /// (the original) otherwise. A translation's own step list is never
  /// missing a position relative to the original -- `save_recipe_translation`
  /// and `translate-recipe`'s `alignSteps` both refuse to save one that is --
  /// so this can return it directly rather than merging by position.
  List<RecipeStep> get displaySteps => translation?.steps ?? steps;
}
