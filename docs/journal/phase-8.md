# Journal — Phase 8

Verbatim build history for Phase 8 — Freshness and images — kept out of `docs/ROADMAP.md` so the roadmap stays a forward-looking index. Nothing here is authoritative going forward -- see `docs/decisions/` for standing rules, `docs/STATE.md` for current status.

---

## Phase 8 — Freshness and images

### Part 1 — Shopping list: pull and long-press regenerate

**Status: complete** (`28514bb`). Decisions taken during it: D147.

Planned with `/plan-slice` on 2026-10-05 from two of the four user requests
behind Phase 8, and built in a fresh session. No migration, no new package,
no new ARB key. The user made both calls during planning: reorder the list
on screen after a long-press, and regenerate *the same* list (its own dates
and language). Pull on the empty state generates.

- **Provider** (`shopping_list_providers.dart`). `generate()`'s body moved
  into a private `_generateFor({householdId, range, locale})`, which keeps
  the "aggregate, save, retire previous, bump" order and its comment.
  `generate()` still takes the range bar's dates and the reader's locale
  (D81). The new `regenerateCurrent()` reads `state.value`, returns if
  there is none, and otherwise regenerates with the list's own
  `dateFrom`/`dateTo` and `locale` (D147 #2, D94). A small
  `_requireHouseholdId()` replaced three copies of the no-household throw;
  the plan did not ask for it. `setPantryPref`'s doc comment now says it
  records the preference only and the screen regenerates afterwards.
- **Screen** (`shopping_list_screen.dart`). `RefreshIndicator.onRefresh`
  is `() => _generate(context, ref)` for both the empty state and the list
  (D147 #1). `AppEmptyState(card: true)` is already a `ListView`, so the
  empty state pulled with no wrapping. `_togglePantry` awaits
  `setPantryPref` and then `regenerateCurrent()` inside one
  `try`/`on AppFailure`; the success snackbar shows only if both succeed.
  Its doc comment cites D147 and keeps D13.
- **Strings.** `markedAsStapleSnackbar` is `{name} moved to Probably
  have.` / `{name} premešteno u Verovatno imate.`, and
  `willBeOnListSnackbar` is `{name} is back on the list.` / `{name} je
  ponovo na listi.` Keys kept (Phase 7 part 7's precedent), `@`
  descriptions updated in `app_sr.arb`, l10n regenerated.
- **The walk's defect, fixed in the same commit (D147 #3).** A long-press
  blanked the list for a moment and returned it scrolled to the top: the
  revision bump reloads `currentShoppingListProvider`, and `loading:`
  rendered `SizedBox.shrink()`. The screen's `list.when` now passes
  `skipLoadingOnReload: true`; the progress bar under the range bar still
  shows the work. `_togglePantry` also reads its notifier, messenger and
  l10n before the awaits, because the reload can now move or drop the
  pressed row before the method resumes, and the old `context.mounted`
  check on the row would swallow the snackbar.
- **Tests** (`shopping_list_screen_test.dart`). `_StubList` gained a
  `regenerateCurrent()` spy (`_Calls.regenerated`), an optional
  `regenerateFailure`, and `reloadOnRegenerate`, which bumps the revision
  so `build()` re-runs as a real reload. New or changed:
  - the long-press test expects `regenerated == 1` and `brašno moved to
    Probably have.`;
  - pulling a list generates; pulling the empty state generates; a failed
    pull shows `failureOffline` and keeps the list;
  - a long-press whose regeneration fails shows the failure and not the
    success snackbar;
  - an unmatched item's long-press regenerates nothing;
  - a long-press mid-reload keeps the list and its scroll offset (fails
    without the fix: the list disappears).

**Differs from the plan.**
- The plan's `fling` of `Offset(0, 300)` never armed the indicator on the
  suite's 1200×3000 surface (it arms at a quarter of the viewport's
  height), so the pull tests pump an 800×600 `_phone` surface.
- The reload test's stub waits a full second: `tester.longPress` pumps
  ~600ms past the callback, so a shorter reload finished before the test
  could look at it.
- `l10n-check` diffs the regenerated output against HEAD, so it reads red
  until the generated files are committed. They were staged, and it
  passed.

**How it was verified.**
- `dart analyze` clean, `flutter test` **750/750** (745 + 5).
- `make -k check` failed only at `seed-check`, the known red since
  `c8be2bc`.

**Walked on the emulator** (`/design-walk shopping-list`, 2026-10-05, the
only device attached), with `make install-emulator` and Dev login: sr/light
→ sr/dark → en/light → en/dark, online and in airplane mode.
- **Pull.** Regenerates, and `Generisano …` updates. With `Ova nedelja`
  it made this week's (empty) Serbian list, with `Sledeća` next week's, and
  a pull on the nothing-to-buy body works too.
- **Long-press, both directions of the locale rule.** On an English list
  for Sep 28 – Oct 4 under Serbian chrome with `Ova nedelja` selected,
  `bread` moved to `Probably have` and back, the list stayed English and
  on its week, and the snackbars were Serbian. On a Serbian list under
  English chrome with `Next` selected, `jaje` did the same: the document
  stayed Serbian and on its week, the snackbar was English.
- **Dark.** The snackbars, the expanded staples card and its muted lines
  read clearly.
- **Offline.** A pull shows `No connection.` after ~5 s and a long-press
  at once; the saved list stays on screen and nothing moves.
- **Phone dark + app `Svetla`** stays light; `uimode` reset to `no`.
- **The defect above**, then **re-walked** after the fix (sr/light): a
  long-press inside the expanded staples and one mid-way down the to-buy
  card each kept the scroll position and the expanded section, with no
  blank frame in ~16 rapid screenshots.
- **Not reached.** Pulling on the empty no-list state on a device: this
  household always has a list. It stays open in STATE with part 22's
  no-list loop (a throwaway household closes both).
- **Seen, not this part's.** `premešteno` is neuter whatever the noun's
  gender (the old `označeno` was the same); the Serbian date-range picker
  header reads `28. sep to 4. okt` with Material's English `to`.
- **Cleanup.** The walk household's latest list is now a Serbian one for
  Sep 28 – Oct 4 (it was an English one). Toggling and toggling back left
  explicit `alwaysHave` rows on hleb, bread, jaje and voda that render the
  same as their defaults. The account ended on Srpski / Svetla.
