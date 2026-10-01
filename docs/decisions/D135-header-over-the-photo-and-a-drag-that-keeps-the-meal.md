# D135 — The recipe detail's app bar sits over the photo and collapses; a meal-plan drag moves an entry but never changes its meal
**Status:** active — amends D119 (the opaque bar above the photo) and D121 / D134 (a drop onto a filled slot's group changed the entry's slot)
**Touches:** lib/features/recipes/presentation/recipe_detail_screen.dart, lib/features/meal_plan/presentation/meal_plan_screen.dart, test/features/meal_plan/meal_plan_screen_test.dart, docs/DESIGN_SYSTEM.md

**Decided.**
1. **Recipe detail: a pinned, collapsing `SliverAppBar` over the 16:9
   photo.** The body is a `CustomScrollView`. `expandedHeight` is the
   screen width × 9/16, and `_PhotoWell` (now sized by the sliver, not an
   `AspectRatio`) is the `FlexibleSpaceBar` background. It still renders
   empty before the recipe loads and when there is no photo. Collapsed,
   the bar is the solid `surface` bar it was before, still with no title.
2. **Every app-bar icon button sits on a `surface` disc at 0.7 alpha.** A
   local `Theme` sets `iconButtonTheme` around the `SliverAppBar`, so the
   automatic back button, the heart, edit and the `PopupMenuButton` all
   get it without restyling each one. On the collapsed bar the disc blends
   into the bar.
3. **Light status-bar icons while a photo is under the status bar.** A
   `NotificationListener` flips `_photoUnderStatusBar` at
   `pixels < photoHeight - kToolbarHeight`. Only when the recipe has an
   `imageUrl` does the bar get `SystemUiOverlayStyle.light`. The empty
   well is `surfaceContainerHighest`, so it keeps the theme's own icons.
4. **A drag only changes where an entry sits, never its slot.** The drop
   targets are:
   - **each entry card**: accepts an entry from the same day and slot (not
     itself) and calls `reorderEntry` with that card's index;
   - **another day's card, expanded or collapsed**: accepts any entry from
     a different day and calls `moveEntry` with the entry's **own** slot.
     That includes an expanded day that has none of that slot yet.

   `_SlotGroup` is no longer a drop target. A different slot on the same
   day accepts nothing. Changing the meal is *Move to…*'s job.

**Why.** It was the user's device feedback. A header above the photo
spent a 64dp strip on three icons. Dropping breakfast near dinner
silently made it dinner, which is the same failure D121 already rejected
for collapsed days ("it silently changes a meal"), just reached by another
route. D119 rejected floating buttons for two reasons. Both are kept: the
discs guarantee contrast over any photo, and the pinned bar keeps the
heart reachable. The walk then found that Light's dark status-bar icons
disappear into a dark photo, which is point 3.

**Rejected.**
- A transparent overlay that scrolls away with the photo. Once scrolled,
  there is no favourite toggle on screen.
- A top gradient scrim with always-light status icons. It darkens the top
  of every photo to fix one row of icons.
- Keeping `_SlotGroup` as a cross-day target. The expanded day card's
  target covers it, and also covers a day without that slot.

**Consequences.** Light status-bar icons over a photo that failed to load
sit on the light empty well. That only happens when a signed URL expires,
so it was accepted. A cross-day drop appends: the entry lands last in its
slot on the new day.
