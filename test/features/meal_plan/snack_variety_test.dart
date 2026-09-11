import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/meal_plan/domain/snack_variety.dart';

/// `snack_variety.dart` is pure Dart with no database, exactly like
/// `plan_week_test.dart` covers `plan_week.dart` -- and it inherits the same
/// date-arithmetic hazards, since its window is built with `DateTime(y, m, d
/// +/- n)`, not `Duration` addition.

void main() {
  group('varietyWindowAround', () {
    test('is centred: kVarietyWindowDays either side of the candidate date',
        () {
      final ({DateTime from, DateTime to}) window =
          varietyWindowAround(DateTime(2026, 6, 15));
      expect(window.from, DateTime(2026, 6, 15 - kVarietyWindowDays));
      expect(window.to, DateTime(2026, 6, 15 + kVarietyWindowDays));
    });

    test('spans a month boundary correctly', () {
      final ({DateTime from, DateTime to}) window =
          varietyWindowAround(DateTime(2026, 6, 3));
      expect(window.from, DateTime(2026, 5, 27));
      expect(window.to, DateTime(2026, 6, 10));
    });

    test('spans a year boundary correctly', () {
      final ({DateTime from, DateTime to}) window =
          varietyWindowAround(DateTime(2026, 1, 2));
      expect(window.from, DateTime(2025, 12, 26));
      expect(window.to, DateTime(2026, 1, 9));
    });

    test('the window crossing a spring-forward DST boundary still lands on '
        'the right calendar dates', () {
      // Europe/Belgrade moves its clocks forward on the last Sunday of
      // March. This is exactly why the assertion is on calendar fields, not
      // on `.difference().inDays`: that duration-based accessor loses the
      // skipped hour across the transition and reports 13, not 14, which
      // would be the wrong thing to assert even though the dates below are
      // both correct -- the same trap plan_week.dart's rule 1 warns about.
      final ({DateTime from, DateTime to}) window =
          varietyWindowAround(DateTime(2026, 3, 29));
      expect(window.from, DateTime(2026, 3, 22));
      expect(window.to, DateTime(2026, 4, 5));
    });
  });

  group('shouldWarnOnRepeat', () {
    test('does not warn below the threshold', () {
      expect(shouldWarnOnRepeat(kVarietyWarnAtOrAbove - 1), isFalse);
    });

    test('warns at the threshold', () {
      expect(shouldWarnOnRepeat(kVarietyWarnAtOrAbove), isTrue);
    });

    test('warns above the threshold', () {
      expect(shouldWarnOnRepeat(kVarietyWarnAtOrAbove + 5), isTrue);
    });

    test('does not warn at zero', () {
      expect(shouldWarnOnRepeat(0), isFalse);
    });
  });
}
