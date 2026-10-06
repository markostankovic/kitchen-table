/// Locale-aware date labels for the meal plan and shopping list.
///
/// Both screens used to build these by hand from two English abbreviation
/// lists in `features/meal_plan/domain/plan_week.dart` -- that file's own
/// history explains why. `core/` rather than a feature, because both
/// `meal_plan` and `shopping_list` reach for this, and `core/` may import
/// Flutter and `intl`: `tool/check_layers.dart` derives a layer only from
/// `lib/features/<name>/<layer>/`, which is exactly what
/// `core/error/failure_l10n.dart` already relies on and what
/// `test/tool/check_layers_test.dart` pins deliberately.
///
/// `intl` decides field order and punctuation, not a hand-written format --
/// so an English short date reads `Mon, Sep 14` and a Serbian one reads
/// `pon 14. sep`, in whatever shape each locale's own pattern table gives,
/// not a shape chosen here.
///
/// Depends only on `intl` (CLAUDE.md rule 8 -- already a direct dependency
/// since Phase 3 part 1, added alongside `flutter_localizations`).
library;

import 'package:intl/intl.dart';

/// `AppLocalizations.localeName` is already `Intl.canonicalizedLocale(locale
/// .toString())`, i.e. `'sr_Latn'` or `'en'` -- the exact tag [DateFormat]
/// wants. `ShoppingList.locale` (migration 16) never goes through that and
/// stays the bare DB code, `'sr'` or `'en'` (CLAUDE.md: "Locale codes are
/// `sr` and `en`. Nothing else."). Feeding a bare `'sr'` straight to
/// [DateFormat] selects `intl`'s *Cyrillic* `sr` symbol table -- the D91 bug
/// one layer over -- so every call in this file goes through this mapping
/// first, whichever shape its caller happens to hold. This is the
/// load-bearing line in the file.
String _tag(String locale) => locale == 'sr' ? 'sr_Latn' : locale;

/// The compact form -- weekday abbreviation and day of month (`Mon 1`,
/// `pon 1`). No longer a day header (that is [weekdayNameAndDay]); it stays
/// for the leftover meta, where a full Serbian weekday after `od` would have
/// to be declined (`od ponedeljka`) and a generated string can't be, so it
/// reads `od pon 14` -- and for the move dialog's day dropdown. Unambiguous
/// only within a single visible week; a range that can cross a month wants
/// [shortDateLabel] instead.
String weekdayAndDay(DateTime date, String locale) =>
    DateFormat('E d', _tag(locale)).format(date);

/// The week view's day header -- full weekday name and day of month
/// (`Monday 1`, `Ponedeljak 1`). Unambiguous only within one visible week,
/// where the week bar already names the month. `intl` gives Serbian weekdays
/// in lower case, and a header starts a line, so it is sentence-cased.
String weekdayNameAndDay(DateTime date, String locale) =>
    toBeginningOfSentenceCase(
      DateFormat('EEEE d', _tag(locale)).format(date),
      _tag(locale),
    );

/// The Today view's day header -- full weekday, day and month (`Monday,
/// June 1`, `Ponedeljak, 1. jun`). A lone day card has no week bar above it
/// to name the month, so this one does. Sentence-cased, as
/// [weekdayNameAndDay] is.
String fullDateLabel(DateTime date, String locale) =>
    toBeginningOfSentenceCase(
      DateFormat.MMMMEEEEd(_tag(locale)).format(date),
      _tag(locale),
    );

/// Weekday, day and month -- unambiguous across a month boundary, unlike
/// [weekdayAndDay]. The leftover dialog needs exactly this: D56's 14-day
/// window from an arbitrary entry date can cross one.
String shortDateLabel(DateTime date, String locale) =>
    DateFormat.MMMEd(_tag(locale)).format(date);

/// A week's range, both endpoints formatted and joined with an en-dash. The
/// year is carried on the end date always, and on the start date only when
/// it differs from the end date's -- so a week within one year carries the
/// year once, and a week crossing a year boundary carries it on both ends.
///
/// Replaces `PlanWeek.label`'s old three-way `year`/`month` branching, which
/// was an assumption about how a range reads that happened to hold for
/// English and stopped holding the moment a second language showed up --
/// there is no single `DateFormat` skeleton for "two dates, one range", so
/// this composes two.
String weekRangeLabel(DateTime start, DateTime end, String locale) {
  final String tag = _tag(locale);
  final DateFormat withYear = DateFormat.yMMMd(tag);
  final DateFormat noYear = DateFormat.MMMd(tag);
  final String startText =
      start.year == end.year ? noYear.format(start) : withYear.format(start);
  return '$startText – ${withYear.format(end)}';
}
