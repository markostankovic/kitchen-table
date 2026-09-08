import 'package:freezed_annotation/freezed_annotation.dart';

import '../../ingredients/domain/ingredient_match.dart';
import '../../ingredients/domain/quantity.dart';
import 'recipe.dart';
import 'recipe_detail.dart';
import 'recipe_ingredient.dart';
import 'recipe_step.dart';

part 'recipe_draft.freezed.dart';
part 'recipe_draft.g.dart';

/// A recipe being edited.
///
/// This is the editor's whole state, and every mutation on it is a pure
/// function returning a new draft. The notifier in `application/` does nothing
/// but assign the result, which is what lets the interesting behaviour --
/// blank lines dropped, positions renumbered after a reorder, a human match
/// decision surviving an unrelated edit -- be tested without a Supabase client
/// or a widget tree.
///
/// In memory only. D12 rejects offline writes outright, so there is no
/// persisted draft store and there must not be one.
///
/// Pure Dart (rule 7).
@freezed
abstract class RecipeDraft with _$RecipeDraft {
  const RecipeDraft._();

  const factory RecipeDraft({
    /// The recipe as last read from or written to the server, or null for a
    /// recipe that has never been saved.
    ///
    /// This carries the fields the editor does not own -- `householdId`,
    /// `createdBy`, `sourceType` -- so [toRecipe] can build a complete row
    /// without the screen having to know they exist. It is also how a second
    /// save knows to update rather than create (D37).
    Recipe? source,
    @Default('') String title,
    String? description,
    int? servings,
    int? prepMinutes,
    int? cookMinutes,
    @Default('sr') String originalLocale,
    @Default(RecipeStatus.draft) RecipeStatus status,
    @Default(<String>[]) List<String> tags,
    @Default(<RecipeDraftLine>[]) List<RecipeDraftLine> lines,
    @Default(<RecipeDraftStep>[]) List<RecipeDraftStep> steps,
  }) = _RecipeDraft;

  factory RecipeDraft.fromJson(Map<String, dynamic> json) =>
      _$RecipeDraftFromJson(json);

  /// A blank recipe, with one empty line and one empty step so the editor
  /// opens showing where to type rather than showing nothing.
  factory RecipeDraft.empty() => const RecipeDraft(
        lines: <RecipeDraftLine>[RecipeDraftLine(localId: 0, rawText: '')],
        steps: <RecipeDraftStep>[RecipeDraftStep(localId: 0, text: '')],
      );

  /// An existing recipe, opened for editing.
  factory RecipeDraft.fromDetail(RecipeDetail detail) {
    final Recipe recipe = detail.recipe;
    return RecipeDraft(
      source: recipe,
      title: recipe.title,
      description: recipe.description,
      servings: recipe.servings,
      prepMinutes: recipe.prepMinutes,
      cookMinutes: recipe.cookMinutes,
      originalLocale: recipe.originalLocale,
      status: recipe.status,
      tags: recipe.tags,
      lines: <RecipeDraftLine>[
        for (final (int index, RecipeIngredient line)
            in detail.ingredients.indexed)
          RecipeDraftLine.fromIngredient(line, localId: index),
      ],
      steps: <RecipeDraftStep>[
        for (final (int index, RecipeStep step) in detail.steps.indexed)
          RecipeDraftStep(
            localId: index,
            text: step.text,
            timerSeconds: step.timerSeconds,
          ),
      ],
    );
  }

  /// Null until the first successful save.
  String? get recipeId => source?.id;

  /// Whether there is anything worth saving. The title carries it: the table
  /// requires a non-blank one, and a recipe with a title and no lines is a
  /// legitimate half-entered recipe.
  bool get hasTitle => title.trim().isNotEmpty;

  /// The lines as they will be written.
  ///
  /// Blank lines are dropped rather than rejected: an editor that always keeps
  /// a spare empty field at the bottom would otherwise be unable to save.
  /// `recipe_ingredients.raw_text` carries a `length(trim(raw_text)) > 0`
  /// check, so sending one would fail the whole transaction.
  ///
  /// `position` is assigned from list order here for the sake of the domain
  /// model being complete; `replace_recipe_lines` derives it from array order
  /// again on the server and ignores what is sent (D36).
  List<RecipeIngredient> toIngredients() {
    final List<RecipeIngredient> kept = <RecipeIngredient>[];
    for (final RecipeDraftLine line in lines) {
      if (line.rawText.trim().isEmpty) continue;
      kept.add(line.toIngredient(position: kept.length));
    }
    return kept;
  }

  /// The steps as they will be written. Blank steps are dropped, for the same
  /// reason and against the same check constraint.
  List<RecipeStep> toSteps() {
    final List<RecipeStep> kept = <RecipeStep>[];
    for (final RecipeDraftStep step in steps) {
      if (step.text.trim().isEmpty) continue;
      kept.add(RecipeStep(
        position: kept.length,
        text: step.text.trim(),
        timerSeconds: step.timerSeconds,
      ));
    }
    return kept;
  }

  /// The editable fields folded back onto [source], for an update.
  ///
  /// Throws if there is no source: a draft that has never been saved has no
  /// `householdId` or `createdBy` to preserve, and must go through
  /// `RecipeRepository.create` instead.
  Recipe toRecipe() {
    final Recipe? current = source;
    if (current == null) {
      throw StateError('toRecipe() on a draft that has never been saved');
    }
    return current.copyWith(
      title: title.trim(),
      description: description,
      servings: servings,
      prepMinutes: prepMinutes,
      cookMinutes: cookMinutes,
      originalLocale: originalLocale,
      status: status,
      tags: tags,
    );
  }

  // ---------------------------------------------------------------------
  // Line and step mutation, all pure
  // ---------------------------------------------------------------------

  RecipeDraft addLine() => copyWith(
        lines: <RecipeDraftLine>[
          ...lines,
          RecipeDraftLine(localId: _nextLineId, rawText: ''),
        ],
      );

  RecipeDraft removeLine(int localId) => copyWith(
        lines: lines
            .where((RecipeDraftLine line) => line.localId != localId)
            .toList(growable: false),
      );

  RecipeDraft setLineText(int localId, String rawText) => copyWith(
        lines: lines
            .map((RecipeDraftLine line) => line.localId == localId
                ? line.copyWith(rawText: rawText)
                : line)
            .toList(growable: false),
      );

  /// Replaces one line wholesale. The line editor uses this to write a parse
  /// result and a match decision together, so a keystroke never lands as two
  /// separate states.
  RecipeDraft replaceLine(RecipeDraftLine replacement) => copyWith(
        lines: lines
            .map((RecipeDraftLine line) =>
                line.localId == replacement.localId ? replacement : line)
            .toList(growable: false),
      );

  RecipeDraft reorderLines(int oldIndex, int newIndex) => copyWith(
        lines: _reordered<RecipeDraftLine>(lines, oldIndex, newIndex),
      );

  RecipeDraft addStep() => copyWith(
        steps: <RecipeDraftStep>[
          ...steps,
          RecipeDraftStep(localId: _nextStepId, text: ''),
        ],
      );

  RecipeDraft removeStep(int localId) => copyWith(
        steps: steps
            .where((RecipeDraftStep step) => step.localId != localId)
            .toList(growable: false),
      );

  RecipeDraft setStepText(int localId, String text) => copyWith(
        steps: steps
            .map((RecipeDraftStep step) =>
                step.localId == localId ? step.copyWith(text: text) : step)
            .toList(growable: false),
      );

  RecipeDraft reorderSteps(int oldIndex, int newIndex) => copyWith(
        steps: _reordered<RecipeDraftStep>(steps, oldIndex, newIndex),
      );

  /// Local ids are allocated above the current high-water mark rather than
  /// from the list length, so removing a line and adding one cannot hand out
  /// an id that a still-live widget is keyed on.
  int get _nextLineId => lines.isEmpty
      ? 0
      : lines
              .map((RecipeDraftLine line) => line.localId)
              .reduce((int a, int b) => a > b ? a : b) +
          1;

  int get _nextStepId => steps.isEmpty
      ? 0
      : steps
              .map((RecipeDraftStep step) => step.localId)
              .reduce((int a, int b) => a > b ? a : b) +
          1;

  /// Indices as `ReorderableListView.onReorderItem` delivers them: [newIndex]
  /// is already adjusted for the dragged child being lifted out, so this is a
  /// plain remove-and-insert. The older `onReorder` callback did not adjust it
  /// and is deprecated; do not reintroduce an off-by-one here to suit it.
  static List<T> _reordered<T>(List<T> items, int oldIndex, int newIndex) {
    final List<T> next = List<T>.of(items);
    next.insert(newIndex, next.removeAt(oldIndex));
    return List<T>.unmodifiable(next);
  }
}

/// One ingredient line being edited.
///
/// [rawText] is the authored field and everything else is an enhancement on
/// top of it (rule 3), exactly as on [RecipeIngredient]. The difference is
/// [localId]: a `ReorderableListView` needs a stable key per child, and two
/// blank freezed lines compare equal, so identity cannot come from the value.
@freezed
abstract class RecipeDraftLine with _$RecipeDraftLine {
  const RecipeDraftLine._();

  const factory RecipeDraftLine({
    required int localId,
    required String rawText,
    String? section,
    String? ingredientId,
    String? displayName,
    Quantity? quantity,
    String? unitCode,
    String? note,
    @Default(false) bool isOptional,
    MatchMethod? matchMethod,
    double? matchConfidence,
    DateTime? matchedAt,
  }) = _RecipeDraftLine;

  factory RecipeDraftLine.fromJson(Map<String, dynamic> json) =>
      _$RecipeDraftLineFromJson(json);

  factory RecipeDraftLine.fromIngredient(
    RecipeIngredient line, {
    required int localId,
  }) =>
      RecipeDraftLine(
        localId: localId,
        rawText: line.rawText,
        section: line.section,
        ingredientId: line.ingredientId,
        displayName: line.displayName,
        quantity: line.quantity,
        unitCode: line.unitCode,
        note: line.note,
        isOptional: line.isOptional,
        matchMethod: line.matchMethod,
        matchConfidence: line.matchConfidence,
        matchedAt: line.matchedAt,
      );

  bool get isMatched => ingredientId != null;

  /// A human decision, which no later machine pass may overwrite (D7).
  bool get isManual => matchMethod == MatchMethod.manual;

  RecipeIngredient toIngredient({required int position}) => RecipeIngredient(
        position: position,
        rawText: rawText.trim(),
        section: section,
        ingredientId: ingredientId,
        displayName: displayName,
        quantity: quantity,
        unitCode: unitCode,
        note: note,
        isOptional: isOptional,
        matchMethod: matchMethod,
        matchConfidence: matchConfidence,
        matchedAt: matchedAt,
      );
}

/// One preparation step being edited. [localId] exists for the same reason it
/// does on [RecipeDraftLine].
@freezed
abstract class RecipeDraftStep with _$RecipeDraftStep {
  const factory RecipeDraftStep({
    required int localId,
    required String text,
    int? timerSeconds,
  }) = _RecipeDraftStep;

  factory RecipeDraftStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeDraftStepFromJson(json);
}
