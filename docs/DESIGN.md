# Design

What the app looks like, stated as rules rather than history.

`docs/ROADMAP.md` and `docs/journal/` record what *changed*. This file records
what is *true now*: the colour roles, the type scale, the spacing scale, and
what belongs in a shared component. A slice that changes the design language
changes this file in the same slice — the same way a schema change updates
`docs/DATA_MODEL.md`.

Load one section, not the file. Written for Phase 7 (see `docs/ROADMAP.md`);
Part 1 of that phase is what fills in Colour, Type and Spacing below.

---

## Current state

`lib/core/theme/app_theme.dart` builds `ThemeData` for each brightness from
one seed colour, `0xFF7A5C3E` (a warm mid brown), through
`ColorScheme.fromSeed` — same identity as Phase 0, but the roles the app
actually reads are now pinned explicitly rather than left to whatever the
generator produced, and a handful of component themes
(`AppBarTheme`, `ChipThemeData`, `FilledButtonThemeData`, `ListTileThemeData`,
`InputDecorationTheme`) are set once here instead of drifting per screen.
`lib/core/theme/app_spacing.dart` names the spacing scale. See Colour, Type
and Spacing below.

`lib/core/widgets/` holds `placeholder_screen.dart` plus three widgets added
in Phase 7 Part 1: `AppErrorView`, `AppSectionHeading`, `AppEmptyState`. See
Components.

---

## Colour

Everything comes from one seed, `0xFF7A5C3E` (a warm mid brown), through
`ColorScheme.fromSeed` — one call for `AppTheme.light()`, the same seed again
with `Brightness.dark` for `AppTheme.dark()`. A screen never reaches for a raw
`Color`; it reaches for a role on `Theme.of(context).colorScheme`.

The roles the app actually uses, and what each means here:

- **`primary` / `onPrimary`** — the one emphasised action: `FilledButton`
  (save, confirm, generate), and the "this is today" highlight on the meal
  plan's day column.
- **`error` / `errorContainer` / `onErrorContainer`** — form validation
  messages and the offline banner. `error` alone for inline text (a field's
  error line), the container pair together for the banner's own background
  and its text/icon on top of it — never `error` as a background colour, it
  is not built for that contrast.
- **`tertiary` / `onTertiary`** — the "look here" accent, distinct from both
  `primary` and `error`: the left-edge marker on an import line flagged for a
  second look (`import_review_screen.dart`). `fromSeed`'s own generated dark
  `tertiary` sat too close in tone to its generated dark `secondary` to read
  at the 3px border width that marker is drawn at, so dark mode overrides it
  to `0xFFE7C17E` / `0xFF422C00` — light mode keeps the generated value.
- **`outline`** — muted icon colour: `placeholder_screen.dart`'s icon,
  `AppEmptyState`'s icon, the source-attribution icon on a recipe's detail
  screen. Never body text — outline is tuned for the low-emphasis role, not
  for reading.
- **`onSurfaceVariant`** — secondary/muted text sitting next to primary text
  of the same size: the translation reviewer's "original" line above the
  editable translation.
- **`surfaceContainerHighest`** — fill for a `Chip` and for a filled
  `TextFormField` (`InputDecorationTheme.fillColor`), so both read as
  slightly raised off the scaffold background without a border.
- **`secondaryContainer`** — a selected `ChoiceChip`/`FilterChip`'s
  background, so "selected" reads as a colour change rather than only an
  outline.

Nowhere in the app is a raw `Color` literal used for something Material 3
already has a role for. `AppTheme`'s own two seed/override literals are the
exception — they are where a role's value is *defined*, not a call site
reaching around a role.

---

## Type

The platform default font — Roboto on Android, San Francisco on iOS. No
`google_fonts`, no bundled `.ttf`; that was asked and declined for Phase 7
Part 1 (CLAUDE.md rule 8). A font swap later is a one-line change to
`AppTheme._textTheme` — this section defines the roles, not the typeface.

A screen picks a role for what the text *is*, never a raw `fontSize`:

| Role | Size / weight | For |
|---|---|---|
| `titleLarge` | 22 / w600 | Screen and dialog titles |
| `titleMedium` | 17 / w600 | Section headings (`AppSectionHeading`), AppBar titles |
| `titleSmall` | 14 / w600 | Field labels, list tile titles |
| `bodyLarge` | 16 / w400 | Primary reading text: recipe steps, ingredient lines |
| `bodyMedium` | 14 / w400 | Default body copy, empty-state text |
| `bodySmall` | 12 / w400 | Captions, secondary/muted text |
| `labelLarge` | 14 / w600 | Buttons, chip labels |
| `labelMedium` | 12 / w500 | Small chip labels, tooltips |

Roles this table does not list (`displayLarge`, `headlineMedium`, ...) are
still Material 3's own defaults — nothing in the app currently needs them, so
they were not worth pinning.

---

## Spacing and layout

`lib/core/theme/app_spacing.dart` names the scale that was already the
de-facto one across the app before it had a name:

| Name | Value |
|---|---|
| `AppSpacing.xs` | 4 |
| `AppSpacing.sm` | 8 |
| `AppSpacing.md` | 12 |
| `AppSpacing.lg` | 16 |
| `AppSpacing.xl` | 24 |
| `AppSpacing.xxl` | 32 |

New code picks a step from this scale instead of writing a literal
`EdgeInsets`/`SizedBox` number. This is not retroactive: existing screens keep
their inline literals except where this slice already touched the file (the
three new shared widgets, and their call sites); the rest migrate as later
Phase 7 parts redesign those screens anyway. A `SizedBox(height: 8)` elsewhere
in the app today is not a bug — it just is not yet `AppSpacing.sm`.

---

## Components

A widget lives in `lib/core/widgets/` when it is **generic and
feature-agnostic** — `docs/ARCHITECTURE.md`'s own words for that folder. A
widget that knows what a recipe or a meal plan is does not go there.

Three widgets live there as of Phase 7 Part 1, each replacing a shape that had
already drifted into two or three disagreeing private copies:

- **`AppErrorView`** — a centered, already-localized error message. Takes a
  `String message`, never the raw error object: `core/widgets/` does not know
  about `FailureCode`, so the caller localizes first with
  `localizedErrorMessage(e, l10n)` (D92) and hands this widget the sentence.
- **`AppSectionHeading`** — a section heading within a screen. Takes a
  `String text`.
- **`AppEmptyState`** — icon, title, optional body, optional action, centered
  and scrollable so it still works as an `AsyncValue.when`'s `data` case
  inside a `RefreshIndicator`. Which icon and strings, and whether there is an
  action, are the caller's call — the widget itself does not know what a
  recipe or a shopping list is.

The middle ground already has a precedent: `core/recipes/widgets/`,
`core/meal_plan/widgets/` and `core/ingredients/widgets/` hold widgets that are
shared across features but still know their subject — each exists because two
features needed the same thing and a direct cross-feature import was not
allowed (D43, D53). Copy that shape rather than widening `core/widgets/` to
hold something feature-shaped.

Everything else stays in its own feature's `presentation/`. The bar for
promoting a widget out of a feature is that a *second* feature needs it — not
that it might one day.

CLAUDE.md's rule stands regardless: cross-feature imports go through `domain/`
only.

---

## Both languages, one layout

Serbian strings run longer than their English pairs, often noticeably. A
component that fits `en` and truncates, wraps badly, or overflows in `sr` is a
bug, not a rendering detail.

Nothing automated catches this. `test/core/l10n/arb_parity_test.dart` checks
that every key exists on both sides; it says nothing about width. So a layout
change is verified by looking at it in both languages, on a device — the app's
language toggle is on the settings screen.

Serbian displays in Latin script only. That is fixed in CLAUDE.md and is not a
design question.

---

## Light and dark

Both are real. `lib/main.dart` passes `AppTheme.light()` as `theme` and
`AppTheme.dark()` as `darkTheme`, and sets no `themeMode` — so `MaterialApp`'s
default applies and the app follows the system setting.

Any colour decision has to hold in both. A value tuned in one and eyeballed in
the other is how a redesign ends up with an unreadable dark mode.

Verify both, every time.
