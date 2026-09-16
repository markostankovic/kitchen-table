## D24 — "Household-scoped" means "has a `household_id` column"

**Decided.** CLAUDE.md rule 4 (`deleted_at` + `updated_at` + trigger on every
household-scoped table) applies to tables carrying a `household_id` column.
Child rows — `recipe_ingredients`, `recipe_steps`, `shopping_list_items`,
`household_members` — cascade with their parent and carry neither column.

**Why.** The reference schema in `docs/DATA_MODEL.md` already works this way,
and putting `deleted_at` on every child means every child query needs a filter
that adds no safety: a soft-deleted recipe's ingredient rows are already
unreachable.

**Consequence.** Removing someone from a household is a **hard delete** of the
`household_members` row. Revisit if membership revocation ever needs to be
auditable — that is a real argument for making this one join table the
exception.
