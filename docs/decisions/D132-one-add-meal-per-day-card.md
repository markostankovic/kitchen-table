# D132 — One `+ Dodaj obrok` per day card, no per-slot add buttons, and a note wears a recipe title's face
**Status:** active
**Touches:** lib/features/meal_plan/presentation/meal_plan_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.**
1. **An expanded day card ends in a single `+ Dodaj obrok`/`+ Add meal`
   text button, aligned bottom-end**, styled like the collapsed day's
   button. It opens the slot chooser, which lists all four slots, filled ones
   included. The per-empty-slot `+ <Slot>` buttons and the trailing icon-only
   `+` are gone, and so is `_SlotAddButton`.
2. **Dragging into an empty slot is gone with them.** Two drop targets
   remain: a filled slot's group and a collapsed day. An empty slot is
   reached through the entry's `Move to` action.
3. **A note entry's text uses `KitchenType.recipeTitle`**, like a recipe or
   a leftover, instead of sans `bodyLarge`. The meta row's `Napomena`/`Note`
   item is what marks it as a note.

**Why.**
- The user's call from device use: four quiet buttons under every day read
  as clutter, and the chooser already asks which meal.
- The user chose to drop the drag targets rather than show them only during
  a drag. Tapping stays the primary path (D53), and `Move to` covers the
  case.
- The user chose recipe-title styling for notes: a note is a meal like any
  other.

**Rejected.**
- Empty-slot drop zones that appear only during a drag. They would add
  layout shift mid-gesture for a shortcut that `Move to` already covers.
- Capping long notes at 2–3 lines. Wrapping stays the rule.
