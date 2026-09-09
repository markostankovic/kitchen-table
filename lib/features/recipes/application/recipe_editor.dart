import 'dart:developer' as developer;

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/household/current_household.dart';
import '../../../core/refresh/data_revision.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import '../domain/recipe_detail.dart';
import '../domain/recipe_draft.dart';
import '../domain/recipe_image_upload.dart';
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

  /// Sets or clears the persisted photo path directly, bypassing an upload.
  /// `save()` calls this itself once a picked [RecipeImageUpload] has been
  /// written to Storage; the screen's Remove action calls it with `null`.
  void setImagePath(String? value) =>
      _update((RecipeDraft d) => d.copyWith(imagePath: value));

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
  /// [image] is a photo picked but not yet uploaded. When present it is
  /// uploaded FIRST, before the recipe row is touched (D48) -- the slow step
  /// happens under the cook's finger, the same order `ImportPhotoScreen`
  /// uses. A draft abandoned before calling `save()` therefore never writes to
  /// Storage, because nothing here runs until this method is called.
  ///
  /// Failures propagate as [AppFailure] for the screen to render.
  Future<String> save({RecipeImageUpload? image}) async {
    final RecipeDraft? current = state.value;
    if (current == null) {
      throw StateError('save() before the draft finished loading');
    }

    final RecipeRepository repository = ref.read(recipeRepositoryProvider);
    final Recipe? existing = current.source;
    final String? previousImagePath = existing?.imagePath;

    // Only a new recipe or a fresh photo touches household_id -- editing an
    // existing recipe's text fields never needs it.
    String? householdId;
    if (image != null || existing == null) {
      householdId = await ref.read(currentHouseholdIdProvider.future);
      if (householdId == null) {
        throw const NotFoundFailure(
            message: 'You are not in a household yet.');
      }
    }

    RecipeDraft draft = current;
    if (image != null) {
      final String uploaded = await repository.uploadImage(
        image.bytes,
        householdId: householdId!,
        contentType: image.contentType,
        extension: image.extension,
      );
      draft = draft.copyWith(imagePath: uploaded);
    }

    late final RecipeDraft saved;
    if (existing == null) {
      final Recipe created = await repository.create(
        householdId: householdId!,
        title: draft.title.trim(),
        originalLocale: draft.originalLocale,
        description: draft.description,
        servings: draft.servings,
        prepMinutes: draft.prepMinutes,
        cookMinutes: draft.cookMinutes,
        tags: draft.tags,
        status: draft.status,
        imagePath: draft.imagePath,
      );
      saved = draft.copyWith(source: created);
      state = AsyncData<RecipeDraft>(saved);
    } else {
      final Recipe updated = draft.toRecipe();
      await repository.update(updated);
      saved = draft.copyWith(source: updated);
      state = AsyncData<RecipeDraft>(saved);
    }

    final String recipeId = saved.source!.id;
    await repository.saveLines(
      recipeId,
      ingredients: saved.toIngredients(),
      steps: saved.toSteps(),
    );

    // The old object is deleted only now that the row pointing at it has
    // actually been overwritten -- and only if it changed. Best-effort: a
    // failed delete leaks a blob, it must not undo an otherwise-successful
    // save (D48), so the failure is logged rather than rethrown.
    if (previousImagePath != null && previousImagePath != saved.imagePath) {
      try {
        await repository.deleteImage(previousImagePath);
      } on Object catch (error, stackTrace) {
        developer.log(
          'Could not delete replaced recipe image',
          name: 'RecipeEditor',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

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
