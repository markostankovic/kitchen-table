# State — 2026-09-21

**Branch:** `main`
**Last shipped:** Phase 6 part 3b (`1fcf196`) — members and invites. An
owner can now remove any other member; any member can leave a household
they do not own; any member can revoke a live invite code. All three go
through new `SECURITY DEFINER` RPCs (`remove_household_member`,
`leave_household`, `revoke_invite`) mirroring `create_household()` — neither
`household_members` nor `household_invites` gained a write policy.
`household_invites` gained `revoked_at`/`revoked_by` with the partial
unique index rebuilt around them, releasing a revoked code for reuse the
same way a used one already was; `redeem-invite`'s peek and claim both
gained a `revoked_at` guard, and the genuinely reachable `invite_revoked`
slug got the full `FailureCode`/ARB treatment while every other RPC
refusal stays unlocalized on purpose, gated out of reach by the UI (D115).
The household screen's member and invite rows gained role-gated trailing
affordances with confirm dialogs for Remove/Leave and none for Revoke.
Verified with `dart analyze` (clean), `flutter test` (all suites green,
including new repository and widget-test coverage), `make gen`, and
`make test-sql` (green against a fresh `supabase db reset`, including new
assertions for every authorization edge in both `rls_household_test.sql`
and `rls_invites_test.sql`, and the D25 re-mint-after-revoke trap asserted
directly). `make check` ran lint, lint-functions, test and test-functions
clean before stopping at the same pre-existing `seed-check` failure noted
below. Migration 22 was pushed to hosted and `redeem-invite` redeployed in
this same slice. A release build against hosted was installed and launched
on the physical Galaxy device and Revoke was confirmed live — the code
vanished from the list immediately with no confirm dialog, and the "Code
revoked." SnackBar appeared, round-tripping through the real RPC and
rebuilt index on hosted Postgres. Remove and Leave were **not** exercised
live: the household under test had only one member (the owner), so neither
affordance had a second row to act on. This device-walk loop is only
partially closed — it joins the others below rather than staying fully
open, since Revoke is confirmed but Remove/Leave need a second account
joined through an invite code first.
**In flight:** none
**Next:** `/plan-slice phase6-part3c` (delete, and what a deleted household
means — the last ordered sub-part of Phase 6 part 3; already knows to
inherit 3b's confirm-dialog and gate-the-affordance patterns, D115), or
close one of the device-walk loops still open below.
**Latest decision:** D115

**Phase 6 part 3b's own Remove/Leave paths are unconfirmed on a real
device.** Revoke was confirmed live (above), but Remove and Leave need a
second account in the same household to have a row to act on — join a
second Google account through a minted invite code first, then confirm:
the owner sees Remove on the other member's row and no Leave on their own;
the adult sees Leave on their own row and no Remove on the owner's;
confirming Remove/Leave actually writes through and the row disappears;
confirming Leave lands the now-memberless account on
`CreateHouseholdRoute` with no restart.

**Phase 6 part 2's own device-walk loop is open.** The release build
installed and launched cleanly on the Galaxy device, but nobody has
confirmed against a real device that typing a tag's spelling — in either
app language — actually narrows the list, that a title match and a tag
match appear together for the same query, that a chip tap still narrows by
whole token only, and that a household with recipes but no tags shows the
Favorites chip.

**Phase 6 part 1b's own device-walk loop is open.** The Edge Function
deployed cleanly and the release build installed on the Galaxy device, but
nobody has confirmed against the real device that saving a recipe with a
brand-new Serbian tag actually mints its English pair, that the chip
relabels when the app's language is switched, and that saving again makes
no second model call (checkable via `ai_usage` rows or the function's log).

**Phase 6 part 1a's own device-walk loop is also still open.** Migration 21
is on hosted (pushed as part of 1b's own device walk), so that blocker is
cleared, but nobody has yet confirmed against a real device that
hand-inserting a `Posno`/`Lenten` pair and switching the app's language
actually shows the translated chip on both the list and detail screens,
that a second untranslated tag still reads as typed, and that tapping the
translated chip still narrows the list. Part 1b's own model-minted pairs
should serve this just as well as a hand-inserted one, once its own loop
above is closed.

**Phase 5 part 6's device-walk loop is also still open** (translating from
the editor, `d7dcb81`) — not to be confused with the three Phase 6 loops
above. The release build installed and launched cleanly on the physical
Galaxy device against hosted, but nobody has confirmed back that tapping
Translate from the editor actually saves, calls the Edge Function, and
shows Review instead of Translate afterward on a real device.

**Phase 5 part 5's device-walk loop is also still open.** The shopping
list's clipboard-copy action installed cleanly on the same device, but
copying an actual generated list, seeing the SnackBar, and pasting the
text elsewhere have not been confirmed back either. Six device-walk
loops (counting 3b's partial one above) are now open at once — a future
session should close all of them, not just the newest one.

**This Flutter SDK's `flutter_test` does not stub the clipboard channel.**
Discovered in Phase 5 part 5: an unmocked call to `Clipboard.setData` (or
`Clipboard.getData`) inside a widget test hangs indefinitely instead of
throwing or returning null — confirmed with several minimal reproductions
before touching the real test. Reading `Clipboard.getData` back from the
test body (as opposed to from inside a widget's own callback) hangs the
same way. Any future test touching the clipboard needs a mock
`SystemChannels.platform` handler registered in `setUp`/`tearDown` (see
`shopping_list_screen_test.dart`) — verify the clipboard's actual contents
by testing the pure-Dart formatter directly instead of round-tripping
through `Clipboard.getData`.

**A dialog-local `TextEditingController` should never be manually
disposed.** Confirmed again in Phase 6 part 3a: calling `controller.dispose()`
right after `Navigator.pop()` closes a `showDialog` races the dialog's exit
animation and throws "Tried to build dirty widget in the wrong build scope"
under `pumpAndSettle` in widget tests. `recipe_picker_sheet.dart`'s own
`_promptForNote` dialog already left its local controller undisposed for
this reason; `household_screen.dart`'s rename dialog now follows the same
precedent rather than disposing. Phase 6 part 3b's Remove/Leave confirm
dialogs carry no controller at all, so the question never came up again.

**A debug-signed and a release-signed APK can never overwrite each other
in place.** Confirmed again in Phase 5 part 6: switching from `make
run-hosted` (debug) to a release install, or back, always needs the other
variant uninstalled first — `adb install -r` alone fails with
`INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Uninstalling clears app data, so
Google sign-in has to happen again afterward. `adb install` is also
ambiguous whenever the Android emulator is attached alongside the physical
device (Phase 5 part 5's finding) — install by serial, `adb -s <serial>
install`.

**A slice with a migration needs `make db-push`, not just `make
db-reset`, before testing against hosted.** Phase 5 part 1's own
release-build walk hit it directly: migration 19 was applied locally and
the code shipped querying the new columns, but hosted was still on an
older migration, so the hosted recipe list 400'd with a generic "Nešto je
pošlo naopako." — no Dart stack trace reaches logcat in a release build, so
this took a direct `information_schema.columns` query against hosted to
diagnose. Fixed with `supabase db push`. Phase 6 part 1a's own migration
(21) sat unpushed for a full slice before part 1b's device walk finally
pushed it. Phase 6 part 3b's migration (22) was pushed in the same slice
that wrote it, closing the loop that note asked for.

**Driving a real device blind by pixel coordinates is unreliable —
`uiautomator dump` gives exact bounds instead.** Found in Phase 6 part 3b's
own device walk: a screenshot tool's displayed-vs-actual resolution scaling
note, applied by hand across two separate `adb shell input tap` calls, put
one tap on the wrong element (opened a "+" FAB menu instead of a bottom-nav
tab) and a second on a menu item left open underneath a mis-tap, which
launched the phone's native Camera app. `adb shell uiautomator dump
/sdcard/ui.xml` followed by `adb pull` and grepping `bounds="..."` off
`content-desc` attributes gives exact tap targets for any adb-driven
verification going forward — Flutter's semantics tree exposes labeled,
bounded elements this way even though there's no native View hierarchy.

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
