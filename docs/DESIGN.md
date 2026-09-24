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

Nothing here has been designed yet. As of Phase 6 the whole of the app's
visual language is:

```dart
// lib/core/theme/app_theme.dart
ColorScheme.fromSeed(seedColor: const Color(0xFF7A5C3E))
```

— one seed colour, a warm mid brown, fed to Material 3's tonal palette
generator for `light()` and again with `Brightness.dark` for `dark()`. Nothing
else is set. Every type size, every elevation, every shape and every spacing
value in the app is a Material 3 default that no one chose.

`lib/core/widgets/` — the folder `docs/ARCHITECTURE.md` describes as "generic,
feature-agnostic" — holds exactly one file, `placeholder_screen.dart`. There is
no shared card, no shared empty state, no shared section header. Screens that
look alike look alike by coincidence.

This section is replaced by real content when Phase 7 Part 1 ships.

---

## Colour

**Not yet decided.** Today: derived entirely from the `0xFF7A5C3E` seed above,
through `ColorScheme.fromSeed`.

Phase 7 Part 1 fills this in: which roles are used, what each one means in this
app, and where a raw `Color` is allowed instead of a role (ideally nowhere).

---

## Type

**Not yet decided.** Today: Material 3's default `TextTheme`, on the default
platform font. No `google_fonts` — adding one is a rule 8 conversation.

Phase 7 Part 1 fills this in: the steps, and what each step is *for*, so a
screen picks a role rather than a size.

---

## Spacing and layout

**Not yet decided.** Today: every padding and gap is written inline at the call
site, chosen per screen.

Phase 7 Part 1 fills this in: the scale, and the rule that gaps come from it.

---

## Components

A widget lives in `lib/core/widgets/` when it is **generic and
feature-agnostic** — `docs/ARCHITECTURE.md`'s own words for that folder. A
widget that knows what a recipe or a meal plan is does not go there.

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
