import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../recipes/widgets/recipe_group_heading.dart';
import '../../theme/app_radii.dart';
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
import 'ingredient_list_layout.dart';
import 'ingredient_suggestion_pill.dart';
import 'quantity_format.dart';

/// A recipe's ingredient lines, being edited: read-only rows that open one at
/// a time into [IngredientLineField] (D123, D157).
///
/// Shared by the recipe editor and import review, which is why it lives in
/// the `core/ingredients/` middle ground (D43, D53). It takes primitives and
/// callbacks, as [IngredientLineRow] does, and owns only which thing is open.
///
/// * **Rows.** Each closed line is the shared row, read like the recipe it
///   will become. [review] is import review's style: every row inset, no
///   grip (long-press drags), and a trailer that leads with `→ <catalog
///   name>` or the not-matched words (D142). Otherwise it is the editor's: a
///   grip on every row, no inset, and a trailer of the note only.
/// * **Sections** (D156) head each run of lines with the same `section`.
///   A heading is its own child of the list ([ingredientListItems]), so a
///   line dropped between a heading and its first line joins that group; a
///   dropped line takes the section of the nearest heading above it. A
///   heading has a grip (long-press in review) and drags its whole run with
///   it, to a group boundary only ([resolveRunDrop]). Tapping a heading
///   opens it for renaming -- one thing open at a time, a line or a heading
///   -- and its ✕ joins its lines to the group above, with Undo. **Add
///   section** opens a heading over a new blank line.
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
    required this.onMoveLine,
    required this.onMoveRun,
    required this.onSetSections,
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

  /// A dropped line, in line indices as `onReorderItem` would give them for
  /// a list of lines alone, with the section it takes where it landed.
  final void Function(int oldIndex, int newIndex, String? section) onMoveLine;

  /// A dragged heading's run `[start, end)`, to sit before the line that is
  /// at [newIndex] now.
  final void Function(int start, int end, int newIndex) onMoveRun;

  /// Sets lines' sections by `localId`: a rename, a removal, or its Undo.
  final ValueChanged<Map<int, String?>> onSetSections;

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

  /// The open heading, by its first line's id -- never set together with
  /// [_openLineId]. It is passed to [ingredientListItems] so the heading
  /// stays one while its name is blank, or mid-word equal to the group
  /// above.
  int? _headingLineId;

  /// The open heading's run, by id, as it was when it opened: every
  /// keystroke writes these, and only these, so a name that passes through
  /// the next group's cannot swallow that group.
  List<int> _headingRun = const <int>[];

  /// The run's sections before the heading opened -- what Undo restores when
  /// a heading closes blank. All null for Add section's heading, which is
  /// how closing that one unnamed knows there is nothing to undo.
  Map<int, String?> _headingBefore = const <int, String?>{};

  /// The open heading's name as last typed. Kept here rather than read back
  /// from [IngredientLinesEditor.lines], which lags a frame behind a
  /// keystroke that Next follows at once.
  String? _headingName;

  /// The heading being dragged, whose run collapses while it is in the air.
  HeadingItem? _dragging;

  String? _sectionOf(int localId) {
    for (final RecipeDraftLine line in widget.lines) {
      if (line.localId == localId) return line.section;
    }
    return null;
  }

  static bool _blank(String? section) =>
      section == null || section.trim().isEmpty;

  /// Removes every blank line but [keep], unless that would leave the list
  /// empty. That one rule covers Next on a blank line, Backspace on an empty
  /// one (the line above opens, the empty one goes), and a blank left behind
  /// by tapping elsewhere.
  void _dropBlanks(Set<int> keep) {
    int remaining = widget.lines.length;
    // A line just added by the caller is not in `widget.lines` yet.
    for (final int id in keep) {
      if (!widget.lines.any((RecipeDraftLine l) => l.localId == id)) {
        remaining++;
      }
    }
    for (final RecipeDraftLine line in widget.lines) {
      if (keep.contains(line.localId) || line.rawText.trim().isNotEmpty) {
        continue;
      }
      if (remaining <= 1) break;
      widget.onRemove(line.localId);
      remaining--;
    }
  }

  /// Opens the line [localId], or closes whatever is open when null. An open
  /// heading closes with it.
  void _open(int? localId) {
    _closeHeading();
    _dropBlanks(<int>{?localId});
    setState(() {
      _openLineId = localId;
      _focusLineId = localId;
    });
  }

  /// Opens the heading over [run], closing the open line. Its first line
  /// stays even when blank: that is Add section's new line, under it.
  void _openHeading(List<int> run) {
    _closeHeading();
    _dropBlanks(<int>{run.first});
    setState(() {
      _openLineId = null;
      _focusLineId = null;
      _headingLineId = run.first;
      _headingRun = run;
      _headingBefore = <int, String?>{
        for (final int id in run) id: _sectionOf(id),
      };
      _headingName = _sectionOf(run.first);
    });
  }

  /// Closes the open heading. One closing with a blank name is removed --
  /// [remove] is the ✕ -- the same as one removed outright, except that its
  /// Undo restores the name it had before it opened.
  void _closeHeading({bool remove = false}) {
    if (_headingLineId == null) return;
    final List<int> run = _headingRun;
    final Map<int, String?> before = _headingBefore;
    final String? name = _headingName;
    final bool blank = _blank(name);
    setState(() {
      _headingLineId = null;
      _headingRun = const <int>[];
      _headingBefore = const <int, String?>{};
      _headingName = null;
    });
    if (!remove && !blank) return;

    final Map<int, String?> restore = blank
        ? before
        : <int, String?>{for (final int id in run) id: name};
    // A new heading closed unnamed: nothing was there, nothing to undo.
    if (restore.values.every(_blank)) return;
    _removeRun(run, restore);
  }

  /// Joins [run] to the group above -- each line takes the section of the
  /// group the heading sat under, or none at the top -- with Undo putting
  /// [restore] back, line by line. Nothing moves and nothing is deleted.
  ///
  /// The snackbar is shown here, so both hosts get it from one place.
  void _removeRun(List<int> run, Map<int, String?> restore) {
    final int at = widget.lines.indexWhere(
      (RecipeDraftLine l) => l.localId == run.first,
    );
    String? above;
    for (int i = at - 1; i >= 0; i--) {
      if (!_blank(widget.lines[i].section)) {
        above = widget.lines[i].section;
        break;
      }
    }
    widget.onSetSections(<int, String?>{for (final int id in run) id: above});

    final AppLocalizations l10n = AppLocalizations.of(context);
    final ValueChanged<Map<int, String?>> setSections = widget.onSetSections;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.sectionRemovedSnackbar),
          // A snackbar with an action persists by default in this Flutter;
          // keep the usual 4 s auto-dismiss.
          persist: false,
          action: SnackBarAction(
            label: l10n.undoSnackbarAction,
            // By id, so a line removed since is simply skipped.
            onPressed: () => setSections(restore),
          ),
        ),
      );
  }

  void _headingChanged(String text) {
    _headingName = text;
    widget.onSetSections(<int, String?>{
      for (final int id in _headingRun) id: text,
    });
  }

  /// Next on a heading: into its first line when that is blank -- Add
  /// section's path, so fast entry carries on inside the new section --
  /// otherwise the heading closes.
  void _headingSubmitted() {
    final int first = _headingRun.first;
    final RecipeDraftLine? line = widget.lines
        .where((RecipeDraftLine l) => l.localId == first)
        .firstOrNull;
    _open(line != null && line.rawText.trim().isEmpty ? first : null);
  }

  void _addSection() {
    final int id = widget.onAdd();
    _openHeading(<int>[id]);
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

  void _reordered(List<IngredientListItem> items, int oldItem, int newItem) {
    switch (items[oldItem]) {
      case LineItem():
        final LineDrop drop = resolveLineDrop(items, oldItem, newItem);
        widget.onMoveLine(drop.oldIndex, drop.newIndex, drop.section);
      case HeadingItem(:final int start, :final int end):
        final int? to = resolveRunDrop(items, oldItem, newItem);
        if (to != null) widget.onMoveRun(start, end, to);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<RecipeDraftLine> lines = widget.lines;
    // A heading whose first line has gone is no longer open.
    if (_headingLineId != null &&
        !lines.any((RecipeDraftLine l) => l.localId == _headingLineId)) {
      _headingLineId = null;
    }
    final List<IngredientListItem> items = ingredientListItems(
      lines,
      openHeadingLineId: _headingLineId,
    );
    final HeadingItem? dragging = _dragging;

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
          onReorderItem: (int oldItem, int newItem) =>
              _reordered(items, oldItem, newItem),
          onReorderStart: (int index) {
            final IngredientListItem item = items[index];
            if (item is HeadingItem) setState(() => _dragging = item);
          },
          onReorderEnd: (int _) {
            if (_dragging != null) setState(() => _dragging = null);
          },
          proxyDecorator: (Widget child, int index, Animation<double> anim) =>
              switch (items[index]) {
                final HeadingItem heading => _liftedRun(heading),
                LineItem() => _liftedLine(child, anim),
              },
          children: <Widget>[
            for (final (int i, IngredientListItem item) in items.indexed)
              switch (item) {
                HeadingItem() => _heading(i, item, lines),
                LineItem(:final int lineIndex) => KeyedSubtree(
                  key: ValueKey<int>(lines[lineIndex].localId),
                  // A dragged heading's run closes up under it; same keys
                  // and child count, so the indices stay valid.
                  child: Offstage(
                    offstage:
                        dragging != null &&
                        lineIndex >= dragging.start &&
                        lineIndex < dragging.end,
                    child: _line(
                      i,
                      lineIndex,
                      l10n,
                      // A line drops its divider before any heading.
                      showDivider:
                          i + 1 < items.length && items[i + 1] is LineItem,
                    ),
                  ),
                ),
              },
          ],
        ),
        // Wraps rather than overflowing at 360dp in Serbian.
        Wrap(
          spacing: AppSpacing.xs,
          children: <Widget>[
            TextButton.icon(
              onPressed: () => _open(widget.onAdd()),
              icon: const Icon(Icons.add),
              label: Text(l10n.addIngredientButton),
            ),
            TextButton.icon(
              onPressed: _addSection,
              icon: const Icon(Icons.title),
              label: Text(l10n.addSectionButton),
            ),
          ],
        ),
      ],
    );
  }

  Widget _line(
    int item,
    int index,
    AppLocalizations l10n, {
    required bool showDivider,
  }) {
    final RecipeDraftLine line = widget.lines[index];
    // A blank line has nothing to read, so it is always open.
    if (line.localId == _openLineId || line.rawText.trim().isEmpty) {
      return IngredientLineField(
        index: item,
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
      );
    }
    return _closedRow(item, line, showDivider: showDivider);
  }

  Widget _closedRow(
    int item,
    RecipeDraftLine line, {
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
      return ReorderableDelayedDragStartListener(index: item, child: row);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ReorderableDragStartListener(
          index: item,
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

  /// A heading item: open, as the field that renames it, or closed.
  Widget _heading(int item, HeadingItem heading, List<RecipeDraftLine> lines) {
    final int firstId = lines[heading.start].localId;
    // `AppSectionHeading` already ends in `sm`; a line above already ends in
    // its own `sm` padding.
    final double top = item == 0 ? AppSpacing.xs : AppSpacing.xl;
    final Key key = ValueKey<String>('section-$firstId');

    if (firstId == _headingLineId) {
      return _OpenHeading(
        key: key,
        index: item,
        text: lines[heading.start].section ?? '',
        locale: widget.locale,
        review: widget.review,
        top: top,
        autofocus: true,
        onChanged: _headingChanged,
        onSubmitted: _headingSubmitted,
        onRemove: () => _closeHeading(remove: true),
      );
    }

    final Widget closed = InkWell(
      key: const Key('ingredientSectionHeading'),
      // The top gap is part of the target: about 48 tall mid-list.
      onTap: () => _openHeading(<int>[
        for (int i = heading.start; i < heading.end; i++) lines[i].localId,
      ]),
      child: _closedHeading(item, heading.section ?? '', top: top),
    );
    return KeyedSubtree(
      key: key,
      child: widget.review
          ? ReorderableDelayedDragStartListener(index: item, child: closed)
          : closed,
    );
  }

  /// The heading as it reads, with the grip in the editor. [index] null is
  /// the drag proxy, which has nothing to start.
  Widget _closedHeading(int? index, String text, {required double top}) {
    final Widget heading = RecipeGroupHeading(text: text, top: 0, bottom: 0);
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: AppSpacing.xs),
      child: widget.review
          // Lined up with the rows' `md` inset.
          ? Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: heading,
            )
          : Row(
              // The grip centres on the heading's text line.
              children: <Widget>[
                _maybeDragStart(
                  index,
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Icon(
                      Icons.drag_indicator,
                      key: const Key('ingredientSectionGrip'),
                      size: AppSizes.grip,
                      color: Theme.of(context)
                          .extension<KitchenColors>()!
                          .dragHandle,
                    ),
                  ),
                ),
                Expanded(child: heading),
              ],
            ),
    );
  }

  Widget _maybeDragStart(int? index, Widget child) => index == null
      ? child
      : ReorderableDragStartListener(index: index, child: child);

  /// A heading under a finger: the heading and its run's closed rows,
  /// lifted the way a step row is (`_liftedStepRow`) -- elevation 3 on
  /// `surfaceContainerHigh`, so it has an edge in both themes.
  ///
  /// The proxy is sized to the heading's own item. `ReorderableListView`
  /// already wraps it in an unbounded, top-aligned `OverflowBox`, so the
  /// rows hang out of it below; a second one here sized itself to that
  /// unbounded height and threw the proxy off the finger (the device walk).
  Widget _liftedRun(HeadingItem heading) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<RecipeDraftLine> run = <RecipeDraftLine>[
      for (int i = heading.start; i < heading.end; i++)
        if (widget.lines[i].rawText.trim().isNotEmpty) widget.lines[i],
    ];
    return Material(
      elevation: 3,
      color: colors.surfaceContainerHigh,
      shadowColor: colors.shadow,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _closedHeading(null, heading.section ?? '', top: AppSpacing.xs),
            for (final (int i, RecipeDraftLine line) in run.indexed)
              Padding(
                // Past the grip column, as the rows sit in the list.
                padding: EdgeInsets.only(
                  left: widget.review ? 0 : AppSizes.grip + AppSpacing.xs,
                ),
                child: _ClosedLine(
                  line: line,
                  locale: widget.locale,
                  units: widget.units,
                  parser: widget.parser,
                  review: widget.review,
                  isFlagged: false,
                  showDivider: i != run.length - 1,
                  onTap: () {},
                  onChanged: (RecipeDraftLine _) {},
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// A line under a finger keeps `ReorderableListView`'s own default lift,
  /// which passing a [ReorderableListView.proxyDecorator] would otherwise
  /// replace.
  Widget _liftedLine(Widget child, Animation<double> animation) =>
      AnimatedBuilder(
        animation: animation,
        builder: (BuildContext context, Widget? child) {
          final double t = Curves.easeInOut.transform(animation.value);
          return Material(elevation: lerpDouble(0, 6, t)!, child: child);
        },
        child: child,
      );
}

/// The open heading: the open line's box (D158) holding one `titleSmall`
/// field in `primary`, so it reads as the heading it will be --
/// `[grip] [box] [✕ 48]`, top-aligned; no grip and inset `md` in review.
///
/// Private because it knows what a section is: it does not clear the
/// `core/widgets/` bar.
class _OpenHeading extends StatefulWidget {
  const _OpenHeading({
    required this.index,
    required this.text,
    required this.locale,
    required this.review,
    required this.top,
    required this.autofocus,
    required this.onChanged,
    required this.onSubmitted,
    required this.onRemove,
    super.key,
  });

  final int index;

  /// The run's section as stored: blank is null, so a field holding spaces
  /// is not reset to empty under the caret.
  final String text;
  final String locale;
  final bool review;
  final double top;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onRemove;

  @override
  State<_OpenHeading> createState() => _OpenHeadingState();
}

class _OpenHeadingState extends State<_OpenHeading> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController.fromValue(
      TextEditingValue(
        text: widget.text,
        selection: TextSelection.collapsed(offset: widget.text.length),
      ),
    );
    _focus = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(_OpenHeading oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Typing round-trips through the draft; only a change from outside, not
    // blank-as-null, moves the field.
    final String typed = _controller.text.trim().isEmpty
        ? ''
        : _controller.text;
    if (widget.text != typed) _controller.text = widget.text;
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focused != _focus.hasFocus) {
      setState(() => _focused = _focus.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle? style = theme.textTheme.titleSmall;

    return Padding(
      padding: EdgeInsets.only(top: widget.top, bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.review)
            const SizedBox(width: AppSpacing.md)
          else
            ReorderableDragStartListener(
              index: widget.index,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  right: AppSpacing.xs,
                ),
                child: Icon(
                  Icons.drag_indicator,
                  key: const Key('ingredientSectionGrip'),
                  size: AppSizes.grip,
                  color: theme.extension<KitchenColors>()!.dragHandle,
                ),
              ),
            ),
          Expanded(
            child: Container(
              key: const Key('ingredientSectionBox'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              // As on the open line: a foreground, always present, so the
              // focus border neither moves the text nor rebuilds the field.
              foregroundDecoration: BoxDecoration(
                border: Border.fromBorderSide(
                  _focused
                      ? BorderSide(color: scheme.primary, width: 2)
                      : BorderSide.none,
                ),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                autofocus: widget.autofocus,
                maxLines: 1,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                style: style?.copyWith(color: scheme.primary),
                // Bare, for the reason the open line's field is.
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  // The RECIPE's own language, as the open line's hint is.
                  hintText: lookupAppLocalizations(Locale(widget.locale))
                      .ingredientSectionHint,
                  hintStyle: style?.copyWith(color: scheme.onSurfaceVariant),
                ),
                onChanged: widget.onChanged,
                // Next's default would move focus on; the list decides.
                onEditingComplete: () {},
                onSubmitted: (String _) => widget.onSubmitted(),
              ),
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).removeTooltip,
            icon: const Icon(Icons.close),
            onPressed: widget.onRemove,
          ),
        ],
      ),
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
    final IngredientMatch? suggestion = line.isMatched || searchName.isEmpty
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
