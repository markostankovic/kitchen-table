/**
 * "Turn content into a reviewable draft", once.
 *
 * import-text does this with a paste, import-url's fallback does it with the
 * text of a web page, and import-photo will do it with an image. The content
 * block differs; nothing else does -- the prompt, the model, the line parse,
 * the match and the shape of what comes out are the same three times over.
 *
 * So they live here rather than in the first function that needed them.
 * import-text was written before this file existed and is refactored onto it,
 * which is what makes this a de-duplication rather than a fourth copy.
 */

import type { SupabaseClient } from "@supabase/supabase-js";
import {
  type AiResult,
  type AiUsage,
  callStructured,
  type ContentBlock,
  MODELS,
} from "./ai.ts";
import { loadUnitLexicon, matchRecipeLines } from "./match.ts";
import {
  ModelRecipe,
  type ModelRecipeT,
  type ParsedRecipeT,
} from "./schema.ts";

/**
 * What a model is asked for, everywhere.
 *
 * The rules earn their place individually:
 *
 * - Verbatim ingredient lines, because `parse_line.ts` produces integer
 *   fractions and `units.code` values deterministically and is held to
 *   `test/fixtures/ingredient_lines.json`. Asking a model to do that work
 *   again would replace exact work with a guess (D41).
 * - `originalLocale` is the language of the RECIPE, not of this instruction --
 *   a prompt in English asking about a Serbian recipe otherwise gets "en".
 * - Do not invent attribution. A standing rule says source_attribution is
 *   stored and displayed for every import, which only works if it is true.
 */
export const RECIPE_SYSTEM_PROMPT = `You read a block of text containing a \
recipe and return it as structured data.

The text may be Serbian or English, and may be messy -- pasted from a web page \
with navigation and comments around it, or typed from a book. Find the recipe \
in it and ignore the rest.

Rules:
- Return ingredient lines EXACTLY as written, including the quantity and unit, \
in one string each. Do not reformat "2 šolje" into a number and a unit, do not \
translate, and do not split one line into two. The quantity is parsed \
separately by code that is better at it than you are.
- If the ingredient list has headings ("Za fil", "For the sauce"), set each \
line's section to the heading above it. Otherwise leave section null.
- Steps are the method, one step per instruction, in the recipe's own language.
- originalLocale is the language the recipe is WRITTEN in, not the language of \
this instruction. Serbian in Latin or Cyrillic script is both "sr".
- Set sourceAttribution when the text credits a book, author or site. Do not \
invent one.
- Do not add ingredients or steps that are not in the text. A short recipe is \
a correct answer to a short text.`;

/** Tier 0: content in, structure out. */
export function readRecipeFromContent(
  content: ContentBlock[],
  model: typeof MODELS.PROSE | typeof MODELS.VISION = MODELS.PROSE,
): Promise<AiResult<ModelRecipeT>> {
  return callStructured({
    model,
    schema: ModelRecipe,
    system: RECIPE_SYSTEM_PROMPT,
    content,
  });
}

/**
 * Tiers 1 to 4 over a model's answer, producing what `import_jobs.result`
 * holds.
 *
 * `caller` must carry the caller's JWT: `search_ingredients` is security
 * invoker, and on the service role it would return every household's private
 * aliases (D31).
 */
export async function enrich(
  caller: SupabaseClient,
  model: ModelRecipeT,
  sourceUrl: string | null,
): Promise<{ result: ParsedRecipeT; usage: AiUsage | null }> {
  const lexicon = await loadUnitLexicon(caller);

  const matched = await matchRecipeLines(
    caller,
    model.ingredients.map((line) => ({
      rawText: line.rawText,
      section: line.section ?? null,
    })),
    model.originalLocale,
    lexicon,
  );

  return {
    result: {
      ...model,
      sourceUrl,
      ingredients: matched.lines,
      steps: model.steps,
    },
    usage: matched.usage,
  };
}
