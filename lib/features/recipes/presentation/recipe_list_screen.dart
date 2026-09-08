import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final AsyncValue<List<Recipe>> recipes =
        ref.watch(recipeListProvider(query: _query));

    return Scaffold(
      appBar: AppBar(title: const Text('Recipes')),
      // A menu rather than a single action, because there is now more than one
      // way to get a recipe in. `import-url` and `import-photo` are the rest
      // of Phase 1d and hang here beside Paste without another redesign.
      floatingActionButton: MenuAnchor(
        builder: (BuildContext context, MenuController controller, Widget? _) =>
            FloatingActionButton(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          tooltip: 'Add a recipe',
          child: const Icon(Icons.add),
        ),
        menuChildren: <Widget>[
          MenuItemButton(
            leadingIcon: const Icon(Icons.edit_outlined),
            onPressed: () => const RecipeNewRoute().go(context),
            child: const Text('New recipe'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.content_paste_outlined),
            onPressed: () => const ImportPasteRoute().go(context),
            child: const Text('Paste a recipe'),
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
                hintText: 'Search recipes',
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
                  child: Text('Could not load your recipes.\n\n$e',
                      textAlign: TextAlign.center),
                ),
              ),
              data: (List<Recipe> items) => items.isEmpty
                  ? _EmptyState(searching: _query.isNotEmpty)
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(recipeListProvider(query: _query)),
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (BuildContext context, int i) =>
                            _RecipeTile(recipe: items[i]),
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
  const _RecipeTile({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    final List<String> meta = <String>[
      if (recipe.servings != null) '${recipe.servings} servings',
      if (recipe.prepMinutes != null) '${recipe.prepMinutes} min prep',
      if (recipe.cookMinutes != null) '${recipe.cookMinutes} min cook',
    ];

    return ListTile(
      title: Text(recipe.title),
      subtitle: meta.isEmpty ? null : Text(meta.join(' · ')),
      // A draft is a recipe nobody has vouched for yet -- the standing rule
      // that keeps AI-produced recipes marked applies to hand-entered ones too.
      trailing: recipe.status == RecipeStatus.draft
          ? const Chip(label: Text('Draft'))
          : null,
      onTap: () => RecipeDetailRoute(recipe.id).go(context),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            searching
                ? 'No recipes match that.'
                : 'No recipes yet.\n\nAdd one you know by heart.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
}
