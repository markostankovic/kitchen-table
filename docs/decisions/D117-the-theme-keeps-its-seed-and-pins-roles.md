# D117 — The theme keeps its seed and pins roles explicitly; a dark-mode tertiary override is the one deliberate departure from `fromSeed`
**Status:** active
**Touches:** lib/core/theme/app_theme.dart, lib/core/theme/app_spacing.dart, docs/DESIGN.md

**Decided.** Phase 7 Part 1 keeps `ColorScheme.fromSeed(seedColor: 0xFF7A5C3E)`
as the generator for both brightnesses — no new palette, no `google_fonts`
(CLAUDE.md rule 8, asked and declined in planning), same platform font. What
changed is that the roles the app actually reads (`primary`, `error`/
`errorContainer`/`onErrorContainer`, `tertiary`, `outline`,
`onSurfaceVariant`, `surfaceContainerHighest`, `secondaryContainer`) are now
named and documented in `docs/DESIGN.md` § Colour instead of being whatever
`fromSeed` happened to produce, and five component themes
(`AppBarTheme`, `ChipThemeData`, `FilledButtonThemeData`,
`ListTileThemeData`, `InputDecorationTheme`) are set once in `AppTheme`
rather than per screen — picked because each backs a widget used across
enough of the app to earn it (`CardTheme` was considered and dropped: one
`Card` exists today). The one place the generator's own output was
overridden is dark-mode `tertiary`/`onTertiary`, pinned to `0xFFE7C17E` /
`0xFF422C00` because the generated value sat too close in tone to the
generated dark `secondary` to read at the 3px border width
`import_review_screen.dart` draws its "needs attention" marker at. `light()`
keeps the generated `tertiary` untouched. The spacing scale
(`AppSpacing.xs`–`xxl`, 4/8/12/16/24/32) names the de-facto steps already in
the codebase rather than inventing new ones, and is applied only to the
three new shared widgets and the files this slice already opened — not
swept across `lib/`.

**Why.** A from-scratch palette was out of scope (visual identity holds);
theming per-screen call sites would have re-created the inconsistency this
slice exists to remove (eight different error-message paddings, three
different section-heading styles were already evidence of that). Pinning
only the one role that actually failed a legibility check, rather than
hand-tuning every generated value, keeps the theme legible without turning
"deliberate" into "arbitrary" — `fromSeed`'s output is trusted everywhere
it wasn't shown to be wrong.

**Rejected.** A full manual `ColorScheme` (no `fromSeed` at all) — rejected
as unnecessary weight; the generator's tonal palette is doing real work and
only one role needed correcting. Theming every Material component
reflexively (`CardTheme`, `DialogTheme`, ...) — rejected per the slice's own
instruction to theme what "earns it": a `CardTheme` for the app's one `Card`
would be speculative. Sweeping `AppSpacing` across every existing
`EdgeInsets`/`SizedBox` literal — rejected as scope creep that would turn a
reviewable slice into a diff touching every screen; migration rides along
with each later per-surface Phase 7 part instead.

**Consequences.** A future palette change is now a handful of role
overrides in `AppTheme._colorScheme`, not a search for every raw `Color` in
`lib/` — because none exist outside `AppTheme` itself (verified: no
`Color(0x...)` or named `Colors.*` literal exists in `lib/` outside
`app_theme.dart`). A font swap is a one-line change to
`AppTheme._textTheme`'s base `TextTheme`. The spacing scale not being
swept means `lib/` still has two conventions in flight (named `AppSpacing`
steps in new code, inline literals everywhere else) until later parts
migrate their own screens — expected, not a bug, per `docs/DESIGN.md` § Spacing.
