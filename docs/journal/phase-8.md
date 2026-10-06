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

### Part 2 — Image cache and decode size

**Status: complete** (`6d789bd`). Decisions taken during it: D148.

Planned with `/plan-slice` on 2026-10-05 and built in a fresh session. No
migration, no new ARB key. Two new packages, both approved under rule 8
during planning: `cached_network_image`, and `flutter_cache_manager` (its
own dependency) taken directly so the cache is a named instance that tests
can override.

- **Cache** (`lib/core/images/recipe_image_cache.dart`, new).
  `recipeImageCacheManagerProvider` is a keep-alive provider, on
  `network_status.dart`'s shape, with a `CacheManager` named `recipeImages`
  (60-day stale period, 500 objects). Its doc comment explains why nothing
  evicts: `uploadImage` never reuses a path (D148 #2).
- **`RecipePhoto`** (`lib/core/recipes/widgets/recipe_photo.dart`, new), a
  `ConsumerStatefulWidget`. With a URL it builds a `CachedNetworkImage` with
  `cacheKey: path`, `memCacheWidth: decodeWidth` and
  `useOldImageOnUrlChange`. With no URL it looks the path up once per path
  (`getFileFromCache`, memoised in state) and shows `Image.file(cacheWidth:)`
  or the placeholder. It never fetches the bare path (D48).
- **Card.** The photo shows whenever `imagePath` is set, not only when
  `imageUrl` is. It sits in the existing `ClipRRect` at `AppSizes.thumb`,
  with the monogram as placeholder and error widget. `decodeWidth` is `2 ×
  thumb × dpr` (D148 #4).
- **Detail.** `_PhotoWell` takes `imagePath` as well and keeps its spinner
  and the quiet `image_outlined` placeholder (D135/D139). The status-bar
  check stays on `imageUrl`. "Has a photo to show" offline is only known
  after an async lookup, so it was not trivially available, as the plan
  allowed; a code comment says so.
- **Editor.** `_PhotoField` decides "has an existing photo" from
  `existingImagePath`. The old `existingImageUrl!` force-unwrap is gone, so
  an offline draft with a path and no URL no longer throws. Spinner and
  broken-image fallback kept (D140).
- **Tests.** There was no shared-fakes folder, so
  `test/helpers/fake_image_cache.dart` is new: `FakeImageCache` (a `Fake`
  over `BaseCacheManager`) and `fakeCachedFile()`. Every pump that can show
  a photo overrides the provider. The `NetworkImage` assertions in the
  screen and editor tests now check `CachedNetworkImage`'s `imageUrl` and
  `cacheKey`. Four new card tests:
  - path + URL: cached under the path, with `memCacheWidth` set;
  - offline hit: an `Image.file` behind a `ResizeImage`;
  - offline miss: the monogram;
  - a refresh that drops the URL for the same path: still the network
    image, on its old URL.

**Differs from the plan.**
- **The remembered URL (D148 #3) came from the walk.** The plan's no-URL
  branch went straight to the disk lookup. On a pull, the cached list comes
  first and unsigned (D131), so every thumbnail flashed to its monogram
  until the signed list arrived. Fixed in the same commit, with a test, and
  re-walked.
- **The cache-hit fake.** `FileInfo` wants a `package:file` `File`, and
  `file` is only a transitive dependency, so importing it would trip
  `depend_on_referenced_packages`. `fakeCachedFile()` makes the file through
  the cache's own `IOFileSystem`, with `path_provider`'s channel mocked to a
  temp dir.
- **The fake's network fetch fails at once** (a `SocketException` stream).
  With a stream that never answered, the detail spinner kept
  `pumpAndSettle` from settling. Failing at once is what a test's
  `Image.network` always did (HTTP 400).
- **An unrelated stale hash.** `build_runner` also rewrote the hash in
  `shopping_list_providers.g.dart`, which was already stale from part 1. It
  was reverted to keep the diff to this part.

**How it was verified.**
- `dart analyze` clean, `flutter test` **754/754** (750 + 4).
- `grep -rn "Image.network" lib` returns nothing.
- `make -k check` failed only at `seed-check`, the known red since
  `c8be2bc`.

**Walked on the emulator** (`/design-walk recipes`, 2026-10-05, the only
device attached), with `make install-emulator` and Dev login. Pixel samples
were taken off rapid `screencap`s for the timing checks.
- **Pull to refresh.** It found the flash above. After the fix, six frames
  across the pull all show the photos.
- **Cold relaunch** (`force-stop`, start, ten rapid frames). Splash, the
  cream background, then the photos, with no monogram frame and no visible
  download.
- **Airplane mode, relaunch.** The list's four photos come from disk, and so
  does the detail's full-size photo. The editor preview reads the same
  path.
- **Replace.** `Kajgana` (no photo) was given a blue test image, then a
  pink one. The list showed pink at once. The detail showed the previous
  photo for a moment, then pink. After the first save the well showed the
  placeholder for about 8–15 s, until the signed detail arrived (D148
  Consequences). It is not a regression: `Image.network` with a null URL
  did the same.
- **sr/light → sr/dark → en/light → en/dark** on the list, a photo detail
  and its editor, plus `Kajgana`'s photoless detail and editor in sr/dark.
  All clean. The thumbnails are sharp at the 2× decode, the status-bar
  icons are light over the photo, and the `outline` placeholder icon reads
  on the dark well.
- **Phone dark + app `Svetla`** stays light; `uimode` reset to `no`.
- **Not reached on a device.** A recipe never seen, offline: all four
  photos had been seen, and a release build's cache can't be cleared
  without clearing the session. The offline-miss card test covers it.
- **Seen, not this part's.** Part 16's add menu is still flush against the
  right edge (fill to x=1079); STATE's bullet was updated. Offline, the tag
  chips show their raw keys (`doručak`, `sweet`) for the whole session, not
  just a frame.
- **Cleanup.** The test photo was removed from `Kajgana`, so it has none
  again, but it now sorts first because it was just edited. The pushed
  test images were deleted from the emulator. The account ended on Srpski /
  Svetla, with airplane mode off.

Part 4 (real thumbnails) stays "only if needed". The 2× decode reads sharp
and the list scrolled without a visible load on the emulator. The Galaxy
has not judged it yet.

### Part 3 — Refresh on tab switch

**Status: complete** (`67640c6`). Decisions taken during it: D149.

Planned with `/plan-slice` on 2026-10-05 and built in a fresh session. No
migration, no new ARB key, no new package, no codegen. Part 2 was its
prerequisite: a recipe-list re-read re-signs every URL, and those are now
cache hits.

- **`AppShell`** (`lib/core/router/app_shell.dart`). `onDestinationSelected`
  calls a new `_refreshBranch(ref, index)` when `index !=
  navigationShell.currentIndex`, then `goBranch`. The helper is a `switch`
  that `ref.invalidate`s the selected branch's top-level provider:
  - Recipes: the whole `recipeListProvider` family. The shell doesn't know
    the screen's query, tag or favourites filter. `tagLabelsProvider` is
    left alone because it is network-only, so re-reading it offline would
    lose the labels.
  - Plan: `mealPlanEditorProvider`, for the visible week.
  - List: `currentShoppingListProvider`, a re-read only. It never calls
    `generate()`, which a pull there means (D147).
  - Settings: `householdMembersProvider`, which feeds the member count.
    `currentHouseholdProvider` is left alone because it is keepAlive and
    the root of every tab's household id.

  It never `.bump()`s a `core/refresh/` revision: a tab switch is not a
  write. A re-tap keeps `initialLocation: true` (pop to root) and refreshes
  nothing. The class doc comment gained a paragraph citing D149.
- **Tests** (`test/core/router/app_shell_test.dart`, a new `refresh on tab
  switch` group). Counting `MealPlanEditor` and `CurrentShoppingList`
  subclasses, with the counts on a separate `_Counts` spy:
  - Recipes → Plan → Recipes → Plan builds the plan twice, once per
    arrival, and not on leaving;
  - List → Recipes → List builds the list twice and never generates;
  - re-tapping Plan or List builds nothing more.

**Differs from the plan.** `pumpApp` gained two optional notifier factories,
`mealPlanEditor:` and `shoppingList:`, instead of a general override list.
`Override` lives in `flutter_riverpod/misc.dart`, an import the repo uses
nowhere else.

**How it was verified.**
- `dart analyze` clean, `flutter test` **757/757** (754 + 3).
- `make -k check` failed only at `seed-check`, the known red since
  `c8be2bc`. Every SQL suite and the Deno tests passed.
- **Not walked.** The slice's device check (a release build against hosted;
  a change from a second account or the dashboard seen after a switch
  away and back, with no blank or spinner; airplane mode keeping the cached
  content and the banner; a re-tap only popping to root) was not run. It
  stays open in `docs/STATE.md`.

### Round 2026-10-06, slice 1 — Full weekday names in the meal plan

**Status: complete** (`96b8c15`). Decisions taken during it: D150.

The first slice of round `2026-10-06-round-2-recipe-structure`
(`docs/design/handoffs/2026-10-06-round-2-recipe-structure/`), canvas § C,
frames C·1–C·3. Planned with `/plan-slice-ui` on 2026-10-06 and built in a
fresh session. No migration, no new ARB key, no new package, no codegen, and
no token change.

- **`lib/core/l10n/date_labels.dart`.** Two new helpers next to
  `weekdayAndDay`, both through `_tag()` (D91) and both sentence-cased with
  intl's `toBeginningOfSentenceCase`, given the tagged locale (intl gives
  Serbian weekdays in lower case):
  - `weekdayNameAndDay`, `DateFormat('EEEE d')`: `Ponedeljak 5` /
    `Monday 5`, the week view's header;
  - `fullDateLabel`, `DateFormat.MMMMEEEEd`: `Ponedeljak, 6. oktobar` /
    `Monday, October 6`, the Today view's header.

  `weekdayAndDay`'s doc comment no longer calls it a day header. It is the
  compact form for the leftover meta (`od pon 5`, which can't take a
  declined full name) and the move dialog's dropdown.
- **`meal_plan_screen.dart`.** `_DayCard._header` swaps to the two helpers,
  and the `showFullDate` doc comment names them. Role, colour, pill and
  spacing are unchanged. The leftover meta, the move dialog
  (`weekdayAndDay`) and the leftover dialog (`shortDateLabel`) are unchanged.
- **Tests.** `date_labels_test.dart` gained a `weekdayNameAndDay` group (all
  seven weekdays in en and sr, Latin-only, no Cyrillic from a bare `'sr'`)
  and a `fullDateLabel` group. `meal_plan_screen_test.dart`'s header finds
  moved to the new helpers. The leftover test now also asserts that Monday's
  header carries the full name while its leftover meta stays abbreviated.
- **`docs/DESIGN_SYSTEM.md`** § Meal entries, the day-card paragraph.

**Differs from the plan.** The plan listed one Today-header find in the
screen test. There were three: the one it named, the "back to Today" pin
(~line 322) and the srLatn test (~1187). All three moved to `fullDateLabel`.

**How it was verified.**
- `dart analyze` clean, `flutter test` **763/763**.
- `make -k check` failed only at `seed-check`, the known red since
  `c8be2bc`. `make test-sql` and `make l10n-check` passed when run on their
  own.
- **Walked** (`/design-walk meal-plan`, 2026-10-06, **emulator**, hosted
  release build, Dev login, all four combinations). Today was Tuesday
  6 October.
  - Week view: `Ponedeljak 5` … `Nedelja 11` and `Monday 5` … `Sunday 11`,
    each on one line beside `+ Dodaj obrok` / `+ Add meal`, and `Utorak 6`
    beside the `Danas` pill.
  - Today view: `Utorak, 6. oktobar` / `Tuesday, October 6` on one line
    beside the pill.
  - A leftover planned from Monday read `od pon 5` / `from Mon 5` under the
    `Ponedeljak 5` header. The move dialog still showed `pon 5`, and the
    leftover dialog `uto 6. okt`.
  - A drag held over collapsed Thursday kept that card at the same
    single-row height as the other collapsed cards (UI dump: 147px), so the
    header didn't wrap. The dragged card covers the header text itself, so
    the screenshot can't show it.
  - In dark, the `onSurfaceVariant` headers, the pill and the today border
    all read clearly.
  - The test entries were removed afterwards, and Srpski / Svetla were
    restored.
  - **Not reached:** the worst-case Today header (`Ponedeljak, 30.
    septembar`, ≈250 of 308dp per the canvas) wasn't on screen, and neither
    was the Galaxy. It opened no loop.

### Round 2026-10-06, slice 2 — Shopping list row markers

**Status: complete** (`124d814`). Decisions taken during it: D151.

The second slice of round `2026-10-06-round-2-recipe-structure`
(`docs/design/handoffs/2026-10-06-round-2-recipe-structure/`), canvas § B,
frames B·1 and B·3. Planned with `/plan-slice-ui` on 2026-10-06 and built in
a fresh session. No migration, no provider or domain change, no new
package, no token change. Four ARB keys added, one removed.

- **`lib/core/ingredients/widgets/ingredient_line_row.dart`.** Two optional
  parameters, both still primitives (D127):
  - `extraAmounts`, a list of `({String? quantity, String? unit})` records,
    stacked under the first amount in a right-aligned `Column`. One private
    `_amount` builder draws the first line (still
    `Key('ingredientAmount')`) and each extra
    (`Key('ingredientExtraAmount')`, led by `+ ` in `onSurfaceVariant`).
  - `nameMarker`, a widget drawn inline after the name and optional label in
    a fixed 16dp box, `xs` before it, before the unmatched ring.

  Recipe detail and import review pass neither, and their files were not
  touched.
- **`shopping_list_screen.dart`.**
  - `_ItemRow` passes `parts.skip(1)` as `extraAmounts`, so the trailer lost
    its `+ …` line.
  - It passes the staple pin (`Key('stapleMarker')`, `outline`, tooltip
    `pantryStapleTooltip`) when `item.isPantryStaple`.
  - An unmatched item with no amount gets `notAddedUpTrailer` first in its
    trailer.
  - The staples card became `_StaplesCard`, a `StatefulWidget` that tracks
    `onExpansionChanged`. Its subline is `staplesHintCollapsed` /
    `staplesHintExpanded` from the reader's `l10n`; the heading still uses
    `bodyL10n`.
- **ARB.** Added `staplesHintCollapsed`, `staplesHintExpanded`,
  `notAddedUpTrailer` and `pantryStapleTooltip`. Removed
  `cupboardStaplesSubtitle`. Regenerated.
- **`format_item_quantity.dart`.** A comment fix only: the unit has sat
  beside the number since D127, not beside the name.
- **Tests.** The row test gained 9: the stack and its alignment, the `+`
  colour, extras without a first amount, the marker's placement and its
  absence, and four last-word cases. The screen test gained 5, and its
  two-families test asserts the stack via the keys.
- **`docs/DESIGN_SYSTEM.md`** § Ingredient lines and § Shopping list. The
  latter also lost its stale "the snackbar says it applies next time"
  (D147).

**Differs from the plan.**
- Every extra amount carries the same `Key('ingredientExtraAmount')`, and
  sibling keys must be unique, so each sits under a
  `KeyedSubtree(ValueKey<int>(i))`.
- **The walk found two defects, both fixed in this slice before close:**
  - The unmatched ring stranded alone on a fourth line under
    `1 manji koren peršuna … preporučujem)`. The U+2060 word joiner does not
    stop Flutter breaking before an overflowing placeholder. This was older
    than the slice, but the pin had copied the same glue.
    `_keepMarkersWithLastWord` now measures the name's last line and, when
    the markers won't fit, turns the last space into a line break. That is
    why `nameMarker` got a fixed 16dp box.
  - `Nije sabrano` sat beside a parsed amount (`1.67 kom`) on the same item.
    The plan assumed unmatched items have no amount. The trailer is now
    gated on `parts.isEmpty`.
- `from <recipe>` was dropped as planned: `ShoppingItem` carries no source
  recipe.

**How it was verified.**
- `dart analyze` clean, `flutter test` **777/777**.
- `make check` failed only at `seed-check`, the known red since `c8be2bc`.
  `make test-sql` passed when run on its own. `make l10n-check` passed once
  the generated files were committed.
- **Walked** (`/design-walk shopping-list`, 2026-10-06, **emulator**, hosted
  release build, Dev login, all four combinations). It used the household's
  existing `sr` list for 28 Sep – 4 Oct, with no regeneration and no
  long-press.
  - `brašno` read `500 g` over `+ 25 ml`, right-aligned, with a muted `+`.
  - `Nije sabrano` sat under `malo ljubavi` and under `malo ljute aleve
    paprike…`. Under English chrome it read `Not added up` while the list
    stayed Serbian.
  - The subline read `Dugo pritisnite stavku da je premestite ovde.`
    collapsed and `…vratite na listu.` expanded, each on one line in
    Serbian.
  - All five Probably-have rows had the pin, readable on the dark card.
  - It found the two defects above. After the fix it re-walked sr/light,
    sr/light expanded, en/dark and en/dark recipe detail: `preporučujem) ◌` sat
    on one line, the item showed `1.67 kom` with no trailer, and recipe
    detail rows were unchanged.
  - Srpski / Svetla were restored.
  - **Not reached:** the pin's tooltip (a long-press on the row would toggle
    the real pantry preference) and import review on a device. Both stay
    open in `docs/STATE.md`.

### Round 2026-10-06, slice 3 — Shopping long-press menu with Undo

**Status: complete** (`a2a278d`). Decisions taken during it: D152.

The third slice of round `2026-10-06-round-2-recipe-structure`
(`docs/design/handoffs/2026-10-06-round-2-recipe-structure/`), canvas § B,
frame B·2, **minus the one-off move**. Planned with `/plan-slice-ui` on
2026-10-06 and built in a fresh session. In planning Marko declined the
canvas's `Move to Probably have` item: it would need per-item state on a
snapshot list (D13). No migration, no provider or domain change, no new
package, no token change. Three ARB keys added.

- **`shopping_list_screen.dart`.**
  - `_ItemRow` became a `ConsumerStatefulWidget` holding a
    `MenuController`, the last pointer-down position (a `Listener`, since
    `InkWell.onLongPress` carries none) and an open flag.
  - A matched row sits in a `MenuAnchor` (`consumeOutsideTap: true`) with one
    text-only `MenuItemButton`: `alwaysInProbablyHaveMenuItem` or
    `alwaysOnListMenuItem` by `item.isPantryStaple`. `onLongPress` calls
    `controller.open(position: …)`. `onOpen` / `onClose` toggle a
    `Key('pressedRowFill')` `DecoratedBox` in `surfaceContainerHighest`,
    `Positioned` `md` past the row each side in a `Clip.none` `Stack`, radius
    `AppRadii.sm`. Unmatched rows return the bare row, so no menu.
  - `_togglePantry` became `_setStaple`, which captures the notifier,
    messenger and `l10n` and hands them to a top-level `_writeStaple`. Undo's
    closure calls `_writeStaple` again with `!alwaysHave` and no
    confirmation, so it never touches the row it may have outlived.
  - The success snackbar gained `SnackBarAction(undoSnackbarAction)`.
  - Doc comments now say: menu, Undo, no one-off move, and the pin marks a
    staple (every Probably-have row is one).
- **ARB.** Added `alwaysInProbablyHaveMenuItem`, `alwaysOnListMenuItem`,
  `undoSnackbarAction` (`Poništi`, its own key, not `clearFiltersChip`).
  Regenerated.
- **Tests.** The four long-press tests now pick from the menu; the unmatched
  one asserts no menu. Five added: which item each card offers (and the fill
  colour), dismissing records nothing, Undo writes the opposite and
  regenerates twice with no second snackbar, a failed Undo shows the
  failure, and the Serbian menu and `Poništi`. `_Calls.pantryPref` became a
  `pantryPrefs` list (with a `pantryPref` last-call getter), and the stub
  gained a `pantryPrefFailure` that fails every write after the first.
- **`docs/DESIGN_SYSTEM.md`** § Shopping list (document-card and staples-card
  sentences) and § Menu, snackbar, banner (the Undo sentence).

**Differs from the plan.**
- **`persist: false` is needed.** This SDK's `SnackBar` has `persist`,
  defaulting to `action != null`; without it the Undo snackbar would stay
  up.
- The press position comes from a `Listener.onPointerDown`, not
  `InkWell.onTapDown`, so the row does not gain a tap gesture.
- The shared helper is split in two (`_setStaple` on the state, the
  top-level `_writeStaple`) so Undo needs nothing from the row.

**How it was verified.**
- `dart analyze` clean, `flutter test` **782/782**.
- `make check` passed lint, the function tests and `make test-sql`, and
  failed only at `seed-check`, the known red since `c8be2bc`.
  `make l10n-check` passed once the generated files were committed.
- **Walked** (`/design-walk shopping-list`, 2026-10-06, **emulator**, hosted
  release build, Dev login, all four combinations), on the household's `sr`
  list for 5–11 Oct, moving `mleko` back and forth.
  - The menu opened at the finger (bounds from `(300,930)` for a press at
    `(300,909)`), and upward near the bottom. `Uvek na listi` showed on a
    Probably-have row, and every item fit on one line in Serbian.
  - Measured fill: `#E8DED3` light, `#34342E` dark, 12dp past the text on
    each side; no row shifted. A tap outside closed the menu, cleared the
    fill and did not press the row underneath.
  - Picking moved the row; the snackbar read `mleko premešteno u Verovatno
    imate.` / `mleko is back on the list.` with `Poništi` / `Undo` in
    `inversePrimary`. Undo moved it back with no second snackbar in all four
    combinations; the expanded card stayed expanded. The first two Undo
    taps missed: hosted regeneration took longer than the sleep before the
    tap, and the 4 s window had passed. A screen-polling script that taps
    as soon as the snackbar appears got it every time after.
  - Offline (sr/dark): `Nema veze sa internetom.`, nothing moved, no Undo.
  - A long-press on the pin itself shows its tooltip, not the menu, which
    closes the tooltip half of slice 2's loop (sr/light).
  - **Two findings, not fixed:** the menu is flush with the right edge when
    the press is near it (as part 16's add menu); and in dark the menu's
    `surfaceContainerHigh` is `#292923`, the same as the card, so over a card
    only the dividers it covers show its edge. Both are in `docs/STATE.md`.
  - `mleko` ended on the to-buy list, now with an explicit override. Srpski /
    Svetla were restored.

### Round 2026-10-06, slice 4 — Recipe structure data: step kinds and notes

**Status: complete** (`009d15d`). Decisions taken during it: D153.

The fourth slice of round `2026-10-06-round-2-recipe-structure`
(`docs/design/handoffs/2026-10-06-round-2-recipe-structure/`). It is data
only, with no screen changes: slices 5 (`phase8-step-headings-notes`), 6
(`phase8-recipe-end-note`) and 9 (`phase8-rich-text-render`) render what it
stores. Planned with `/plan-slice` on 2026-10-06 and built in a fresh
session. No new package, no Drift schema change, no ARB change, nothing
under `presentation/`.

The risk was silent data loss. Once a recipe has a heading or a note, every
path that rewrites it (editor save, import save, translation review save)
has to send them back. Today's editor and review screens don't show them,
so the drafts carry them through untouched.

- **Migration 24, `20261006100000_recipe_structure.sql`.**
  - `recipe_steps.kind` text not null default `'step'`, checked against
    `step` / `heading` / `note`. A new constraint,
    `recipe_steps_timer_only_on_step`, allows a timer only on a step.
  - `recipes.notes` and `recipe_translations.notes`, nullable text, with
    column comments.
  - `replace_recipe_lines` and `save_imported_recipe` are `create or
    replace` with the same signatures. Kind rides in the steps jsonb (absent
    or blank means `step`), and `recipe.notes` in the recipe jsonb (blank
    means null). `save_imported_recipe` still composes
    `replace_recipe_lines` (D44).
  - `save_recipe_translation` and `review_recipe_translation` are dropped
    and recreated with a trailing `new_notes text default null`, and their
    revoke/grant is re-applied on the six-argument signatures. The upsert
    writes notes on both insert and conflict; the review writes
    `notes = nullif(btrim(new_notes), '')`.
- **Edge Functions.**
  - `_shared/schema.ts`: `ModelStep.kind` (`ParsedStepKind`, nullable),
    `ModelRecipe.notes`, `ModelTranslation.notes`. `ModelTranslationStep`
    is unchanged.
  - `_shared/read_recipe.ts`: the import prompt learns method subheadings
    (`kind: "heading"`), asides (`kind: "note"`), a Tips / Napomena / Saveti
    section (`notes`), and keeping `- ` / `1. ` lists without adding bold or
    italics. A headnote is "the description, … and never notes". `enrich`
    spreads `model`, so both reach `import_jobs.result` unchanged.
  - `_shared/jsonld.ts`: a `HowToSection` with a string `name` emits a
    heading row ahead of its `itemListElement`.
  - `_shared/translate.ts`: the source carries `kind` and `notes`.
    `buildTranslationRequest` is exported, tags non-step rows `3. [heading]
    …` / `5. [note] …`, and adds a `Notes:` line. The prompt states the tag
    rule (translate the words, return them without the tag, keep headings
    short) and the marker rule (`**`, `*`, `"- "`, `"1. "` stay where they
    are). `translateRecipe` returns `notes`.
  - `translate-recipe/index.ts` selects `notes` and
    `recipe_steps(position, text, kind)` and sends `new_notes`.
  - The `import-*` functions were read, not changed: none builds a
    `ModelRecipe` by hand.
  - `make types` changed only `kind` / `ParsedStepKind` / `notes` in
    `parsed_recipe.dart`.
- **Dart.**
  - `RecipeStepKind { step, heading, note }` with `fromWire` (null → step,
    unknown throws), and `RecipeStep.kind` defaulting to `step`.
  - `Recipe.notes` and `RecipeTranslation.notes`.
  - `RecipeDetail.displayNotes` mirrors `displayDescription`. When a
    translation is shown, `displaySteps` overlays each row's kind from the
    source step at the same position.
  - `RecipeDraft.notes` and `RecipeDraftStep.kind` are carried by
    `fromDetail` and written by `toSteps` / `toRecipe`. `toSteps` drops a
    blank row of any kind and keeps a timer only on a step. No new
    mutators: slice 5 adds them.
  - `TranslationReviewDraft` gains `sourceNotes`, `notes` and a pure
    `setNotes`.
  - DTO, datasource and repository: `notes` on create, update and review;
    `kind` in the step embed and the step payloads of both
    `recipe_repository.dart` and `import_repository.dart`.
  - Plumbing: `RecipeEditor`, `TranslationReviewer`, `ImportConfirm` and
    `draftFromParsed` pass the new fields along.
- **Tests.**
  - SQL:
    - `rls_recipes_test.sql`: kinds stored in order, omitted kind → step,
      unknown kind and a timer on a heading refused, a refused call rolls
      back.
    - `save_imported_recipe_test.sql`: imported notes trimmed, imported
      kinds stored.
    - `review_recipe_translation_test.sql`: a review with notes writes
      them, without notes clears them.
    - `rls_recipe_translations_test.sql`: the same two for the upsert.
    - Both grant checks moved to the six-argument signatures.
  - Deno: the HowToSection heading, the four markers named in the prompt,
    the tag rule, and `buildTranslationRequest` tagging (plus no `Notes:`
    line when there are none).
  - Dart:
    - `recipe_draft_test` (kind round trip, blank heading dropped, no timer
      on a heading or note, notes through `toRecipe`).
    - `recipe_detail_translation_test` (kind overlay, `displayNotes` three
      ways, the review draft carries both notes).
    - `local_recipe_datasource_test` (a pre-D153 cached blob decodes to
      `step` and null).
    - `parsed_recipe_draft_test` (kinds and notes mapped, null kind → step).
    - The offline-test fake gained the new parameters.

**Differs from the plan.**
- **`save_recipe_translation` had explicit grants too.** The plan named
  only the review function's. Since a drop takes the grants with it, both
  are re-applied, and `rls_recipe_translations_test.sql`'s grant checks
  moved to the new signature.
- **`alignSteps` takes `Pick<TranslationSourceStep, "position">`.** It only
  reads positions, so the existing kind-less test fixtures still
  type-check.
- **`save_recipe_translation` blanks notes to null** (`nullif(btrim(…))`),
  unlike its verbatim `description`.
- Tests beyond the list: the upsert's notes cases, the review draft
  carrying notes, and an import with no notes.

**How it was verified.**
- `supabase db reset` applied migration 24 cleanly, and `make test-sql`
  passed all 20 suites, the new cases included.
- `make test-functions` **165/165**, and `make lint-functions` (check,
  lint, fmt) clean.
- `dart run build_runner build -d`, then `dart analyze` clean and
  `flutter test` **795/795**.
- `make check` failed only at `seed-check`, the known red since `c8be2bc`.
  `test-sql` and `l10n-check`, which `make check` runs after it, were run
  by hand and passed.
- **Not deployed and not walked.** There is nothing on screen to walk. The
  hosted project still needs `supabase db push` for migration 24, and
  `make functions-deploy` for `translate-recipe` and the three `import-*`
  functions, before slices 5–6 can be walked on a device.
