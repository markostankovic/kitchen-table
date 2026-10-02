# D141 — Import capture: Read inline on the entry screens, a square photo well with a tonal pair, and Discard while reading with no confirm
**Status:** active — amends D124 #2 (the import entry screens no longer use `AppActionBar`); D140's rejected ✕ stands here too
**Touches:** lib/features/import/presentation/import_url_screen.dart, lib/features/import/presentation/import_paste_screen.dart, lib/features/import/presentation/import_photo_screen.dart, lib/features/import/presentation/import_review_screen.dart, docs/DESIGN_SYSTEM.md

**Decided.** For frames 10–13 of round `sync-design-initial` (2026-10-02):
1. **Read is inline.** On link, paste and photo, the filled `Pročitaj ovaj
   recept` follows the last field (or the photo's buttons), full width,
   `xl` under it, with the error line `sm` above it in `bodySmall` `error`.
   The intro paragraph is `bodyLarge` `onSurfaceVariant`, then `xl`.
2. **The photo well is square.** 1:1, `surfaceContainerHighest`, radius
   `md`. Empty, a 48dp `menu_book_outlined` in `outline` (private
   `_wellIcon`). Filled, the page with `BoxFit.contain` in the same box, so
   a portrait page letterboxes on the well colour and nothing below moves.
   Tonal Camera / Gallery in a centred `Wrap` (`sm`) sit *below* the well in
   both states. Read stays the screen's only filled button.
3. **The waiting state** follows `AppEmptyState`'s rhythm: a spinner on a
   `surfaceContainerHighest` track, `lg`, `titleMedium`, `sm`, a
   `bodyMedium` `onSurfaceVariant` hint, padded `xxl`. A full-width outlined
   `Odbaci ovaj uvoz` is pinned on `AppActionBar`, with **no confirm**. It
   is the same soft delete as Failed (`dismiss_import_job`), so no
   migration was needed.

**Why.**
- Scaffold's `bottomNavigationBar` does not rise with the keyboard, so on
  link and paste the pinned Read sat under it. D137's onboarding already
  puts a full-width filled button inline.
- A 3:4 well came to about 805dp of content in about 693dp at 360×760, which
  put Read below the fold. A square is about 696dp. This was the planner's
  call after the user chose a well.
- One filled button per screen, so the pickers are tonal (D140's pair).
- Nothing has been parsed while a job waits, so there is nothing for a
  confirm to protect, as in Failed. The model call already under way still
  runs and still counts against quota. The user accepted that.

**Rejected.**
- The frame's filled Camera / outlined Gallery: two filled buttons.
- The frame's 3:4-ish flex well: see above.
- The frame's app-bar ✕ leading (D140): no unsaved-changes guard exists
  for it to promise.
- The frame's 4dp top padding, 20px gaps, 240px paste box and 44px spinner:
  `lg` all round, `xl`, `minLines` 8 / `maxLines` 14 and the default spinner
  stand. There is no 20 step and no new token.
- A shared `core/widgets/` well with the editor's `_PhotoField`: the
  aspects differ, and each has one user (D140).
- D123's `lg` horizontal padding on the pickers: tonal buttons in a `Wrap`
  size to their labels.

**Consequences.** A docked keyboard, the photo screen at 360dp and the
waiting state's pixels in sr and light were not seen on a device (part 19's
walk loop). Link imports never show the waiting state, because the fetch
finishes inside the request.
