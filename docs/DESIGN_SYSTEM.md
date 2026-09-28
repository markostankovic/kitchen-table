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
row and lightened the steps. It replaces `docs/DESIGN.md`, which is now only a
pointer at this file.

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
| `outline` | `#6F6759` | `#96978A` | muted icons, badge edge, the dashed unmatched ring |
| `outlineVariant` | `#D1C8B8` | `#494A3F` | card hairline, dividers |

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

Two faces. **The platform sans** (Roboto on Android, San Francisco on iOS) for
every Material role but one. **Literata** — bundled, OFL, weights 400 and 600
under `assets/fonts/` — for recipe titles and the wordmark, nothing else.

A screen picks a role for what the text *is*, never a raw `fontSize`.

| Role | Size / line | Weight | Face | For |
|---|---|---|---|---|
| `displaySmall` | 36 / 44 | 600 | Literata | the wordmark, in `primary`, and nothing else |
| `headlineSmall` | 26 / 32 | 600 | sans | the household's name (a *recipe's* detail title is `KitchenType.recipeTitleLarge`) |
| `titleLarge` | 22 / 28 | 600 | sans | app bar, dialog titles |
| `titleMedium` | 18 / 24 | 600 | sans | section headings, sheet titles, empty-state titles |
| `titleSmall` | 14 / 20 | 600 | sans | labels, settings group headers |
| `bodyLarge` | 18 / 28 | 400 | sans | the reading text — recipe steps, ingredient lines |
| `bodyMedium` | 14 / 20 | 400 | sans | default copy |
| `bodySmall` | 12 / 16 | 400 | sans | captions, meta |
| `labelLarge` | 14 / 20 | 600 | sans | buttons, chips, the step number |
| `labelMedium` | 12 / 16 | 500 | sans | badges, nav labels |

Roles not listed keep Material 3's defaults; nothing in the app needs them.

### `KitchenType` — the recipe titles

A `ThemeExtension` in `lib/core/theme/kitchen_type.dart`, read as
`Theme.of(context).extension<KitchenType>()!`, built from the scheme like
`KitchenColors`. Deliberately not a Material role.

| Token | Size / line | Weight | Face | For |
|---|---|---|---|---|
| `recipeTitle` | 18 / 24 | 600 | Literata, `onSurface` | a recipe's name on a recipe card and on a meal-plan entry |
| `recipeTitleLarge` | 26 / 32 | 600 | Literata, `onSurface` | a recipe's title on its detail screen, and the monogram letter on a card's 72dp tile |

**Literata reaches a screen only through `displaySmall` or `KitchenType`**
(D127). A serif on screen always means "this is a recipe's name". Screen
titles, section headings, steps, ingredient lines and the household name are
sans. The warmth the all-serif scale used to carry now comes from the cream
ground, the green / mustard / paprika palette, the monogram tiles, and the
serif recipe names.

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
| `full` | stadium | buttons, the search field, the nav indicator |

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
| `signInButton` | 52 | the sign-in screen's Google button |
| `field` | 52 | filled text field, search |
| `chip` | 40 | filter chips — 32 for input tags |
| `appBar` | 64 | top app bar |
| `nav` | 80 | `NavigationBar` |
| `icon` / `iconInButton` / `iconInMeta` | 24 / 20 / 16 | actions · inside buttons · in meta lines |
| `thumb` | 72 | recipe card photo or monogram tile |
| `stepDisc` | 28 | the step-number disc on a recipe — one `bodyLarge` line, so it centres on the first line with no offset |
| `avatar` | 40 | a person's monogram circle — member, profile |
| `emptyStateIcon` | 48 | `AppEmptyState`'s icon |

`emptyStateIcon` is its own name rather than a borrowed `target`: they are the
same number today, but one is a hit area and the other is a drawing, and they
have no reason to move together. `signInButton` is not `field` for the same
reason.

`AppDurations`: 150 ms for a small state change, 250 ms for a transition,
emphasized easing. **No decorative animation.** The class exists so later
slices have a name to reach for, not so anything animates for its own sake.

---

## Elevation

Flat by default. `surfaceTintColor: Colors.transparent` everywhere — tone comes
from the container roles, not from Material's tint.

| Level | Where | How |
|---|---|---|
| 0 | cards, app bar, nav bar, fields | a container-role tone step plus a 1dp `outlineVariant` hairline. No shadow. |
| 2 | menus, snackbar | a soft two-layer shadow (y1 blur2, y2 blur6 spread2) |
| 3 | dialogs, bottom sheets | the same, heavier; in dark, black at 60% |

Scrim behind dialogs and sheets: `#1F190F` at 32% in light, black at 50% in dark.

---

## The semantic layer — `KitchenColors`

(Its type counterpart, `KitchenType`, is in § Type.)

A `ThemeExtension` read as `Theme.of(context).extension<KitchenColors>()!`.
Every member is an alias of a role above, so there is no second palette to keep
in sync — what it adds is a name for what the colour *means here*.

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
| `docLanguage` | `surfaceContainerLow` with an `outlineVariant` ring | the "SR"/"EN" tag saying which language a generated document is in |
| `destructive` | `error` | destructive actions, as text only — never a fill |

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
button is the 52dp filled `primary`, with no logo.

**Sign out** is a full-width `OutlinedButton.icon` with the `logout` icon and
`foregroundColor: onSurface` — label and icon neutral, border `outline`. Not
`error`, not `primary`: signing out loses nothing, so it is neither destructive
nor the screen's one action, and it has no confirm dialog.

**The FAB** — the recipe list's is the only one in the app — is `primary` on
`onPrimary`, radius 16, elevation 0. Not Material's `primaryContainer` default:
unthemed, it sat at 1.94:1 against the dark surface and was invisible to a
person while present in the widget tree (Phase 7 part 2's device walk). It is
the screen's one filled action, and the one filled action is `primary`
everywhere else here.

### Action bar

A screen whose save action sits at the bottom puts it on `AppActionBar`:
`surface` (not `surfaceContainer`, the nav bar's colour — the two would merge)
with a 1dp `outlineVariant` top hairline, padded `lg`/`md`, and an optional
already-localized error line above the buttons in `bodySmall` `error`, `sm`
above them. Its child is one filled button, full width, or equal `Expanded`
halves `md` apart. The busy spinner inside a button is the call site's,
`AppSizes.iconInMeta` square.

The onboarding screens (create / join household) do **not** use it: they have
no app bar and centre their form, so the filled button sits in that column,
then `sm`, then the text-button switcher.

### Cards

`surfaceContainerLow`, a 1dp `outlineVariant` hairline, radius 12, elevation 0.
That hairline is what separates a card from the ground — not a shadow.

### Navigation

App bar 64dp on `surface`, no elevation, title in sans `titleLarge`,
left-aligned. `NavigationBar` 80dp on `surfaceContainer`; the selected
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

**The label is `AppFieldLabel`** (`titleSmall`, no padding of its own). The
call site writes the gaps: `sm` from label to field, `lg` from a field to the
next label, `xl` from the last field of a group to an `AppSectionHeading`. A
field whose purpose is already said by the paragraph or title above it (the
paste box, the join code) has no label. `hintText`, `helperText` and
`counterText: ''` stay in the decoration; `labelText`, a local
`OutlineInputBorder` and `isDense` do not appear at all.

**A row of short fields labels its columns in a row of their own**, above
the row of fields: labels `Expanded` and bottom-aligned, then `sm`, then the
fields top-aligned. A label that wraps at 360dp (`Priprema (min)`) pushes all
the fields down together, so they never stagger. Columns sit `sm` apart.

**A code-entry field** (the join code) is `titleLarge` with `sm` letter
spacing and tabular figures, centred, no label.

**The search field is the stadium exception.** A stadium is a shape, not a
radius, so it is not in `AppRadii` — and because `InputBorder` takes only a
`BorderRadius`, inside a decoration it is spelled
`BorderRadius.circular(AppSizes.field / 2)`. It is `AppSearchField`: no resting
border, `surfaceContainerHighest`, a magnifier in `outline`, and a clear button
once there is something to clear.

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
filters only: the search field keeps its text and its own clear button. While
the list is narrowed and non-empty, a result count (`2 recepta` /
`2 recipes`, `bodySmall` `onSurfaceVariant`) sits `sm` under the row and `sm`
above the first card.

### Ingredient lines

**Name left, amount right**: a row of `Expanded` name column, a 24dp (`xl`)
gap, then the amount — grid `1fr | auto`. `bodyLarge` 18/28, min height 48,
`sm` vertical padding, a hairline between lines.

The amount is one `Text.rich` that never wraps: the number in `primary`, w600,
tabular figures, then the unit in `onSurfaceVariant` beside it (`½ kg`). It
sizes to its content, so amounts line up on the right edge down a list. The
name, in `onSurface`, takes what is left and wraps on the left. **No amount →
name only**, with no gap reserved. Under the name, the `trailer` (note,
`→ catalog name`, extra quantities, unmatched raw lines) in `bodySmall` muted.

- **matched** — plain
- **optional** — the `optionalLabel` (`opciono` / `optional`) inline after the
  name as ` · opciono` in muted `bodySmall`. Callers do not fold it into the
  trailer
- **unmatched** — rendered exactly as typed, with a 16dp dashed `unmatched`
  ring **inline after the name** (a `WidgetSpan`, `sm` before it; a small
  `CustomPainter`, not a package). A word joiner (U+2060) sits before it so a
  line can't break there and strand the ring alone on the next line. The PDF draws it at 14; 16 is the existing
  `iconInMeta` and a token for 2dp is not worth it. Never `error`, never red —
  a line the catalog did not know is a supported outcome, not a fault
- **flagged** (import review only) — a 3px `reviewMarker` left edge painted
  as a **foreground** (it takes no layout) on a `surfaceContainerLow` tint.
  A flagged row is always inset (below), so the name clears the marker

**`inset`** pads a row's content `md` in from both edges, while its hairline
and tint still run the full width. Import review sets it on **every** row, so
flagged and unflagged names and amounts line up (`Review import@1x.png`). The
recipe detail and the shopping list sit flush with the gutter
(`Recipe@1x.png`).

On import review the name is the local parse of the raw text, falling back to
the whole raw text when there is no usable parse, and a matched line's trailer
leads with `→ <catalog name>` (in the recipe's language), joined to the note
with ` · `.

**The match chip under a field being typed** (`IngredientMatchChip`) follows
two people. Its **status words** — `No match` / `Nema poklapanja`, and the
`{name}?` wrapper of a suggestion — are chrome and follow the **reader**. The
amount, the unit names inside it, the suggested catalog name and the field's
hint follow the **recipe** (D86). Unmatched and suggested chips set their label
in `onSurfaceVariant` and their `help_outline` icon in `outline` — `outline`
is never text.

Rows take `showDivider`: the last row of a card omits its hairline, so the
card's own edge does the separating. Every other row keeps it, including the
last of a block followed by a gap: a hairline missing mid-card reads as
uneven spacing, not as a break.

### Steps and stats

A step number, in `labelLarge` `onPrimaryContainer`, sits in a 28dp
`todayContainer` disc; `lg` (16) to the step itself in `bodyLarge` (sans
18/28, w400 — no bold); `xl` (24) between steps. The servings / prep / cook /
rating strip puts labels in `bodySmall` muted above values in `bodyLarge`
w600 `statValue`.

### Recipe card

A 72dp photo, or — far more often — a monogram tile: the title's first letter
on `secondaryContainer`, in `KitchenType.recipeTitleLarge`. Then the title in
`KitchenType.recipeTitle`, then a meta row.

**The meta row is a component with a rule**: each item is an icon plus its own
text, and **an item never splits across lines — a whole item wraps instead**.
There are no `·` separators. This is the shape that survives Serbian running
30% longer than English; a dot-separated run is not.

Favourite is a filled heart in `favorite`, top-right. `Draft` / `Nacrt` is a
small outlined badge, radius 4, in `labelMedium`.

### Meal entries

All of these are private classes in `meal_plan_screen.dart` — each has one
consumer, so none of them is in `core/widgets/`.

**The day card.** The theme's `Card` (`surfaceContainerLow`, 1dp
`outlineVariant`, radius 12), padded `md`, with the day header in
`titleSmall` `onSurface` — `weekdayAndDay` (`pon 14`) in the week view, where
the week bar already names the month, and `shortDateLabel` in the Today view.
Today's card keeps that fill and gets a **2dp border in `today`** plus a
`Danas`/`Today` pill beside the header: `today` fill, `onPrimary` text in
`labelMedium`, `StadiumBorder`, `sm` horizontal padding. Today is outlined,
not filled.

**Entry cards.** Nested inside the day card, grouped by slot in
`MealSlot.ordered` order, `sm` apart: `surfaceContainerLowest` fill, 1dp
`outlineVariant`, radius 12, padded `md`. On top an `AppMetaRow` — the slot as
plain `bodySmall` `onSurfaceVariant` text, then a servings item
(`soup_kitchen_outlined`) for a recipe, a `Napomena`/`Note` item
(`edit_note_outlined`) for a note, or `od pon 14.`/`from Mon 14`
(`event_outlined`) for a leftover whose source is in the loaded week. Then,
`xs` below, a recipe or leftover title in `KitchenType.recipeTitle`, or a
note's own words in sans `bodyLarge`,
wrapping rather than truncating. **No thumbnail or monogram** — an entry
carries a recipe's title and servings, not the recipe (D53).

**Leftovers.** The same card with a **dashed 1dp `outline` border** (a private
`CustomPainter` along the `RRect`, no package) and a leading return icon in
`leftover`, so it reads as derived from another meal rather than as a meal of
its own. The source's day is the abbreviated `weekdayAndDay` on purpose: a
full Serbian weekday would have to be declined after `od`.

**Adding.** Under the entries, a `Wrap(spacing: sm, runSpacing: xs)`: a quiet
`+ <Slot>` text button (`onSurfaceVariant`) for each **empty** slot — inviting
without shouting — then a trailing icon-only `+` in `primary` that opens the
slot chooser (a small bottom sheet of the four slots). The `+` is how a second
entry gets into a filled slot. **A week-view day with nothing planned, other
than today, collapses** to one compact card on `surface` — lighter than a
planned day — with the header on the left and `+ Dodaj obrok`/`+ Add meal` in
`primary` on the right, which opens the same chooser. The Today view never
collapses.

**Drag.** Long-press lifts the entry card itself at its own width, on
`Material` elevation 2. Three drop targets, each highlighted in
`primaryContainer` while a drag is over it: a filled slot's group of entry
cards, a `+ <Slot>` button, and a collapsed day — which **keeps the entry's
own slot**, since it shows none to aim at.

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
the quantity column with its unit beside the name, any further unit family
(never merged, D9) and every unmatched raw line in the trailer. Items are
grouped and ordered by `groupByCategory`, with blocks `md` apart, a hairline
under **every** row but the card's last, and **no category headings** — D105-amended: headings were noise when scanning a list
in a shop, and the Garden mock that draws them was declined. Omitted when
nothing is to buy. Long-press toggles a pantry staple (D13: the snapshot is
not rewritten; the snackbar says it applies next time).

**The staples card.** `md` below, a second `Card` (`Clip.antiAlias`) holding
an `ExpansionTile`, **collapsed**, with `const Border()` shapes so it draws no
lines of its own: `Verovatno imate (N)` in `titleSmall`, the staples subtitle
in `bodySmall` `onSurfaceVariant`, the same `IngredientLineRow`s inside.

### Import review

All of these are private in `import_review_screen.dart`; none is in
`core/widgets/` (one consumer each). The screen is built for speed (D8):
reading, not editing, is the workflow.

**The summary card.** A theme `Card` padded `lg`: the matched count in
`titleMedium`, `md` below a 4dp `LinearProgressIndicator` (`primary` on
`surfaceContainerHighest`, radius `xs`), and — only when something is flagged
— `md` below a 3px × 16dp `reviewMarker` bar, `sm`, then `N vredno pažnje pre
čuvanja` in `bodySmall` `onSurfaceVariant`. Paprika is the bar, never the
text.

**The title field.** Its label above it in `titleSmall`, `sm` gap, the field
from the theme with `bodyMedium` typed text; no local border.

**Ingredient lines.** Read-only `IngredientLineRow`s. **Tap opens one** in
place into the unchanged `IngredientLineField`, with a right-aligned `Done` /
`Gotovo` `TextButton` under it; opening another closes it (one open at a
time). A blank line always renders open, and Add ingredient opens the line it
adds by id. Long-press drags. Flagged means matched without auto-accept — an
unmatched line is **not** flagged, it gets the dashed ring.

**Method.** A theme `Card` holding a collapsed `ExpansionTile` (`const
Border()` shapes, `expand_more` in `outline`): `Postupak` in `titleMedium`,
`N koraka` in `bodySmall` `onSurfaceVariant`. It expands **in place** to the
step fields and Add step. No route, so no chevron.

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

**The header.** The household's name in `headlineSmall`, wrapping with no
`maxLines`, and under it `xs` then the member count (`2 člana` / `2 members`)
in `bodySmall` `onSurfaceVariant`, once the members have loaded. The edit
icon sits top-right beside it and opens the rename dialog.

**Member rows.** `ListTile`s: a 40dp (`avatar`) mustard
`AppMonogramTile(circular: true)`, the name, and the role as subtitle —
`Član · vi` / `Member · you` on the caller's own row. The role is in the
text, so the avatar is never colour-coded by it. A `⋮` overflow with one
`destructive` item, Remove member, appears **only** on another member's row
when the caller is the owner. A full-width hairline under every row.

**Invite cards.** A theme `Card` padded `lg`, `md` apart: the code in
`titleLarge` with `sm` letter spacing and tabular figures (the join field's
exact style), `xs`, the expiry in `bodySmall` `onSurfaceVariant`, `md`, then a
`Wrap` of a tonal Copy code and a `destructive` text Revoke — a narrow card
wraps by whole button. No codes is one `bodyMedium` `onSurfaceVariant` line,
not `AppEmptyState`. Create invite code is an outlined button, left-aligned.

**The destructive row.** One slot at the bottom, under a hairline: Delete
household for the owner, Leave household for an adult, text and icon in
`destructive`. Only one ever renders, and neither while the caller's role is
unknown — absent, not disabled (D115).

### Settings

All private in `settings_screen.dart`; none is in `core/widgets/`.

**Groups.** A `titleSmall` `onSurfaceVariant` header (`Izgled`, `Jezik`,
`Domaćinstvo`, `Nalog`), `sm`, then a theme `Card` padded `lg`. Groups sit
`xl` (24) apart. The profile card comes first, with no header: the 40dp
circular monogram, `md`, then the name in `titleMedium`, the email in
`bodyMedium`, and `Prijavljeni ste Google nalogom` in `bodySmall`, both
`onSurfaceVariant`. Loading and error keep their text in the same card.

**The two selectors.** Both full-width `SegmentedButton`s. Theme: `Tema` in
`titleMedium`, `xs`, the "this app only" line in `bodySmall`
`onSurfaceVariant`, `md`, then `light_mode_outlined` Svetla /
`dark_mode_outlined` Tamna with `showSelectedIcon: false` — the sun or moon
stays on the selected segment, not a check. Language: `Srpski` / `English`,
never translated, with the check.

**The household row.** The whole card is an `InkWell` clipped to its radius:
`home_outlined` in `onSurfaceVariant`, `md`, the household's name in
`titleMedium` over `2 člana` in `bodySmall`, and a trailing `chevron_right`.

**Sign out** is set apart: `xl`, a full-width hairline, `xl`, the `Nalog`
header, then the neutral outlined button (§ Buttons).

### Menu, snackbar, banner

Menus radius 16 at level 2. Snackbars on `inverseSurface` with the action in
`inversePrimary`. The offline banner on `offline` / `onOffline` — calm.

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

`AppMonogramTile(circular: true)` is a person (member, profile); the square
is a thing (recipe).

`IngredientLineRow` takes **primitives, not a model** — a `RecipeIngredient`
and a `RecipeDraftLine` carry the same five facts under different types, and
strings are what let the detail screen and the import review screen share one
row. `AppStatColumn`'s value is a `Widget` for the same reason: one column on a
recipe is five stars.

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
the phone's modes**, with no icon. Android draws it before any Dart runs, so
it can't know the in-app choice. A cream or near-black splash would flash the
wrong theme for half the cooks, while the brand colour looks intended in front
of either. It lives in `android/app/src/main/res/values/colors.xml`
(`splash_background`), used by `launch_background.xml`, `values-v31/styles.xml`
and `NormalTheme`. There is deliberately no `values-night`. Change the brand
green, change it there too.

Every colour decision holds in both or it is not a decision. A value tuned in
one brightness and eyeballed in the other is how a redesign ends up with an
unreadable dark mode.

Verify both, every time.
