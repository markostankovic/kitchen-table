import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../application/recipe_providers.dart';
import '../domain/recipe.dart';

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

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Recipe>> recipes =
        ref.watch(recipeListProvider(query: _query));

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
                  ? _EmptyState(searching: _query.isNotEmpty, l10n: l10n)
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(recipeListProvider(query: _query)),
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
      trailing: recipe.status == RecipeStatus.draft
          ? Chip(label: Text(l10n.draftChipLabel))
          : null,
      onTap: () => RecipeDetailRoute(recipe.id).go(context),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching, required this.l10n});

  final bool searching;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            searching ? l10n.noRecipesMatch : l10n.noRecipesYet,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
}
