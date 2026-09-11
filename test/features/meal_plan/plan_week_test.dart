import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_table/features/meal_plan/domain/plan_week.dart';

/// `plan_week.dart` is the one file in the feature that does date arithmetic,
/// specifically so its correctness can be pinned down here with no Supabase
/// client and no widget tree -- the same reason `recipe_draft_test.dart`
/// exists for the editor.

void main() {
  group('PlanWeek.of', () {
    test('every day of a week resolves to the same Monday', () {
      // Monday 2026-06-01 through Sunday 2026-06-07.
      final DateTime monday = DateTime(2026, 6, 1);
      for (int i = 0; i < 7; i++) {
        final DateTime day = DateTime(2026, 6, 1 + i);
        expect(PlanWeek.of(day).start, monday,
            reason: '$day should resolve to Monday $monday');
      }
    });

    test('a Sunday resolves backward, not forward', () {
      // The classic off-by-one: DateTime.sunday is weekday 7, the LAST day
      // of its own week, not the first day of the next one.
      final DateTime sunday = DateTime(2026, 6, 7);
      expect(PlanWeek.of(sunday).start, DateTime(2026, 6, 1));
    });
  });

  group('days', () {
    test('has 7 entries, Monday first, Sunday last, each one day apart', () {
      final List<DateTime> days = PlanWeek.of(DateTime(2026, 6, 3)).days;

      expect(days, hasLength(7));
      expect(days.first.weekday, DateTime.monday);
      expect(days.last.weekday, DateTime.sunday);
      for (int i = 1; i < days.length; i++) {
        expect(days[i].difference(days[i - 1]).inDays, 1);
      }
    });

    test('spans a month boundary correctly', () {
      // Monday 2026-06-29 .. Sunday 2026-07-05.
      final List<DateTime> days = PlanWeek.of(DateTime(2026, 6, 30)).days;
      expect(days.first, DateTime(2026, 6, 29));
      expect(days.last, DateTime(2026, 7, 5));
    });

    test('spans a year boundary correctly', () {
      // Monday 2025-12-29 .. Sunday 2026-01-04.
      final List<DateTime> days = PlanWeek.of(DateTime(2025, 12, 31)).days;
      expect(days.first, DateTime(2025, 12, 29));
      expect(days.last, DateTime(2026, 1, 4));
    });

    test('the week crossing a spring-forward DST boundary is still 7 '
        'consecutive calendar days', () {
      // Europe/Belgrade moves its clocks forward on the last Sunday of
      // March. `Duration(days: 1)` added in local time would land at 23:00
      // the previous day on that one hop; DateTime(y, m, d + n) must not.
      final List<DateTime> days = PlanWeek.of(DateTime(2026, 3, 25)).days;
      expect(days, hasLength(7));
      expect(days.first, DateTime(2026, 3, 23));
      expect(days.last, DateTime(2026, 3, 29));
      for (int i = 1; i < days.length; i++) {
        expect(days[i].difference(days[i - 1]).inDays, 1);
      }
    });

    test('the week crossing a fall-back DST boundary is still 7 consecutive '
        'calendar days', () {
      // Europe/Belgrade moves its clocks back on the last Sunday of October.
      final List<DateTime> days = PlanWeek.of(DateTime(2026, 10, 21)).days;
      expect(days, hasLength(7));
      expect(days.first, DateTime(2026, 10, 19));
      expect(days.last, DateTime(2026, 10, 25));
    });
  });

  group('next / previous', () {
    test('next is exactly 7 calendar days on', () {
      final PlanWeek week = PlanWeek.of(DateTime(2026, 6, 1));
      expect(week.next.start, DateTime(2026, 6, 8));
    });

    test('next.previous is value-equal to the original week', () {
      final PlanWeek week = PlanWeek.of(DateTime(2026, 6, 1));
      expect(week.next.previous, week);
    });

    test('previous crosses a year boundary correctly', () {
      final PlanWeek week = PlanWeek.of(DateTime(2026, 1, 1));
      expect(week.previous.start, DateTime(2025, 12, 22));
    });
  });

  group('contains', () {
    final PlanWeek week = PlanWeek.of(DateTime(2026, 6, 3));

    test('true for all seven days', () {
      for (final DateTime day in week.days) {
        expect(week.contains(day), isTrue, reason: '$day should be inside');
      }
    });

    test('false for the day before the start', () {
      expect(week.contains(DateTime(2026, 5, 31)), isFalse);
    });

    test('false for the day after the end', () {
      expect(week.contains(DateTime(2026, 6, 8)), isFalse);
    });
  });

  group('isoDate / parseIsoDate', () {
    test('zero-pads month and day', () {
      expect(isoDateOf(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('does not shift the day for a DateTime built at end-of-day', () {
      expect(isoDateOf(DateTime(2026, 1, 5, 23, 30)), '2026-01-05');
    });

    test('round-trips through PlanWeek.fromIsoDate', () {
      final PlanWeek week = PlanWeek.fromIsoDate('2026-06-01');
      expect(week.start, DateTime(2026, 6, 1));
      expect(week.isoDate, '2026-06-01');
    });

    test('parseIsoDate is the inverse of isoDateOf', () {
      final DateTime date = DateTime(2026, 3, 9);
      expect(parseIsoDate(isoDateOf(date)), date);
    });
  });

  group('label', () {
    test('within one month', () {
      expect(PlanWeek.of(DateTime(2026, 6, 3)).label, '1-7 Jun 2026');
    });

    test('across a month boundary', () {
      expect(PlanWeek.of(DateTime(2026, 6, 30)).label, '29 Jun - 5 Jul 2026');
    });

    test('across a year boundary', () {
      expect(
          PlanWeek.of(DateTime(2025, 12, 31)).label, '29 Dec 2025 - 4 Jan 2026');
    });
  });

  group('dayAbbrevOf', () {
    test('all seven weekdays', () {
      final PlanWeek week = PlanWeek.of(DateTime(2026, 6, 3));
      expect(week.days.map(dayAbbrevOf), <String>[
        'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
      ]);
    });
  });

  group('shortDateLabel', () {
    test('day, date and month, unambiguous on its own', () {
      expect(shortDateLabel(DateTime(2026, 9, 14)), 'Mon 14 Sep');
    });

    test('disambiguates dates that dayAbbrevOf + day cannot -- a leftover '
        'window crossing a month boundary', () {
      // The 14-day leftover window can straddle a month, where two
      // different days share the same day-of-month.
      expect(shortDateLabel(DateTime(2026, 6, 29)), 'Mon 29 Jun');
      expect(shortDateLabel(DateTime(2026, 7, 29)), 'Wed 29 Jul');
    });
  });
}
