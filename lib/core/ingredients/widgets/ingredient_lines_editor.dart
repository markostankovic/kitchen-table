import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../recipes/widgets/recipe_group_heading.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/kitchen_colors.dart';
import '../../../features/ingredients/domain/ingredient_line_parser.dart';
import '../../../features/ingredients/domain/ingredient_match.dart';
import '../../../features/ingredients/domain/unit_catalog.dart';
import '../../../features/recipes/domain/recipe_draft.dart';
import '../ingredient_catalog_providers.dart';
import 'ingredient_line_field.dart';
import 'ingredient_line_row.dart';
import 'ingredient_suggestion_pill.dart';
import 'quantity_format.dart';

/// A recipe's ingredient lines, being edited: read-only rows that open one at
/// a time into [IngredientLineField] (D123, D157).
///
/// Shared by the recipe editor and import review, which is why it lives in
/// the `core/ingredients/` middle ground (D43, D53). It takes primitives and
/// callbacks, as [IngredientLineRow] does, and owns only which line is open.
///
/// * **Rows.** Each closed line is the shared row, read like the recipe it
///   will become. [review] is import review's style: every row inset, no
///   grip (long-press drags), and a trailer that leads with `→ <catalog
///   name>` or the not-matched words (D142). Otherwise it is the editor's: a
///   grip on every row, no inset, and a trailer of the note only.
/// * **Sections** show read-only, as a heading over each run of lines with
///   the same `section` (D156). The heading rides inside its first line's
///   child, so the list's indices stay line indices.
/// * **Fast entry** (D159). Next on a line commits it and opens a blank one
///   under it, in the same section; Next on a blank line closes it. Backspace
///   on an empty line removes it and opens the one above. There is no Done:
///   a line closes when another opens, on Next, or on ✕, and a blank line
///   that closes is removed -- unless it is the only line.
/// * **The pill** (D160). An unmatched closed row searches its name once and
///   offers the top candidate; tapping it confirms. A closed row never
///   auto-accepts, so opening a saved recipe changes nothing. A matched row
///   never searches.
class IngredientLinesEditor extends StatefulWidget {
  const IngredientLinesEditor({
    required this.lines,
    required this.locale,
    required this.units,
    required this.parser,
    required this.onReplace,
    required this.onRemove,
    required this.onReorder,
    required this.onInsertAfter,
    required this.onAdd,
    this.review = false,
    this.flagged = const <int>{},
    super.key,
  });

  final List<RecipeDraftLine> lines;

  /// The recipe's language: units are spelled in it, and it is the search
  /// locale (D86).
  final String locale;

  final UnitCatalog? units;
  final IngredientLineParser? parser;

  final ValueChanged<RecipeDraftLine> onReplace;
  final ValueChanged<int> onRemove;

  /// `ReorderableListView.onReorderItem`'s indices, which are line indices.
  final void Function(int oldIndex, int newIndex) onReorder;

  /// Inserts a blank line after the given one and returns the new line's id.
  final int Function(int localId) onInsertAfter;

  /// Appends a blank line and returns its id.
  final int Function() onAdd;

  /// Import review's row style. See the class doc.
  final bool review;

  /// Lines a human still has to look at (import review only), by `localId`.
  final Set<int> flagged;

  @override
  State<IngredientLinesEditor> createState() => _IngredientLinesEditorState();
}

class _IngredientLinesEditorState extends State<IngredientLinesEditor> {
  /// The one open line, if any. A single id is what keeps it to one at a
  /// time: opening a line closes the last.
  int? _openLineId;

  /// The line to focus when it builds open. Set with every open, so a line
  /// opened by a person takes the keyboard; left null on screen load.
  int? _focusLineId;

  /// Opens [localId], or closes the open line when null.
  ///
  /// Every other blank line closes with it and is removed, unless that would
  /// leave the list empty. That one rule covers Next on a blank line,
  /// Backspace on an empty one (the line above opens, the empty one goes),
  /// and a blank left behind by tapping elsewhere.
  void _open(int? localId) {
    int remaining = widget.lines.length;
    // A line just added by the caller is not in `widget.lines` yet.
    if (localId != null &&
        !widget.lines.any((RecipeDraftLine l) => l.localId == localId)) {
      remaining++;
    }
    for (final RecipeDraftLine line in widget.lines) {
      if (line.localId == localId || line.rawText.trim().isNotEmpty) continue;
      if (remaining <= 1) break;
      widget.onRemove(line.localId);
      remaining--;
    }
    setState(() {
      _openLineId = localId;
      _focusLineId = localId;
    });
  }

  void _submitted(RecipeDraftLine line, String text) {
    if (text.trim().isNotEmpty) {
      _open(widget.onInsertAfter(line.localId));
      return;
    }
    // Next on a blank line ends the burst. The only line stays, unfocused.
    if (widget.lines.length <= 1) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
    _open(null);
  }

  void _backspaceWhenEmpty(int index) {
    if (index == 0) return;
    _open(widget.lines[index - 1].localId);
  }

  void _remove(int localId) {
    widget.onRemove(localId);
    if (_openLineId == localId) setState(() => _openLineId = null);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<RecipeDraftLine> lines = widget.lines;

    // D156, as on the recipe detail's ingredient list.
    String? sectionAt(int i) {
      if (i < 0 || i >= lines.length) return null;
      final String? section = lines[i].section?.trim();
      return section == null || section.isEmpty ? null : section;
    }

    bool startsGroup(int i) =>
        sectionAt(i) != null && sectionAt(i) != sectionAt(i - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // IngredientLineField emits a ReorderableDragStartListener, so it
        // asserts outside a ReorderableListView, and every row supplies its
        // own handle, so the default ones are off. The list sits inside the
        // screen's own scroll view.
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: widget.onReorder,
          children: <Widget>[
            for (final (int index, RecipeDraftLine line) in lines.indexed)
              Column(
                key: ValueKey<int>(line.localId),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (startsGroup(index))
                    Padding(
                      // Lined up with the row text: past the grip in the
                      // editor, the rows' `md` inset in review. The heading's
                      // grip belongs to the next slice.
                      padding: EdgeInsets.only(
                        left: widget.review
                            ? AppSpacing.md
                            : AppSizes.grip + AppSpacing.xs,
                      ),
                      child: RecipeGroupHeading(
                        text: line.section!,
                        // `AppSectionHeading` already ends in `sm`; a line
                        // above already ends in its own `sm` padding.
                        top: index == 0 ? AppSpacing.xs : AppSpacing.xl,
                        bottom: AppSpacing.xs,
                      ),
                    ),
                  // A blank line has nothing to read, so it is always open.
                  if (line.localId == _openLineId ||
                      line.rawText.trim().isEmpty)
                    IngredientLineField(
                      index: index,
                      line: line,
                      locale: widget.locale,
                      autofocus: line.localId == _focusLineId,
                      onChanged: widget.onReplace,
                      onRemove: () => _remove(line.localId),
                      onSubmitted: (String text) => _submitted(line, text),
                      onBackspaceWhenEmpty: () => _backspaceWhenEmpty(index),
                      onFocused: () {
                        if (_openLineId != line.localId) _open(line.localId);
                      },
                    )
                  else
                    _closedRow(
                      index,
                      line,
                      l10n,
                      showDivider:
                          index != lines.length - 1 && !startsGroup(index + 1),
                    ),
                ],
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _open(widget.onAdd()),
            icon: const Icon(Icons.add),
            label: Text(l10n.addIngredientButton),
          ),
        ),
      ],
    );
  }

  Widget _closedRow(
    int index,
    RecipeDraftLine line,
    AppLocalizations l10n, {
    required bool showDivider,
  }) {
    final Widget row = _ClosedLine(
      line: line,
      locale: widget.locale,
      units: widget.units,
      parser: widget.parser,
      review: widget.review,
      isFlagged: widget.review && widget.flagged.contains(line.localId),
      showDivider: showDivider,
      onTap: () => _open(line.localId),
      onChanged: widget.onReplace,
    );

    if (widget.review) {
      return ReorderableDelayedDragStartListener(index: index, child: row);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReorderableDragStartListener(
          index: index,
          child: Padding(
            // Top-aligned to the first text line: the row's own `sm`.
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              right: AppSpacing.xs,
            ),
            child: Icon(
              Icons.drag_indicator,
              key: const Key('ingredientLineGrip'),
              size: AppSizes.grip,
              color: Theme.of(context).extension<KitchenColors>()!.dragHandle,
            ),
          ),
        ),
        Expanded(child: row),
      ],
    );
  }
}

/// One closed line: the shared row, and the pill under it when the line is
/// unmatched and the search has a candidate.
///
/// `recipe_detail_screen`'s `_ingredientRow`, with three differences. The
/// unit is spelled in the **recipe's** locale, because this is the source
/// being edited, not a reading. The name is the local parse of the raw text,
/// since a draft line has no resolved name. And in review, a matched line's
/// trailer leads with `→ <catalog name>`, which is what the cook is there to
/// check.
class _ClosedLine extends ConsumerWidget {
  const _ClosedLine({
    required this.line,
    required this.locale,
    required this.units,
    required this.parser,
    required this.review,
    required this.isFlagged,
    required this.showDivider,
    required this.onTap,
    required this.onChanged,
  });

  final RecipeDraftLine line;
  final String locale;
  final UnitCatalog? units;
  final IngredientLineParser? parser;
  final bool review;
  final bool isFlagged;
  final bool showDivider;
  final VoidCallback onTap;
  final ValueChanged<RecipeDraftLine> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? parsedName = units == null
        ? null
        : parser?.parse(line.rawText).name;
    // Rule 3: with no usable parse, the whole line shows as typed, with no
    // quantity or unit beside it to double up.
    final bool whole = parsedName == null || parsedName.trim().isEmpty;

    // Searched once, with no debounce -- the text is not changing -- and only
    // for an unmatched line. Offered, never applied (D160).
    final String searchName = ingredientSearchName(line.rawText, parser);
    final IngredientMatch? suggestion =
        line.isMatched || searchName.isEmpty
        ? null
        : ref
              .watch(ingredientMatchesProvider(searchName, locale: locale))
              .value
              ?.firstOrNull;

    final String trailer = <String>[
      if (review && line.isMatched && line.displayName != null)
        '→ ${line.displayName}',
      // The ring's tooltip string doubles as the unmatched line's trailer.
      if (review && !line.isMatched) l10n.ingredientNotMatchedTooltip,
      if (line.note != null) line.note!,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          onTap: onTap,
          child: IngredientLineRow(
            quantity: whole || line.quantity == null
                ? null
                : formatQuantity(line.quantity!),
            unit: whole || line.unitCode == null
                ? null
                : units!.displayName(line.unitCode!, locale: locale),
            name: whole ? line.rawText : parsedName,
            // The parser moves the optional marker into the note, so a line
            // with a note already says it; the inline `opciono` is for one
            // without.
            optionalLabel: line.isOptional && line.note == null
                ? l10n.ingredientOptionalTrailer
                : null,
            trailer: trailer.isEmpty ? null : trailer,
            isMatched: line.isMatched,
            isFlagged: isFlagged,
            inset: review,
            unmatchedTooltip: l10n.ingredientNotMatchedTooltip,
            // The pill belongs to its line, so it sits above the dashes.
            showDivider: showDivider && suggestion == null,
          ),
        ),
        if (suggestion != null) ...<Widget>[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: review ? AppSpacing.md : 0,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: IngredientSuggestionPill(
                name: suggestion.displayName,
                onConfirm: () => unawaited(
                  confirmIngredientMatch(
                    ref: ref,
                    context: context,
                    line: line,
                    match: suggestion,
                    typedName: searchName,
                    locale: locale,
                    onChanged: onChanged,
                  ),
                ),
              ),
            ),
          ),
          if (showDivider) IngredientLineDivider(inset: review),
        ],
      ],
    );
  }
}
