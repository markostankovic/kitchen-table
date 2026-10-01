# State — 2026-10-01

**Branch:** `main`
**Last shipped:** Phase 7 part 13 (`6f3336b`), two fixes from device
feedback (D135, amending D119 and D121).

- **Recipe detail.** The app bar sits over the 16:9 photo as a pinned,
  collapsing `SliverAppBar`. Back, heart, edit and the overflow menu sit on
  `surface` discs at 0.7 alpha. The status-bar icons are light while a
  photo is behind them. Collapsed, it is the old solid bar.
- **Meal plan.** A drag never changes an entry's slot. Dropped on an entry
  of the same day and slot it takes that position (`reorderEntry`).
  Dropped on another day's card, expanded or collapsed, it moves there in
  its own slot and lands last. A different slot on the same day takes
  nothing. Changing the meal is *Move to…*.

`dart analyze` is clean and `flutter test` passes 718/718 (`make check`
was not run). The emulator walk (sr/en × light/dark, hosted release build)
found one defect, dark status-bar icons over a photo in Light. It was
fixed and re-walked in sr/light and en/light, so part 13 opened no loop.
Not reached: a same-day drop onto a different slot (the widget test covers
it) and the Galaxy.

Still open, not part 13's:
- meal-plan recipe entries show the original-language title under `en`
  (the entry's own `recipeTitle`, D53);
- the signed-out sign-in screen stays Serbian after an in-app switch to
  English;
- tag chips show raw keys for a frame on a cold start;
- the shopping list prints `1.5 kg` in Serbian;
- units don't inflect (`2 glavica`);
- the recipe-delete confirm is a filled button;
- the `List — offline`, `Review import`, `Household` and `Settings` frames
  in `docs/design/screens/` still show the old bordered card, until Claude
  Design updates them.

**In flight:** none.
**Next:** no roadmap part is planned. Walk the open loops below in one
sitting with the Galaxy attached: part 10a's two surfaces, part 10b's
Galaxy checks, and part 12's import review. Then `/plan-slice` whatever
comes next. The meal-plan translated-title gap is a small candidate.
**Latest decision:** D135

**Nine device-walk loops are open.** Phase 7 part 3's walk ran on the physical
Galaxy (2026-09-25) and closed four: Phase 6 1a and 2, and part 2's own FAB
and search-field defects. It found one defect of its own, which was fixed and
re-walked in the same sitting, so part 3's loop closed too. Part 5's walk
(`/design-walk shopping-list`, 2026-09-25) closed part 1's shopping-list
translation item and part 2's two remaining defects, so both of those loops
closed. It found two defects of its own, both fixed and re-walked the same
evening, so part 5's own loop closed too. Part 6's walk
(`/design-walk import-review`, 2026-09-26) opened no loop. It found one
defect, fixed and re-walked in the same sitting, and answered part 2's
marker-in-dark and part 3's dashed-ring leftovers below. Part 7's walk
(`/design-walk forms`, 2026-09-26, with its defect re-walked 2026-09-28)
closed Phase 5 part 6. It opened part 7's own loop, which now holds only
the unwalked onboarding screens. Part 8's walk (`/design-walk
auth-household`, 2026-09-28, on the emulator) confirmed the adult halves of
Phase 6 3b and 3c. It opened part 8's own loop for the owner side and the
Google-only checks. Part 9a's three walks (recipe detail, import review,
shopping list; 2026-09-28, emulator) found four defects, all fixed and
re-walked, so part 9a's loop closed. Part 9b's walks (Settings and
recipes, 2026-09-28, emulator) found one defect, the white native splash on a
Dark cold start. It was fixed and re-walked the same sitting, so part 9b's
loop closed. Part 10a's recipe-detail walk (2026-09-29, emulator) was
clean; its shopping-list and import-review walks are still open. Part
10b's emulator check (2026-09-29) covered the Pixel icon mask and one cold
start. Its Samsung, themed-icon and Light/Dark cold-start checks are still
open. Part 11's walk (2026-09-29, emulator, all four combinations) was
clean, so it opened no loop. In the same sitting the user's own paste into
Google Keep closed Phase 5 part 5. Part 12's walk (2026-09-30, emulator,
all four combinations) was clean, but it opened a loop for the two surfaces
it didn't reach. It also confirmed most of part 4's meal-plan items. Part 13's walk
(2026-09-30, emulator, all four combinations; the fix re-walked 2026-10-01)
found one defect, fixed and
re-walked in the same session, so it opened no loop. Oldest
first:

- ~~**Phase 5 part 5**~~ — **closed 2026-09-29.** Phase 7 part 5's walk
  (2026-09-25) confirmed the copy and the SnackBar on the physical Galaxy.
  The paste half was confirmed by the user, who pasted a copied list into
  Google Keep and reported that it works.
- ~~**Phase 5 part 6**~~ — **closed by Phase 7 part 7's walk (2026-09-26).**
  On the physical Galaxy, hosted release build, Translate in the editor's app
  bar on `Kajgana` (no translation) saved, called the Edge Function (one
  hosted AI call) and came back: the action left the app bar (the D85 guard),
  the recipe reads `Scrambled Eggs` with a `Machine translation` chip under
  English, and the detail menu offers `Review translation` instead of
  Translate. The snackbar was not seen: it went by while the walk was
  polling the screen. So `Kajgana` now has a machine English translation on
  hosted, not yet reviewed.
- ~~**Phase 6 part 1a**~~ — **closed by Phase 7 part 3's walk (2026-09-25).**
  On the physical Galaxy, switching to English relabelled the household's
  `Doručak` tag to `Breakfast` on the list and `Slatko`/`Užina` to
  `Sweet`/`Snack` on the detail; the recipe's own title came through as
  `Crêpes` under a `Machine translation` chip; tapping the translated
  `Breakfast` chip still narrowed the list to one recipe.
- **Phase 6 part 1b** — saving a recipe with a brand-new Serbian tag mints
  its English pair; the chip relabels on a language switch; saving again
  makes no second model call (`ai_usage` rows or the function log). Not
  confirmed — Phase 7 part 3's walk read the recipes surface but minted no new
  tag, which is what this loop needs.
- ~~**Phase 6 part 2**~~ — **closed by Phase 7 part 3's walk (2026-09-25).**
  With the app in English, typing the *Serbian* spelling `doru` narrowed to
  the recipe tagged `Doručak` — cross-language tag search works from the
  field, not only from the chips. A chip tap narrowed by whole token, and the
  Favorites chip rendered alongside the tag chips throughout.

  Not exercised: a single query matching one recipe by title and another by
  tag at the same time. This household has two recipes and no query separates
  them that way; it needs seed data built for it rather than another walk.
- **Phase 6 part 3b** — with a second account joined: owner sees Remove on
  the other member's row and no Leave on their own; the adult sees Leave on
  their own and no Remove on the owner's; both write through and the row
  disappears; Leave lands the now-memberless account on
  `CreateHouseholdRoute` with no restart. Needs a second Google account.
  **Adult half confirmed by Phase 7 part 8's walk (2026-09-28, emulator):**
  the D125 dev-login account is an adult in the device household. It sees
  the bottom `Napusti domaćinstvo` row, no `⋮` on anyone's row, and no
  Delete. The Leave dialog opens with a crimson text confirm and was
  cancelled, because leaving would drop the dev account from the real
  household. Still open: the owner's `⋮` → `Ukloni člana`, and both
  write-throughs.
- **Phase 6 part 3c** — on a throwaway household: the owner sees the Delete
  row and an adult does not; the confirm dialog names the household;
  confirming lands the ex-owner on `CreateHouseholdRoute` with no restart;
  creating a new household afterward works. Needs a throwaway household —
  the signed-in device account has real recipes. **Adult half confirmed by
  Phase 7 part 8's walk (2026-09-28):** an adult sees no Delete row. The
  owner half is still open.
- ~~**Phase 7 part 1**~~ — **closed by Phase 7 part 5's walk (2026-09-25).**
  Walked on the physical Galaxy across `sr`/`en` ×
  light/dark on recipe list, recipe detail, meal plan, shopping list,
  household, settings. Two defects found, both now resolved:
  - ~~Recipe list card's meta line wraps badly in Serbian~~ — **resolved by
    Phase 7 part 2**, incidentally rather than deliberately. Part 2's
    `ListTileThemeData` sets `subtitleTextStyle` to `bodySmall` (12);
    before that the subtitle fell through to Material's `bodyMedium` (14).
    Two points narrower is enough: `4 porcije · 10 min priprema · 10 min
    kuvanja · ★ 5` now sits on one line in both languages and brightnesses.
    Re-confirmed on the device 2026-09-25.
  - The shopping list screen (`Lista`/`List` tab) leaves several UI strings
    untranslated when the app language is Serbian: the "Generated Thu, Sep
    24 for Mon, Sep 21 – Sun, Sep 27" line, the "Probably have (N)" section
    header, and its "Cupboard staples" subtitle all render in English.
    `test/core/l10n/arb_parity_test.dart` only checks that ARB keys exist on
    both sides, so it didn't catch this — worth checking whether these
    strings are hardcoded rather than routed through `AppLocalizations`, or
    whether the `sr` ARB entries are simply missing. (Ingredient names
    themselves — bread, milk, egg, flour — were also English, but that's
    recipe data, not a UI string, and out of scope here.) **Resolved — it was
    never a missing translation.** The list on the device had been
    *generated in English*, and D94 renders the document in its generating
    locale; the English ingredient names were the same fact. Part 5's walk
    confirmed it both ways on the device: regenerated under Serbian, the
    list read `Generisano pet 25. sep za …`, `Verovatno imate (3)`,
    `Namirnice iz ostave` and `mleko`/`jaje`; regenerated under English, all
    of it English — each under the new `SR`/`EN` doc-language tag, which is
    what makes the split legible.

- ~~**Phase 7 part 2**~~ — **closed by Phase 7 part 5's walk (2026-09-25).**
  Walked on the physical Galaxy 2026-09-25 across
  `sr`/`en` × light/dark on recipe list, recipe detail, meal plan, shopping
  list, household and settings. The tokens themselves are sound: Literata
  renders every Serbian Latin diacritic in both weights (`č ć ž š đ Č Ć Ž Š
  Đ`, checked against real recipe copy, no tofu), nothing truncates or
  overflows in Serbian, both brightnesses are legible throughout, and the
  offline banner reads calm in both. Of the four things it left open, part 3
  resolved two (the FAB and the search field) and part 5 the other two:
  - ~~The shopping list's week-range header wraps badly~~ — **resolved by
    Phase 7 part 5**: the range left the button row for its own `bodySmall`
    line under the segments, shown only when it differs from the list's.
    On the device `Sledeća lista: pon 28. sep – ned 4. okt` and `… uto 22.
    sep – čet 24. sep` each sit on one line. Was: In Serbian `pon 21.
    sep – ned 27. sep` breaks across **three** lines with `sep` orphaned on
    the last; English `Mon, Sep 21 – Sun, Sep 27` takes two. It shares a row
    with the `Ova nedelja`/`Sledeća` buttons and the calendar icon, and
    `titleMedium` going 17pt sans → 18pt Literata is what pushed it over.
    Nothing clips — it wraps, it does not overflow.
  - ~~The saved-copy line in `error` crimson~~ — **resolved for the shopping
    list by Phase 7 part 5**: in airplane mode on the device, sr/light and
    sr/dark, it renders grey under the grey banner. Was: the global offline
    banner is now calm grey, but the **per-screen**
    "Showing your saved copy — no connection." line is still drawn in
    `error` crimson, and the two appear on screen together on the shopping
    list. MIGRATION_PLAN § 2.1 settled that offline is calm; part 2 only
    restyled the global banner (`core/net/offline_banner.dart`). **Fixed for
    the meal plan by Phase 7 part 4** (`onSurfaceVariant`, with a test on
    its colour), which has not yet been confirmed on the device — that is
    part 4's loop, below.
  - ~~The FAB has **no `FloatingActionButtonThemeData`**~~ — **resolved by
    Phase 7 part 3**, which added one (`primary`/`onPrimary`, elevation 0,
    radius `AppRadii.lg`). Confirmed on the device 2026-09-25: in dark the
    FAB is now a light-green `primary` square that is unmistakably present,
    where `primaryContainer` had it at 1.94:1 receding into the ground.
  - ~~The search field's hint and input text render in **Literata**~~ —
    **resolved by Phase 7 part 3**, which put the hint on
    `inputDecorationTheme.hintStyle` and the typed text on `AppSearchField`'s
    own `style:` (a `TextField`'s *input* style cannot be themed). Confirmed
    on the device 2026-09-25 in **both** consumers — the recipe list and the
    meal plan's recipe picker sheet. The forms elsewhere still need their own
    `style:`; slice 6 sweeps them.

  Not verified: the 3px paprika review marker on `import_review_screen.dart`
  in dark (D117's constraint, now carried by `tertiary` `#FF9569`). Reaching
  that screen needs a real import — an AI parse on the hosted quota and an
  `import_jobs` row — and that was deliberately skipped rather than spend it.
  The value measures 8.44:1 against the dark surface, well clear of the
  generated value D117 rejected, but nobody has looked at it at 3px.
  **Confirmed by Phase 7 part 6's walk (2026-09-26):** on the physical Galaxy
  the 3px marker reads clearly in dark, on the flagged rows' `#1C1C16` tint and
  as the bar in the summary card.

- ~~**Phase 7 part 3**~~ — **closed 2026-09-25.** Walked on the physical
  Galaxy across `sr`/`en` × light/dark on the recipe list, the recipe detail
  and the meal plan's recipe picker sheet. The surface is right: **the meta
  row wraps by whole items** — in Serbian `Palačinke` takes three lines
  (`4 porcije` / `10 min priprema` / `10 min kuvanja ★ 2`) and no item is ever
  split from its own icon, which is the Serbian defect fixed structurally
  rather than by two points of font size. Monogram tiles stand in for missing
  photos, the heart/star split reads clearly, the stat strip's four Serbian
  labels (`Porcije` `Priprema` `Kuvanje` `Ocena`) each fit on one line at
  phone width, step discs and ingredient hairlines are legible in both
  brightnesses, and `RecipeCard` renders identically in the picker sheet.

  One defect found, and fixed in the same sitting:
  - ~~**The stat strip's rating column overflowed**~~ — stars three, four and
    five sat off the right edge, untappable, so nobody could rate a recipe
    above 2. `_RatingStars` is five `IconButton`s, and an M3 `IconButton`
    sizes itself from its **style**: `app_theme.dart`'s `iconButtonTheme`
    sets `minimumSize: Size(target, target)` (48dp), which the widget-level
    `padding: zero` / `constraints: BoxConstraints()` do **not** override. Five
    stars wanted ~220dp inside an ~86dp quarter-width column. The stars had
    always been that wide; before part 3 they had a full-width row to sprawl
    in, so it never showed.

    Fixed locally in `_RatingStars` — `IconButton.styleFrom(minimumSize:
    Size.zero, padding: EdgeInsets.zero, tapTargetSize: shrinkWrap)` makes
    each button exactly its 16dp icon, and a `FittedBox(scaleDown)` is the
    backstop below ~340dp of screen width. Not a theme change: the 48dp
    minimum is right everywhere else in the app.

    Re-walked after the fix on the same device: all five stars inside the
    Rating column in `sr`/`en` × light/dark, and tapping the fifth registered
    a 5 against hosted data (set back to its original 2 immediately).

    Guarded by two new tests that pump a 360×780 surface — the old ones all
    pumped 800×600, where a 220dp row simply fits. One asserts every star's
    rect is on screen, the other hit-tests the fifth star's centre and asserts
    the hit reaches it. Both fail against the pre-fix widget.

  Fixed alongside it: **the strip's values did not share an optical line.**
  Each column's value hung from its own top edge, so a 16dp star row sat lower
  than a 26dp line of text and the strip read as four things at four heights.
  `AppStatStrip` now centres every value in a box one `bodyLarge` line tall
  (a minimum, so a two-line value grows rather than clipping), with its own
  alignment test.

  Not exercised: an unmatched ingredient line's dashed ring. No recipe in this
  household has an unmatched line, so there was nothing to look at — it needs
  seeded data rather than another walk. **Confirmed by Phase 7 part 6's walk
  (2026-09-26):** a hand-added line on the import review showed the 16dp dashed
  ring, legible and reading as dashed in both brightnesses.

- ~~**Phase 7 part 5**~~ — **closed 2026-09-25.** The shopping list
  surface, walked on the physical Galaxy across `sr`/`en` × light/dark
  (`/design-walk shopping-list`). Right: quantities line up in their `primary` column; the
  `SR`/`EN` tag is legible in dark (`#1C1C16` fill, `#494A3F` ring); the
  staples card expands and collapses, its trailers (`Malo mlake vode`) read
  in both brightnesses and its last row drops its hairline; long-press
  toggles a staple with the "applies next time" snackbar and leaves the
  snapshot alone (D13) — `hleb` was toggled on, regenerated into
  `Verovatno imate`, and toggled back; `Sledeća` and a custom `Datumi`
  range select correctly and show the range line on one line; re-tapping
  `Datumi` reopens the picker pre-filled; the saved-copy line is grey
  offline; the document follows the generating locale both ways. Two
  defects, both fixed and re-walked on the device the same evening:
  - ~~**The selected `Ova nedelja` / `This week` segment wraps to two
    lines**~~ — **fixed with `showSelectedIcon: false`** and re-walked on
    the device in `sr`/`en` × light/dark: every segment on one line, the bar
    a steady 48dp, the selected one still unmistakable by its
    `secondaryContainer` fill in both brightnesses. Pinned by a test on the
    flag itself — `flutter_test`'s square-glyph font wraps `Ova nedelja` at
    any segment width, so no test can measure this one. Was: in **both**
    languages, so it is width, not Serbian length.
    Each segment is ~109dp at this width; Material swaps the selected
    segment's icon for a check, and check + padding leave too little for a
    two-word label. The bar grows from 48dp to 56dp while that segment is
    selected (measured 168px vs 144px at 3×) and snaps back when another
    is. `Sledeća`/`Next` and `Datumi`/`Dates` fit selected.
  - ~~**The category grouping does not read as grouping.**~~ — **fixed by
    a hairline under every to-buy row but the card's last** (the card edge
    does that one), the `md` gap between blocks kept. Re-walked in light and
    dark: one even list, with a block break showing as extra space above a
    hairline and same-block rows (`milk`, `egg`) sitting tighter. The
    grouping is now a quiet cue rather than a loud one, which suits D105's
    "scan it in a shop". Pinned by a test that the last row of a block
    keeps its hairline and only the card's last drops it. Was: blocks are
    separated by a bare `md` gap and a block's last row drops its hairline,
    so on a real list (`mleko, jaje` · `brašno` · `hleb`) the only hairline
    on screen sits between `mleko` and `jaje`, and the gaps read as uneven
    row spacing rather than as groups. Working as specified (D105-amended,
    no headings) — the spec did not survive a real list where most
    categories hold one item.

  Not exercised: a two-family item's `+ 300 g` trailer — nothing planned
  this week sums two unit families, so there was nothing to look at.
  Cosmetic, not this slice: the global offline banner's Serbian string
  shows a literal `--` (`Nema veze -- prikazane su …`), and the date
  picker's Material header reads `22. sep to 24. sep` — Flutter's own `sr`
  strings, not ours.

- **Phase 7 part 4** — the meal plan surface, not yet walked.
  `/design-walk meal-plan` on the physical Galaxy across `sr`/`en` ×
  light/dark. Look at: today's 2dp outline and `Danas` pill legible in dark
  (`#9ED498` on `#1C1C16`, `#013908` pill text); an add row `+ Doručak +
  Ručak + Večera + Užina + [+]` wrapping by whole buttons at phone width, with
  the trailing `+` not reading as a stray duplicate of `+ Užina`; the
  leftover's dashed border reading as dashed at 1dp in both brightnesses and
  the mustard return icon visible in dark (`#E8C174`); a long Serbian recipe
  title wrapping, not truncating; a collapsed `pon 14 … + Dodaj obrok` on one
  line; the Serbian week range on one line (two at worst) between the
  chevrons; the drop highlight on a `+ Slot` button, a filled slot's group
  and a collapsed day; a drop on a collapsed day keeping the slot; the action
  sheet, all three dialogs and the snack-repeat dialog still opening; the
  saved-copy line grey in airplane mode beside the calm banner; and an empty
  Today view showing all four `+ Slot` buttons.
  **Mostly confirmed by Phase 7 part 12's walk (2026-09-30, emulator,
  all four combinations).** Today's 2dp outline and `Danas` pill read in
  dark. The leftover's dashed border reads as dashed in both brightnesses,
  and the mustard return icon shows in dark. A collapsed `čet 1 … + Dodaj
  obrok` fits on one line, and so does the Serbian week range
  (`28. sep – 4. okt 2026.`). Hovering a filled slot's group or a collapsed
  day highlights it. A drop on a collapsed day kept `Večera`. A tap opens
  the action sheet. The per-slot add row and the empty Today view's
  `+ Slot` buttons are gone (D132), so those checks no longer apply.
  **Still open:**
  - a long Serbian recipe title wrapping (none in this household);
  - the three dialogs and the snack-repeat dialog;
  - the saved-copy line in airplane mode;
  - the Galaxy's own screen.

- **Phase 7 part 7** — the form vocabulary. Walked on the physical Galaxy
  (2026-09-26) across `sr`/`en` × light/dark: the recipe editor, translation
  review, and the import paste / URL / photo screens. All right: labels above
  every field, sans typed text in title, description, a number, an
  ingredient line and a step; the numbers row fits one line at this width
  (`Porcije` / `Priprema (min)` / `Kuvanje (min)`, no wrap, so the two-row
  layout was not exercised on device; the 360dp test covers it); the action
  bar on `surface` with its hairline, distinct from the nav bar in both
  brightnesses; the match chip reads `Nema poklapanja` under Serbian and
  `No match` under English on the same Serbian recipe, with the new line's
  hint staying `2 šolje glatkog brašna`; translation review's caption /
  original / field stacking reads in both, original visibly secondary.
  **One defect, fixed and re-walked (2026-09-28):** the photo screen's
  outlined `Izaberi fotografiju` / `Choose a photo` wrapped to two lines in
  **both** languages and both brightnesses. That's a width problem, not a
  Serbian one: each half is ~183dp. The import review's `lg` button padding
  (D123) fixed the English but not the Serbian, so the labels became
  `Kamera` / `Galerija` and `Camera` / `Gallery` (ARB values only, keys
  unchanged), the editor's own photo-picker words. Re-walked on the Galaxy in
  sr/dark and en/light: one line each, with room to spare.
  **Not walked:** the create / join household screens. They are reachable
  only on an account with no household, and the device account has real
  recipes, so the join code's serif digits are still unjudged. Slice 7
  (`phase7-auth-household`) can walk them with its throwaway household.

- **Phase 7 part 8** — sign-in, settings, household
  (`phase7-auth-household`). Walked on the **emulator** (2026-09-28,
  `make install-emulator`, dev-login account) across `sr`/`en` ×
  light/dark. All right:
  - **Sign-in:** the green wordmark on one line; the Serbian tagline wraps
    evenly over two lines; the 52dp button is pinned at the bottom with the
    spinner while busy; legible in dark. Dismissing Google's add-account
    screen returns to idle with no error line.
  - **Settings:** a mustard circle avatar, legible in dark; `Jezik` /
    `Language` in Literata; `Srpski` / `English` on one line each.
  - **Household:** `Renamed Household` / `2 člana` / `2 members`; circles,
    not squares; `Član · vi` / `Member · you`. The invite card's six serif
    digits are evenly spaced and read as a code. `Kopiraj kod` + `Opozovi`
    fit on one row. Revoke and the Leave row are crimson in light and pink in
    dark. Copy and Revoke both write through.

  **Two defects, fixed and re-walked the same sitting:**
  - The tonal Copy button rendered **filled green**. `filledButtonTheme` set
    `backgroundColor: primary`, which overrides every `FilledButton`
    variant, and it also painted the import review's tonal `Open recipe`
    green. The two colour lines came out of the theme (Material 3's
    defaults already give filled `primary` and tonal
    `secondaryContainer`), with a light/dark theme test that fails on the
    old theme.
  - Settings' language toggle sat flush on the hairline under it: the theme
    `Divider` takes 1dp of space. An `lg` gap was added.

  **Not walked** (they need the Galaxy, or an owner account on the
  emulator):
  - the owner's `⋮` → `Ukloni člana` and the Remove / Delete dialogs;
  - a long Serbian household name wrapping under the edit icon (the 360dp
    widget test covers the layout, not the device);
  - the sign-in failure line;
  - part 7's create / join screens;
  - a fresh Google account via `on_auth_user_created`.

- ~~**Phase 7 part 9a**~~ — **closed by its own three walks (2026-09-28,
  emulator).** Serif only on recipe titles, ingredient rows name-left /
  amount-right, lighter steps (`phase7-part9a-type-and-reading`).
  **Recipe detail is walked**: on the **emulator**
  (2026-09-28, `make install-emulator`, dev-login account) across `sr`/`en` ×
  light/dark, using a throwaway `Walk test 9a` recipe that has since been
  soft-deleted. `adb` can't type diacritics, so its long name was ASCII. What
  was right:
  - **Serif:** the recipe title, card titles and monogram letters are the
    only serif. The app bar, `Sastojci` / `Koraci` and the dialog title are
    sans.
  - **Ingredients:** Palačinke's amounts (`200 g`, `2`, `1 dl`, `3 dl`,
    `kašičica`) line up on the right edge. The number is green and the unit
    muted, and both hold in dark. A long unmatched name wraps over two lines
    with the dashed ring inline after it. `so` shows the name only, with
    `po ukusu` under it.
  - **Steps:** 18/28 sans, lighter than before. The 28dp disc centres on the
    first line.
  - **Stats:** values are w600.

  **Two defects, fixed and re-walked the same sitting:**
  - An optional line said `opciono` twice (`limun · opciono` over an
    `opciono` note). The parser moves the marker into the note, and the
    slice had dropped the old `note == null` guard. The guard is restored on
    recipe detail and import review.
  - An unmatched line showed its amount twice (`1,5 kg meseno…` with
    `1½ kg` at the right). This predates the slice, but the flip made it
    obvious. A line with no catalog name now gets no amount of its own
    (rule 3: it renders as typed).

  **Import review is walked** too, on the emulator the same day across
  `sr`/`en` × light/dark. It used a pasted `Sarma od kiselog kupusa` that
  was then discarded: 7 of 8 matched, 3 flagged, one unmatched, a `3–4`
  range, `so · po ukusu`, and a `lovorov list · opciono` trailer. The
  marker, tint and muted trailers hold in dark. Two more defects, both fixed
  and re-walked:
  - **Only flagged rows were inset.** The mock insets every row 12dp on both
    sides, which is how flagged names line up with the others. A new
    `IngredientLineRow.inset` does this, and import review sets it on every
    row. The hairline and tint still run the full width.
  - **The unmatched ring could wrap onto a line by itself** (`…od koliko
    bude` / `◌`). A word joiner before the ring now keeps it with the last
    word.

  **Shopping list is walked**, clean, the same day across `sr`/`en` ×
  light/dark. A throwaway Sarma import was saved, planned for Tuesday lunch
  and used to generate this week's Serbian list; the recipe and the plan
  entry were removed afterwards. The generated list itself stays, since a
  list is a snapshot. What was right:
  - amounts line up on the right edge down the card (`1.5 kg`, `300 ml`,
    `2 kom`, `1 glavica`);
  - the long unmatched `komadic … od koliko bude ◌` wraps with its ring;
  - `so` under `Verovatno imate` shows the name only, with `so, po ukusu`
    as its trailer;
  - the gaps between rows fall between category blocks, with no headings,
    per D105;
  - legible in dark;
  - the `SR` tag and the list's own text stay Serbian under English labels,
    by design.

  **Seen, not part 9a's, left alone:**
  - the list prints `1.5 kg` with a decimal point in a Serbian list;
  - units don't inflect (`2 glavica`).

  **Not reached on device:** a *matched* long name against its amount.
  Catalog names are short, so only the 360dp widget test covers it.

- ~~**Phase 7 part 9b**~~ — **closed by its own walks (2026-09-28,
  emulator).** Grouped Settings, in-app Light/Dark, clear filters on the
  recipe list (`phase7-part9b-settings-and-filters`).
  **Settings is walked**: on the **emulator** (2026-09-28,
  `make install-emulator`, dev-login account) across `sr`/`en` ×
  light/dark, using the in-app theme toggle. What was right:
  - **Layout:** the groups, their headers, the cards and the neutral
    outlined `Odjavi se` / `Sign out` all fit at 1080×2424 without scrolling.
    `Važi samo za ovu aplikaciju, bez obzira na podešavanje telefona.` wraps
    cleanly over two lines, and the English line fits on one. `2 člana` /
    `2 members` read right. The muted headers and subtitles hold in dark.
  - **Theme:** tapping `Tamna` repaints within 0.6s. With the phone in
    night mode and the app on `Svetla`, the app stays light. Dark survives
    sign-out (the sign-in screen stays dark) and signing back in.
  - **Household row:** opens the household screen.

  **One defect, fixed and re-walked the same sitting:**
  - **A cold start in Dark flashed white.** The first Flutter frame
    is already dark, so the Dart preload works. But Android's native launch
    screen (`android/app/src/main/res/values*/styles.xml`, the stock white
    `launch_background` with the Flutter logo) comes first. It follows the
    phone's night mode, not the app's choice, and it can't read Drift. So a
    Dark user on a light phone sees a white splash, and a Light user on a
    dark phone sees a black one. The fix is probably a neutral splash that
    doesn't depend on the brightness (a brand surface colour, the same in
    `values` and `values-night`), which is a design call.

    **Fixed in part 9b:** the user chose to fix it inside the slice. The
    launch screen is now flat `primary` green (`#366A35`) with no icon, from
    one `splash_background` colour. `values-night` is deleted, and a new
    `values-v31` sets Android 12+'s `windowSplashScreenBackground` and a
    transparent icon; the stock Flutter logo was the launcher icon.
    `NormalTheme` uses the same colour. **Re-walked:** a cold start in all
    four combinations of phone mode × app theme goes green, then the app's
    own theme. The wrong theme's colour never appears (`c_phone{L,D}_app{L,D}`
    strips). Nothing green shows through while the keyboard opens.

  **The recipe list is walked too** (`/design-walk recipes`, same sitting,
  emulator, all four combinations). All right:
  - **Filter row:** with nothing selected there is no `Poništi` / `Clear`,
    and the last chip runs off the right edge (full-bleed). With a tag or
    Favorites on, the outlined Clear chip and the hairline come first and are
    visible without scrolling. Both hold in dark.
  - **Clear:** it drops the tag and Favorites and keeps the search text
    (`p` + Doručak → `1 recept`; Clear → `p` still in the field,
    `2 recepta`).
  - **Count:** `1 recept`, `2 recepta`, `1 recipe`, `2 recipes`, muted and
    readable in dark. A search on its own shows the count and no Clear chip.
    `5 recepata` isn't reachable: this household has three recipes, so that
    form rests on the widget test.
  - **No results** (Omiljeni + Doručak): `search_off`, `Nema recepata koji se
    poklapaju.`, the body on one line in both languages, and a tonal
    `Poništi filtere` / `Clear filters` that restores the full list.

  Seen, not a defect: the Clear chip's ✕ takes the theme's chip-icon colour
  (green `primary`), which the slice didn't specify.

  **Not reachable on the emulator:** the Google half of `Prijavljeni ste
  Google nalogom`. The dev-login account shows the line too, which is only
  true of real (Google-only) accounts.

- **Phase 7 part 10a** — step timeline, dashed ingredient dividers
  (`phase7-part10a-step-timeline-dashed-dividers`). **Recipe detail is
  walked**, clean, on the **emulator** (2026-09-29) across `sr`/`en` ×
  light/dark. The dashes run edge to edge with none under the last
  ingredient. The step line stops short of each disc, stretches through the
  8-line Serbian step 5 of Palačinke, and is quiet but visible in dark. A
  single step (Kajgana) draws none. The unmatched ring reads as a different
  thing from the divider in both brightnesses. Nit: the dashes end ~3dp
  short of the right text edge.
  **Still open:**
  - `/design-walk shopping-list`: dashes between every to-buy row but the
    card's last, still reading as block breaks per part 5's fix.
  - `/design-walk import-review`: the dashes start and end at the text while
    the flagged tint and marker reach the edge and meet the dashes with no
    gap. Check the right-edge nit there, where the dashes should end at the
    text.

- **Phase 7 part 10b** — the app logo (`phase7-part10b-app-logo`).
  **Checked on the emulator** (2026-09-29, API 37): the adaptive icon sits
  under the Pixel circle mask with the steam and legs inside it, and one
  Light cold start showed the green splash with the centred mark, then the
  recipe list. **Still open:**
  - On the **Galaxy**: the icon under Samsung's squircle mask, with nothing
    clipped.
  - **Themed icons** on (Android 13+): the monochrome icon shows, and the
    band reads as a gap in the bowl.
  - **Cold start** in all four phone × app Light/Dark combinations: no white
    flash, and no mark jump or flicker into the first Flutter frame. If it
    flickers, point `NormalTheme` at `@drawable/launch_background`.
  - iOS: no device.

- **Phase 7 part 12** — sans only, borderless cards, the meal-plan grip
  (`phase7-sans-borderless-cards`). **Walked on the emulator** (2026-09-30,
  hosted release build, Dev login, sr/light → sr/dark → en/light → en/dark).
  All clean:
  - recipe list and detail;
  - meal plan Today and week, including the drag, tap and long-press;
  - settings, household and shopping list;
  - sign-in.
  Cards separate from the ground without a border in both brightnesses.
  The light recipe cards share the nav bar's colour, but the cream gap keeps
  them apart. **Still open:**
  - **Import review.** It needs a hosted AI import, which was skipped on
    purpose: its cards on `KitchenColors.card` and the flagged rows' tint
    and dashed dividers on that fill, in both brightnesses.
  - **The household invite card.** It only shows with an active code, and
    no code was created on hosted.
  - The Galaxy's own screen.

All open ones need the hosted release build: `make install-hosted` on
the Galaxy, or `make install-emulator` on the emulator for anything behind
sign-in that needs no Google account (`.claude/commands/design-walk.md`
§ 1). Never `flutter run`, never the local stack (CLAUDE.md). A future
session should close as many as it reasonably can in one sitting rather than
walking one loop at a time; 3b and 3c's second-account/throwaway-household
setup can close both together. The same throwaway household can close part
7's onboarding loop and part 8's owner side with them. Phase 7 parts 2, 3, 5, 6 and 7 all
walked on the device (2026-09-25/28) — release build, both languages, both brightnesses —
so the older loops are blocked on nothing but someone sitting down with the
phone. Phase 5 part 5's clipboard loop and Phase 6 1b's tag-minting loop are
the two that need an action taken rather than a screen read.

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
this reason; `household_screen.dart`'s rename dialog follows the same
precedent rather than disposing.

**A debug-signed and a release-signed APK can never overwrite each other
in place.** Switching from `make run-hosted` (debug) to a release install,
or back, always needs the other variant uninstalled first — `adb install -r`
alone fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`. Uninstalling clears
app data, so Google sign-in has to happen again afterward. `adb install` is
also ambiguous whenever the Android emulator is attached alongside the
physical device — install by serial, `adb -s <serial> install`.

**A slice with a migration needs `make db-push`, not just `make
db-reset`, before testing against hosted.** Phase 5 part 1's own
release-build walk hit it directly: migration 19 was applied locally and
the code shipped querying the new columns, but hosted was still on an
older migration, so the hosted recipe list 400'd with a generic "Nešto je
pošlo naopako." — no Dart stack trace reaches logcat in a release build, so
this took a direct `information_schema.columns` query against hosted to
diagnose. Phase 6 parts 3b and 3c both pushed their own migration in the
same slice that wrote it, closing the loop this note used to ask for.

**Driving a real device blind by pixel coordinates is unreliable —
`uiautomator dump` gives exact bounds instead.** `adb shell uiautomator
dump /sdcard/ui.xml` followed by `adb pull` and grepping `bounds="..."` off
`content-desc` attributes gives exact tap targets for any adb-driven
verification — Flutter's semantics tree exposes labeled, bounded elements
this way even though there's no native View hierarchy.

**Local sign-in requires a device that can hold a Google account.** The
Android emulator cannot add one at all — Google's device-integrity gating —
so it stays useful for UI work and useless for exercising sign-in. A
physical device's silent credential restore can sign in with no visible tap
at all, which is worth knowing when a screenshot shows the recipe list with
no sign-in step in between.

**Google-only sign-in means no App Store submission.** Guideline 4.8
requires an equivalent privacy-preserving login option; Apple sign-in was
dropped from the roadmap outright, not deferred. Personal signing and
TestFlight are unaffected.

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
