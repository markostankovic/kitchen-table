import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kitchen_table/core/l10n/date_labels.dart';

/// Pure Dart, no `MaterialApp` -- so unlike a widget test, `DateFormat`'s
/// locale symbols are not loaded by `GlobalMaterialLocalizations` and must be
/// loaded explicitly here, once, before any test runs.
void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('weekdayAndDay', () {
    test('all seven weekdays, English', () {
      final DateTime monday = DateTime(2026, 6, 1);
      final List<String> labels = List<String>.generate(
        7,
        (int i) => weekdayAndDay(
            DateTime(monday.year, monday.month, monday.day + i), 'en'),
      );
      expect(labels, <String>[
        'Mon 1', 'Tue 2', 'Wed 3', 'Thu 4', 'Fri 5', 'Sat 6', 'Sun 7',
      ]);
    });

    test('all seven weekdays, Serbian -- Latin script only (D91, D4)', () {
      final DateTime monday = DateTime(2026, 6, 1);
      final List<String> labels = List<String>.generate(
        7,
        (int i) => weekdayAndDay(
            DateTime(monday.year, monday.month, monday.day + i), 'sr'),
      );
      expect(labels, <String>[
        'pon 1', 'uto 2', 'sre 3', 'čet 4', 'pet 5', 'sub 6', 'ned 7',
      ]);
      for (final String label in labels) {
        expect(RegExp(r'^[\x00-\x7Fčćžšđ ]+$', caseSensitive: false)
            .hasMatch(label), isTrue, reason: '$label is not Latin script');
      }
    });
  });

  group('shortDateLabel', () {
    test('English', () {
      expect(shortDateLabel(DateTime(2026, 9, 14), 'en'), 'Mon, Sep 14');
    });

    test('Serbian, Latin script', () {
      expect(shortDateLabel(DateTime(2026, 9, 14), 'sr'), 'pon 14. sep');
    });

    test('disambiguates dates a bare weekday-and-day cannot -- a leftover '
        'window crossing a month boundary', () {
      expect(shortDateLabel(DateTime(2026, 6, 29), 'en'), 'Mon, Jun 29');
      expect(shortDateLabel(DateTime(2026, 7, 29), 'en'), 'Wed, Jul 29');
    });

    test('a bare "sr" locale never renders the Cyrillic symbol table (D91)',
        () {
      expect(shortDateLabel(DateTime(2026, 9, 14), 'sr'), isNot(contains('пон')));
    });
  });

  group('weekRangeLabel', () {
    test('within one month, English -- year carried once', () {
      expect(
        weekRangeLabel(DateTime(2026, 6, 1), DateTime(2026, 6, 7), 'en'),
        'Jun 1 – Jun 7, 2026',
      );
    });

    test('within one month, Serbian -- year carried once', () {
      expect(
        weekRangeLabel(DateTime(2026, 6, 1), DateTime(2026, 6, 7), 'sr'),
        '1. jun – 7. jun 2026.',
      );
    });

    test('across a month boundary, English', () {
      expect(
        weekRangeLabel(DateTime(2026, 6, 29), DateTime(2026, 7, 5), 'en'),
        'Jun 29 – Jul 5, 2026',
      );
    });

    test('across a month boundary, Serbian', () {
      expect(
        weekRangeLabel(DateTime(2026, 6, 29), DateTime(2026, 7, 5), 'sr'),
        '29. jun – 5. jul 2026.',
      );
    });

    test('across a year boundary, English -- year carried on both ends', () {
      expect(
        weekRangeLabel(DateTime(2025, 12, 29), DateTime(2026, 1, 4), 'en'),
        'Dec 29, 2025 – Jan 4, 2026',
      );
    });

    test('across a year boundary, Serbian -- year carried on both ends', () {
      expect(
        weekRangeLabel(DateTime(2025, 12, 29), DateTime(2026, 1, 4), 'sr'),
        '29. dec 2025. – 4. jan 2026.',
      );
    });
  });
}
