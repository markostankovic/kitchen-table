/// Text normalization for search and ingredient matching.
///
/// This is one half of a contract. The other half is `normalize_text()` in
/// Postgres, and the two are verified against the same fixture list in
/// `test/fixtures/normalization.json`. Change one, change both, run the test
/// (CLAUDE.md rule 6, D5).
///
/// Two implementations that silently disagree is the worst failure mode in the
/// system: diacritic-insensitive search and every ingredient match tier depend
/// on this producing identical output on both sides.
///
/// Pure Dart. No Flutter imports (CLAUDE.md rule 7).
library;

/// Normalizes Serbian text to a diacritic-free Latin form.
///
/// The order of operations is load-bearing -- see [normalize].
class TextNormalizer {
  const TextNormalizer._();

  /// Cyrillic letters whose Latin form is more than one character.
  ///
  /// These must run *before* the single-character map: `њ` is one codepoint
  /// but two Latin letters, so a 1:1 translation cannot express it.
  static const Map<String, String> _cyrillicDigraphs = <String, String>{
    'њ': 'nj',
    'љ': 'lj',
    'џ': 'dz',
    'ђ': 'dj',
    'ћ': 'c',
    'ж': 'z',
  };

  /// 1:1 Cyrillic -> Latin. Parallel strings, indexed together.
  static const String _cyrillicFrom = 'абвгдезијклмнопрстуфхцчш';
  static const String _cyrillicTo = 'abvgdezijklmnoprstufhccs';

  /// Latin diacritics.
  ///
  /// `đ` -> `dj` is the reason Postgres `unaccent` is not usable here: it
  /// produces `d`, which splits *đuveč* from a user typing *djuvec* (D5).
  static const Map<String, String> _latinDiacritics = <String, String>{
    'č': 'c',
    'ć': 'c',
    'š': 's',
    'ž': 'z',
    'đ': 'dj',
  };

  static final RegExp _whitespace = RegExp(r'\s+');

  /// Returns [input] lowercased, transliterated to Latin, stripped of
  /// diacritics, with whitespace collapsed and trimmed.
  ///
  /// Punctuation is deliberately preserved: the ingredient line parser already
  /// splits notes off at the first comma, so stripping it here would only make
  /// two representations of the same line normalize identically when they
  /// should not.
  static String normalize(String input) {
    // 1. lowercase
    String s = input.toLowerCase();

    // 2a. Cyrillic -> Latin, digraphs first
    for (final MapEntry<String, String> e in _cyrillicDigraphs.entries) {
      s = s.replaceAll(e.key, e.value);
    }

    // 2b. Cyrillic -> Latin, remaining single characters
    final StringBuffer buffer = StringBuffer();
    for (final int rune in s.runes) {
      final String char = String.fromCharCode(rune);
      final int index = _cyrillicFrom.indexOf(char);
      buffer.write(index >= 0 ? _cyrillicTo[index] : char);
    }
    s = buffer.toString();

    // 3. Latin diacritics
    for (final MapEntry<String, String> e in _latinDiacritics.entries) {
      s = s.replaceAll(e.key, e.value);
    }

    // 4. collapse whitespace, trim
    return s.replaceAll(_whitespace, ' ').trim();
  }
}
