import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../error/failure_l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/app_error_view.dart';
import '../../../features/ingredients/domain/ingredient_match.dart';
import '../ingredient_catalog_providers.dart';

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
    // The recipe's own language, not the reader's chrome locale -- this
    // sheet is opened from the match chip, which already follows that rule
    // (ingredient_line_field.dart, ingredient_match_chip.dart).
    final AppLocalizations sheetL10n = lookupAppLocalizations(Locale(locale));

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
                sheetL10n.ingredientPickerQuestion(query),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: matches.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (Object e, _) => AppErrorView(
                    message:
                        localizedErrorMessage(e, AppLocalizations.of(context))),
                data: (List<IngredientMatch> found) => found.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                        child: Text(sheetL10n.ingredientPickerNoMatches),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: <Widget>[
                          for (final IngredientMatch match in found)
                            _MatchTile(match: match, l10n: sheetL10n),
                        ],
                      ),
              ),
            ),
            const Divider(height: 1),
            // Always last, and always present: "create new" is the escape
            // hatch that keeps an unusual ingredient from blocking a save.
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(sheetL10n.ingredientPickerCreateNew(query)),
              subtitle: Text(sheetL10n.ingredientPickerCreateNewSubtitle),
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
  const _MatchTile({required this.match, required this.l10n});

  final IngredientMatch match;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // The spelling that matched is worth showing when it is not the name being
    // offered: it is the answer to "why is this in the list", and it is often
    // the other language or an inflected form.
    final bool matchedByAnotherName = match.matchedName != match.displayName;

    return ListTile(
      title: Text(match.displayName),
      subtitle: matchedByAnotherName
          ? Text(l10n.ingredientPickerMatchedByAlias(match.matchedName))
          : null,
      trailing: match.isVerified
          ? null
          : Tooltip(
              message: l10n.ingredientPickerUnverifiedTooltip,
              child: const Icon(Icons.help_outline, size: 18),
            ),
      onTap: () => Navigator.of(context).pop(ChooseExisting(match)),
    );
  }
}
