# D163 — A dropped line takes the heading above; a heading carries its run to a group boundary
**Status:** active
**Touches:** lib/core/ingredients/widgets/ingredient_list_layout.dart, lib/core/ingredients/widgets/ingredient_lines_editor.dart, lib/features/recipes/domain/recipe_draft.dart, docs/DESIGN_SYSTEM.md

**Decided.** Round `2026-10-06-round-2-recipe-structure`,
`phase8-ingredient-sections-edit`, 2026-10-08:
1. **A dropped line** lands at the matching line index and takes the
   section of **the nearest heading item above it**, or null above the
   first. Only the moved line's section changes (`RecipeDraft.moveLine`).
2. **A heading drags with a grip** in the editor (`ingredientSectionGrip`)
   and **long-press** in review, as its lines do.
3. **While it is in the air its run collapses**: the run's line children
   stay (same keys and count, so indices stay valid) under `Offstage`. The
   proxy is the heading plus its run's closed rows under `IgnorePointer`,
   lifted like a step row: `Material` elevation 3 on
   `surfaceContainerHigh`. A line's proxy keeps Flutter's default lift.
4. **On drop the whole run moves** (`RecipeDraft.moveLines`), and only to a
   **group boundary**: the end of any group (the headingless top block
   counts), or the top of the list. A drop inside another group snaps to
   the nearest boundary, **ties going down**. A drop in its own run is no
   move.
5. **The top of the list is a boundary only when no headingless block is
   there** (found on the device walk). Lines with no section read as the
   group above them (D156), so a run dropped above that block took it in.
6. The planned fallback (keep the run visible while dragging) was **not
   needed**: the zero-height run behaved on the device.

**Why.**
- Snapping to boundaries means a section can never split a group and
  leave a duplicate heading behind by accident.
- A headingless block can exist only first; the rules must not create a
  state D156 cannot draw.

**Rejected.**
- Letting a run land anywhere, splitting the group it lands in.
- A drawn drop line (D154 #2 already rejects it).
- An `OverflowBox` of our own round the run proxy: Flutter's proxy already
  sits in an unbounded, top-aligned one, and a second sized itself to that
  height and threw the proxy off the finger (found on the walk; a widget
  test holds a drag and checks the proxy stays by the finger).
