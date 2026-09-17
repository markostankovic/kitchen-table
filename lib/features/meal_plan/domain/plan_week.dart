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
/// No `intl` here, still -- rule 7 is the reason, not rule 8: this file does
/// arithmetic, and arithmetic is pure Dart. The display labels that used to
/// live here (`dayAbbrevOf`, `shortDateLabel`, `PlanWeek.label`) moved to
/// `core/l10n/date_labels.dart` in Phase 3 part 6, because rendering a date
/// needs a locale and a domain model may never take one -- the same argument
/// `core/error/failure_l10n.dart` already made for `AppFailure`. `isoDateOf`
/// and `parseIsoDate` stayed: `data/` depends on them heavily
/// (`remote_meal_plan_datasource.dart`, `remote_shopping_list_datasource.dart`,
/// `shopping_list_dto.dart`) and neither is display.
///
/// Pure Dart (CLAUDE.md rule 7).
library;

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

  @override
  bool operator ==(Object other) => other is PlanWeek && other.start == start;

  @override
  int get hashCode => start.hashCode;

  @override
  String toString() => 'PlanWeek($isoDate)';
}
