/// The snack variety check: docs/DATA_MODEL.md's "not yet built" client-side
/// query, now built (Phase 2, part 3).
///
/// Defined once, here, so `MealPlanEditor.snackRepeatCount` and the screen's
/// warning dialog cannot each answer "how many is too many" or "over what
/// window" differently -- the same reason `RecipeIngredient.resolvedName` and
/// `MealPlanEntry.label` are single-definition getters rather than duplicated
/// in a widget.
///
/// The window is CENTRED on the candidate date, +/- [kVarietyWindowDays], not
/// trailing as `docs/DATA_MODEL.md`'s original sketch worded it ("the last N
/// days"). A meal plan is a forward-looking document: most of what a
/// candidate snack should be compared against has not been cooked yet, only
/// planned, and a trailing window only warns when slots happen to be filled
/// in calendar order. A cook who plans Saturday's snack before Wednesday's
/// gets no warning from a trailing window even though the two sit five days
/// apart; a centred one catches it regardless of fill order. Recorded as D58.
///
/// This check is advisory. [shouldWarnOnRepeat] never blocks a write -- it
/// only tells the screen whether to ask before writing it, the same "loud,
/// not blocking" instinct D54 already gives every meal-plan failure.
///
/// Pure Dart (CLAUDE.md rule 7).
library;

/// Days either side of a candidate date that count toward its repeat total.
/// 7 either side is 15 calendar days inclusive -- close to
/// `docs/DATA_MODEL.md`'s original 14-day figure, kept centred rather than
/// trailing (see the file doc above).
const int kVarietyWindowDays = 7;

/// A recipe already occupying this many (or more) snack slots in the window
/// is worth a warning before adding one more.
const int kVarietyWarnAtOrAbove = 2;

/// The inclusive `[from, to]` window around [date] that a repeat count should
/// be taken over. Built with `DateTime(y, m, d +/- n)`, never a `Duration`
/// add -- `plan_week.dart`'s rule 1 applies here too: a `Duration` add crosses
/// a DST boundary in local time and can land on the wrong calendar day.
({DateTime from, DateTime to}) varietyWindowAround(DateTime date) => (
      from: DateTime(date.year, date.month, date.day - kVarietyWindowDays),
      to: DateTime(date.year, date.month, date.day + kVarietyWindowDays),
    );

/// Whether a recipe already appearing [existingCount] times in the window
/// (not counting the slot about to be filled) is worth warning about.
bool shouldWarnOnRepeat(int existingCount) =>
    existingCount >= kVarietyWarnAtOrAbove;
