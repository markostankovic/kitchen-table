# Design system — Garden

The app's visual language, stated as values and rules. Derived from the Claude
Design export in `docs/design/` (`design-system.pdf`, `key-screens.pdf`, and
the seven screen references under `docs/design/screens/`), which is the visual
source of truth for the Phase 7 redesign.

**Status.** This file describes **the code**. Phase 7 part 2 (D118) landed
the tokens: both `ColorScheme`s, the Literata type scale, `AppRadii`,
`AppSizes`, `AppDurations` and `KitchenColors` are in
`lib/core/theme/` as written here. It replaces `docs/DESIGN.md`, which is now
only a pointer at this file.

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
| `primaryContainer` | `#B9F1B3` | `#1D511E` | tonal buttons, today's day card, step-number disc |
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
at 3px — that constraint is why the role exists (D117).

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

Two faces. **Literata** — bundled, OFL, weights 400 and 600 under
`assets/fonts/` — for reading and titles. **The platform sans** (Roboto on
Android, San Francisco on iOS) for UI furniture: labels, buttons, captions.

A screen picks a role for what the text *is*, never a raw `fontSize`.

| Role | Size / line | Weight | Face | For |
|---|---|---|---|---|
| `displaySmall` | 36 / 44 | 600 | Literata | the wordmark, and nothing else |
| `headlineSmall` | 26 / 32 | 600 | Literata | a recipe's own title on its detail screen |
| `titleLarge` | 22 / 28 | 600 | Literata | screen and dialog titles |
| `titleMedium` | 18 / 24 | 600 | Literata | section headings, card titles |
| `titleSmall` | 14 / 20 | 600 | sans | field labels, tile titles |
| `bodyLarge` | 17 / 26 | 400 | Literata | the reading text — recipe steps, ingredient lines |
| `bodyMedium` | 14 / 20 | 400 | sans | default copy, empty states |
| `bodySmall` | 12 / 16 | 400 | sans | captions, meta lines |
| `labelLarge` | 14 / 20 | 600 | sans | buttons, chips |
| `labelMedium` | 12 / 16 | 500 | sans | badges, nav labels |

Roles not listed keep Material 3's defaults; nothing in the app needs them.

The serif is doing the domestic, handwritten-recipe-box work, and it is only
ever on content a person reads: a title, a step, an ingredient line. A button
label in a serif reads as decoration, which is why `labelLarge` is sans.

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
| `button` | 48 | all buttons — the sign-in button is 52 |
| `field` | 52 | filled text field, search |
| `chip` | 40 | filter chips — 32 for input tags |
| `appBar` | 64 | top app bar |
| `nav` | 80 | `NavigationBar` |
| `icon` / `iconInButton` / `iconInMeta` | 24 / 20 / 16 | actions · inside buttons · in meta lines |
| `thumb` | 72 | recipe card photo or monogram tile |
| `emptyStateIcon` | 48 | `AppEmptyState`'s icon |

`emptyStateIcon` is its own name rather than a borrowed `target`: they are the
same number today, but one is a hit area and the other is a drawing, and they
have no reason to move together.

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

A `ThemeExtension` read as `Theme.of(context).extension<KitchenColors>()!`.
Every member is an alias of a role above, so there is no second palette to keep
in sync — what it adds is a name for what the colour *means here*.

| Token | Alias of | Means |
|---|---|---|
| `today` | `primary` | the "Danas"/"Today" pill and the day header it belongs to |
| `todayContainer` | `primaryContainer` | today's day card, and the step-number disc |
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
| Outlined | none, `outline` border | cancel-weight (Discard this import) |
| Text in `error` | none | destructive (Delete recipe, Leave household) |

### Cards

`surfaceContainerLow`, a 1dp `outlineVariant` hairline, radius 12, elevation 0.
That hairline is what separates a card from the ground — not a shadow.

### Navigation

App bar 64dp on `surface`, no elevation, title in Literata `titleLarge`,
left-aligned. `NavigationBar` 80dp on `surfaceContainer`; the selected
destination is a **`primary` pill with an `onPrimary` icon and a `primary`
label** — not Material's default `secondaryContainer` indicator.

### Inputs

Filled, 52dp, radius 8, no underline. **The label sits above the field** in
`titleSmall`, not floating inside it. Focus is a 2dp `primary` border.
Validation text is `error`, below the field.

### Chips

40dp, radius 8 (32dp for an input/tag chip). Selected is `secondaryContainer`
plus a check icon — selection reads as colour, not only as an outline. **A
filter row scrolls horizontally and never wraps**: a wrapping row grows
downward and eats the list beneath it.

### Ingredient lines

`bodyLarge`, with a hairline between lines. The quantity is `primary`,
right-aligned in its own narrow column so fractions line up; the unit is
`onSurfaceVariant`; the name is `onSurface`. Four states:

- **matched** — plain
- **optional** — an `opciono` / `optional` suffix in muted `bodySmall`
- **unmatched** — a dashed `unmatched` ring, rendered as typed
- **flagged** (import review only) — a 3px `reviewMarker` left edge and a
  tinted row

### Steps and stats

A step number sits in a 32dp `todayContainer` disc, the step itself in
`bodyLarge`. The servings / prep / cook / rating strip puts labels in
`bodySmall` muted above values in `statValue`.

### Recipe card

A 72dp photo, or — far more often — a monogram tile: the title's first letter
on `secondaryContainer`. Then the title, then a meta row.

**The meta row is a component with a rule**: each item is an icon plus its own
text, and **an item never splits across lines — a whole item wraps instead**.
There are no `·` separators. This is the shape that survives Serbian running
30% longer than English; a dot-separated run is not.

Favourite is a filled heart in `favorite`, top-right. `Draft` / `Nacrt` is a
small outlined badge, radius 4, in `labelMedium`.

### Meal entries

`MealEntry` is a nested card inside its day card: slot and servings in muted
`bodySmall`, the recipe title in Literata below. `LeftoverEntry` is the same
shape with a dashed border and a return icon in `leftover` — it reads as
derived from another meal rather than as a meal of its own. `EmptySlot` is a
quiet text button (`+ Doručak`), inviting without shouting.

### Menu, snackbar, banner

Menus radius 16 at level 2. Snackbars on `inverseSurface` with the action in
`inversePrimary`. The offline banner on `offline` / `onOffline` — calm.

### Dialog

`surfaceContainerHigh`, radius 28, level 3. Title in `titleLarge` Literata,
body in `bodyMedium`, a destructive action as text in `error`. The longest body
copy in the app lives in these — they have to hold a 147-character Serbian
sentence without scrolling.

### Empty state

A 48dp icon in `outline`, a `titleMedium` title, a `bodyMedium` body, and at
most one tonal action.

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

Both are real, both follow the system setting, neither is an afterthought.
`lib/main.dart` passes `AppTheme.light()` and `AppTheme.dark()` and sets no
`themeMode`. There is no in-app theme toggle.

Every colour decision holds in both or it is not a decision. A value tuned in
one brightness and eyeballed in the other is how a redesign ends up with an
unreadable dark mode.

Verify both, every time.
