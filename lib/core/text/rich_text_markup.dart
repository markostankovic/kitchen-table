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
/// markers in plain runs. `AppRichText` renders the result; the editing
/// toolbar reuses [parseRichRuns].
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

/// Splits one line into inline runs: `**…**` bold, `*…*` italic, the gaps
/// plain. No nesting; an unmatched marker stays literal.
List<RichRun> parseRichRuns(String line) {
  final List<RichRun> runs = <RichRun>[];
  int last = 0;
  for (final RegExpMatch match in _inline.allMatches(line)) {
    if (match.start > last) {
      runs.add(RichRun(line.substring(last, match.start), RichRunStyle.plain));
    }
    runs.add(
      match[1] != null
          ? RichRun(match[1]!, RichRunStyle.bold)
          : RichRun(match[2]!, RichRunStyle.italic),
    );
    last = match.end;
  }
  if (last < line.length) {
    runs.add(RichRun(line.substring(last), RichRunStyle.plain));
  }
  return runs;
}
