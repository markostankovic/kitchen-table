# D93 — The date-label layer lives in `core/l10n/`, backed by `intl`, not hand-written formatting
**Status:** active
**Touches:** lib/core/l10n/date_labels.dart, lib/features/meal_plan/domain/plan_week.dart, lib/features/meal_plan/presentation/meal_plan_screen.dart, lib/features/shopping_list/presentation/shopping_list_screen.dart

**Decided.** `weekdayAndDay`, `shortDateLabel` and `weekRangeLabel` (formerly
`dayAbbrevOf`, `shortDateLabel` and `PlanWeek.label`) move from
`plan_week.dart` to `core/l10n/date_labels.dart`, each a plain function
taking `(DateTime, ..., String locale)`. `intl`'s `DateFormat` decides field
order and punctuation, not a hand-written format -- English's short date
changes shape (`Mon 14 Sep` → `Mon, Sep 14`) as a direct consequence, and
existing test assertions were updated rather than preserved. A single
private `_tag()` maps `'sr'` → `'sr_Latn'` and passes anything else through,
so both a DB locale code and an `AppLocalizations.localeName` can be handed
in directly -- D91 applied to `DateFormat`, since a bare `'sr'` selects
`intl`'s Cyrillic symbol table the same way a bare `Locale('sr')` did.
`weekRangeLabel` drops the old three-way `year`/`month` string-branching:
both endpoints are formatted and joined with an en-dash, the year carried on
the end date always and on the start date only when it differs.

**Why.** `plan_week.dart` is pure Dart (rule 7) and cannot reach a locale;
rendering a date needs one. `core/` rather than the feature, because both
`meal_plan` and `shopping_list` need it, and `core/error/failure_l10n.dart`
already established that `lib/core/` may import Flutter and `intl` despite
rule 7 -- `tool/check_layers.dart` derives a layer only from
`lib/features/<name>/<layer>/`.

**Rejected.** Keeping the old hand-written English abbreviation lists and
adding a Serbian pair beside them -- rule 6's "one definition per side, a
shared fixture" is for a rule ported across the Dart/TypeScript boundary,
not an excuse to hand-roll what `intl` already knows for every locale it
ships symbols for.

**Consequences.** `DateFormat.MMMEd('sr_Latn')` does not put a comma where
`DateFormat.MMMEd('en')` does (`pon 14. sep`, not `pon, 14. sep`) -- verified
directly against the pinned `intl` version, not assumed. A future locale's
own date shape is `intl`'s problem, not this file's.
