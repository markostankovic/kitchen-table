import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/ingredients/ingredient_catalog_providers.dart';
import '../../../core/refresh/data_revision.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/text/text_normalizer.dart';
import '../../ingredients/domain/ingredient_line_parser.dart';
import '../../recipes/domain/recipe_draft.dart';
import '../domain/import_job.dart';
import '../domain/parsed_recipe.dart';
import '../domain/parsed_recipe_draft.dart';
import 'import_providers.dart';

part 'import_confirm.g.dart';

/// The confirm screen's state (D8).
///
/// Deliberately the same shape as `RecipeEditor`: an `AsyncNotifier` over a
/// `RecipeDraft`, with one thin delegate per pure mutator. That is what lets
/// the screen reuse `IngredientLineField` verbatim -- which is why D43 moved
/// that widget to `core/` in the first place.
///
/// Not `keepAlive`: an abandoned review should not outlive its screen.
@riverpod
class ImportConfirm extends _$ImportConfirm {
  /// The parsed source, kept for the fields the draft does not model --
  /// `sourceUrl` and `sourceAttribution`, which belong to the recipe row
  /// rather than to anything the cook edits here.
  ParsedRecipe? _parsed;

  /// How the import arrived, kept for the same reason: `recipes.source_type`
  /// is derived from it, and D16's household-only rule is derived from that.
  ImportKind? _kind;

  @override
  Future<ImportReview> build(String jobId) async {
    // Waits on the poller rather than fetching once: entering the screen
    // straight after a paste means the job is still `queued`, and this is what
    // makes the same screen serve both the wait and the review.
    final ImportJob job = await ref.watch(importJobProvider(jobId).future);

    if (job.status == ImportJobStatus.failed) {
      throw ValidationFailure(
        message: job.errorMessage ?? 'That import could not be read.',
      );
    }
    final ParsedRecipe? result = job.result;
    if (result == null) {
      // Still queued or processing. The screen renders progress from the job
      // itself; this notifier simply has nothing to hand it yet.
      throw const _StillWorking();
    }

    _parsed = result;
    _kind = job.kind;
    // The attention set travels IN the state rather than beside it. A notifier
    // with a public getter is a second channel the UI has to remember to read,
    // and riverpod_lint says so.
    return draftFromParsed(result);
  }

  void setTitle(String value) =>
      _update((RecipeDraft d) => d.copyWith(title: value));
  void setServings(int? value) =>
      _update((RecipeDraft d) => d.copyWith(servings: value));
  void addLine() => _update((RecipeDraft d) => d.addLine());
  void removeLine(int localId) =>
      _update((RecipeDraft d) => d.removeLine(localId));
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

  /// Saves the reviewed recipe and returns its id.
  ///
  /// Two things happen here, in this order, and the order matters.
  ///
  /// FIRST the aliases (D42). Phase 1d part 2 took the write-back away from
  /// the machine tiers, on the grounds that a guess should not become a global
  /// permanent fact before a human has seen it -- which makes THIS the moment
  /// the catalog grows, and the only one. Accepting an import is the human
  /// agreeing, so every line still matched at save time writes its wording
  /// back. Without this the LLM tier pays for the same string forever.
  ///
  /// THEN the recipe, in one transaction (D44).
  ///
  /// Alias failures are collected and reported, never fatal. `linkAlias`
  /// returns false rather than raising when a string already names a different
  /// ingredient, and losing a recipe over a word one household spells oddly
  /// would be the wrong trade.
  Future<String> save() async {
    final ImportReview? review = state.value;
    if (review == null) {
      throw StateError('save() before the draft finished loading');
    }
    final RecipeDraft current = review.draft;

    await _writeBackAliases(current);

    final ParsedRecipe? parsed = _parsed;
    final String recipeId =
        await ref.read(importRepositoryProvider).saveImported(
              jobId,
              kind: _kind ?? ImportKind.text,
              title: current.title,
              originalLocale: current.originalLocale,
              description: current.description,
              servings: current.servings,
              prepMinutes: current.prepMinutes,
              cookMinutes: current.cookMinutes,
              sourceUrl: parsed?.sourceUrl,
              sourceAttribution: parsed?.sourceAttribution,
              tags: current.tags,
              ingredients: current.toIngredients(),
              steps: current.toSteps(),
            );

    // Not `ref.invalidate(recipeListProvider)`: that provider belongs to
    // another feature and this one may not name it. The counter in core/ is
    // the channel both writers share.
    ref.read(recipesRevisionProvider.notifier).bump();
    return recipeId;
  }

  /// One `link_ingredient_alias` per matched line whose wording is not already
  /// the name it matched.
  ///
  /// The normalized-equality guard is the same one `IngredientLineField` uses
  /// before its own write-back: if the cook wrote the catalog's own word there
  /// is nothing to record. It is what stops an accept-all writing forty rows
  /// that already exist.
  Future<void> _writeBackAliases(RecipeDraft draft) async {
    final IngredientLineParser? parser =
        ref.read(lineParserProvider).value;
    if (parser == null) return;

    // Deliberately not annotated with its type. `IngredientRepository` lives
    // in features/ingredients/data/, and a feature may not import another
    // feature's data layer -- the provider in core/ IS the sanctioned access
    // point (D43). This is the same move recipe_providers.dart makes to use a
    // SupabaseClient without naming one.
    final catalog = ref.read(ingredientCatalogProvider);

    for (final RecipeDraftLine line in draft.lines) {
      final String? ingredientId = line.ingredientId;
      final String? displayName = line.displayName;
      if (ingredientId == null || displayName == null) continue;

      final String? name = parser.parse(line.rawText).name;
      if (name == null || name.trim().isEmpty) continue;
      if (TextNormalizer.normalize(displayName) ==
          TextNormalizer.normalize(name)) {
        continue;
      }

      try {
        await catalog.linkAlias(ingredientId, name,
            locale: draft.originalLocale);
      } on AppFailure {
        // Best effort, by design. A wording that could not be recorded is a
        // catalog that grew a little less, not a recipe that failed to save.
      }
    }
  }

  void _update(RecipeDraft Function(RecipeDraft draft) change) {
    final ImportReview? current = state.value;
    if (current == null) return;
    state = AsyncData<ImportReview>((
      draft: change(current.draft),
      // Carried unchanged: the marks are about what the SERVER proposed, and
      // editing a line does not rewrite that history. The line editor already
      // retires a match when the name changes, which is what actually clears
      // the doubt.
      needsAttention: current.needsAttention,
    ));
  }
}

/// The job exists but has not been read yet.
///
/// An error rather than a state on the draft, because there is no draft: the
/// screen watches the job for progress and only asks this notifier for
/// something once there is something to ask for.
class _StillWorking implements Exception {
  const _StillWorking();
  @override
  String toString() => 'import still processing';
}
