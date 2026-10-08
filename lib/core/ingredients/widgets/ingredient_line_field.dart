import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../error/app_failure.dart';
import '../../error/failure_l10n.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../text/text_normalizer.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/kitchen_colors.dart';
import '../../../features/ingredients/domain/ingredient_line_parser.dart';
import '../../../features/ingredients/domain/ingredient_match.dart';
import '../../../features/ingredients/domain/parsed_ingredient_line.dart';
import '../../../features/ingredients/domain/unit.dart';
import '../../../features/ingredients/domain/unit_catalog.dart';
import '../ingredient_catalog_providers.dart';
import '../../../features/recipes/domain/recipe_draft.dart';
import 'ingredient_picker_sheet.dart';
import 'ingredient_suggestion_pill.dart';
import 'quantity_format.dart';

/// The word a line is about, as searched and as written back as an alias:
/// the local parse's name, or the whole line when the parse found none
/// (rule 3). The closed rows and the open line both search with it, so
/// opening a row hits the search it already made.
String ingredientSearchName(String rawText, IngredientLineParser? parser) {
  final String? name = parser?.parse(rawText).name?.trim();
  return name == null || name.isEmpty ? rawText.trim() : name;
}

/// Confirms [match] for [line] as the cook's own decision, then teaches the
/// catalog the word they typed.
///
/// The one path for both ways a person picks an existing ingredient: a
/// `ChooseExisting` from the picker, and a tap on the suggestion pill (D160).
/// A human pick is `manual` with full confidence and is never overwritten by
/// a later machine pass (D7). The alias write-back (D8) is skipped when the
/// string that matched already is the string typed -- `link_ingredient_alias`
/// would return the row unchanged, so the round trip buys nothing. When the
/// alias is already taken by a different ingredient the RPC returns false
/// rather than raising, and that is not an error worth telling anyone about:
/// the line still saves, only the global write-back is declined.
Future<void> confirmIngredientMatch({
  required WidgetRef ref,
  required BuildContext context,
  required RecipeDraftLine line,
  required IngredientMatch match,
  required String typedName,
  required String locale,
  required ValueChanged<RecipeDraftLine> onChanged,
}) async {
  onChanged(
    _withManualMatch(
      line,
      ingredientId: match.ingredientId,
      displayName: match.displayName,
    ),
  );

  if (TextNormalizer.normalize(match.matchedName) ==
      TextNormalizer.normalize(typedName)) {
    return;
  }

  try {
    await ref
        .read(ingredientCatalogProvider)
        .linkAlias(match.ingredientId, typedName, locale: locale);
  } on AppFailure catch (e) {
    if (!context.mounted) return;
    _report(context, e);
  }
}

RecipeDraftLine _withManualMatch(
  RecipeDraftLine line, {
  required String ingredientId,
  required String displayName,
}) =>
    line.copyWith(
      ingredientId: ingredientId,
      displayName: displayName,
      matchMethod: MatchMethod.manual,
      matchConfidence: 1,
      matchedAt: DateTime.now(),
    );

/// The line is already saved either way, so a failed write-back is reported
/// and dropped rather than turned into something the cook has to resolve.
void _report(BuildContext context, AppFailure failure) {
  final AppLocalizations l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(failure.localized(l10n))));
}

/// The one open ingredient line: the text the cook typed, and under it, live,
/// what the app made of it (`docs/DESIGN_SYSTEM.md` § Ingredient lines, A4·2).
///
/// One box -- `surfaceContainerHighest`, a 2dp `primary` border only while
/// focused -- with the raw text on top in `bodyLarge` (D158: the open line
/// *is* the row being edited, and dropping to `bodyMedium` on tap would make
/// it jump), the preview row under it (`→ brašno · prosejano   2 šolje`), and
/// the suggestion pill under that when there is one. Tapping the preview is
/// "choose another": it opens the picker.
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
///
/// Fast entry (D159) is the list's business; this field only reports the
/// keys: [onSubmitted] for the keyboard's Next, and [onBackspaceWhenEmpty]
/// for Backspace on an empty line. Next keeps focus here -- the list decides
/// where it goes -- so the keyboard stays up through a burst of lines.
class IngredientLineField extends ConsumerStatefulWidget {
  const IngredientLineField({
    required this.index,
    required this.line,
    required this.locale,
    required this.onChanged,
    required this.onRemove,
    this.autofocus = false,
    this.onSubmitted,
    this.onBackspaceWhenEmpty,
    this.onFocused,
    super.key,
  });

  final int index;
  final RecipeDraftLine line;

  /// The recipe's language, which is both the search locale and the locale a
  /// newly created ingredient is named in.
  final String locale;

  final ValueChanged<RecipeDraftLine> onChanged;
  final VoidCallback onRemove;

  /// Focus the field when it first builds -- a line opened by a tap, by
  /// Enter, by Backspace or by Add ingredient. A new recipe's lone blank line
  /// is built without it, so the keyboard does not jump up on screen load.
  final bool autofocus;

  /// The keyboard's Next key, with the text as it stands.
  final ValueChanged<String>? onSubmitted;

  /// Backspace pressed while the text is already empty.
  final VoidCallback? onBackspaceWhenEmpty;

  /// The field gained focus -- how the list learns a blank line it rendered
  /// open, but never opened itself, is now the one being typed in.
  final VoidCallback? onFocused;

  @override
  ConsumerState<IngredientLineField> createState() =>
      _IngredientLineFieldState();
}

class _IngredientLineFieldState extends ConsumerState<IngredientLineField> {
  Timer? _debounce;

  /// Its own controller rather than `initialValue`: Backspace on an empty
  /// line opens the one above with the caret at its end, and only a
  /// controller can put it there. Only one line is ever open, so the
  /// per-row lifecycle `RecipeEditScreen`'s doc warns about does not arise:
  /// created when the line opens, disposed when it closes.
  late final TextEditingController _controller;
  late final FocusNode _focus;
  bool _focused = false;

  /// The term currently being searched.
  ///
  /// Empty for a matched line: opening a recipe with fifteen saved lines
  /// would otherwise fire fifteen searches for rows that are already
  /// matched, and the picker does not need it -- it takes the parsed name
  /// directly when it opens. An unmatched line starts with its own name, the
  /// same search its closed row already made for the pill, so the pill is
  /// still there once the line opens.
  String _query = '';

  @override
  void initState() {
    super.initState();
    final String text = widget.line.rawText;
    _controller = TextEditingController.fromValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
    _focus = FocusNode(onKeyEvent: _onKey)..addListener(_onFocusChanged);
    if (!widget.line.isMatched && text.trim().isNotEmpty) {
      _query = ingredientSearchName(text, ref.read(lineParserProvider).value);
    }
  }

  @override
  void didUpdateWidget(IngredientLineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Typing round-trips through the draft and comes back equal; anything
    // else changed the line from outside, and the field follows the draft.
    if (widget.line.rawText != _controller.text) {
      _controller.text = widget.line.rawText;
    }
    // A blank line is built open before anyone opens it -- Add section's,
    // under its heading -- so `autofocus` alone, read once, would never
    // reach it when Next on the heading opens it.
    if (widget.autofocus && !oldWidget.autofocus) _focus.requestFocus();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focused == _focus.hasFocus) return;
    setState(() => _focused = _focus.hasFocus);
    if (_focus.hasFocus) widget.onFocused?.call();
  }

  /// Android's soft keyboard delivers Backspace on an empty field as a key
  /// event, which is what this catches. iOS's may not (unverified); the
  /// zero-width-space workaround is out because it would leak into
  /// `raw_text`.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final VoidCallback? onBackspace = widget.onBackspaceWhenEmpty;
    if (onBackspace != null &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty) {
      onBackspace();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final IngredientLineParser? parser = ref.watch(lineParserProvider).value;
    final UnitCatalog units =
        ref.watch(unitCatalogProvider).value ?? UnitCatalog.empty();

    final AsyncValue<List<IngredientMatch>> matches =
        ref.watch(ingredientMatchesProvider(_query, locale: widget.locale));

    ref.listen(
      ingredientMatchesProvider(_query, locale: widget.locale),
      (AsyncValue<List<IngredientMatch>>? _,
              AsyncValue<List<IngredientMatch>> next) =>
          _maybeAutoAccept(next.value, parser),
    );

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final RecipeDraftLine line = widget.line;
    final bool blank = line.rawText.trim().isEmpty;
    final List<IngredientMatch> found =
        matches.value ?? const <IngredientMatch>[];
    final IngredientMatch? suggestion =
        line.isMatched || blank || found.isEmpty ? null : found.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReorderableDragStartListener(
            index: widget.index,
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.md,
                right: AppSpacing.xs,
              ),
              child: Icon(
                Icons.drag_indicator,
                size: AppSizes.grip,
                color: theme.extension<KitchenColors>()!.dragHandle,
              ),
            ),
          ),
          Expanded(
            child: Container(
              key: const Key('ingredientLineBox'),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              // Foreground, so the 2dp border appearing on focus does not
              // move the text by 2dp. Always present, with no side when
              // unfocused: a decoration that comes and goes changes the
              // Container's subtree and rebuilds the TextField under it.
              foregroundDecoration: BoxDecoration(
                border: Border.fromBorderSide(
                  _focused
                      ? BorderSide(color: scheme.primary, width: 2)
                      : BorderSide.none,
                ),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: widget.autofocus,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurface,
                    ),
                    // Bare: the box around it is the field. `collapsed`
                    // alone is not enough -- it sets only `border`, so the
                    // theme's focused border and 52dp minimum height still
                    // came through (the 2026-10-08 walk: a second ring
                    // inside the box, and a gap above the preview).
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      // The RECIPE's own language, not the reader's chrome
                      // locale -- an example of what to type in this recipe
                      // should read in the language this recipe is written
                      // in (D86's own reasoning, one screen over).
                      hintText: lookupAppLocalizations(Locale(widget.locale))
                          .ingredientLineHint,
                      hintStyle: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    onChanged: (String value) => _onTextChanged(value, parser),
                    // Overrides Next's default of moving focus on: the list
                    // decides where it goes, and keeping it keeps the
                    // keyboard up.
                    onEditingComplete: () {},
                    onSubmitted: widget.onSubmitted,
                  ),
                  if (!blank) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    _preview(
                      context,
                      parser: parser,
                      units: units,
                      noMatch: suggestion == null &&
                          !line.isMatched &&
                          _query.isNotEmpty &&
                          matches.hasValue &&
                          !matches.isLoading,
                    ),
                  ],
                  if (suggestion != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IngredientSuggestionPill(
                        name: suggestion.displayName,
                        onConfirm: () => unawaited(
                          confirmIngredientMatch(
                            ref: ref,
                            context: context,
                            line: widget.line,
                            match: suggestion,
                            typedName: _parsedName(parser),
                            locale: widget.locale,
                            onChanged: widget.onChanged,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
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

  /// What the app made of the line, under the text: `→ name · note` on the
  /// left, the amount on the right. Tapping it opens the picker.
  ///
  /// Two people (D86): the status words -- ` · opciono`, ` · Nema
  /// poklapanja` -- are chrome and follow the reader; the catalog name, the
  /// amount and its unit follow the recipe.
  Widget _preview(
    BuildContext context, {
    required IngredientLineParser? parser,
    required UnitCatalog units,
    required bool noMatch,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final RecipeDraftLine line = widget.line;

    final String? parsedName = parser?.parse(line.rawText).name?.trim();
    // Rule 3: with no usable parse, the whole line is the name, with no
    // amount beside it to double up.
    final bool whole = parsedName == null || parsedName.isEmpty;
    final String name = line.isMatched && line.displayName != null
        ? line.displayName!
        : whole
            ? line.rawText.trim()
            : parsedName;

    // A status word never splits, and never strands its `·` at a line end:
    // inside it and after each `·` the spaces are non-breaking, so the line
    // breaks only in the cook's own words or before a `·` (the 2026-10-08
    // walk: `No` at a line end, `match` under it).
    String unbroken(String words) => words.replaceAll(' ', '\u00A0');
    final String left = <String>[
      '→ $name',
      if (line.note != null) line.note!,
      // The parser moves the optional marker into the note, so a line with a
      // note already says it.
      if (line.isOptional && line.note == null)
        unbroken(l10n.ingredientOptionalTrailer),
      if (noMatch) unbroken(l10n.ingredientNoMatchLabel),
    ].join(' ·\u00A0');

    final String? quantity = whole || line.quantity == null
        ? null
        : formatQuantity(line.quantity!);
    final String? unit = whole || line.unitCode == null
        ? null
        : units.displayName(line.unitCode!, locale: widget.locale);
    final TextStyle? style = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return Tooltip(
      message: l10n.ingredientPickerQuestion(_parsedName(parser)),
      child: InkWell(
        key: const Key('ingredientLinePreview'),
        borderRadius: BorderRadius.circular(AppRadii.xs),
        onTap: () => unawaited(_openPicker(parser)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: Text(left, style: style)),
            if (quantity != null || unit != null) ...<Widget>[
              const SizedBox(width: AppSpacing.md),
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    if (quantity != null)
                      TextSpan(
                        text: quantity,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    if (quantity != null && unit != null)
                      const TextSpan(text: ' '),
                    if (unit != null) TextSpan(text: unit),
                  ],
                ),
                key: const Key('ingredientLinePreviewAmount'),
                style: style,
                softWrap: false,
              ),
            ],
          ],
        ),
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
  ///
  /// Only the open line does this, and only for what is typed into it: a
  /// closed row offers the pill and never applies anything, so opening a
  /// saved recipe cannot change a line nobody touched (D160).
  void _maybeAutoAccept(
    List<IngredientMatch>? found,
    IngredientLineParser? parser,
  ) {
    if (found == null || found.isEmpty) return;
    // Already answered -- by an earlier pass or by a person. Never overwrite
    // a decision that is already there.
    if (widget.line.isMatched) return;
    // An answer to a word the line no longer says. A search that went out
    // during a pause can land after more was typed (the 2026-10-08 walk:
    // `secera` auto-accepted onto `secera100 g kukuruzzznog brasnaa`). The
    // controller is the latest text; [widget.line] can be a frame behind it,
    // and adopting onto that would also write the older text back.
    if (_controller.text != widget.line.rawText) return;
    if (parser?.parse(_controller.text).name != _query) return;

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
        await confirmIngredientMatch(
          ref: ref,
          context: context,
          line: widget.line,
          match: match,
          typedName: name,
          locale: widget.locale,
          onChanged: widget.onChanged,
        );
      case ChooseNew(name: final String newName):
        await _createIngredient(newName);
    }
  }

  Future<void> _createIngredient(String name) async {
    // A unit on the line is the best evidence available for what family the
    // new ingredient is measured in. `other` is not a legal argument, and the
    // datasource already maps it to null.
    final UnitCatalog units =
        ref.read(unitCatalogProvider).value ?? UnitCatalog.empty();
    final String? unitCode = widget.line.unitCode;
    final UnitFamily? family =
        unitCode == null ? null : units.byCode(unitCode)?.family;

    try {
      final String ingredientId = await ref
          .read(ingredientCatalogProvider)
          .createIngredient(name, locale: widget.locale, unitFamily: family);
      if (!mounted) return;
      // A created ingredient is a human decision too (D7).
      widget.onChanged(
        _withManualMatch(
          widget.line,
          ingredientId: ingredientId,
          displayName: name,
        ),
      );
    } on AppFailure catch (e) {
      if (!mounted) return;
      _report(context, e);
    }
  }

  String _parsedName(IngredientLineParser? parser) =>
      ingredientSearchName(widget.line.rawText, parser);
}
