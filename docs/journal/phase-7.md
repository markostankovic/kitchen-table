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
