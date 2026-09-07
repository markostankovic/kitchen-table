import 'package:freezed_annotation/freezed_annotation.dart';

import 'recipe.dart';
import 'recipe_ingredient.dart';
import 'recipe_step.dart';

part 'recipe_detail.freezed.dart';
part 'recipe_detail.g.dart';

/// A recipe with its lines and steps.
///
/// One aggregate rather than three providers, so the detail screen has one
/// `AsyncValue` to handle instead of three that can each be in a different
/// state -- and so a half-loaded recipe is not a state the UI has to render.
///
/// Pure Dart (rule 7).
@freezed
abstract class RecipeDetail with _$RecipeDetail {
  const factory RecipeDetail({
    required Recipe recipe,
    @Default(<RecipeIngredient>[]) List<RecipeIngredient> ingredients,
    @Default(<RecipeStep>[]) List<RecipeStep> steps,
  }) = _RecipeDetail;

  factory RecipeDetail.fromJson(Map<String, dynamic> json) =>
      _$RecipeDetailFromJson(json);
}
