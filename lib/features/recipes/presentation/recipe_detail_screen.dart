import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/date_labels.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/l10n/language_labels.dart';
import '../../../core/l10n/meal_slot_labels.dart';
import '../../../core/meal_plan/meal_plan_writer.dart';
import '../../../core/meal_plan/widgets/meal_slot_picker_sheet.dart';
import '../../../core/refresh/data_revision.dart';
import '../../../core/router/routes.dart';
import '../../../core/text/text_normalizer.dart';
import '../../../core/theme/app_sizes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/kitchen_colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_section_heading.dart';
import '../../../core/widgets/app_stat_strip.dart';
import '../../ingredients/domain/unit_catalog.dart';
import '../../../core/ingredients/ingredient_catalog_providers.dart';
import '../../meal_plan/domain/meal_slot.dart';
import '../../meal_plan/domain/snack_variety.dart';
import '../application/recipe_providers.dart';
import '../domain/recipe.dart';
import '../domain/recipe_detail.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_step.dart';
import '../../../core/ingredients/widgets/ingredient_line_row.dart';
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
      // No title. The recipe's own name is the one thing on this screen that
      // earns `headlineSmall`, and it says it once -- in the body, under the
      // photo, where § Type reserves that role for it. An app bar repeating
      // it in `titleLarge` would be the same words twice in two sizes.
      //
      // The bar stays opaque on `surface` rather than floating circular
      // buttons over the photo the way the mock does: an arbitrary photo in
      // two brightnesses has no contrast guarantee behind an icon, and the
      // favourite toggle has to stay reachable at any scroll position.
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
            tooltip: recipe != null && _isFavorite(recipe)
                ? l10n.removeFromFavoritesTooltip
                : l10n.addToFavoritesTooltip,
            // A heart, not a star. The star meant favourite *and* rating on
            // this screen, one bar apart from five more stars that meant
            // something else; after Phase 7 part 3 a star is a rating
            // everywhere in the app and nothing else is.
            icon: Icon(
              recipe != null && _isFavorite(recipe)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: recipe != null && _isFavorite(recipe)
                  ? Theme.of(context).extension<KitchenColors>()!.favorite
                  : null,
            ),
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
              _DetailAction.addToPlan => _addToPlan(detail.value!.recipe, l10n),
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
                  child: Text(l10n.translateAction(
                    languageName(l10n, detail.value!.readingLocale),
                  )),
                ),
              if (detail.value?.canReview ?? false)
                PopupMenuItem<_DetailAction>(
                  value: _DetailAction.review,
                  child: Text(l10n.reviewTranslationMenuItem),
                ),
              PopupMenuItem<_DetailAction>(
                value: _DetailAction.addToPlan,
                child: Text(l10n.addToPlanMenuItem),
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
        error: (Object e, _) => AppErrorView(
            message:
                '${l10n.couldNotLoadRecipe}\n\n${localizedErrorMessage(e, l10n)}'),
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

  /// Opens the day/slot sheet and writes the pick through `core/meal_plan`'s
  /// own [MealPlanWriter] -- not [MealPlanEditor], which derives its
  /// destination from a visible week this screen does not have (D103).
  ///
  /// The snack-warning-then-write sequence mirrors `_SlotRow._add` /
  /// `_confirmRepeat` in `meal_plan_screen.dart` exactly: advisory only
  /// (D58), never blocking the write on its own.
  Future<void> _addToPlan(Recipe recipe, AppLocalizations l10n) async {
    final MealSlotPick? pick = await showMealSlotPicker(context);
    if (pick == null || !mounted) return;

    if (pick.slot == MealSlot.snack) {
      final int repeatCount = await ref
          .read(mealPlanWriterProvider.notifier)
          .snackRepeatCount(recipeId: recipe.id, entryDate: pick.date);
      if (!mounted) return;
      if (shouldWarnOnRepeat(repeatCount)) {
        final bool proceed = await _confirmSnackRepeat(repeatCount, l10n);
        if (!proceed || !mounted) return;
      }
    }

    try {
      await ref.read(mealPlanWriterProvider.notifier).addRecipe(
            entryDate: pick.date,
            slot: pick.slot,
            recipeId: recipe.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.addedToPlanSnackbar(
          shortDateLabel(pick.date, l10n.localeName),
          mealSlotLabel(pick.slot, l10n),
        )),
      ));
    } on AppFailure catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.localized(l10n))));
    }
  }

  /// Advisory only -- cancelling here writes nothing. `_SlotRow._confirmRepeat`
  /// in `meal_plan_screen.dart` is this dialog's exact precedent.
  Future<bool> _confirmSnackRepeat(int repeatCount, AppLocalizations l10n) async {
    final bool? proceed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.snackRepeatWarningTitle),
        content: Text(
          l10n.snackRepeatWarningBody(l10n.snackSlotCount(repeatCount)),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.addAnywayButton),
          ),
        ],
      ),
    );
    return proceed ?? false;
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

enum _DetailAction { translate, review, addToPlan, delete }

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
    final ThemeData theme = Theme.of(context);
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;
    final Recipe recipe = detail.recipe;

    // The lexicon is already cached for the session, so this rarely suspends.
    // Until it arrives, lines render with the unit code instead of its
    // Serbian spelling -- readable, and better than withholding the recipe.
    final UnitCatalog units =
        ref.watch(unitCatalogProvider).value ?? UnitCatalog.empty();

    // Per-tag lookup, not `RecipeTag.relabelled`: these chips render
    // `recipe.tags` (original spellings) directly, not the household
    // vocabulary (Phase 6, part 1a).
    final Map<String, String> tagLabels =
        ref.watch(tagLabelsProvider(detail.readingLocale)).value ??
            const <String, String>{};

    final String? description = detail.displayDescription;

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: <Widget>[
        // Full-bleed, outside the gutter -- and rendered whether or not there
        // is a photo. A recipe out of a notebook has no picture and never
        // will; an omitted hero made the screen start at a different place
        // for those recipes, which read as something having failed to load.
        _PhotoWell(imageUrl: recipe.imageUrl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: AppSpacing.lg),
              ..._caveats(context),
              // The recipe's own name, said once, here. The app bar carries
              // no title (see the `AppBar` above).
              Text(
                detail.displayTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (description != null && description.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (recipe.tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: recipe.tags
                      .map(
                        (String t) => Chip(
                          label: Text(
                            tagLabels[TextNormalizer.normalize(t)] ?? t,
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              // Four facts as four columns, replacing the ` · `-joined
              // sentence this screen used to carry. A column is the same
              // width in Serbian as in English; a joined sentence is not.
              AppStatStrip(columns: _stats(context, kitchen)),
              const SizedBox(height: AppSpacing.xl),
              AppSectionHeading(text: l10n.ingredientsHeading),
              if (detail.ingredients.isEmpty)
                Text(
                  l10n.noIngredientsYet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...detail.ingredients.map(
                  (RecipeIngredient line) => _ingredientRow(line, units),
                ),
              const SizedBox(height: AppSpacing.xl),
              AppSectionHeading(text: l10n.stepsHeading),
              if (detail.displaySteps.isEmpty)
                Text(
                  l10n.noStepsYet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...detail.displaySteps.map(
                  (RecipeStep step) => _StepRow(step: step),
                ),
              ..._sourceFooter(context),
            ],
          ),
        ),
      ],
    );
  }

  /// The badge and chips that qualify this recipe, and the gap under them.
  ///
  /// All three are caveats, never endorsements: a draft is a recipe nobody
  /// has vouched for yet, and the machine-translation chip disappears of its
  /// own accord once `review_recipe_translation` sets
  /// `is_machine_generated = false` (Phase 3, part 3). There is no
  /// "Reviewed" chip and there should not be one -- the disappearance is the
  /// signal.
  ///
  /// `Draft` is an [AppBadge] rather than a `Chip` now: a chip in this app is
  /// a control, and nothing taps this.
  List<Widget> _caveats(BuildContext context) {
    final List<Widget> chips = <Widget>[
      if (detail.recipe.status == RecipeStatus.draft)
        AppBadge(label: l10n.draftChipLabel),
      if (detail.isShowingMachineTranslation)
        Chip(
          avatar: const Icon(Icons.language, size: AppSizes.iconInMeta),
          label: Text(l10n.machineTranslationChipLabel),
        ),
      if (translating)
        const Chip(
          label: SizedBox(
            width: AppSizes.iconInMeta,
            height: AppSizes.iconInMeta,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
    ];
    if (chips.isEmpty) return const <Widget>[];
    return <Widget>[
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      ),
      const SizedBox(height: AppSpacing.md),
    ];
  }

  /// Servings, prep, cook and the rating -- only the ones this recipe has,
  /// except the rating, which is a control rather than a fact and is offered
  /// even when unrated.
  List<AppStatColumn> _stats(BuildContext context, KitchenColors kitchen) {
    final TextStyle? value = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: kitchen.statValue,
    );
    final Recipe recipe = detail.recipe;
    return <AppStatColumn>[
      if (recipe.servings != null)
        AppStatColumn(
          label: l10n.statServingsLabel,
          value: Text('${recipe.servings}', style: value),
        ),
      if (recipe.prepMinutes != null)
        AppStatColumn(
          label: l10n.statPrepLabel,
          value: Text(l10n.statMinutesValue(recipe.prepMinutes!), style: value),
        ),
      if (recipe.cookMinutes != null)
        AppStatColumn(
          label: l10n.statCookLabel,
          value: Text(l10n.statMinutesValue(recipe.cookMinutes!), style: value),
        ),
      AppStatColumn(
        label: l10n.statRatingLabel,
        value: _RatingStars(rating: rating, onRate: onSetRating, l10n: l10n),
      ),
    ];
  }

  /// One line, assembled from the structured columns into the shared row.
  ///
  /// `resolvedName` is the catalog's word when the line matched and the raw
  /// line when it did not. One definition, so the detail screen and the
  /// shopping list cannot disagree.
  ///
  /// The unit is spelled in the **reader's** locale, not
  /// `recipe.originalLocale` -- a translated method read in one language
  /// beside a unit spelled in another would be the same bug D81 fixed for the
  /// display name, one column over.
  Widget _ingredientRow(RecipeIngredient line, UnitCatalog units) {
    final String trailer = <String>[
      if (line.note != null) line.note!,
      if (line.isOptional && line.note == null) l10n.ingredientOptionalTrailer,
    ].join(', ');

    return IngredientLineRow(
      quantity:
          line.quantity == null ? null : formatQuantity(line.quantity!),
      unit: line.unitCode == null
          ? null
          : units.displayName(line.unitCode!, locale: detail.readingLocale),
      name: line.resolvedName,
      trailer: trailer.isEmpty ? null : trailer,
      isMatched: line.isMatched,
      unmatchedTooltip: l10n.ingredientNotMatchedTooltip,
    );
  }

  /// Where the recipe came from. Stored and displayed for every import
  /// (docs/ROADMAP.md, standing rules). Nothing in 1c sets it, but the
  /// display is the half that must not be forgotten later.
  List<Widget> _sourceFooter(BuildContext context) {
    final Recipe recipe = detail.recipe;
    if (recipe.sourceAttribution == null && recipe.sourceUrl == null) {
      return const <Widget>[];
    }
    final ThemeData theme = Theme.of(context);
    return <Widget>[
      const SizedBox(height: AppSpacing.xl),
      const Divider(),
      const SizedBox(height: AppSpacing.md),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.link,
            size: AppSizes.iconInMeta,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              <String>[
                if (recipe.sourceAttribution != null)
                  recipe.sourceAttribution!,
                if (recipe.sourceUrl != null) recipe.sourceUrl!,
              ].join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ];
  }
}

/// The 16:9 well the recipe's photo sits in -- and sits in empty, when there
/// is none.
///
/// A missing picture is not a failure state (rule 3's spirit), so there is no
/// broken-image icon: the well shows a quiet `image_outlined` in `outline`,
/// the same thing it shows when a signed URL has outlived its TTL or the
/// object behind it was replaced. Either way the recipe still renders.
class _PhotoWell extends StatelessWidget {
  const _PhotoWell({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? url = imageUrl;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: url == null
            ? _placeholder(theme)
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? progress,
                ) => progress == null
                    ? child
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (_, _, _) => _placeholder(theme),
              ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Center(
    child: Icon(
      Icons.image_outlined,
      size: AppSizes.icon,
      color: theme.colorScheme.outline,
    ),
  );
}

/// One step: its number in a tonal disc, then the step itself.
///
/// The disc is what makes a list of steps countable at a glance while
/// cooking -- a bare `1.` in the text column reads as part of the sentence.
class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: AppSizes.stepDisc,
            height: AppSizes.stepDisc,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kitchen.todayContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${step.position + 1}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(step.text, style: theme.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

/// Five tap targets, filled up to the current rating. Tapping the star that
/// already *is* the rating clears it back to unrated (decision 6) -- unrated
/// is `rating == null`, never zero.
///
/// It sits in the stat strip's fourth column. **A deliberate exception to the
/// 48dp target**: five stars cannot each be 48 wide inside a quarter of a
/// phone's width. Widening them would cost the column, and the column is what
/// stops the strip reflowing in Serbian.
///
/// Making that exception actually hold takes more than `padding: zero` and
/// `constraints: BoxConstraints()`. An M3 `IconButton` sizes itself from its
/// **style**, and `app_theme.dart`'s `iconButtonTheme` sets
/// `minimumSize: Size(target, target)` -- 48dp -- which those two widget-level
/// properties do not override. Phase 7 part 3's device walk found the result:
/// each star claimed ~44dp, five wanted ~220dp inside an ~86dp column, and
/// stars three through five sat off the right edge of the screen, unreachable.
/// Nobody could rate a recipe above 2. The stars had always been that wide;
/// before part 3 they had a full-width row to sprawl in, so it never showed.
///
/// So the style is overridden here: `minimumSize: Size.zero` plus
/// `tapTargetSize: shrinkWrap` makes each button exactly its icon, 16dp, and
/// five of them 80dp. The 48dp minimum stays right everywhere else in the app,
/// which is why this is a local override and not a theme change. The
/// [FittedBox] underneath is the backstop: 80dp fits a quarter column on any
/// phone down to about 340dp wide, and below that the row scales rather than
/// overflowing again.
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
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final KitchenColors kitchen = theme.extension<KitchenColors>()!;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        // Keyed so widget tests can scope to these five stars. The key
        // predates the heart -- it was there to keep them apart from the
        // AppBar's own favorite star -- and it still earns its place now that
        // the bar's icon is a heart, because the recipe cards behind a route
        // also carry stars.
        key: const Key('ratingStars'),
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(5, (int i) {
          final int star = i + 1;
          final bool filled = rating != null && star <= rating!;
          return IconButton(
            iconSize: AppSizes.iconInMeta,
            // See the class doc: the theme's 48dp minimum is what put three
            // of these five off the screen, and only the style overrides it.
            style: IconButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            tooltip: star == rating
                ? l10n.clearRatingTooltip
                : l10n.ratingStarsTooltip(star),
            icon: Icon(
              filled ? Icons.star : Icons.star_border,
              color: filled ? kitchen.rating : theme.colorScheme.outline,
            ),
            onPressed: () => onRate(star),
          );
        }),
      ),
    );
  }
}

