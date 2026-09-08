/**
 * Zod: the single definition of every AI-facing shape (D18).
 *
 * `lib/features/import/domain/parsed_recipe.dart` is GENERATED from this file
 * by `make types` and must never be hand-edited. If the parse contract
 * changes, it changes here and nowhere else -- hand-mirroring it in Dart drifts
 * silently, because a renamed field makes the Dart parser read null and the bug
 * surfaces three screens later.
 *
 * TWO schemas live here, and the split is the important part (D41).
 *
 *   ModelRecipe  -- what a model is ASKED for. Prose and raw ingredient lines,
 *                   nothing else.
 *   ParsedRecipe -- what `import_jobs.result` HOLDS and the confirm screen
 *                   reads. ModelRecipe plus everything the deterministic
 *                   pipeline added.
 *
 * A model is never asked for quantities, unit codes or ingredient ids. It would
 * happily invent all three, and it does not need to: `parse_line.ts` produces
 * integer fractions and `units.code` values deterministically and is held to
 * `test/fixtures/ingredient_lines.json`, and `search_ingredients` produces
 * matches and is held to the SQL tests. Asking a model for work that is already
 * exact is how the exact work gets quietly replaced by a guess.
 */

import { z } from "zod";

// ---------------------------------------------------------------------------
// Shared leaves
// ---------------------------------------------------------------------------

/** `sr` and `en`. Nothing else, ever (CLAUDE.md conventions). */
export const Locale = z.enum(["sr", "en"]).meta({ title: "ParsedLocale" });

/**
 * A quantity as an exact integer fraction (CLAUDE.md rule 5). `1 1/2` is
 * `{num: 3, den: 2}`, never 1.5, because a shopping list that sums halves and
 * thirds across a week has to land on exact numbers.
 *
 * Produced by `parse_line.ts`, never by a model.
 */
export const ParsedQuantity = z.object({
  num: z.int(),
  den: z.int().positive(),
  maxNum: z.int().nullable().optional(),
  maxDen: z.int().positive().nullable().optional(),
}).meta({ title: "ParsedQuantity" });

/**
 * How a line came to be linked to a catalog ingredient (D7).
 *
 * `manual` is deliberately absent. A machine pass cannot produce a human
 * decision; only the confirm screen upgrades a line to `manual`, and that
 * happens on the client against `recipe_ingredients`, never in a job result.
 */
export const MachineMatchMethod = z.enum(["exact", "alias", "fuzzy", "llm"])
  .meta({ title: "ParsedMatchMethod" });

// ---------------------------------------------------------------------------
// ModelRecipe -- the structured-output contract
// ---------------------------------------------------------------------------

/**
 * One ingredient line as the model found it on the page.
 *
 * `rawText` is the line as printed and is required. That is CLAUDE.md rule 3
 * expressed in the schema rather than in a comment: a model that returns a
 * section heading with no line fails validation instead of writing a null into
 * a NOT NULL column three steps later.
 */
export const ModelIngredientLine = z.object({
  rawText: z.string().min(1).describe(
    "The ingredient line exactly as it appears, including quantity and unit. " +
      "Do not reformat, translate, or split it.",
  ),
  section: z.string().nullable().optional().describe(
    "The heading this line sits under, if the list has headings, e.g. " +
      "'Za fil' or 'For the sauce'. Null when the list is flat.",
  ),
});

export const ModelStep = z.object({
  text: z.string().min(1).describe(
    "One preparation step, in the recipe's original language.",
  ),
  timerSeconds: z.int().positive().nullable().optional().describe(
    "Duration in seconds if the step names an explicit time, else null.",
  ),
}).meta({ title: "ParsedStep" });

/**
 * What an import function asks a model to return.
 *
 * Deliberately narrow. Everything omitted here is either produced
 * deterministically later (quantities, units, matches) or is not the model's to
 * decide (household, source type, status -- anything AI-produced stays `draft`
 * until a human marks it tested, per the standing rules in docs/ROADMAP.md).
 */
export const ModelRecipe = z.object({
  title: z.string().min(1),
  description: z.string().nullable().optional().describe(
    "A headnote or short introduction, if the source has one.",
  ),
  servings: z.int().positive().nullable().optional(),
  prepMinutes: z.int().nonnegative().nullable().optional(),
  cookMinutes: z.int().nonnegative().nullable().optional(),
  originalLocale: Locale.describe(
    "The language the recipe is written in. 'sr' for Serbian (in either " +
      "script), 'en' for English.",
  ),
  sourceAttribution: z.string().nullable().optional().describe(
    "Book title, author, page, or site name -- whatever credits the source. " +
      "Null if the source does not say.",
  ),
  ingredients: z.array(ModelIngredientLine),
  steps: z.array(ModelStep),
});

// ---------------------------------------------------------------------------
// ParsedRecipe -- what import_jobs.result holds
// ---------------------------------------------------------------------------

/**
 * A ModelIngredientLine after `parse_line.ts` and `match-ingredients` have run.
 *
 * Every added field is nullable, and that is rule 3 again from the other side:
 * an unparsed line and an unmatched line are both supported states. The line
 * still renders on the confirm screen exactly as it was written.
 */
export const ParsedIngredientLine = ModelIngredientLine.extend({
  // --- filled by parse_line.ts (tier 1) ---
  quantity: ParsedQuantity.nullable().optional(),
  unitCode: z.string().nullable().optional().describe(
    "A units.code. Null when no unit was recognised.",
  ),
  name: z.string().nullable().optional().describe(
    "The literal remainder after quantity and unit -- inflected as written, " +
      "because the parser does not de-inflect (D6).",
  ),
  note: z.string().nullable().optional(),
  isOptional: z.boolean().default(false),

  // --- filled by match-ingredients (tiers 2-4) ---
  ingredientId: z.uuid().nullable().optional(),
  matchMethod: MachineMatchMethod.nullable().optional(),
  matchConfidence: z.number().min(0).max(1).nullable().optional(),
  /**
   * Whether the confirm screen should pre-accept this match.
   *
   * Carried, never recomputed. The 0.75 auto-accept line lives only inside
   * `search_ingredients` (D31) and gets no second home in TypeScript any more
   * than it gets one in Dart.
   */
  autoAccept: z.boolean().default(false),
  /**
   * The catalog's own name for the matched ingredient, in the recipe's locale.
   *
   * The confirm screen renders this rather than `name` when a line is matched
   * -- that hop is D1's payoff, and it is what makes one shopping list read
   * `brašno` whether the recipe said `brašna` or `flour`.
   */
  displayName: z.string().nullable().optional(),
}).meta({ title: "ParsedIngredientLine" });

export const ParsedStep = ModelStep;

/**
 * The complete result of an import, ready for the confirm screen (D8).
 *
 * `sourceUrl` is here and not on ModelRecipe because the importer knows it and
 * the model does not -- it is the URL that was fetched, not something read off
 * the page.
 */
export const ParsedRecipe = ModelRecipe.extend({
  sourceUrl: z.url().nullable().optional(),
  ingredients: z.array(ParsedIngredientLine),
  steps: z.array(ParsedStep),
}).meta({ title: "ParsedRecipe" });

export type ModelRecipeT = z.infer<typeof ModelRecipe>;
export type ParsedRecipeT = z.infer<typeof ParsedRecipe>;
export type ParsedIngredientLineT = z.infer<typeof ParsedIngredientLine>;
export type ParsedQuantityT = z.infer<typeof ParsedQuantity>;
