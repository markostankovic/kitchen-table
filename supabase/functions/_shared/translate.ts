/**
 * "Translate a recipe's prose", once (Phase 3, part 2).
 *
 * `read_recipe.ts`'s own header put it well for import: the prompt, the
 * model and the shape of what comes out belong in one place rather than
 * inside the function that first needed them. This is that file's
 * counterpart for translation -- smaller, because there is only one caller
 * so far (`translate-recipe/index.ts`), but the same split between "the
 * prompt" and "the thin wrapper around it".
 */

import { AiFailure, type AiResult, callStructured, MODELS } from "./ai.ts";
import { ModelTranslation, type ModelTranslationT } from "./schema.ts";

/**
 * What `translate-recipe` asks a model for, every time.
 *
 * The rules earn their place individually:
 *
 * - Ingredient lines are never sent and never mentioned, because they are
 *   never translated per recipe (D1) -- they render from the catalog at read
 *   time, and sending them here would invite a second, worse answer to a
 *   question `ingredient_display_name()` already answers exactly.
 * - Serbian output is Latin script only, always (D4 / CLAUDE.md). A model
 *   asked for Serbian will otherwise return Cyrillic perfectly happily, and
 *   nothing downstream would catch it -- there is no display path in this
 *   app that expects it.
 * - Every source step gets exactly one translated step back, at the SAME
 *   position. That number is an alignment key the caller uses to match a
 *   translated line to its source, not a value the model is asked to derive
 *   -- `alignSteps` below validates it and refuses to guess past a mismatch.
 */
export const TRANSLATE_SYSTEM_PROMPT = `You translate a recipe's title, \
description and method into the language you are asked for. The ingredient \
list is never given to you and is never translated here -- it renders from a \
separate catalog that already knows both languages, so nothing about \
ingredient lines is your job.

Rules:
- Translate naturally, in the register a cook writes in, not word-for-word. \
Keep quantities, units and any brand or proper names that appear inside a \
step's text -- you are translating the sentence around them, not the numbers.
- Serbian output is ALWAYS Latin script, never Cyrillic, regardless of which \
script the source used.
- Do not add, drop, merge or split steps. Return exactly one translated step \
per source step, and set its position to the SAME NUMBER the source step at \
that position carries -- that number is how the translation is matched back \
to its source, not a value you are free to renumber.
- Do not invent detail the source does not have, and leave description null \
if the source has none.`;

export interface TranslationSourceStep {
  readonly position: number;
  readonly text: string;
}

export interface TranslationSource {
  readonly title: string;
  readonly description: string | null;
  readonly steps: readonly TranslationSourceStep[];
}

function languageName(targetLocale: "sr" | "en"): string {
  return targetLocale === "sr" ? "Serbian (Latin script)" : "English";
}

function buildTranslationRequest(
  source: TranslationSource,
  targetLocale: "sr" | "en",
): string {
  const lines = [
    `Translate this recipe into ${languageName(targetLocale)}.`,
    "",
    `Title: ${source.title}`,
  ];
  if (source.description) lines.push(`Description: ${source.description}`);
  lines.push("Steps:");
  for (const step of source.steps) {
    lines.push(`${step.position}. ${step.text}`);
  }
  return lines.join("\n");
}

/**
 * Checks that a model's returned step positions are exactly the source's own
 * positions -- no duplicate, no missing, no extra -- and returns the steps
 * sorted into position order.
 *
 * Pure, and exported separately from [translateRecipe] so it is testable
 * without a network call (`translate_test.ts`). Throws a plain `Error`
 * rather than an `AiFailure`: this function does not know a call's usage,
 * and [translateRecipe] is what turns the throw into a billed failure.
 */
export function alignSteps(
  source: readonly TranslationSourceStep[],
  returned: readonly { position: number; text: string }[],
): { position: number; text: string }[] {
  const expected = source.map((s) => s.position).toSorted((a, b) => a - b);
  const got = returned.map((s) => s.position).toSorted((a, b) => a - b);

  const mismatched = expected.length !== got.length ||
    expected.some((position, i) => position !== got[i]);
  if (mismatched) {
    throw new Error(
      `translated steps do not match the source positions: expected ` +
        `[${expected.join(",")}], got [${got.join(",")}]`,
    );
  }

  return returned.toSorted((a, b) => a.position - b.position);
}

export interface Translation {
  readonly title: string;
  readonly description: string | null;
  readonly steps: { position: number; text: string }[];
}

/**
 * One recipe's title, description and steps, translated into [targetLocale].
 *
 * Validates the model's step positions against [source]'s own before
 * returning -- a mismatch is billed (the call still spent tokens) but
 * refused, as [AiFailure], rather than saved with a silently reordered or
 * dropped step.
 */
export async function translateRecipe(
  source: TranslationSource,
  targetLocale: "sr" | "en",
): Promise<AiResult<Translation>> {
  const result: AiResult<ModelTranslationT> = await callStructured({
    model: MODELS.TRANSLATION,
    schema: ModelTranslation,
    system: TRANSLATE_SYSTEM_PROMPT,
    content: [
      { type: "text", text: buildTranslationRequest(source, targetLocale) },
    ],
  });

  let steps: { position: number; text: string }[];
  try {
    steps = alignSteps(source.steps, result.value.steps);
  } catch {
    throw new AiFailure(
      "The translation did not match the recipe's own steps.",
      result.usage,
    );
  }

  return {
    value: {
      title: result.value.title,
      description: result.value.description ?? null,
      steps,
    },
    usage: result.usage,
  };
}
