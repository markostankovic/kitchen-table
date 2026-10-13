# D174 — Leaving the current household switches to the most recently used other one, from a device-local recent list
**Status:** active
**Touches:** lib/core/db/device_preferences.dart, lib/features/households/data/household_repository.dart, lib/features/households/domain/next_household.dart, lib/features/households/application/household_providers.dart, lib/features/households/presentation/household_screen.dart

**Decided.** `phase9-household-leave-switch`, 2026-10-13. Builds on D169, D170, D173.
1. **Recent list.** `HouseholdRepository.select` also writes
   `recent_households.<userId>` in `DevicePreferences` (D128): ids, most
   recent first, joined by `,`, deduped, capped at 10. It writes the
   selection first, so the list can never cost the switch.
   `recentHouseholdIds(userId)` reads it back (`[]` when nothing is
   stored). Stale ids are filtered on read and never pruned (D169).
2. **Pick.** The pure `nextHouseholdAfter(leavingId, mine, recentIds)`
   returns the first recent id that is still in `mine` and isn't the one
   being left. If there is none, it returns the first other membership in
   join order, else null. `nextHouseholdAfterLeavingProvider(id)` wraps it.
3. **Leaving the current household with others** resolves the pick
   *before* the dialog, so the dialog names it ("You'll switch to Y." in
   `onSurface`). Confirming runs the RPC, then `switchTo(next)`, then `go`
   to the Settings root, then "You left X. Now in Y." with **no Undo**.
   `switchTo` replaces the `invalidate` + `fetchCurrent` fallback on this
   path.
4. **Non-current with others:** the named dialog, no switch sentence,
   today's `invalidate` and back to the list. **One household, or
   `myHouseholds` unknown (D115):** today's dialog and path, unchanged.
5. **Button verbs** stay `Napusti` / `Obriši`, and sr titles use the
   infinitive (`Napustiti „X“?`), matching the one-household dialog and
   Remove / Revoke. The canvas's imperative `Napustite` / `Obrišite` was
   not adopted.

**Why.** D5 asks for the household used most recently among the others.
Until now the device stored only the current selection, so recency needed
its own record, and `select` is the one place every switch already passes
through. `fetchCurrent`'s fallback picks the *oldest*, which may not be
the household the dialog named. Ending with `switchTo` lands exactly there,
and shows D172's switch-loading state on the way.

**Rejected.**
- Join order as the pick: it ignores recency, which D5 asks for.
- D169's oldest-first fallback after `invalidate`: it can disagree with the
  dialog.
- A per-household `last_used` timestamp key: more keys, same answer.
- Pruning stale ids on leave: D169 already settled that stale selections
  need no cleanup.
- An Undo on the snackbar: a leave or delete can't be undone from the app.

**Consequences.**
- The recent list only knows switches made since this build. Before any,
  the pick falls back to join order.
- The screen holds a `listenManual` subscription while it awaits the
  autoDispose pick provider, so the provider isn't disposed mid-read.
- If the walk shows a flash of the left household's screen during the
  switch, move the `go` before `switchTo` (not yet observed; the confirming
  taps weren't walked).
