# State — 2026-09-20

**Branch:** `main`
**Last shipped:** Phase 5 part 4 (`0e24704`) — the meal plan's Today and
This week views. `MealPlanScreen` gains a `SegmentedButton` (Today / This
week) under the AppBar, Today being the default. Today pins
`visibleWeekProvider` to the current week and shows one `_DaySection` for
`DateTime.now()`, hiding the week bar's chevrons and the AppBar's
jump-to-today action — neither means anything pinned to one day. This week
is the pre-existing screen, untouched. `isSameDate` in `plan_week.dart` is
now the one definition of same-calendar-day, replacing the inline
comparisons in both `MealPlanWeek.entriesFor` and `_DaySection._isToday`.
No schema change, no migration, no new package. Verified with the full
automated suite (`dart analyze`, `flutter test`, `make lint`,
`test-functions`, `test-sql`) and, unlike Parts 2 and 3, walked end to end
on the physical Galaxy S25 against hosted: Today opening on the real date,
adding a recipe to Today, switching to This week, paging forward and
switching back to Today to confirm the pin invariant (D104) — all
confirmed on-device, not just in widget tests. Also closed both loops
Parts 2 and 3 had left open (see below).
**In flight:** none
**Next:** Phase 5 Part 5 — export the shopping list to the clipboard. See
`docs/ROADMAP.md`.
**Latest decision:** D104

**Parts 2 and 3's device-walk gaps are now closed.** Walked on the same
physical device during Part 4's session: the tag filter (tapping "doručak"
correctly narrowed the recipe list to one match) and the add-to-plan flow
(recipe detail → overflow → "Add to meal plan…" → a day next week → paging
the Plan tab forward confirmed the entry landed). Neither was Part 4's own
code; both simply worked. The lines below recording those gaps as open are
now historical, kept for one cycle in case a future session wants the
detail, and can be dropped next time this file is rewritten.

**Known gap from Part 2, not fixed:** the filter row — Favorites chip
included — only renders once the tag vocabulary is non-empty or a filter is
already selected (the slice's own spec). A household with zero tags
therefore has no way to reach the Favorites filter at all right now. Recorded
in D102's Consequences. A future session should decide whether the Favorites
chip deserves to render on its own regardless of tag vocabulary.

**A slice with a migration needs `make db-push`, not just `make
db-reset`, before testing against hosted.** Phase 5 part 1's own
release-build walk hit it directly: migration 19 was applied locally and
the code shipped querying the new columns, but hosted was still on
migration 18, so the hosted recipe list 400'd with a generic "Nešto je
pošlo naopako." — no Dart stack trace reaches logcat in a release build, so
this took a direct `information_schema.columns` query against hosted to
diagnose. Fixed with `supabase db push`. Any future slice touching a
migration should push it to hosted before a device walk, not just reset
local. (Parts 2, 3 and 4 carried no migration, so this did not recur.)

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
