import 'package:freezed_annotation/freezed_annotation.dart';

import 'recipe_detail.dart';
import 'recipe_step.dart';
import 'recipe_translation.dart';

part 'translation_review_draft.freezed.dart';
part 'translation_review_draft.g.dart';

/// A machine translation being reviewed (Phase 3, part 3).
///
/// On [RecipeDraft]'s precedent: every mutation is a pure function returning
/// a new draft, so the notifier in `application/` does nothing but assign
/// the result. Unlike [RecipeDraft], the row set of [steps] is fixed --
/// there is no `addStep`/`removeStep`/`reorderSteps` here, because
/// `review_recipe_translation` refuses a step count or position it does not
/// already have (D80). [setStepText] is keyed by [RecipeStep.position]
/// rather than a synthetic local id for exactly that reason: position IS the
/// identity here, not an ordering a human can rearrange.
///
/// The source fields ([sourceTitle], [sourceDescription], [sourceSteps]) are
/// read-only -- the recipe's own original prose, carried alongside the
/// editable translation so the review screen never needs a second fetch to
/// show both.
///
/// In memory only, like [RecipeDraft] -- D12 rejects offline writes.
///
/// Pure Dart (rule 7).
@freezed
abstract class TranslationReviewDraft with _$TranslationReviewDraft {
  const TranslationReviewDraft._();

  const factory TranslationReviewDraft({
    required String locale,

    /// The recipe's own language -- distinct from [locale], which is the
    /// language being reviewed. Used only to label the source side of the
    /// screen ("Original (Serbian)").
    required String sourceLocale,
    required String sourceTitle,
    String? sourceDescription,
    @Default(<RecipeStep>[]) List<RecipeStep> sourceSteps,
    required String title,
    String? description,
    @Default(<RecipeStep>[]) List<RecipeStep> steps,
  }) = _TranslationReviewDraft;

  factory TranslationReviewDraft.fromJson(Map<String, dynamic> json) =>
      _$TranslationReviewDraftFromJson(json);

  /// Opens [detail]'s translation for [detail.readingLocale] for review.
  ///
  /// Throws if there is none -- `TranslationReviewer.build` is the only
  /// caller, and it turns this into a [NotFoundFailure] before it reaches
  /// here, the same shape `RecipeDraft.fromDetail` assumes a loaded
  /// [RecipeDetail] rather than re-checking one.
  factory TranslationReviewDraft.fromDetail(RecipeDetail detail) {
    final RecipeTranslation? translation = detail.translation;
    if (translation == null) {
      throw StateError(
        'TranslationReviewDraft.fromDetail with no translation for '
        '${detail.readingLocale}',
      );
    }
    return TranslationReviewDraft(
      locale: detail.readingLocale,
      sourceLocale: detail.recipe.originalLocale,
      sourceTitle: detail.recipe.title,
      sourceDescription: detail.recipe.description,
      sourceSteps: detail.steps,
      title: translation.title,
      description: translation.description,
      steps: translation.steps,
    );
  }

  /// Mirrors the SQL guard (`review_recipe_translation`'s blank-title check)
  /// so the screen can refuse a save before the round trip.
  bool get isValid => title.trim().isNotEmpty;

  /// [sourceSteps] paired with their translation by position -- there is
  /// always exactly one of each (D80, re-checked by
  /// `review_recipe_translation`), so the widget never has to join by hand.
  List<(RecipeStep source, RecipeStep translated)> get pairedSteps {
    final Map<int, RecipeStep> byPosition = <int, RecipeStep>{
      for (final RecipeStep step in steps) step.position: step,
    };
    return <(RecipeStep, RecipeStep)>[
      for (final RecipeStep source in sourceSteps)
        if (byPosition[source.position] case final RecipeStep translated)
          (source, translated),
    ];
  }

  TranslationReviewDraft setTitle(String value) => copyWith(title: value);

  TranslationReviewDraft setDescription(String? value) =>
      copyWith(description: value);

  /// Edits the text of the translated step at [position]. No other field of
  /// [RecipeStep] is ever touched here -- there is nothing on this screen
  /// that could change a position or a timer.
  TranslationReviewDraft setStepText(int position, String text) => copyWith(
        steps: steps
            .map((RecipeStep step) => step.position == position
                ? step.copyWith(text: text)
                : step)
            .toList(growable: false),
      );
}
