# D139 — Recipe detail per the design round: opaque photo-bar discs, a one-line source, a tonal badge
**Status:** active — amends D135 point 2 (the translucent `surface` disc)
**Touches:** lib/features/recipes/presentation/recipe_detail_screen.dart, lib/core/widgets/app_badge.dart, lib/core/widgets/app_section_heading.dart, lib/core/widgets/app_stat_strip.dart, lib/core/l10n/arb/, test/features/recipes/recipe_screens_test.dart, docs/DESIGN_SYSTEM.md

**Decided.** The user settled three calls for frame 07 of round
`sync-design-initial` (2026-10-02).
1. **The photo-bar discs are opaque `surface`, icons `onSurface`**, not
   `surface` at 0.7 alpha. No `minimumSize`, so each is M3's 40dp disc in a
   48dp target. A favourite heart keeps `KitchenColors.favorite`.
2. **The source footer is one line**: a lead-in by `source_type`
   (`urlImport` → `Uvezeno sa linka`, `ocr` → `Uvezeno sa fotografije`,
   otherwise `Izvor`), ` · `, then the attribution, or the URL's host
   without `www.`. All of it muted `bodySmall`. It is never styled as a
   link while nothing opens it.
3. **The Ingredients heading carries `za N porcija` / `for N servings`** at
   its right, through `AppSectionHeading(trailing:)`.
4. **`AppBadge` has a tonal look** (`tonal: true`: a
   `surfaceContainerHighest` fill, no border, an optional `leading` icon).
   Machine translation and the translation in flight use it. Draft keeps
   the outlined look.
5. The stat strip follows the frame's type: `bodyMedium` labels,
   `titleMedium` values, `lg` inside the hairlines.

**Why.**
- An opaque disc reads the same over any photo, and it is identical to the
  collapsed `surface` bar, so nothing changes tint as the header collapses.
- The full URL in the footer was long and unreadable. The host says where
  the recipe came from, and the lead-in says how.
- A chip in this app is a control (`AppBadge`'s own rule), and nothing taps
  the machine-translation caveat.

**Rejected.**
- Styling the host in `primary`: it would promise a tap. There is no
  `url_launcher`, and adding a package needs asking (rule 8).
- The frame's 12dp gap between stat columns: at 360dp it shrinks the five
  stars.
- The frame's 184dp header, 32dp placeholder, `favorite`-tinted outline
  heart, and its heading and row spacings. D135's 16:9, § Spacing and
  § Ingredient lines stand (journal, part 17).
- Separate badge widgets per caveat: `AppBadge` stays subject-free with two
  opt-in parameters.

**Consequences.** `AppSectionHeading` and `AppBadge` each gained an optional
parameter, and their other callers render as before. The OCR lead-in and
`Mašinski prevod` in the badge were not seen on a device: no hosted data
reaches them yet.
