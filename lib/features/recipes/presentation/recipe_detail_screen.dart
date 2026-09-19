import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/refresh/data_revision.dart';
import '../../../core/router/routes.dart';
import '../../ingredients/domain/unit_catalog.dart';
import '../../../core/ingredients/ingredient_catalog_providers.dart';
import '../application/recipe_providers.dart';
import '../domain/recipe.dart';
import '../domain/recipe_detail.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_step.dart';
import '../../../core/ingredients/widgets/quantity_format.dart';

/// One recipe, read-only.
///
/// The ingredient list is the part that matters. A matched line renders the
/// *catalog's* name for the ingredient in the reader's locale rather than the
/// words the cook typed -- that hop is D1, and it is what will later let one
/// shopping list say `brašno` for a recipe written in Serbian and one written
/// in English. A line that matched nothing renders exactly what was typed,
/// which is rule 3 and a perfectly good outcome, not a degraded one.
///
/// Phase 3 part 2 widens the same idea to the recipe's own prose:
/// [RecipeDetail.displayTitle]/[displayDescription]/[displaySteps] read from
/// a `recipe_translations` row when the reader's locale differs from the
/// recipe's own, exactly as [RecipeIngredient.resolvedName] already reads
/// from the catalog. This screen is also this feature's first to read
/// [AppLocalizations] (D77's rhythm, one screen at a time) -- the recipe
/// list and editor still render in English.
class RecipeDetailScreen extends ConsumerStatefulWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailScreen> createState() =>
      _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  bool _translating = false;

  // Local echo (decision 3): the detail provider is a plain Future, and
  // invalidating it after every tap would flash a spinner over the whole
  // recipe for a value the screen already knows. `_pendingFavorite` and
  // `_pendingRating` hold that known value until the next real fetch
  // replaces it; `_hasPendingRating` distinguishes "no override yet" from
  // "overridden to null (unrated)".
  bool? _pendingFavorite;
  bool _hasPendingRating = false;
  int? _pendingRating;

  bool _isFavorite(Recipe recipe) => _pendingFavorite ?? recipe.isFavorite;

  int? _rating(Recipe recipe) =>
      _hasPendingRating ? _pendingRating : recipe.rating;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String readingLocale = ref.watch(appLocaleProvider).languageCode;
    final AsyncValue<RecipeDetail> detail = ref.watch(
      recipeDetailProvider(widget.recipeId, locale: readingLocale),
    );
    final Recipe? recipe = detail.value?.recipe;

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.value?.displayTitle ?? l10n.recipeDetailFallbackTitle),
        actions: <Widget>[
          IconButton(
            tooltip: recipe != null && _isFavorite(recipe)
                ? l10n.removeFromFavoritesTooltip
                : l10n.addToFavoritesTooltip,
            icon: Icon(recipe != null && _isFavorite(recipe)
                ? Icons.star
                : Icons.star_border),
            onPressed:
                recipe != null ? () => _setFavorite(recipe, l10n) : null,
          ),
          IconButton(
            tooltip: l10n.editTooltip,
            icon: const Icon(Icons.edit_outlined),
            onPressed: detail.hasValue
                ? () => RecipeEditRoute(widget.recipeId).go(context)
                : null,
          ),
          // Delete sits behind an overflow rather than next to Edit: they are
          // one tap apart and only one of them is reversible.
          PopupMenuButton<_DetailAction>(
            enabled: detail.hasValue && !_translating,
            onSelected: (_DetailAction action) => switch (action) {
              _DetailAction.translate => _translate(detail.value!, l10n),
              _DetailAction.review =>
                RecipeTranslationReviewRoute(widget.recipeId).go(context),
              _DetailAction.delete => _confirmDelete(l10n),
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<_DetailAction>>[
              // canTranslate and canReview are mutually exclusive (Phase 3,
              // part 3): before a translation exists only Translate shows;
              // once one does, only Review does. Neither shows while reading
              // the recipe's own language. This is also the whole
              // implementation of "no retranslate after a review" -- once a
              // translation exists, canTranslate is false and stays false.
              if (detail.value?.canTranslate ?? false)
                PopupMenuItem<_DetailAction>(
                  value: _DetailAction.translate,
                  child: Text(l10n.translateAction(_targetLanguageName(
                    l10n,
                    detail.value!.recipe.originalLocale,
                  ))),
                ),
              if (detail.value?.canReview ?? false)
                PopupMenuItem<_DetailAction>(
                  value: _DetailAction.review,
                  child: Text(l10n.reviewTranslationMenuItem),
                ),
              PopupMenuItem<_DetailAction>(
                value: _DetailAction.delete,
                child: Text(l10n.deleteRecipeMenuItem),
              ),
            ],
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
                '${l10n.couldNotLoadRecipe}\n\n${localizedErrorMessage(e, l10n)}',
                textAlign: TextAlign.center),
          ),
        ),
        data: (RecipeDetail d) => _Body(
          detail: d,
          l10n: l10n,
          translating: _translating,
          rating: _rating(d.recipe),
          onSetRating: (int star) => _setRating(d.recipe, star, l10n),
        ),
      ),
    );
  }

  /// The other locale's own name, in the reading language -- distinct from
  /// the Settings toggle's untranslated *Srpski*/*English* (D77): this is
  /// prose ("Translate to Serbian"), not the language's own label.
  String _targetLanguageName(AppLocalizations l10n, String originalLocale) =>
      originalLocale == 'sr' ? l10n.languageEnglish : l10n.languageSerbian;

  Future<void> _translate(RecipeDetail detail, AppLocalizations l10n) async {
    setState(() => _translating = true);
    try {
      await ref.read(recipeRepositoryProvider).translate(
            widget.recipeId,
            detail.readingLocale,
          );
      ref.read(recipesRevisionProvider.notifier).bump();
      ref.invalidate(recipeDetailProvider);
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  /// Toggles the household-wide favorite flag (D24, D100).
  ///
  /// Local echo, not `ref.invalidate` (decision 3): the screen already knows
  /// the value it just wrote, so it renders that immediately and reverts it
  /// on failure, exactly as [_confirmDelete] reverts nothing because it never
  /// guesses -- this is the first mutation in the app that does.
  Future<void> _setFavorite(Recipe recipe, AppLocalizations l10n) async {
    final bool next = !_isFavorite(recipe);
    setState(() => _pendingFavorite = next);
    try {
      await ref
          .read(recipeRepositoryProvider)
          .setFavorite(widget.recipeId, isFavorite: next);
      ref.read(recipesRevisionProvider.notifier).bump();
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() => _pendingFavorite = !next);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    }
  }

  /// Sets the household-wide rating to [star], or clears it if [star] is
  /// already the current rating (decision 6: re-tap clears, unrated is
  /// null, not zero). Local echo, same shape as [_setFavorite].
  Future<void> _setRating(Recipe recipe, int star, AppLocalizations l10n) async {
    final int? previous = _rating(recipe);
    final int? next = previous == star ? null : star;
    setState(() {
      _hasPendingRating = true;
      _pendingRating = next;
    });
    try {
      await ref.read(recipeRepositoryProvider).setRating(widget.recipeId, next);
      ref.read(recipesRevisionProvider.notifier).bump();
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _hasPendingRating = true;
        _pendingRating = previous;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    }
  }

  /// Soft-deletes the recipe after a confirmation, then returns to the list.
  ///
  /// The row is not erased -- there are no hard deletes (rule 4) -- so the
  /// copy says the recipe goes away rather than that it is destroyed.
  Future<void> _confirmDelete(AppLocalizations l10n) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: Text(l10n.deleteRecipeDialogTitle),
            content: Text(l10n.deleteRecipeDialogBody),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancelButton),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.deleteButton),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    try {
      await ref.read(recipeRepositoryProvider).softDelete(widget.recipeId);
      ref.invalidate(recipeListProvider);
      if (!mounted) return;
      const RecipesRoute().go(context);
    } on AppFailure catch (e) {
      if (!mounted) return;
      // A snackbar rather than the forms' inline error: this screen has no
      // field for the message to sit under, and the action is transient.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    }
  }
}

enum _DetailAction { translate, review, delete }

class _Body extends ConsumerWidget {
  const _Body({
    required this.detail,
    required this.l10n,
    required this.translating,
    required this.rating,
    required this.onSetRating,
  });

  final RecipeDetail detail;
  final AppLocalizations l10n;
  final bool translating;

  /// The rating to render, with the screen's own local echo already
  /// resolved (decision 3) -- may differ from `detail.recipe.rating` for the
  /// moment between a tap and its write landing.
  final int? rating;

  final ValueChanged<int> onSetRating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Recipe recipe = detail.recipe;

    // The lexicon is already cached for the session, so this rarely suspends.
    // Until it arrives, lines render with the unit code instead of its
    // Serbian spelling -- readable, and better than withholding the recipe.
    final UnitCatalog units =
        ref.watch(unitCatalogProvider).value ?? UnitCatalog.empty();

    final List<String> meta = <String>[
      if (recipe.servings != null) l10n.recipeServingsCount(recipe.servings!),
      if (recipe.prepMinutes != null)
        l10n.recipePrepMinutes(recipe.prepMinutes!),
      if (recipe.cookMinutes != null)
        l10n.recipeCookMinutes(recipe.cookMinutes!),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        if (recipe.imageUrl != null) ...<Widget>[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                recipe.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? progress) =>
                    progress == null
                        ? child
                        : const Center(child: CircularProgressIndicator()),
                // A signed URL can outlive its TTL, or the object can have
                // been replaced since this page loaded. Either way the recipe
                // still renders without its picture (rule 3), not an error
                // screen over a working recipe.
                errorBuilder: (_, _, _) =>
                    const Center(child: Icon(Icons.broken_image_outlined)),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          children: <Widget>[
            if (recipe.status == RecipeStatus.draft)
              Chip(label: Text(l10n.draftChipLabel)),
            // Anything AI-produced is draft until a human marks it tested
            // (docs/ROADMAP.md) -- this is that rule applied to prose rather
            // than to the recipe row itself (Phase 3, part 2). It needs no
            // code change to disappear once reviewed (Phase 3, part 3):
            // review_recipe_translation sets is_machine_generated = false,
            // which is exactly what this getter reads. No separate
            // "Reviewed" chip is added -- this app's chips are caveats
            // (Draft, Machine translation), not endorsements, and this
            // chip's own disappearance already is the signal.
            if (detail.isShowingMachineTranslation)
              Chip(label: Text(l10n.machineTranslationChipLabel)),
            if (translating)
              const Chip(
                label: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        if (recipe.status == RecipeStatus.draft ||
            detail.isShowingMachineTranslation ||
            translating)
          const SizedBox(height: 8),
        if (meta.isNotEmpty)
          Text(meta.join(' · '), style: Theme.of(context).textTheme.bodySmall),
        _RatingStars(rating: rating, onRate: onSetRating, l10n: l10n),
        if (detail.displayDescription != null &&
            detail.displayDescription!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(detail.displayDescription!),
        ],
        if (recipe.tags.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: recipe.tags
                .map((String t) => Chip(label: Text(t)))
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 24),
        _SectionHeading(text: l10n.ingredientsHeading),
        if (detail.ingredients.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.noIngredientsYet),
          )
        else
          ...detail.ingredients.map(
            (RecipeIngredient line) => _IngredientRow(
              line: line,
              units: units,
              locale: detail.readingLocale,
              l10n: l10n,
            ),
          ),
        const SizedBox(height: 24),
        _SectionHeading(text: l10n.stepsHeading),
        if (detail.displaySteps.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(l10n.noStepsYet),
          )
        else
          ...detail.displaySteps.map((RecipeStep step) => _StepRow(step: step)),
        if (recipe.sourceAttribution != null ||
            recipe.sourceUrl != null) ...<Widget>[
          const SizedBox(height: 24),
          // Stored and displayed for every import (docs/ROADMAP.md, standing
          // rules). Nothing in 1c sets it, but the display is the half that
          // must not be forgotten later.
          Text(
            <String>[
              if (recipe.sourceAttribution != null) recipe.sourceAttribution!,
              if (recipe.sourceUrl != null) recipe.sourceUrl!,
            ].join('\n'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.line,
    required this.units,
    required this.locale,
    required this.l10n,
  });

  final RecipeIngredient line;
  final UnitCatalog units;

  /// The reader's own locale, not `recipe.originalLocale` -- a translated
  /// method reading in one language beside a unit spelled in another would
  /// be the same bug D81 fixed for the display name, one column over.
  final String locale;

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    // The measured half of the line, assembled from the structured columns.
    // Empty whenever the parse found no quantity, which is normal.
    final String amount = <String>[
      if (line.quantity != null) formatQuantity(line.quantity!),
      if (line.unitCode != null)
        units.displayName(line.unitCode!, locale: locale),
    ].join(' ');

    final String trailer = <String>[
      if (line.note != null) line.note!,
      if (line.isOptional && line.note == null) l10n.ingredientOptionalTrailer,
    ].join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(amount, style: text.bodyMedium),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // resolvedName is the catalog's word when the line matched and
                // the raw line when it did not. One definition, so the detail
                // screen and the shopping list cannot disagree.
                Text(line.resolvedName, style: text.bodyMedium),
                if (trailer.isNotEmpty)
                  Text(trailer, style: text.bodySmall),
              ],
            ),
          ),
          if (!line.isMatched)
            Tooltip(
              message: l10n.ingredientNotMatchedTooltip,
              child: Icon(Icons.help_outline,
                  size: 18, color: Theme.of(context).colorScheme.outline),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final RecipeStep step;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 28,
              child: Text('${step.position + 1}.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Expanded(child: Text(step.text)),
          ],
        ),
      );
}

/// Five tap targets, filled up to the current rating. Tapping the star that
/// already *is* the rating clears it back to unrated (decision 6) -- unrated
/// is `rating == null`, never zero.
class _RatingStars extends StatelessWidget {
  const _RatingStars({
    required this.rating,
    required this.onRate,
    required this.l10n,
  });

  final int? rating;
  final ValueChanged<int> onRate;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Row(
        // Keyed so widget tests can scope to these five stars without
        // conflating them with the AppBar's own favorite star/star_border
        // icon.
        key: const Key('ratingStars'),
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(5, (int i) {
          final int star = i + 1;
          final bool filled = rating != null && star <= rating!;
          return IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: star == rating
                ? l10n.clearRatingTooltip
                : l10n.ratingStarsTooltip(star),
            icon: Icon(filled ? Icons.star : Icons.star_border),
            onPressed: () => onRate(star),
          );
        }),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
