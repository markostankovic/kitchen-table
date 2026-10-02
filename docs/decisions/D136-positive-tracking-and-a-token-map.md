# D136 — Positive tracking on the w700 roles, and § Token map as the bundle-to-Flutter name table
**Status:** active — amends D134's letter-spacing values only
**Touches:** lib/core/theme/app_theme.dart, lib/core/theme/kitchen_type.dart, test/core/theme/app_theme_test.dart, docs/DESIGN_SYSTEM.md

**Decided.**
1. **The bold roles track positive, at the design round's values.**
   `displaySmall` (the wordmark) is 0.5, `headlineSmall` (the household
   name) 0.3, `KitchenType.recipeTitle` 0.1 and `recipeTitleLarge` 0.3.
   `monogram` stays 0. Size, line height, weight, family and the w400 note
   exception are D134's, unchanged. The note picks up 0.1, because its
   call site `copyWith`s only the weight.
2. **Tracking is a type metric.** Each value stays a plain `double` on its
   role, not a constant and not an `AppSpacing` step.
3. **`DESIGN_SYSTEM.md` § Token map pairs each design-bundle CSS token with
   its Flutter symbol.** It holds names only, because the sections above
   own the values. `/design-handoff` diffs later rounds against it by
   name, and a bundle token missing from it is new and gets a row in that
   round's tokens slice.
4. **No `AppSizes.tag`.** The bundle's `--size-tag` (32) maps to nothing,
   because no code draws a tag chip. The number stays in `AppSizes.chip`'s
   doc comment. `--radius-full` maps to `StadiumBorder()` at the call
   site, not to an `AppRadii` member (§ Shape).

**Why.** Round `sync-design-initial`'s token delta
(`docs/design/handoffs/2026-10-02-sync-design-initial/ROUND.md`) found
these three tracking values as its only change, each differing only in
sign. Tight tracking on bold display type is the usual choice, so the
round flagged a likely dropped minus. The user confirmed on 2026-10-02
that the positive values are intended. Before this round there was no
name table, so every token delta was matched by hand.

**Rejected.**
- Keeping D134's negative values as an export error. The user ruled it
  out.
- Adding `AppSizes.tag` now. A token with no consumer is dead weight. The
  slice that first draws a tag adds it.
- Repeating values in § Token map. Two places holding one number is how
  docs drift.

**Consequences.** A title can ellipsize one word earlier than before. The
emulator walk (sr/en × light/dark, 2026-10-02) found no title that wraps
differently or overflows.
