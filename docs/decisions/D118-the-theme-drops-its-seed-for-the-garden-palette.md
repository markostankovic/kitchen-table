# D118 — The theme drops its seed for two explicit `ColorScheme`s, bundles Literata, and gains a semantic layer
**Status:** active
**Touches:** lib/core/theme/app_theme.dart, lib/core/theme/kitchen_colors.dart, lib/core/theme/app_radii.dart, lib/core/theme/app_sizes.dart, lib/core/theme/app_durations.dart, assets/fonts/, pubspec.yaml, docs/DESIGN_SYSTEM.md

**Decided.** Phase 7 Part 2 deletes `_seed` and both `ColorScheme.fromSeed`
calls. `AppTheme._colorScheme(Brightness)` returns one of two
`const ColorScheme` values, every role an explicit value from the Claude
Design export in `docs/design/`; light and dark were designed as a pair and
neither is derived from the other. `surfaceTint` is `Colors.transparent` in
both, which disables Material's elevation tint app-wide in one place. Literata
(static instances, weights 400 and 600) is **bundled** under `assets/fonts/`
and set on the roles a person reads — the wordmark, titles, recipe steps,
ingredient lines — while UI furniture (buttons, chips, field labels, nav
labels, meta lines) keeps the platform sans as `fontFamily: null`. Three token
classes join `AppSpacing`: `AppRadii`, `AppSizes`, `AppDurations`. `"Full"` is
deliberately not a member of `AppRadii` — a stadium is a shape, so it is
`const StadiumBorder()` at the call site. `KitchenColors`, the app's first
`ThemeExtension`, adds twelve names for what a colour *means* here; every
member is an alias of a `ColorScheme` role, built in one factory,
`KitchenColors.of(ColorScheme)`. **This supersedes D117 on both counts**: the
seed is gone, and D117's pinned dark `tertiary`/`onTertiary`
(`0xFFE7C17E`/`0xFF422C00`) is replaced by the palette's own paprika,
`0xFFFF9569`.

**Why.** D117 kept the seed because a from-scratch palette was out of scope
then; the Garden export closed that question, and once every role is a
decision a generator has nothing left to contribute. Writing both schemes out
is also what makes them reviewable — a hex in a table can be checked against
the export, a tonal palette derived from a seed cannot. Literata is bundled
rather than fetched because CLAUDE.md rule 8 holds (`google_fonts` was asked
about and declined, twice) and because a font the app always has beats one it
downloads. `KitchenColors` exists so that a screen drawing "the thing that
means today" names `today` rather than `primary`: the day those two stop being
the same colour, one line changes instead of eleven call sites.

**Rejected.** Keeping `fromSeed` and overriding more roles — rejected once the
override list grew past a handful; at that point the generator is noise.
Deriving dark from light programmatically — rejected, the export's two schemes
are not a transform of each other. `google_fonts` — rejected, rule 8. The
variable Literata build (the `google/fonts` mirror carries only that) —
rejected because a variable TTF needs `FontVariation` rather than `fontWeight`
in Flutter, which buys nothing for two static weights. Codegen or a package
for the `ThemeExtension` — rejected; `copyWith`/`lerp` are mechanical and the
value of the file is its doc comment. Trimming `KitchenColors` to the one
member this slice consumes — rejected; the other eleven are the vocabulary
slices 3–7 read, and adding them one at a time would invite each slice to
reach for a role directly instead.

**Consequences.** A palette change is now an edit to two `const ColorScheme`s
in `app_theme.dart` — not a new seed and a guess at what the generator does
with it. A screen that wants "the colour that means today" reads
`KitchenColors.today`, not `primary`, and a screen that reaches for a role
where a semantic name exists is now a review comment. The `tertiary` role
stays **signal-only** — the 3px review marker, a filled heart, a star, a stat
value — and never a surface something sits on: that is D117's legibility
constraint surviving its own value, and it is why the new paprika still has to
read at 3px. Two roles remain deliberately *not* errors and both are asserted
in `app_theme_test.dart`: `offline` (frequent, not a fault) and `unmatched`
(CLAUDE.md rule 3 — a line the catalog missed still renders what was typed).
`docs/DESIGN_SYSTEM.md` now describes the code and `docs/DESIGN.md` is a
pointer; D117's own file stays as written, since this decision is the record
that it was superseded.
