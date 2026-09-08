import '../../../core/text/text_normalizer.dart';
import 'parsed_ingredient_line.dart';
import 'quantity.dart';
import 'unit_catalog.dart';

/// Tier 1 of docs/INGREDIENTS.md's pipeline: turn `2 šolje glatkog brašna,
/// prosejano` into a quantity, a unit, a name and a note, deterministically
/// and without reaching for a model.
///
/// D31 puts this in Dart rather than in Postgres. It touches no data -- it is
/// string work over a unit lexicon -- so a round trip would buy nothing and
/// cost the responsiveness Phase 1c's line editor needs while someone types.
/// Phase 1d adds a Deno mirror for the import functions, driven by the same
/// `test/fixtures/ingredient_lines.json`, exactly as normalization is (D5).
///
/// The contract, and the reason a failed parse is not a bug (CLAUDE.md rule 3):
/// [ParsedIngredientLine.rawText] is always the line as written. Everything
/// else is an enhancement. If nothing is recognised, [name] is the whole line
/// and the cook still sees what they typed.
///
/// Pure Dart (rule 7). No I/O: the lexicon is injected.
class IngredientLineParser {
  const IngredientLineParser(this.units);

  /// Injected so the parser stays pure and offline-capable. Pass
  /// `UnitCatalog.empty()` and quantities, names and notes still parse -- only
  /// unit resolution stops.
  final UnitCatalog units;

  /// Words that stand in for a number.
  static const Map<String, (int, int)> _wordQuantities = <String, (int, int)>{
    'pola': (1, 2),
    'par': (2, 1),
    'half': (1, 2),
  };

  /// Unicode vulgar fractions, which cookbook scans and pasted web text are
  /// full of. `normalize_text` leaves them alone, so they arrive intact.
  static const Map<String, (int, int)> _vulgarFractions = <String, (int, int)>{
    '½': (1, 2), '⅓': (1, 3), '⅔': (2, 3), '¼': (1, 4), '¾': (3, 4),
    '⅕': (1, 5), '⅖': (2, 5), '⅗': (3, 5), '⅘': (4, 5), '⅙': (1, 6),
    '⅚': (5, 6), '⅛': (1, 8), '⅜': (3, 8), '⅝': (5, 8), '⅞': (7, 8),
  };

  /// Trailing markers that mean "this line is discretionary".
  ///
  /// `po ukusu` is in this list even though it is also seeded as a unit with
  /// family `other`. Where a recipe actually writes it -- at the end of a line
  /// -- it is a note, not a measurement, and treating it as a note is what
  /// lets `so po ukusu` come out as the ingredient `so`. The unit code exists
  /// for imports that carry an explicit "to taste" quantity field.
  static const List<String> _optionalMarkers = <String>[
    'po ukusu',
    'po zelji',
    'opciono',
    'optional',
    'to taste',
    'if desired',
  ];

  /// The three dash characters that appear in real recipe text.
  static const String _dashes = '-–—';

  static final RegExp _parenthesised = RegExp(r'\(([^)]*)\)');
  static final RegExp _whitespace = RegExp(r'\s+');

  /// A number followed immediately by letters: `500g`, `1,5dl`.
  static final RegExp _numberUnit =
      RegExp(r'^(\d+(?:[.,]\d+)?)([^\d\s]+)$');

  ParsedIngredientLine parse(String rawText) {
    final List<String> notes = <String>[];

    // 1. Parenthesised text is always a note, wherever it sits.
    String work = rawText.replaceAllMapped(_parenthesised, (Match m) {
      final String inner = (m.group(1) ?? '').trim();
      if (inner.isNotEmpty) notes.add(inner);
      return ' ';
    });

    // 2. Everything after the first comma is a note.
    final int comma = _noteCommaIndex(work);
    if (comma >= 0) {
      final String tail = work.substring(comma + 1).trim();
      work = work.substring(0, comma);
      if (tail.isNotEmpty) notes.insert(0, tail);
    }

    work = work.replaceAll(_whitespace, ' ').trim();

    // 3. Optional markers, whether they ended up in the notes or are still
    //    trailing the line itself.
    bool isOptional = false;
    for (final String marker in _optionalMarkers) {
      if (notes.any((String n) => TextNormalizer.normalize(n) == marker)) {
        isOptional = true;
      }
      final String stripped = _stripTrailingMarker(work, marker);
      if (stripped != work) {
        isOptional = true;
        notes.add(work.substring(stripped.length).trim());
        work = stripped;
      }
    }

    // 4. Tokenise once. Originals are kept alongside their normalized forms so
    //    the name comes back as written -- the parser does not de-inflect (D6).
    final List<String> tokens = <String>[];
    for (final String token
        in work.isEmpty ? <String>[] : work.split(_whitespace)) {
      final (String, String)? split = _splitNumberUnit(token);
      if (split == null) {
        tokens.add(token);
      } else {
        tokens
          ..add(split.$1)
          ..add(split.$2);
      }
    }
    final List<String> normalized =
        tokens.map(TextNormalizer.normalize).toList();

    int cursor = 0;

    // 5. Quantity.
    final (Quantity, int)? quantity = _readQuantity(normalized, cursor);
    Quantity? qty;
    if (quantity != null) {
      qty = quantity.$1;
      cursor = quantity.$2;
    }

    // 6. Unit. Two tokens first: `supena kašika` and `čajna kašičica` would
    //    otherwise resolve on their first word alone, or not at all.
    String? unitCode;
    if (cursor < normalized.length) {
      if (cursor + 1 < normalized.length) {
        final String pair =
            '${normalized[cursor]} ${normalized[cursor + 1]}';
        final String? code = units.resolveCode(pair);
        if (code != null) {
          unitCode = code;
          cursor += 2;
        }
      }
      if (unitCode == null) {
        final String? code = units.resolveCode(normalized[cursor]);
        // A unit is only a unit here if something follows it. `2 kašike` on
        // its own line is a quantity of an unnamed thing, but `šolja` alone is
        // far more likely to be somebody's ingredient than a bare unit.
        if (code != null && (qty != null || cursor + 1 < normalized.length)) {
          unitCode = code;
          cursor += 1;
        }
      }
    }

    // 7. Whatever is left is the name, verbatim.
    final String name = tokens.skip(cursor).join(' ').trim();

    return ParsedIngredientLine(
      rawText: rawText,
      quantity: qty,
      unitCode: unitCode,
      name: name.isEmpty ? null : name,
      note: notes.isEmpty ? null : notes.join(', '),
      isOptional: isOptional,
    );
  }

  /// Splits `500g` into `500` and `g`, or null if [token] is not that shape.
  ///
  /// Real recipe pages write the quantity and the unit as one word far more
  /// often than not -- `500g beef mince`, `200ml mleka` -- and before this the
  /// whole line parsed to no quantity and no unit at all. Found by importing
  /// actual pages in Phase 1d part 4, which is exactly the case
  /// `test/fixtures/ingredient_lines.json` asks to be told about.
  ///
  /// Only splits when the tail IS a known unit. Unconditional splitting would
  /// be shorter and would also invent a quantity out of any ingredient whose
  /// first word happened to start with a digit. The digit-free tail is what
  /// keeps `1/2`, `2-3` and `1½` out of here -- each of those has a digit or a
  /// vulgar fraction after the number, and each is already handled below.
  (String, String)? _splitNumberUnit(String token) {
    final RegExpMatch? m = _numberUnit.firstMatch(token);
    if (m == null) return null;

    final String number = m.group(1)!;
    final String tail = m.group(2)!;
    if (units.resolveCode(tail) == null) return null;

    return (number, tail);
  }

  /// Reads a quantity starting at [start]. Returns it with the index of the
  /// first token after it, or null if the line does not begin with a number.
  (Quantity, int)? _readQuantity(List<String> tokens, int start) {
    if (start >= tokens.length) return null;

    // `2-3`, `2–3` as a single token.
    final (Quantity, int)? single = _readDashRange(tokens, start);
    if (single != null) return single;

    final (int, int)? first = _readValue(tokens, start);
    if (first == null) return null;
    int cursor = start + first.$2;
    (int, int) lower = (first.$1, _denominatorOf(tokens, start));

    // A mixed number: `1 1/2`, or `1 ½`.
    if (lower.$2 == 1 && cursor < tokens.length) {
      final (int, int)? frac = _readPureFraction(tokens[cursor]);
      if (frac != null) {
        lower = (lower.$1 * frac.$2 + frac.$1, frac.$2);
        cursor += 1;
      }
    }

    // A spaced range: `2 - 3`.
    if (cursor + 1 < tokens.length &&
        tokens[cursor].length == 1 &&
        _dashes.contains(tokens[cursor])) {
      final (int, int)? upper = _readNumeric(tokens[cursor + 1]);
      if (upper != null) {
        return (
          Quantity.range(
            numerator: lower.$1,
            denominator: lower.$2,
            maxNumerator: upper.$1,
            maxDenominator: upper.$2,
          ),
          cursor + 2,
        );
      }
    }

    return (Quantity.fraction(lower.$1, lower.$2), cursor);
  }

  /// `2-3` and friends, where the dash is inside the token.
  (Quantity, int)? _readDashRange(List<String> tokens, int start) {
    final String token = tokens[start];
    for (int i = 1; i < token.length; i++) {
      if (!_dashes.contains(token[i])) continue;
      final (int, int)? lower = _readNumeric(token.substring(0, i));
      final (int, int)? upper = _readNumeric(token.substring(i + 1));
      if (lower != null && upper != null) {
        return (
          Quantity.range(
            numerator: lower.$1,
            denominator: lower.$2,
            maxNumerator: upper.$1,
            maxDenominator: upper.$2,
          ),
          start + 1,
        );
      }
    }
    return null;
  }

  /// The numerator half of a leading value, plus how many tokens it consumed.
  /// Paired with [_denominatorOf] so a mixed number can be assembled without
  /// parsing the same token twice.
  (int, int)? _readValue(List<String> tokens, int index) {
    final (int, int)? numeric = _readNumeric(tokens[index]);
    if (numeric != null) return (numeric.$1, 1);

    final (int, int)? word = _wordQuantities[tokens[index]];
    if (word != null) return (word.$1, 1);

    return null;
  }

  int _denominatorOf(List<String> tokens, int index) {
    final (int, int)? numeric = _readNumeric(tokens[index]);
    if (numeric != null) return numeric.$2;
    return _wordQuantities[tokens[index]]?.$2 ?? 1;
  }

  /// A whole number, fraction, decimal or vulgar fraction in one token.
  (int, int)? _readNumeric(String token) {
    if (token.isEmpty) return null;

    final (int, int)? pure = _readPureFraction(token);
    if (pure != null) return pure;

    // `1½`
    final String last = token.substring(token.length - 1);
    final (int, int)? vulgar = _vulgarFractions[last];
    if (vulgar != null && token.length > 1) {
      final int? whole = int.tryParse(token.substring(0, token.length - 1));
      if (whole != null) {
        return (whole * vulgar.$2 + vulgar.$1, vulgar.$2);
      }
    }

    // `1,5` and `1.5`. Serbian writes the decimal comma, but the comma split
    // happens before this, so only a comma with no space around it survives --
    // which is exactly how a decimal is written.
    final int dot = token.indexOf(RegExp('[.,]'));
    if (dot > 0 && dot < token.length - 1) {
      final int? whole = int.tryParse(token.substring(0, dot));
      final String fracDigits = token.substring(dot + 1);
      final int? frac = int.tryParse(fracDigits);
      if (whole != null && frac != null) {
        int denominator = 1;
        for (int i = 0; i < fracDigits.length; i++) {
          denominator *= 10;
        }
        return (whole * denominator + frac, denominator);
      }
    }

    final int? whole = int.tryParse(token);
    return whole == null ? null : (whole, 1);
  }

  /// `1/2`, or a bare vulgar fraction.
  (int, int)? _readPureFraction(String token) {
    final (int, int)? vulgar = _vulgarFractions[token];
    if (vulgar != null) return vulgar;

    final int slash = token.indexOf('/');
    if (slash <= 0 || slash == token.length - 1) return null;
    final int? numerator = int.tryParse(token.substring(0, slash));
    final int? denominator = int.tryParse(token.substring(slash + 1));
    if (numerator == null || denominator == null || denominator == 0) {
      return null;
    }
    return (numerator, denominator);
  }

  /// Index of the first comma that separates a note, or -1.
  ///
  /// A comma between two digits is a Serbian decimal point, not a separator.
  /// Splitting on it would turn `1,5 dl vode` into the quantity 1 and the note
  /// `5 dl vode` -- silently, and wrong by a factor of ten in the direction
  /// nobody checks.
  int _noteCommaIndex(String text) {
    for (int i = 0; i < text.length; i++) {
      if (text[i] != ',') continue;
      final bool digitBefore = i > 0 && _isDigit(text[i - 1]);
      final bool digitAfter = i + 1 < text.length && _isDigit(text[i + 1]);
      if (digitBefore && digitAfter) continue;
      return i;
    }
    return -1;
  }

  static bool _isDigit(String character) {
    final int code = character.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }

  /// Removes [marker] from the end of [text] if it is there, comparing
  /// normalized so `po želji` and `po zelji` both strip.
  String _stripTrailingMarker(String text, String marker) {
    final List<String> words = marker.split(' ');
    final List<String> tokens =
        text.isEmpty ? <String>[] : text.split(_whitespace);
    if (tokens.length <= words.length) return text;

    final List<String> tail = tokens
        .skip(tokens.length - words.length)
        .map(TextNormalizer.normalize)
        .toList();
    if (tail.join(' ') != marker) return text;

    return tokens.take(tokens.length - words.length).join(' ');
  }
}
