import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../text/rich_text_editing.dart';
import '../text/rich_text_markup.dart';

/// A text controller that shows the light-formatting subset (D165) styled
/// in place, and the edits `AppFormattingToolbar`'s buttons make (D166).
///
/// The stored text is exactly what is typed; nothing is hidden. Bold content
/// is drawn w600 (never w700, D134), italic content italic, and the `**`,
/// `*`, `- ` and `12. ` markers dimmed to `onSurfaceVariant`. No span ever
/// changes the size or letter spacing, so the caret stays on its character.
///
/// Bold or italic at a caret outside any word inserts an empty pair with the
/// caret inside. The controller remembers it and removes it again if it is
/// still empty when the caret leaves it, or on [dropPendingPair] (the field
/// losing focus): an empty `****` would otherwise stay behind as a stray
/// italic `*`.
///
/// The editing rules themselves are the pure functions in
/// `core/text/rich_text_editing.dart`; this is the Flutter side of them.
class RichTextEditingController extends TextEditingController {
  RichTextEditingController({super.text});

  ({int start, RichRunStyle style})? _pending;

  /// The toolbar's toggle state for the current selection.
  RichFormatState get formatState {
    final ({int start, RichRunStyle style})? pending = _pending;
    final (int start, int end) = _selection;
    final RichFormatState state = richFormatState(text, start, end);
    if (pending == null) return state;
    // An empty `****` scans as italic; while it waits, it is what was asked.
    final bool bold = pending.style == RichRunStyle.bold;
    return RichFormatState(
      bold: bold,
      italic: !bold,
      bullet: state.bullet,
      numbered: state.numbered,
      boldEnabled: bold,
      italicEnabled: !bold,
    );
  }

  void toggleBold() => _toggleInline(RichRunStyle.bold);

  void toggleItalic() => _toggleInline(RichRunStyle.italic);

  void toggleBullet() => _toggleList(ordered: false);

  void toggleNumbered() => _toggleList(ordered: true);

  /// Removes the empty pair bold or italic left at a caret, if it is still
  /// empty.
  void dropPendingPair() {
    final ({int start, RichRunStyle style})? pending = _pending;
    if (pending == null) return;
    _pending = null;
    final TextEditingValue dropped = _dropPair(value, pending);
    if (dropped == value) {
      // Nothing left to drop; the toggle state still changes.
      notifyListeners();
    } else {
      super.value = dropped;
    }
  }

  @override
  set value(TextEditingValue newValue) {
    final ({int start, RichRunStyle style})? pending = _pending;
    if (pending == null) {
      super.value = newValue;
      return;
    }
    if (newValue.text != text) {
      // Typed into, or deleted from: either way no longer an empty pair
      // waiting for its content.
      _pending = null;
      super.value = newValue;
      return;
    }
    final int inside = pending.start + _markerLength(pending.style);
    final TextSelection selection = newValue.selection;
    if (selection.isValid &&
        selection.isCollapsed &&
        selection.baseOffset == inside) {
      super.value = newValue;
      return;
    }
    // The selection left the still-empty pair: take it out.
    _pending = null;
    super.value = _dropPair(newValue, pending);
  }

  /// [value] without the empty pair at [pending], its selection moved with
  /// the text.
  static TextEditingValue _dropPair(
    TextEditingValue value,
    ({int start, RichRunStyle style}) pending,
  ) {
    final TextSelection selection = value.selection;
    RichEdit at(int offset) =>
        dropEmptyPair(value.text, pending.start, pending.style, offset);
    if (!selection.isValid) {
      return TextEditingValue(text: at(value.text.length).text);
    }
    final RichEdit base = at(selection.baseOffset);
    if (base.text == value.text) return value;
    return TextEditingValue(
      text: base.text,
      selection: TextSelection(
        baseOffset: base.selectionStart,
        extentOffset: at(selection.extentOffset).selectionStart,
      ),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final String text = this.text;
    if (text.isEmpty) return TextSpan(style: style, text: text);

    final TextStyle marker = TextStyle(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    List<_Piece> pieces = <_Piece>[
      for (final RichSegment segment in richSegments(text))
        _Piece(segment.start, segment.end, switch (segment.kind) {
          RichSegmentKind.plain => null,
          RichSegmentKind.marker => marker,
          RichSegmentKind.bold => _bold,
          RichSegmentKind.italic => _italic,
        }),
    ];

    final ({int start, RichRunStyle style})? pending = _pending;
    if (pending != null) {
      pieces = _overlay(
        pieces,
        pending.start,
        pending.start + 2 * _markerLength(pending.style),
        (_) => marker,
      );
    }

    // Keep the IME's composing underline: Gboard composes on nearly every
    // word, so dropping the styling while composing would turn it off all
    // the time.
    final TextRange composing = value.composing;
    if (withComposing &&
        value.isComposingRangeValid &&
        !composing.isCollapsed) {
      pieces = _overlay(
        pieces,
        composing.start,
        composing.end,
        (TextStyle? s) => (s ?? const TextStyle()).merge(_underline),
      );
    }

    return TextSpan(
      style: style,
      children: <InlineSpan>[
        for (final _Piece piece in pieces)
          TextSpan(
            text: text.substring(piece.start, piece.end),
            style: piece.style,
          ),
      ],
    );
  }

  (int, int) get _selection {
    final TextSelection selection = value.selection;
    if (!selection.isValid) return (text.length, text.length);
    return (selection.start, selection.end);
  }

  void _toggleInline(RichRunStyle style) {
    final ({int start, RichRunStyle style})? pending = _pending;
    if (pending != null) {
      // Tapping the same toggle again takes the empty pair back out; the
      // other one is disabled while it waits.
      if (pending.style == style) dropPendingPair();
      return;
    }
    final RichFormatState state = formatState;
    if (style == RichRunStyle.bold ? !state.boldEnabled : !state.italicEnabled) {
      return;
    }
    final (int start, int end) = _selection;
    final RichEdit edit = toggleInline(text, start, end, style);
    final int? pair = edit.pendingPair;
    _pending = pair == null ? null : (start: pair, style: style);
    _setEdit(edit);
  }

  void _toggleList({required bool ordered}) {
    dropPendingPair();
    final (int start, int end) = _selection;
    _setEdit(toggleList(text, start, end, ordered: ordered));
  }

  /// Bypasses [value]'s pending-pair check: the edit already accounts for
  /// it.
  void _setEdit(RichEdit edit) {
    super.value = TextEditingValue(
      text: edit.text,
      selection: TextSelection(
        baseOffset: edit.selectionStart,
        extentOffset: edit.selectionEnd,
      ),
    );
  }

  static int _markerLength(RichRunStyle style) =>
      style == RichRunStyle.bold ? 2 : 1;

  static const TextStyle _bold = TextStyle(fontWeight: FontWeight.w600);
  static const TextStyle _italic = TextStyle(fontStyle: FontStyle.italic);
  static const TextStyle _underline = TextStyle(
    decoration: TextDecoration.underline,
  );
}

/// Continues a list on Enter and ends it on Enter in an empty item -- see
/// `continueListOnNewline`. Anything else (paste, a multi-character change,
/// a non-collapsed selection) passes through untouched.
class RichListFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final TextSelection selection = oldValue.selection;
    if (!selection.isValid || !selection.isCollapsed) return newValue;
    final RichEdit? edit = continueListOnNewline(
      oldValue.text,
      selection.baseOffset,
      newValue.text,
    );
    if (edit == null) return newValue;
    return TextEditingValue(
      text: edit.text,
      selection: TextSelection.collapsed(offset: edit.selectionStart),
      composing: TextRange.empty,
    );
  }
}

/// A stretch of the edited text and the style it is drawn in, on top of the
/// field's.
class _Piece {
  const _Piece(this.start, this.end, this.style);

  final int start;
  final int end;
  final TextStyle? style;
}

/// [pieces] with [start]..[end] restyled through [restyle], splitting any
/// piece that crosses either edge.
List<_Piece> _overlay(
  List<_Piece> pieces,
  int start,
  int end,
  TextStyle? Function(TextStyle?) restyle,
) => <_Piece>[
  for (final _Piece piece in pieces)
    for (final (int a, int b, bool inside) in <(int, int, bool)>[
      (piece.start, _clamp(start, piece), false),
      (_clamp(start, piece), _clamp(end, piece), true),
      (_clamp(end, piece), piece.end, false),
    ])
      if (a < b) _Piece(a, b, inside ? restyle(piece.style) : piece.style),
];

int _clamp(int offset, _Piece piece) =>
    offset < piece.start ? piece.start : (offset > piece.end ? piece.end : offset);
