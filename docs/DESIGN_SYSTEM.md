# Design system — Garden

The app's visual language, stated as values and rules. Derived from the Claude
Design export in `docs/design/` (`design-system.pdf`, `key-screens.pdf`, and
the seven screen references under `docs/design/screens/`), which is the visual
source of truth for the Phase 7 redesign.

**Status.** This file describes **the code**. Phase 7 part 2 (D118) landed
the tokens: both `ColorScheme`s, the type scale, `AppRadii`,
`AppSizes`, `AppDurations` and `KitchenColors` are in
`lib/core/theme/` as written here. The 2026-09-28 design fixes round
(`docs/design/BRIEF_design_fixes.md`, Claude Design's updated
`design-system.pdf` and screens) is part of the source too: part 9a (D127)
moved the type to sans with serif recipe titles only, flipped the ingredient
row and lightened the steps. The 2026-09-28 steps/dividers round
(`docs/design/BRIEF_steps_dividers_logo.md`) followed: part 10a turned the
steps into a timeline and the ingredient hairline into a dashed divider. The
2026-09-30 round-2 handover followed: part 12 (D134) dropped the serif
altogether (a recipe's name is sans w700), took the hairline off every card in
favour of a per-brightness `KitchenColors.card` fill, and gave meal-plan
entries a drag grip and a new lift / placeholder / drop look. Part 13
(D135), from device feedback, put recipe detail's app bar over the photo and
made a meal-plan drag keep the entry's meal. It
replaces `docs/DESIGN.md`, which is now only a pointer at this file.

What is *described* here and what is *applied* are two different things. The
tokens are real everywhere — the palette and typeface repaint every screen at
once. The per-surface component and layout work of § Components is landing
slice by slice across the rest of Phase 7; a screen that has not had its slice
yet is on the new palette in its old arrangement. A slice that changes the
design language changes this file in the same slice, the way a schema change
updates `docs/DATA_MODEL.md`.

**Load one section, not the file.**

---

## How to read this

Three layers, in order of how a screen should reach for them:

1. **Material 3 roles** — `Theme.of(context).colorScheme.primary`, and the
   `TextTheme` roles. A screen uses these for anything Material already has a
   name for.
2. **The semantic layer** — `KitchenColors`, a `ThemeExtension` whose members
   are named for *meaning* in this app (`today`, `reviewMarker`, `favorite`).
   Each is an alias of a role, so light and dark follow automatically. A screen
   drawing "the thing that means today" reads `today`, not `primary`.
3. **Token classes** — `AppSpacing`, `AppRadii`, `AppSizes`, `AppDurations`.
   Numbers with names.

A screen never writes a hex, a raw `fontSize`, or a bare `EdgeInsets` number.
The only place a colour literal is allowed is where a role's value is
*defined*, in `lib/core/theme/`.

A design round's CSS token names map to these symbols in § Token map.

---

## Colour

Both schemes are written out in full. There is no seed and no
`ColorScheme.fromSeed` — every role is a decision, and the light and dark
values were designed as a pair.

### Primary — green, the brand

| Role | Light | Dark | Use |
|---|---|---|---|
| `primary` | `#366A35` | `#9ED498` | main actions, "today", links |
| `onPrimary` | `#FFFFFF` | `#013908` | label on primary |
| `primaryContainer` | `#B9F1B3` | `#1D511E` | tonal buttons, the meal plan's drop highlight, step-number disc |
| `onPrimaryContainer` | `#032B00` | `#BFF6B8` | content on it |

### Secondary — mustard, the small golden highlight

| Role | Light | Dark | Use |
|---|---|---|---|
| `secondary` | `#775A0E` | `#E8C174` | leftover marker |
| `onSecondary` | `#FFFFFF` | `#3F2E00` | content on secondary |
| `secondaryContainer` | `#FFDEA4` | `#5B4300` | selected chip, no-photo monogram tile, tonal button |
| `onSecondaryContainer` | `#2F2201` | `#FFE5B9` | label on it |

### Tertiary — paprika, reserved for small signals

| Role | Light | Dark | Use |
|---|---|---|---|
| `tertiary` | `#AC3F25` | `#FF9569` | 3px review marker, favourite heart, filled stars, stat values |
| `onTertiary` | `#FFFFFF` | `#461200` | content on tertiary |
| `tertiaryContainer` | `#FFDBD0` | `#881F09` | rare tonal accent |
| `onTertiaryContainer` | `#461200` | `#FFE2DA` | content on it |

Paprika is a *signal*, never a surface a screen sits on. It has to stay legible
at 3px — that constraint is why the role exists (D117). Confirmed on device
(Phase 7 part 6's walk): at 3px on the import review, `#FF9569` on the dark
`#1C1C16` tint reads clearly.

### Error

| Role | Light | Dark | Use |
|---|---|---|---|
| `error` | `#A50048` | `#FEB9CB` | validation text and destructive text buttons only |
| `onError` | `#FFFFFF` | `#650030` | content on error |
| `errorContainer` | `#FFDDE2` | `#891446` | reserved; not the offline banner (see below) |
| `onErrorContainer` | `#520020` | `#FFE1E8` | content on it |

`error` is never a background. The offline banner used to be drawn in
`errorContainer` and no longer is — offline is a frequent state, not a failure,
and it reads calm (see `offline` in the semantic layer).

### Surfaces — warm cream ground

| Role | Light | Dark | Use |
|---|---|---|---|
| `surface` | `#FFF7EC` | `#16160F` | screen background |
| `surfaceBright` | `#FFFAF4` | `#373731` | bright variant |
| `surfaceDim` | `#E5DBD0` | `#16160F` | dim variant |
| `surfaceContainerLowest` | `#FFFDFA` | `#101007` | lowest step |
| `surfaceContainerLow` | `#FAF1E5` | `#1C1C16` | **card fill** |
| `surfaceContainer` | `#F5EBDF` | `#20201A` | **nav bar** |
| `surfaceContainerHigh` | `#EFE5DA` | `#292923` | **menus, dialogs** |
| `surfaceContainerHighest` | `#E8DED3` | `#34342E` | **chips, text fields, photo well** |

### Content and lines

| Role | Light | Dark | Use |
|---|---|---|---|
| `onSurface` | `#1F190F` | `#EBEBE4` | primary text |
| `onSurfaceVariant` | `#484134` | `#CFD0C2` | secondary text, meta, units |
| `outline` | `#6F6759` | `#96978A` | muted icons, badge edge, the dashed unmatched ring, the segmented button's stroke |
| `outlineVariant` | `#D1C8B8` | `#494A3F` | dividers, the action bar's top hairline — **not** a card edge (D134) |

`outline` is never body text — it is tuned for the low-emphasis role, not for
reading. Secondary text that sits beside primary text of the same size is
`onSurfaceVariant`.

### Inverse — the snackbar

| Role | Light | Dark |
|---|---|---|
| `inverseSurface` | `#342D24` | `#E3E3DB` |
| `onInverseSurface` | `#F9EFE3` | `#2E2F29` |
| `inversePrimary` | `#9ED498` | `#366A35` |

Every text role above meets at least 5.0 : 1 against its own background in both
brightnesses; the ratios are printed on the export's colour sheet and do not
need re-deriving when a value is quoted unchanged.

### Intended weight on a screen

Mostly cream surfaces, green for the one action that matters, mustard as a
small golden highlight, paprika only as a signal. A screen that reads as
"mostly green" has gone wrong.

---

## Type

One face: **the platform sans** (Roboto on Android, San Francisco on iOS),
`fontFamily: null` on every role. No font is bundled (D134, superseding the
type half of D127). Letter spacing is in logical px; a role with none listed
has Material's default.

A screen picks a role for what the text *is*, never a raw `fontSize`.

| Role | Size / line | Weight | Letter spacing | For |
|---|---|---|---|---|
| `displaySmall` | 32 / 40 | 700 | 0.5 | the type wordmark for text contexts; no screen uses it since D137 (sign-in shows the lockup) |
| `headlineSmall` | 28 / 34 | 700 | 0.3 | the household's name, and the onboarding screens' titles (D137) (a *recipe's* detail title is `KitchenType.recipeTitleLarge`) |
| `titleLarge` | 22 / 28 | 600 | — | app bar, dialog titles |
| `titleMedium` | 18 / 24 | 600 | — | section headings, sheet titles, empty-state titles, stat values |
| `titleSmall` | 14 / 20 | 600 | — | labels, settings group headers |
| `bodyLarge` | 18 / 28 | 400 | — | the reading text — recipe steps, ingredient lines; the intro paragraph on the import screens |
| `bodyMedium` | 14 / 20 | 400 | — | default copy, the result count, menu items, stat labels |
| `bodySmall` | 12 / 16 | 400 | — | captions, meta |
| `labelLarge` | 14 / 20 | 600 | — | buttons, chips, the step number |
| `labelMedium` | 12 / 16 | 500 | — | badges (Draft, the machine-translation badge), nav labels |

Roles not listed keep Material 3's defaults; nothing in the app needs them.

### `KitchenType` — a recipe's name

A `ThemeExtension` in `lib/core/theme/kitchen_type.dart`, read as
`Theme.of(context).extension<KitchenType>()!`, built from the scheme like
`KitchenColors`. Deliberately not a Material role. Every member is sans, w700,
`onSurface`.

| Token | Size / line | Weight | Letter spacing | For |
|---|---|---|---|---|
| `recipeTitle` | 17 / 24 | 700 | 0.1 | a recipe's name on a recipe card and on a meal-plan entry, and a leftover's title |
| `recipeTitleLarge` | 28 / 34 | 700 | 0.3 | a recipe's title on its detail screen |
| `monogram` | 30 / 36 | 700 | 0 | the letter on a recipe card's 72dp monogram tile |

**Weight 700 marks a recipe's name** (D134). Bold in a title position always
means "this is a recipe". Screen titles, section headings, steps, ingredient
lines are the Material roles above. **One exception:** a meal-plan note wears
`recipeTitle`'s metrics at **w400** —
`recipeTitle.copyWith(fontWeight: FontWeight.w400)` at its one call site —
because a note is not a recipe (D134, amending D132). The warmth comes from the
cream ground, the green / mustard / paprika palette and the monogram tiles.

---

## Spacing and layout

| Name | Value |
|---|---|
| `AppSpacing.xs` | 4 |
| `AppSpacing.sm` | 8 |
| `AppSpacing.md` | 12 |
| `AppSpacing.lg` | 16 |
| `AppSpacing.xl` | 24 |
| `AppSpacing.xxl` | 32 |

Screen gutter 16. Gap between sections 24. Gap between cards 12.

New code picks a step from this scale instead of writing a literal. Migration
is not retroactive across the whole app, but *is* expected for any file a
slice already opens.

---

## Shape

`AppRadii`, rounded but not pillowy:

| Name | Value | For |
|---|---|---|
| `xs` | 4 | badges |
| `sm` | 8 | chips, fields, thumbnails, snackbar, banner |
| `md` | 12 | cards, meal entries |
| `lg` | 16 | menus, FAB |
| `xl` | 28 | dialogs, the top of a bottom sheet |
| `full` | stadium | buttons, segmented buttons, the search field, the nav indicator |

`full` is **not a member of `AppRadii`**. A stadium is a shape, not a radius:
it is `const StadiumBorder()` at the call site. Keeping it out of the class is
what stops a control that should stay pill-shaped at any height from being
quietly turned into a rounded rectangle by someone reaching for the largest
number in the table.

---

## Size and motion

`AppSizes`, written for one hand at arm's length:

| Name | Value | For |
|---|---|---|
| `target` | 48 | minimum hit area, every control |
| `button` | 48 | all buttons — the sign-in button is `signInButton` |
| `signInButton` | 52 | the sign-in screen's Google button (outlined, neutral) |
| `field` | 52 | filled text field, search |
| `chip` | 40 | filter chips |
| `tag` | 32 | an input/tag chip and the ingredient suggestion pill — a drawing; a tappable one keeps a 48 hit area |
| `appBar` | 64 | top app bar |
| `nav` | 80 | `NavigationBar` |
| `icon` / `iconInButton` / `iconInMeta` | 24 / 20 / 16 | actions · inside buttons · in meta lines |
| `thumb` | 72 | recipe card photo or monogram tile |
| `stepDisc` | 28 | the step-number disc on a recipe — one `bodyLarge` line, so it centres on the first line with no offset |
| `avatar` | 40 | a person's monogram circle — member, profile |
| `emptyStateIcon` | 48 | `AppEmptyState`'s icon |
| `grip` | 20 | the drag-indicator glyph on a meal-plan entry and the editor's ingredient and step rows |
| `gripColumn` | 40 | the trailing column that glyph is centred in |
| `signInIllustration` | 176 | the sign-in screen's painted recipe card, as a width (176 × 139) |
| `lockup` | 48 | the sign-in screen's logo lockup, as a height |
| `onboardingMark` | 56 | the mark tile on create / join household |

`emptyStateIcon` is its own name rather than a borrowed `target`: they are the
same number today, but one is a hit area and the other is a drawing, and they
have no reason to move together. `signInButton` is not `field`, `grip` is not
`iconInButton`, `gripColumn` is not `avatar` and `onboardingMark` is not
`thumb` or `field`, for the same reason.

`AppDurations`: 150 ms for a small state change, 250 ms for a transition,
emphasized easing. **No decorative animation.** The class exists so later
slices have a name to reach for, not so anything animates for its own sake.

---

## Elevation

Flat by default. `surfaceTintColor: Colors.transparent` everywhere — tone comes
from the container roles, not from Material's tint.

| Level | Where | How |
|---|---|---|
| 0 | cards | a container-role fill (`KitchenColors.card`), no hairline, no shadow |
| 0 | app bar, nav bar, fields | a container-role tone step. No shadow. |
| 2 | menus, snackbar | a soft two-layer shadow (y1 blur2, y2 blur6 spread2) |
| 3 | dialogs, bottom sheets, a dragged step row in the editor | the same, heavier; in dark, black at 60%. The dragged row is a `Material` on `surfaceContainerHigh` with `colorScheme.shadow`, radius `md` (the steps list's `proxyDecorator`; the ingredient list keeps the default lift) |

Scrim behind dialogs and sheets: `#1F190F` at 32% in light, black at 50% in dark.

---

## Token map

Design rounds arrive as a web bundle whose tokens are CSS custom
properties. This table is how `/design-handoff` matches them to Flutter
symbols. A bundle token not listed here is new and needs a row added in
the round's tokens slice. Values are not repeated here. The sections
above own them.

| Bundle token | Flutter symbol |
|---|---|
| `--primary`, `--on-primary`, … `--inverse-primary` (every M3 role, kebab-case) | `ColorScheme.<role>` in camelCase (`--surface-container-high` → `surfaceContainerHigh`) |
| `--scrim` | `AppTheme`'s dialog barrier (`onSurface` at 32% light, black at 50% dark) |
| `--today`, `--today-container`, `--review-marker`, `--favorite`, `--rating`, `--stat-value`, `--leftover`, `--unmatched`, `--offline`, `--on-offline`, `--doc-language`, `--destructive`, `--card`, `--step-connector`, `--drag-handle` | `KitchenColors.<camelCase>` |
| `--doc-language-ring` | `ColorScheme.outlineVariant` (no field of its own) |
| `--meal-entry` | `ColorScheme.surface` (no field of its own) |
| (no bundle token) | `KitchenColors.dividerDash`, `KitchenColors.dropTarget` (app-only) |
| `--type-display-small`, `--type-headline-small`, `--type-title-large/-medium/-small`, `--type-body-large/-medium/-small`, `--type-label-large/-medium` | `TextTheme.<role>` |
| `--tracking-display-small`, `--tracking-headline-small` | `letterSpacing` on that `TextTheme` role |
| `--type-recipe-title` + `--tracking-recipe-title` | `KitchenType.recipeTitle` |
| `--text-recipe-title-large` | `KitchenType.recipeTitleLarge` |
| `--type-monogram` | `KitchenType.monogram` |
| `--space-xs`, `-s`, `-m`, `-l`, `-xl`, `-xxl` | `AppSpacing.xs`, `.sm`, `.md`, `.lg`, `.xl`, `.xxl` |
| `--gutter`, `--section-gap`, `--card-gap` | `AppSpacing.lg`, `.xl`, `.md` |
| `--radius-xs`, `-sm`, `-md`, `-lg`, `-xl` | `AppRadii.xs`, `.sm`, `.md`, `.lg`, `.xl` |
| `--radius-full` | `StadiumBorder()` (§ Shape) |
| `--size-target`, `-button`, `-button-signin`, `-field`, `-chip`, `-app-bar`, `-nav-bar`, `-thumb`, `-step-disc` | `AppSizes.target`, `.button`, `.signInButton`, `.field`, `.chip`, `.appBar`, `.nav`, `.thumb`, `.stepDisc` |
| `--size-tag` | `AppSizes.tag` (32) — first drawn by the ingredient suggestion pill |
| `--icon-action`, `--icon-button`, `--icon-meta` | `AppSizes.icon`, `.iconInButton`, `.iconInMeta` |
| `--duration-short`, `--duration-medium` | `AppDurations.short`, `.medium` |
| `--ease-emphasized` (`cubic-bezier(0.2,0,0,1)`, M3's CSS fallback) | `AppDurations.emphasized` (`Curves.easeInOutCubicEmphasized`) |
| `--elevation-2`, `--elevation-3` | M3 elevation 2 / 3 with `shadowColor: scheme.shadow` (§ Elevation) |
| `assets/recipe-card.png` | `SignInIllustration` (a painter in theme roles, D137) |
| `assets/mark-master.svg` | `assets/brand/mark.png` (`make icons`) |
| `lockup-en-light.svg`, `lockup-en-dark.svg` | `assets/brand/lockup_light.png`, `lockup_dark.png` (`make icons`) |
| (web only, no mapping) | `--font-sans`, `--font-mono`, the `--surface-*` / `--text-*` / `--border-*` aliases (they resolve to roles above), `.kt-state`, `.kt-dash` |

---

## The semantic layer — `KitchenColors`

(Its type counterpart, `KitchenType`, is in § Type.)

A `ThemeExtension` read as `Theme.of(context).extension<KitchenColors>()!`.
Every member is an alias of a role above, so there is no second palette to keep
in sync — what it adds is a name for what the colour *means here*. (`card` is
the one that aliases a different role per brightness; still an alias.)

| Token | Alias of | Means |
|---|---|---|
| `today` | `primary` | the "Danas"/"Today" pill and the 2dp outline of today's day card |
| `todayContainer` | `primaryContainer` | the step-number disc (today's day card is outlined in `today`, not filled) |
| `reviewMarker` | `tertiary` | the 3px left edge on an import line flagged for a second look |
| `favorite` | `tertiary` | a filled heart — only ever a heart |
| `rating` | `tertiary` | filled stars; an empty star is `outline` |
| `statValue` | `tertiary` | the values in the servings / prep / cook / rating strip |
| `leftover` | `secondary` | the return icon on a leftover meal entry |
| `unmatched` | `outline` | the dashed ring on an ingredient that matched nothing — **never `error`** |
| `offline` / `onOffline` | `surfaceContainerHighest` / `onSurface` | the offline banner: calm, not red |
| `docLanguage` | `surfaceContainerLow` with an `outlineVariant` ring | the "SR"/"EN" tag saying which language a generated document is in, and the panel behind a field's original text on the translation review |
| `destructive` | `error` | destructive actions, as text only — never a fill |
| `stepConnector` | `outlineVariant` | the 2dp line joining one step disc to the next |
| `dividerDash` | `outlineVariant` | the dashed divider under an ingredient row |
| `card` | `surfaceContainer` (light) / `surfaceContainerHigh` (dark) | every themed `Card`'s fill. It picks a role per brightness because dark `surfaceContainer` (`#20201A`, +5 tone from the ground) fades out once there is no border. In light it matches the nav bar's `#F5EBDF` on purpose |
| `dragHandle` | `outline` | the 6-dot grip on every reorderable row: a meal-plan entry, and the editor's ingredient and step rows |
| `dropTarget` | `primaryContainer` | the fill of the entries in a hovered slot, and of a hovered collapsed day |

Two of these are load-bearing rules rather than preferences:

- **`unmatched` is not an error.** An ingredient line the catalog did not
  recognise still renders exactly what the cook typed, and that is a fine
  outcome (CLAUDE.md rule 3). It gets a quiet dashed ring, not a red anything.
- **`offline` is not an error.** Offline is a frequent state in this app. The
  banner informs; it does not alarm.

---

## Components

### Buttons

48dp high, stadium, `labelLarge`. **One filled button per screen** — the screen's
single most important action. Everything else is quieter:

| Kind | Fill | For |
|---|---|---|
| Filled | `primary` | the one action (Save recipe, Generate list) |
| Tonal | `secondaryContainer` | a second-rank action (Copy code) |
| Outlined | none, `outline` border | cancel-weight (Discard this import); Settings' Sign out, in `onSurface` |
| Text in `error` | none | destructive (Delete recipe, Leave household) |

The household screen has no filled button: its invite action is outlined and
Copy is tonal, because nothing on it is the screen's one action. The sign-in
button is 52dp, outlined in `outline`, filled `surfaceContainerLowest`, label
`onSurface`, with the official Google G at `iconInButton`. The sign-in screen,
like the household screen, has no filled button (D137).

**Sign out** is a full-width `OutlinedButton.icon` with the `logout` icon and
`foregroundColor: onSurface` — label and icon neutral, border `outline`. Not
`error`, not `primary`: signing out loses nothing, so it is neither destructive
nor the screen's one action, and it has no confirm dialog.

**No FAB.** No screen has one since sync-design-initial's recipe-list slice:
the recipe list's add entry is a `+` `IconButton` at the end of the app bar
that opens the four-item add menu (D138, amending D119).
`floatingActionButtonTheme` — `primary` on `onPrimary`, radius 16, elevation
0 — stays in the theme as a guard. Not Material's `primaryContainer` default:
unthemed, the old FAB sat at 1.94:1 against the dark surface and was invisible
to a person while present in the widget tree (Phase 7 part 2's device walk).
If a FAB ever comes back, it is the screen's one filled action, and the one
filled action is `primary` everywhere else here.

### Action bar

A screen whose save action sits at the bottom puts it on `AppActionBar`:
`surface` (not `surfaceContainer`, the nav bar's colour — the two would merge)
with a 1dp `outlineVariant` top hairline, padded `lg`/`md`, and an optional
already-localized error line above the buttons in `bodySmall` `error`, `sm`
above them. Its child is one filled button, full width, or equal `Expanded`
halves `md` apart, or a single full-width **outlined** button — the import
waiting state's Discard. The busy spinner inside a button is the call
site's, `AppSizes.iconInMeta` square.

The import entry screens (link, paste, photo) do **not** use it: a pinned
bar sits under the keyboard. Their filled `Pročitaj ovaj recept` is inline,
full width, `xl` under the last field (or the photo screen's button row),
with the error line `sm` above it in `bodySmall` `error`.

The onboarding screens (create / join household) do **not** use it: no app
bar, no hairline, `surface` throughout. They are top-aligned — the 56dp mark,
the `headlineSmall` title, the `bodyLarge` subtitle, the field — with the
filled button, then `sm`, then the full-width text-button switcher pinned to
the bottom by `SliverFillRemaining(hasScrollBody: false)` and a `Spacer`
(D137). The padding goes inside `SliverFillRemaining`, not in a trailing
`SliverPadding`, which would push the bottom air below the fold.

### Cards

`KitchenColors.card`, no hairline, radius 12, elevation 0, no surface tint. The
fill alone separates a card from the cream ground — not a border, not a shadow
(D134). Every themed `Card` follows: recipe list, meal plan, settings,
shopping list, import review, the household invite card.

### Navigation

App bar 64dp on `surface`, no elevation, title in sans `titleLarge`,
left-aligned. The one exception is recipe detail (D135). Its bar has no
title and sits over the 16:9 photo as a pinned, collapsing `SliverAppBar`.
Every icon button there sits on a `surface` disc at 0.7 alpha, and the
status-bar icons are light while a photo is behind them. Collapsed, it is
the ordinary bar. `NavigationBar` 80dp on `surfaceContainer`; the selected
destination is a **`primary` pill with an `onPrimary` icon and a `primary`
label** — not Material's default `secondaryContainer` indicator.

### Inputs

Filled, 52dp, radius 8, no underline. **The label sits above the field** in
`titleSmall`, not floating inside it. Focus is a 2dp `primary` border.
Validation text is `error`, below the field.

**Field text and hint are `bodyMedium`**, not the 18/28 `bodyLarge` Flutter
falls through to. A field is furniture, not something a person reads; since
part 9a the reason is size, not face (`bodyLarge` is sans now too). The hint half is set once in
`inputDecorationTheme`; the typed half **cannot be themed**, so every
`TextField` passes `style: bodyMedium` at its call site. Forgetting it is
exactly the defect part 2's walk found in the search box.

**One exception: the ingredient editor's open line types in `bodyLarge`**
(D158). The open line *is* the row being edited — the closed row above it is
`bodyLarge` 18/28 — and dropping to 14 on tap would make the line jump. Its
hint is `bodyLarge` too. Every other field keeps `bodyMedium`.

**The label is `AppFieldLabel`** (`titleSmall`, no padding of its own). The
call site writes the gaps: `sm` from label to field, `lg` from a field to the
next label, `xl` from the last field of a group to an `AppSectionHeading`. A
field whose purpose is already said by the paragraph or title above it (the
paste box) has no label. `hintText`, `helperText` and
`counterText: ''` stay in the decoration; `labelText`, a local
`OutlineInputBorder` and `isDense` do not appear at all.

**A row of short fields labels its columns in a row of their own**, above
the row of fields: labels `Expanded` and bottom-aligned, then `sm`, then the
fields top-aligned. A label that wraps at 360dp (`Priprema (min)`) pushes all
the fields down together, so they never stagger. Columns sit `sm` apart.

**A code-entry field** (the join code) is `titleLarge` with `sm` letter
spacing and tabular figures, centred, under its label (`Pozivni kod` /
`Invite code`).

**The search field is the stadium exception.** A stadium is a shape, not a
radius, so it is not in `AppRadii` — and because `InputBorder` takes only a
`BorderRadius`, inside a decoration it is spelled
`BorderRadius.circular(AppSizes.field / 2)`. It is `AppSearchField`: no resting
border, `surfaceContainerHighest`, a magnifier in `outline`, and a clear button
once there is something to clear.

**The photo well** (the recipe editor) is 16:9, `surfaceContainerHighest`,
radius `md`. Empty, it centres a 32dp `image` icon in `outline`, `md`, then
tonal Camera / Gallery `sm` apart (a `Wrap`, so a large text scale stacks
them instead of overflowing). Filled, the photo takes the same 16:9 shape at
radius `md`, so picking one does not move the form; under it, `sm`, then the
tonal Camera / Gallery row and the remove button.

**The import photo well** (import from a photo) is the same vocabulary at
1:1 — square, not the page's shape, so Read clears the fold at 360×760. Empty,
a centred 48dp `menu_book_outlined` in `outline`; filled, the page with
`BoxFit.contain` in the same box, letterboxed on `surfaceContainerHighest`.
The tonal Camera / Gallery `Wrap` (`sm` apart, centred) sits *below* the well
in both states, `md` under it; then `xl`, then Read. Private to
`import_photo_screen.dart`, not shared with the editor's well.

**A step field is labelled** `Korak N` / `Step N` with `AppFieldLabel` above
its row, indented past the grip, not hinted: a hint vanishes once the cook
types. Steps sit `md` apart. N counts steps only, as on detail. A heading's
label is `Naslov` / `Heading` after a 16dp `title` icon, a note's `Beleška` /
`Note` after `sticky_note_2_outlined`, both icons `onSurfaceVariant`, `xs` to
the text. Every kind keeps the same grip | field | ✕ frame (the canvas's
✕-in-the-label-row would fight the 48dp `iconButtonTheme` minimum); a heading
field is one line, a step or note field three. Under the list, indented with
the labels, a `Wrap` (`xs` apart) of tonal `Korak` (`add`), then text buttons
`Naslov` (`title`) and `Beleška` (`sticky_note_2_outlined`). Removing a
heading shows `Naslov je uklonjen.` with `Poništi`; a step or note goes
without one. A dragged row lifts to level 3 (§ Elevation); the gap
`ReorderableListView` opens is the drop indicator, no drawn line.

**The translation review's original text** sits in a panel above its field
(D84): `docLanguage` with a 1dp `outlineVariant` ring, radius `sm`, padded
`md`/`sm`. The ring is not optional: dark `docLanguage` on the dark ground is
invisible without it. Inside, the `Original (…)` label in `labelMedium`, `xs`,
then the text in `bodyMedium`, both `onSurfaceVariant`.

### Chips

40dp, radius 8 (32dp for an input/tag chip). Selected is `secondaryContainer`
plus a check icon — selection reads as colour, not only as an outline. **A
filter row scrolls horizontally and never wraps**: a wrapping row grows
downward and eats the list beneath it.

**The row is full-bleed.** The `lg` gutter is the `SingleChildScrollView`'s own
padding, not a `Padding` around it, so the chips scroll to the screen edge and
the cut-off last chip is what says the row scrolls.

**Clear.** While any filter is on (the recipe list: Favorites or a tag), the
row starts with an `ActionChip` — `close` avatar, `Poništi` / `Clear`,
`outline` border on a `surface` fill so it reads outlined, not selected — then
`sm`, a 1dp × 24 `outlineVariant` vertical line, `sm`, and the filter chips.
It is absent, not disabled, when nothing is selected, and it clears the
filters only: the search field keeps its text and its own clear button. Above
every non-empty list, narrowed or not, a result count (`2 recepta` /
`2 recipes`, `bodyMedium` `onSurfaceVariant`) sits `lg` under the row and `md`
above the first card.

### Ingredient lines

**Name left, amount right**: a row of `Expanded` name column, a 24dp (`xl`)
gap, then the amount — grid `1fr | auto`. `bodyLarge` 18/28, min height 48,
`sm` vertical padding, a **dashed divider** between lines: 6dp dashes, 4dp
gaps, 1dp, butt caps, in `dividerDash` — a small private `CustomPainter`, not
a package. It takes the 1dp the old solid hairline took, inside the 48, so row
heights did not change. The same row, and so the same divider, on recipe
detail, the shopping list and import review.

**The divider is not the unmatched ring.** The ring is small, closed, 1.5dp,
8 dashes, in `outline`; the divider is long, flat, 1dp, in the lighter
`outlineVariant`. A row carrying both must never read as one thing twice.

The amount is one `Text.rich` that never wraps: the number in `primary`, w600,
tabular figures, then the unit in `onSurfaceVariant` beside it (`½ kg`). It
sizes to its content, so amounts line up on the right edge down a list. The
name, in `onSurface`, takes what is left and wraps on the left. **No amount →
name only**, with no gap reserved. Under the name, the `trailer` (note,
`→ catalog name`, unmatched raw lines) in `bodySmall` muted.

**Further amounts stack** (`extraAmounts`): each one more `bodyLarge` line
under the first in the same right-aligned column, no gap between, led by a
`+ ` in `onSurfaceVariant` w400 (`480 ml` / `+ 300 g`) — a second unit family
never merged into the first (D9). The canvas paints the `+` in `outline`; it
is body text at `bodyLarge` beside primary text of the same size, and
`outline` is never body text, so `onSurfaceVariant` wins. The row simply grows.
Only the shopping list passes any.

- **matched** — plain
- **optional** — the `optionalLabel` (`opciono` / `optional`) inline after the
  name as ` · opciono` in muted `bodySmall`. Callers do not fold it into the
  trailer
- **unmatched** — rendered exactly as typed, with a 16dp dashed `unmatched`
  ring **inline after the name** (a `WidgetSpan`, `sm` before it; a small
  `CustomPainter`, not a package). A word joiner (U+2060) sits before it,
  but Flutter still breaks before a placeholder when the last word and the
  ring overflow together, so the row also measures the name's last line and,
  when the markers won't fit after it, turns the last space into a line
  break: **a marker always travels with the last word**, never alone on a
  line. The PDF draws it at 14; 16 is the existing
  `iconInMeta` and a token for 2dp is not worth it. Never `error`, never red —
  a line the catalog did not know is a supported outcome, not a fault
- **name marker** (`nameMarker`) — a generic slot for one caller-built
  widget inline after the name and optional label, before the ring: the same
  word joiner and middle-aligned `WidgetSpan`, `xs` before it (a 16dp icon's
  own ~2dp side bearing makes up the rest), in a fixed 16dp (`iconInMeta`)
  box, so its width is known for the last-word measurement. The row gives it no meaning; only
  the shopping list uses it, for the staple pin
- **flagged** (import review only) — a 3px `reviewMarker` left edge painted
  as a **foreground** (it takes no layout) on a `surfaceContainerLow` tint.
  A flagged row is always inset (below), so the name clears the marker

**`inset`** pads a row's content `md` in from both edges, and its dashed
divider with it, so the dashes start and end at the text. The flagged tint
and marker still run the full width, down to the divider with no gap. Import review sets it on **every** row, so
flagged and unflagged names and amounts line up (`Review import@1x.png`). The
recipe detail and the shopping list sit flush with the gutter
(`Recipe@1x.png`).

On import review the name is the local parse of the raw text, falling back to
the whole raw text when there is no usable parse, and a matched line's trailer
leads with `→ <catalog name>` (in the recipe's language), joined to the note
with ` · `. An unmatched line's trailer leads with `Nije povezano sa sastojkom` /
`Not matched to an ingredient` — the ring's tooltip string — joined to the note
the same way, in the row's muted `bodySmall`. It stays unflagged and is never
red: an unmatched line is a supported outcome (rule 3).

**Being edited** (`IngredientLinesEditor`, the recipe editor and import
review). Every line is the closed row above; tapping one **opens** it — one at
a time — into **the open line** (`IngredientLineField`, A4·2): `[grip]
[box] [✕ 48]`, top-aligned, the grip `md` from the top. The box is
`surfaceContainerHighest`, radius `sm`, padded `md`, with a 2dp `primary`
border only while focused (painted as a foreground, so focus does not move
the text). Inside it: the raw text, borderless, in `bodyLarge` (§ Inputs'
one exception) with `ingredientLineHint` in the recipe's language; then
`xs` and, once there is text, **the preview row** in `bodyMedium`
`onSurfaceVariant` — `→ <catalog name, or the parsed name, or the whole
line>`, ` · <note>`, ` · opciono` when optional with no note, and
` · Nema poklapanja` when unmatched with nothing to suggest; then `md` and the
amount on the right as one non-wrapping `Text.rich` (number `primary` w600
tabular, unit muted). The whole preview row is an `InkWell` that opens the
picker: "choose another". Under the box, nothing — no Done; rows sit `sm`
apart.

**Fast entry** (D159). The keyboard's **Next** on a line commits it and opens
a blank line directly under it, in the same section, with the keyboard still
up. Next on a blank line closes and removes it — that ends a burst.
**Backspace on an empty line** removes it and opens the line above, caret at
the end (Android's key event; iOS unverified). A line closes when another
opens, on Next, or on ✕; a blank line that closes is removed unless it is the
only line. A new recipe's lone blank line renders open but unfocused.

**The suggestion pill** (`IngredientSuggestionPill`, A4·1) sits under any
unmatched, non-blank line — closed or open — when the search has a
candidate, `sm` under the text and above the divider, so it belongs to its
line. 32dp (`tag`) stadium in `secondaryContainer`: a `check` (18) in
`onSecondaryContainer`, `xs`, `{name}?` in `labelLarge`
`onSecondaryContainer`, padded `sm` left and `md` right, with a 48 hit area;
then `sm` and `Dodirni za potvrdu` / `Tap to confirm` in `bodySmall`
`onSurfaceVariant`, in a `Wrap` so the hint drops under the pill at 360dp.
**Tapping it confirms** — `manual`, confidence 1, and the alias written back
(D7, D8) — with no picker. A closed row searches only when unmatched, and
**never auto-accepts**: only typing in the open line can, so opening a saved
recipe changes nothing.

These follow two people (D86). **Status words** — `Nema poklapanja`, the
`{name}?` wrapper, `Dodirni za potvrdu`, ` · opciono` — are chrome and follow
the **reader**. The amount, the unit names, the suggested catalog name and
the field's hint follow the **recipe**.

Rows take `showDivider`: the last row of a card omits its divider, so the
card's own edge does the separating, and the last line of the recipe detail's
list omits it too (`Recipe@1x.png`). Every other row keeps it, including the
last of a block followed by a gap: a divider missing mid-card reads as
uneven spacing, not as a break.

**Sections** (recipe detail, the recipe editor and import review). A
section heading opens each run of consecutive
lines sharing a `section` (`Za testo`, `Za fil`), in `titleSmall` `primary` —
the same look as a step heading (§ Steps and stats), from the same
`RecipeGroupHeading`. It sits `xl` above (`xs` when it opens the list, on top of the
`AppSectionHeading`'s `sm`) and `xs` below, both on top of the row's own `sm`
padding: 24 to the group above, 12 to its own first line, 12 under
`Sastojci`. A section's last line drops its divider, just as the list's last
line does. The heading is the cook's text as typed and is not translated.
Lines before the first section sit headingless at the top, and a flat list
renders exactly as it did before sections showed. In the editor the heading
is indented past the grip column (`grip` + `xs`) to line up with the row
text, and in import review `md`, matching the inset rows.

Editing them, in both: the heading is its own list item. In the editor it
has a grip (`dragHandle`, `grip` + `xs`) centred on its text line, with the
top gap outside the grip row; in import review it drags on long-press, as
its rows do. The tap target takes in the top gap, so mid-list it is about
48 tall. Tapping a heading opens it, through the same one-thing-open rule as
a line: the open line's box (`surfaceContainerHighest`, radius `sm`, padded
`md`, a 2dp `primary` focus border as a foreground) holding one borderless
`titleSmall` `primary` field, hinted `Za testo` / `For the dough` in the
**recipe's** locale, as `[grip] [box] [✕ 48]`, top-aligned (no grip and
inset `md` in review). Each keystroke renames every line of the run. **Add
section** (`Icons.title`, a text button) sits beside Add ingredient in a
`Wrap` with `xs` spacing, so the two wrap rather than overflow in Serbian at
360dp; it opens an unnamed heading over a new blank line, and Next goes into
that line. A line dropped anywhere takes the section of the heading above
it, or none above the first. A dragged heading carries its run: the run
closes up while it is in the air, the proxy shows the heading and its rows
lifted at level 3 on `surfaceContainerHigh`, and the drop snaps to the
nearest group boundary (ties going down), so it never splits another group;
it never lands above a headingless top block, which would read as its own.
The open heading's ✕ joins its lines to the group above — nothing moves or
is deleted — with `Odeljak je uklonjen.` / `Section removed.` and Undo
(4 s, `persist: false`); a heading closed blank counts as removed, and an
unnamed new one simply goes.

### Steps and stats

A step number, in `labelLarge` `onPrimaryContainer`, sits in a 28dp
`todayContainer` disc; `lg` (16) to the step itself in `bodyLarge` (sans
18/28, w400 — no bold); `xl` (24) between steps.

**The steps are a timeline.** A 2dp `stepConnector` line runs down the disc
column from one disc to the next, stopping 4dp short of both. The 24dp gap
sits inside the step above, so the line crosses it, and a step whose text
wraps stretches the line with it. No line above step 1 or below the last
step, so a single step draws none. The 2 and the 4 are private consts in
`recipe_detail_screen.dart`, its only user.

**Numbering counts steps only** and continues across headings (1–4 under
`Za testo`, 5–7 under `Fil`) — never `position + 1`.

**A heading** (`RecipeGroupHeading`) groups the steps after it: `titleSmall` in `primary`, flush with
the disc column, `sm` top (32 effective after the row above's `xl`; 0 when it
is first) and `md` bottom. **A note** is an un-numbered aside: `bodyMedium`
`onSurfaceVariant` on a `KitchenColors.card` panel, radius `sm`, padded
`sm`/`md`, in the text column (the disc column stays, empty), `xl` below. A
warning reads the same — never red.

**The line breaks at a heading and runs past a note.** A step draws its line
only when a step or note follows, running straight into a note's segment. A
note draws one when a step or note precedes it or a step follows; before a
heading or at the end its line stops level with the panel's bottom.

**The end note** (`Napomena` / `Notes`, never `Beleška`) is a themed `Card`
(radius 12, padded `lg`), full width, outside the timeline, `xxl` (32) below
the last step — `sm` on top of the last row's own `xl`. Its header is
`edit_note` at 20 (`iconInButton`) in `onSurfaceVariant`, `sm`, then
`Napomena` in `titleMedium`; then `sm`, then the body in `bodyLarge`, plain
text until the rich-text slice. An empty note renders nothing at all — no
heading, no gap — and the source footer follows unchanged either way.

The servings / prep / cook /
rating strip puts labels in `bodyMedium` `onSurfaceVariant` above values in
`titleMedium` (18/24 w600) `statValue`, both start-aligned in equal-width
columns (the mock's left edge, not centred), with `lg` inside the
`outlineVariant` hairlines. The columns abut with no gap between them, so five
16dp stars still fit a quarter of a 360dp screen.

### Recipe card

A 72dp photo, or — far more often — a monogram tile: the title's first letter
on `secondaryContainer`, in `KitchenType.monogram`. Then the title in
`KitchenType.recipeTitle` (sans 700), then a meta row.

**The meta row is a component with a rule**: each item is an icon plus its own
text, and **an item never splits across lines — a whole item wraps instead**.
There are no `·` separators. This is the shape that survives Serbian running
30% longer than English; a dot-separated run is not.

Favourite is a filled heart in `favorite`, top-right. `Draft` / `Nacrt` is a
small outlined badge, radius 4, in `labelMedium`.

### Meal entries

All of these are private classes in `meal_plan_screen.dart` — each has one
consumer, so none of them is in `core/widgets/`.

**The day card.** The theme's `Card` (`KitchenColors.card`, no hairline,
radius 12), padded `md` — except `xs` at the bottom, where the add button's
own 48dp target makes the space — with the day header in
`titleSmall` `onSurfaceVariant` — `weekdayNameAndDay` (`Ponedeljak 14` /
`Monday 14`) in the week view, where the week bar already names the month, and
`fullDateLabel` (`Ponedeljak, 14. septembar` / `Monday, September 14`) in the
Today view, both sentence-cased.
Today's card keeps that fill and gets a **2dp border in `today`** plus a
`Danas`/`Today` pill beside the header: `today` fill, `onPrimary` text in
`labelMedium`, `StadiumBorder`, `sm` horizontal and `xs` vertical padding,
so it is **24 tall**. Today is outlined,
not filled.

**Entry cards.** Nested inside the day card, grouped by slot in
`MealSlot.ordered` order, `sm` apart: `surface` fill (the cream ground, so an
entry reads as sunk into its day card), no border, radius 12, padded `md` on
the start, top and bottom, with its content centred vertically. On top an
`AppMetaRow` — the slot as
plain `bodySmall` `onSurfaceVariant` text, then a servings item
(`soup_kitchen_outlined`) for a recipe, a `Napomena`/`Note` item
(`edit_note_outlined`) for a note, or `od pon 14.`/`from Mon 14`
(`event_outlined`) for a leftover whose source is in the loaded week. Then,
`xs` below, the title in `KitchenType.recipeTitle` — a recipe's or leftover's
title — wrapping rather than truncating. **A note's own words are the same
17/24 at w400**: bold means a recipe's name and a note is not one (D134,
amending D132). **No thumbnail or monogram** — an entry carries a recipe's
title and servings, not the recipe (D53).

**The grip.** After the text column, a 40dp (`AppSizes.gripColumn`) trailing
column with `Icons.drag_indicator` centred in it at `AppSizes.grip` (20) in
`KitchenColors.dragHandle`. A long Serbian name keeps the full width up to
that column. The grip is **only a hint**: no gesture of its own, no hit
target, excluded from semantics.

**Leftovers.** The same card with a **transparent fill**, so the day card
shows through, a **dashed 1dp `outline` border** (a private `CustomPainter`
along the `RRect`, no package) and a leading `Icons.undo` at 24 (`AppSizes.icon`) in `leftover`, `md`
before the text, so it reads as derived from another meal rather than as a meal of
its own. The source's day is the abbreviated `weekdayAndDay` on purpose: a
full Serbian weekday would have to be declined after `od`.

**Adding.** One way in: under the entries, `+ Dodaj obrok`/`+ Add meal` in
`primary`, aligned to the card's bottom-right, opens **the add-meal sheet**
(`showRecipePicker`, D143):
- the title `Dodaj obrok` in `titleMedium`, with the day's `shortDateLabel`
  directly under it in `bodyMedium` `onSurfaceVariant`;
- the four slots as `ChoiceChip`s in a `Wrap` (never a scrolling row), Dinner
  preselected and always exactly one selected, every slot offered, filled ones
  included — that is how a second entry gets into a slot;
- then the search field (not autofocused), `RecipeCard` results and
  `Add a note instead`.

There is no per-slot `+ <Slot>` button; four of them
under every day read as clutter. **A week-view day with nothing planned, other
than today, collapses** to one compact 56dp card on `KitchenColors.card` —
`xs` above and below the 48dp button — with the header on the left and
`+ Dodaj obrok`/`+ Add meal` in `primary` on the right, which opens the same
sheet. The Today view never
collapses.

**Drag.** Tap anywhere on an entry opens its actions sheet; long-press anywhere
lifts it. The lifted card is drawn at its own width in `KitchenColors.card`,
on `Material` elevation 2, scaled 1.02 and tilted −1.5°. Where it was, its
footprint stays behind, emptied, under a **1.5dp dashed `outline` at 60%**.
A drag **never changes an entry's slot** (D135). There are two kinds of drop
target, each filled `KitchenColors.dropTarget` and outlined in a **2dp dashed
`primary`** while a drag it would take is over it:
- **another entry of the same day and slot**, where the dragged entry takes
  that entry's position;
- **another day's card**, expanded or collapsed, where the entry moves to
  that day in **its own slot**, landing last in it.

A different slot on the same day takes nothing. Changing the meal is the
entry's `Move to` action. All three dashed outlines are the same private
painter, 4 on / 3 off.

### Shopping list

All of these are private classes in `shopping_list_screen.dart` — each has one
consumer, so none of them is in `core/widgets/`. Two locales render on this
one screen (D94): the list is a document in `list.locale`, everything around
it is chrome in the reader's.

**The range bar.** A full-width `SegmentedButton` under the app bar, padded
`lg`/`sm`: `Ova nedelja`/`This week` · `Sledeća`/`Next` · `Datumi`/`Dates`
(the third with a 20dp `date_range_outlined` icon and the longer
`Izaberi datume` as its tooltip). **No check on the selected segment**
(`showSelectedIcon: false`): at ~109dp a segment cannot hold a check plus
`Ova nedelja` or `This week` on one line, and the `secondaryContainer` fill
already marks it. The selection is **derived** from the
range, never stored — a range equal to this or next week selects that
segment, anything else selects `Datumi`. Re-tapping `Datumi` reopens the
picker (`emptySelectionAllowed`, since a single-select `SegmentedButton`
otherwise ignores a tap on its selected segment). Under it, `xs` below, a
`bodySmall` `onSurfaceVariant` `Sledeća lista: …`/`Next list: …` line —
**only when** there is no list yet or the selected range differs from the
list's own. The range never shares the segments' row: in Serbian it wrapped
to three lines there.

**The provenance lines.** The generated-at line in `bodySmall`
`onSurfaceVariant`, in the document's locale; under it, offline only, the
saved-copy line in the same style — `onSurfaceVariant`, not `error`, on
`_SavedCopyLine`'s precedent.

**The doc-language tag.** `sm` below, hugging its content: a `StadiumBorder`
with `docLanguage` fill and a 1dp `outlineVariant` ring, padded `sm`/`xs`,
holding the code (`SR`/`EN`, from `list.locale`) in `labelMedium` `onSurface`
and, `sm` after it, a sentence in `bodySmall` `onSurfaceVariant` in the
**reader's** locale (`Ova lista je na engleskom`) — chrome about the
document. **Always shown** while a list is on screen, not only when the two
locales differ: it is calm, and it is what makes D94 legible.

**The document card.** `lg` below, one theme `Card` padded `lg`/`sm`,
holding every to-buy item as an `IngredientLineRow`: the first quantity in
the amount column, any further unit family (never merged, D9) **stacked under
it**, right-aligned, led by a muted `+`. The trailer holds every unmatched raw
line; an unmatched item (raw text + ring) **with no amount** leads it with
`Nije sabrano` / `Not added up` — chrome, the **reader's** locale, beside the
ring whose tooltip is chrome too — saying why it has none. An unmatched item
that parsed an amount (`1.67 kom`) shows the amount and no such line. Never
`error`. Items are
grouped and ordered by `groupByCategory`, with blocks `md` apart, a dashed divider
under **every** row but the card's last, and **no category headings** — D105-amended: headings were noise when scanning a list
in a shop, and the Garden mock that draws them was declined. Omitted when
nothing is to buy. Long-press opens a **one-item menu at the press point** —
`Uvek u Verovatno imate` / `Always in Probably have` on a to-buy row, `Uvek
na listi` / `Always on the list` on a Probably-have row; chrome, no icon.
While it is open the pressed row holds a `surfaceContainerHighest` fill
(radius `sm`, bleeding `md` past the row each side, drawn behind it so
nothing shifts). Picking sets the permanent preference and regenerates the
same list at once (D147 — a new snapshot, not an edit, so D13 stands). The
confirmation snackbar carries `Poništi` / `Undo`, which writes the opposite
preference and regenerates again, with no second snackbar. There is **no
one-off move**: it would be per-item state on a snapshot (D13, D152).

**The staples card.** `md` below, a second `Card` (`Clip.antiAlias`) holding
an `ExpansionTile`, **collapsed**, with `const Border()` shapes so it draws no
lines of its own: `Verovatno imate (N)` in `titleSmall` (the document's
locale), then a subline in `bodySmall` `onSurfaceVariant` that **teaches the
long-press**, in the **reader's** locale (an instruction, so chrome):
collapsed `Dugo pritisnite stavku da je premestite ovde.` / `Long-press any
item to move it here.`, expanded `Dugo pritisnite stavku da je vratite na
listu.` / `Long-press an item to move it back.` The same `IngredientLineRow`s
inside; every staple row carries a 16dp `push_pin_outlined` in `outline` as
its name marker, tooltip `Uvek u Verovatno imate` / `Always in Probably have`
(chrome). The pin is drawn from `isPantryStaple`, not from the card; every
Probably-have row is a staple, so every one carries it.

**The no-list state.** Under the range bar (and its range line), the carded
`AppEmptyState(card: true)`: `shopping_basket_outlined`, `Još nema liste.`/
`No list yet.`, the body, and one tonal `Napravi listu`/`Generate list` — no
leading icon, on the recipe list's precedent. Chrome, so the reader's locale
(D94). It stays inside the `RefreshIndicator`; pull-to-refresh still works.

### Import capture

The entry screens (link, paste, photo): body padded `lg`, the intro paragraph
in `bodyLarge` `onSurfaceVariant`, `xl`, then the fields, then the inline Read
(§ Action bar). The import routes keep the automatic back arrow, not the
frame's ✕ (D140).

**The waiting state** (the review screen while the job is queued or being
read) follows `AppEmptyState`'s rhythm with a spinner for its icon: the
default-size `CircularProgressIndicator` (`primary` on a
`surfaceContainerHighest` track), `lg`, `Čitanje recepta...` / `U redu
čekanja...` in `titleMedium`, `sm`, the hint in `bodyMedium`
`onSurfaceVariant`, all centred and padded `xxl` horizontally. Pinned under it
on `AppActionBar`, a full-width outlined `Odbaci ovaj uvoz` with **no
confirm**: nothing has been parsed yet, so, as in the Failed state, nothing is
lost. The model call already under way still runs and still counts against
quota.

### Import review

All of these are private in `import_review_screen.dart`; none is in
`core/widgets/` (one consumer each). The screen is built for speed (D8):
reading, not editing, is the workflow.

**The summary card.** A theme `Card` padded `lg`: the matched count in
`titleMedium`, `md` below a 4dp `LinearProgressIndicator` (`primary` on
`surfaceContainerHighest`, radius `xs`), and — only when something is flagged
— `md` below a 3px × 16dp `reviewMarker` bar, `sm`, then `N vredno pažnje pre
čuvanja` in `bodyMedium` `onSurfaceVariant`. Paprika is the bar, never the
text.

**The title field.** Its label above it in `titleSmall`, `sm` gap, the field
from the theme with `bodyMedium` typed text; no local border.

**Ingredient lines.** The shared `IngredientLinesEditor` in its review style
(§ Ingredient lines): read-only `IngredientLineRow`s, every one inset, no
grip. **Tap opens one** in place into the open line, with its live preview,
fast entry and the suggestion pill; opening another closes it (one open at a
time). There is no `Done` any more (D159). A blank line always renders open,
and Add ingredient opens the line it adds. Long-press drags. Flagged means matched without auto-accept — an
unmatched line is **not** flagged, it gets the dashed ring.

**Method.** A theme `Card` holding a collapsed `ExpansionTile` (`const
Border()` shapes, `expand_more` in `outline`): `Postupak` in `titleMedium`,
`N koraka` in `bodyMedium` `onSurfaceVariant`, N counting steps only. It
expands **in place** to the step fields and Add step. No route, so no
chevron. A heading or note field carries a `title` /
`sticky_note_2_outlined` prefix icon in `outline`, so it doesn't read as one
more step.

**Notes.** The same collapsed `ExpansionTile` card as Method, `md` (12) below
it: `Napomena` in `titleMedium`, then the note's first words on one line with
an ellipsis (whitespace collapsed), or `Nije pronađena` / `None found`, in
`bodyMedium` `onSurfaceVariant`. It expands in place to one multiline field
(`minLines` 3, growing); the subline follows what is typed.

**The action bar.** `AppActionBar` (§ Action bar), pinned under the list —
this screen's bar is the one the widget was lifted from. Outlined `Odbaci ovaj uvoz`
and filled `Sačuvaj recept` as equal halves, `md` apart, each with `lg`
horizontal padding so the Serbian fits on one line at 360dp. Discard sits
behind a confirm dialog whose destructive action is a `TextButton` in
`destructive` — text, not a filled button. The Failed state's discard needs
no confirm: a failed parse has nothing to lose.

### Household

All of these are private in `household_screen.dart`; none is in
`core/widgets/` (one consumer each).

**The header.** `sm` below the app bar (Settings' top inset), the
household's name in `headlineSmall`, wrapping with no `maxLines`, and under
it `xs` then the member count (`2 člana` / `2 members`) in `bodyMedium`
`onSurfaceVariant`, once the members have loaded. The edit
icon sits top-right beside it and opens the rename dialog.

**Member rows.** `ListTile`s: a 40dp (`avatar`) mustard
`AppMonogramTile(circular: true)`, the name in `titleMedium` `onSurface`,
and the role as subtitle in `bodyMedium` `onSurfaceVariant` — `Član · vi` /
`Member · you` on the caller's own row. That is Settings' name/role pair
(D146), set on each tile, not in `listTileTheme`, which other screens share. The role is in the
text, so the avatar is never colour-coded by it. A `⋮` overflow with one
`destructive` item, Remove member, appears **only** on another member's row
when the caller is the owner. A full-width hairline under every row.

**Invite cards.** A theme `Card` padded `lg`, `md` apart: the code in
`titleLarge` with `sm` letter spacing and tabular figures (the join field's
exact style), `xs`, the expiry in `bodyMedium` `onSurfaceVariant`, `md`, then a
`Wrap` of a tonal Copy code and a `destructive` text Revoke — a narrow card
wraps by whole button. No codes is one `bodyMedium` `onSurfaceVariant` line,
not `AppEmptyState`. Create invite code is an outlined button, left-aligned.

**The destructive button.** One slot at the bottom: `xl`, a hairline, `sm`,
then a left-aligned `TextButton.icon` in `destructive` — Delete household
(`delete_forever_outlined`) for the owner, Leave household (`logout`) for an
adult. An `xs` start inset plus the theme's `lg` button padding puts the icon
at 20dp (D146). Only one ever renders, and neither while the caller's role is
unknown — absent, not disabled (D115).

### Settings

All private in `settings_screen.dart`; none is in `core/widgets/`.

**Groups.** A `titleSmall` `onSurfaceVariant` header (`Izgled`, `Jezik`,
`Domaćinstvo`, `Nalog`), `md`, then a theme `Card` padded `lg`. Groups sit
`xl` (24) apart. The profile card comes first, with no header: the 40dp
circular monogram, `lg`, then the name in `titleMedium`, the email and
`Prijavljeni ste Google nalogom` in `bodyMedium`, both `onSurfaceVariant`. Loading and error keep their text in the same card.

**The two selectors.** Both full-width `SegmentedButton`s. Theme: `Tema` in
`titleMedium`, `xs`, the "this app only" line in `bodyMedium`
`onSurfaceVariant`, `md`, then `light_mode_outlined` Svetla /
`dark_mode_outlined` Tamna with `showSelectedIcon: false` — the sun or moon
stays on the selected segment, not a check. Language: `Srpski` / `English`,
never translated, with the check. The stadium shape, `outline` stroke and
`onSurface` unselected label come from `segmentedButtonTheme`, shared by
every `SegmentedButton` in the app.

**The household row.** The whole card is an `InkWell` clipped to its radius:
`home_outlined` in `onSurfaceVariant`, `lg`, the household's name in
`titleMedium` over `2 člana` in `bodyMedium`, and a trailing `chevron_right`.

**Sign out** is set apart: `xl`, a full-width hairline, `xl`, the `Nalog`
header, then the neutral outlined button (§ Buttons).

### Menu, snackbar, banner

Menus radius 16 at level 2. Menu items — `MenuItemButton` (`menuButtonTheme`)
and `PopupMenuItem` (`popupMenuTheme`) alike — are `bodyMedium` w400 in
`onSurface`. The recipe list's add menu keeps its leading `_outlined` icons,
though the design's menu has no icon slot. Snackbars on `inverseSurface` with the action in
`inversePrimary`. A snackbar that confirms a reversible change carries a `Poništi` /
`Undo` `SnackBarAction`, its colour left to the theme (`inversePrimary`) —
the first is the shopping list's pantry move. The offline banner on `offline` / `onOffline` — calm.

### Dialog

`surfaceContainerHigh`, radius 28, level 3. Title in `titleLarge` (sans),
body in `bodyMedium`. A destructive confirm is a `TextButton` in
`destructive` (`TextButton.styleFrom(foregroundColor: kitchen.destructive)`),
never a filled button: Discard import, Remove member, Leave household, Delete
household. The longest body
copy in the app lives in these — they have to hold a 147-character Serbian
sentence without scrolling.

### Empty state

A 48dp icon in `outline`, a `titleMedium` title, a `bodyMedium` body, and at
most one tonal action.

**The card variant** — `AppEmptyState(card: true)` — is the design's shape for
an empty screen region: the same column on a `KitchenColors.card` panel,
radius 12, no border or shadow, inset `lg` and aligned to the top, padded
`xxl` top and bottom and `xl` at the sides. The recipe list uses it for both
its empty states. The shopping list's no-list state uses it too, with
`shopping_basket_outlined` and a tonal `Napravi listu`/`Generate list`; import
review stays bare.

The recipe list's no-results state is the example of that one action. While a
filter is on (Favorites or a tag) it shows `search_off`, `Nema recepata koji se
poklapaju.`, the body `Uklonite neki filter da biste videli više recepata.`,
and a `FilledButton.tonal` `Poništi filtere` that clears the filters. With only
a search query it has the same title and no action — the field's own clear
button is the way out.

### The shared widgets, and where each one is

Reach for these rather than re-deriving them. Homes follow § Where a component
lives, below.

| Widget | File |
|---|---|
| `AppBadge` | `core/widgets/app_badge.dart` |
| `AppMetaRow` / `AppMetaItem` | `core/widgets/app_meta_row.dart` |
| `AppMonogramTile` | `core/widgets/app_monogram_tile.dart` |
| `AppStatStrip` / `AppStatColumn` | `core/widgets/app_stat_strip.dart` |
| `AppSearchField` | `core/widgets/app_search_field.dart` |
| `AppEmptyState` | `core/widgets/app_empty_state.dart` |
| `AppErrorView` | `core/widgets/app_error_view.dart` |
| `AppSectionHeading` | `core/widgets/app_section_heading.dart` |
| `AppFieldLabel` | `core/widgets/app_field_label.dart` |
| `AppActionBar` | `core/widgets/app_action_bar.dart` |
| `RecipeCard` | `core/recipes/widgets/recipe_card.dart` |
| `IngredientLineRow` | `core/ingredients/widgets/ingredient_line_row.dart` |
| `IngredientLinesEditor` | `core/ingredients/widgets/ingredient_lines_editor.dart` |
| `RecipeGroupHeading` | `core/recipes/widgets/recipe_group_heading.dart` |

`AppBadge` has two looks, both 24 tall, radius `xs`, the label in
`labelMedium` `onSurfaceVariant`:

- **outlined** (the default) — Draft: an `outline` hairline, no fill;
- **tonal** (`tonal: true`) — Machine translation (the recipe detail and the
  translation review) and Translating…: a
  `surfaceContainerHighest` fill, no border, an optional 16dp `leading` icon
  and an `xs` gap before the label.

`AppSectionHeading` takes an optional `trailing` string, in `bodyMedium`
`onSurfaceVariant`, baseline-aligned at the right (the recipe detail's
`for 8 servings` beside Ingredients). Without it the heading is unchanged.

`AppMonogramTile(circular: true)` is a person (member, profile); the square
is a thing (recipe).

`IngredientLineRow` takes **primitives, not a model** — a `RecipeIngredient`
and a `RecipeDraftLine` carry the same five facts under different types, and
strings are what let the detail screen and the import review screen share one
row. `AppStatColumn`'s value is a `Widget` for the same reason: one column on a
recipe is five stars.

`IngredientLinesEditor` is the ingredient list being edited, in the recipe
editor and import review. It takes the lines, the recipe's locale, units,
parser and callbacks, plus `review` (import review's inset, gripless rows with
`→ catalog name` trailers) and `flagged` (the ids to tint); it owns only which
line is open. `RecipeGroupHeading` is shared by step headings and ingredient
sections — one look, the caller passes the gaps.

---

## Where a component lives

A widget lives in `lib/core/widgets/` when it is **generic and
feature-agnostic** — it does not know what a recipe or a meal plan is.

A widget that is shared but knows its subject lives in the middle ground:
`core/recipes/widgets/`, `core/meal_plan/widgets/`, `core/ingredients/widgets/`
(D43, D53). That folder exists because two features needed the same thing and a
direct cross-feature import was not allowed.

Everything else stays in its own feature's `presentation/`. The bar for
promoting a widget is that a *second* feature actually needs it — not that one
might.

CLAUDE.md's rule stands regardless: cross-feature imports go through `domain/`
only.

---

## Both languages, one layout

Serbian strings run longer than their English pairs — a mean of 1.12x across
all 255 UI strings, but up to 4x on the short strings that sit in chips,
buttons and labels (`Nuts` / `Orašasti plodovi`). A component that fits `en`
and truncates, wraps badly or overflows in `sr` is a bug, not a rendering
detail.

Serbian also has a `few` plural form English lacks, and dates order their
fields differently by locale (`Mon, Sep 14` vs `pon 14. sep`) — a layout that
assumes one shape will not hold.

Nothing automated catches any of this. `test/core/l10n/arb_parity_test.dart`
checks that every key exists on both sides; it says nothing about width. So a
layout change is verified by looking at it, in both languages, on a device.

Design and check in Serbian first. If it fits in Serbian it fits in English;
the reverse is how the one confirmed live defect shipped.

Serbian displays in Latin script only. Fixed in CLAUDE.md, not a design
question.

---

## Light and dark

Both are real, neither is an afterthought. The cook picks one in Settings →
Izgled; the app **does not follow the phone's setting** (D128). `lib/main.dart`
passes `AppTheme.light()` and `AppTheme.dark()` and takes `themeMode` from
`appThemeModeProvider` (`core/theme/app_theme_mode.dart`): Light or Dark only,
Light by default, no System option. The choice is device-local, in the Drift
`device_preferences` table, and survives sign-out and cache schema bumps.
`main.dart` reads it before `runApp`, so a Dark cook never sees a Light
first frame.

**The Android launch screen is flat `primary` green (`#366A35`) in both of
the phone's modes**, with the logo mark centred on it (§ Logo; D130): the
adaptive icon's foreground drawn on a 288dp canvas, Android 12's size for a
splash icon without a background, so it matches either side of 12. Android
draws it before any Dart runs, so it can't know the in-app choice. A cream or
near-black splash would flash the wrong theme for half the cooks, while the
brand colour looks intended in front of either. It lives in
`android/app/src/main/res/values/colors.xml` (`splash_background`), used by
`launch_background.xml`, `values-v31/styles.xml`, `NormalTheme` and the
adaptive icon's ground. There is deliberately no `values-night`. Change the
brand green, change it there too. iOS's `LaunchScreen.storyboard` is the same
green with the same mark (`LaunchImage`).

Every colour decision holds in both or it is not a decision. A value tuned in
one brightness and eyeballed in the other is how a redesign ends up with an
unreadable dark mode.

Verify both, every time.

## Logo

The mark is "bowl on the table" (D130): two wisps of steam over a bowl with a
band, on a small table, on the brand green. Four colours, all Garden light
values:

| Part | Colour | Role |
|---|---|---|
| Ground | `#366A35` | `primary` |
| Table, steam | `#FFF7EC` | `surface` |
| Bowl | `#FFDEA4` | `secondaryContainer` |
| Band | `#AC3F25` | `tertiary` |

The sources live in `docs/design/logo/` (and `docs/design/app-logo.pdf`), on
Android's 108-unit adaptive canvas with the mark inside the 66-unit safe
zone. `android-adaptive-foreground.svg` is the source of truth for the shapes.

- **Android adaptive and launch mark**: hand-written VectorDrawables,
  `res/drawable/ic_launcher_foreground.xml` and `ic_launcher_monochrome.xml`,
  path data copied from the SVGs. No icon package (rule 8).
- **Themed icon (Android 13+)**: the same shapes in one colour, with the band
  cut out of the bowl so it still reads. VectorDrawable has no mask, so the
  bowl is a rim and a base either side of the band, a straight cut.
- **Raster icons** (Android legacy `mipmap-*`, iOS `AppIcon`, iOS
  `LaunchImage`): rendered by `tool/gen_app_icons.py` (`make icons`) through
  headless Chrome and PIL. Re-run it when `docs/design/logo/` changes, and
  edit the VectorDrawables to match by hand.

The launcher label stays "Kitchen Table" in both locales. In the app (D137),
sign-in shows the lockup (`lockup-en-*.svg`, mark plus Literata wordmark) as a
raster PNG, light or dark, and create / join show the mark as a 56dp rounded
PNG tile. Both are written by `make icons` into `assets/brand/` at 1x / 2.0x /
3.0x. Literata is baked into the PNG and is never UI type. The third output
there is the Google G for the sign-in button, from `docs/design/google/`
(Google's own sign-in assets), not recoloured.
