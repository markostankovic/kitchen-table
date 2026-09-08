import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/text/text_normalizer.dart';
import '../../../ingredients/domain/ingredient_line_parser.dart';
import '../../../ingredients/domain/ingredient_match.dart';
import '../../../ingredients/domain/parsed_ingredient_line.dart';
import '../../../ingredients/domain/unit.dart';
import '../../../ingredients/domain/unit_catalog.dart';
import '../../application/recipe_providers.dart';
import '../../domain/recipe_draft.dart';
import 'ingredient_match_chip.dart';
import 'ingredient_picker_sheet.dart';

/// One ingredient line: the text the cook typed, and what the app made of it.
///
/// The three tiers, in the three places D31 put them:
///
/// 1. [IngredientLineParser] runs locally on every keystroke. It is pure
///    string work over the unit lexicon, so a round trip would buy nothing and
///    cost the responsiveness this field exists to have.
/// 2. The parsed name is debounced into `search_ingredients` -- tiers 2 and 3,
///    one RPC.
/// 3. A row is adopted automatically only when the server said `auto_accept`.
///    The threshold behind that flag stays in SQL.
///
/// Editing the quantity or the note of a matched line leaves the match alone;
/// editing the *name* clears it, because it is no longer a decision about the
/// word that is there now.
class IngredientLineField extends ConsumerStatefulWidget {
  const IngredientLineField({
    required this.index,
    required this.line,
    required this.locale,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final RecipeDraftLine line;

  /// The recipe's language, which is both the search locale and the locale a
  /// newly created ingredient is named in.
  final String locale;

  final ValueChanged<RecipeDraftLine> onChanged;
  final VoidCallback onRemove;

  @override
  ConsumerState<IngredientLineField> createState() =>
      _IngredientLineFieldState();
}

class _IngredientLineFieldState extends ConsumerState<IngredientLineField> {
  Timer? _debounce;

  /// The term currently being searched.
  ///
  /// Deliberately empty until the cook types. Opening a recipe with fifteen
  /// saved lines would otherwise fire fifteen searches for rows that are
  /// already matched, and the picker does not need it -- it takes the parsed
  /// name directly when it opens.
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final IngredientLineParser? parser =
        ref.watch(recipeLineParserProvider).value;
    final UnitCatalog units =
        ref.watch(recipeUnitCatalogProvider).value ?? UnitCatalog.empty();

    final AsyncValue<List<IngredientMatch>> matches =
        ref.watch(ingredientMatchesProvider(_query, locale: widget.locale));

    ref.listen(
      ingredientMatchesProvider(_query, locale: widget.locale),
      (AsyncValue<List<IngredientMatch>>? _,
              AsyncValue<List<IngredientMatch>> next) =>
          _maybeAutoAccept(next.value),
    );

    final List<IngredientMatch> found = matches.value ?? const <IngredientMatch>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              ReorderableDragStartListener(
                index: widget.index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.drag_handle),
                ),
              ),
              Expanded(
                child: TextFormField(
                  initialValue: widget.line.rawText,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: '2 šolje glatkog brašna',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (String value) => _onTextChanged(value, parser),
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.close),
                onPressed: widget.onRemove,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 2),
            child: IngredientMatchChip(
              line: widget.line,
              units: units,
              locale: widget.locale,
              suggestion: widget.line.isMatched || found.isEmpty
                  ? null
                  : found.first,
              onTap: () => unawaited(_openPicker(parser)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Typing
  // ---------------------------------------------------------------------

  void _onTextChanged(String value, IngredientLineParser? parser) {
    RecipeDraftLine next = widget.line.copyWith(rawText: value);

    if (parser != null) {
      final ParsedIngredientLine parsed = parser.parse(value);
      final ParsedIngredientLine previous = parser.parse(widget.line.rawText);

      next = next.copyWith(
        quantity: parsed.quantity,
        unitCode: parsed.unitCode,
        note: parsed.note,
        isOptional: parsed.isOptional,
      );

      // The match is a decision about a word. Changing the quantity or the
      // note leaves that word alone and the decision stands -- including a
      // manual one, which is the whole point of D7. Changing the word itself
      // retires it, human or not: it is no longer an answer to what is there.
      if (parsed.name != previous.name) {
        next = next.copyWith(
          ingredientId: null,
          displayName: null,
          matchMethod: null,
          matchConfidence: null,
          matchedAt: null,
        );
      }

      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        setState(() => _query = parsed.name ?? '');
      });
    }

    widget.onChanged(next);
  }

  /// Adopts the top row, but only when the server flagged it `auto_accept`.
  void _maybeAutoAccept(List<IngredientMatch>? found) {
    if (found == null || found.isEmpty) return;
    // Already answered -- by an earlier pass or by a person. Never overwrite
    // a decision that is already there.
    if (widget.line.isMatched) return;

    final IngredientMatch top = found.first;
    if (!top.autoAccept) return;

    widget.onChanged(widget.line.copyWith(
      ingredientId: top.ingredientId,
      displayName: top.displayName,
      // The method the search reported, not `manual`: nobody confirmed this.
      matchMethod: top.matchMethod,
      matchConfidence: top.confidence,
      matchedAt: DateTime.now(),
    ));
  }

  // ---------------------------------------------------------------------
  // The human decision, and its write-back
  // ---------------------------------------------------------------------

  Future<void> _openPicker(IngredientLineParser? parser) async {
    final String name = _parsedName(parser);
    if (name.isEmpty) return;

    final IngredientChoice? choice = await showIngredientPicker(
      context,
      query: name,
      locale: widget.locale,
    );
    if (choice == null || !mounted) return;

    switch (choice) {
      case ChooseExisting(match: final IngredientMatch match):
        _applyManual(
          ingredientId: match.ingredientId,
          displayName: match.displayName,
        );
        await _writeBackAlias(match, name);
      case ChooseNew(name: final String newName):
        await _createIngredient(newName);
    }
  }

  /// A picked or created ingredient is a human decision (D7): `manual`, full
  /// confidence, and never overwritten by a later machine pass.
  void _applyManual({
    required String ingredientId,
    required String displayName,
  }) {
    widget.onChanged(widget.line.copyWith(
      ingredientId: ingredientId,
      displayName: displayName,
      matchMethod: MatchMethod.manual,
      matchConfidence: 1,
      matchedAt: DateTime.now(),
    ));
  }

  /// Teaches the catalog the words this household actually uses (D8).
  ///
  /// Skipped when the string that matched already is the string typed --
  /// `link_ingredient_alias` would return the row unchanged, so the round trip
  /// buys nothing. When the alias is already taken by a different ingredient
  /// the RPC returns false rather than raising, and that is not an error worth
  /// telling anyone about: the line still saves, only the global write-back is
  /// declined.
  Future<void> _writeBackAlias(IngredientMatch match, String name) async {
    if (TextNormalizer.normalize(match.matchedName) ==
        TextNormalizer.normalize(name)) {
      return;
    }

    try {
      await ref
          .read(ingredientCatalogDatasourceProvider)
          .linkAlias(match.ingredientId, name, locale: widget.locale);
    } on AppFailure catch (e) {
      _report(e.message);
    }
  }

  Future<void> _createIngredient(String name) async {
    // A unit on the line is the best evidence available for what family the
    // new ingredient is measured in. `other` is not a legal argument, and the
    // datasource already maps it to null.
    final UnitCatalog units =
        ref.read(recipeUnitCatalogProvider).value ?? UnitCatalog.empty();
    final String? unitCode = widget.line.unitCode;
    final UnitFamily? family =
        unitCode == null ? null : units.byCode(unitCode)?.family;

    try {
      final String ingredientId = await ref
          .read(ingredientCatalogDatasourceProvider)
          .createIngredient(name, locale: widget.locale, unitFamily: family);
      if (!mounted) return;
      _applyManual(ingredientId: ingredientId, displayName: name);
    } on AppFailure catch (e) {
      _report(e.message);
    }
  }

  String _parsedName(IngredientLineParser? parser) {
    final String rawText = widget.line.rawText;
    if (parser == null) return rawText.trim();
    return parser.parse(rawText).name?.trim() ?? rawText.trim();
  }

  /// The line is already saved either way, so a failed write-back is reported
  /// and dropped rather than turned into something the cook has to resolve.
  void _report(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
