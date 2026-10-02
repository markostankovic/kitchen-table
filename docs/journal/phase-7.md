# Journal — Phase 7

Verbatim build history for Phase 7 — Redesign — moved out of `docs/ROADMAP.md` so the roadmap stays a forward-looking index. Nothing here is authoritative going forward -- see `docs/decisions/` for standing rules, `docs/STATE.md` for current status.

---

## Phase 7 — Redesign

### Part 1 — The design foundation

**Status: complete** (`e61e9a8`). Decisions taken during it: D117.

Phase 0's whole visual language was one seed colour handed to
`ColorScheme.fromSeed` and nothing else -- no role was ever chosen
deliberately, and `lib/core/widgets/` held a single file,
`placeholder_screen.dart`. This slice kept the seed (`0xFF7A5C3E`, the same
warm brown) and the platform font, but made the roles the app actually reads
explicit, wrote the result into `docs/DESIGN.md`, and extracted the first
three genuinely generic shared widgets.

- **`app_theme.dart`** now builds each brightness's `ThemeData` from an
  explicit `ColorScheme` (seven roles documented in `docs/DESIGN.md` § Colour:
  `primary`/`onPrimary`, `error`/`errorContainer`/`onErrorContainer`,
  `tertiary`/`onTertiary`, `outline`, `onSurfaceVariant`,
  `surfaceContainerHighest`, `secondaryContainer`), an explicit `TextTheme`
  (eight named roles, § Type), and five component themes that earned it —
  `AppBarTheme`, `ChipThemeData`, `FilledButtonThemeData`,
  `ListTileThemeData`, `InputDecorationTheme` — picked because each is used
  across enough screens to be worth setting once rather than per call site
  (D117). `CardTheme` was considered and dropped: exactly one `Card` exists
  in the app today, not enough to earn a theme.
- **D117** (this slice): `fromSeed`'s own generated dark-mode `tertiary` sat
  too close in tone to the generated dark `secondary` to read at the 3px
  border width `import_review_screen.dart` draws its "needs attention"
  marker at, so dark mode pins `tertiary`/`onTertiary` explicitly
  (`0xFFE7C17E` / `0xFF422C00`); light mode keeps the generated value.
- **`app_spacing.dart`** (new) names the spacing scale that was already the
  de-facto one in the codebase — 4/8/12/16/24/32 as `AppSpacing.xs` through
  `AppSpacing.xxl` — rather than inventing new numbers. Applied only to the
  three new widgets and the files this slice already opened; the rest of the
  app migrates as later per-surface parts touch those screens (scope fence
  agreed in planning, to keep the diff reviewable).
- **Three widgets in `lib/core/widgets/`** (new): `AppErrorView` (a
  centered, already-localized error message — D92's `localizedErrorMessage`
  stays the caller's job, never done inside `core/widgets/`) replaces eight
  hand-written `Center(Padding(Text))` call sites plus two judgement-call
  sites (`recipe_detail_screen.dart`'s concatenated "could not load" message,
  `translation_review_screen.dart`) where the swap was clean;
  `AppSectionHeading` replaces two duplicate private `_SectionHeading`
  classes, `household_screen.dart`'s `_sectionHeader()` helper, and two
  inline headings in `import_review_screen.dart`; `AppEmptyState`
  (icon/title/optional body/optional action, built scrollable so it still
  works as an `AsyncValue.when`'s `data` case inside a `RefreshIndicator`)
  replaces both disagreeing `_EmptyState` classes
  (`shopping_list_screen.dart`'s fuller icon+title+body+button shape became
  the design; `recipe_list_screen.dart`'s text-only one gained an icon).
  All five duplicate private classes/helpers are deleted, not left
  alongside.
- **`docs/DESIGN.md`** — the Colour, Type and Spacing sections (previously
  all "**Not yet decided.**") are filled in to match the code exactly, and
  Components gained a paragraph naming the three new widgets. The
  `core/widgets/` (generic) vs. `core/<feature>/widgets/` (shared but
  feature-shaped, D43/D53's precedent) line was re-stated, not re-litigated.

This was deliberately **not** a screen-by-screen restyle — the only screen
edits are the shared-widget call-site swaps plus whatever the theme itself
changed. Per-surface redesign is later Phase 7 parts.

**How it was verified.** `dart analyze` — clean. `flutter test` — 584/584
green (576 before this slice, plus 8 new: `app_error_view_test.dart`,
`app_section_heading_test.dart`, `app_empty_state_test.dart`,
`app_theme_test.dart`, the last asserting both brightnesses build, the
roles this slice decided are actually set rather than left to `fromSeed`,
and light/dark differ where they should). `dart run tool/check_layers.dart`
— OK. `l10n-check` — green; no ARB keys were added. `make check` was not run
against hosted or the local Supabase stack, since this slice touches
nothing under `data/`, no migration, no Edge Function — `pubspec.yaml` is
also unchanged (no new package, per CLAUDE.md rule 8, asked and declined in
planning). The one pre-existing `seed-check` failure (`c8be2bc`,
`docs/STATE.md`) is unrelated and untouched.

**The device walk did not happen.** Only an Android emulator was available
in the session that built this slice — no physical Galaxy device was
attached, and CLAUDE.md's "running the app" means a release build on the
physical device specifically, not the emulator. None of this slice's own
`sr`/`en` × light/dark walk across the six main screens ran, and none of
the seven older device-walk loops this slice's plan had agreed to fold in
(P5 p5, P5 p6, P6 p1a, P6 p1b, P6 p2, P6 p3b, P6 p3c) closed. All eight
loops stay open in `docs/STATE.md`.

---

### Part 2 — The Garden tokens

**Status: complete** (`b74552c`). Decisions taken during it: D118.

Part 1 made the roles deliberate but kept Phase 0's seed. This slice deletes
the seed. Both `ColorScheme`s are now written out in full from the Claude
Design export in `docs/design/`, Literata is bundled and carries everything a
person reads, and the app gains its first `ThemeExtension`. Deliberately a
repaint and nothing else: **not one screen file under `lib/features/**` was
edited**, so that if a colour or a size made something unreadable it showed up
here rather than five slices later.

- **`app_theme.dart`** — `_seed` and both `fromSeed` calls are gone.
  `_colorScheme(Brightness)` returns one of two `const ColorScheme` values,
  every role explicit, light and dark designed as a pair rather than derived
  from one another. `surfaceTint` is `Colors.transparent` in both, which is
  what kills Material's elevation tint app-wide in one place. The five
  component themes became seventeen, all on the `…ThemeData` names Flutter
  3.47 wants (Part 1's `AppBarTheme(...)` and `InputDecorationTheme(...)` —
  the widget classes — were switched over while they were being rewritten).
  The `NavigationBarThemeData` is the one that is *not* Material's default:
  M3 gives the indicator `secondaryContainer`, the design wants a `primary`
  pill with the icon knocked out in `onPrimary`.
- **Type** — Literata (weights 400 and 600) for the wordmark, titles, recipe
  steps and ingredient lines; the platform sans (`fontFamily: null`) for
  buttons, chips, field labels, nav labels and meta lines. A button label set
  in a serif reads as decoration, which is why `labelLarge` is sans.
  `titleMedium` went 17 → 18 and `bodyLarge` 16 → 17. The font is bundled
  under `assets/fonts/` as static instances rather than pulled from
  `google_fonts` (CLAUDE.md rule 8, asked and declined in Part 1's planning
  and still declined) — the variable build would need `FontVariation` rather
  than `fontWeight`, which is not worth it here. `OFL.txt` ships beside it.
- **Three token classes** join `AppSpacing`: `AppRadii` (4/8/12/16/28),
  `AppSizes` (eleven values, including a new `emptyStateIcon` — borrowing
  `target` for a drawing would read wrong), and `AppDurations` (150/250 and
  one curve, existing so later slices have a name to reach for, not so this
  slice animates anything). "Full" deliberately is **not** in `AppRadii`: a
  stadium is a shape, so it is `const StadiumBorder()` at the call site, which
  is what stops a pill being turned into a rounded rectangle by someone
  reaching for the biggest number in the class.
- **`KitchenColors`** (new, D118) — the app's first `ThemeExtension`, twelve
  members, hand-written `copyWith`/`lerp`, built from a scheme by a single
  `KitchenColors.of(ColorScheme)` factory. Every member is an *alias* of a
  role, so there is no second palette to keep in sync; what it adds is
  vocabulary. Two members are load-bearing rules rather than preferences, and
  the doc comment says so: `unmatched` is not an error (a line the catalog did
  not recognise still renders what the cook typed — CLAUDE.md rule 3) and
  `offline` is not an error (offline is frequent here; the banner informs, it
  does not alarm). Only the offline banner consumes it in this slice; the
  other eleven members are what slices 3–7 read instead of reaching for a role
  directly, and were left in on purpose.
- **Three shared widgets retuned** — `offline_banner.dart` is now a calm inset
  rounded card on `KitchenColors.offline` with a `cloud_off` icon and
  left-aligned text, not a full-bleed `errorContainer` strip with centred
  text; `app_empty_state.dart`'s icon went 56 → `AppSizes.emptyStateIcon`
  (48); `app_section_heading.dart` needed no code change but its doc comment
  did, since `titleMedium` now means something different. `app_shell.dart`
  swapped two nav glyphs (List → `format_list_bulleted`, Settings → `tune`).
  `placeholder_screen.dart`, dead since Phase 1, is deleted.
- **Docs** — `docs/DESIGN_SYSTEM.md`'s Status paragraph now says it describes
  the code rather than the target, with a new paragraph drawing the line
  between what is *described* (all of it) and what is *applied* (the tokens
  everywhere; § Components slice by slice). `docs/DESIGN.md` is reduced to a
  pointer. Every live reference to it — `CLAUDE.md`, the three
  `.claude/commands/`, `docs/ROADMAP.md`, `docs/design-brief.md` — was
  repointed. `docs/journal/**` and `D117` were left alone: they are history,
  and D118 is what records that D117 has been superseded.

**How it was verified.** `dart analyze` — clean. `flutter test` — **587/587**
green (584 before, and the theme test rewrite went 3 tests → 6; no test was
worked around, the ones asserting old values were updated to the new ones).
`dart run tool/check_layers.dart` — OK. `l10n-check` — green, no ARB key
added. `make check` is green except `seed-check`, red on `main` since
`c8be2bc` for an unrelated reason (`docs/STATE.md`) — `l10n-check` sits behind
it in the target and was run separately. `make test-sql` and the Deno suite
were not run: no `supabase/` file is touched. The grep invariant D117
established still holds — no `Color(0x…)` and no named `Colors.*` anywhere in
`lib/` outside `lib/core/theme/`.

One assertion differs from the plan. The slice asked the test to assert
`fontFamily == null` on the sans roles; it cannot, because `ThemeData` merges
the `TextTheme` onto the platform typography and an unset family resolves to
`Roboto` before the test sees it. That *is* the wanted behaviour — `null` is
how a role asks for the platform sans and the platform answered — so the test
asserts `isNot('Literata')`, which is what the rule actually protects.

**The device walk happened** (2026-09-25, physical Galaxy SM-S931B, release
build against hosted via `make install-hosted`; no emulator attached). All
four combinations — `sr`/`en` × light/dark — across recipe list, recipe
detail, meal plan, shopping list, settings and household. Literata renders
every Serbian Latin diacritic in both weights against real recipe copy
(`raspoređeno`, `Čim`, `izručite`, `šećer`, `kašičica` — no tofu); nothing
truncates, wraps badly or overflows in Serbian; both brightnesses are legible
throughout; the offline banner, forced with airplane mode, reads calm in both
(text at 13.1:1 light / 10.5:1 dark, its fill at 1.45:1 against the surface —
present without alarming). **Part 1's recipe-list meta-line defect is
resolved**, incidentally: the new `ListTileThemeData` sets `subtitleTextStyle`
to `bodySmall` (12) where it had been falling through to Material's
`bodyMedium` (14), and two points is enough for the Serbian line to fit.

Four things the walk found are recorded in `docs/STATE.md` and belong to later
slices: the shopping list's week-range header wraps to three lines in Serbian
(two in English) now that `titleMedium` is 18pt Literata; the per-screen
"Showing your saved copy" lines are still `error` crimson while the global
banner is calm, so the two contradict each other on screen; the FAB has no
`FloatingActionButtonThemeData` and recedes in dark (1.94:1 — presence, not
legibility, the glyph is 7.60:1); and the search field renders in Literata
because Flutter's `InputDecoration` takes `bodyLarge`, though a search box is
furniture and should be sans. Part 1's shopping-list translation defect is
unchanged by the repaint. The 3px paprika review marker was **not** verified —
reaching `import_review_screen.dart` needs a real import (an AI parse on the
hosted quota plus an `import_jobs` row) and that was deliberately skipped;
`#FF9569` measures 8.44:1 against the dark surface, well clear of the value
D117 rejected, but nobody has looked at it at 3px.

---

### Part 3 — The recipes surface

**Status: complete** (`f487c64`). Decisions taken during it: D119.

Slice 2 of `docs/design/MIGRATION_PLAN.md` § 4, and the first slice to touch a
screen. Part 2 repainted the app without editing a single file under
`lib/features/**`; this one edits two of them, and builds the six shared
widgets the migration plan said the recipes surface would need.

The centre of it is the meta row. A recipe card's facts used to be a single
`Text` of strings joined with ` · ` — `8 porcija · 30 min priprema · 45 min
kuvanja`. A joined run has no choice but to break wherever the line runs out,
so in Serbian `30 min` ended one line and `priprema` began the next, and the
two halves of one fact stopped reading as one fact. Part 1's walk logged it;
Part 2 resolved it *incidentally*, by dropping the subtitle from 14pt to 12pt.
That was luck, and two points of font size is not a fix. `AppMetaRow` is: each
fact is its own `Row(mainAxisSize: min)` inside a `Wrap`, so an item is
indivisible and a fact that does not fit moves to the next line whole. There
are no separators — the gaps separate.

- **Six new widgets, seven counting `AppMetaItem`.** `AppBadge`,
  `AppMetaRow`/`AppMetaItem`, `AppMonogramTile`, `AppStatStrip` and
  `AppSearchField` in `lib/core/widgets/`; `RecipeCard` in
  `core/recipes/widgets/` and `IngredientLineRow` in
  `core/ingredients/widgets/` — D43/D53's middle ground, for a widget that
  knows its subject but is needed by two features. `RecipeCard`'s second
  consumer is wired in this slice rather than promised: `recipe_picker_sheet.dart`
  deleted its own `_RecipeTile` and lists `RecipeCard`s. `IngredientLineRow`
  takes **primitives, not a model**, because the import review screen renders
  `RecipeDraftLine`s where this one renders `RecipeIngredient`s, and strings
  are what let slice 5 reuse it instead of forking it.
- **`AppSearchField` was not in the migration plan's widget table.** It earned
  its way in: generic, subject-free, and with a second consumer *today* — the
  recipe list and the picker sheet both held a debounced search box, and both
  needed the same three corrections (stadium, sans input, sans hint). It owns
  the decoration and the clear button but **not** the debounce: the two screens
  key different providers, so each keeps its own `Timer`. Its table row was
  added to `MIGRATION_PLAN.md` § 1.
- **The recipe list** — `_RecipeTile` is gone. Cards in a padded `ListView`
  with `AppSpacing.md` between them, a monogram tile wherever there is no photo
  (and on an image error, since a signed URL can outlive its TTL), the
  favourite marker as a heart at the title's first line, and the Favorites
  chip stripped of its star avatar.
- **The recipe detail** — the app bar loses its title. The recipe's own name
  moves into the body at `headlineSmall`, which is what § Type reserves that
  role for; an app bar repeating it in `titleLarge` would be the same words
  twice in two sizes. The mock floats circular buttons over a full-bleed photo
  and that was deliberately not built: an arbitrary photo in two brightnesses
  has no contrast guarantee behind an icon, and the favourite toggle has to
  stay reachable at any scroll position. Below it: a 16:9 photo well that
  renders **with or without** a photo (a missing picture is not a failure
  state — rule 3's spirit — so `broken_image_outlined` is gone), the stat
  strip replacing the old `meta.join(' · ')` line, `IngredientLineRow`s, 32dp
  step discs, and a source footer.
- **Favourite is a heart.** It used to be a star, one app bar away from five
  more stars that meant a rating. After this slice a star is a rating
  everywhere in the app and nothing else is — the two `Icons.star` left in
  `lib/` are both ratings.
- **Two of Part 2's walk defects are fixed here**, this being the only screen
  in the app with either. The FAB gains a `FloatingActionButtonThemeData`
  (`primary`/`onPrimary`, elevation 0, radius `AppRadii.lg`); Material's
  `primaryContainer` default sat at 1.94:1 on the dark surface and the FAB
  receded into the ground. And the search field is sans: the hint via
  `inputDecorationTheme.hintStyle`, the typed text via `AppSearchField`'s own
  `style:`, because a `TextField`'s *input* style cannot be themed and falls
  through to `bodyLarge`, which Part 2 made Literata.
- **Tokens and strings** — `AppSizes` gains `stepDisc` (32). Five ARB key
  pairs feed the stat strip (`statServingsLabel`, `statPrepLabel`,
  `statCookLabel`, `statRatingLabel`, `statMinutesValue`). Every literal in the
  three files this slice opened migrated to a token.

**One thing the plan got wrong.** It said to delete `recipeDetailFallbackTitle`
from both ARB files because the detail screen's app bar no longer reads it.
`meal_plan_screen.dart` still does — it is the fallback for a plan entry whose
recipe title is missing. The key stayed; its description was rewritten to name
its remaining reader.

**Two things the plan settled that were kept.** Prep and cook stay two
separate meta items with their existing strings, rather than the mock's
combined `3 h 30 min`: the app has no hour/minute formatter and inventing one
would merge two facts into one. And the FAB with its `MenuAnchor` stays, where
the mock puts a bare `+` in the app bar — four import routes need a menu.

**How it was verified.** `dart analyze` — clean. `flutter test` — **621/621**
green (587 before; 34 new, one file per new widget plus the screen tests).
`dart run tool/check_layers.dart` — OK; nothing here crosses a layer.
`make check` is green except `seed-check`, red on `main` since `c8be2bc` for an
unrelated reason. `make test-sql` and the Deno suite were not run: no
`supabase/` file is touched. `l10n-check` regenerates clean and is idempotent.

Tests were updated with the redesign, not worked around: the draft chip test
asserts `AppBadge`, the favourite test asserts a heart and a bare rating
number scoped to `RecipeCard`, the no-photo tests assert a monogram tile and
the well's placeholder, and the ingredient tests assert `g šargarepa` as one
run with `200` alone in its column. Two harnesses gained `theme:
AppTheme.light()` — `recipe_screens_test.dart` and
`meal_plan_screen_test.dart`, the latter because the picker sheet now lists
`RecipeCard`s — since the redesigned widgets read `KitchenColors` and a
default `ThemeData` carries no extensions.

**The device walk happened** (2026-09-25, physical Galaxy SM-S931B, release
build against hosted via `make install-hosted`; no emulator attached), across
`sr`/`en` × light/dark on the list, the detail and the picker sheet. **The
meta row wraps by whole items**: in Serbian `Palačinke` takes three lines
(`4 porcije` / `10 min priprema` / `10 min kuvanja ★ 2`) and no item is ever
split from its own icon; the same card in English takes two. That is the
Serbian defect fixed structurally rather than by luck. Monogram tiles, the
heart/star split, the four Serbian stat labels at phone width, step discs and
ingredient hairlines all hold in both brightnesses, and `RecipeCard` renders
identically in the picker sheet. The FAB is unmistakably present in dark now,
and the search field is sans in both of its consumers.

**The walk found one defect, and it was fixed and re-walked in the same
sitting.** The stat strip's rating column overflowed: stars three, four and
five sat off the right edge, untappable, so nobody could rate a recipe above
2. An M3 `IconButton` sizes itself from its **style**, and `app_theme.dart`'s
`iconButtonTheme` sets `minimumSize: Size(target, target)` (48dp), which the
widget-level `padding: zero` / `constraints: BoxConstraints()` do not
override. Five stars wanted ~220dp inside an ~86dp quarter-width column. The
stars had always been that wide — before this slice they had a full-width row
to sprawl in, so it never showed, which is also why the plan's "keep today's
compact, zero-constraint `IconButton`s, do not fix it" instruction was wrong
about what "today's" meant. Fixed locally in `_RatingStars` with
`IconButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero,
tapTargetSize: shrinkWrap)` plus a `FittedBox(scaleDown)` backstop; not a theme
change, because the 48dp minimum is right everywhere else. Alongside it, the
strip's values did not share an optical line — each hung from its own top
edge, so a 16dp star row sat lower than a 26dp line of text; `AppStatStrip`
now centres every value in a box one `bodyLarge` line tall, as a minimum so a
two-line value grows rather than clipping.

Re-walked after the fix on the same device: all five stars inside the Rating
column in all four combinations, and tapping the fifth registered a 5 against
hosted data (set back to its original 2 immediately). Three new tests guard
it, two of them pumping a 360×780 surface — the old tests all pumped 800×600,
where a 220dp row simply lays out, which is why none of them caught it. Both
width tests fail against the pre-fix widget.

**Three older walk loops closed with it**, taking `docs/STATE.md`'s list from
nine to six: Phase 6 1a (switching to English relabelled `Doručak` →
`Breakfast` on the list and `Slatko`/`Užina` → `Sweet`/`Snack` on the detail,
the title came through as `Crêpes` under a Machine translation chip, and
tapping a translated chip still narrowed), Phase 6 2 (typing the *Serbian*
`doru` while the app was in English narrowed to the recipe tagged `Doručak` —
cross-language tag search works from the field, not only from the chips), and
Part 2's own FAB and search-field defects. Not exercised: a single query
matching one recipe by title and another by tag at once, which needs seeded
data this household does not have; and an unmatched ingredient line's dashed
ring, for the same reason — no recipe here has an unmatched line.

---

### Part 4 — The meal plan surface

**Status: complete** (`3689c56`). Decisions taken during it: D121.

Slice 3 of `docs/design/MIGRATION_PLAN.md` § 4. `meal_plan_screen.dart` takes
the Garden "Plan — week" layout. It is presentation only: no provider,
repository, route or `supabase/` file changed, and the only other files
touched are the ARBs, `kitchen_colors.dart`'s doc comments, the screen's test
and `docs/DESIGN_SYSTEM.md`.

The old screen was a flat list of days, each with four slot rows of chips and
an `Add` chip in every slot, so an empty week was 28 identical `Add`s with
`Divider`s between them. The new one is a padded list of **day cards**, with
each entry nested inside as a card of its own. The brief was that **no
affordance is lost**. The Today/Week toggle, week navigation, the per-entry
action sheet (open, cooking for, plan leftovers, move to, move up, move
down, remove), its three dialogs, the snack-repeat advisory, several entries
in one slot, notes, pull-to-refresh, and long-press drag with a visible drop
highlight all survive.

- **Day cards.** A day with any entry, and today always, is expanded: its
  entries grouped by slot in `MealSlot.ordered` order, then an add row. Today
  keeps the ordinary day-card fill and gets a **2dp border in
  `KitchenColors.today`** plus a `Danas`/`Today` pill (`labelMedium` on
  `today`, `StadiumBorder`). Today is outlined, not filled, which leaves
  `todayContainer` meaning only the step-number disc. Its doc comment and
  DESIGN_SYSTEM's semantic-layer row were rewritten to say so. The header
  drops its `FontWeight.bold` for plain `titleSmall`.
- **Collapsed empty days.** In Week view, a day with nothing planned that is
  not today collapses to one compact card on `surface` (lighter than a
  planned day, as in the mock), with its header and a `+ Dodaj obrok` / `+ Add
  meal` button. The button opens a **slot chooser**, a small bottom sheet of
  the four slots, and the chosen slot runs the same `_add` flow as a direct
  `+ <Slot>` tap. An empty week is seven collapsed cards, not an empty state.
  The Today view never collapses.
- **The add row.** A `+ <Slot>` text button in quiet `onSurfaceVariant` for
  each *empty* slot, then a trailing icon-only `+` in `primary` that opens
  the same chooser. The `+` is load-bearing: it is the only way a second
  entry gets into an already-filled slot, and several entries per slot is a
  supported feature.
- **Entry cards.** `surfaceContainerLowest`, radius 12, and an `AppMetaRow`
  above the title (D119: never a ` · `-joined string). The row holds the slot
  as plain text, then a servings item for a recipe, a `Napomena`/`Note` item
  for a note, or `od pon 1.`/`from Mon 1` for a leftover. Titles are
  `titleMedium`, and a note's own words are `bodyLarge`. Both wrap rather
  than truncate. There is no thumbnail, since an entry carries a recipe's
  title and servings but not the recipe itself (D53).
- **Leftovers.** The same card with a dashed 1dp `outline` border, drawn by
  a private `_DashedRoundedRectPainter` that runs `_DashedRingPainter`'s
  approach along an `RRect`'s `PathMetric` (rule 8: no package), plus a
  leading return icon in `KitchenColors.leftover`. The source's day is shown
  only when the source entry is in the week the screen already holds, which
  avoids a new query. It uses the abbreviated `weekdayAndDay` form because a
  full Serbian weekday would have to be declined after `od`.
- **Drag.** `LongPressDraggable` now carries the `MealPlanEntry` rather than
  its id, because a drop onto a collapsed day has to know which slot to keep.
  There are three targets: a filled slot's group of cards, a `+ <Slot>`
  button, and a collapsed day, which **keeps the entry's own slot**. The
  feedback is the card itself at its source width (a `LayoutBuilder`) on
  `Material` elevation 2. The highlight is `primaryContainer`. On a filled
  slot it tints the entry cards themselves, because their own fill would hide
  a highlight drawn behind them. The plan did not say how to show it there;
  this was the build's call.
- **Part 2's walk defect for this screen is fixed.** The per-screen "Showing
  your saved copy" line is `onSurfaceVariant` instead of `error` crimson,
  matching the calm global banner (MIGRATION_PLAN § 2.1). The shopping list's
  copy of the line is still crimson and stays with that slice.
- **Tokens and strings.** Every literal the plan listed migrated to
  `AppSpacing`, `AppRadii` or `AppSizes`, including the `withValues(alpha:
  0.3)` tint on the old drop highlight. The week bar centres its range in an
  `Expanded` between the chevrons, and the segmented toggle is full-width
  (`expandedInsets: EdgeInsets.zero`). Three ARB key pairs were added:
  `addMealButton`, `mealEntryNoteLabel` and `leftoverFromDay`.

**Settled in planning and kept.** The toggle keeps the app's `Danas | Ova
nedelja` order and Today default, although the mock has them the other way
round. Phase 5 chose to open on Today, and a mock does not overrule that.
The mock's "Already planned recently" line under an entry was **not built**:
the app keeps no per-entry repeat flag, and the snack-variety check is an
advisory at add time (D58), so showing it persistently would need new data.

**How it was verified.** `dart analyze` was clean. `flutter test` passed
**629/629**. The meal plan file has 32 tests, several of them new: the slot
chooser from a collapsed day reaching the recipe picker with that day and
*Dinner*; the trailing `+` on a filled day opening the chooser with all four
slots; a leftover showing `from Mon 1` when its source is in the week and
only its slot when it is not; long-press drag onto `+ Dinner` calling
`moveEntry(slot: dinner)`, and onto a collapsed Tuesday calling it with the
entry's own slot; the offline line's colour being `onSurfaceVariant` and not
`error`; and Serbian at **360×780** in both views with a long recipe title,
a leftover and a note, with no overflow. Existing tests were rewritten to the
new structure, not worked around. `ActionChip 'Add'` counts became
`+ <Slot>` and `Add meal` button counts, the `Divider` counts went, and the
add-a-note and snack tests tap `+ Breakfast` / `+ Snack` in the Today view.
One thing surfaced while writing them: `TextButton.icon` builds a private
`TextButton` subclass, so `find.widgetWithText(TextButton, …)`, an
exact-type match, never sees one. The suite finds them with
`find.bySubtype<TextButton>()` instead. The test file was also reflowed by
`dart format`, so its diff is wider than its changes.
`dart run tool/check_layers.dart` passed. `l10n-check` regenerates
identically. `make check` is otherwise green except the pre-existing
`seed-check`. `make test-sql` and the Deno suite were not run, since no
`supabase/` file was touched.

**Not yet walked on the device.** The plan's `/design-walk meal-plan` covers
`sr`/`en` × light/dark on the physical Galaxy and has not happened. It is
open in `docs/STATE.md` with the plan's checklist: today's outline and pill
in dark, the add row wrapping by whole buttons (and the trailing `+` not
reading as a duplicate of `+ Užina`), the dashed border at 1dp and the
mustard icon in dark, long Serbian titles wrapping, a collapsed day on one
line, the week range between the chevrons, the three drop highlights,
dropping on a collapsed day keeping the slot, the action sheet and all four
dialogs, the offline line in airplane mode, and an empty Today view showing
all four `+ Slot` buttons.

---

### Part 5 — The shopping list surface

**Status: complete** (`f6c5dcc`). Decisions taken during it: D122.

Slice 4 of `docs/design/MIGRATION_PLAN.md` § 4. `shopping_list_screen.dart`
takes the Garden "List — offline, document in SR" layout. It is presentation
only: no provider, repository, route or `supabase/` file changed. The other
files touched are `format_item_quantity.dart` (pure-Dart `domain/`),
`IngredientLineRow`, the ARBs, three test files, `docs/DESIGN_SYSTEM.md` and
`docs/design/MIGRATION_PLAN.md`.

The old screen had a `Row` holding the date range in `titleMedium`, two
`TextButton`s and a calendar icon. Under that came a flat run of dense
`ListTile`s with the summed quantities trailing, and a bare `ExpansionTile`
for staples. The new one:

- **The range bar.** A full-width `SegmentedButton`: `Ova nedelja` ·
  `Sledeća` · `Datumi` (the third with a date icon and the longer `Izaberi
  datume` as its tooltip). The selection is **derived**: a range equal to
  `PlanWeek.of(now)` or its `.next` selects that segment, and anything else
  selects `Datumi`. A single-select `SegmentedButton` ignores a tap on its
  selected segment, so `emptySelectionAllowed: true` turns that tap into an
  empty set, and an empty set while `Datumi` is selected reopens the picker.
  That is how a second custom range gets picked. The range text leaves the
  button row for its own `bodySmall` line, `Sledeća lista: {from} – {to}`,
  shown **only** when there is no list or the selected range differs from
  the list's own (compared by date). This fixes part 2's defect, where the
  range wrapped to three lines in Serbian beside the buttons.
- **Provenance and the doc-language tag.** The generated-at line, then the
  saved-copy line when offline, both `bodySmall` `onSurfaceVariant`. The
  saved-copy line was `error` crimson, part 2's other open defect. Under
  them is a new `_DocumentLanguageTag`: a stadium with `docLanguage` fill and
  an `outlineVariant` ring, holding the code from `list.locale` and a
  sentence in the **reader's** locale (`Ova lista je na engleskom`). It is
  always shown, not only when the two locales differ.
- **The document card.** One theme `Card` of `IngredientLineRow`s (its third
  consumer, D53). The first quantity goes in the row's quantity column with
  its unit beside the name. Further unit families (`+ 300 g`, never merged,
  D9) and each unmatched raw line go in the trailer. Items are ordered by
  `groupByCategory`, the call the clipboard export uses, with an `md` gap
  between category blocks and **no heading** (D105-amended; the Garden mock
  draws them and was declined). A long-press still toggles a pantry staple,
  and `_togglePantry` is unchanged.
- **The staples card.** A second `Card` (`Clip.antiAlias`) holding the
  collapsed `ExpansionTile`, with `const Border()` shapes so it draws no
  lines of its own.
- **Supporting changes.** `formatItemQuantityParts` returns `(number, unit)`,
  and `formatItemQuantity` is now `'${p.number} ${p.unit}'` on top of it, so
  the screen's split form and the export's joined form cannot drift.
  `IngredientLineRow` gains `showDivider` (default `true`, so recipe detail
  is unchanged). Four ARB key pairs were added: `listIsInSerbian`,
  `listIsInEnglish`, `pickDatesSegment` (`Datumi`, short on purpose: a
  segment gets ~109dp) and `nextListRangeLine`. Every literal the plan
  listed migrated to `AppSpacing`.

**Part 1's "untranslated strings" was not a missing translation.** Both
ARBs had `generatedForRangeLine`, `probablyHaveHeading` and
`cupboardStaplesSubtitle`. The list on the device had been *generated in
English*, and D94 renders the document in its generating locale. The English
ingredient names in the same report were the same fact. Nothing moved to
the reader's locale. The tag is what makes the split legible.

**Changed by the walk.** The device walk found two defects, both fixed and
re-walked on the device the same evening. They differ from the plan in two
places:

1. **No selected check on the segments.** The plan expected `Ova nedelja`
   to fit with the check icon. On the Galaxy it wrapped to two lines, and
   `This week` did too, so the cause was width rather than Serbian length.
   The bar grew from 48dp to 56dp while that segment was selected.
   `showSelectedIcon: false` fixes it; the `secondaryContainer` fill still
   marks the selection in both brightnesses.
2. **A hairline on every to-buy row but the card's last.** The plan dropped
   the hairline on the last row of every category block. On a real list
   (`mleko, jaje` · `brašno` · `hleb`) most blocks hold one item, so the only
   hairline on screen sat between milk and eggs, and the gaps read as uneven
   row spacing rather than as groups. Now every row keeps it, the card's edge
   stands in for the last, and the `md` gap still separates blocks. The
   grouping is a quiet cue, which suits a list read while shopping. The
   staples card already worked this way.

**How it was verified.** `dart analyze` was clean. `flutter test` passed
**645/645**. The shopping list screen file has 30 tests, many of them new:
the column form of quantities (`1.2` and `kg brašno`); a second family in
the trailer (`+ 300 g`); the unmatched marker; the saved-copy line's colour
being `onSurfaceVariant`, not `error`; an English list under a Serbian reader
showing `EN`, `Ova lista je na engleskom` and an English `Probably have (1)`,
which pins D94 as intended; no category label rendering while the order
holds; Serbian at **360×780** with a list, a two-family item, a long name, an
unmatched line and staples, with no overflow; the derived selection
(`thisWeek` by default, `nextWeek` after tapping `Sledeća`); the range line
absent for the list's own range and present for another; re-tapping the
selected `Datumi` opening `DateRangePickerDialog`; the selected segment
carrying no check; and a block's last row keeping its hairline while only
the card's last drops it. The last two fail against the pre-fix code.
`format_item_quantity_test.dart` covers `formatItemQuantityParts` and pins
`formatItemQuantity` as its join. `ingredient_line_row_test.dart` covers
`showDivider: false`.

`flutter_test`'s square-glyph font wraps `Ova nedelja` at any segment width,
so no widget test can measure the segment wrap. The test pins the flag
instead. `check_layers` passed. `l10n-check` regenerates identically (the
generated files have to be staged for its `git diff`). `make test-sql` and
the Deno suite passed. `make check` is otherwise green except the
pre-existing `seed-check`. `dart format` was not applied to the existing
test files, so the diff is only the changes.

**Walked on the device.** `/design-walk shopping-list` on the physical
Galaxy, hosted release build, across `sr`/`en` × light/dark:

- Quantities line up in their `primary` column.
- The `SR`/`EN` tag is legible in dark.
- The staples card expands and collapses, and its trailers read in both
  brightnesses.
- `Sledeća` and a custom `Datumi` range select correctly. The range line
  sits on one line (`Sledeća lista: uto 22. sep – čet 24. sep`), and
  re-tapping `Datumi` reopens the picker pre-filled.
- In airplane mode the saved-copy line is grey under the grey banner.
- Long-press marked `hleb` as a staple with the "applies next time"
  snackbar, and the list on screen stayed as it was (D13). The next
  regenerate moved it to `Verovatno imate`, and a second long-press set it
  back.
- Copy shows `Lista kopirana.`.
- Regenerated once under each language, the document followed the
  generating locale both ways, and the tag said so.

Three lists were regenerated on hosted in the process.

Not exercised:

- A two-family `+ 300 g` trailer on the device: nothing planned that week
  summed two unit families.
- The paste half of Phase 5 part 5's clipboard loop, which would have meant
  writing a note into one of the user's own apps.

Noticed, not this slice's: the global offline banner's Serbian string has a
literal `--`, and Flutter's own `sr` date-picker header reads `22. sep to
24. sep`.

**Closed by it.** Part 1's loop (its translation item, explained above),
part 2's loop (the range header and the crimson line), and part 5's own.
Phase 5 part 5 is half confirmed.

**Out of scope, noted as ideas:** a Serbian decimal comma (`1,5`); count
units reading `3 kom jaje`; the mock's genitive names (`kiselog kupusa`),
which would need catalog data.

### Part 6 — The import review surface

**Status: complete** (`882d77a`). Decisions taken during it: D123.

Slice 5 of `docs/design/MIGRATION_PLAN.md` § 4. `import_review_screen.dart`
takes the Garden "Review import" layout. It is presentation only: no
provider, repository method, route or `supabase/` file changed. The one
server call newly reachable from the review body is the existing
`importRepositoryProvider.dismiss`, which `_Failed` already made. The other
files touched are `IngredientLineRow`, the ARBs and two test files.
`docs/DESIGN_SYSTEM.md` was updated in the record commit, not the code
commit. The build session skipped the slice file's design-system step, and
closing the slice caught it.

The old screen was a form: a summary with a sparkle icon and paprika text, an
outlined title field, every ingredient as an always-open
`IngredientLineField` inside a `Container` with a 3px `tertiary` border when
flagged, the steps as outlined fields under a heading, and a lone Save at
the bottom. The new one:

- **The summary card.** `Poklopljeno N od M sastojaka` in `titleMedium`, a
  4dp `primary` progress bar on `surfaceContainerHighest`, and, only when
  something is flagged, a 3px × 16dp `reviewMarker` bar before `N vredno
  pažnje pre čuvanja` in `bodySmall` `onSurfaceVariant`. Paprika is the bar,
  not the text.
- **The title field** is on the theme, with its label above it in
  `titleSmall`. The local `OutlineInputBorder` that overrode the theme is
  gone, and so is the one on the steps.
- **Read-only rows that open on tap.** Each line is an `IngredientLineRow`
  (its fourth consumer). The quantity goes through `formatQuantity`, the unit
  is spelled in the **recipe's** locale, and the name is the local parse of
  the raw text, falling back to the whole raw text (rule 3). The trailer
  reads `→ <catalog name> · <note> · opciono`. A tap swaps the row in place
  for the unchanged `IngredientLineField`, with a right-aligned
  `Done`/`Gotovo`. One `_openLineId` keeps one line open at a time. The list
  stays a `ReorderableListView` because the field's drag listener asserts
  outside one, and closed rows drag by long-press.
- **`IngredientLineRow`'s flagged state.** It gains a `surfaceContainerLow`
  tint, and the marker moves from `decoration` to `foregroundDecoration`. As
  a decoration border it added 3px of padding, so a flagged row's quantity
  sat 3px right of its neighbours. The tint gets `sm` of right padding and
  none on the left.
- **Method** is a theme `Card` holding a collapsed `ExpansionTile`
  (`Postupak`, `N koraka`), which expands in place to the step fields and
  Add step.
- **The action bar** is on `surface` with a top hairline. It holds outlined
  `Odbaci ovaj uvoz` and filled `Sačuvaj recept` as equal halves, each padded
  `lg` so the Serbian fits at 360dp. Discard opens a confirm dialog whose
  `Odbaci` is a `TextButton` in `destructive`, then `dismiss` → recipe list,
  mirroring `_FailedState._dismiss`. Both buttons are disabled while either
  runs.
- **Failed and AlreadySaved** move onto `AppEmptyState`. The failed icon is
  `outline` rather than `error` (a failed import is not validation), and its
  discard stays unconfirmed. `Otvori recept` is tonal.
- **Five ARB key pairs:** `importStepsCount` (plural), `discardImportDialogTitle`,
  `discardImportConfirmBody`, `discardButton`, `doneButton`.

**What "flagged" means did not change.** It is the set of lines the server
matched without `autoAccept`. The Garden mock flags an unmatched `Vegeta`
line. The app keeps its own semantics: unmatched gets the dashed ring and
nothing red.

**Changed by the walk.** The plan said a blank line renders open, so Add
ingredient needed "no id bookkeeping". On the device, the first keystroke
made the line non-blank, and it collapsed into a read-only `m` row with the
keyboard gone. `_addLine()` now opens the new line by id. Its test types
into the line and fails against the pre-fix code.

**How it was verified.** `dart analyze` was clean. `flutter test` passed
**654/654**. The import review screen file has 13 tests. The old "renders
every line" test asserted whole raw strings in text fields and now finds the
rich-text rows plus `→ šargarepa`, with `za posluživanje` still on screen
without a quantity or unit. New tests cover:

- only the LLM line flagged, and the unmatched one carrying the ring with no
  flag
- tap-to-edit: no field before a tap, exactly one after, none after `Done`,
  still one after tapping two rows in turn
- Add ingredient opening a blank line that stays open after a keystroke
- Method collapsed on open (`1 step` shown, the step text not) and expanded
  on tap
- Discard: Cancel makes no `dismiss` call, and confirming calls
  `dismiss('job-1')` once and lands on the recipe route
- `_Failed` rendering through `AppEmptyState` with an `outline` icon
- Serbian at **360×780** with no overflow and both actions present

The tests now pump through a small `GoRouter`, so Discard's navigation
happens, and they override `importRepositoryProvider` with a fake whose
`noSuchMethod` throws. `ingredient_line_row_test.dart` adds three tests: the
tint and foreground marker on a flagged row, neither on an unflagged row
(the three other consumers), and the quantity's right edge landing at the
same x for a flagged and an unflagged row. `check_layers` passed.
`l10n-check` regenerates identically. `make test-sql` and the Deno suite
passed. `make check` is otherwise green except the pre-existing
`seed-check`.

**Walked on the device.** `/design-walk import-review` on the physical
Galaxy, hosted release build, across `sr`/`en` × light/dark. A paste import
of `Proja sa sirom` (ASCII Serbian: `adb input text` cannot type
diacritics) was the real parse the plan budgeted:

- `Čitanje recepta…` shows with its hint while the job runs.
- The server matched 6 of 6, including `Vegeta` and `1 saka pirinca`, and
  flagged two (`feta`, `pirinač`). Two adjacent flagged rows read as one
  continuous marker with the hairline between them intact.
- The quantity column lines up across the flagged rows (`300`/`2`/`200`/`100`/`1`).
- The 3px marker is clearly legible in dark, on the rows and in the summary.
- The progress bar shows on its track in dark.
- The dashed ring reads as dashed at 16dp in both brightnesses. The parse
  left no line unmatched, so it was seen on a hand-added line.
- `Odbaci ovaj uvoz` / `Sačuvaj recept` each sit on one line above the nav
  bar, and the bar reads as separate from it.
- The dialog fits without scrolling. Cancel stays, and Discard lands on the
  recipe list with no recipe created.
- `Postupak` / `3 koraka` expands in place.
- The draft survives a tab switch to change the language, and the rows stay
  in the recipe's language under an English reader.

A second import, `Kajgana`, re-checked the Add-ingredient fix (`malo
ljubavi` typed whole, the line staying open), showed the summary with
nothing flagged, and was saved, landing on its detail. It is now a draft
recipe on hosted.

Not exercised:

- **`AlreadySaved`.** The plan expected Back from the saved recipe to reach
  the review. Save navigates with `go`, which was already the case before
  this slice, so Back lands on the recipe list. Widget tests cover the
  state.
- **`Failed`.** Nothing provoked it, and no quota was spent trying.
- **A long-press reorder** and picking a match through the chip.

Noticed, not this slice's: the match chip under an open line reads `Nema
poklapanja` under an English reader. That is `IngredientLineField`, which
this slice was told not to touch. The flagged tint is 5–6 levels off the
ground in both brightnesses (the token pairing), so the marker carries the
signal.

**Closed by it.** Part 2's "3px marker in dark, not verified" and part 3's
"unmatched ring not exercised" leftovers. No new loop opened.

### Part 7 — The form vocabulary

**Status: complete** (`46c6742`). Decisions taken during it: D124.

Slice 6 of `docs/design/MIGRATION_PLAN.md` § 4. It puts one form vocabulary
on every form the earlier slices had not reached: the recipe editor,
translation review, the three import entry screens, and create / join
household. It is presentation only: no provider, repository, route or
`supabase/` file changed, and no ARB key was added or removed. Two ARB
*values* changed on the walk (below). `docs/DESIGN_SYSTEM.md` was updated in
the code commit this time: § Inputs, a new § Action bar, § Import review,
§ Ingredient lines, and the shared-widgets table.

Before this slice, each form did its own thing:

- floating `labelText` inside outlined fields (`OutlineInputBorder`,
  `isDense`) that overrode the theme
- typed text falling through to the Literata `bodyLarge`
- the editor's private `_FieldLabel` in `labelLarge`
- every bottom save button in a bare padded `SafeArea` that merged into the
  nav bar
- raw numbers for every gap

The new vocabulary:

- **`AppFieldLabel`** (`core/widgets/`) is `titleSmall` with no padding of
  its own. Every field has one above it, followed by `sm`, then the field
  from the theme with `style: bodyMedium`. The exceptions are the paste box
  and the join code, where the paragraph or title above already says what
  the field is. Import review's inline label became this widget.
- **`AppActionBar`** (`core/widgets/`) is import review's bar, lifted whole
  (D123). It sits under the editor, translation review, and paste / URL /
  photo, as well as import review, whose rendering did not change. The
  error line is `bodySmall` `error`, and each busy spinner is
  `AppSizes.iconInMeta` square.
- **The editor's numbers row** labels its three columns in a separate row,
  bottom-aligned, above a row of the fields, so a wrapped `Priprema (min)`
  never staggers them. `_NumberField` lost its `label`.
- **Translation review** stacks each pair as label, then `_OriginalText`
  (caption in `labelMedium`, text in `bodyMedium`, both `onSurfaceVariant`),
  then the field. It still has no drag handles and no add or remove (D80).
- **Onboarding** titles moved from `headlineSmall` to `titleLarge`, with
  subtitles in `onSurfaceVariant`. The join code is `titleLarge` with `sm`
  letter spacing and tabular figures, replacing `fontSize: 24`.
- **`IngredientLineField`** lost its border and `isDense`, and its chip
  indent is now `AppSizes.icon + AppSpacing.xs`.
- **`IngredientMatchChip`**'s status words now come from
  `AppLocalizations.of(context)`, so the chip follows the reader. The amount,
  units and suggested name stay in the recipe's locale (D86), and `chipL10n`
  is gone. The label text moved from `outline` to `onSurfaceVariant`, and the
  icon stays `outline`. The icon's raw `size: 18` was dropped rather than
  raised to 20, because the chip theme's default avatar size is already 18.

**Changed by the walk.** The photo import's outlined pickers wrapped
(`Choose a photo` / `Izaberi fotografiju`) in both languages and both
brightnesses. Each half is about 183dp wide on the Galaxy. D123's `lg`
button padding fixed the English but not the Serbian. The labels became
`Camera` / `Gallery` and `Kamera` / `Galerija`, which are the editor's own
photo-picker words. Those are changes to `takePhotoButton` /
`choosePhotoButton` values only; the keys stayed the same. The `lg` padding
stays as headroom for 360dp.

**How it was verified.** `dart analyze` was clean. `flutter test` passed
**664/664**, ten more than before. New tests:

- `AppFieldLabel` renders `titleSmall`.
- `AppActionBar` has a `surface` fill, a 1dp `outlineVariant` hairline, and
  its child at full width inside the `lg` gutters. The error line appears
  only when set, in `bodySmall` `error`, above the child.
- The match chip reads `No match` under an English app on a Serbian recipe
  and `Nema poklapanja` under Serbian. A suggestion's label is
  `onSurfaceVariant` and its icon is `outline`.
- The editor has a Serbian 360×780 no-overflow test, which also asserts
  that the three number fields share one top edge.
- All nine editor fields type in `bodyMedium` and never in Literata.

Three existing tests changed:

- Translation review finds the title field as the first `TextFormField`,
  because its label is no longer inside the decoration.
- Two `ingredient_line_field_test` checks expected `Nema poklapanja` under
  an English host. They now expect `No match`, which is the fix itself, so
  the plan's "none found by grep" was wrong.

`make test-sql`, the Deno suite and `l10n-check` passed. `make check` is
otherwise green except the pre-existing `seed-check`. The acceptance grep
over the touched files was clean, apart from one `0` in import review's
method card, which this slice was told not to touch.

**Walked on the device.** `/design-walk forms` on the physical Galaxy,
hosted release build, across `sr`/`en` × light/dark. It covered the editor,
translation review and the paste / URL / photo screens:

- Every field has its label above it.
- Typed text is sans in the title, description, a number, an ingredient line
  and a step.
- The numbers row fits one line at ~411dp, so the two-row layout never
  handled a wrapped label on the device. The 360dp test covers that case.
- The action bar on `surface` reads as separate from the nav bar in both
  brightnesses.
- On the same Serbian recipe the chip reads `Nema poklapanja` under Serbian
  and `No match` under English, and a new line's hint stays `2 šolje glatkog
  brašna`.
- In translation review, the original is visibly secondary but legible in
  both brightnesses.

**Folded in Phase 5 part 6's loop.** Translate in the editor's app bar on
`Kajgana`, which had no translation, saved, called the Edge Function (one
hosted AI call), and came back. The action left the app bar (the D85
guard), the recipe reads `Scrambled Eggs` under a `Machine translation`
chip in English, and the detail menu offers `Review translation`. The
snackbar went by unseen while the walk was polling the screen. `Kajgana`
now has an unreviewed machine English translation on hosted.

Not exercised:

- **Create / join household.** They are reachable only on an account with
  no household, and the device account has real recipes. Whether the serif
  join digits read as a code is still unjudged, which is left for slice 7's
  throwaway household.
- **A suggestion chip on the device.** No typed line produced a
  below-auto-accept candidate. Widget tests cover it.

**Closed by it.** Phase 5 part 6's loop, and part 6's "`Nema poklapanja`
under an English reader" note. **Opened:** part 7's own loop, for the
onboarding screens only.

### Part 8 — Sign-in, settings and household

**Status: complete** (`47ec811`). Decisions taken during it: D126.

Slice 7 of `docs/design/MIGRATION_PLAN.md` § 4, and the last per-surface
slice: every surface is now on the Garden vocabulary. It is presentation
only, apart from one theme fix found on the walk (below). No provider,
repository, route or `supabase/` file changed. `docs/DESIGN_SYSTEM.md` was
updated in the code commit: § Type, § Size and motion, § Buttons, § Dialog,
a new § Household, and a line under the shared-widgets table.

- **Sign-in.** The `Kitchen Table` wordmark moved from `headlineMedium` to
  `displaySmall`, in `primary`, with a Literata `bodyLarge` tagline under it
  in `onSurfaceVariant`. The new key `signInTagline` replaces
  `signInSubtitle`, which only repeated the button. One full-width 52dp
  filled `primary` button (the new `AppSizes.signInButton`) is pinned at the
  bottom, with no logo. The D125 dev-login button sits under it, unchanged.
  The failure line is `bodySmall` `error`.
- **Settings.** The profile row leads with a circular monogram avatar
  (`AppSizes.avatar`, 40), and the error icon lost its `error` colour.
  `Jezik` is an `AppSectionHeading`. Sign-out is not destructive-coloured.
- **Household.**
  - The first `ListTile` became a header: the name in `headlineSmall`, and
    `2 člana` / `2 members` in `bodySmall` under it (the new plural
    `householdMemberCount`).
  - Members have circular mustard avatars. The caller's own row reads
    `Član · vi` / `Member · you` (`householdMemberYou`).
  - Only the owner sees a `⋮` on another member's row, holding one
    destructive item, `Ukloni člana`.
  - Invites are theme `Card`s. The code uses the join field's exact style.
    A tonal Copy and a destructive text Revoke sit in a `Wrap`.
  - Create invite code is outlined, so the screen has no filled button.
  - Leave moved off the adult's own row into the one bottom destructive
    slot, which the owner's Delete already used. Only one of the two ever
    renders, and neither renders while the role is unknown.
  - The Remove / Leave / Delete confirms became `TextButton`s in
    `destructive`, on import review's `_discard` pattern.
  - The rename field lost its border and label.
- **Keys.** The four tooltip keys became labels: `copyCodeButton`,
  `revokeInviteButton` (now `Opozovi` / `Revoke`, dropping "kod"),
  `leaveHouseholdButton` and `removeMemberMenuItem`. The old keys are gone.
- **`AppMonogramTile`** gained `circular`. A circle is a person and a square
  is a thing.

**Changed by the walk.**

- **Tonal buttons were green app-wide.** `filledButtonTheme` set
  `backgroundColor: primary` / `foregroundColor: onPrimary`. A theme style
  applies to every `FilledButton` variant, so `FilledButton.tonal` rendered
  as a filled green button. That included import review's `Open recipe`
  since D123, and nobody had noticed. Material 3's defaults already give
  filled `primary` and tonal `secondaryContainer`, so the two lines came
  out.
- **Settings' toggle sat flush on the hairline under it.** The theme
  `Divider` takes 1dp of space, so an `lg` gap went above it.

**How it was verified.** `dart analyze` was clean. `flutter test` passed
**673/673**, nine more than before. New tests:

- A Serbian 360×780 household with two members and a live invite. It
  asserts no exception, Copy and Revoke fully on screen, and the name in
  `headlineSmall`.
- The member count reads `2 člana` (the `few` form).
- The caller's own row has `· vi`, and every avatar is circular.
- All three confirms are `TextButton`s whose foreground is
  `KitchenColors.destructive`, with no `FilledButton`.
- `AppMonogramTile(circular: true)` is a `BoxShape.circle` on
  `secondaryContainer`.
- A new sign-in test: the Google button is 52 tall, the wordmark is
  `displaySmall` in `primary`, and there is no dev-login button without its
  defines.
- Light and dark theme tests: filled is `primary` and tonal is
  `secondaryContainer`. They fail on the old theme.

The household tests find Leave, Remove and Revoke by their new labels. The
D115 gating tests keep their meaning. `app_shell_test` expected a bare
`Vlasnik` on the caller's own row and now expects `Vlasnik · vi`; the plan
missed that file. `make test-sql`, the Deno suite, `l10n-check` and
`check_layers` passed. `make check` is otherwise green except the
pre-existing `seed-check`.

**Walked on the emulator.** `/design-walk auth-household` ran on the
emulator, not the Galaxy, which wasn't attached. The command now allows the
emulator for anything behind sign-in that needs no Google account. It used
the hosted release build via `make install-emulator` and the D125 dev-login
account, which is an **adult** in the device household. It covered
`sr`/`en` × light/dark:

- **Sign-in:** the wordmark fits on one line, and the Serbian tagline wraps
  evenly over two. The 52dp button shows the spinner while busy. The
  `#9ED498` wordmark and button are legible in dark. Dismissing Google's
  add-account screen returns to idle with no error line.
- **Settings:** the avatar circle is legible in dark (`#FFE5B9` on
  `#5B4300`), and `Jezik` / `Language` is in Literata.
- **Household:**
  - `Renamed Household`, `2 člana` / `2 members`, circles, and `Član · vi`
    / `Member · you`.
  - The Leave row is present, with no `⋮` and no Delete (the adult half of
    Phase 6 3b and 3c).
  - The six serif digits read as a code, evenly spaced.
  - `Kopiraj kod` + `Opozovi` fit on one row.
  - Revoke and Leave are crimson in light and pink in dark.
  - The Leave dialog has a crimson text confirm. It was cancelled, because
    leaving would drop the dev account from the real household.
- **Writes to hosted:** one invite code was minted, copied, and revoked.

Not exercised:

- the owner side: the `⋮` → `Ukloni člana`, and the Remove and Delete
  dialogs;
- a long Serbian household name wrapping on the device (the 360dp test
  covers the layout);
- the sign-in failure line;
- create / join household;
- a fresh Google account via `on_auth_user_created`.

All of these need the Galaxy, or an owner or memberless account on the
emulator.

**Closed by it:** nothing outright. The adult halves of Phase 6 3b and 3c
are confirmed. **Opened:** part 8's own loop, for the owner side and the
Google-only checks.

### Part 9a — Serif recipe titles, name-left ingredient rows, lighter steps

**Status: complete** (`2fb06a8`). Decisions taken during it: D127.

The first half of the design fixes round (`docs/design/BRIEF_design_fixes.md`
items 1–3, against Claude Design's updated `design-system.pdf` and the
reference screens). It is presentation only: no provider, repository, route,
ARB string or `supabase/` file changed, apart from one ARB *description*.
`docs/DESIGN_SYSTEM.md` was updated in the code commit: § Type (new table,
new `KitchenType` subsection), § Size and motion, § The semantic layer,
§ Navigation, § Inputs, § Ingredient lines, § Steps and stats, § Recipe
card, § Meal entries, § Dialog and the Status paragraph.

- **Type.** Every Material role is the platform sans except `displaySmall`,
  the wordmark. `bodyLarge` went from Literata 17/26 to sans 18/28.
  - A new `KitchenType` `ThemeExtension` (`lib/core/theme/kitchen_type.dart`,
    on `KitchenColors`' pattern) carries the serif recipe titles:
    - `recipeTitle` 18/24: card titles, and recipe or leftover titles on
      plan entries. A note on the plan stays `bodyLarge`.
    - `recipeTitleLarge` 26/32: the detail title and a card's monogram
      letter.
  - `headlineSmall` went sans against the PDF, because the Household mock
    draws the household name in sans (D127).
  - The sign-in tagline is sans now, which option (b) accepts.
- **`IngredientLineRow`.** Name left, amount right. The amount is one
  `Text.rich` with `softWrap: false`: the number in `primary` w600 with
  tabular figures, the unit in `onSurfaceVariant`, and a 24dp gap only when
  there is an amount. Minimum height is 48. The fixed `AppSizes.thumb`
  quantity column is gone.
  - New `optionalLabel`, inline after the name as ` · opciono`.
  - The dashed ring is inline after the name, as a `WidgetSpan`. Its size
    stays `iconInMeta` 16 rather than the PDF's 14; a token for 2dp was not
    worth it.
  - The class doc's "unit rides with the name" reasoning was rewritten,
    since the unit now rides with the number.
- **Steps and stats.** `stepDisc` went from 32 to 28, one `bodyLarge` line,
  so it centres on the first line with no offset. The disc→text gap is `lg`,
  and steps are `xl` apart. Stat values are w600.
- **Doc comments** in `AppSectionHeading`, `AppSearchField`,
  `AppMonogramTile` and `app_theme.dart` no longer claim Literata. The
  `signInTagline` ARB description was updated to match.

**Changed by the walks.** Four fixes, each with a widget test:

- **`opciono` twice.** `limun · opciono` sat over an `opciono` note. The
  parser moves the optional marker into the note, and the old code had
  shown the suffix only when there was no note. The slice dropped that
  guard; recipe detail and import review have it back.
- **Doubled amount on an unmatched line.** A line with no catalog name
  renders its raw text, which already carries the amount, so `1,5 kg mesa`
  also showed `1½ kg` at the right. This predates the slice, but the flip
  made it obvious. Recipe detail now gives such a line no amount.
- **Only flagged import rows were inset.** `Review import@1x.png` insets
  *every* row 12dp on both sides, which is how flagged names line up. The
  slice plan had given only the flagged row a left pad. The new
  `IngredientLineRow.inset` is set by import review on every row. A flagged
  row is always inset, and the hairline and tint still run the full width.
- **A stranded ring.** `komadic dimljenih rebaraca od koliko bude` wrapped
  with the ring alone on the second line. A word joiner (U+2060) before the
  `WidgetSpan` forbids that break.

**How it was verified.** `dart analyze` was clean. `flutter test` passed
**684/684**. The new or rewritten tests cover:

- the amount right of the name, and the unit beside the number;
- the number `primary` w600 and the unit muted;
- right edges lining up down a list;
- a long Serbian name wrapping at 360dp, at least 24dp clear of a one-line
  `1,5 kg`;
- no amount, so no gap;
- `optionalLabel` inline;
- a minimum height of 48;
- the ring inline after the name, and glued to the last word;
- inset rows lining up with flagged ones on both edges;
- the flagged name clearing the marker;
- every role but `displaySmall` not being Literata;
- `KitchenType` values in both brightnesses;
- an unmatched line with an amount saying it once;
- no inline `opciono` when the note already says it.

The recipe-detail and shopping-list tests now find amounts as `200 g` /
`1.2 kg`, and unmatched names via `textContaining` (the ring's placeholder is
in the run's plain text). `make test-sql`, the Deno suite and lint passed.
`make check` is otherwise green except the pre-existing `seed-check`.
`l10n-check` passes once committed.

A repo-wide `dart format` during the walks rewrote about 115 untouched files.
The repo is not format-clean. That noise was stripped before the commit.

**Walked on the emulator.** The Galaxy wasn't attached. Three walks ran on
2026-09-28, each across `sr`/`en` × light/dark, using the hosted release via
`make install-emulator` and the dev-login account:

- **`/design-walk recipe-detail`.** It used a throwaway `Walk test 9a`
  recipe, since soft-deleted; `adb` can't type diacritics, so its long name
  was ASCII.
  - Only recipe titles, card titles and monogram letters are serif.
  - Palačinke's amounts line up on the right.
  - The long unmatched name wraps with its ring.
  - `so` shows over `po ukusu`.
  - Steps read lighter, and the disc centres on the first line.
- **`/design-walk import-review`.** A pasted `Sarma od kiselog kupusa`,
  discarded afterwards, came back 7/8 matched with 3 flagged, one unmatched
  and a `3–4` range.
  - After the inset fix, names and amounts line up flagged or not.
  - The marker, tint and muted trailers hold in dark.
- **`/design-walk shopping-list`.** The Sarma was saved, planned for Tuesday
  lunch, and this week's Serbian list regenerated. The recipe and the plan
  entry were removed afterwards; the list stays, as a snapshot.
  - Amounts line up down the card, and the unmatched line wraps with its
    ring.
  - `so` under `Verovatno imate` is the name only.
  - The gaps fall between category blocks (D105).
  - Legible in dark.

Seen but not part 9a's:

- the list prints `1.5 kg` with a decimal point in Serbian;
- units don't inflect (`2 glavica`);
- the recipe-delete confirm is still a filled button, against § Dialog.

Not reached on device: a long *matched* name against its amount, since
catalog names are short. The 360dp widget test covers it.

**Closed by it:** its own loop, since all three walks ran clean after the
fixes. **Opened:** nothing.

### Part 9b — Grouped Settings, in-app Light/Dark, clear filters

**Status: complete** (`782ca40`). Decisions taken during it: D128.

The second half of the design fixes round (`docs/design/BRIEF_design_fixes.md`
items 4–6 and the two extras, against `Settings@1x.png`,
`Recipes — filters active@1x.png`, `Recipes — no results@1x.png` and the
PDF's FilterRow and Settings patterns). No Supabase migration and no Edge
Function. `docs/DESIGN_SYSTEM.md` was updated in the code commit: § Buttons,
§ Chips, a new § Settings, § Empty state and a rewritten § Light and dark.

- **Theme mode (D128).** Light or Dark, Light by default, no System option.
  - A new Drift table `DevicePreferences` (`key` / `value`); schema 7 → 8.
    `onUpgrade` now skips it when it drops tables, and
    `clearHouseholdCache` leaves it, with a comment saying why.
  - `core/db/device_preferences.dart`: `DevicePreferenceStore`, on
    `sync_watermark.dart`'s `cacheOrElse` / `cacheWrite` pattern.
  - `core/theme/app_theme_mode.dart`: `AppThemeMode`, a keep-alive
    `AsyncNotifier<ThemeMode>`. `set()` writes, then updates the state.
  - `main.dart` builds a `ProviderContainer`, awaits the mode, and runs
    under `UncontrolledProviderScope`. `KitchenTableApp` passes `themeMode`.
- **Settings.** Rewritten into groups. The profile card comes first, then
  `Izgled` (the theme segments, sun/moon kept on the selected one, no check)
  and `Jezik` (unchanged, never translated). Then `Domaćinstvo`: the whole
  card is the tap target, with the household's name and `2 člana`. Last,
  after a hairline, `Nalog` and a full-width outlined Sign out in
  `onSurface`. `_setLocale`, `_signOut` and `_initial` are kept.
  - The name and count come from a new `currentHouseholdSummaryProvider`
    in `core/household/current_household.dart`. It returns a
    `({String name, int memberCount})` record, not the `Household` model
    (D52).
  - `householdMenuItem` became unused and was removed from both ARBs.
- **Recipe list.**
  - `_clearFilters()` drops the tag and Favorites, never the query.
  - The `_FilterRow` starts with an outlined `ActionChip` (`Poništi` /
    `Clear`) and a 1dp × 24 divider while a filter is on.
  - The row is full-bleed: the gutter moved onto the scroll view.
  - While narrowed, a `recipeCount` plural line (`2 recepta`) rides as the
    list's item 0.
  - With a filter on and no results, the empty state adds
    `noRecipesMatchFilterBody` and a tonal `Poništi filtere`. A query alone
    keeps the old title with no action.
- **12 new ARB keys** in both locales, each with an `@` description.

**Changed by the walk.** One defect, fixed in the slice at the user's call:

- **A Dark cold start flashed white.** The first Flutter frame was already
  dark, so the preload worked. But the stock Android launch screen
  (`values*/styles.xml`, white or black by the phone's night mode) came
  first. The launch screen is now flat `primary` green `#366A35` with no
  icon, from one `splash_background` colour:
  - `values-night` is deleted;
  - `values-v31` sets `windowSplashScreenBackground` and a transparent
    `windowSplashScreenAnimatedIcon` (the stock Flutter logo was the
    launcher icon);
  - `NormalTheme` uses the same colour.

  The first build failed: `--` is not allowed inside an XML comment.

**How it was verified.** `dart analyze` was clean. `flutter test` passed
**704/704**. The new tests cover:

- `device_preferences_test.dart`: an unwritten key reads null; the store
  round-trips; `clearHouseholdCache` leaves the row; a v7 file upgrades to
  v8 with the table created and the caches still dropped; a simulated v9
  bump keeps the stored theme. With the `onUpgrade` skip removed, the v9
  test fails.
- `app_theme_mode_test.dart`: Light by default; an unknown value reads
  Light; `set(dark)` writes the store; a stored Dark is read back.
- `app_shell_test.dart` (settings layout): a Serbian 360×780 render with no
  overflow; Sign out is an `OutlinedButton` in `onSurface`, not `error`; the
  theme segment writes the store and flips `MaterialApp.themeMode`; the
  language labels are untranslated in English. The two household-navigation
  tests now tap the household's name.
- `recipe_screens_test.dart` (recipe list filters): Clear only with a
  filter; a query alone brings no Clear; Clear resets the tag and Favorites
  but keeps the query; the count only while narrowed; `1 recept` /
  `2 recepta` / `5 recepata`; `Clear filters` restores the list; a query
  alone gets no action.

`make check` passed lint, tests and Deno tests, then stopped at the
pre-existing `seed-check`. `make test-sql` and `make l10n-check` pass on
their own.

**Walked on the emulator.** The Galaxy wasn't attached. All walks ran
2026-09-28 on the hosted release via `make install-emulator`, with the
dev-login account.

- **`/design-walk settings`**, `sr`/`en` × light/dark with the in-app
  toggle.
  - Every group fits on one 1080×2424 screen. `Važi samo za ovu
    aplikaciju…` wraps evenly over two lines; the English line fits on one.
  - Muted headers and subtitles hold in dark.
  - `Tamna` repaints within 0.6s.
  - Phone in night mode + app on `Svetla` stays light.
  - Dark survives sign-out (the sign-in screen stays dark) and signing back
    in.
  - The household row opens the household screen.
- **`/design-walk recipes`**, all four combinations.
  - No Clear with nothing selected. With a filter on, Clear and the divider
    come first and are visible without scrolling. The last chip runs off the
    edge.
  - `p` + Doručak → `1 recept`; Clear → `p` kept, `2 recepta`.
  - Omiljeni + Doručak → `search_off`, the title, a one-line body in both
    languages, and a tonal `Poništi filtere` that restores the list.
  - Readable in dark.
- **Cold-start re-walk after the splash fix.** Eight frames per launch in
  all four phone × app combinations. Each goes from green to the app's own
  theme; the wrong theme's colour never shows. Nothing green shows through
  while the keyboard opens.

Not reached:

- `5 recepata` (the household has three recipes; the widget test covers
  it);
- anything Google. The dev-login account also shows `Prijavljeni ste Google
  nalogom`, which is only true of real accounts.

Seen, not part 9b's:

- For a frame on a cold start, the tag chips show raw keys (`doručak`,
  and `sweet` in English on a Serbian screen) before `tagLabelsProvider`
  resolves. The fallback is documented as intended.
- The Clear chip's ✕ takes the theme's `primary` chip-icon colour, which the
  slice didn't specify.

**Closed by it:** its own loop, since both walks and the cold-start re-walk
ran clean after the fix. **Opened:** nothing.

### Part 10a — Step timeline, dashed ingredient dividers

**Status: complete** (`b761527`). Decisions taken during it: D129.

Items 1 and 2 of Claude Design's 2026-09-28 export
(`docs/design/BRIEF_steps_dividers_logo.md`). The logo, item 3, is part 10b.
No Supabase migration, no Edge Function, no new ARB key. `docs/DESIGN_SYSTEM.md`
was updated in the code commit: § Ingredient lines, § Steps and stats, § The
semantic layer, § Shopping list and the status paragraph.

- **The export, tidied first.** Claude Design's screens had landed as
  `<name>@1x (1).png` next to deleted originals. They were moved back to
  their plain names, which code comments and DESIGN_SYSTEM cite. Four
  changed (Recipe, Review import, Dark mode, List offline) and six came back
  byte-identical. `Recipes@1x.png` was restored from git. The new
  `design-system.pdf`, `key-screens.pdf` and the brief went in with the
  code. `app-logo.pdf` and `docs/design/logo/` wait for part 10b.
- **`KitchenColors`** gains `stepConnector` and `dividerDash`, both aliases
  of `outlineVariant` (D118's rule: names, not a second palette).
- **The dashed divider (D129).** `IngredientLineRow`'s `Border(bottom: …)` is
  gone. A private `_DashedLinePainter` (6 on, 4 off, 1dp, butt caps), keyed
  `ingredientDivider`, draws it, on `_DashedRingPainter`'s precedent.
  - **Where it sits differs from the plan.** The slice put it in a
    `Column` below the tinted container. It went *inside* the container
    instead, with the 48dp minimum moved onto the content as
    `target - 1`. Below the container, the flagged tint would have stopped
    1dp short at the edges, and a one-line row's dashes would have sat 3dp
    above the row's 48dp bottom.
  - Inset (and flagged) rows pad the dashes `md` on both sides.
  - The class, `inset` and `showDivider` docs now say "dashed divider".
- **The step timeline.** `_StepRow` takes `isLast` and is an
  `IntrinsicHeight` `Row(stretch)`. The left column, 28dp wide, is the disc,
  then (unless last) a 4dp gap, an `Expanded` centred 2dp `stepConnector`
  keyed `stepConnector`, and another 4dp gap. The text keeps `xl` padding
  below it on every step, including the last, so the old trailing gap is
  unchanged and the line runs through the gap to the next disc. The 2 and
  the 4 are private consts in `recipe_detail_screen.dart`; the 6 and the 4
  in `ingredient_line_row.dart`.
- **The last ingredient on recipe detail** passes `showDivider: false`. Both
  `map`s became indexed `for` loops.
- Import review and the shopping list needed no code change; neither draws
  a divider of its own.

**How it was verified.** `dart analyze` was clean. `flutter test` passed
**709/709** (704 before). New or rewritten tests:

- `ingredient_line_row_test.dart`: the `showDivider` test finds the painter
  by key, checks it paints a line in `outlineVariant` and runs edge to edge,
  1dp tall, and is absent with `showDivider: false`. New: an inset, flagged
  row's divider is padded 12 on both sides while the row stays full width;
  a one-line row is 48dp with the divider's bottom on the row's bottom.
- `recipe_screens_test.dart`: three ingredients draw two dividers; three
  steps draw two connectors; one step draws none. The last two are separate
  tests, because a second `_pumpDetail` in one test reuses the first
  `ProviderScope` and keeps the old detail.
- `shopping_list_screen_test.dart`: **missed by the plan.** The part 5 test
  "every to-buy row draws its hairline…" read `Border.bottom` and failed.
  It now finds the keyed divider per row, with the same three assertions.

`make check` passed lint, tests and Deno tests, then stopped at the
pre-existing `seed-check`. `make test-sql` and `make l10n-check` pass on
their own.

**Walked on the emulator** (`/design-walk recipe-detail`, 2026-09-29,
`make install-emulator`, dev-login account; the Galaxy wasn't attached),
`sr`/`en` × light/dark with the in-app toggles:

- **Palačinke / Crêpes.** The dashes run edge to edge between ingredients,
  with none under `voda`. At full resolution the step line stops short of
  both discs. It stretches through the 4-line step 3 and the 8-line Serbian
  step 5, and there is none below step 7. The line is quiet but visible in
  dark (`#494A3F` on `#16160F`). Nothing truncates or overflows in either
  language.
- **Kajgana / Scrambled Eggs.** A single step draws no line. The unmatched
  `malo ljubavi` ring sits one row under a divider and reads as a different
  thing in both brightnesses: smaller, closed and darker.
- **Prženice / French Toast.** Light, English: the same.

Seen, a nit, left alone: the dash pattern restarts every 10dp from the
left, so on a ~379dp row the last dash ends ~3dp short of the right text
edge while the left end sits on it (the `c2` crop).

**Not walked yet:** `/design-walk shopping-list` and
`/design-walk import-review`. Import review is where the inset dashes and
the flagged tint meeting the divider can be seen. **Opened:** part 10a's
loop, for those two walks.

### Part 10b — App logo

**Status: complete** (`6747f57`). Decisions taken during it: D130.

Item 3 of Claude Design's 2026-09-28 export
(`docs/design/BRIEF_steps_dividers_logo.md`): "bowl on the table", a cream
table with steam and a mustard bowl with a paprika band, on Garden green. No
Dart change, no migration, no ARB key. The logo sources
(`docs/design/logo/`, `docs/design/app-logo.pdf`) went in with the code, as
did `docs/DESIGN_SYSTEM.md`'s launch-screen paragraph and a new § Logo.

- **Android adaptive and themed icons (D130).** New
  `drawable/ic_launcher_foreground.xml` and `ic_launcher_monochrome.xml`,
  108dp on a 108 viewport, with the path data copied from
  `android-adaptive-foreground.svg`. The rects are rewritten as
  rounded-rect paths. VectorDrawable has no mask, so the monochrome bowl is
  a rim (to y 47.25) and a base (from y 50.75), leaving the band as a gap.
  `mipmap-anydpi-v26/ic_launcher.xml` sets the background to
  `@color/splash_background`, whose comment now names the icon too.
- **Launch screen.** Both `launch_background.xml` files add the foreground,
  centred at 288dp, over the green. `values-v31/styles.xml` points
  `windowSplashScreenAnimatedIcon` at the foreground, and
  `splash_icon_none.xml` is deleted. `NormalTheme` stays flat green, and
  there is still no `values-night`.
- **Rasters, from `tool/gen_app_icons.py` (`make icons`).** Headless Chrome
  renders each SVG at 1024 and PIL downsamples it with LANCZOS:
  - `mipmap-{m,h,xh,xxh,xxxh}dpi/ic_launcher.png` (48–192 px) from
    `mark-master.svg`, a rounded square with a 24/108 radius and transparent
    corners;
  - every `AppIcon.appiconset` file its `Contents.json` lists, from
    `ios-appicon-1024.svg`, `convert('RGB')`, so `sips` reports `hasAlpha:
    no` on all 15;
  - `LaunchImage{,@2x,@3x}.png` at 96/192/288 px, from the foreground
    cropped to its alpha bounding box.
- **iOS storyboard.** The view's background goes from white to sRGB
  `#366A35`.

**Where it differs from the plan.**
- **Chrome's colour flag.** The slice's `--default-background-color=0` makes
  Chrome log "Expected a hex RGB or RGBA value" and exit without writing a
  screenshot. The script uses `00000000`. A trial with `--user-data-dir`
  also left Chrome running after the screenshot. The script doesn't pass
  one.
- **The storyboard's image size.** Its `<image name="LaunchImage">`
  resource still declared the old placeholder's 168×185. It now says
  96×96, which the plan didn't mention.

**How it was verified.** `make check` passed all of: `dart analyze`, the
layer check, `flutter test` (**709/709**), the Deno tests (161), the SQL
tests and `l10n-check`. The pre-existing `seed-check` failed, as before.
`xmllint` passed every resource XML and the storyboard.
`make install-hosted` built the release APK and installed it.

The rendered 1024 app icon, the xxxhdpi PNG and the @3x launch image were
opened side by side and look right.

**Walked on the emulator** (API 37, Pixel launcher; the Galaxy wasn't
attached), hosted release build:

- **App drawer.** The icon sits under the circle mask with the steam and
  both legs inside it, and nothing is clipped. The label reads "Kitchen
  Table".
- **Cold start**, after a force-stop, with screencaps taken back to back:
  the green splash with the centred mark, then the recipe list in Light. No
  white frame was caught.

**Not walked:**
- the Samsung squircle (needs the Galaxy);
- themed icons turned on, to see the band read as a gap;
- the other three phone × app Light/Dark cold starts;
- a frame-by-frame look for a mark flicker at the `NormalTheme` hand-off.
  Screencaps are too far apart to catch one. If it flickers, point
  `NormalTheme` at `@drawable/launch_background`.

iOS was not walked (no device). **Opened:** part 10b's loop, for those
four checks.

### Part 11 — Device-feedback polish

**Status: complete** (`da5e198`). Decisions taken during it: D131, D132,
D133.

The user brought seven items from using the app, not a roadmap part. It was
planned in one session with the user (plan mode, not `/plan-slice`), so there
is no `docs/active/` handoff. One item was dropped at planning: the user
re-tested pasting the copied shopping list into Google Keep and it works. No
migration, no ARB key, no new package.

- **Portrait only (D133).** `SystemChrome.setPreferredOrientations` in
  `main()`, `screenOrientation="portrait"` on `MainActivity`, and iPhone's
  `UISupportedInterfaceOrientations` cut to Portrait. The `~ipad` list is
  untouched.
- **Stat strip.** `AppStatStrip` start-aligns each label and value in its
  equal-width column (`Align(centerStart)` instead of `Center`), per
  `Recipe@1x.png`. `DESIGN_SYSTEM.md` § Steps and stats says so.
- **Recipe list photos and translated titles (D131).**
  - `watchList`'s online emission is signed through `_withImageUrls`.
    `_withImageUrlsOrNot` returns the list unsigned on any failure.
  - `Recipe.titleByLocale` is read from the cached translations embed.
    `displayTitle(locale)` drives `RecipeCard`'s title and monogram, and
    `RecipeFilter` matches translated titles.
- **Meal plan (D132).**
  - Each expanded day card ends in one bottom-end `+ Dodaj obrok`.
    `_SlotAddButton` is gone, which also removes the empty-slot drop target.
  - A note entry uses `KitchenType.recipeTitle`.
  - `DESIGN_SYSTEM.md` § Meal entries (Adding, Drag, Entry cards) and the
    screen's doc comments were rewritten.

**Decisions taken with the user at planning.**
- What was wrong with the note tile: the user chose "style like a recipe".
- Dropping drag-into-empty-slot rather than showing drop zones only during a
  drag: the user chose to drop it.

**Tests.**
- Nine meal-plan screen tests assumed the per-slot buttons. They now go
  through an `_addTo(tester, slot)` helper (Add meal, then the chooser).
- The "+ Dinner" drag test is now a drop onto a filled Dinner group.
- New tests:
  - the stat strip's leading-edge alignment;
  - `RecipeCard`'s `en` title and monogram;
  - `RecipeFilter` matching a translated title;
  - `readAll`'s `titleByLocale`;
  - `watchList` signing only the fresh emission;
  - the signing-failure fallback.

**How it was verified.** `dart analyze` was clean and `flutter test` passed
**715/715**. `make check` was not run; its `seed-check` is known red on main.
`make install-emulator` built and installed the hosted release APK.

**Walked on the emulator** (the Galaxy wasn't attached), all four
combinations, sr/light → sr/dark → en/light → en/dark, signed in through
Dev login:

- **Recipe list.** Photos show on Palačinke and Prženice, and Kajgana keeps
  its monogram. In `en` the titles read Scrambled Eggs / Crêpes / French
  Toast (Prženice), with the monogram S. No Serbian truncation. Dark reads
  fine.
- **Recipe detail.** The Porcije / Priprema / Kuvanje / Ocena strip is
  left-aligned, matching the mock, in both languages and both themes.
- **Meal plan.** The Today card shows one `+ Dodaj obrok`/`+ Add meal`
  bottom-right. The breakfast note renders in the serif title face under
  `Doručak · Napomena`.
- **Rotation.** With `accelerometer_rotation 0` and `user_rotation 1`, the
  display stayed at `ROTATION_0`, 1080x2424. Both settings were restored.

The account was put back to Srpski / Svetla. The walk was clean, so no loop
was opened.

**Seen, not fixed.** Meal-plan recipe entries show the original-language
title under `en` (`Kajgana`, `Prženice`), because an entry carries its own
`recipeTitle` embed (D53). This is outside this slice; see D131's
Consequences.

**Also closed in the same sitting.** Phase 5 part 5's paste half, on the
user's own Keep test.

### Part 12 — Sans only, borderless cards, a drag grip

**Status: complete** (`0696cfe`). Decisions taken during it: D134.

This applied Claude Design's round-2 handover (2026-09-30). It went through
the full `/plan-slice` → `/build-slice` → `/design-walk` → `/close-slice`
loop from `docs/active/phase7-sans-borderless-cards.md`. No migration, no
ARB key, and no new package. A package was removed instead: Literata's
three files and the `fonts:` / `assets:` blocks in `pubspec.yaml`.

- **Type (D134, superseding D127's type half).**
  - Every role is the platform sans.
  - `KitchenType` keeps its job, "a recipe's name", now as w700:
    `recipeTitle` 17/24 −0.1 and `recipeTitleLarge` 28/34 −0.3.
  - A new `monogram` (30/36) replaces `recipeTitleLarge` on the 72dp tile.
  - `displaySmall` is 32/40 w700 −0.5 and `headlineSmall` 28/34 w700 −0.3.
- **Cards.** `CardTheme` loses its `outlineVariant` side and fills with the
  new `KitchenColors.card`. It is `surfaceContainer` in light and
  `surfaceContainerHigh` in dark, because dark `surfaceContainer` is
  +5 tone from the ground and vanishes without a border. `AppTheme._build`
  builds the extension once and reuses it for the card colour.
- **Meal plan** (all of it private to `meal_plan_screen.dart`).
  - `_MealEntryCard._card` takes an optional `fill`. The default is:
    - `surface`;
    - `dropTarget` in a hovered slot;
    - transparent for a leftover.
  - The padding drops its end, and the row centres its children
    vertically.
  - A 40dp trailing column holds `Icons.drag_indicator` at 20 in
    `dragHandle`, inside `ExcludeSemantics`.
  - A note's title is `recipeTitle.copyWith(fontWeight: w400)`.
  - The draggable's feedback is `Transform.rotate(−1.5°)` over
    `Transform.scale(1.02)` in the card fill.
  - `childWhenDragging` is an `Opacity(0)` copy under a 1.5dp dashed
    `outline` at 60% alpha.
  - `_SlotGroup` and a collapsed day draw a 2dp dashed `primary`
    foreground while hovered.
  - Collapsed days gain `xs` vertical padding (56dp) and the card fill.
  - `_DashedRoundedRectPainter` gains `strokeWidth`. The six new numbers
    are named `static const`s on `_MealEntryCard`.
- **New tokens.** `KitchenColors.card` / `dragHandle` / `dropTarget`, and
  `AppSizes.grip` (20) / `gripColumn` (40).
- `DESIGN_SYSTEM.md` got these sections:
  - the header;
  - § Content and lines;
  - § Type and its `KitchenType` subsection;
  - § Size and motion;
  - § Elevation;
  - § The semantic layer;
  - § Cards;
  - § Recipe card;
  - § Meal entries, including the Drag paragraph.

  The updated design frames and PDFs went into the same commit.

**Decisions taken with the user at planning.**
- Tap keeps opening the actions sheet. The handover's "tap opens the
  recipe" was read as loose wording.
- A note reads w400.
- All themed cards follow the new `CardTheme`, including the four whose
  frames still show the old border.

**Differs from the plan.**
- The plan asked the theme test to assert `fontFamily == null` on every
  Material role. On a built `ThemeData`, Flutter's typography fills in the
  platform family (Roboto under the test VM), so the test asserts instead
  that every role, `displaySmall` included, shares that one family and that
  it isn't Literata. `KitchenType`'s styles do assert `null`.
- `app_section_heading.dart` still mentions D127 and Literata as history in
  a comment. It was outside the plan's file list.

**Tests.** `app_theme_test.dart`:
- "every role is sans" replaces "sans, bar the wordmark";
- `KitchenType` asserts the new metrics and `monogram`;
- new: cards have no side, with `#F5EBDF` / `#292923` fills;
- `KitchenColors` asserts `card`, `dragHandle` and `dropTarget`.

No meal-plan widget test depended on `Opacity(0.3)` or a card's side.

**How it was verified.** `dart analyze` was clean and `flutter test` passed
**716/716**. `make -k check` was green apart from the known `seed-check`,
including the Deno and SQL suites and the l10n check.

**Walked on the emulator** (the Galaxy wasn't attached). `make
install-emulator` ran with Dev login, sr/light → sr/dark → en/light →
en/dark. Every surface was clean in every combination.
- **Recipe list.** Cards separate from the cream ground without a border
  in both themes. In light they share the nav bar's `#F5EBDF`, and the cream
  gap keeps them apart. The `K`/`S` monogram reads in bold sans.
- **Recipe detail.** The title is bold sans 28.
- **Meal plan, Today and week.**
  - Entries sit on the cream ground inside their day card, with the grip
    centred vertically.
  - The leftover is transparent and dashed, with its title bold.
  - The `Ostaci` note reads regular beside bold recipe names.
  - Collapsed days are 147px (56dp at 2.625), and `+ Dodaj obrok` fits.
- **Drag.** Driven with `input motionevent` (DOWN, a 1.2s hold, then MOVEs):
  - the lifted card showed its tilt and lift over a dashed placeholder;
  - a hovered collapsed day and a hovered filled slot each got the green
    fill and the dashed `primary` outline, which a full-resolution crop
    confirmed in dark;
  - a drop on Thursday landed and kept `Večera`, and a second drag put
    `Kajgana` back on Wednesday;
  - a tap opened the actions sheet.
- **Other surfaces.**
  - Settings, household (the name at 28 w700) and the shopping list, whose
    dashed dividers still read on the darker card fill.
  - Sign-in, where the wordmark is bold sans in `primary` in both themes.

The account was put back to Srpski / Svetla, and the plan was as found.
**Not reached:**
- import review (the user chose not to spend a hosted AI call);
- the household invite card (no active code);
- the Galaxy.

Part 12's loop in `STATE.md` holds those. The same walk also confirmed most
of part 4's meal-plan loop, which `STATE.md` records.

**Seen, not fixed.**
- The signed-out sign-in screen stays Serbian after an in-app switch to
  English.
- Meal-plan entries still carry the original-language title under `en`
  (D53, see part 11).

### Part 13 — Header over the photo, a drag that keeps the meal

**Status: complete** (`6f3336b`). Decisions taken during it: D135.

Two fixes from the user's own use of the app. There was no
`/plan-slice` handoff: the plan was made and approved in one session,
then built, walked and closed in the same one. No migration, no ARB key,
no new package, and no data or RPC change. Both changes reuse what was
already there.

- **Recipe detail: the header sits over the photo** (amends D119).
  - The `Scaffold.appBar` became a pinned, collapsing `SliverAppBar` at
    the top of a `CustomScrollView`. Its `expandedHeight` is width × 9/16.
  - `_PhotoWell` is the `FlexibleSpaceBar` background. It lost its
    `AspectRatio` and kept the placeholder, loading and error behaviour.
  - `_Body` went from a `ListView` to a `SliverPadding` +
    `SliverToBoxAdapter`. Loading and error sit in `SliverFillRemaining`.
  - A local `Theme` gives every icon button in the bar a `surface` disc at
    0.7 alpha (`_overPhotoAlpha`). The automatic back button and the
    `PopupMenuButton` get it without restyling either.
- **Meal plan: a drag never changes an entry's slot** (amends D121).
  - Each entry card is now a `DragTarget` for entries of the same day and
    slot. A drop calls the existing `reorderEntry` with that card's index.
  - The expanded day card is a new target for entries from any other day.
    So is the collapsed day, which now refuses same-day drops. Either one
    calls `moveEntry` with the entry's own slot.
  - `_SlotGroup` is no longer a target.
  - `_moveHere` lost its `slot` parameter. `_MealEntryCard._reorder`
    became a top-level `_reorderTo`, which *Move up/down* share with the
    drop.

**Decisions taken with the user at planning.**
- The drag can also move an entry to another day, in its own slot, not
  only reorder within its slot.
- A collapsing `SliverAppBar` that pins, rather than an overlay that
  scrolls away.

**Differs from the plan.**
- The plan kept `_SlotGroup` as a cross-day target. The build dropped it,
  because the expanded day card's target already covers it, and also
  covers a day with none of that slot.
- The walk found that Light's dark status-bar icons vanish into a dark
  photo. The fix was added in the same session (D135 point 3): light
  icons while a photo is under the status bar, the theme's own icons over
  an empty well or once collapsed.

**Tests.** In `meal_plan_screen_test.dart`'s drag group, "onto a filled
slot's entries moves the entry into that slot" was replaced with:
- onto another slot's entry on the same day changes nothing;
- onto an entry of the same day and slot calls `reorderEntry(e1, 1)`;
- onto another day's expanded card, which has only a dinner, moves the
  breakfast there as breakfast.

The collapsed-day test stays. No recipe-detail test needed changing:
`find.byType(Scrollable).first` holds for a `CustomScrollView`.

**How it was verified.** `dart analyze` was clean and `flutter test`
passed **718/718**. `make check` was not run.

**Walked on the emulator** (the Galaxy wasn't attached). `make
install-emulator` ran with Dev login, sr/light → sr/dark → en/light →
en/dark.
- **Recipe detail.**
  - Prženice (photo) and Kajgana (no photo) both open with the discs
    readable over the photo and over the empty well, in both
    brightnesses.
  - Scrolling collapses to the solid bar, where the discs blend in.
  - `French Toast (Prženice)` under its machine-translation chip fits in
    English.
- **Defect found: the status bar.** In Light the status-bar icons stayed
  dark over the photo, and the clock was barely readable on Prženice's
  dark corner. After the fix, sr/light and en/light were re-walked:
  - light icons over the photo;
  - dark once collapsed;
  - light again when scrolled back;
  - dark over Kajgana's empty well.

  Dark was not re-walked, because its icons were already light.
- **Meal plan.** Driven with `input motionevent` (DOWN, a 1.2s hold,
  then MOVEs):
  - Kajgana dropped on the first of today's three dinners took first
    place. The hovered card showed the green fill and the dashed outline
    over the placeholder, in light and dark.
  - Dropped back on its own placeholder, it changed nothing.
  - In the week view, a drop on Monday's card (the whole card highlights)
    moved it there as `Večera`. Dragged back to Wednesday, it landed last,
    and a reorder put it back in the middle.

The account was put back to Srpski / Svetla, and the plan to its original
order.

**Not reached:**
- a same-day drop onto a different slot (today held only dinners; the
  widget test covers it);
- the Galaxy.

### Part 14 — Positive tracking, a token map (round `sync-design-initial`, slice 1)

**Status: complete** (`3f33e44`). Decisions taken during it: D136.

The first slice of design round `sync-design-initial`
(`docs/design/handoffs/2026-10-02-sync-design-initial/`, the first round
through `/design-handoff`). The round's bundle is a recreation of the app
as it is on `main`, so its token delta was small. Out of about 100 values,
only three changed, and each changed only in sign: the w700 roles' letter
spacing is positive in the bundle and was negative in the app. Planned in
one session, then built in a fresh one. No migration, no ARB key,
no new package, and no screen code changed.

- **Tracking flipped** (amends D134's values).
  - `app_theme.dart` `_textTheme`: `displaySmall` −0.5 → **0.5**, and
    `headlineSmall` −0.3 → **0.3**.
  - `kitchen_type.dart`: `recipeTitle` −0.1 → **0.1**, and
    `recipeTitleLarge` −0.3 → **0.3**. `monogram` stays 0.
  - The meal-plan note picks up 0.1 through its `copyWith(fontWeight:
    w400)`. That is intended, because a note has the same metrics as
    `recipeTitle`.
  - The four expectations in `app_theme_test.dart` follow.
- **`DESIGN_SYSTEM.md`.**
  - § Type's two tables show the new values.
  - A new **§ Token map** sits between § Elevation and § The semantic
    layer. It pairs every bundle CSS token with its Flutter symbol, by
    name only, so `/design-handoff` can diff the next round by name.
  - § How to read this gains one line pointing at it.

**Decisions taken with the user at planning.**
- The bundle's positive tracking is intended, not an export error. The
  round's `ROUND.md` had guessed the export dropped the minus.
- No `AppSizes.tag`. No code draws a 32dp tag, so `--size-tag` maps to
  nothing, and the number stays in `AppSizes.chip`'s doc comment.

**Differs from the plan.** One small addition: the pointer line in
§ How to read this. That section lists three layers and is not a contents
list, so a one-line pointer was the closest fit to the plan's "add a line
if it has one".

**How it was verified.**
- `dart analyze` was clean, `flutter test` passed **718/718**, and
  `deno test` passed 161/161.
- `make check` stopped at `seed-check`, the known red on `main` since
  `c8be2bc`. Its remaining targets, `test-sql` and `l10n-check`, were run
  by hand and passed.
- `grep -rn 'letterSpacing: -' lib/core/theme` returns nothing.

**Walked on the emulator** (`/design-walk recipe list`, 2026-10-02, the
only device attached). `make install-emulator` ran with Dev login,
sr/light → sr/dark → en/light → en/dark, on the four surfaces the
tracking reaches:
- **Recipe list.** *Domaći čorbasti pasulj sa dimljenom slaninom* and
  *Losos iz rerne — najjednostavnija varijanta* still wrap to two lines on
  their cards, with nothing ellipsized.
- **Recipe detail.** The 28 title wraps to two lines under the expanded
  photo. Collapsed, the bar shows no title, which is D135's design.
- **Meal plan.** Today's two-line entry title breaks after "dimljenom",
  as before. The note "Ostaci" is at w400. In the week view the leftover
  *Ostaci: Palačinke* / *Leftovers: Palačinke* fits on one line.
- **Household.** *Renamed Household* at 28 fits on one line beside the
  edit button.

Dark was readable throughout, including `onSurfaceVariant` meta lines and
the leftover's dashed border. The account was put back to Srpski / Svetla.
The walk was clean, so the slice opened no loop.

**Not reached:**
- the wordmark, which is only on the signed-out sign-in screen, and the
  walk did not sign out;
- the Galaxy.

### Part 15 — Onboarding per the design (round `sync-design-initial`, slice 2)

**Status: complete** (`04b56d0`). Decisions taken during it: D137.

The second slice of design round `sync-design-initial`
(`docs/design/handoffs/2026-10-02-sync-design-initial/`), frames 01–03:
sign-in, create household, join household. The user chose "do per
design" on all three open questions, over the shipped calls in D124 and
D126. Planned with `/plan-slice-ui`, built in a fresh session, walked in
the same one. One new ARB key (`inviteCodeFieldLabel`), no migration, no
new package. One `flutter: assets:` entry was added.

- **Brand images** (`tool/gen_app_icons.py`, `make icons`). Four new
  outputs go into `assets/brand/` at 1x / 2.0x / 3.0x:
  - `mark.png`: the Android legacy rounded mask, factored into
    `rounded_tile()` and shared with `android_legacy`.
  - `lockup_light.png` and `lockup_dark.png`: the new `render_inline()`
    puts the SVG into a page that links Literata 600 from Google Fonts.
    The script drops the opaque background, crops left/right to the
    content, and scales to 48 tall.
  - `google_g.png`: from Google's sign-in assets zip. The untouched SVG is
    committed under `docs/design/google/`. The script removes the tile and
    sets `viewBox` to the G. It is inlined because the gradient is a
    `<foreignObject>`.

  The existing Android/iOS outputs came out byte-identical. The script
  needed `from __future__ import annotations`, because this Mac's Python
  is 3.9.
- **Sign-in.**
  - `SignInIllustration` is a `CustomPainter` in a 176 × 139 unit box,
    drawn back to front: the back card in `primaryContainer`, the front
    card in `surfaceContainerLow` with an `outlineVariant` edge, the title
    bar, rule and lines, a `tertiary` tomato and a `primary` sprig. It was
    matched by eye against `bundle/assets/recipe-card-reference.png`. That
    file was added during planning, cropped from `docs/design/key-screens.pdf`.
  - Then the lockup at `AppSizes.lockup`, and the `bodyLarge` tagline.
  - The Google button is now an `OutlinedButton.icon`: lowest fill,
    `outline` side, `onSurface` label, with the G at `iconInButton`.
  - The dev-login button is unchanged.
- **Create / join.** Both are top-aligned and start-aligned.
  - `OnboardingMark` (56dp, in `households/presentation/`), a
    `headlineSmall` title, a `bodyLarge` subtitle, the field.
  - The filled button, `sm`, and a full-width `TextButton` are pinned to
    the bottom by `SliverFillRemaining(hasScrollBody: false)` and a
    `Spacer`.
  - The join code gains `AppFieldLabel` (`Pozivni kod` / `Invite code`).
    Its field behaviour is unchanged.
- **`AppSizes`.** It gains `signInIllustration` 176, `lockup` 48 and
  `onboardingMark` 56.
- **`DESIGN_SYSTEM.md`.** Updated § Type, § Size and motion, § Buttons,
  § Action bar, § Inputs, § Logo and § Token map.
- **Tests.**
  - `sign_in_screen_test.dart`: the lockup asset per brightness, the
    button's fill and side, and "exactly one `OutlinedButton`" without dev
    login.
  - New `onboarding_screens_test.dart`: a `headlineSmall` start-aligned
    title, the buttons pinned with no scroll at 360 × 760, the keyboard
    case, and join's label.

**Differs from the plan.**
- **The skeleton's `SliverPadding` was a bug.** `SliverFillRemaining`
  fills the remaining viewport and ignores trailing padding, so the
  bottom `xxl` landed below the fold and the screen scrolled by 32. The
  padding moved inside `SliverFillRemaining` as a `Padding`.
- **The plan's pin test couldn't pass.** It asked for the filled button
  within `xxl` of the bottom, but the text button sits under it. The test
  now asserts that the text button's bottom is exactly `xxl` above the
  screen's, that the filled button sits `sm` + 48 above that, and that
  `maxScrollExtent` is 0. It fails on the plan's skeleton.
- **A keyboard-open widget test was added** (300px inset, no overflow, the
  buttons scroll into reach), because the emulator could not open a full
  keyboard.

**How it was verified.**
- `dart analyze` was clean, `flutter test` passed **727/727**, and
  `deno test` passed 161/161. `test-sql` passed.
- `make check` stopped only at `seed-check`, the known red since
  `c8be2bc`.
- `l10n-check` passed once the regenerated files were committed. It
  compares against git, so it is red until then.

**Walked on the emulator** (`/design-walk onboarding`, 2026-10-02, the
only device attached). `make install-emulator` ran with Dev login,
sr/light → sr/dark → en/light → en/dark.
- **Sign-in** was reached by signing out.
  - Illustration, lockup and tagline are centred. The Serbian tagline
    wraps evenly over two lines. The G and the lockup are crisp.
  - In dark, sampled off the screenshot: surface `#16160F`, button fill
    `#101007`, border `#96978A`, lockup text `#9ED498`, illustration bar
    `#CFD0C2`. There is no box behind any image.
  - It stays Serbian after an in-app switch to English (D77, known).
- **Create / join** were reached by having `test-user` (a member, not the
  owner) leave `Renamed Household` and rejoin by invite code, once per
  combination. That ran the real redeem three times. Codes are
  single-use, so the owner's active `770578` was consumed.
  - Every title fits on one line, and `Napravi domaćinstvo umesto toga`
    fits on one line.
  - The buttons are pinned, and the mark's transparent corners sit
    cleanly in dark.
  - A wrong code shows `Taj kod nije važeći.` in pink under the field.

The account ended back in the household (2 members), on Srpski / Svetla.

The walk was clean. It closed part 7's onboarding loop and part 8's
create/join item, and opened this slice's own loop.

**Not reached:**
- the keyboard-open state on a device: the emulator's Gboard stays in its
  stylus toolbar, so the widget test covers it for now;
- the Google button's busy spinner and a real Google sign-in through it,
  which need the Galaxy.

### Part 16 — Recipe list per the design (round `sync-design-initial`, slice 3)

**Status: complete** (`3812981`). Decisions taken during it: D138.

The third slice of design round `sync-design-initial`
(`docs/design/handoffs/2026-10-02-sync-design-initial/`), frames 04–06:
recipes with filters on, no results, and the add menu. The bundle recreates
`main`, so the search field, the filter row with its Clear chip, the cards
and the strings already matched. The user settled three calls during
planning (2026-10-02): the app-bar `+`, the carded empty state, and the
always-on count. Planned with `/plan-slice-ui`, built in a fresh session.
No ARB key, no migration, no new package.

- **Add menu** (`recipe_list_screen.dart`). The FAB is gone. `AppBar.actions`
  holds the `MenuAnchor`, whose builder is an `IconButton` (`Icons.add`,
  tooltip `Dodaj recept` / `Add a recipe`). The four `MenuItemButton`s moved
  over unchanged, leading icons included. `floatingActionButtonTheme` stays
  as a guard.
- **Spacing.** Search 4 under the app bar, 12 to the chips, 16 to the
  count, 12 between items, 24 at the bottom. `_FilterRow` lost its own
  `bottom: sm` padding, and the separator is `md` everywhere (the
  "narrowed and i == 0" case is gone).
- **Result count.** It is always item 0 of a non-empty list, in
  `bodyMedium` / `onSurfaceVariant` (was `bodySmall`, narrowed only).
- **`AppEmptyState(card: true)`.** The same column on a `KitchenColors.card`
  `DecoratedBox`, radius 12, inset `lg`, padded `xxl` / `xl`, still inside
  a `ListView`. The bare and card paths share one `_content` column; the
  bare path renders as before. Only the recipe list opts in, for both its
  empty states.
- **`menuButtonTheme`** (`app_theme.dart`): `bodyMedium` text style only.
- **`DESIGN_SYSTEM.md`.** Updated § Type (`bodyMedium` row), § Buttons ("No
  FAB"), § Chips (the count), § Menu, snackbar, banner (item text, the kept
  icons) and § Empty state (the card variant).
- **Tests.**
  - `recipe_screens_test.dart`: the count test now asserts `2 recipes`
    unfiltered and `1 recipe` on `Posno`. A new test asserts no
    `FloatingActionButton`, the `Add a recipe` `IconButton` inside the
    `AppBar`, and the four labels after a tap.
  - `app_empty_state_test.dart`: a `card: true` case, a `DecoratedBox` in
    `KitchenColors.card` above the title.

**Seen in the bundle, not adopted.** Frames 04–05 show multi-select tags
(`Favorites` + `Lenten`, `Cakes` + `Lenten`). That is a change to the
provider and the repository, so D102's single tag plus a Favorites toggle
stands (D138).

**Differs from the plan.** Nothing in substance. `dart format` on the
screen also re-indented two lines unrelated to the slice; they were put
back. `unnecessary_underscores` flagged `(_, __)` in the separator builder,
which became `(_, _)`.

**How it was verified.**
- `dart analyze` was clean, `flutter test` passed **729/729**, and
  `deno test` passed 161/161. `test-sql` and `l10n-check` passed.
- `make check` stopped only at `seed-check`, the known red since
  `c8be2bc`. The targets after it were run by hand.

**Not walked.** `/design-walk recipes` has not run yet, so this slice opens
its own loop. Still to check on a device: where the menu sits under the `+`
(the `alignmentOffset` was left at its default), `Fotografiši stranicu` on
one line, the count's Serbian plural on the real household, the card
against the ground in light and dark, and the last card's 24 of clearance
over the nav bar.

### Part 17 — Recipe detail per the design (round `sync-design-initial`, slice 4)

**Status: complete** (`696c887`). Decisions taken during it: D139.

The fourth slice of design round `sync-design-initial`
(`docs/design/handoffs/2026-10-02-sync-design-initial/`), frame 07. The
bundle recreates the screen as `main` had it after part 13 (D135), so the
photo header, title, ingredient rows, step timeline and stars already
matched. Six things differed and were adopted. The user settled three of
them during planning (2026-10-02): the servings trailer, the source line and
the photo-bar discs. Planned with `/plan-slice-ui`, built in a fresh session.
No migration, no new package.

- **Photo-bar discs** (`recipe_detail_screen.dart`). They are opaque
  `surface` with `onSurface` icons, where they were `surface` at 0.7 alpha.
  `_overPhotoAlpha` is gone. No `minimumSize`: the local
  `IconButtonThemeData` replaces the app's whole style, so each button is
  M3's 40dp disc in a padded 48dp target, which is the frame's disc. A
  non-favourite heart inherits `onSurface`.
- **Tonal `AppBadge`.** `AppBadge` gains `tonal` (a `surfaceContainerHighest`
  fill, no border) and `leading` (laid out at `iconInMeta`, `xs` before the
  label). Machine translation is a tonal badge with a `language` icon, not
  a `Chip`. The translating spinner is the same badge with the spinner as
  its leading and a new label, `Prevodi se…` / `Translating…`. Draft and
  `RecipeCard`'s badge render as before.
- **Stat strip** (`app_stat_strip.dart`). Labels are `bodyMedium`, values
  `titleMedium` (the call site dropped its explicit w600), the minimum value
  box is one `titleMedium` line (24), and the padding inside the hairlines
  is `lg`. The columns still abut.
- **`AppSectionHeading(trailing:)`.** An optional string at the right, in
  `bodyMedium` `onSurfaceVariant`, baseline-aligned, with an `sm` gap after
  the `Expanded` title. Without it the output is the bare `Text` it was. The
  detail passes `ingredientsForServings` when servings is set: `za 2
  porcije` (accusative after `za`) / `for 2 servings`.
- **Source footer.** One `Text`: a lead-in by `source_type` (`Uvezeno sa
  linka` / `Uvezeno sa fotografije` / `Izvor`), ` · `, then the attribution,
  or the URL's host with `www.` stripped (`_sourceHost`, raw URL if no
  host). All muted `bodySmall`, host included. The gap above its divider is
  `xxl`.
- **ARB.** Five keys: `translatingBadgeLabel`, `ingredientsForServings`,
  `sourceImportedFromLink`, `sourceImportedFromPhoto`, `sourceLabel`.
- **`DESIGN_SYSTEM.md`.** § Steps and stats (the strip), § Type (stat values
  and labels, the badge), and a paragraph under § The shared widgets on
  `AppBadge`'s two looks and `AppSectionHeading`'s `trailing`.
- **Tests** (`recipe_screens_test.dart`): the trailer present at 8 and
  absent with no servings; `Imported from a link · kuvajmo.rs` as one
  `Text`; an attribution replacing the host; Machine translation with an
  `AppBadge` ancestor and no `Chip`. The five-stars-at-360dp test is
  unchanged and green.

**Seen in the frame, not adopted.**
- The frame's 184dp header: D135's 16:9 stays.
- The 32dp `image` placeholder: it stays `image_outlined` at
  `AppSizes.icon`, since there is no 32 token.
- A `favorite`-coloured outline heart when not a favourite.
- 32 above / 16 below the Steps heading, 4 below Ingredients: § Spacing's
  24 and `AppSectionHeading`'s `sm` stand.
- The description→stats gap of 20 (not a token); it stays `lg`.
- `IngredientRow`'s 10dp padding and 16dp name/amount gap:
  `IngredientLineRow` is shared, and § Ingredient lines stands.
- The 12dp column gap in the stat strip: at 360dp it would shrink the stars.
- No tag chips in the frame's recipe: not evidence they should go.

**Differs from the plan.**
- The plan asked for an `@` description on each new key in both ARBs.
  `app_en.arb` carries none (Serbian is the template, D77), so the
  descriptions went into `app_sr.arb` only.
- The `sm` gap between the heading and its trailer was not in the plan. It
  keeps a long Serbian heading from touching the trailer.

**How it was verified.**
- `dart analyze` was clean, `flutter test` passed **734/734**, and
  `deno test` passed 161/161. `test-sql` passed.
- `make check` stopped only at `seed-check`, the known red since
  `c8be2bc`. The targets after it were run by hand.
- `l10n-check` passed with the regenerated files staged. It compares
  against git, so it is red until they are committed.

**Walked on the emulator** (`/design-walk recipe-detail`, 2026-10-02, the
only device attached), on the same code before commit. `make
install-emulator` ran with Dev login, sr/light → sr/dark → en/dark →
en/light. Recipes: Losos (photo, URL import, 2 servings), Kajgana (no
photo, no servings, an unmatched line, a machine English translation), and
the footers of all five.
- The opaque discs read over the photo in both brightnesses. When collapsed
  they blend into the bar, and the status-bar icons flip back.
- `za 2 porcije` / `for 2 servings` sits on the heading's baseline. Kajgana
  shows no trailer.
- `Porcije`, `Kuvanje`, `Ocena` each fit one line. The five stars have
  separate 42px targets inside the rating column, read off `uiautomator`
  rather than tapped, to avoid writing a rating on hosted.
- The tonal `Machine translation` badge is legible in both brightnesses, and
  its fill shows against `#16160F`.
- The footer is one line: `Uvezeno sa linka · chatgpt`, `… · Aleksandra,
  Recepti.com`, `Imported from a link · chatgpt`.
- With the phone in night mode the app stayed light under `Svetla`.

The account ended on Srpski / Svetla.

**Not reached:** `Uvezeno sa fotografije · …`, because no hosted recipe is
an OCR import, and `Mašinski prevod` in the badge, because nothing is
machine-translated *into* Serbian. Part 17's loop holds those two only.
(Kajgana's note `po ukusu` stays Serbian under English. Notes are not
translated; this is not new.)
