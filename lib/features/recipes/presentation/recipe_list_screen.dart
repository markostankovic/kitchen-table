import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../application/recipe_providers.dart';
import '../domain/recipe.dart';
import '../domain/recipe_tag.dart';

/// The household's recipes, searchable by title.
///
/// Search runs against `title_normalized`, so diacritics and case do not
/// matter: `Šargarepa`, `sargarepa` and `ШАРГАРЕПА` all find the same recipe.
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchRecipesHint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          _onQueryChanged('');
                        },
                      ),
              ),
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
              error: (Object e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(localizedErrorMessage(e, l10n),
                      textAlign: TextAlign.center),
                ),
              ),
              data: (List<Recipe> items) => items.isEmpty
                  ? _EmptyState(
                      narrowed: _query.isNotEmpty ||
                          _tag.isNotEmpty ||
                          _favoritesOnly,
                      l10n: l10n,
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
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int i) =>
                            _RecipeTile(recipe: items[i], l10n: l10n),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe, required this.l10n});

  final Recipe recipe;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final List<String> meta = <String>[
      if (recipe.servings != null) l10n.recipeServingsCount(recipe.servings!),
      if (recipe.prepMinutes != null)
        l10n.recipePrepMinutes(recipe.prepMinutes!),
      if (recipe.cookMinutes != null)
        l10n.recipeCookMinutes(recipe.cookMinutes!),
      if (recipe.rating != null) '★ ${recipe.rating}',
    ];

    // Display-only (decision 5): no in-place toggle here, favoriting and
    // rating both happen on the detail screen.
    final List<Widget> trailingChildren = <Widget>[
      if (recipe.isFavorite) const Icon(Icons.star, size: 20),
      if (recipe.status == RecipeStatus.draft)
        Chip(label: Text(l10n.draftChipLabel)),
    ];

    return ListTile(
      leading: recipe.imageUrl == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                recipe.imageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                // A stale or since-invalidated signed URL falls back to no
                // thumbnail rather than a broken-image icon in every row.
                errorBuilder: (_, _, _) => const SizedBox(width: 56),
              ),
            ),
      title: Text(recipe.title),
      subtitle: meta.isEmpty ? null : Text(meta.join(' · ')),
      // A draft is a recipe nobody has vouched for yet -- the standing rule
      // that keeps AI-produced recipes marked applies to hand-entered ones too.
      trailing: trailingChildren.isEmpty
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < trailingChildren.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 4),
                  trailingChildren[i],
                ],
              ],
            ),
      onTap: () => RecipeDetailRoute(recipe.id).go(context),
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

    // The selected tag may have fallen out of the vocabulary (its last
    // recipe was deleted) -- still show a chip for it, labelled with the
    // key, so the filter is never a dead end.
    final List<RecipeTag> chips = selectedTag.isEmpty ||
            vocabulary.any((RecipeTag t) => t.key == selectedTag)
        ? vocabulary
        : <RecipeTag>[
            ...vocabulary,
            RecipeTag(key: selectedTag, label: selectedTag),
          ]..sort((RecipeTag a, RecipeTag b) => a.key.compareTo(b.key));

    if (chips.isEmpty && !favoritesOnly) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            FilterChip(
              avatar: const Icon(Icons.star, size: 18),
              label: Text(l10n.favoritesFilterLabel),
              selected: favoritesOnly,
              onSelected: (_) => onFavoritesTap(),
            ),
            for (final RecipeTag tag in chips) ...<Widget>[
              const SizedBox(width: 8),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.narrowed, required this.l10n});

  final bool narrowed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            narrowed ? l10n.noRecipesMatch : l10n.noRecipesYet,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
}
