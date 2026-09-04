// Dart half of the normalization contract (CLAUDE.md rule 6, D5).
//
// Both this test and supabase/tests/normalization_test.sql are driven off
// test/fixtures/normalization.json. If you change normalize_text() in Postgres
// or TextNormalizer here, change both and run both.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/core/text/text_normalizer.dart';

void main() {
  final File fixtureFile = File('test/fixtures/normalization.json');

  test('fixture file exists and is non-empty', () {
    expect(fixtureFile.existsSync(), isTrue,
        reason: 'test/fixtures/normalization.json is the shared contract');
  });

  final List<dynamic> raw =
      jsonDecode(fixtureFile.readAsStringSync()) as List<dynamic>;

  group('TextNormalizer.normalize', () {
    for (final dynamic entry in raw) {
      final List<dynamic> pair = entry as List<dynamic>;
      final String input = pair[0] as String;
      final String expected = pair[1] as String;

      test('"$input" -> "$expected"', () {
        final String actual = TextNormalizer.normalize(input);
        expect(
          actual,
          expected,
          reason: 'input:    "$input"\n'
              'expected: "$expected"\n'
              'actual:   "$actual"',
        );
      });
    }
  });

  test('is idempotent across every fixture', () {
    for (final dynamic entry in raw) {
      final String input = (entry as List<dynamic>)[0] as String;
      final String once = TextNormalizer.normalize(input);
      expect(TextNormalizer.normalize(once), once,
          reason: 'normalizing "$once" again changed it');
    }
  });
}
