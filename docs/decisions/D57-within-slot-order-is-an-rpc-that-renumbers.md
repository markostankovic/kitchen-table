## D57 — Within-slot order is an RPC that renumbers the whole group, not a two-row swap

**Decided.** `reorder_meal_plan_entry(entry uuid, new_position int)`
(migration 15), the RPC D49 named and left unbuilt. It looks up the entry's
`(meal_plan_id, entry_date, slot)`, clamps `new_position` into `[0, group_size
- 1]`, and renumbers every sibling in that group to `0..n-1` in one
statement — splicing the moving row in at the target index among the others,
ordered by their current `position` — rather than swapping the two rows at
the old and new positions.

**Why.** A two-row swap would preserve whatever gap or duplicate already
exists elsewhere in that group's `position` values. D49 rejected a unique
index on `position` specifically so two concurrent inserts into an empty slot
do not collide as a spurious "already exists" — which means gaps (and,
briefly, ties) are legal, and this RPC has to tolerate them on the way in
regardless of what produced them. Renumbering the whole group is also what
lets it leave the group gap-free on the way out, which a swap does not
guarantee. Clamping rather than raising on an out-of-range `new_position`: a
"move down" tapped on the last chip is a no-op, not a mistake worth
surfacing.

It does not fight `meal_plan_entries_before_write`: that trigger reassigns
`position` only on `INSERT`, or on `UPDATE` when `entry_date` or `slot`
actually changed (migration 14). A reorder changes neither, so its
tail-assignment branch never fires — the update this RPC issues is exactly
the "note text or servings changed" case that trigger was already written to
leave `position` alone for. This is the one fact that makes the RPC work at
all, and it is not obvious from reading either function in isolation, which
is why migration 15 writes it down explicitly rather than leaving it to be
rediscovered by whoever next touches either trigger.

**Rejected.** A two-row swap (preserves existing gaps/duplicates instead of
normalising them, and is not obviously simpler to reason about than a full
renumber). A unique index on `(meal_plan_id, entry_date, slot, position)` —
D49 already rejected this for a different reason (it would turn two
concurrent inserts into a spurious conflict), and it would make this RPC's
renumbering a multi-statement dance to avoid transiently violating it.
