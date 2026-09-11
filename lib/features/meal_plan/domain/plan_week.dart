/// Week and date arithmetic for the meal plan.
///
/// This is the ONLY file in the feature that does date arithmetic -- every
/// other file receives a [PlanWeek] or a `DateTime` already built here.
/// Two rules, both load-bearing:
///
///  1. Every date is constructed with `DateTime(year, month, day)`, never
///     `DateTime(...).add(Duration(days: n))`. A `Duration` add crosses a DST
///     boundary in local time and can land at 23:00 the previous day, quietly
///     turning a 7-day week into 6 or 8. The `DateTime(y, m, d + n)`
///     constructor normalizes the calendar field instead and cannot do that.
///  2. Nothing here ever calls `.toUtc()`. `week_start` and `entry_date` are
///     Postgres `date` columns -- there is no time of day to convert -- and a
///     UTC conversion done at, say, 00:30 in a +02:00 zone moves the
///     calendar day. Every [DateTime] this file produces is local-midnight
///     and stays that way.
///
/// A plain class, not freezed: this has no wire representation, it is a
/// computed value object over `DateTime`, the same shape as
/// `features/ingredients/domain/quantity.dart` (also plain).
///
/// No `intl` (rule 8 -- a new dependency needs asking first, and this is one
/// `yyyy-MM-dd` format plus a dozen hand-written English abbreviations).
/// Localizing these labels is Phase 3's job, not this one's -- `AppShell`
/// already took that same call for the tab bar.
///
/// Pure Dart (CLAUDE.md rule 7).
library;

const List<String> _dayAbbrev = <String>[
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
];

const List<String> _monthAbbrev = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// `yyyy-MM-dd` over a date's local calendar fields. Never derived from
/// `.toIso8601String()`, which includes a time component this feature has
/// none of.
String isoDateOf(DateTime date) {
  final String y = date.year.toString().padLeft(4, '0');
  final String m = date.month.toString().padLeft(2, '0');
  final String d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// The inverse of [isoDateOf]. `DateTime.parse('2026-09-07')` already yields
/// local midnight with no time component, so this is a thin, explicit wrapper
/// rather than a call site that could grow a stray `.toUtc()` later.
DateTime parseIsoDate(String isoDate) => DateTime.parse(isoDate);

/// A three-letter English day abbreviation for [date]'s weekday.
String dayAbbrevOf(DateTime date) => _dayAbbrev[date.weekday - DateTime.monday];

/// `Mon 14 Sep` -- [dayAbbrevOf] plus day and month.
///
/// `dayAbbrevOf(day) + day.day` (what the Move-to dialog uses) is only
/// unambiguous within a single visible week. Phase 2 part 3's leftover
/// dialog offers 14 consecutive dates from an arbitrary entry, which can
/// cross a month boundary, so that shorthand is not enough there.
String shortDateLabel(DateTime date) =>
    '${dayAbbrevOf(date)} ${date.day} ${_monthAbbrev[date.month - 1]}';

/// A calendar week, Monday through Sunday.
///
/// Two weeks with the same [start] are equal, which is what lets
/// `visibleWeekProvider` be compared and overridden by value in tests.
class PlanWeek {
  const PlanWeek._(this.start);

  /// The Monday of this week, local midnight.
  final DateTime start;

  /// The week containing [date], whichever day of the week [date] is.
  factory PlanWeek.of(DateTime date) {
    final int daysAfterMonday = date.weekday - DateTime.monday;
    return PlanWeek._(
      DateTime(date.year, date.month, date.day - daysAfterMonday),
    );
  }

  factory PlanWeek.fromIsoDate(String isoStart) =>
      PlanWeek._(parseIsoDate(isoStart));

  /// The seven days of this week, Monday first.
  List<DateTime> get days => List<DateTime>.generate(
        7,
        (int i) => DateTime(start.year, start.month, start.day + i),
        growable: false,
      );

  DateTime get end => DateTime(start.year, start.month, start.day + 6);

  PlanWeek get next =>
      PlanWeek._(DateTime(start.year, start.month, start.day + 7));

  PlanWeek get previous =>
      PlanWeek._(DateTime(start.year, start.month, start.day - 7));

  /// Whether [date] falls within this week, inclusive of both ends.
  bool contains(DateTime date) {
    final DateTime day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  /// `yyyy-MM-dd` of [start]. The provider family key (`MealPlanEditor`
  /// watches `visibleWeekProvider` directly rather than being keyed on this,
  /// but the string is what the repository sends to `ensure_meal_plan`).
  String get isoDate => isoDateOf(start);

  /// `8-14 Sep 2026`, or `29 Sep - 5 Oct 2026` across a month boundary, or
  /// `29 Dec 2025 - 4 Jan 2026` across a year boundary.
  String get label {
    final String startDay = start.day.toString();
    final String endDay = end.day.toString();
    final String startMonth = _monthAbbrev[start.month - 1];
    final String endMonth = _monthAbbrev[end.month - 1];

    if (start.year != end.year) {
      return '$startDay $startMonth ${start.year} - '
          '$endDay $endMonth ${end.year}';
    }
    if (start.month != end.month) {
      return '$startDay $startMonth - $endDay $endMonth ${end.year}';
    }
    return '$startDay-$endDay $startMonth ${end.year}';
  }

  @override
  bool operator ==(Object other) => other is PlanWeek && other.start == start;

  @override
  int get hashCode => start.hashCode;

  @override
  String toString() => 'PlanWeek($isoDate)';
}
