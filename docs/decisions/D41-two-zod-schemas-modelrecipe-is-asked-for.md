## D41 — Two Zod schemas: `ModelRecipe` is asked for, `ParsedRecipe` is stored

**Decided.** `_shared/schema.ts` defines both. `ModelRecipe` is what a model is
asked to return — prose and raw ingredient lines. `ParsedRecipe` is
`ModelRecipe` enriched by `parse_line.ts` and `match-ingredients`, and is what
`import_jobs.result` holds and what `make types` generates Dart from.

**Why.** A model asked for quantities and `units.code` values will happily
invent both. It does not need to: `parse_line.ts` produces integer fractions
deterministically and is held to `test/fixtures/ingredient_lines.json`, and
`search_ingredients` produces matches and is held to the SQL tests. Asking a
model to redo exact work is how the exact work gets quietly replaced by a guess.

**Consequence.** `ParsedIngredientLine.matchMethod` has no `manual` value and
must not gain one — a machine pass cannot produce a human decision (D7), and
only the confirm screen promotes a line to `manual`.

Also recorded here because it has no better home: `import_jobs.kind` has three
values and `recipes.source_type` has four. `url` maps to `url_import`, `photo`
to `ocr`, and `text` to `url_import` when the paste carried a URL and `manual`
when it did not. That mapping lives in `ImportKind.sourceTypeFor`. It was wrong
for photos until Phase 1d part 5 — derived from whether a source URL was
present, which a photograph never has — and a photographed cookbook page was
being recorded as a recipe somebody typed out by hand. D16's household-only rule
hangs off that column.
