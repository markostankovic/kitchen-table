import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ingredients/domain/ingredient_match.dart';
import '../../application/recipe_providers.dart';

/// What the cook decided about one ingredient line.
///
/// The sheet performs no writes of its own -- it returns the decision and the
/// line field acts on it, so the alias write-back and the catalog insert stay
/// in one place next to the line they belong to.
sealed class IngredientChoice {
  const IngredientChoice();
}

/// An existing catalog ingredient, picked from the ranked list.
class ChooseExisting extends IngredientChoice {
  const ChooseExisting(this.match);

  final IngredientMatch match;
}

/// Nothing in the catalog fits, so make one.
class ChooseNew extends IngredientChoice {
  const ChooseNew(this.name);

  final String name;
}

/// Asks the cook which ingredient a line means.
///
/// Opened from the chip under a line, which is the confirm step D8 requires
/// expressed for manual entry: the machine's guess is a suggestion until a
/// human says otherwise, and saying otherwise is what writes an alias.
Future<IngredientChoice?> showIngredientPicker(
  BuildContext context, {
  required String query,
  required String locale,
}) =>
    showModalBottomSheet<IngredientChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) =>
          _IngredientPickerSheet(query: query, locale: locale),
    );

class _IngredientPickerSheet extends ConsumerWidget {
  const _IngredientPickerSheet({required this.query, required this.locale});

  final String query;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<IngredientMatch>> matches =
        ref.watch(ingredientMatchesProvider(query, locale: locale));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Which ingredient is “$query”?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: matches.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not search the catalog.\n\n$e'),
                ),
                data: (List<IngredientMatch> found) => found.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
                        child: Text('Nothing in the catalog matches.'),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          for (final IngredientMatch match in found)
                            _MatchTile(match: match),
                        ],
                      ),
              ),
            ),
            const Divider(height: 1),
            // Always last, and always present: "create new" is the escape
            // hatch that keeps an unusual ingredient from blocking a save.
            ListTile(
              leading: const Icon(Icons.add),
              title: Text('Create “$query”'),
              subtitle: const Text('Adds it to the catalog for the household'),
              onTap: () => Navigator.of(context).pop(ChooseNew(query)),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});

  final IngredientMatch match;

  @override
  Widget build(BuildContext context) {
    // The spelling that matched is worth showing when it is not the name being
    // offered: it is the answer to "why is this in the list", and it is often
    // the other language or an inflected form.
    final bool matchedByAnotherName = match.matchedName != match.displayName;

    return ListTile(
      title: Text(match.displayName),
      subtitle: matchedByAnotherName ? Text('matched “${match.matchedName}”') : null,
      trailing: match.isVerified
          ? null
          : const Tooltip(
              message: 'Added by someone, not from the curated list',
              child: Icon(Icons.help_outline, size: 18),
            ),
      onTap: () => Navigator.of(context).pop(ChooseExisting(match)),
    );
  }
}
