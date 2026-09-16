## D51 — `leftover_of_entry_id` and the `leftover` vocabulary ship now, unreachable

**Decided.** The column, its self-FK (`on delete cascade`), its index, and
`'leftover'` in the `entry_kind` check all ship in migration 14. No client
writes them until a later part builds the leftover feature. The `recipe` and
`note` branches of the check constraint are made mutually exclusive; the
`leftover` branch requires only its own pointer, deliberately looser.

**Why.** The same argument D35 made for `recipes.image_path`: shipping the
column now means the leftover feature is a feature, not a migration against
existing rows, when it arrives. The `leftover` branch stays permissive
because a later part may want `recipe_id` denormalised onto a leftover row so
the snack variety check can count it without a join, and this migration will
be unwritable by then (CLAUDE.md: never edit an applied migration). Being
loose on the one branch with no client yet is honest; being loose on the two
branches that already have one would just be sloppy.

**Rejected.** Deferring the column entirely to the part that needs it — the
migration-against-existing-rows problem D35 already named. Deciding the
leftover-to-source relationship rule now, with no client yet to check it
against.
