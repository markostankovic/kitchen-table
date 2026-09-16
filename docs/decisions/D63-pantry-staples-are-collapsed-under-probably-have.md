## D63 — Pantry staples are collapsed under "Probably have", never hidden, and the override works both ways

**Decided.** A flagged item renders inside a collapsed *Probably have*
`ExpansionTile` with its quantity intact, never omitted from the snapshot.
`household_pantry_prefs.always_have` overrides `ingredients.is_pantry_staple`
in **both** directions. Long-pressing an item records the override and
deliberately does **not** rewrite the list on screen; it says the change takes
effect next time.

**Why.** The first half was pre-decided in Phase 2 part 3's closing note and
is written down here properly. Five ingredients are flagged globally by the
seed (*so, ulje, šećer, voda, biber*) and every household disagrees with that
list somewhere — a one-way override would make "we never actually have sugar
in this house" unsayable. Hiding rather than collapsing would mean a cook who
is out of salt has no way to see that this week needed any, and D13's snapshot
is supposed to be a complete record of what the plan requires.

Not rearranging the visible list is the same instinct: the list is a snapshot
(D13), and a document that reorders itself while somebody is reading it in a
shop is worse than one that is slightly out of date and says so.

**Rejected.** Suppressing staples entirely — loses information the cook
sometimes needs. Rewriting the on-screen list when an override is recorded —
turns a snapshot into a live document, which is the thing D13 ruled out.
