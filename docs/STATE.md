# State — 2026-10-13

**Branch:** `main`
**Last shipped:** Phase 9 slice C's fifth slice,
`phase9-household-leave-switch` (`7d6847b`), from the design round
`docs/design/handoffs/2026-10-13-multiple-households/` (§ D5, D174).
Leaving or deleting a household when you have others.

- **Dialog.** With two or more households, Leave / Delete name the
  household (`Napustiti „X“?` / `Obrisati „X“?`). When it is the current
  one, the dialog ends "You'll switch to Y." in `onSurface`, `md` below the
  body. Buttons stay `Napusti` / `Obriši`.
- **After.** It switches to Y (`switchTo`), goes to the Settings root, and
  shows "You left X. Now in Y." (or "Deleted X. …") with no Undo. A
  non-current household left through the list's gear gets the named dialog,
  no switch sentence, and you're back on the list.
- **Y** is the most recently used other household on this device:
  `HouseholdRepository.select` now keeps `recent_households.<userId>` in
  `DevicePreferences`, and the pure `nextHouseholdAfter` picks from it,
  else join order.
- **One household:** unchanged, the same dialog and the same path to
  onboarding.

`dart analyze` is clean, `flutter test` passes 1128/1128. `make check` is
green except the known `seed-check`.

**Hosted** needs nothing from this slice (no migration, no function). The
emulator runs this slice's release build; the Galaxy still runs slice 4's.

**Hosted test data** for the next slices' walks:
- the walk account (Galaxy) owns `Renamed Household` and `Porodica
  Stanković – vikendica` (current on the Galaxy);
- `test-user` (emulator) owns `Kod Mire` and is a member of `Renamed
  Household`. Current on the emulator: `Walk throwaway`.

**Still left for Marko to clean up**, from slice 4's walk (the session may
not delete or leave on hosted). These are also the confirming taps this
slice's walk still owes; see its loop below:
- `test-user` owns two throwaways, `Walk throwaway` and `Porodica Stankovic
  - vikendica`. Delete them.
- `test-user` joined the Galaxy's `Porodica Stanković – vikendica`. Leave
  it.
- Kod Mire's code `324272` is live. Revoke it.

`test-user` is in five households until then. Brought back to Kod Mire +
Renamed, it is the walk stand-in again; with Kod Mire alone, it is the
one-household account for this slice's check and slice 4's en "Another
home?" check.

Still open:
- the switch sheet's rows turn into a small spinner for a frame or two as
  it closes after a pick: `myHouseholds` reloads under it
  (`showHouseholdSwitchSheet`, D171). Seen on the switch-loading walk with
  a slowed network;
- during a switch, List's "Next list: …" line under the range segments is
  absent (it derives from the list), then appears with the data and nudges
  the card down a line;
- an offline cold start came up in Serbian chrome with the profile set to
  English (seen on the emulator, switch-loading walk). Not traced;
- in dark, the recipe list's empty state (`Još nema recepata.`) renders its
  second line large and bold, seen on the switcher walk in an empty
  household. Not from that slice, not traced;
- **a throwaway recipe on hosted**: `Setnja odeljci TEST`, saved by the
  `phase8-ingredient-sections-edit` editor walk (later walks' throwaways
  were soft-deleted). It wants deleting (the app's own soft delete), which
  is Marko's call;
- **the formatting toolbar's last adopter**: the translation review's
  editable fields are still raw text. `AppFormattableField`,
  `AppFormattingToolbar` and `RichTextEditingController` are in
  `core/widgets/` for it (D167);
- while the formatting toolbar shows, the editor's save bar and import
  review's action bar are out of reach. Saving means hiding the keyboard
  first (D166 Consequences, D167);
- a snackbar with Undo sits over the screen's bottom action bar (the
  editor's Sačuvaj; review's Sačuvaj recept / Odbaci). A tap meant for Undo
  that lands just after the 4 s auto-dismiss presses the button under it;
  the walk saved its throwaway twice that way. Step headings have the same
  layout. With the formatting toolbar up, the heading's Undo snackbar
  covers the toolbar instead;
- in import review, light only, about 4px of dark shows behind a dragged
  section's proxy at its rounded top-left corner when the drag starts on a
  long-press. The editor's proxy is clean. Cause not traced;
- **a junk global alias on hosted**: `seceraa → šećer`, written when the
  editor walk confirmed a pill on a typo (D8, D160). It wants removing from
  `ingredient_aliases`, which is Marko's call. Nothing in the app can unlink
  an alias;
- right after a recipe save, the detail's well shows the placeholder (or
  the previous photo) for about 8–15 s, until the signed detail arrives. The
  new path has never been cached and the first emission is unsigned. It was
  the same before part 2. Seeding the cache with the uploaded bytes on save
  would close it (D148 Consequences);
- while the offline banner shows, about 200px of empty space sits between
  it and the tab's app bar, in both brightnesses. The banner's `SafeArea`
  probably takes the status-bar inset while the `AppBar` below still pads
  for it. It is `AppShell` code, so every tab has it;
- in dark, the add-meal sheet's `RecipeCard`s take the sheet's own fill and
  lose their edge (the old picker did the same);
- the recipe list's add menu touches the screen's right edge (part 16's
  loop, below; re-checked 2026-10-05, still flush). The shopping
  long-press menu does the same near the edge;
- in dark, a menu over a card has almost no edge: `menuTheme`'s
  `surfaceContainerHigh` (`#292923`) equals the card fill and the shadow
  barely reads. Seen on the shopping long-press menu; a theme-level fix
  touches every menu;
- a failed link import shows the server's English sentence under `sr`
  (`That page could not be fetched.`), the stored `error_message`;
- the matcher matched `pilecih krilca` (wings) to `pileća prsa` (breast) on
  a hosted import. It was flagged, so review catches it, but the match is
  wrong;
- meal-plan recipe entries show the original-language title under `en`
  (the entry's own `recipeTitle`, D53);
- the signed-out sign-in screen stays Serbian after an in-app switch to
  English;
- tag chips show raw keys for a frame on a cold start, and **for the whole
  session offline** (`doručak`, `sweet`): the tag labels are not cached;
- the shopping list prints `1.5 kg` in Serbian;
- units don't inflect (`2 glavica`), and the long-press snackbar's
  `premešteno` doesn't agree with the noun's gender (`hleb premešteno`);
- the Serbian date-range picker header reads `28. sep to 4. okt`, with
  Material's English `to`;
- ingredient notes are not translated (`po ukusu` under English), and
  neither are ingredient section headings (`Za testo` under English). Both
  need ingredient lines sent to `translate-recipe`, which is a schema and
  function change (D156);
- the recipe-delete confirm is a filled button;
- the `List — offline`, `Review import`, `Household` and `Settings` frames
  in `docs/design/screens/` still show the old bordered card, until Claude
  Design updates them.

**In flight:** none.
**Next:** `phase9-import-save-to`: where an import is saved, with 2+
households (§ D6 of the round; `ROUND.md`'s last unticked slice), via
`/plan-slice-ui`. Its walk needs a real share intent, so the Galaxy.
Still open as candidates beside Phase 9:
- the formatting toolbar in the translation review, the last raw formatting
  surface. It is a small `/plan-slice-ui` on D167's pattern;
- Phase 8 part 4 (real thumbnails), which stays optional, "only if part 2 is
  not enough on the device";
- the smaller candidates still open from round `sync-design-initial`:
  - the offline banner gap (`AppShell`, every tab);
  - part 16's add-menu edge, fixed on its own (the shopping long-press
    menu's edge with it);
  - the dark menu-over-card edge (theme-level, wants a decision);
  - the recipe-delete confirm, the one filled destructive confirm left
    (§ Buttons says text in destructive).

The open device-walk loops below still want one sitting with the Galaxy
attached.
**Latest decision:** D174

**Twenty-two device-walk loops are open.** Phase 7 part 3's walk ran on the physical
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
re-walked in the same session, so it opened no loop. Part 14's walk
(2026-10-02, emulator, all four combinations) was clean, so it opened no
loop. The `phase7-sync-onboarding` walk (`/design-walk onboarding`,
2026-10-02, emulator, all four combinations) was clean and closed part 7's
onboarding loop. It opened its own loop for the two checks the emulator
cannot reach. Part 16's walk (`/design-walk recipes`, 2026-10-02, emulator, all four
combinations) found one defect, the add menu flush against the right edge,
so its loop stays open with that recorded.
Part 17's walk (`/design-walk recipe-detail`, 2026-10-02, emulator, all
four combinations) was clean on everything it reached, and it opened a loop
for the two checks no hosted data reached. Part 18's walk (the same
`/design-walk recipes` sitting) was clean on everything it reached, and it
opened a loop for the two checks it could not reach. Part 19's walk
(`/design-walk import`, 2026-10-02, emulator, all four combinations on the
entry screens) was clean on everything it reached, and it opened a loop for
the checks the emulator and a one-import quota budget could not reach.
Part 20's walk (`/design-walk import-review`, 2026-10-05, emulator, all four
combinations, one paste import) was clean and opened no loop. It closed
part 18's grip check, part 19's waiting-state check and part 10a's
import-review dash check, though each of those loops keeps other items. Part 21's walk (`/design-walk meal-plan`, 2026-10-05, emulator, all four
combinations) was clean and opened no loop. The `phase7-sync-shopping-list`
walk (`/design-walk shopping-list`, 2026-10-05, emulator, all four
combinations, online and offline) was clean on what it reached and closed
part 10a. It opened part 22's loop for the no-list state, which it could not
reach: the screen shows the household's latest list whatever range is
selected, and this household has one. Part 23's walk (`/design-walk settings`,
2026-10-05, emulator, all four combinations, with every segmented button
in the app) was clean and opened no loop. The `phase7-sync-household` walk
(`/design-walk household`, 2026-10-05, emulator, all four combinations,
adult account, one invite code minted and revoked) was clean and opened no
loop. The owner's Delete is covered by the widget test, as the slice
planned. No hosted member has a long enough name to test wrapping. Phase 8 part
2's walk (`/design-walk recipes`, 2026-10-05, emulator, all four
combinations, online, offline and a photo replaced) found one defect, the
pull's thumbnail flash, which was fixed and re-walked the same sitting, so
it opened no loop. It re-checked part 16's add menu (still flush). The
`phase8-shopping-row-markers` walk (`/design-walk shopping-list`,
2026-10-06, emulator, all four combinations) found two defects, both fixed
and re-walked the same sitting. It opened a loop for the two checks it could
not reach; the `phase8-shopping-long-press-menu` walk (the same day,
emulator, all four combinations) closed that loop's tooltip half and
opened its own for two findings it did not fix. The
`phase8-step-headings-notes` walk (`/design-walk recipe detail steps +
recipe editor steps`, 2026-10-06, emulator, all four combinations) was clean
on everything it reached, and opened a loop for the import-review check it
did not reach. The `phase8-recipe-end-note` walk (`/design-walk
recipe-detail`, 2026-10-06, emulator, all four combinations, with the
editor, import review and translation review) was clean on everything it
reached, and opened a loop for the source-footer check it did not reach.
The `phase8-ingredient-sections` walk (`/design-walk recipe-detail`,
2026-10-07, emulator, all four combinations) was clean on everything it
reached, and opened a loop for the wrapping check it did not reach.
The `phase8-ingredient-editor` walk (`/design-walk recipe-editor`,
2026-10-08, emulator, all four combinations) found three defects, all fixed
and re-walked the same sitting. It opened a loop for import review, which it
did not walk, and for the iOS Backspace check. The same day's
`/design-walk import-review` (emulator, all four combinations, one paste
import, discarded) was clean. It closed slice 7's wrapping-heading loop and
the import-review half of slice 8's.
The `phase8-ingredient-sections-edit` walks (`/design-walk recipe-editor`
and `/design-walk import-review`, 2026-10-08, emulator, all four
combinations, 360dp) found two defects, both fixed and re-walked the same
sitting, and opened no loop.
The `phase8-rich-text-render` walk (`/design-walk recipe-detail`, 2026-10-08,
emulator, all four combinations, with the translation review in en/light and
en/dark) was clean and opened no loop. It used a throwaway `Knedle WALK TEST`
recipe holding the canvas samples and a step whose numbered list reaches
`10.`. The recipe took one hosted translate call and was soft-deleted
afterwards. `adb input` cannot type `š`/`ž`, so its Serbian text is
ASCII-only.
The `phase8-rich-text-toolbar` walk (`/design-walk recipe-editor`,
2026-10-08, **physical Galaxy**, all four combinations) found one defect:
the toolbar never showed inside the shell. It was fixed and re-walked the
same sitting, so it opened no loop. The emulator can't reach this surface:
its Gboard floats and gives the app no keyboard inset. The Galaxy's Gboard
draws no composing underline in any field, so that check rests on the
controller test.
The `phase9-household-leave-switch` walk (`/design-walk household-leave`,
2026-10-13, emulator, all four combinations, every dialog cancelled) was
clean on everything it reached. It opened a loop for the confirming taps,
which the session may not run on hosted, and for the one-household check.
Oldest first:

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

- ~~**Phase 7 part 7**~~ — **closed by the `phase7-sync-onboarding` walk
  (2026-10-02).** The form vocabulary. Walked on the physical Galaxy
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
  ~~**Not walked:** the create / join household screens.~~ Walked
  2026-10-02 on the emulator after the `phase7-sync-onboarding` redesign:
  the join code's digits are sans now (D134), evenly spaced, tabular, and
  read as a code in light and dark.

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

- ~~**Phase 7 part 10a**~~ — **closed by the `phase7-sync-shopping-list`
  walk (2026-10-05).** Step timeline, dashed ingredient dividers
  (`phase7-part10a-step-timeline-dashed-dividers`). **Recipe detail is
  walked**, clean, on the **emulator** (2026-09-29) across `sr`/`en` ×
  light/dark. The dashes run edge to edge with none under the last
  ingredient. The step line stops short of each disc, stretches through the
  8-line Serbian step 5 of Palačinke, and is quiet but visible in dark. A
  single step (Kajgana) draws none. The unmatched ring reads as a different
  thing from the divider in both brightnesses. Nit: the dashes end ~3dp
  short of the right text edge.
  **Still open:**
  - ~~`/design-walk shopping-list`~~ — **confirmed 2026-10-05** (emulator,
    all four combinations): a dash under every to-buy row but the card's
    last (`fileta lososa`), and the `md` block gaps still read as breaks in
    one rhythm, quiet but visible in dark.
  - ~~`/design-walk import-review`~~ — **confirmed 2026-10-05** (emulator,
    the `phase7-sync-import-review` walk): the dashes start and end at the
    text (x 73–1005 against the amount's right edge at 1003, 1080px wide),
    while the flagged tint and marker reach the edge and meet them with no
    gap. The right-edge nit does not show here.

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
- **Phase 7 part 15** (`phase7-sync-onboarding`) — sign-in lockup + illustration, outlined
  Google button, top-aligned create / join. Walked on the **emulator**
  (2026-10-02, `make install-emulator`, dev-login account) across `sr`/`en`
  × light/dark. All right:
  - **Sign-in:** illustration, lockup and tagline centred; the Serbian
    tagline wraps evenly over two lines; the G and the lockup are crisp
    at 1080px. Dark, sampled off the screenshot: surface `#16160F`, no box
    behind the illustration or lockup, lockup text `#9ED498`, button fill
    `#101007` with a `#96978A` border, label legible. The signed-out screen
    stays Serbian after an in-app switch to English (D77), so en = sr there.
  - **Create / join:** the mark top-left; `Imenujte svoje domaćinstvo` and
    `Unesite svoj pozivni kod` fit on one line; `Napravi domaćinstvo umesto
    toga` fits on one line; the buttons are pinned at the bottom; the field
    label `Pozivni kod` / `Invite code` is there. A wrong code shows `Taj kod
    nije važeći.` in pink under the field, readable in dark. The real join
    worked three times (one invite code each, single-use).
  - Reached by leaving `Renamed Household` as `test-user` (a member) and
    rejoining by code each cycle; it ended back in, 2 members. The owner's
    active code `770578` was consumed by the first rejoin.

  **Not reached on the emulator:**
  - **Keyboard open.** The emulator's Gboard stays in its stylus toolbar
    and never opens the full keyboard. A widget test now covers it (300px
    inset, nothing overflows, the buttons scroll into reach), but the
    device check is still open.
  - **The Google button's busy spinner** on the new outlined button, and a
    real Google sign-in through it. Both need the Galaxy.
- **Phase 7 part 16** (`phase7-sync-recipe-list`) — app-bar add menu,
  carded empty state, always-on count. **Walked on the emulator**
  (`/design-walk recipes`, 2026-10-02, all four combinations). Everything
  below held **except one defect**: the add menu is flush against the
  screen's right edge in every combination. Its fill reaches the last pixel
  column (x=1079 of 1080), so it is not "clear of the right edge". The fix
  wants a non-default `alignmentOffset` (or a menu style with an end inset),
  then a re-walk of just the menu. **Re-checked 2026-10-05** (emulator,
  sr/light, the Phase 8 part 2 `/design-walk recipes` sitting): still flush,
  fill to x=1079, so the loop stays open. **Re-checked again 2026-10-06**
  (emulator, sr/light, sr/dark and en/light): still flush, fill to x=1079. Clean: the `+` long-press tooltip,
  `Fotografiši stranicu` on one line, four regular-weight rows, the menu not
  covering the `+`; `5 recepata` / `5 recipes`; Favorites + `Jednostavno`
  giving the carded panel with `Poništi filtere` (which cleared both); a
  query alone (`zzzq`) giving the panel with no button, visible on
  `#16160F`; the last card clearing the nav bar by exactly 24dp. The
  original checklist:
  - no FAB; the `+` at the app bar's end, long-press `Dodaj recept` /
    `Add a recipe`; the menu opens below it, fully on screen, clear of the
    right edge and not covering the `+` (`alignmentOffset` is at its
    default), four rows in regular weight, `Fotografiši stranicu` on one
    line;
  - `N recepata` / `N recipes` 16 under the chips with no filter on, the
    Serbian plural right on the real count;
  - Favorites + a tag that match nothing: the panel on a card just under
    the chips, visible against the cream and against `#16160F`, the body
    wrapping cleanly, `Poništi filtere` clearing the filters; a query alone
    gives the same panel with no button;
  - the last card clears the nav bar with 24 to spare.
- **Phase 7 part 17** (`phase7-sync-recipe-detail`) — opaque discs, tonal
  badge, servings trailer, one-line source. Walked on the **emulator**
  (2026-10-02) across sr/en × light/dark, and clean on everything reached
  (journal, part 17). Two Serbian-width checks remain, both blocked on data
  rather than on a device:
  - `Uvezeno sa fotografije · …` on one line or wrapping cleanly. It needs
    an OCR (photo) import on hosted;
  - `Mašinski prevod` in the tonal badge. It needs a recipe written in
    English and machine-translated into Serbian.
- **Phase 7 part 18** (`phase7-sync-recipe-edit`) — one grip, the photo
  well, labelled steps, the ringed original panel. Walked on the
  **emulator** (2026-10-02) across sr/en × light/dark, and clean on
  everything reached (journal, part 18). One check remains:
  - the translation review in Serbian chrome: `Mašinski prevod` on one line
    in its badge and `Original (engleski)` in the panel. Same data gap as
    part 17: it needs a recipe written in English and machine-translated
    into Serbian (one hosted AI call);
  - ~~the import review's line editor showing the new grip~~ — **confirmed
    2026-10-05** (emulator, the `phase7-sync-import-review` walk): an open
    line shows the `drag_indicator` grip left of the field.
- **Phase 7 part 19** (`phase7-sync-import-capture`) — inline Read on the
  import entry screens, the square photo well with the tonal pair, the
  waiting state's no-confirm Discard. Walked on the **emulator** (2026-10-02,
  about 411dp wide): link, paste and photo (empty and filled with a portrait
  page) were clean across sr/en × light/dark. The well's `outline` icon
  measured about 4.2:1 on `surfaceContainerHighest` in both brightnesses.
  One paste import (en/dark) was discarded while it read. It landed on the
  recipe list, and the job had not come back after the read would have
  finished and the app was restarted. Two checks remain:
  - **with a docked keyboard**, `Pročitaj ovaj recept` above it or one
    scroll away on link and paste. The emulator's Gboard only floats over
    the app and never resizes it, so this needs the Galaxy;
  - **the photo screen at 360dp**: Read on screen without scrolling after a
    pick. The emulator is wider, so this also needs the Galaxy;
  - ~~**the waiting state's pixels**~~ — **confirmed 2026-10-05**
    (emulator, sr/light, a paste import in the `phase7-sync-import-review`
    walk): the spinner's arc on its `surfaceContainerHighest` track, `U redu
    čekanja...` in `titleMedium` with the `bodyMedium` hint, and the outlined
    `Odbaci ovaj uvoz` pinned above the nav bar under a hairline.
- **Phase 7 part 22** (`phase7-sync-shopping-list`) — the carded no-list
  state. The list itself walked clean on the **emulator** (2026-10-05, all
  four combinations, online and offline). **Still open:** the no-list state
  on a device, which only a household that has never generated a list
  shows (the screen shows the latest list whatever range is selected). Check
  that the panel reads as a region in both brightnesses (in dark, `#292923`
  on `#16160F`), that `Još nema liste.` and its body wrap cleanly, that
  `Napravi listu` is a mustard-cream tonal pill, not a green one, and
  whether the 24dp gap above the panel looks off next to the 16dp above a
  real list. The throwaway household that 3c needs can close this too.
- **Phase 8 part 1** (`phase8-part1`) — pull and long-press regenerate.
  Walked on the **emulator** (`/design-walk shopping-list`, 2026-10-05, all
  four combinations, online and offline). Everything the slice asked for
  holds: a pull regenerates (`Generisano …` updates), a pull with `Sledeća`
  makes next week's list, a pull on the nothing-to-buy body works, a
  long-press moves an item into `Verovatno imate` and back with the new
  snackbars, a long-press keeps the list's own week and language in both
  directions (Serbian list under English chrome with `Next` selected;
  English list under Serbian chrome with `Ova nedelja` selected), and
  offline a pull (~5 s) and a long-press (at once) each show `No
  connection.` with the saved list left on screen. Phone dark + app
  `Svetla` stays light. **Defect found and fixed the same sitting:** a
  long-press blanked the list for a moment (the bump reloads
  `currentShoppingListProvider`, and `loading:` rendered
  `SizedBox.shrink()`), and it came back scrolled to the top, so a
  long-press in `Verovatno imate` lost the cook's place. Fixed with
  `skipLoadingOnReload: true` on the screen's `when` (the list stays up,
  the progress bar shows the work), pinned by a widget test that fails
  without it. Re-walked on the emulator (sr/light): a long-press inside
  the expanded staples and one mid-way down the to-buy card each kept the
  scroll position and the expanded section, with no blank frame in ~16
  samples. **Still open, the one thing not reached:** the
  empty no-list state's pull on a device (this household always has a
  list; part 22's throwaway household can close it). Side notes, not this
  slice's: `hleb premešteno` / `jaje premešteno` uses a neuter participle
  whatever the noun's gender (the old `označeno` string did the same); the
  Serbian date-range picker header reads `28. sep to 4. okt` with an
  English `to` (Material's own localization). The walk left `alwaysHave`
  overrides on hleb, bread, jaje and voda in the walk household, which
  render the same as their defaults.
- **Phase 8 part 3** (`phase8-part3`) — refresh on tab switch. **Partly
  walked on the emulator** (`/design-walk recipes`, 2026-10-06, all four
  combinations on the recipe list, online and offline). Confirmed:
  - Recipes → Plan → Recipes, in sr/light and sr/dark: in rapid screencaps
    right after the tap, the list stays on screen with no blank or spinner
    frame;
  - with Kajgana's detail open, re-tapping `Recepti` pops to the list root;
  - in airplane mode, Recipes → Lista → Recipes and Plan → Recipes keep the
    cached list and shopping list, with the banner on every tab.

  **Still open, the one thing it exists for:** a change made *outside* the
  device (a second account or the Supabase dashboard), seen after a switch
  away and back, on Recipes, Plan, List and Settings' member count. The walk
  had no outside writer: only the emulator was attached, and pulling the
  hosted service-role key for a REST edit was refused by the session's
  permission check. Make the edit by hand, or walk it on the Galaxy with
  the emulator as the second device.

  **Seen, not part 3's:** going offline *while a photo detail is open*
  leaves the status-bar icons white on the cream banner. The detail's light
  style is right over the photo, but the banner pushes the photo down and
  nothing re-asserts the style. It sticks across tab switches (Lista showed
  it too) until a screen with its own app bar at the top resets it. Opening
  a detail while already offline is fine (dark icons). The offline
  banner's gap above the app bar (STATE's list above) showed on every tab,
  as known.
- **Phase 8 round 2 slice 2** (`phase8-shopping-row-markers`) — stacked
  amounts, staple pin, `Not added up`, long-press hint. Walked on the
  **emulator** (`/design-walk shopping-list`, 2026-10-06, all four
  combinations, on the walk household's existing `sr` list for 28 Sep – 4
  Oct; no regeneration, no long-press). **Clean:**
  - `brašno` `500 g` / `+ 25 ml` stacks right-aligned in one column, with a
    muted `+`. The name column is not squeezed, and it is readable in dark;
  - `Nije sabrano` / `Not added up` sits under each unmatched item in the
    **reader's** locale (English under an `sr` list, as designed). It is
    muted, never red, and readable in dark;
  - the `Verovatno imate` subline is `Dugo pritisnite stavku da je
    premestite ovde.` collapsed and `… vratite na listu.` expanded. Each
    fits on one line in Serbian with no ellipsis. Under English chrome the
    English hints appear while the heading stays `Verovatno imate (5)`;
  - all five Probably-have rows carry the `outline` pin, readable on the
    dark card fill;
  - recipe detail ingredient rows are unchanged (en/dark spot check).
    Import review was not reached.

  **Two defects found, both fixed in the slice before close and re-walked
  the same sitting** (emulator, sr/light, sr/light expanded, en/dark, and en/dark
  recipe detail):
  - *A marker stranded alone on a line.* The ring under `1 manji koren
    peršuna … preporučujem)` sat by itself on a fourth line. The U+2060 word
    joiner does not stop Flutter breaking before a placeholder that
    overflows. This was older than the slice, but the new pin copied the
    same glue. `IngredientLineRow` now measures the name's last line and,
    if the markers won't fit, moves the last word down with them.
    Re-walked: `preporučujem) ◌` on one line, in both brightnesses;
    recipe detail is unchanged.
  - *`Nije sabrano` beside an amount* on that same unmatched item
    (`1.67 kom`). The trailer now shows only when the item has no amount.
    Re-walked: the item shows `1.67 kom` and the ring, with no trailer.

  **Tooltip confirmed** by the `phase8-shopping-long-press-menu` walk
  (2026-10-06, emulator, sr/light only): a long-press on the pin itself shows
  `Uvek u Verovatno imate` and opens no menu (the tooltip wins the gesture).
  **Still open:** import review, which renders the same row and so the new
  last-word measurement. Widget tests cover the row there; it has not been
  seen on a device.
- **Phase 8 round 2 slice 3** (`phase8-shopping-long-press-menu`) — the
  long-press "Always" menu with Undo. Walked on the **emulator**
  (`/design-walk shopping-list`, 2026-10-06, all four combinations, on the
  walk household's `sr` list for 5–11 Oct, moving `mleko` back and forth).
  **Clean:**
  - a long-press on a to-buy row opens `Uvek u Verovatno imate` / `Always in
    Probably have` at the finger; on a Probably-have row (card expanded)
    `Uvek na listi` / `Always on the list`. Near the bottom it opens
    upward. Each item is one line in Serbian;
  - the pressed row takes the fill, light `#E8DED3` / dark `#34342E`
    (measured), reaching 12dp past the text on each side, radius 8; rows do
    not shift. A tap outside closes the menu, clears the fill, and does not
    reach the row underneath;
  - picking moves the row (D147). The snackbar keeps its text and carries
    `Poništi` / `Undo` in `inversePrimary` (light green on the dark bar in
    light, dark green on the light bar in dark). Undo moves it back with no
    second snackbar, in all four combinations, and the expanded card stays
    expanded;
  - offline (sr/dark): `Nema veze sa internetom.`, nothing moved, no Undo.

  **Still open (two findings, not fixed):**
  - *The menu is flush with the screen's right edge* when the press is
    near it (bounds end at x=1080). It is the same thing as part 16's add
    menu; the slice said to note it, not to widen scope.
  - *In dark, the menu has no visible edge over a card.* `menuTheme`'s
    `surfaceContainerHigh` is `#292923`, the same as the card fill, and a
    level-2 shadow barely reads on a dark surface, so only the dashed
    dividers it covers show where it ends. Legible, but weak. In light the
    two are close too (`#EFE5DA` on `#F5EBDF`) but the shadow carries it.
    A fix is theme-level (the menu's fill or an outline), so it touches
    every menu; it wants a decision, not a call-site style.
- **Phase 8 round 2 slice 5** (`phase8-step-headings-notes`) — step
  headings and notes on detail and in the editor. Walked on the
  **emulator** (2026-10-06, all four combinations, hosted release build), on
  a new walk recipe `Pita proba koraka` (leading heading, two groups, two
  notes; one wraps two lines). `adb input text` cannot type č/ć/š/ž, so the
  walk's step text is ASCII Serbian. **Clean:**
  - an existing step-only recipe (`Domaći čorbasti pasulj…`) is unchanged:
    the disc-to-disc spacing (210/357/210/357/210 px) matches a screenshot of
    the previous build exactly, and the crops differ only in sub-pixel
    anti-aliasing;
  - numbering runs 1–3 under `Za testo` and 4–5 under `Fil`; the line breaks
    at `Fil` and runs unbroken through the first note into step 3; the last
    note's line stops level with its panel. `Za testo`, first, sits right
    under `Koraci`; `Fil` sits ~32dp below step 3, flush with the discs;
  - dark: the note text on its panel measured 9.4:1. The panel against the
    page is 1.24:1, the same step every dark card uses;
  - editor labels read `Korak 1`, `Korak 2`, `Beleška`, `Korak 3`, `Naslov`,
    `Korak 4…` (en: `Step N` / `Heading` / `Note`). At 411dp the Serbian add
    row fits one line; at 360dp (`wm size 945x2424`) `Beleška` wraps cleanly
    under `Korak`, with no overflow;
  - a dragged row lifts with a visible edge in both themes, and the drop gap
    opens where it lands; reorder works up and down;
  - removing `Fil` shows `Naslov je uklonjen.` / `Poništi`, and Undo puts it
    back between step 3 and step 4.

  **Still open:**
  - *Import review* (Method subline counting steps only; heading/note
    prefix icons) was not reached: it needs an import of a URL whose JSON-LD
    carries `HowToSection`, which this walk did not run against hosted.
    The widget test covers both behaviours.

  **Noted, not defects:**
  - the lifted row has no top padding, so its label sits about 4dp under
    the card's top edge;
  - the snackbar sits over the Save button. A tap meant for `Poništi` that
    lands after the 4s dismissal saves the recipe instead. The walk did that
    once by accident.

  `mleko` ended on the to-buy list as it began, but now with a household
  `always_have = false` override where it may have had none (D152's Undo
  semantics; no difference to the list).
- **Phase 8 round 2 slice 6** (`phase8-recipe-end-note`) — the end note on
  detail, in the editor, in import review and in translation review.
  Walked on the **emulator** (2026-10-06, all four combinations, hosted
  release build). A seven-line note with `- ` and `**` markers was added to
  `Pita proba koraka`. That recipe was then machine-translated (one hosted AI
  call), and one paste import made the new recipe `Palacinke`, which is still
  in the household. **Clean:**
  - detail: with no note, `Pita proba koraka` ends at its last note panel,
    exactly as before. With a note, the card is full width (gutter to
    gutter) and sits 84px (32dp) below the last row. In dark the card fill
    separates from the ground, and the `edit_note` icon and body read.
    Markers show literally, as expected;
  - under `en` the card shows the translated note. An edit made in
    translation review (`… Enjoy!`) is what detail shows after Save and
    approve;
  - editor: the `Napomena` heading, then the field, then the helper
    `Neobavezno. Serviranje, čuvanje, varijacije, saveti.` on one line at
    411dp. The field grew from 3 to 7 lines while typing. The note persists
    on reopen. Clearing it and saving removed the card from detail;
  - import review: the paste's `Napomena:` section was parsed into the
    note. The card sits 31px (12dp) below Method and collapses to the first
    words with an ellipsis. It expands in place to one field. Clearing the
    field shows `Nije pronađena`, which reads naturally under `Napomena`,
    and the subline follows typing. The saved recipe's detail carries the
    note;
  - translation review: the `Notes` pair follows the last step pair, in
    both themes.

  **Still open:**
  - the end note above a **source footer** was not seen. Both walk recipes
    are manual or pasted without a source. It needs a URL import, or a
    recipe with an attribution. The footer's own spacing code is unchanged.

  **Not seen on device (covered by the widget test):** translation review
  for a recipe without a note, where no pair should appear.
- ~~**Phase 8 round 2 slice 7**~~ (`phase8-ingredient-sections`) — **closed
  by the `phase8-ingredient-editor` import-review walk (2026-10-08)**, where
  a 63-character section heading wrapped cleanly onto two lines (below).
  Ingredient section headings on recipe detail, and `_StepHeadingRow` generalised to
  `_GroupHeading`. Walked on the **emulator** (2026-10-07, all four
  combinations, hosted release build). One paste import (one hosted AI call)
  made `Proja sa sirom i pavlakom`, with `Za testo` / `Za fil` / `Za preliv
  od kiselog mleka i belog luka` sections. It is still in the household.
  **Clean:**
  - headings read as green `titleSmall`. Measured ink gaps at 2.625 px/dp:
    about 23dp from a heading to its first line, about 49dp from the group
    above, and about 22dp from `Sastojci` to the first heading. Allowing for
    line-box leading, these match the planned 4+8, 24+8 and 8+4;
  - no divider under the last line of each section or of the list;
  - `Kajgana` (a flat list) looks exactly as before: no heading, and only
    its last line drops the divider;
  - contrast of `primary` on the surface: 6.05:1 in light and 10.66:1 in
    dark;
  - under `en` the headings stay Serbian (`Za testo`), as the slice
    accepted. The rows show catalog English;
  - `Pita proba koraka`'s step headings are unchanged after the refactor:
    the first sits flush under `Koraci`, and `Fil` measures about 37dp of
    ink above and 17dp below (the planned 32 and 12);
  - with the phone in night mode the app stayed `Svetla`.

  **Still open:**
  - a section heading that **wraps** was not seen. `Za preliv od kiselog
    mleka i belog luka` (39 characters) fits on one line at 411dp. The
    editor cannot set sections yet, so this needs a longer name from a
    paste import, or `phase8-ingredient-editor`'s walk. The heading is a
    plain `Text` with no `maxLines`. The `phase8-ingredient-editor` walk
    (2026-10-08) did not reach it either: in the editor, indented past the
    grip, the same 39-character heading still fits on one line at 411dp.
    **Seen 2026-10-08** in import review: `Za premaz od jajeta, mleka i
    susama koji se stavlja pre pecenja:` (63 characters) wraps at a word onto
    two lines, flush with the inset row text, with the heading gaps intact,
    in all four combinations. Heading contrast in dark is 10.66:1.
- **Phase 8 round 2 slice 8** (`phase8-ingredient-editor`) — ingredient lines
  as rows, one open line with a live preview, fast entry and the suggestion
  pill. The recipe editor was walked on the **emulator** (2026-10-08, all four
  combinations, hosted release build) on `Proja sa sirom i pavlakom`. Nothing
  was saved.
  **Found and fixed the same sitting** (each re-walked):
  - the open line drew a second focus ring inside its box, with about 40dp of
    gap above the preview. `InputDecoration.collapsed` sets only `border`, so
    the theme's `focusedBorder` and 52dp `constraints` came through. The field
    is now bare;
  - a search that went out during a typing pause (`secera`) auto-accepted
    onto a line whose name had since changed. This came from the old field's
    logic, unchanged. A test then showed the late answer could also write the
    older text back over newer keystrokes. Auto-accept now requires the
    controller's current text and parsed name to match the query;
  - the preview wrapped `· No` / `match` across lines. Status words and the
    `·` after each separator now use non-breaking spaces.
  **Clean:**
  - a saved recipe opens with every line a closed row and section headings
    indented to the text. Each group's last line drops its divider;
  - a tap opens the box with the keyboard up. The preview updates as you type
    (`→ brašno · prosejano   2 šolja`);
  - Next three times types three lines, each inserted under the last and in
    its section, with the keyboard staying up. Next on the blank fourth line
    removes it and closes the keyboard;
  - Backspace on an empty line with the **Android soft keyboard's own** key
    removes it and opens the line above, caret at the end. Repeated, it
    chains up through lines;
  - the pill on open and closed rows: `šećer?` + `Dodirni za potvrdu` on one
    line at 411dp. Tapping it matched the line and the pill went away. The
    preview opens the picker (`Koji sastojak je „seceraa”?`);
  - contrast: the pill is 7.63:1 in dark (`#5B4300` / `#FFE5B9`) and 12.0:1
    in light, the preview is 8.0:1 in dark, and the hint is 11.6:1 in dark;
  - `en`: chrome follows the reader (`Tap to confirm`, `· No match`), while
    catalog names and units stay Serbian (D86);
  - a new recipe's only blank line renders open and unfocused, with no
    keyboard.

  **Side effect on hosted:** confirming the pill on the typo `seceraa` wrote
  a global alias `seceraa → šećer` (D8, by design). A second `seceraa` line
  then auto-accepted. It is junk in the shared catalog and wants removing.

  **Import review, walked 2026-10-08** (emulator, all four combinations).
  One paste import (one hosted AI call), `Pogaca sa susamom`, was
  **discarded**, with no pill confirmed and no alias written. **Clean:**
  - read-only inset rows with `→ catalog` trailers and no `Done` anywhere.
    The long section heading wraps cleanly (slice 7's check);
  - a line changed to `susammm` closes as an unmatched row: dashed ring
    (6.13:1 in dark), `Nije povezano sa sastojkom` / `Not matched to an
    ingredient` (11.64:1 in dark), and the `susam?` pill inset `md` with
    `Dodirni za potvrdu` / `Tap to confirm`. At the list's end the row has no
    divider;
  - long-press drag still works (`kurkume` moved above `jaje`, and the
    heading moved with the new first line). The lifted row looks right;
  - Next on an open line opens a blank one, and Next on that closes it and
    the keyboard;
  - with the phone in night mode the app stayed `Svetla`.

  **Still open:**
  - the **flagged** tint and 3px marker under the new list: this import
    matched 8 of 8, all auto-accepted, so nothing was flagged. The row
    widget is unchanged (`IngredientLineRow`), so the risk is low;
  - Backspace on an empty line on **iOS** (unverified, no device).
- ~~**Phase 9** (`phase9-household-list`)~~ — **closed 2026-10-13.** The
  Households list and the id-scoped Household screen, walked on the
  **Galaxy** (all four combinations, hosted release build) with two hosted
  households seeded by hand for the walk account (`Porodica Stanković –
  vikendica`, owner; `Kod Mire`, adult, owned by `test-user` -- since left on
  the walk). **Found and fixed the same sitting** (re-walked): the list came
  back newest-first, because `postgrest-dart`'s `.order()` defaults to
  **descending**; `fetchMembershipRows` now passes `ascending: true`.
  Everything else clean: one-household Settings unchanged; `Domaćinstva` /
  `2 člana · još 2 domaćinstva`; long names wrap, never ellipsized; join
  order, `primary` radio, the 32dp hairline `#494A3F` on `#292923` in dark;
  a tap switches and Recipes follows; each gear opens that household with
  the right role (Delete / Leave); leaving the non-current `Kod Mire`
  landed on the list one row shorter, and Settings then read `1 more
  household`. The leave needed slice B's migration
  `20261013120000_household_rpcs_take_a_household.sql`, which was **not on
  hosted** until this walk (pushed 2026-10-13).
  The same `.order()` default had also made `fetchMineRows` -- D169's
  "oldest first" fallback -- pick the **newest** household when the device
  has no selection (after the seed, the walk account landed in
  `vikendica`), and `fetchMembers` list members newest-first. Both
  pre-existing; fixed in this slice too (`ascending: true`), after the walk.
  Member order re-checked on the Galaxy (Renamed Household: the owner now
  above `test-user`). The fallback is not re-walked: it only shows on a
  device with no saved selection, and the Galaxy has one now.

- ~~**Phase 9** (`phase9-household-switcher`)~~ — **closed 2026-10-13.**
  The tab header and switch sheet, walked on the **Galaxy** (all four
  combinations, hosted release build). **Found and fixed the same sitting**
  (re-walked):
  - with 2+ households the title rendered in `bodyMedium`, because
    `Material` resets `DefaultTextStyle`;
  - `Now in X.` never auto-dismissed (a `SnackBar` with an action persists
    by default) and covered the next sheet's Manage row.
  Clean after the fixes:
  - the header on all three tabs, and the sheet in both brightnesses;
  - the two-line Serbian snackbar; Undo with no second snackbar;
  - Manage → Domaćinstva;
  - a recipe detail reset to the Recipes root after a switch from List's
    sheet and from the Domaćinstva list;
  - the offline fallback is the plain title at x 16.
  Not reached: the long name beside List's two actions (vikendica has no
  list; the widget test covers it), and a real one-household account
  (`test-user` is in two now).

- **Phase 9** (`phase9-household-create-join-another`) — walked 2026-10-13
  on the **emulator** (`test-user`, all four combinations) with the Galaxy
  minting codes and taking the keyboard check; hosted release build.
  **Found, not this slice's code:** hosted Edge Functions were still slice
  A's (deployed 07:24 UTC, before slice B's `48728cf`), so a fresh join
  answered `409 already_in_household` and the form showed `Nešto je pošlo
  naopako.` Fixed by `make functions-deploy` the same sitting
  (`redeem-invite` v5, `create-invite` v3); the join then worked.
  Clean on everything reached:
  - one household (sr light/dark): "Još jedan dom?" between the invite
    button and the hairline, body on one line; absent with two; Settings
    unchanged;
  - the list's two footer rows, one hairline, in all four;
  - both forms: ✕, no mark, the sr titles wrap to two lines, en fits on
    one, the body names the current household; ✕ pops to the list;
  - create lands on Recipes in the new household; `Sada ste u domaćinstvu
    „…“.` + Pozovite (sr dark), `Now in Walk throwaway.` + Invite (en
    light), and Invite opens Settings › its screen; Settings afterwards is
    the list with the new radio, never a form;
  - join: the already-a-member panel in all four (card fill, 16 `info`,
    never red); Gotovo pops without switching; Pređite / Switch to X lands
    with Undo, and Undo switches back; a fresh join (code from the Galaxy)
    lands with Poništi; Unesite drugi kod clears;
  - Galaxy, real keyboard, a name longer than the slice's: no overflow, the
    button sits above the keyboard.
  Not reached:
  - the en "Another home?" card. `test-user` is in five households now, and
    reducing it needs deletes and leaves, which the session may not run on
    hosted;
  - onboarding unchanged on a device (needs an account with no household;
    the widget test covers mark and cross-link).
  **Hosted data left by the walk, for Marko to clean up:** `test-user` owns
  `Walk throwaway` and `Porodica Stankovic - vikendica` (both throwaway,
  delete them), and joined the Galaxy's `Porodica Stanković – vikendica`
  (leave it). One more throwaway was deleted during the walk. The Galaxy's
  `950420` and `793155` are spent; `324272` (Kod Mire) is still live, revoke it.

- **Phase 9** (`phase9-household-leave-switch`) — walked 2026-10-13 on the
  **emulator** (`test-user`, five households, all four combinations, hosted
  release build). Every dialog was opened and cancelled; nothing was left or
  deleted. Clean on everything reached:
  - recency: switched to the Galaxy's `Porodica Stanković – vikendica`
    (B), then to `Porodica Stankovic - vikendica` (C). C's Delete named
    B, not `Kod Mire` (first in join order). Then switched to B: B's
    Leave named C;
  - the named titles wrap to two lines in sr and en, and in the longest
    one (`Napustiti „Porodica Stanković – vikendica“?`) the body and
    the switch sentence fit without scrolling;
  - the switch sentence is darker than the body in light (≈`#1F190F` vs
    `#484134`) and brighter in dark (≈`#EBEBE4` vs `#CFD0C2`), in sr and
    en; the destructive verb (`Obriši` / `Napusti`) reads in both;
  - non-current through the gear (`Renamed Household`): named title, no
    switch sentence;
  - Cancel leaves the current household unchanged.
  Cosmetic, not a defect: C's own name, `Porodica Stankovic - vikendica`,
  breaks at its hyphen, so the sr title's second line starts
  `- vikendica“?`. That's the name's own ASCII hyphen.
  Not reached (Marko's confirming taps, which double as the STATE.md
  cleanup above):
  - after confirming: the Settings root, the household row showing the
    named household, the snackbar with no action, and no flash of the left
    household's spinner or `noHouseholdYet` during the switch (if there is
    one, move `go` before `switchTo` in `household_screen.dart`'s `_go`);
  - leaving a non-current one through the gear: back on the list, current
    unchanged;
  - the one-household check: today's dialog exactly, then onboarding.
    `test-user` is in five households; once it's back to one it serves.

All open ones need the hosted release build: `make install-hosted` on
the Galaxy, or `make install-emulator` on the emulator for anything behind
sign-in that needs no Google account (`.claude/commands/design-walk.md`
§ 1). Never `flutter run`, never the local stack (CLAUDE.md). A future
session should close as many as it reasonably can in one sitting rather than
walking one loop at a time; 3b and 3c's second-account/throwaway-household
setup can close both together. The same throwaway household can close part
7's onboarding loop, part 8's owner side and part 22's no-list state with them. Phase 7 parts 2, 3, 5, 6 and 7 all
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
