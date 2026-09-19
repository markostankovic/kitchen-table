# State — 2026-09-19

**Branch:** `main`
**Last shipped:** Phase 5 part 1 (`d80bf74`) — favorites and a five-star
rating on recipes, both household facts (`is_favorite`, `rating` on
`recipes`, migration 19 — the repo's first additive `alter table ... add
column`, D100). Narrow writers (`setFavorite`/`setRating`), an AppBar star
and a five-star row with local echo instead of invalidate (D101), a
display-only list tile (filled star + `★ N`). `RecipeDraft`/`RecipeEditor`
deliberately gained neither field — the ROADMAP's original sketch calling
for editor setters was wrong. Verified with `make lint test db-reset
test-sql` locally, then end-to-end on the physical Galaxy S25 against
hosted, after discovering hosted was still on migration 18 (see below).
**In flight:** none
**Next:** Phase 5 Part 2 — filtering the recipe list by tag and by
favorite, built once over both since favorites now exists. See
`docs/ROADMAP.md`.
**Latest decision:** D101

**A slice with a migration needs `make db-push`, not just `make
db-reset`, before testing against hosted.** This slice's own release-build
walk hit it directly: migration 19 was applied locally and the code shipped
querying the new columns, but hosted was still on migration 18, so the
hosted recipe list 400'd with a generic "Nešto je pošlo naopako." — no
Dart stack trace reaches logcat in a release build, so this took a direct
`information_schema.columns` query against hosted to diagnose. Fixed with
`supabase db push`. Any future slice touching a migration should push it to
hosted before a device walk, not just reset local.

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
