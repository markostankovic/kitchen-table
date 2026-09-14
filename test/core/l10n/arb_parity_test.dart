// Guards the two ARB files against drifting apart -- the gap
// `l10n-check` (Makefile) does NOT catch.
//
// `l10n-check` regenerates `lib/core/l10n/generated/` and diffs it against
// what is committed, so it fails if an ARB edit was made without `make gen`.
// It says nothing about the ARB files agreeing with EACH OTHER: a key added
// to `app_sr.arb` (the template, D77) and forgotten in `app_en.arb` still
// regenerates cleanly -- `flutter gen-l10n` just emits a getter with no
// English translation, `dart analyze` stays clean, and the gap is only
// caught by eye. Phase 3 part 5 roughly doubled the key count, which is
// exactly when a byte-for-byte template/translation pair stops being
// something a person can eyeball reliably.
//
// Same shape of guarantee as rule 6's cross-language fixtures and
// `supabase_failure_test.dart`'s slug sweep: parse both sources of truth and
// assert they agree, rather than trusting them to stay in sync by
// inspection.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A placeholder name inside an ICU-ish ARB value: `{` + an identifier +
/// either `}` (a plain placeholder, or a reference inside a plural arm --
/// `one{{count} sat}`) or `,` (the count/choice variable that opens a
/// `{count, plural, ...}` construct). Requiring one of those two follow-up
/// characters is what keeps an arm's own literal text from matching --
/// `one{Expires in {count} hour}` must yield only `count`, not `Expires`,
/// even though `{Expires` is itself a `{` followed by an identifier.
final RegExp _placeholder = RegExp(r'\{(\w+)[,}]');

Set<String> _placeholdersIn(String value) =>
    _placeholder.allMatches(value).map((Match m) => m.group(1)!).toSet();

Map<String, dynamic> _loadArb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// The real, translatable keys -- everything except `@@locale` and the
/// `@key` metadata entries the template file carries alongside each one.
Set<String> _translatableKeys(Map<String, dynamic> arb) => arb.keys
    .where((String k) => !k.startsWith('@'))
    .toSet();

void main() {
  final Map<String, dynamic> sr =
      _loadArb('lib/core/l10n/arb/app_sr.arb');
  final Map<String, dynamic> en =
      _loadArb('lib/core/l10n/arb/app_en.arb');

  test('every template key has an English translation, and vice versa', () {
    final Set<String> srKeys = _translatableKeys(sr);
    final Set<String> enKeys = _translatableKeys(en);

    final Set<String> missingFromEn = srKeys.difference(enKeys);
    final Set<String> missingFromSr = enKeys.difference(srKeys);

    expect(
      missingFromEn,
      isEmpty,
      reason: 'app_sr.arb is the template (D77) -- these keys need an '
          'English value in app_en.arb: $missingFromEn',
    );
    expect(
      missingFromSr,
      isEmpty,
      reason: 'these keys exist only in app_en.arb, with nothing in the '
          'template: $missingFromSr',
    );
  });

  test('every key uses the same placeholder names in both languages', () {
    final Set<String> sharedKeys =
        _translatableKeys(sr).intersection(_translatableKeys(en));

    final Map<String, ({Set<String> sr, Set<String> en})> mismatched =
        <String, ({Set<String> sr, Set<String> en})>{};
    for (final String key in sharedKeys) {
      final Set<String> srPlaceholders =
          _placeholdersIn(sr[key] as String);
      final Set<String> enPlaceholders =
          _placeholdersIn(en[key] as String);
      // Set's own `==` is identity-based, not structural -- compare via
      // `difference` in both directions instead of `!=`.
      if (srPlaceholders.difference(enPlaceholders).isNotEmpty ||
          enPlaceholders.difference(srPlaceholders).isNotEmpty) {
        mismatched[key] = (sr: srPlaceholders, en: enPlaceholders);
      }
    }

    expect(
      mismatched,
      isEmpty,
      reason: 'these keys reference different placeholders per language, '
          'which flutter gen-l10n would only catch by refusing to build: '
          '$mismatched',
    );
  });
}
