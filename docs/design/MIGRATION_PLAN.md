# Phase 7 redesign — migration plan

How the Garden design in `docs/design/` gets applied to the Flutter app, in
order, without changing what the app does.

`docs/DESIGN_SYSTEM.md` holds the *system* — colours, type, tokens,
components. This file holds the *plan* — what maps to what, what fights, what
is missing, and the slice order. It is scaffolding: delete it when Phase 7
closes.

**Ground rules, unchanged from `docs/ROADMAP.md` § Phase 7.** Presentation
only. No migration, no Edge Function, no `supabase/` change, no new route, no
new provider, no data-layer touch. If a part appears to need one, that is a
different slice and gets named as one. Every part is walked on the physical
device in `sr` × `en` × light × dark.

**Decisions already taken** (2026-09-25, with the user):

1. Literata is bundled as `.ttf` under `assets/fonts/` — no new package.
2. `docs/DESIGN_SYSTEM.md` absorbs `docs/DESIGN.md`; DESIGN.md is reduced to a
   pointer and every live reference updated.
3. The sign-in illustration is not ported — wordmark, tagline, button.
4. Recipes (list + detail) is the first surface after the token slice.

---

## 1. Screen mapping

| Design reference | Flutter screen | What the screen needs |
|---|---|---|
| `Sign in` | `features/auth/presentation/sign_in_screen.dart` | wordmark in `displaySmall`, tagline, 52dp outlined Google button |
| `Recipes` | `features/recipes/presentation/recipe_list_screen.dart` | cards replace `ListTile` + `Divider`; monogram tile; non-splitting meta row; heart; `Draft` badge |
| `Recipe` | `features/recipes/presentation/recipe_detail_screen.dart` | photo well even with no photo; 4-column stat strip; hairline ingredient rows; tonal step discs; source footer |
| `Plan — week` | `features/meal_plan/presentation/meal_plan_screen.dart` | day cards; today outlined + pill; nested entry cards; dashed leftover; `+ Slot` buttons |
| `List — offline, document in SR` | `features/shopping_list/presentation/shopping_list_screen.dart`, `core/net/offline_banner.dart` | calm banner; segmented range bar; category headings; document-language tag |
| `Review import` | `features/import/presentation/import_review_screen.dart` | summary card with progress bar; flagged rows; bottom action bar |
| `Household` | `features/households/presentation/household_screen.dart` | monogram avatars; invite card; tonal "Copy code"; destructive text rows |

### What lands globally, through the theme

All of this is `lib/core/theme/` and every screen inherits it without being
edited:

- both `ColorScheme`s written out in full — `fromSeed` and the seed constant
  are deleted
- `TextTheme` on Literata, with explicit line heights
- `scaffoldBackgroundColor`, `surfaceTintColor: Colors.transparent`
- new token classes `AppRadii`, `AppSizes`, `AppDurations` beside `AppSpacing`
- `KitchenColors`, the app's first `ThemeExtension`
- component themes that **do not exist today**: `CardThemeData`,
  `NavigationBarThemeData` (the primary pill is not the M3 default),
  `DialogThemeData`, `SnackBarThemeData`, `BottomSheetThemeData`,
  `MenuThemeData` / `PopupMenuThemeData`, `SegmentedButtonThemeData`,
  `DividerThemeData`, `TextButtonThemeData`, `OutlinedButtonThemeData`,
  `IconButtonThemeData`
- rewrites of the five that do: `AppBarTheme` (64dp, Literata title),
  `ChipThemeData` (40dp, radius 8), `InputDecorationTheme` (52dp, 2dp primary
  focus ring), `FilledButtonThemeData` (48dp minimum, stadium),
  `ListTileThemeData`

### Reusable components to create or modify

| Widget | Home | Why there | First needed by |
|---|---|---|---|
| `AppBadge` | `core/widgets/` | label in a hairline outline; knows no subject | slice 2 |
| `AppMetaRow` / `AppMetaItem` | `core/widgets/` | the wrapping meta row — **this is the fix for the Serbian defect** | slice 2 |
| `AppMonogramTile` | `core/widgets/` | an initial on a tonal tile, at a given size | slice 2, reused slice 7 |
| `AppStatStrip` | `core/widgets/` | label-above-value columns | slice 2 |
| `AppSearchField` | `core/widgets/` | the stadium search box; two consumers today — the recipe list and `recipe_picker_sheet.dart` — and the one place the Literata-in-the-search-box defect gets fixed | slice 2 |
| `AppFieldLabel` | `core/widgets/` | promote `recipe_edit_screen.dart`'s private `_FieldLabel` | slice 6 |
| `RecipeCard` | `core/recipes/widgets/` | knows what a recipe is; second consumer is `recipe_picker_sheet.dart` (D53's precedent) | slice 2 |
| `IngredientLineRow` | `core/ingredients/widgets/` | read-only sibling of `ingredient_line_field.dart`; detail and import review both need it | slice 2, reused slice 5 |
| `AppEmptyState` | `core/widgets/` | **modify** — 48dp icon, tonal action | slice 1 |
| `AppSectionHeading` | `core/widgets/` | **modify** — `titleMedium` is now 18 and Literata | slice 1 |
| `OfflineBanner` | `core/net/` | **modify** — calm surface instead of `errorContainer` | slice 1 |
| `MealEntryCard`, `LeftoverEntry`, `EmptySlot` | feature `presentation/` | meal-plan-shaped, one consumer | slice 3 |
| `DocumentLanguageTag` | feature `presentation/` | shopping-list-shaped, one consumer | slice 4 |

`lib/core/widgets/placeholder_screen.dart` is dead — no route builds it. Delete
it in slice 1.

### What stays screen-specific

Layout, and only layout: the recipe card's internal arrangement, the detail
screen's section order, the meal plan's day/slot structure, the shopping list's
grouping and collapsed staples, the import summary card, the household invite
card. No screen gains a provider, a repository call or a route.

---

## 2. Where the design fights the app

1. **The offline banner contradicts itself inside the export.** The colour
   sheet labels `errorContainer` "offline banner", but the semantic layer
   defines `offline`/`onOffline` as `surfaceContainerHighest`/`onSurface`
   ("calm, not red"), the component sheet says the same, and the `List` mock
   renders it grey. **Resolved: calm**, three sources to one. The banner stays
   where it is — above the tab body in `AppShell`, one instance for all four
   tabs. The mock shows it inside a screen only because it mocks a screen.
2. **Favourite and rating both use a star today.** `recipe_list_screen.dart`
   draws `Icons.star` for favourite *and* `★ n` for rating in the same row.
   The design reassigns **heart = favourite, stars = rating**. Both have to
   change together or the signals collide.
3. **Rating is interactive; the design draws it as a stat.** The mock shows
   four filled and one outline star under a "Rating" column head. Keep the tap
   behaviour, including re-tap-to-clear; take only the styling.
4. **The meal plan design drops affordances the app has.** It shows each day as
   a card holding only its filled slots, plus `+ Breakfast`-style buttons. The
   app renders all four slots always and supports drag-and-drop between them
   (`DragTarget` / `LongPressDraggable`), a drop-target highlight, and a
   per-entry sheet (open / cooking for / plan leftovers / move to / move up /
   move down / remove). **All of it stays.** The genuine fight: in the design's
   layout an empty slot has no row to drop onto, so either the `+ Slot` buttons
   become drop targets or the day card accepts a drop and infers the slot.
   Settle this while planning slice 3 — it is the only structural risk in the
   phase.
5. **The recipe list loses its dividers and gains 72dp tiles.** `_RecipeTile`
   is a `ListTile` inside a `ListView.separated`; it becomes a card in a padded
   `ListView`. Behaviour is unchanged — tap opens the detail, and there is
   still no in-place favouriting.
6. **Detail shows a photo well even with no photo.** Today the hero is omitted
   entirely when `imageUrl == null`. Visual change only.
7. **"Discard this import" appears on a *successful* review.** The app offers
   dismissal only from the `_Failed` state. Either wire the existing dismiss
   path into `_ReviewBody` or drop the button — a new server call would break
   the presentation-only rule.
8. **The design omits things that must survive.** The owner-only "Delete
   household" row (D116) and the member overflow menu on `Household`; the
   `Today` view on `Plan` (the mock shows the toggle, not the view); the app
   bar overflow on `Recipe`. Absence from a mock is not a removal.
9. **Nav icons drift.** The design's List tab is a plain list glyph and
   Settings is sliders; the app uses `checklist` and `settings`. Cosmetic —
   follow the design.
10. **Category headings are new on the shopping list.** `groupByCategory`
    already orders items by category, but the screen renders no headings. The
    design draws them in `titleMedium` inside the list card. No new data.
11. **The document-language tag needs new strings.** `ShoppingList.locale`
    already exists in the domain model and nothing reads it, so the tag itself
    is presentation-only — but `SR` / `This list is in Serbian` are new ARB
    keys on both sides (template is `app_sr.arb`; Serbian is the source).

---

## 3. App states the design never shows

The export covers seven happy paths. These have to be derived from the system
rather than copied, and each one is a place where a redesign silently regresses
if nobody looks:

- **Universal** — loading (spinner, and `LinearProgressIndicator` over stale
  data), `AppErrorView` bodies, pull-to-refresh, every `SnackBar` in context,
  every `AlertDialog` beyond the single destructive example, and all four
  bottom sheets (recipe picker, ingredient picker, meal-slot picker, meal-entry
  actions).
- **Recipe list** — empty-no-recipes, empty-narrowed-by-search, search active
  with a clear button, tag labels degraded to as-typed while
  `tagLabelsProvider` is pending.
- **Recipe detail** — `Draft` badge, the translating spinner chip, a broken or
  still-loading photo, empty ingredients, empty steps, unit catalog not yet
  loaded (units render as raw codes, deliberately), the unmatched-line tooltip.
- **Whole screens with no reference at all** — the recipe editor (the app's
  longest form), translation review, the three import entry forms, the import
  job's `Queued` / `Reading` / `Failed` / `AlreadySaved` states, settings,
  create household, join household, and sign-in's error and in-progress states.
- **Meal plan** — the `Today` view, drag in progress, drop highlight, several
  entries in one slot, note entries, the saved-copy line, and the servings /
  move / leftover / repeat-advisory dialogs.
- **Shopping list** — nothing-to-buy, staples expanded, the date-range picker,
  items with no quantity, items with unmatched raw lines.
- **Household** — the delete-household row, the member overflow, the rename
  dialog, three confirmations, invites loading / empty / failed.
- **Language coverage** — the brief asked for Serbian mockups; only the
  shopping list's *document* is Serbian. There is **no Serbian mock of the
  recipe card meta row**, which is exactly the component whose English-only fit
  is the confirmed live defect. The device walks carry that weight instead.

---

## 4. Slice order

Seven slices, each a full `/plan-slice-ui <name>` → `/clear` →
`/build-slice <name>` → `/close-slice <name>` loop. Each is independently
shippable and leaves the app working. Only slice 1 is ordered; 2–7 can be
resequenced freely.

### Slice 1 — `phase7-tokens`

The design system itself, and nothing else.

- `lib/core/theme/app_theme.dart` — both schemes explicit, `TextTheme` on
  Literata, every component theme from § 1.
- new `app_radii.dart`, `app_sizes.dart`, `app_durations.dart`,
  `kitchen_colors.dart`.
- `assets/fonts/Literata-{Regular,SemiBold}.ttf` + `OFL.txt`, and the `fonts:`
  and `assets:` blocks in `pubspec.yaml` (both currently commented out;
  `assets/` does not exist yet).
- `offline_banner.dart` calm; `AppEmptyState` and `AppSectionHeading` retuned;
  `placeholder_screen.dart` deleted.
- Docs: `docs/DESIGN.md` reduced to a pointer at `docs/DESIGN_SYSTEM.md`, and
  the live references updated — `CLAUDE.md`'s Finding-context table,
  `.claude/commands/plan-slice-ui.md` (7 mentions), `plan-slice.md`,
  `design-walk.md`, `docs/ROADMAP.md`, `docs/STATE.md`,
  `docs/design-brief.md`, and the doc comment in `app_theme.dart`.
  `docs/journal/**` and `docs/decisions/D117-*` are history — leave them.
- A new decision amending D117: the theme no longer derives from a seed, both
  schemes are explicit, and D117's dark `tertiary` override is superseded by
  the palette.
- `test/core/theme/app_theme_test.dart` asserts today's values and gets
  rewritten against the new ones; `core/router/app_shell_test.dart` may notice
  the nav bar.

**This slice changes every screen at once** — palette and typeface — with no
layout work. That is the point: it is the cheapest place to discover that
something became unreadable.

### Slice 2 — `phase7-recipes`

`recipe_list_screen.dart` and `recipe_detail_screen.dart`, plus `AppBadge`,
`AppMetaRow`, `AppMonogramTile`, `AppStatStrip`, `RecipeCard` and
`IngredientLineRow`. Fixes the meta-line defect and the heart/star collision.
Folds in the Phase 6 1a / 1b / 2 device walks.

### Slice 3 — `phase7-meal-plan`

`meal_plan_screen.dart` (764 lines) — day cards, today card, nested entry
cards, dashed leftovers, `+ Slot` buttons. Settle § 2.4 (drop targets) during
planning, not during the build. Both views; drag intact.

### Slice 4 — `phase7-shopping-list`

`shopping_list_screen.dart` — segmented range bar, category headings, document
card, collapsed staples, the `docLanguage` tag and its new ARB keys, and the
untranslated-strings defect recorded in `docs/STATE.md` (the generated-at line,
"Probably have (N)" and "Cupboard staples" render in English under a Serbian
UI). Folds in the Phase 5 part 5 walk.

### Slice 5 — `phase7-import-review`

`import_review_screen.dart` — summary card with the matched progress bar,
flagged rows on `reviewMarker`, bottom action bar, and all four job states
(the design covers one). Reuses `IngredientLineRow`.

### Slice 6 — `phase7-forms`

The form vocabulary applied once, across `recipe_edit_screen.dart`,
`translation_review_screen.dart`, the three import entry screens, and both
onboarding forms: `AppFieldLabel`, 52dp fields, labels above, consistent bottom
save bars. Folds in the Phase 5 part 6 walk.

### Slice 7 — `phase7-auth-household`

`sign_in_screen.dart` (wordmark, tagline, 52dp Google button, no illustration),
`settings_screen.dart`, `household_screen.dart` (monogram avatars, invite card,
tonal copy button, destructive text rows — keeping the delete-household row and
the member overflow). Folds in the Phase 6 3b / 3c walks, which need a second
Google account and a throwaway household.

**On the open device walks.** `docs/STATE.md` lists eight. Each is folded into
the slice that touches its surface rather than walked separately —
`docs/ROADMAP.md` § Phase 7 asks for exactly that, and every slice already puts
someone on the device in both languages and both brightnesses.

---

## 5. Verification, per slice

1. `dart run build_runner build -d` if anything generated changed, then
   `dart analyze` — clean before anything else.
2. `flutter test` — 584 today. The widget tests that assert structure this work
   changes: `core/theme/app_theme_test.dart` and `core/router/app_shell_test.dart`
   (slice 1), `features/recipes/recipe_screens_test.dart` (2),
   `features/meal_plan/meal_plan_screen_test.dart` (3),
   `features/shopping_list/shopping_list_screen_test.dart` (4),
   `features/import/import_review_screen_test.dart` (5),
   `features/recipes/recipe_edit_screen_test.dart` and
   `translation_review_screen_test.dart` (6),
   `features/households/household_screen_test.dart` (7). A test that asserts a
   colour or a widget type is updated with the redesign, not worked around.
3. `make check` — green except `seed-check`, red on `main` since `c8be2bc` for
   an unrelated reason (`docs/STATE.md`).
4. `dart run tool/check_layers.dart` — the layering wall is untouched by every
   slice here. If it trips, something has gone wrong.
5. `make install-hosted` on the physical Galaxy, then `/design-walk <surface>`
   — `sr` × `en` × light × dark. Nothing truncates, wraps badly or overflows in
   Serbian; nothing is unreadable in dark. This is the only check that catches
   the failure mode this phase is most likely to produce, and CLAUDE.md is
   explicit that the emulator, `flutter run` and the local stack do not count.
6. `/close-slice <name>` — journal, decisions, `docs/ROADMAP.md`,
   `docs/STATE.md`.

`make test-sql` and the Deno suite stay out of scope throughout: no slice here
touches `supabase/`.
