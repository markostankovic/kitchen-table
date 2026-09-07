import '../../../core/text/text_normalizer.dart';
import 'unit.dart';

/// The unit lexicon, resolved by any spelling a recipe might use.
///
/// Held in memory for the session and handed to [IngredientLineParser], which
/// is why the parser does no I/O and works offline. Twenty-odd units and a
/// hundred-odd names -- one fetch, no round trip per keystroke.
///
/// Pure Dart. Lookups go through [TextNormalizer], so `kašike`, `kasike` and
/// `КАШИКЕ` all resolve, exactly as `normalize_text()` makes them resolve in
/// Postgres.
class UnitCatalog {
  UnitCatalog({
    required List<Unit> units,
    required Map<String, String> aliases,
    Map<String, String> displayNames = const <String, String>{},
  })  : _byCode = <String, Unit>{
          for (final Unit u in units) u.code: u,
        },
        _byAlias = <String, String>{
          for (final MapEntry<String, String> e in aliases.entries)
            TextNormalizer.normalize(e.key): e.value,
        },
        // Copied rather than aliased: the catalog is held for the whole
        // session and must not change under the caller's feet.
        _displayNames = Map<String, String>.unmodifiable(displayNames);

  /// An empty lexicon. A parser given this still parses quantities, names and
  /// notes -- it simply never resolves a unit, which is a supported state
  /// (rule 3), not a failure.
  UnitCatalog.empty()
      : _byCode = const <String, Unit>{},
        _byAlias = const <String, String>{},
        _displayNames = const <String, String>{};

  final Map<String, Unit> _byCode;

  /// Normalized name -> unit code. Built once at construction.
  ///
  /// Deliberately locale-blind. `unit_names` is unique per (name, locale), so
  /// in principle one string could mean different units in two locales; in
  /// practice the seed contains no such pair, and an ingredient line does not
  /// reliably carry a locale to disambiguate with. If one ever appears, the
  /// unit alias contract test fails and this becomes a real decision rather
  /// than a silent last-write-wins.
  final Map<String, String> _byAlias;

  /// `'<code>|<locale>'` -> the spelling to render, from the `unit_names` rows
  /// flagged `is_display_name`.
  ///
  /// Separate from [_byAlias], which goes the other way and is deliberately
  /// locale-blind: recognising `kašike` on input is not the same question as
  /// choosing what to print for `tbsp` in Serbian. A Serbian-first app that
  /// renders a saved line as `2 tbsp brašno` has lost the plot, and the
  /// spelling it should use is already in the table -- only the fetch was
  /// dropping it.
  final Map<String, String> _displayNames;

  Iterable<Unit> get units => _byCode.values;

  /// What to print for [code] in [locale].
  ///
  /// Falls back to the code itself, and deliberately not to the other locale:
  /// printing `tbsp` where Serbian is missing is honest, printing the English
  /// word inside a Serbian line is not. The code is a defensible last resort
  /// anyway -- `g`, `kg`, `ml` and `dl` are spelled the same in both.
  String displayName(String code, {String locale = 'sr'}) =>
      _displayNames['$code|$locale'] ?? code;

  Unit? byCode(String code) => _byCode[code];

  /// Resolves a raw token, e.g. `kašike` or `TBSP`, to a `units.code`.
  ///
  /// Returns null for anything unrecognised, which the parser treats as "this
  /// token is part of the name" rather than as an error.
  ///
  /// This, not [resolve], is what the parser uses: a parsed line carries a
  /// unit *code*, and reading the row behind it -- family, to_base -- is the
  /// shopping list's business in Phase 2. Keeping them separate also means a
  /// lexicon can be built from aliases alone, which is how the parser tests
  /// are driven.
  String? resolveCode(String token) => _byAlias[TextNormalizer.normalize(token)];

  /// The full unit row behind a token, when the caller needs its family or
  /// conversion factor.
  Unit? resolve(String token) {
    final String? code = resolveCode(token);
    return code == null ? null : _byCode[code];
  }

  /// True when [token] names a unit. Cheaper than [resolve] when the caller
  /// only needs to know whether to consume the token.
  bool isUnit(String token) =>
      _byAlias.containsKey(TextNormalizer.normalize(token));
}
