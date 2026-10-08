/// Editing the light-formatting subset (D165) in place: the toggle state the
/// formatting toolbar shows, and the edits its buttons and the Enter key
/// make (D166).
///
/// The rules:
///
/// - **Lines touched.** A selection touches every line it overlaps by at
///   least one character; blank lines inside a multi-line selection are
///   ignored. A collapsed caret, or a selection that overlaps nothing (just
///   a newline), touches the caret's line.
/// - **Bold / italic active** when every touched line's selected part sits
///   inside a match of that style, markers included. A collapsed caret
///   counts when it is between or touching the markers. Bold is disabled
///   inside italic and vice versa: there is no nesting (D165 #3).
/// - **Inline toggle**, per touched line: a selection that overlaps a match
///   of the same style unwraps every such match. Otherwise the selected part,
///   trimmed, is wrapped. A collapsed caret in a word wraps the word; a
///   collapsed caret elsewhere inserts an empty pair with the caret inside
///   and reports it as [RichEdit.pendingPair].
/// - **List toggle** over the touched lines: when every one is an item of
///   that kind, the markers come off. Otherwise each line gets the marker,
///   losing the other kind's first. Numbering continues from the line above
///   when that is a numbered item, else starts at 1. Nothing else is ever
///   renumbered (D165 #4).
/// - **Enter** in an item continues the list; Enter in an empty item ends
///   it.
///
/// Every function is total: out-of-range offsets are clamped, and the worst
/// case is the text handed back unchanged.
///
/// Pure Dart. No Flutter imports (CLAUDE.md rule 7).
library;

import 'rich_text_markup.dart';

/// The result of an edit: new text, the selection on it, and the offset of
/// an empty inline pair the edit just inserted, if it did.
final class RichEdit {
  const RichEdit({
    required this.text,
    required this.selectionStart,
    required this.selectionEnd,
    this.pendingPair,
  });

  final String text;
  final int selectionStart;
  final int selectionEnd;

  /// Where an empty `****` or `**` starts, while it waits to be typed into.
  final int? pendingPair;

  @override
  bool operator ==(Object other) =>
      other is RichEdit &&
      other.text == text &&
      other.selectionStart == selectionStart &&
      other.selectionEnd == selectionEnd &&
      other.pendingPair == pendingPair;

  @override
  int get hashCode =>
      Object.hash(text, selectionStart, selectionEnd, pendingPair);

  @override
  String toString() =>
      'RichEdit("$text", $selectionStart-$selectionEnd'
      '${pendingPair == null ? '' : ', pending $pendingPair'})';
}

/// What the toolbar's toggles show for a selection.
final class RichFormatState {
  const RichFormatState({
    this.bold = false,
    this.italic = false,
    this.bullet = false,
    this.numbered = false,
    this.boldEnabled = true,
    this.italicEnabled = true,
  });

  final bool bold;
  final bool italic;
  final bool bullet;
  final bool numbered;
  final bool boldEnabled;
  final bool italicEnabled;

  @override
  bool operator ==(Object other) =>
      other is RichFormatState &&
      other.bold == bold &&
      other.italic == italic &&
      other.bullet == bullet &&
      other.numbered == numbered &&
      other.boldEnabled == boldEnabled &&
      other.italicEnabled == italicEnabled;

  @override
  int get hashCode =>
      Object.hash(bold, italic, bullet, numbered, boldEnabled, italicEnabled);

  @override
  String toString() =>
      'RichFormatState(bold: $bold, italic: $italic, bullet: $bullet, '
      'numbered: $numbered, boldEnabled: $boldEnabled, '
      'italicEnabled: $italicEnabled)';
}

/// How a run of text is drawn while it is edited: as typed, dimmed as a
/// marker, or styled.
enum RichSegmentKind { plain, marker, bold, italic }

/// One stretch of the edited text in one [RichSegmentKind], by offset.
final class RichSegment {
  const RichSegment(this.start, this.end, this.kind);

  final int start;
  final int end;
  final RichSegmentKind kind;

  @override
  bool operator ==(Object other) =>
      other is RichSegment &&
      other.start == start &&
      other.end == end &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(start, end, kind);

  @override
  String toString() => 'RichSegment(${kind.name}, $start-$end)';
}

/// [text] cut into contiguous, non-empty segments covering every character
/// in order: list markers and inline markers as [RichSegmentKind.marker],
/// bold and italic content as such, everything else (newlines included)
/// plain. Adjacent plain stretches are merged.
List<RichSegment> richSegments(String text) {
  final List<RichSegment> out = <RichSegment>[];
  void add(int start, int end, RichSegmentKind kind) {
    if (end <= start) return;
    if (out.isNotEmpty &&
        out.last.kind == kind &&
        kind == RichSegmentKind.plain &&
        out.last.end == start) {
      out[out.length - 1] = RichSegment(out.last.start, end, kind);
    } else {
      out.add(RichSegment(start, end, kind));
    }
  }

  for (final _Line line in _lines(text)) {
    final String lineText = text.substring(line.start, line.end);
    final int markerLength = matchRichListMarker(lineText)?.length ?? 0;
    add(line.start, line.start + markerLength, RichSegmentKind.marker);
    final int base = line.start + markerLength;
    int last = base;
    for (final RichInlineMatch m in scanRichInline(
      lineText.substring(markerLength),
    )) {
      add(last, base + m.start, RichSegmentKind.plain);
      add(base + m.start, base + m.contentStart, RichSegmentKind.marker);
      add(
        base + m.contentStart,
        base + m.contentEnd,
        m.style == RichRunStyle.bold
            ? RichSegmentKind.bold
            : RichSegmentKind.italic,
      );
      add(base + m.contentEnd, base + m.end, RichSegmentKind.marker);
      last = base + m.end;
    }
    add(last, line.end, RichSegmentKind.plain);
    if (line.end < text.length) {
      add(line.end, line.end + 1, RichSegmentKind.plain);
    }
  }
  return out;
}

/// The toggle state for the selection [start]..[end] in [text].
RichFormatState richFormatState(String text, int start, int end) {
  final (int s, int e) = _order(text, start, end);
  final List<_Line> touched = _touched(text, s, e);

  bool allItems({required bool ordered}) => touched.every((_Line line) {
    final ({int length, bool ordered, int? number})? marker =
        matchRichListMarker(text.substring(line.start, line.end));
    return marker != null && marker.ordered == ordered;
  });

  final bool bold = _inside(text, s, e, touched, RichRunStyle.bold);
  final bool italic = _inside(text, s, e, touched, RichRunStyle.italic);
  return RichFormatState(
    bold: bold,
    italic: italic,
    bullet: allItems(ordered: false),
    numbered: allItems(ordered: true),
    boldEnabled: bold || !italic,
    italicEnabled: italic || !bold,
  );
}

/// Bold or italic on or off for the selection [start]..[end] -- see the
/// library doc. [style] is [RichRunStyle.bold] or [RichRunStyle.italic]; a
/// plain one is a no-op.
RichEdit toggleInline(String text, int start, int end, RichRunStyle style) {
  final (int s, int e) = _order(text, start, end);
  if (style == RichRunStyle.plain) return _unchanged(text, s, e);
  final String marker = _marker(style);

  if (s == e) return _toggleAtCaret(text, s, style, marker);

  final List<_Edit> edits = <_Edit>[];
  final List<(int, int)> wrapped = <(int, int)>[];
  for (final _Line line in _touched(text, s, e)) {
    final String lineText = text.substring(line.start, line.end);
    final int a = (s > line.start ? s : line.start) - line.start;
    final int b = (e < line.end ? e : line.end) - line.start;
    final List<RichInlineMatch> same = <RichInlineMatch>[
      for (final RichInlineMatch m in scanRichInline(lineText))
        // Overlapping, not just adjacent: selecting `foo` in `**x**foo`
        // bolds it rather than unbolding `x`.
        if (m.style == style && m.start < b && a < m.end) m,
    ];
    if (same.isNotEmpty) {
      for (final RichInlineMatch m in same) {
        edits
          ..add(_Edit(line.start + m.start, m.contentStart - m.start, ''))
          ..add(_Edit(line.start + m.contentEnd, m.end - m.contentEnd, ''));
      }
      continue;
    }
    int ta = a;
    int tb = b;
    while (ta < tb && _isSpace(lineText.codeUnitAt(ta))) {
      ta++;
    }
    while (tb > ta && _isSpace(lineText.codeUnitAt(tb - 1))) {
      tb--;
    }
    if (ta == tb) continue;
    edits
      ..add(_Edit(line.start + ta, 0, marker))
      ..add(_Edit(line.start + tb, 0, marker));
    wrapped.add((line.start + ta, line.start + tb));
  }
  if (edits.isEmpty) return _unchanged(text, s, e);

  final String next = _apply(text, edits);
  // One wrapped part: select exactly its content, so the cook sees it
  // styled and still selected.
  if (wrapped.length == 1 && edits.length == 2) {
    final (int wa, int wb) = wrapped.single;
    return RichEdit(
      text: next,
      selectionStart: wa + marker.length,
      selectionEnd: wb + marker.length,
    );
  }
  return RichEdit(
    text: next,
    selectionStart: _map(edits, s, afterInsert: true),
    selectionEnd: _map(edits, e, afterInsert: false),
  );
}

/// A bulleted (`ordered: false`) or numbered list on or off over the lines
/// the selection [start]..[end] touches -- see the library doc.
RichEdit toggleList(
  String text,
  int start,
  int end, {
  required bool ordered,
}) {
  final (int s, int e) = _order(text, start, end);
  final List<_Line> touched = _touched(text, s, e);
  final bool allOn = touched.every((_Line line) {
    final ({int length, bool ordered, int? number})? marker =
        matchRichListMarker(text.substring(line.start, line.end));
    return marker != null && marker.ordered == ordered;
  });

  final List<_Edit> edits = <_Edit>[];
  if (allOn) {
    for (final _Line line in touched) {
      final int length = matchRichListMarker(
        text.substring(line.start, line.end),
      )!.length;
      edits.add(_Edit(line.start, length, ''));
    }
  } else {
    int number = 1;
    if (ordered) {
      final List<_Line> all = _lines(text);
      final int first = all.indexWhere(
        (_Line l) => l.start == touched.first.start,
      );
      if (first > 0) {
        final _Line above = all[first - 1];
        final ({int length, bool ordered, int? number})? marker =
            matchRichListMarker(text.substring(above.start, above.end));
        if (marker != null && marker.ordered && marker.number != null) {
          number = marker.number! + 1;
        }
      }
    }
    for (final _Line line in touched) {
      final ({int length, bool ordered, int? number})? existing =
          matchRichListMarker(text.substring(line.start, line.end));
      edits.add(
        _Edit(
          line.start,
          existing?.length ?? 0,
          ordered ? '${number++}. ' : '- ',
        ),
      );
    }
  }

  return RichEdit(
    text: _apply(text, edits),
    selectionStart: _map(edits, s, afterInsert: true),
    selectionEnd: _map(edits, e, afterInsert: true),
  );
}

/// What Enter should do in a list, or null to let it through as typed.
///
/// Only when [newText] is [oldText] with one `\n` inserted at the collapsed
/// [oldCaret], on an item line, with the caret past its marker: an empty
/// item loses its marker and the newline is not inserted (the list ends);
/// any other item gets the next marker after the newline.
RichEdit? continueListOnNewline(
  String oldText,
  int oldCaret,
  String newText,
) {
  if (oldCaret < 0 || oldCaret > oldText.length) return null;
  if (newText.length != oldText.length + 1 ||
      newText !=
          '${oldText.substring(0, oldCaret)}\n${oldText.substring(oldCaret)}') {
    return null;
  }
  final _Line line = _lineAt(oldText, oldCaret);
  final String lineText = oldText.substring(line.start, line.end);
  final ({int length, bool ordered, int? number})? marker =
      matchRichListMarker(lineText);
  if (marker == null || oldCaret - line.start < marker.length) return null;

  if (lineText.substring(marker.length).trim().isEmpty) {
    return RichEdit(
      text: oldText.replaceRange(line.start, line.end, ''),
      selectionStart: line.start,
      selectionEnd: line.start,
    );
  }
  final String next;
  if (marker.ordered) {
    final int? number = marker.number;
    if (number == null) return null;
    next = '${number + 1}. ';
  } else {
    next = '- ';
  }
  final int caret = oldCaret + 1 + next.length;
  return RichEdit(
    text: newText.replaceRange(oldCaret + 1, oldCaret + 1, next),
    selectionStart: caret,
    selectionEnd: caret,
  );
}

/// Removes the empty pair of [style] markers at [pairStart] if it is still
/// empty, moving [caret] with the text. Anything else is left as is.
RichEdit dropEmptyPair(
  String text,
  int pairStart,
  RichRunStyle style,
  int caret,
) {
  final int c = caret.clamp(0, text.length);
  if (style == RichRunStyle.plain) return _unchanged(text, c, c);
  final String pair = _marker(style) * 2;
  if (pairStart < 0 ||
      pairStart + pair.length > text.length ||
      text.substring(pairStart, pairStart + pair.length) != pair) {
    return _unchanged(text, c, c);
  }
  final List<_Edit> edits = <_Edit>[_Edit(pairStart, pair.length, '')];
  final int mapped = _map(edits, c, afterInsert: true);
  return RichEdit(
    text: _apply(text, edits),
    selectionStart: mapped,
    selectionEnd: mapped,
  );
}

// -- The collapsed caret ----------------------------------------------------

RichEdit _toggleAtCaret(
  String text,
  int caret,
  RichRunStyle style,
  String marker,
) {
  final _Line line = _lineAt(text, caret);
  final String lineText = text.substring(line.start, line.end);
  final int p = caret - line.start;

  for (final RichInlineMatch m in scanRichInline(lineText)) {
    if (m.start > p || p > m.end) continue;
    // Bold is not offered inside italic, nor italic inside bold.
    if (m.style != style) return _unchanged(text, caret, caret);
    final List<_Edit> edits = <_Edit>[
      _Edit(line.start + m.start, m.contentStart - m.start, ''),
      _Edit(line.start + m.contentEnd, m.end - m.contentEnd, ''),
    ];
    final int mapped = _map(edits, caret, afterInsert: true);
    return RichEdit(
      text: _apply(text, edits),
      selectionStart: mapped,
      selectionEnd: mapped,
    );
  }

  int ws = p;
  int we = p;
  while (ws > 0 && _isWordChar(lineText.codeUnitAt(ws - 1))) {
    ws--;
  }
  while (we < lineText.length && _isWordChar(lineText.codeUnitAt(we))) {
    we++;
  }
  if (ws < we) {
    return RichEdit(
      text: text.replaceRange(
        line.start + ws,
        line.start + we,
        '$marker${lineText.substring(ws, we)}$marker',
      ),
      selectionStart: caret + marker.length,
      selectionEnd: caret + marker.length,
    );
  }

  return RichEdit(
    text: text.replaceRange(caret, caret, marker * 2),
    selectionStart: caret + marker.length,
    selectionEnd: caret + marker.length,
    pendingPair: caret,
  );
}

/// Whether every touched line's selected part sits inside a [style] match.
bool _inside(
  String text,
  int s,
  int e,
  List<_Line> touched,
  RichRunStyle style,
) {
  if (touched.isEmpty) return false;
  for (final _Line line in touched) {
    final String lineText = text.substring(line.start, line.end);
    final int a = (s > line.start ? s : line.start) - line.start;
    final int b = (e < line.end ? e : line.end) - line.start;
    final bool covered = scanRichInline(lineText).any(
      (RichInlineMatch m) => m.style == style && m.start <= a && b <= m.end,
    );
    if (!covered) return false;
  }
  return true;
}

// -- Lines ------------------------------------------------------------------

/// One line by offset; [end] excludes its `\n`.
final class _Line {
  const _Line(this.start, this.end);

  final int start;
  final int end;

  bool isBlankIn(String text) => text.substring(start, end).trim().isEmpty;
}

List<_Line> _lines(String text) {
  final List<_Line> lines = <_Line>[];
  int start = 0;
  while (true) {
    final int nl = text.indexOf('\n', start);
    if (nl < 0) {
      lines.add(_Line(start, text.length));
      return lines;
    }
    lines.add(_Line(start, nl));
    start = nl + 1;
  }
}

_Line _lineAt(String text, int offset) =>
    _lines(text).firstWhere((_Line l) => l.start <= offset && offset <= l.end);

List<_Line> _touched(String text, int s, int e) {
  if (s < e) {
    final List<_Line> overlapping = <_Line>[
      for (final _Line l in _lines(text))
        if ((e < l.end ? e : l.end) > (s > l.start ? s : l.start)) l,
    ];
    if (overlapping.length > 1) {
      final List<_Line> nonBlank = <_Line>[
        for (final _Line l in overlapping)
          if (!l.isBlankIn(text)) l,
      ];
      if (nonBlank.isNotEmpty) return nonBlank;
    }
    if (overlapping.isNotEmpty) return overlapping;
  }
  return <_Line>[_lineAt(text, s)];
}

// -- Edits ------------------------------------------------------------------

/// Replace [length] characters at [at] with [insert], in the original
/// text's offsets.
final class _Edit {
  const _Edit(this.at, this.length, this.insert);

  final int at;
  final int length;
  final String insert;
}

/// Applies non-overlapping [edits] given in the original text's offsets.
String _apply(String text, List<_Edit> edits) {
  final List<_Edit> sorted = <_Edit>[...edits]
    ..sort((_Edit a, _Edit b) => a.at.compareTo(b.at));
  final StringBuffer out = StringBuffer();
  int last = 0;
  for (final _Edit edit in sorted) {
    out
      ..write(text.substring(last, edit.at))
      ..write(edit.insert);
    last = edit.at + edit.length;
  }
  out.write(text.substring(last));
  return out.toString();
}

/// Where [offset] lands after [edits]. An offset inside a removed stretch
/// lands where it was; one exactly at an insertion goes after it when
/// [afterInsert], before it otherwise.
int _map(List<_Edit> edits, int offset, {required bool afterInsert}) {
  int delta = 0;
  for (final _Edit edit in edits) {
    final int editEnd = edit.at + edit.length;
    if (edit.length == 0) {
      if (edit.at < offset || (edit.at == offset && afterInsert)) {
        delta += edit.insert.length;
      }
    } else if (editEnd <= offset) {
      delta += edit.insert.length - edit.length;
    } else if (edit.at < offset) {
      // Inside the removed stretch: land at its start, after any insert.
      delta += edit.at - offset + edit.insert.length;
    }
  }
  return offset + delta;
}

// -- Small helpers ----------------------------------------------------------

(int, int) _order(String text, int start, int end) {
  final int a = start.clamp(0, text.length);
  final int b = end.clamp(0, text.length);
  return a <= b ? (a, b) : (b, a);
}

RichEdit _unchanged(String text, int s, int e) =>
    RichEdit(text: text, selectionStart: s, selectionEnd: e);

String _marker(RichRunStyle style) =>
    style == RichRunStyle.bold ? '**' : '*';

bool _isSpace(int unit) =>
    unit == 0x20 || unit == 0x09 || unit == 0xA0 || unit == 0x3000;

final RegExp _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

bool _isWordChar(int unit) => _wordChar.hasMatch(String.fromCharCode(unit));
