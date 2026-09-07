import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ingredients/domain/unit_catalog.dart';
import '../application/recipe_providers.dart';
import '../domain/recipe.dart';
import '../domain/recipe_detail.dart';
import '../domain/recipe_ingredient.dart';
import '../domain/recipe_step.dart';
import 'widgets/quantity_format.dart';

/// One recipe, read-only.
///
/// The ingredient list is the part that matters. A matched line renders the
/// *catalog's* name for the ingredient in the reader's locale rather than the
/// words the cook typed -- that hop is D1, and it is what will later let one
/// shopping list say `brašno` for a recipe written in Serbian and one written
/// in English. A line that matched nothing renders exactly what was typed,
/// which is rule 3 and a perfectly good outcome, not a degraded one.
class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<RecipeDetail> detail =
        ref.watch(recipeDetailProvider(recipeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(detail.value?.recipe.title ?? 'Recipe'),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not load this recipe.\n\n$e',
                textAlign: TextAlign.center),
          ),
        ),
        data: (RecipeDetail d) => _Body(detail: d),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.detail});

  final RecipeDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Recipe recipe = detail.recipe;

    // The lexicon is already cached for the session, so this rarely suspends.
    // Until it arrives, lines render with the unit code instead of its
    // Serbian spelling -- readable, and better than withholding the recipe.
    final UnitCatalog units =
        ref.watch(recipeUnitCatalogProvider).value ?? UnitCatalog.empty();

    final List<String> meta = <String>[
      if (recipe.servings != null) '${recipe.servings} servings',
      if (recipe.prepMinutes != null) '${recipe.prepMinutes} min prep',
      if (recipe.cookMinutes != null) '${recipe.cookMinutes} min cook',
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        if (recipe.status == RecipeStatus.draft)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text('Draft')),
            ),
          ),
        if (meta.isNotEmpty)
          Text(meta.join(' · '), style: Theme.of(context).textTheme.bodySmall),
        if (recipe.description != null && recipe.description!.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(recipe.description!),
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
        _SectionHeading(text: 'Ingredients'),
        if (detail.ingredients.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No ingredients yet.'),
          )
        else
          ...detail.ingredients.map(
            (RecipeIngredient line) =>
                _IngredientRow(line: line, units: units, recipe: recipe),
          ),
        const SizedBox(height: 24),
        _SectionHeading(text: 'Steps'),
        if (detail.steps.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No steps yet.'),
          )
        else
          ...detail.steps.map((RecipeStep step) => _StepRow(step: step)),
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
    required this.recipe,
  });

  final RecipeIngredient line;
  final UnitCatalog units;
  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    // The measured half of the line, assembled from the structured columns.
    // Empty whenever the parse found no quantity, which is normal.
    final String amount = <String>[
      if (line.quantity != null) formatQuantity(line.quantity!),
      if (line.unitCode != null)
        units.displayName(line.unitCode!, locale: recipe.originalLocale),
    ].join(' ');

    final String trailer = <String>[
      if (line.note != null) line.note!,
      if (line.isOptional && line.note == null) 'optional',
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
              message: 'Not matched to an ingredient',
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

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
