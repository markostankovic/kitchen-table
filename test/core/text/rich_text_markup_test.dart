import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/text/rich_text_markup.dart';

/// A compact, comparable picture of the parse: `P[...]` for a paragraph,
/// `UL[...]` / `OL[...]` for a list, runs as `text`, `B(text)`, `I(text)`.
String _show(List<RichBlock> blocks) => blocks
    .map(
      (RichBlock block) => switch (block) {
        RichParagraph(:final List<RichRun> runs) => 'P[${_runs(runs)}]',
        RichList(:final bool ordered, :final List<RichListItem> items) =>
          '${ordered ? 'OL' : 'UL'}[${items.map((RichListItem i) => '${i.number ?? '•'} ${_runs(i.runs)}').join(' | ')}]',
      },
    )
    .join(' ');

String _runs(List<RichRun> runs) => runs
    .map(
      (RichRun r) => switch (r.style) {
        RichRunStyle.plain => r.text,
        RichRunStyle.bold => 'B(${r.text})',
        RichRunStyle.italic => 'I(${r.text})',
      },
    )
    .join();

void main() {
  group('parseRichText', () {
    final List<(String, String, String)> cases = <(String, String, String)>[
      ('empty input', '', ''),
      ('all-blank input', '  \n\n \t', ''),
      ('one plain line', 'Zagrej rernu.', 'P[Zagrej rernu.]'),
      (
        'canvas description',
        'Potato dough wrapped around a **whole plum**, rolled in buttery '
            'crumbs. *Knedle* the way Grandma Ljubica made them.',
        'P[Potato dough wrapped around a B(whole plum), rolled in buttery '
            'crumbs. I(Knedle) the way Grandma Ljubica made them.]',
      ),
      (
        'canvas step',
        'Work in the flour and egg. **Don\'t over-knead** — stop when it '
            'holds.\n- 2 cups first, then the rest a spoonful at a time\n'
            '- a pinch of salt',
        'P[Work in the flour and egg. B(Don\'t over-knead) — stop when it '
            'holds.] UL[• 2 cups first, then the rest a spoonful at a time '
            '| • a pinch of salt]',
      ),
      (
        'canvas end note',
        'To freeze:\n1. Freeze uncooked on a floured tray.\n2. Bag once '
            'firm.\n3. Cook from frozen, 4 minutes longer.',
        'P[To freeze:] OL[1. Freeze uncooked on a floured tray. | 2. Bag '
            'once firm. | 3. Cook from frozen, 4 minutes longer.]',
      ),
      ('\\r\\n and \\r are newlines', 'a\r\nb\rc', 'P[a] P[b] P[c]'),
      ('numbers are kept as typed', '3. x\n7. y', 'OL[3. x | 7. y]'),
      ('multi-digit numbers', '10. x', 'OL[10. x]'),
      (
        'a change of kind starts a new list',
        '- a\n1. b\n- c',
        'UL[• a] OL[1. b] UL[• c]',
      ),
      ('a blank line ends a list', '- a\n\n- b', 'UL[• a] UL[• b]'),
      ('blank lines collapse', 'a\n\n\n\nb', 'P[a] P[b]'),
      ('a single newline is two paragraphs', 'a\nb', 'P[a] P[b]'),
      ('a paragraph ends a list', '- a\nb\n- c', 'UL[• a] P[b] UL[• c]'),
      ('unmatched * stays literal', '2 * 3', 'P[2 * 3]'),
      ('unmatched ** stays literal', 'a **b', 'P[a **b]'),
      ('no nesting', '**a *b* c**', 'P[B(a *b* c)]'),
      ('* at line start is not a bullet', '* x', 'P[* x]'),
      ('indented hyphen is not a bullet', '  - x', 'P[  - x]'),
      ('hyphen without a space is not a bullet', '-x', 'P[-x]'),
      ('# is text', '# x', 'P[# x]'),
      ('runs inside items', '- **a** and *b*', 'UL[• B(a) and I(b)]'),
    ];

    for (final (String name, String input, String expected) in cases) {
      test(name, () => expect(_show(parseRichText(input)), expected));
    }
  });

  group('parseRichRuns', () {
    test('splits bold, italic and plain left to right', () {
      expect(parseRichRuns('a **b** c *d*'), const <RichRun>[
        RichRun('a ', RichRunStyle.plain),
        RichRun('b', RichRunStyle.bold),
        RichRun(' c ', RichRunStyle.plain),
        RichRun('d', RichRunStyle.italic),
      ]);
    });

    test('an empty line has no runs', () {
      expect(parseRichRuns(''), isEmpty);
    });
  });
}
