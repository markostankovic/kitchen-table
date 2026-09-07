import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_step.freezed.dart';
part 'recipe_step.g.dart';

/// One preparation step, in the recipe's original language.
///
/// Pure Dart (rule 7).
@freezed
abstract class RecipeStep with _$RecipeStep {
  const factory RecipeStep({
    required int position,
    required String text,

    /// Set where a step names a duration worth counting down. Nothing in Phase
    /// 1c reads it; the column is cheap and retrofitting it onto entered
    /// recipes would not be.
    int? timerSeconds,

    /// Null for a step that has not been saved yet.
    String? id,
  }) = _RecipeStep;

  factory RecipeStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeStepFromJson(json);
}
