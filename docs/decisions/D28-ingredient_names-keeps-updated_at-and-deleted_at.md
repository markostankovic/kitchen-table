## D28 — `ingredient_names` keeps `updated_at` and `deleted_at`

**Decided.** Unlike `household_invites` in D25, this table takes no exception
to CLAUDE.md rule 4. It gets both lifecycle columns, and its unique index
`(normalized_name, locale, coalesce(household_id, zero-uuid))` stays **total**
rather than partial on `deleted_at is null`.

**Why.** The append-only argument that carried D25 does not survive contact
with this table: `is_display_name` is mutable — a merge demotes it — so rows
here are written more than once. It has a `household_id`, so D24 catches it
literally. Phase 2 caches the catalog for offline autocomplete and a cache
needs tombstones to evict. And `docs/DATA_MODEL.md` words the merge's second
step as "drop the duplicate name row", which is a hard delete and a straight
violation of rule 4; `deleted_at` makes it soft and keeps the rule intact.

The total index is the interesting half. It means a given
`(normalized_name, locale, scope)` resolves to exactly **one** ingredient
globally, forever — so one string can never come to mean two things, and
re-seeding a retired alias resurrects and repoints the existing row rather
than adding a second one for the same string.

**Consequence worth knowing.** Because two ingredients cannot share an alias,
a merge can never produce a duplicate name row, so the "drop the duplicate"
step is unreachable and nothing is ever deleted. See D30.

**Rejected.**
- Append-only with no lifecycle columns, the D25 shape — see above.
- A partial unique index — would allow two live rows for one string as soon as
  one of them was soft-deleted and re-created, which is the failure this index
  exists to prevent.
