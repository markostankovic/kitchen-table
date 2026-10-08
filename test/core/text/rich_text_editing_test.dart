import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/text/rich_text_editing.dart';
import 'package:kitchen_table/core/text/rich_text_markup.dart';

/// Text with its selection written in: `|` is a collapsed caret, `[` and `]`
/// the two ends of a selection. None of the cases use those characters
/// otherwise.
(String, int, int) _parse(String marked) {
  final int caret = marked.indexOf('|');
  if (caret >= 0) return (marked.replaceFirst('|', ''), caret, caret);
  final int start = marked.indexOf('[');
  final String once = marked.replaceFirst('[', '');
  final int end = once.indexOf(']');
  return (once.replaceFirst(']', ''), start, end);
}

String _show(RichEdit edit) {
  final String text = edit.text;
  if (edit.selectionStart == edit.selectionEnd) {
    return text.replaceRange(edit.selectionStart, edit.selectionStart, '|');
  }
  return text
      .replaceRange(edit.selectionEnd, edit.selectionEnd, ']')
      .replaceRange(edit.selectionStart, edit.selectionStart, '[');
}

void main() {
  group('richFormatState', () {
    RichFormatState state(String marked) {
      final (String text, int start, int end) = _parse(marked);
      return richFormatState(text, start, end);
    }

    final List<(String, String, RichFormatState)> cases =
        <(String, String, RichFormatState)>[
          ('plain caret', 'ab|c', const RichFormatState()),
          (
            'caret inside bold disables italic',
            '**ab|c**',
            const RichFormatState(bold: true, italicEnabled: false),
          ),
          (
            'caret touching a bold marker counts',
            '|**abc** d',
            const RichFormatState(bold: true, italicEnabled: false),
          ),
          (
            'caret inside italic disables bold',
            'x *a|b*',
            const RichFormatState(italic: true, boldEnabled: false),
          ),
          (
            'a selection inside bold',
            '**a[bc]d**',
            const RichFormatState(bold: true, italicEnabled: false),
          ),
          (
            'a selection running out of bold is not bold',
            '**a[bc**d]',
            const RichFormatState(),
          ),
          (
            'multi-line: every line must be bold',
            '**[a**\n**b]**',
            const RichFormatState(bold: true, italicEnabled: false),
          ),
          (
            'multi-line: one plain line is enough to say no',
            '**[a**\nb]',
            const RichFormatState(),
          ),
          ('a bullet line', '- a|b', const RichFormatState(bullet: true)),
          ('a numbered line', '3. a|b', const RichFormatState(numbered: true)),
          (
            'blank lines in a selection are ignored',
            '- [a\n\n- b]',
            const RichFormatState(bullet: true),
          ),
          (
            'a mix of kinds is neither',
            '- [a\n1. b]',
            const RichFormatState(),
          ),
          (
            'a bold word in a bullet',
            '- **a|b**',
            const RichFormatState(
              bold: true,
              bullet: true,
              italicEnabled: false,
            ),
          ),
        ];

    for (final (String name, String marked, RichFormatState expected)
        in cases) {
      test(name, () => expect(state(marked), expected));
    }
  });

  group('toggleInline', () {
    String run(String marked, RichRunStyle style) {
      final (String text, int start, int end) = _parse(marked);
      return _show(toggleInline(text, start, end, style));
    }

    const RichRunStyle b = RichRunStyle.bold;
    const RichRunStyle i = RichRunStyle.italic;

    final List<(String, String, RichRunStyle, String)> cases =
        <(String, String, RichRunStyle, String)>[
          (
            'a selection is wrapped and stays selected on its content',
            'Umesi [testo] lagano',
            b,
            'Umesi **[testo]** lagano',
          ),
          (
            'surrounding whitespace stays outside the markers',
            'a[ bc ]d',
            b,
            'a **[bc]** d',
          ),
          ('italic wraps with one *', 'a [bc] d', i, 'a *[bc]* d'),
          (
            'a selection over a bold match unwraps it',
            '[**ab**]',
            b,
            '[ab]',
          ),
          (
            'a selection inside a bold match unwraps it',
            '**a[b]c**',
            b,
            'a[b]c',
          ),
          (
            'a selection next to a bold match wraps, not unwraps',
            '**x**[foo]',
            b,
            '**x****[foo]**',
          ),
          (
            'every touched match of the style is unwrapped',
            '[**a** b **c**]',
            b,
            '[a b c]',
          ),
          (
            'multi-line: each line is wrapped on its own, the selection '
                'kept on the same characters',
            'a[b\n\ncd]e',
            b,
            'a**[b**\n\n**cd]**e',
          ),
          (
            'a caret in a word wraps the word, keeping its place',
            'Dodaj šeć|er polako',
            b,
            'Dodaj **šeć|er** polako',
          ),
          (
            'a caret at the end of a word wraps it',
            'so|',
            i,
            '*so|*',
          ),
          (
            'a caret in a bold word unwraps it',
            '**šeć|er**',
            b,
            'šeć|er',
          ),
          (
            'a caret on a space inserts an empty pair',
            'a | b',
            b,
            'a **|** b',
          ),
          ('an empty field gets an empty pair', '|', i, '*|*'),
          (
            'italic at a caret inside bold is a no-op',
            '**a|b**',
            i,
            '**a|b**',
          ),
          (
            'a whitespace-only selection is a no-op',
            'a[  ]b',
            b,
            'a[  ]b',
          ),
        ];

    for (final (String name, String marked, RichRunStyle style, String out)
        in cases) {
      test(name, () => expect(run(marked, style), out));
    }

    test('the empty pair is reported pending', () {
      final RichEdit edit = toggleInline('a  b', 2, 2, RichRunStyle.bold);
      expect(edit.pendingPair, 2);
      expect(
        toggleInline('ab', 1, 1, RichRunStyle.bold).pendingPair,
        isNull,
      );
    });
  });

  group('toggleList', () {
    String run(String marked, {required bool ordered}) {
      final (String text, int start, int end) = _parse(marked);
      return _show(toggleList(text, start, end, ordered: ordered));
    }

    final List<(String, String, bool, String)> cases =
        <(String, String, bool, String)>[
          ('a caret line gets a bullet', 'ab|c', false, '- ab|c'),
          ('a bullet comes off', '- ab|c', false, 'ab|c'),
          (
            'a lone blank caret line gets a bullet, caret after it',
            'a\n|',
            false,
            'a\n- |',
          ),
          (
            'every touched line, blank ones skipped',
            '[a\n\nb]',
            false,
            '- [a\n\n- b]',
          ),
          (
            'a numbered line loses its number for a bullet',
            '1. a|',
            false,
            '- a|',
          ),
          (
            'a mixed selection is all bulleted',
            '[- a\nb]',
            false,
            '[- a\n- b]',
          ),
          (
            'numbering starts at 1',
            '[a\nb\nc]',
            true,
            '1. [a\n2. b\n3. c]',
          ),
          (
            'numbering continues from 3. above',
            '3. x\n[a\nb]',
            true,
            '3. x\n4. [a\n5. b]',
          ),
          (
            'lines below are never renumbered',
            '[a]\n1. y',
            true,
            '1. [a]\n1. y',
          ),
          (
            'a bullet becomes a number',
            '- a|',
            true,
            '1. a|',
          ),
          (
            'numbers come off when every line is numbered',
            '[1. a\n7. b]',
            true,
            '[a\nb]',
          ),
          (
            'a caret inside the marker lands at the line start',
            '1|2. a',
            true,
            '|a',
          ),
        ];

    for (final (String name, String marked, bool ordered, String out)
        in cases) {
      test(name, () => expect(run(marked, ordered: ordered), out));
    }
  });

  group('continueListOnNewline', () {
    String? enter(String marked) {
      final (String text, int caret, _) = _parse(marked);
      final String typed = text.replaceRange(caret, caret, '\n');
      final RichEdit? edit = continueListOnNewline(text, caret, typed);
      return edit == null ? null : _show(edit);
    }

    final List<(String, String, String?)> cases = <(String, String, String?)>[
      ('a bullet continues', '- a|', '- a\n- |'),
      ('a number continues', '3. a|', '3. a\n4. |'),
      ('Enter on an empty bullet ends the list', '- a\n- |', '- a\n|'),
      ('Enter on an empty number ends the list', '1. a\n2. |', '1. a\n|'),
      (
        'Enter mid-content splits the item',
        '- ab|cd',
        '- ab\n- |cd',
      ),
      ('Enter in a paragraph passes through', 'ab|', null),
      ('Enter inside the marker passes through', '-| a', null),
    ];

    for (final (String name, String marked, String? out) in cases) {
      test(name, () => expect(enter(marked), out));
    }

    test('anything but one inserted newline passes through', () {
      expect(continueListOnNewline('- a', 3, '- ab'), isNull);
      expect(continueListOnNewline('- a', 3, '- a\n\n'), isNull);
      expect(continueListOnNewline('- a', 1, '- a\n'), isNull);
    });
  });

  group('dropEmptyPair', () {
    test('an empty pair goes, the caret with it', () {
      final RichEdit edit = dropEmptyPair('a **** b', 2, RichRunStyle.bold, 4);
      expect(_show(edit), 'a | b');
    });

    test('a caret after it shifts back', () {
      final RichEdit edit = dropEmptyPair('a ** b', 2, RichRunStyle.italic, 6);
      expect(_show(edit), 'a  b|');
    });

    test('a pair that was typed into stays', () {
      final RichEdit edit = dropEmptyPair('a **x** b', 2, RichRunStyle.bold, 5);
      expect(_show(edit), 'a **x|** b');
    });
  });

  group('richSegments', () {
    String show(String text) => richSegments(text)
        .map(
          (RichSegment s) =>
              '${s.kind.name[0]}(${text.substring(s.start, s.end)})',
        )
        .join();

    test('markers, content and plain text, in order', () {
      expect(
        show('- a **b** *c*\n12. d'),
        'm(- )p(a )m(**)b(b)m(**)p( )m(*)i(c)m(*)p(\n)m(12. )p(d)',
      );
    });

    test('cover the text exactly', () {
      for (final String text in <String>[
        '',
        '\n',
        'a\n\nb',
        '****',
        '- \n1. ',
        '**a *b* c**',
        'Šargarepa **torta**\n- so *po* ukusu',
      ]) {
        expect(
          richSegments(text)
              .map((RichSegment s) => text.substring(s.start, s.end))
              .join(),
          text,
          reason: text,
        );
      }
    });
  });
}
