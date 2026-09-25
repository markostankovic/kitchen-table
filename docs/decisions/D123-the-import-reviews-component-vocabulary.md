# D123 — The import review's component vocabulary: read-only rows that open one at a time, a foreground review marker, a confirmed Discard, Method in place, and an action bar on `surface`
**Status:** active
**Touches:** lib/features/import/presentation/import_review_screen.dart, lib/core/ingredients/widgets/ingredient_line_row.dart, docs/DESIGN_SYSTEM.md

**Decided.** Phase 7 Part 6 builds the import review from a summary card,
`IngredientLineRow`s, a Method card and a bottom action bar. All of them are
private to `import_review_screen.dart`. Six calls:

1. **Lines are read-only rows, and tapping one opens it in place** into the
   unchanged `IngredientLineField` (D8, D43), with `Done` to close it. A
   single `_openLineId` keeps one line open at a time. A blank line always
   renders open, and **Add ingredient opens its line by id**.
2. **The 3px `reviewMarker` is a foreground decoration** on
   `IngredientLineRow`, over a `surfaceContainerLow` tint. It takes no
   layout, so the quantity column stays aligned.
3. **Flagged still means "matched without `autoAccept`"**, as
   `draftFromParsed` has always defined it. An unmatched line is not flagged.
   It gets the dashed ring, and nothing red (rule 3). The Garden mock flags
   an unmatched `Vegeta` line, and the app's semantics win over the mock.
4. **Discard on a successful review sits behind a confirm dialog.** The
   dialog's destructive action is a `TextButton` in `destructive`. The Failed
   state's discard has no confirm.
5. **Method is a collapsed `ExpansionTile` card that expands in place.** It
   has no route, so it uses `expand_more` and no `›` chevron.
6. **The action bar sits on `surface` with a top hairline**, with outlined
   Discard and filled Save as equal halves, each padded `lg`.

**Why.** D8 says editing the odd line out is the exception, so the screen
should read like the recipe it will become. It uses the same row as the
detail screen, and the editor appears only where asked for. As a decoration
border, the marker added 3px of padding and pushed a flagged row's quantity
3px right of its neighbours. Holding a new line open only because it was
blank looked like no bookkeeping, but the first keystroke made it non-blank
and closed it mid-typing. The device walk caught that, and the plan had
approved the approach. A successful review holds a whole recipe, and a
failed one holds nothing. The bar's background is `surface` because the nav
bar is `surfaceContainer`, and on the same fill the two bars merge into one
block. With the theme's default 24dp button padding, `Odbaci ovaj uvoz` wraps
at a 158dp half.

**Rejected.**
- Rows that are always editable fields (the old screen).
- Several lines open at once.
- Clearing a flag once the cook edits the line. The attention set stays as
  the server produced it.
- The mock's `×` app-bar close. The route is nested under the recipes tab,
  and Back is correct there.
- A `FilledButton` destructive action (household_screen's delete dialog is
  not the pattern).
- A route for Method.
- Promoting the summary card, the action bar or the Method card to
  `core/widgets/`.

**Consequences.** `isFlagged` changes only import review: no other consumer
sets it, and a test pins "no tint, no foreground" for the default. Save
navigates with `go`, so Back from the saved recipe lands on the recipe list.
The `AlreadySaved` state is therefore reached only by a stale deep link, and
widget tests are what cover it.
