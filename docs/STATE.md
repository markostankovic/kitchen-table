# State — 2026-09-19

**Branch:** `main`
**Last shipped:** Phase 5 part 3 (`e3245e0`) — add a recipe to the meal plan
from its own screen. The recipe detail screen's overflow menu gains **Add to
meal plan...**, opening a bottom sheet (four slot chips, the next 14 days)
that writes a `meal_plan_entries` row and confirms with a snackbar. Writes go
through a new keepAlive `MealPlanWriter` in `lib/core/meal_plan/`, not
`MealPlanEditor` — that notifier's write funnel targets the visible week
(wrong here, there is none) and is `autoDispose` (risks a mid-`await`
teardown from a caller that never watches it). The destination week is
derived from the chosen date instead, `PlanWeek.of(entryDate)`, the same rule
`MealPlanEditor.addLeftover` already uses (D56, D103). No schema change, no
migration. Verified with the full automated suite (`dart analyze`,
`check_layers`, `flutter test`, `make test-sql`) and installed as a release
build on the physical Galaxy S25 against hosted, confirmed running. The
on-device walk itself — add a recipe to next week, page the Plan tab forward
to find it, trigger the snack-repeat dialog from this screen — was **not**
confirmed manually in this pass; see below and `docs/journal/phase-5.md`.
**In flight:** none
**Next:** Phase 5 Part 4 — the meal plan's Today and This week views. See
`docs/ROADMAP.md`.
**Latest decision:** D103

**Part 3's device walk stopped short of confirming the add-to-plan
interaction.** The release build installed and launched cleanly on the
physical Galaxy S25 against hosted, but the actual flow — overflow menu →
Add to meal plan... → pick a day in next week and a slot → confirm the entry
appears after paging the Plan tab forward → trigger the snack-repeat dialog
by adding the same recipe to two snack slots — was never walked through by
hand in this session, only proved by the automated widget tests. A future
session should close that loop before trusting the on-device behaviour
beyond what those tests already cover.

**Known gap from Part 2, not fixed:** the filter row — Favorites chip
included — only renders once the tag vocabulary is non-empty or a filter is
already selected (the slice's own spec). A household with zero tags
therefore has no way to reach the Favorites filter at all right now. Recorded
in D102's Consequences. A future session should decide whether the Favorites
chip deserves to render on its own regardless of tag vocabulary.

**Part 2's device walk also stopped short of confirming the filter
interaction**, for the same reason: the test household's recipes carried no
tags, so the filter row stayed hidden and the tap-to-narrow behaviour was
never watched on a real device — only proved by the automated widget tests.
Add a tag to a recipe through the editor's Tags field before trusting the
on-device UI beyond what those tests already cover.

**A slice with a migration needs `make db-push`, not just `make
db-reset`, before testing against hosted.** Phase 5 part 1's own
release-build walk hit it directly: migration 19 was applied locally and
the code shipped querying the new columns, but hosted was still on
migration 18, so the hosted recipe list 400'd with a generic "Nešto je
pošlo naopako." — no Dart stack trace reaches logcat in a release build, so
this took a direct `information_schema.columns` query against hosted to
diagnose. Fixed with `supabase db push`. Any future slice touching a
migration should push it to hosted before a device walk, not just reset
local. (Parts 2 and 3 carried no migration, so this did not recur.)

**Local sign-in requires a device that can hold a Google account**
(Phase 4 part 3's finding). The Android emulator cannot add one at all —
Google's device-integrity gating — so it stays useful for UI work and
useless for exercising sign-in. A physical device's silent credential
restore can sign in with no visible tap at all, which is worth knowing when
a screenshot shows the recipe list with no sign-in step in between.

**Google-only sign-in means no App Store submission** (Phase 4 part 4).
Guideline 4.8 requires an equivalent privacy-preserving login option;
Apple sign-in was dropped from the roadmap outright, not deferred.
Personal signing and TestFlight are unaffected.

**Not yet watched:** a brand-new Google user landing on
`CreateHouseholdRoute` through `on_auth_user_created`, flagged since Phase 4
part 3. The trigger is unchanged and fires on `auth.users` regardless of
provider, but no slice has watched it fire for a Google-created user yet.
`display_name` will be the email local-part when someone checks —
`handle_new_user()` does `split_part(new.email, '@', 1)` and ignores
Google's `full_name`.

**Known issue, not from this slice:** `make check` fails at `seed-check` and
has since `c8be2bc`. That commit edited one *comment* line in
`supabase/seeds/ingredients.csv`, and `catalogFingerprint()` hashes raw bytes,
so the guard fires on a byte-identical catalog (200 ingredients, 618 names).
Everything else in `make check` is green. Deliberately left for its own slice
— the candidate fix is fingerprinting the parsed rows rather than reverting a
correct comment or emitting a catalog migration for a typo.

Update this file as the last step of closing a slice (`/close-slice`), not
mid-task. If it disagrees with `git log`, trust `git log` and fix this file.
