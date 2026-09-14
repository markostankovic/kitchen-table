import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/refresh/data_revision.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe_detail.dart';
import '../domain/translation_review_draft.dart';
import 'recipe_providers.dart';

part 'translation_reviewer.g.dart';

/// The translation review screen's state and the save that ends it (Phase 3,
/// part 3).
///
/// Keyed on `(recipeId, locale)`, on [RecipeEditor]'s precedent: loads once
/// through the repository rather than watching `recipeDetailProvider`, for
/// the same reason `RecipeEditor.build`'s own comment gives -- `save()`
/// invalidates that provider, and a notifier watching it would answer its
/// own save by discarding whatever the reviewer had just typed.
///
/// Unlike [RecipeEditor], this notifier does NOT inherit D81's deferred
/// `RecipeEditor` caveat (the editor's own hardcoded `'sr'`, fixed
/// separately this part): [locale] is known before the fetch happens,
/// because a review is by definition reading in one locale. The two
/// notifiers look alike enough that this is worth saying rather than
/// leaving a reader to assume the same caveat applies here.
///
/// Not `keepAlive`: an abandoned review should not outlive its screen, the
/// same call `RecipeEditor` makes.
@riverpod
class TranslationReviewer extends _$TranslationReviewer {
  @override
  Future<TranslationReviewDraft> build(
    String recipeId, {
    required String locale,
  }) async {
    final RecipeRepository repository = ref.watch(recipeRepositoryProvider);
    final RecipeDetail detail =
        await repository.fetchDetail(recipeId, locale: locale);

    // Unreachable from the detail screen's own entry point (`canReview`
    // requires a translation to exist), but a deep link to
    // `/recipes/<id>/review` on an untranslated recipe reaches this all the
    // same, and it must not be a blank screen.
    if (detail.translation == null) {
      throw const NotFoundFailure(
        message: 'There is no translation to review yet.',
        code: FailureCode.noTranslationToReview,
      );
    }

    return TranslationReviewDraft.fromDetail(detail);
  }

  void setTitle(String value) =>
      _update((TranslationReviewDraft d) => d.setTitle(value));

  void setDescription(String? value) =>
      _update((TranslationReviewDraft d) => d.setDescription(value));

  void setStepText(int position, String text) => _update(
        (TranslationReviewDraft d) => d.setStepText(position, text),
      );

  /// Writes the review and returns once it has landed.
  ///
  /// Failures propagate as [AppFailure] for the screen to render.
  Future<void> save() async {
    final TranslationReviewDraft? current = state.value;
    if (current == null) {
      throw StateError('save() before the draft finished loading');
    }

    final RecipeRepository repository = ref.read(recipeRepositoryProvider);
    await repository.reviewTranslation(
      recipeId,
      locale: current.locale,
      title: current.title.trim(),
      description: current.description,
      steps: current.steps,
    );

    ref.read(recipesRevisionProvider.notifier).bump();
    // The whole family, not just this locale -- `RecipeEditor.save`'s own
    // comment explains why: a save should invalidate whichever locale a
    // screen is actually watching.
    ref.invalidate(recipeDetailProvider);
  }

  /// Applies a pure change to a loaded draft. A change arriving while the
  /// draft is still loading is dropped rather than queued -- `RecipeEditor
  /// ._update`'s own reasoning: the screen shows a spinner until it lands,
  /// so there is nothing on screen to have produced one.
  void _update(
    TranslationReviewDraft Function(TranslationReviewDraft draft) change,
  ) {
    final TranslationReviewDraft? current = state.value;
    if (current == null) return;
    state = AsyncData<TranslationReviewDraft>(change(current));
  }
}
