import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_step.freezed.dart';
part 'recipe_step.g.dart';

/// What a row of a recipe's method is (D153): an instruction, a section
/// heading inside the method ("Za testo"), or an aside between steps.
enum RecipeStepKind {
  step,
  heading,
  note;

  /// The `recipe_steps.kind` column's value. Null is [step]: an
  /// `import_jobs.result` or a cached row written before the column existed
  /// has no kind, and every such row was an instruction. An unknown string
  /// throws -- the column's check constraint makes it unreachable from the
  /// database.
  static RecipeStepKind fromWire(String? wire) => wire == null
      ? RecipeStepKind.step
      : RecipeStepKind.values.byName(wire);
}

/// One row of a recipe's method, in the recipe's original language.
///
/// [position] is shared across kinds: a heading or a note takes a position
/// like any step, which is what lets a translation align to it (D80, D153).
/// Numbering only the [RecipeStepKind.step] rows is a render concern.
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

    @Default(RecipeStepKind.step) RecipeStepKind kind,
  }) = _RecipeStep;

  factory RecipeStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeStepFromJson(json);
}
