/**
 * "Translate a household's tag vocabulary", once per untranslated key
 * (Phase 6, part 1b).
 *
 * `translate.ts`'s counterpart for vocabulary rather than prose: one model
 * call for the whole batch of untranslated tags, not one per tag -- a tag is
 * a word or two, and asking separately would multiply round trips for no
 * reason `translate-recipe`'s own per-recipe shape has.
 */

import { AiFailure, type AiResult, callStructured, MODELS } from "./ai.ts";
import {
  ModelTagTranslations,
  type ModelTagTranslationsT,
  type ModelTagTranslationT,
} from "./schema.ts";

/**
 * The largest batch `translateTags` sends in one call.
 *
 * A household's tag vocabulary is a handful of entries (D108's own framing
 * for `recipe_tag_names`); this is a backstop against a runaway vocabulary
 * costing more than one call, not a limit any real household should reach.
 */
export const MAX_TAGS_PER_CALL = 50;

/**
 * What `translate-tags` asks a model for, every time.
 *
 * The one rule this adds beyond `TRANSLATE_SYSTEM_PROMPT`'s own: return
 * exactly one entry per requested key, echoing it back unchanged, and
 * translate a tag as a short label rather than a sentence -- a chip reads
 * "Posno", not "This dish is suitable for fasting."
 */
export const TRANSLATE_TAGS_SYSTEM_PROMPT = `You translate a household's \
recipe tags -- short labels like "brzo" or "posno" -- into both Serbian and \
English.

Rules:
- Translate each tag as a short label, capitalized the way a chip reads, not \
as a sentence or a definition.
- Serbian output is ALWAYS Latin script, never Cyrillic, regardless of which \
script the source used.
- Return exactly one entry per requested key, and echo that key back \
UNCHANGED -- it is how your reply is matched to the tag that was asked for, \
not a value you are free to alter, reformat or translate.
- Do not add, drop or duplicate keys.`;

export interface TagToTranslate {
  readonly key: string;
  readonly label: string;
}

export interface TagTranslation {
  readonly key: string;
  readonly sr: string;
  readonly en: string;
}

function buildTagsRequest(tags: readonly TagToTranslate[]): string {
  const lines = ["Translate these tags into Serbian and English:", ""];
  for (const tag of tags) {
    lines.push(`${tag.key}: ${tag.label}`);
  }
  return lines.join("\n");
}

/**
 * Checks that a model's returned keys are exactly the requested ones -- no
 * duplicate, no missing, no extra -- and returns the entries sorted by key.
 *
 * Pure, and exported separately from [translateTags] so it is testable
 * without a network call (`translate_tags_test.ts`), on `alignSteps`'s own
 * exact stance: a plain `Error`, converted into a billed [AiFailure] by the
 * caller, which is what knows this call's usage.
 */
export function alignTags(
  requested: readonly TagToTranslate[],
  returned: readonly ModelTagTranslationT[],
): ModelTagTranslationT[] {
  const expected = requested.map((t) => t.key).toSorted();
  const got = returned.map((t) => t.key).toSorted();

  const mismatched = expected.length !== got.length ||
    expected.some((key, i) => key !== got[i]);
  if (mismatched) {
    throw new Error(
      `translated tags do not match the requested keys: expected ` +
        `[${expected.join(",")}], got [${got.join(",")}]`,
    );
  }

  return returned.toSorted((a, b) => a.key.localeCompare(b.key));
}

/**
 * The Serbian and English spelling of every tag in [tags], in one call.
 *
 * [tags] is capped to [MAX_TAGS_PER_CALL] entries before it reaches the
 * model, so the prompt stays bounded -- the caller (`translate-tags/index.ts`)
 * is what decides which keys make this run's cut when a household's
 * vocabulary somehow exceeds it; a leftover key simply waits for the next
 * save that triggers this function.
 *
 * Refuses (as an [AiFailure]) rather than saves a partial or mismatched
 * batch: [alignTags] validates the returned keys against [tags]' own before
 * this returns.
 */
export async function translateTags(
  tags: readonly TagToTranslate[],
): Promise<AiResult<TagTranslation[]>> {
  const batch = tags.slice(0, MAX_TAGS_PER_CALL);

  const result: AiResult<ModelTagTranslationsT> = await callStructured({
    model: MODELS.TRANSLATION,
    schema: ModelTagTranslations,
    system: TRANSLATE_TAGS_SYSTEM_PROMPT,
    content: [{ type: "text", text: buildTagsRequest(batch) }],
  });

  let aligned: ModelTagTranslationT[];
  try {
    aligned = alignTags(batch, result.value.tags);
  } catch {
    throw new AiFailure(
      "The translation did not match the requested tags.",
      result.usage,
    );
  }

  return {
    value: aligned.map((t) => ({ key: t.key, sr: t.sr, en: t.en })),
    usage: result.usage,
  };
}
