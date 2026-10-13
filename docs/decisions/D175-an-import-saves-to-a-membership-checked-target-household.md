# D175 — An import saves to a membership-checked target household, chosen per import, without switching
**Status:** active
**Touches:** supabase/migrations/20261013180000_save_imported_recipe_target.sql, lib/features/import/data/import_repository.dart, lib/features/import/presentation/import_review_screen.dart, lib/core/household/current_household.dart, lib/core/household/widgets/household_switch_sheet.dart

**Decided.** `phase9-import-save-to`, 2026-10-13. Builds on D168, D171, D152.
1. **Server.** `save_imported_recipe` takes `target_household uuid default
   null`. The job's household stays the default. A named target is accepted
   only if `is_household_member(target_household)`, checked after the
   job's own visibility check and before anything keyed on the target. A
   failure raises `42501`, which maps to `UnauthorizedFailure` like the
   job check. This amends migration 11's "household from the job, never
   from the payload".
2. **Wire.** The client sends `target_household` only when a target was
   picked. An unchanged save is byte-for-byte today's call, so it worked
   against hosted before the migration did.
3. **The target is screen state** in the review (`_targetHouseholdId`),
   per import. Null means the job's household. Picking the job's own
   household again resets it to null. The default is the **job's**
   household, not the current one.
4. **The condition** is `householdNameAmongMany(id)`: 2+ households that
   contain the id, else null (and null on `AppFailure`). With null, the bar
   is today's widget tree (D171's rule).
5. **The sheet** is `showHouseholdSwitchSheet`'s widget, generalized:
   `showSaveToHouseholdSheet` has a "Save to" title, the radio on the
   target and no Manage row, and returns `({id, name})?`.
6. **After saving elsewhere**, the review lands on the *current* household's
   Recipes root, with no switch. Otherwise it lands on the detail. With 2+
   households, both paths show "Saved to X." with no action.

**Why.** A link shared from the browser reaches the review without ever
showing a tab, so the person never sees which household is current. With
two households, that can be the wrong one. D168's reasoning carries over:
the rule "never write into a household you're not in" is upheld by a
membership check, not by refusing to let the client name one. The job's
household is the honest default, because it's where the server would save
today. The current household's detail would offer Plan and edit actions
against the wrong household's data.

**Rejected.**
- Switching to the target on save: the canvas says the pick doesn't switch.
- The current household as the default: it differs from the job's only if
  someone switched between sharing and reviewing, and then it's a guess.
- A `22023` error (slice A's): `42501` matches the job check's arm.
- Always sending `target_household` (null included): PostgREST rejects an
  unknown argument name, so un-migrated hosted would break.
- A Manage row in this sheet: it would leave an unsaved review.
- Keeping the target in `ImportConfirm`'s state: no other part of the
  review needs it.

**Consequences.**
- No Undo on "Saved to X.": the recipe isn't in the current household, so
  there's nothing to undo where the person is.
- Leaving the target household mid-review makes the save fail with the
  unauthorized error. The draft stays.
