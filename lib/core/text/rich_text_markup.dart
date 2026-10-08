/// The light-formatting subset recipe text may hold (D165): `**bold**`,
/// `*italic*`, `- ` bullet lists and `1. ` numbered lists. Nothing else --
/// no `#` headings, links, code, `_`, `+`/`*` bullets or indented sub-lists.
///
/// The rules, line by line, after `\r\n` / `\r` become `\n`:
///
/// - `- x` at column 0 is a bullet item; `12. x` is a numbered item whose
///   marker is kept exactly as typed (`3.` stays `3.` -- never renumbered).
/// - Consecutive items of the same kind are one list; a change of kind
///   starts a new list.
/// - Every other non-blank line is its own paragraph. A single `\n` and a
///   blank line read the same.
/// - Blank lines emit nothing and end any open list; several collapse.
/// - Inline runs: `**…**` bold, `*…*` italic, left to right, no nesting.
///   An unmatched `*` or `**` stays literal.
///
/// Parsing is total: any string parses, and the worst case is literal
/// markers in plain runs. `AppRichText` renders the result. The recipe
/// editor's formatting toolbar and styled fields (D166) use the
/// offset-carrying [scanRichInline] and [matchRichListMarker], so the three
/// regexes have one definition each.
///
/// Pure Dart. No Flutter imports (CLAUDE.md rule 7).
library;

/// How one inline run is drawn.
enum RichRunStyle { plain, bold, italic }

/// A stretch of text in one [RichRunStyle].
final class RichRun {
  const RichRun(this.text, this.style);

  final String text;
  final RichRunStyle style;

  @override
  bool operator ==(Object other) =>
      other is RichRun && other.text == text && other.style == style;

  @override
  int get hashCode => Object.hash(text, style);

  @override
  String toString() => 'RichRun(${style.name}, "$text")';
}

/// One block of parsed text: a [RichParagraph] or a [RichList].
sealed class RichBlock {
  const RichBlock();
}

/// One non-blank, non-item line.
final class RichParagraph extends RichBlock {
  const RichParagraph(this.runs);

  final List<RichRun> runs;
}

/// Consecutive items of one kind.
final class RichList extends RichBlock {
  const RichList({required this.ordered, required this.items});

  final bool ordered;
  final List<RichListItem> items;
}

/// One list item. [number] is the marker as typed (`'3.'`), or null for a
/// bullet.
final class RichListItem {
  const RichListItem({required this.number, required this.runs});

  final String? number;
  final List<RichRun> runs;
}

final RegExp _bullet = RegExp(r'^- (.*)$');
final RegExp _numbered = RegExp(r'^(\d+)\. (.*)$');
final RegExp _inline = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');

/// Splits [text] into blocks. Empty or all-blank input gives `[]`.
List<RichBlock> parseRichText(String text) {
  final List<RichBlock> blocks = <RichBlock>[];
  List<RichListItem>? openItems;
  bool openOrdered = false;

  void closeList() {
    if (openItems != null) {
      blocks.add(RichList(ordered: openOrdered, items: openItems!));
      openItems = null;
    }
  }

  void addItem({required bool ordered, required RichListItem item}) {
    if (openItems != null && openOrdered != ordered) closeList();
    openOrdered = ordered;
    (openItems ??= <RichListItem>[]).add(item);
  }

  final String normalized = text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
  for (final String line in normalized.split('\n')) {
    final RegExpMatch? bullet = _bullet.firstMatch(line);
    if (bullet != null) {
      addItem(
        ordered: false,
        item: RichListItem(number: null, runs: parseRichRuns(bullet[1]!)),
      );
      continue;
    }
    final RegExpMatch? numbered = _numbered.firstMatch(line);
    if (numbered != null) {
      addItem(
        ordered: true,
        item: RichListItem(
          number: '${numbered[1]}.',
          runs: parseRichRuns(numbered[2]!),
        ),
      );
      continue;
    }
    closeList();
    if (line.trim().isNotEmpty) blocks.add(RichParagraph(parseRichRuns(line)));
  }
  closeList();
  return blocks;
}

/// One inline match in a line, by offset. [start] and [end] include the
/// markers; [contentStart] and [contentEnd] are what sits between them.
final class RichInlineMatch {
  const RichInlineMatch({
    required this.start,
    required this.end,
    required this.contentStart,
    required this.contentEnd,
    required this.style,
  });

  final int start;
  final int end;
  final int contentStart;
  final int contentEnd;

  /// [RichRunStyle.bold] or [RichRunStyle.italic], never plain.
  final RichRunStyle style;

  @override
  bool operator ==(Object other) =>
      other is RichInlineMatch &&
      other.start == start &&
      other.end == end &&
      other.contentStart == contentStart &&
      other.contentEnd == contentEnd &&
      other.style == style;

  @override
  int get hashCode =>
      Object.hash(start, end, contentStart, contentEnd, style);

  @override
  String toString() =>
      'RichInlineMatch(${style.name}, $start-$end, content '
      '$contentStart-$contentEnd)';
}

/// Every inline match in one line, left to right, by offset: `**…**` bold,
/// `*…*` italic, no nesting. The gaps between matches are plain.
List<RichInlineMatch> scanRichInline(String line) => <RichInlineMatch>[
  for (final RegExpMatch match in _inline.allMatches(line))
    if (match[1] != null)
      RichInlineMatch(
        start: match.start,
        end: match.end,
        contentStart: match.start + 2,
        contentEnd: match.end - 2,
        style: RichRunStyle.bold,
      )
    else
      RichInlineMatch(
        start: match.start,
        end: match.end,
        contentStart: match.start + 1,
        contentEnd: match.end - 1,
        style: RichRunStyle.italic,
      ),
];

/// The column-0 list marker [line] starts with, if it is an item: its
/// length (`- ` is 2, `12. ` is 4), whether it is numbered, and the number
/// as typed (null for a bullet, or for digits too long for an int).
({int length, bool ordered, int? number})? matchRichListMarker(String line) {
  if (_bullet.hasMatch(line)) {
    return (length: 2, ordered: false, number: null);
  }
  final RegExpMatch? numbered = _numbered.firstMatch(line);
  if (numbered == null) return null;
  return (
    length: numbered[1]!.length + 2,
    ordered: true,
    number: int.tryParse(numbered[1]!),
  );
}

/// Splits one line into inline runs: `**…**` bold, `*…*` italic, the gaps
/// plain. No nesting; an unmatched marker stays literal.
List<RichRun> parseRichRuns(String line) {
  final List<RichRun> runs = <RichRun>[];
  int last = 0;
  for (final RichInlineMatch match in scanRichInline(line)) {
    if (match.start > last) {
      runs.add(RichRun(line.substring(last, match.start), RichRunStyle.plain));
    }
    runs.add(
      RichRun(
        line.substring(match.contentStart, match.contentEnd),
        match.style,
      ),
    );
    last = match.end;
  }
  if (last < line.length) {
    runs.add(RichRun(line.substring(last), RichRunStyle.plain));
  }
  return runs;
}

/// [text] with its markup taken out, for a one-line preview: each line's
/// column-0 list marker dropped and its inline runs joined, the lines joined
/// with `\n`. What [parseRichText] would draw, minus the drawing; an
/// unmatched marker stays literal, as it does there. The caller collapses
/// whitespace if it wants one line.
String richPlainText(String text) => text
    .replaceAll('\r\n', '\n')
    .replaceAll('\r', '\n')
    .split('\n')
    .map((String line) {
      final int marker = matchRichListMarker(line)?.length ?? 0;
      return parseRichRuns(
        line.substring(marker),
      ).map((RichRun run) => run.text).join();
    })
    .join('\n');
