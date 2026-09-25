import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/app_locale.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/recipes/widgets/recipe_card.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_search_field.dart';
import '../application/recipe_providers.dart';
import '../domain/recipe.dart';
import '../domain/recipe_tag.dart';

/// The household's recipes, searchable by title or tag.
///
/// Search is diacritic- and case-insensitive: `Šargarepa`, `sargarepa` and
/// `ШАРГАРЕПА` all find the same recipe, and typing any known spelling of a
/// tag -- the spelling on the recipe, or any locale's translated pair --
/// finds it too (Phase 6, part 2).
class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  final TextEditingController _search = TextEditingController();

  /// Debounced, because `recipeListProvider` is a family keyed on the query:
  /// watching it on every keystroke would issue a request per character and
  /// leave one cached provider behind for each prefix.
  Timer? _debounce;
  String _query = '';
  String _tag = '';
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  /// A chip tap is discrete, unlike typing (which mints a provider entry per
  /// keystroke prefix), so this calls `setState` directly -- no debounce.
  void _toggleTag(String key) {
    setState(() => _tag = _tag == key ? '' : key);
  }

  void _toggleFavoritesOnly() {
    setState(() => _favoritesOnly = !_favoritesOnly);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Recipe>> recipes = ref.watch(
      recipeListProvider(
        query: _query,
        tag: _tag,
        favoritesOnly: _favoritesOnly,
      ),
    );

    return Scaffold(
      // The title shares its ARB key with the nav label (D77, Phase 3 part 1)
      // so the tab and this AppBar never disagree about the language they are
      // in, even though the rest of this screen's content is still English.
      appBar: AppBar(title: Text(l10n.navRecipes)),
      // A menu rather than a single action, because there is now more than one
      // way to get a recipe in. `import-url` and `import-photo` are the rest
      // of Phase 1d and hang here beside Paste without another redesign.
      floatingActionButton: MenuAnchor(
        builder: (BuildContext context, MenuController controller, Widget? _) =>
            FloatingActionButton(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          tooltip: l10n.addRecipeTooltip,
          child: const Icon(Icons.add),
        ),
        menuChildren: <Widget>[
          MenuItemButton(
            leadingIcon: const Icon(Icons.edit_outlined),
            onPressed: () => const RecipeNewRoute().go(context),
            child: Text(l10n.newRecipeMenuItem),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.link_outlined),
            onPressed: () => const ImportUrlRoute().go(context),
            child: Text(l10n.importFromLinkMenuItem),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.content_paste_outlined),
            onPressed: () => const ImportPasteRoute().go(context),
            child: Text(l10n.pasteRecipeMenuItem),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.photo_camera_outlined),
            onPressed: () => const ImportPhotoRoute().go(context),
            child: Text(l10n.photographPageMenuItem),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: AppSearchField(
              controller: _search,
              hintText: l10n.searchRecipesHint,
              onChanged: _onQueryChanged,
            ),
          ),
          _FilterRow(
            selectedTag: _tag,
            favoritesOnly: _favoritesOnly,
            onTagTap: _toggleTag,
            onFavoritesTap: _toggleFavoritesOnly,
            l10n: l10n,
          ),
          Expanded(
            child: recipes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object e, _) =>
                  AppErrorView(message: localizedErrorMessage(e, l10n)),
              data: (List<Recipe> items) {
                final bool narrowed = _query.isNotEmpty ||
                    _tag.isNotEmpty ||
                    _favoritesOnly;
                return items.isEmpty
                    ? AppEmptyState(
                        icon: narrowed
                            ? Icons.search_off
                            : Icons.menu_book_outlined,
                        title: narrowed
                            ? l10n.noRecipesMatch
                            : l10n.noRecipesYet,
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(
                          recipeListProvider(
                            query: _query,
                            tag: _tag,
                            favoritesOnly: _favoritesOnly,
                          ),
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            0,
                            AppSpacing.lg,
                            AppSpacing.xxl,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (BuildContext context, int i) =>
                              RecipeCard(
                                recipe: items[i],
                                l10n: l10n,
                                onTap: () =>
                                    RecipeDetailRoute(items[i].id).go(context),
                              ),
                        ),
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The Favorites toggle plus one chip per tag in the household's vocabulary
/// (Phase 5, part 2). A horizontally scrolling row, not a `Wrap` -- a `Wrap`
/// would grow downward and eat the list below it.
class _FilterRow extends ConsumerWidget {
  const _FilterRow({
    required this.selectedTag,
    required this.favoritesOnly,
    required this.onTagTap,
    required this.onFavoritesTap,
    required this.l10n,
  });

  final String selectedTag;
  final bool favoritesOnly;
  final ValueChanged<String> onTagTap;
  final VoidCallback onFavoritesTap;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<RecipeTag> vocabulary = ref.watch(recipeTagsProvider);

    // Relabelled into the reader's own language before the "fell out of the
    // vocabulary" branch below, so a synthesised chip for a still-selected
    // but now-missing tag is translated too (Phase 6, part 1a). Degrading to
    // the as-typed label while the future is pending is intended, not a gap.
    final String locale = ref.watch(appLocaleProvider).languageCode;
    final Map<String, String> labels =
        ref.watch(tagLabelsProvider(locale)).value ?? const <String, String>{};
    final List<RecipeTag> labelled = RecipeTag.relabelled(vocabulary, labels);

    // The selected tag may have fallen out of the vocabulary (its last
    // recipe was deleted) -- still show a chip for it, labelled with the
    // key, so the filter is never a dead end.
    final List<RecipeTag> chips = selectedTag.isEmpty ||
            labelled.any((RecipeTag t) => t.key == selectedTag)
        ? labelled
        : <RecipeTag>[
            ...labelled,
            RecipeTag(key: selectedTag, label: selectedTag),
          ]..sort((RecipeTag a, RecipeTag b) => a.key.compareTo(b.key));

    // Bound to the unfiltered household list, not the tag vocabulary (Phase
    // 6, part 2, closing D102's open consequence): a household with recipes
    // but no tags yet would otherwise strand the Favorites chip with nowhere
    // to render. Zero recipes is still zero row. A filter already selected
    // keeps the row up even if the unfiltered list is momentarily
    // unavailable (still loading, say), so it never disappears out from
    // under a selection.
    final bool hasAnyRecipe =
        (ref.watch(recipeListProvider()).value ?? const <Recipe>[])
            .isNotEmpty;
    final bool filterActive = selectedTag.isNotEmpty || favoritesOnly;
    if (!hasAnyRecipe && !filterActive) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            // No star avatar. A star means a rating and nothing else after
            // Phase 7 part 3; selection already reads as `secondaryContainer`
            // plus a check, so the chip is its label alone, like the tags.
            FilterChip(
              label: Text(l10n.favoritesFilterLabel),
              selected: favoritesOnly,
              onSelected: (_) => onFavoritesTap(),
            ),
            for (final RecipeTag tag in chips) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              FilterChip(
                label: Text(tag.label),
                selected: tag.key == selectedTag,
                onSelected: (_) => onTagTap(tag.key),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

