# D156 — Ingredient sections are runs of equal `section`, under the step heading's row
**Status:** active
**Touches:** lib/features/recipes/presentation/recipe_detail_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`, canvas § A4·3, 2026-10-07:
1. **A section is a run of consecutive lines with the same `section`.**
   The values are compared after `trim()`, and the heading shows the
   string as typed. A line opens a group when its section is non-empty and
   differs from the line before's.
2. **A null `section` after a named one gets no heading.** The line just
   continues the list, and no "Other" heading is invented for it. Lines
   before the first section sit headingless at the top. Two groups with the
   same name that are not adjacent each get a heading.
3. **A group's last line drops its divider**, as the list's last line
   already did.
4. **Step headings (D154) and ingredient sections share one private
   `_GroupHeading(text, top, bottom)`**: `titleSmall` in `primary`, with the
   gaps passed in by the caller. Ingredients use `xl` above (`xs` when the
   heading opens the list) and `xs` below. Steps keep `0`/`sm` above and
   `md` below.
5. **Section headings are not translated for now.** They are the cook's
   text, like an ingredient note, and `translate-recipe` sends no
   ingredient lines.

**Why.**
- Import's Zod schema repeats the heading on every line under it, so a run
  of equal values is the group. A flat list then builds exactly the tree it
  built before, the same promise D154 made for a step-only method.
- An invented "Other" would put a string the cook never wrote on the
  screen.
- The canvas says the heading looks the same as A1's step heading. One row
  means the two can't drift apart.
- Translating sections needs a schema and function change, which is out of
  scope for a client-only slice.

**Rejected.**
- A heading per line, or grouping non-adjacent lines that share a name.
- Reusing `AppSectionHeading`: it is `titleMedium` on-surface, the level
  above.
- Promoting the heading to `lib/core/ingredients/widgets/` now. That waits
  for a second user (import review, `phase8-ingredient-editor`; D43/D53).
- Keeping two near-copies of the heading row.

**Consequences.** Under an English reading, a Serbian recipe's sections stay
Serbian (an open item in `docs/STATE.md`). A heading that wraps has not been
seen on a device.
