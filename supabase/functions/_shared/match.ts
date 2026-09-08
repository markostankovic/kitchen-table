/**
 * The ingredient matcher, server side: docs/INGREDIENTS.md's pipeline run over
 * a whole recipe at once.
 *
 *   tier 1  parse_line.ts        deterministic, free
 *   tier 2  search_ingredients   exact / alias, confidence 1.0
 *   tier 3  search_ingredients   fuzzy, auto-accept above the line
 *   tier 4  one batched model call for everything still unresolved
 *   tier 5  create               NOT RUN HERE -- see below
 *
 * Lives in `_shared/` rather than inside `match-ingredients/` because the
 * importers need it in-process. The alternative was an HTTP hop from
 * import-text to a sibling function, which costs a round trip, a second auth
 * check and a new failure mode, to run code that is already in the same
 * isolate.
 *
 * TIER 5 DOES NOT FIRE, AND NOTHING HERE WRITES AN ALIAS (D42).
 *
 * docs/INGREDIENTS.md says every resolution writes back, and it is right about
 * why -- ingredient strings are Zipf-distributed, so a few hundred aliases
 * cover most of everything anyone will ever write, and that is what stops the
 * LLM tier being paid for twice. The disagreement is only about WHEN.
 *
 * Writing back here would make a machine guess global and permanent (D28: one
 * string, one ingredient, forever) before any human has looked at it -- and
 * D8 exists precisely because a human looks at every import. Creating an
 * ingredient here would be worse: `za posluživanje` is a real line in the
 * fixture, and tier 5 at import time would enter it into the catalog as food.
 *
 * So the write-back moves one screen later. The confirm screen accepts by
 * default, and accepting calls `link_ingredient_alias` -- which already exists
 * (D34), already writes `source = 'user'`, and already means a human agreed.
 * The cost curve still drops on the first import of a new string; it just
 * drops after somebody nodded at it.
 *
 * That also resolves a smaller problem cleanly: `link_ingredient_alias`
 * hardcodes `source = 'user'` and requires a non-null `auth.uid()`. Calling it
 * from a machine tier would have meant either lying about provenance -- the
 * exact thing D7 exists to prevent -- or a new migration to widen it.
 */

import type { SupabaseClient } from "@supabase/supabase-js";
import { IngredientLineParser, type UnitLexicon } from "./parse_line.ts";
import { normalizeText } from "./normalize.ts";
import {
  AiFailure,
  type AiUsage,
  callStructured,
  type ContentBlock,
  MODELS,
} from "./ai.ts";
import type { ParsedIngredientLineT } from "./schema.ts";
import { z } from "zod";

/** One row of `search_ingredients`, as PostgREST returns it. */
interface SearchRow {
  ingredient_id: string;
  display_name: string;
  matched_name: string;
  matched_locale: string;
  is_verified: boolean;
  is_household_alias: boolean;
  match_method: string;
  match_confidence: number | string;
  auto_accept: boolean;
}

/** What tier 4 is asked to decide, per line. */
const LlmChoice = z.object({
  index: z.int().nonnegative().describe(
    "The index of the ingredient line this answers, from the list given.",
  ),
  candidateId: z.string().nullable().describe(
    "The id of the chosen candidate, copied exactly. Null when none of them " +
      "is the same food as the line.",
  ),
  confidence: z.number().min(0).max(1).describe(
    "How sure you are, 0 to 1. Below 0.75 the line is shown to a person as a " +
      "suggestion rather than applied.",
  ),
});

const LlmChoices = z.object({ choices: z.array(LlmChoice) });

/**
 * The unit lexicon, read once per invocation.
 *
 * `unit_names` is world-readable to `authenticated` (migration 4), so either
 * client works; the caller's is used so that nothing in this file needs the
 * service role to do its ordinary job.
 */
export async function loadUnitLexicon(
  db: SupabaseClient,
): Promise<UnitLexicon> {
  const { data, error } = await db
    .from("unit_names")
    .select("name, unit_code");
  if (error) throw error;

  const lexicon = new Map<string, string>();
  for (const row of data as { name: string; unit_code: string }[]) {
    lexicon.set(normalizeText(row.name), row.unit_code);
  }
  return lexicon;
}

/**
 * Tier 1 over every line. Pure, and separated from the tiers that do I/O so
 * that the ordering above is a thing a test can look at.
 */
export function parseLines(
  rawLines: { rawText: string; section?: string | null }[],
  lexicon: UnitLexicon,
): ParsedIngredientLineT[] {
  const parser = new IngredientLineParser(lexicon);

  return rawLines.map((line) => {
    const parsed = parser.parse(line.rawText);
    return {
      // Rule 3 first and always: whatever the tiers below do or fail to do,
      // this is the line as it was written.
      rawText: parsed.rawText,
      section: line.section ?? null,
      quantity: parsed.quantity
        ? {
          num: parsed.quantity.num,
          den: parsed.quantity.den,
          maxNum: parsed.quantity.maxNum ?? null,
          maxDen: parsed.quantity.maxDen ?? null,
        }
        : null,
      unitCode: parsed.unitCode ?? null,
      name: parsed.name ?? null,
      note: parsed.note ?? null,
      isOptional: parsed.isOptional,
      ingredientId: null,
      matchMethod: null,
      matchConfidence: null,
      autoAccept: false,
      displayName: null,
    };
  });
}

/**
 * Applies a `search_ingredients` row to a line.
 *
 * `autoAccept` is copied from the row, never derived. The 0.75 line lives only
 * inside `search_ingredients` (D31) and there is no copy of it here, in Dart,
 * or anywhere else.
 */
function applyRow(
  line: ParsedIngredientLineT,
  row: SearchRow,
): ParsedIngredientLineT {
  const method = row.match_method;
  return {
    ...line,
    ingredientId: row.ingredient_id,
    displayName: row.display_name,
    // The column is `numeric`, which PostgREST hands over as a string when it
    // will not fit a double exactly -- the same shape RecipeRepository's
    // _toNullableDouble deals with on the Dart side.
    matchConfidence: Number(row.match_confidence),
    matchMethod: method === "exact" || method === "alias" || method === "fuzzy"
      ? method
      : null,
    autoAccept: row.auto_accept,
  };
}

/**
 * Tiers 2 and 3, one RPC per distinct name.
 *
 * Deduplicated by normalized name before the calls go out: a recipe that lists
 * `2 kašike ulja` and `100 ml ulja` asks about *ulje* once. Distinct names in
 * one recipe are few enough that a per-name round trip is cheaper than the
 * batching machinery would be.
 *
 * MUST be given a caller-scoped client. `search_ingredients` is security
 * invoker, so the service role would see every household's private aliases.
 */
export async function matchFromCatalog(
  caller: SupabaseClient,
  lines: ParsedIngredientLineT[],
  locale: string,
): Promise<ParsedIngredientLineT[]> {
  const byName = new Map<string, SearchRow | null>();

  for (const line of lines) {
    if (!line.name) continue;
    const key = normalizeText(line.name);
    if (key.length === 0 || byName.has(key)) continue;

    const { data, error } = await caller.rpc("search_ingredients", {
      search_query: line.name,
      preferred_locale: locale,
      max_results: 1,
    });
    if (error) throw error;

    const rows = (data ?? []) as SearchRow[];
    byName.set(key, rows.length > 0 ? rows[0] : null);
  }

  return lines.map((line) => {
    if (!line.name) return line;
    const row = byName.get(normalizeText(line.name));
    return row ? applyRow(line, row) : line;
  });
}

/**
 * Which lines tier 4 should be asked about.
 *
 * A line that matched but did NOT auto-accept is included: the catalog's
 * suggestion is carried into the prompt as a candidate, so the model either
 * agrees with it -- which raises a suggestion to something a person can accept
 * with one tap -- or names a better one. Sending only the unmatched lines
 * would throw away the case tier 3 is worst at and tier 4 is best at.
 */
export function unresolved(
  lines: ParsedIngredientLineT[],
): number[] {
  const out: number[] = [];
  lines.forEach((line, i) => {
    if (!line.name) return;
    if (line.autoAccept) return;
    out.push(i);
  });
  return out;
}

const MATCH_SYSTEM = `You match ingredient lines from a recipe to entries in a \
food catalog.

The recipe is Serbian or English. Serbian ingredient names arrive inflected --\
 "šargarepe" is the genitive of "šargarepa", "brašna" of "brašno" -- and an \
inflected form of a candidate's name is the same food, not a different one.

For each line you are given, pick the candidate that names THE SAME FOOD, or \
null if none does.

Rules:
- A candidate is only right if it is the same ingredient. "so" (salt) and \
"soja" (soy) are different foods that look alike; do not confuse them.
- A more specific line may match a more general candidate: "glatko brašno" is \
a kind of "brašno". Prefer an exact candidate when one is offered.
- Preparation words are not part of the food: "sitno seckan luk" is "luk".
- Some lines are not food at all -- "za posluživanje" (for serving) is an \
instruction. Answer null for those.
- Report confidence honestly. Below 0.75 the answer is shown to a person as a \
suggestion instead of being applied, and that is the right outcome when you \
are unsure.

Answer for every line you are given, once each, using its index.`;

/**
 * Tier 4: ALL unresolved lines of a recipe in ONE call (docs/INGREDIENTS.md).
 *
 * One call per recipe rather than per line is the whole design. Per line it
 * would cost twenty times as much and lose the context that makes a recipe
 * legible -- a list containing *brašno*, *jaja* and *mleko* tells the model
 * what kind of dish it is reading.
 *
 * Candidates come from the catalog, so the model chooses from a closed list
 * and cannot invent an ingredient id. That is also why tier 4 cannot create
 * anything: there is nothing in its answer that could name a new row.
 */
export async function matchWithModel(
  caller: SupabaseClient,
  lines: ParsedIngredientLineT[],
  locale: string,
): Promise<{ lines: ParsedIngredientLineT[]; usage: AiUsage | null }> {
  const indexes = unresolved(lines);
  if (indexes.length === 0) return { lines, usage: null };

  // Candidates per line, from the same RPC the deterministic tiers used --
  // more of them this time, because the model is choosing rather than the
  // ranking deciding.
  const candidates = new Map<number, SearchRow[]>();
  for (const i of indexes) {
    const { data, error } = await caller.rpc("search_ingredients", {
      search_query: lines[i].name,
      preferred_locale: locale,
      max_results: 8,
    });
    if (error) throw error;
    candidates.set(i, (data ?? []) as SearchRow[]);
  }

  const prompt = indexes.map((i) => {
    const rows = candidates.get(i) ?? [];
    const options = rows.length === 0
      ? "  (no candidates)"
      : rows.map((r) => `  - id ${r.ingredient_id}: ${r.display_name}`).join(
        "\n",
      );
    return `Line ${i}: ${lines[i].name}\nCandidates:\n${options}`;
  }).join("\n\n");

  const content: ContentBlock[] = [{ type: "text", text: prompt }];

  const { value, usage } = await callStructured({
    model: MODELS.MATCHING,
    schema: LlmChoices,
    system: MATCH_SYSTEM,
    content,
    maxTokens: 4_000,
  });

  const out = [...lines];
  for (const choice of value.choices) {
    const i = choice.index;
    if (!Number.isInteger(i) || i < 0 || i >= out.length) continue;
    if (choice.candidateId === null) continue;

    // The model may only choose an id that was offered for THAT line. Without
    // this a hallucinated or misplaced id would be written into
    // recipe_ingredients.ingredient_id as a foreign key to something the cook
    // never saw.
    const offered = (candidates.get(i) ?? []).find(
      (r) => r.ingredient_id === choice.candidateId,
    );
    if (!offered) continue;

    // Never overwrite a resolution the deterministic tiers already made and
    // the database was willing to auto-accept.
    if (out[i].autoAccept) continue;

    out[i] = {
      ...out[i],
      ingredientId: offered.ingredient_id,
      displayName: offered.display_name,
      matchMethod: "llm",
      matchConfidence: choice.confidence,
      // Deliberately false, always. The confirm screen is what accepts an LLM
      // answer, because D8 says a human looks at every import and this is the
      // tier with no ground truth behind it.
      autoAccept: false,
    };
  }

  return { lines: out, usage };
}

/**
 * The whole pipeline, tiers 1 to 4.
 *
 * `caller` must carry the caller's JWT. Nothing here uses the service role,
 * which is the point: matching reads the catalog and writes nothing.
 */
export async function matchRecipeLines(
  caller: SupabaseClient,
  rawLines: { rawText: string; section?: string | null }[],
  locale: string,
  lexicon: UnitLexicon,
): Promise<{ lines: ParsedIngredientLineT[]; usage: AiUsage | null }> {
  const parsed = parseLines(rawLines, lexicon);
  const fromCatalog = await matchFromCatalog(caller, parsed, locale);

  // Tier 4 is BEST EFFORT, and this try/catch is the load-bearing part of that
  // sentence.
  //
  // Tiers 1-3 are deterministic, free and already done by the time we get
  // here. Tier 4 is an enhancement on top of them in exactly the way the
  // structured columns are an enhancement on top of raw_text (rule 3) -- so
  // losing a recipe that was read perfectly well, because an optional
  // improvement to its ingredient matching was unavailable, is the wrong
  // trade every time.
  //
  // The cook sees a draft with more lines to confirm by hand. That is the
  // confirm screen's whole job (D8), and it is a far better outcome than a
  // failed import.
  //
  // Usage is still returned when the failure carried some: a call that spent
  // tokens and produced nothing is exactly the one the cap must see.
  try {
    return await matchWithModel(caller, fromCatalog, locale);
  } catch (e) {
    console.error("tier 4 unavailable; keeping the deterministic matches", e);
    return {
      lines: fromCatalog,
      usage: e instanceof AiFailure ? e.usage : null,
    };
  }
}
