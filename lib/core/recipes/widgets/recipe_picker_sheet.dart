import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../error/failure_l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_error_view.dart';
import '../../widgets/app_search_field.dart';
import '../../../features/recipes/domain/recipe.dart';
import '../recipe_picker_providers.dart';
import 'recipe_card.dart';

/// What the cook decided to put in a slot.
///
/// The sheet performs no writes of its own -- it returns the decision and the
/// week grid acts on it, the same split `showIngredientPicker` uses.
sealed class RecipePick {
  const RecipePick();
}

/// An existing recipe, picked from the search results.
class PickRecipe extends RecipePick {
  const PickRecipe(this.recipe);

  final Recipe recipe;
}

/// A free-text note instead of a recipe -- "leftovers", "eating out".
class PickNote extends RecipePick {
  const PickNote(this.note);

  final String note;
}

/// Asks the cook what goes in one slot: a recipe, or a note.
///
/// Opened by tapping an empty slot in the week grid.
Future<RecipePick?> showRecipePicker(BuildContext context) =>
    showModalBottomSheet<RecipePick>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => const _RecipePickerSheet(),
    );

class _RecipePickerSheet extends ConsumerStatefulWidget {
  const _RecipePickerSheet();

  @override
  ConsumerState<_RecipePickerSheet> createState() =>
      _RecipePickerSheetState();
}

class _RecipePickerSheetState extends ConsumerState<_RecipePickerSheet> {
  final TextEditingController _search = TextEditingController();
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

  Future<void> _addNote() async {
    final String? note = await _promptForNote(context);
    if (note == null || !mounted) return;
    Navigator.of(context).pop(PickNote(note));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<List<Recipe>> recipes =
        ref.watch(plannableRecipesProvider(query: _query));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: AppSearchField(
                controller: _search,
                hintText: l10n.searchRecipesHint,
                onChanged: _onQueryChanged,
                autofocus: true,
              ),
            ),
            Flexible(
              child: recipes.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object e, _) =>
                    AppErrorView(message: localizedErrorMessage(e, l10n)),
                data: (List<Recipe> found) => found.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.sm,
                          AppSpacing.xl,
                          AppSpacing.sm,
                        ),
                        child: Text(l10n.noRecipesMatch),
                      )
                    // The same card the recipe list shows, which is what
                    // makes `RecipeCard`'s home in `core/recipes/` true
                    // today rather than on a promise (D43, D53).
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        itemCount: found.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (BuildContext context, int i) =>
                            RecipeCard(
                              recipe: found[i],
                              l10n: l10n,
                              onTap: () => Navigator.of(context)
                                  .pop(PickRecipe(found[i])),
                            ),
                      ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_note_outlined),
              title: Text(l10n.addNoteInsteadMenuItem),
              subtitle: Text(l10n.addNoteInsteadSubtitle),
              onTap: _addNote,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

Future<String?> _promptForNote(BuildContext context) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  final TextEditingController controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(l10n.addNoteDialogTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.addNoteHint),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () {
            final String text = controller.text.trim();
            Navigator.of(context).pop(text.isEmpty ? null : text);
          },
          child: Text(l10n.addButton),
        ),
      ],
    ),
  );
}
