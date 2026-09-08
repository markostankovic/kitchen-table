import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/refresh/data_revision.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import '../domain/recipe_detail.dart';
import '../domain/recipe_draft.dart';
import 'recipe_providers.dart';

part 'recipe_editor.g.dart';

/// The recipe editor's state and the save that ends it.
///
/// The shape `docs/ARCHITECTURE.md` names for editing: an in-memory notifier,
/// no persistence (D12 rejects offline writes). Every mutator delegates to a
/// pure method on [RecipeDraft] and assigns the result, so the logic worth
/// testing lives in `domain/` and this class stays thin enough to be worth not
/// mocking.
///
/// Keyed on the recipe id, or null for one that does not exist yet. Not
/// `keepAlive`: an abandoned editor should not outlive its screen.
@riverpod
class RecipeEditor extends _$RecipeEditor {
  @override
  Future<RecipeDraft> build(String? recipeId) async {
    if (recipeId == null) return RecipeDraft.empty();

    // The repository is used directly rather than watching
    // `recipeDetailProvider`. Saving invalidates that provider so the list and
    // detail screens re-read, and an editor watching it would answer by
    // throwing away whatever the user had typed. A draft is only ever loaded
    // once.
    final RecipeRepository repository = ref.watch(recipeRepositoryProvider);
    final RecipeDetail detail = await repository.fetchDetail(recipeId);
    return RecipeDraft.fromDetail(detail);
  }

  // ---------------------------------------------------------------------
  // Scalar fields
  // ---------------------------------------------------------------------

  void setTitle(String value) =>
      _update((RecipeDraft d) => d.copyWith(title: value));

  void setDescription(String? value) =>
      _update((RecipeDraft d) => d.copyWith(description: value));

  void setServings(int? value) =>
      _update((RecipeDraft d) => d.copyWith(servings: value));

  void setPrepMinutes(int? value) =>
      _update((RecipeDraft d) => d.copyWith(prepMinutes: value));

  void setCookMinutes(int? value) =>
      _update((RecipeDraft d) => d.copyWith(cookMinutes: value));

  void setLocale(String value) =>
      _update((RecipeDraft d) => d.copyWith(originalLocale: value));

  void setStatus(RecipeStatus value) =>
      _update((RecipeDraft d) => d.copyWith(status: value));

  void setTags(List<String> value) =>
      _update((RecipeDraft d) => d.copyWith(tags: value));

  // ---------------------------------------------------------------------
  // Lines and steps
  // ---------------------------------------------------------------------

  void addLine() => _update((RecipeDraft d) => d.addLine());

  void removeLine(int localId) =>
      _update((RecipeDraft d) => d.removeLine(localId));

  void setLineText(int localId, String rawText) =>
      _update((RecipeDraft d) => d.setLineText(localId, rawText));

  void replaceLine(RecipeDraftLine line) =>
      _update((RecipeDraft d) => d.replaceLine(line));

  void reorderLines(int oldIndex, int newIndex) =>
      _update((RecipeDraft d) => d.reorderLines(oldIndex, newIndex));

  void addStep() => _update((RecipeDraft d) => d.addStep());

  void removeStep(int localId) =>
      _update((RecipeDraft d) => d.removeStep(localId));

  void setStepText(int localId, String text) =>
      _update((RecipeDraft d) => d.setStepText(localId, text));

  void reorderSteps(int oldIndex, int newIndex) =>
      _update((RecipeDraft d) => d.reorderSteps(oldIndex, newIndex));

  // ---------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------

  /// Writes the draft and returns the recipe's id.
  ///
  /// Two round trips for a new recipe -- an insert, then
  /// `replace_recipe_lines` -- because `recipes` has an INSERT policy and
  /// there is nothing about the insert alone to make atomic (D37). What makes
  /// that safe is the [RecipeDraft.source] assignment between them: if the
  /// line write fails, the draft is already pointing at the recipe that was
  /// created, so pressing Save again updates it. The worst case is a titled
  /// recipe with no lines, sitting in the list, editable.
  ///
  /// Failures propagate as [AppFailure] for the screen to render.
  Future<String> save() async {
    final RecipeDraft? current = state.value;
    if (current == null) {
      throw StateError('save() before the draft finished loading');
    }

    final RecipeRepository repository = ref.read(recipeRepositoryProvider);
    final Recipe? existing = current.source;

    late final RecipeDraft saved;
    if (existing == null) {
      final Recipe created = await repository.create(
        title: current.title.trim(),
        originalLocale: current.originalLocale,
        description: current.description,
        servings: current.servings,
        prepMinutes: current.prepMinutes,
        cookMinutes: current.cookMinutes,
        tags: current.tags,
        status: current.status,
      );
      saved = current.copyWith(source: created);
      state = AsyncData<RecipeDraft>(saved);
    } else {
      final Recipe updated = current.toRecipe();
      await repository.update(updated);
      saved = current.copyWith(source: updated);
      state = AsyncData<RecipeDraft>(saved);
    }

    final String recipeId = saved.source!.id;
    await repository.saveLines(
      recipeId,
      ingredients: saved.toIngredients(),
      steps: saved.toSteps(),
    );

    ref.read(recipesRevisionProvider.notifier).bump();
    ref.invalidate(recipeDetailProvider(recipeId));
    return recipeId;
  }

  /// Applies a pure change to a loaded draft. A change arriving while the
  /// draft is still loading is dropped rather than queued -- the screen shows
  /// a spinner until it lands, so there is nothing on screen to have produced
  /// one.
  void _update(RecipeDraft Function(RecipeDraft draft) change) {
    final RecipeDraft? current = state.value;
    if (current == null) return;
    state = AsyncData<RecipeDraft>(change(current));
  }
}
