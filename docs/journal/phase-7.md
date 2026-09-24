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
