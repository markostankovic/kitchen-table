## D1 — Canonical ingredient catalog, accreted not hand-curated

**Decided.** Ingredients are language-neutral concept rows. `ingredient_names`
holds aliases *and* translations. Matching happens in tiers: exact normalized →
trigram fuzzy → LLM → create new as unverified. Every resolution writes an alias
row back, so each unfamiliar string costs one model call ever, across all users.

**Why.** String matching cannot unify *brašno* and *flour*. Cross-language
shopping lists are the product's wedge, so the catalog is the feature, not
overhead. But hand-curating thousands of ingredients is not required: seed
~200 core items (heavily Serbian), let the long tail auto-create.

**Rejected.**
- Pure string matching — cannot bridge languages. Fails the core demo.
- Fully hand-curated catalog up front — weeks of work before anything ships.
- Third-party ingredient database — none cover Serbian items (kajmak, pavlaka,
  ajvar, suvo meso, vegeta, slatka/kisela pavlaka).
