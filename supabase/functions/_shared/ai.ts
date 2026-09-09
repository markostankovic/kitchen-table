/**
 * The model client. The only file in the repository that holds an API key
 * (CLAUDE.md rule 2 -- no provider key ever reaches the client).
 *
 * Every call here returns its token usage alongside its value. That is not
 * politeness: `ai_usage` requires model, input tokens, output tokens and cost,
 * and a helper that returned only the answer would make dropping the ledger
 * entry the path of least resistance. D17 says usage limits from day one, and
 * a limit you can forget to record is not a limit.
 *
 * Pricing lives here too, in one table, because `cost_micros` has to be
 * computed somewhere and two places that both know what Opus costs is one
 * place too many.
 */

import Anthropic from "@anthropic-ai/sdk";
import { betaZodOutputFormat } from "@anthropic-ai/sdk/helpers/beta/zod";
import type { z } from "zod";
import { HttpError } from "./http.ts";

/**
 * Which model does what.
 *
 * `PROSE` reads a cookbook page or a web article and returns structure. The
 * hard part of a printed page is layout, not character recognition (D15) --
 * two columns, sidebar ingredient lists, headnotes mixed with method -- and
 * that is a reasoning problem worth the better model. Vision uses the same
 * one, because it is the same job with an image attached.
 *
 * `MATCHING` is the LLM tier of ingredient matching (docs/INGREDIENTS.md tier
 * 4): pick, from a short list of candidates the database already produced,
 * which one a string names. Narrow, high volume, batched one call per recipe.
 * A cheaper model is the right instrument, not a compromise.
 */
export const MODELS = {
  PROSE: "claude-opus-5",
  VISION: "claude-opus-5",
  MATCHING: "claude-haiku-4-5",
} as const;

export type ModelId = typeof MODELS[keyof typeof MODELS];

/**
 * What each model actually accepts.
 *
 * Adaptive thinking is NOT universal. Haiku 4.5 predates it and answers
 * `adaptive thinking is not supported on this model` with a 400 -- which is
 * how tier 4 came to be broken from the day it was written and stay broken
 * for three parts: `callStructured` sent `thinking: adaptive` for every model,
 * and part 4's best-effort catch then swallowed the failure and returned the
 * deterministic matches. It logged, and nothing else went wrong, so nothing
 * asked why.
 *
 * A table rather than an `if` at the call site, so adding a model is a row
 * here and `ai_test.ts` fails if a selectable model has no entry.
 */
const CAPABILITIES: Record<
  string,
  { adaptiveThinking: boolean; refusalFallback: boolean }
> = {
  // Reasoning about a page's layout is what this model is for, and a
  // classifier refusal on a cookbook page should degrade rather than fail.
  "claude-opus-5": { adaptiveThinking: true, refusalFallback: true },
  // Pre-4.6: no adaptive thinking, and no server-side fallback either. It is
  // also the right instrument without thinking -- picking one of eight
  // candidates is not a reasoning problem.
  "claude-haiku-4-5": { adaptiveThinking: false, refusalFallback: false },
};

/**
 * US dollars per million tokens, as micro-dollars per token.
 *
 * Written as the published per-MTok price divided by 1e6 rather than as a
 * pre-computed constant, so checking it against the pricing page is reading
 * two numbers instead of trusting one.
 */
export const MODEL_CAPABILITIES = CAPABILITIES;

export const PRICING: Record<
  string,
  { inPerMTok: number; outPerMTok: number }
> = {
  "claude-opus-5": { inPerMTok: 5, outPerMTok: 25 },
  "claude-haiku-4-5": { inPerMTok: 1, outPerMTok: 5 },
};

/** What every call in this file returns beside its answer. */
export interface AiUsage {
  readonly model: string;
  readonly inputTokens: number;
  readonly outputTokens: number;
  readonly costMicros: number;
}

export interface AiResult<T> {
  readonly value: T;
  readonly usage: AiUsage;
}

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`missing env var ${name}`);
  return value;
}

let cached: Anthropic | undefined;

/** One client per isolate. Constructing it per request is pure overhead. */
function client(): Anthropic {
  cached ??= new Anthropic({ apiKey: requireEnv("ANTHROPIC_API_KEY") });
  return cached;
}

/**
 * Micro-dollars for a call. An unknown model costs 0 rather than throwing:
 * losing the recipe because the price table is stale would be a worse trade
 * than under-counting one call, and the row still lands with its token counts
 * so the gap is visible.
 */
export function costMicros(
  model: string,
  inputTokens: number,
  outputTokens: number,
): number {
  const price = PRICING[model];
  if (!price) {
    console.error(`no price for model ${model}; recording cost_micros = 0`);
    return 0;
  }
  const dollars = (inputTokens * price.inPerMTok +
    outputTokens * price.outPerMTok) / 1_000_000;
  return Math.round(dollars * 1_000_000);
}

/**
 * One user-message content block: text, or an image for the vision path.
 *
 * The SDK's own type rather than a hand-written union. Re-declaring it would
 * lose the media_type constraint -- the API accepts four image formats and a
 * local `media_type: string` would let a fifth through to a runtime 400.
 */
export type ContentBlock = Anthropic.Beta.BetaContentBlockParam;

export interface StructuredCallOptions<S extends z.ZodType> {
  readonly model: ModelId;
  readonly schema: S;
  readonly system: string;
  readonly content: ContentBlock[];
  readonly maxTokens?: number;
}

/**
 * Asks a model for a value matching `schema` and returns it parsed.
 *
 * Structured output rather than "return JSON" in the prompt: the schema is
 * enforced by the API, so a response that does not match is an API error here
 * instead of a `JSON.parse` surprise two functions away. The same Zod object
 * that `make types` generates Dart from is what constrains the model, which is
 * what D18 means by a single definition.
 */
export async function callStructured<S extends z.ZodType>(
  options: StructuredCallOptions<S>,
): Promise<AiResult<z.infer<S>>> {
  const { model, schema, system, content, maxTokens = 16_000 } = options;

  // Not every model takes every option -- see CAPABILITIES. Sending one a
  // model does not support is a 400, not a warning.
  const can = CAPABILITIES[model] ??
    { adaptiveThinking: false, refusalFallback: false };

  // client.beta.messages, not client.messages: `fallbacks` exists only on the
  // beta surface. Sending it on the plain endpoint typechecks -- `parse` is
  // generic over its params, so excess-property checking does not fire -- and
  // then silently does nothing, which is the worst of the three outcomes.
  const response = await withRetry(() =>
    client().beta.messages.parse({
      model,
      max_tokens: maxTokens,
      system,
      messages: [{ role: "user", content }],
      output_config: { format: betaZodOutputFormat(schema) },
      // Adaptive thinking: the model decides how much reasoning a page needs.
      // A two-ingredient card and a two-column spread arrive on the same
      // endpoint and should not cost the same.
      ...(can.adaptiveThinking
        ? { thinking: { type: "adaptive" as const } }
        : {}),
      // A safety classifier can decline a request. Without a fallback that is
      // a failed import; with one it is a slightly weaker answer. An imported
      // recipe is reviewed by a human before it is saved either way (D8).
      ...(can.refusalFallback
        ? {
          betas: ["server-side-fallback-2026-07-01"],
          fallbacks: "default" as const,
        }
        : {}),
    })
  );

  const usage: AiUsage = {
    model,
    inputTokens: response.usage.input_tokens,
    outputTokens: response.usage.output_tokens,
    costMicros: costMicros(
      model,
      response.usage.input_tokens,
      response.usage.output_tokens,
    ),
  };

  // Checked before the content is read, because on a refusal there is no
  // content to read. Tokens were still spent, so the caller still records
  // usage -- which is why this throws an HttpError rather than returning null.
  if (response.stop_reason === "refusal") {
    throw new AiRefusal(usage);
  }

  const parsed = response.parsed_output;
  if (parsed === null || parsed === undefined) {
    throw new AiFailure(
      "The model's reply did not match the expected shape.",
      usage,
    );
  }

  return { value: parsed as z.infer<S>, usage };
}

/**
 * A failure that still spent tokens.
 *
 * Carries its usage so the caller can record the ledger row on the way out.
 * A call that failed after billing is exactly the call you most want in the
 * ledger, because it is the one that burns money without producing a recipe.
 */
export class AiFailure extends HttpError {
  constructor(message: string, readonly usage: AiUsage) {
    super(502, "ai_failed", message);
    this.name = "AiFailure";
  }
}

export class AiRefusal extends AiFailure {
  constructor(usage: AiUsage) {
    super("The model declined to read this source.", usage);
    this.name = "AiRefusal";
  }
}

const RETRY_DELAYS_MS = [1_000, 4_000, 10_000];

/**
 * Retries on rate limits and server errors, with backoff.
 *
 * Branches on the SDK's typed status rather than on message text: an error
 * class is a contract and a message is prose. 4xx other than 429 is not
 * retried -- a malformed request stays malformed.
 */
async function withRetry<T>(call: () => Promise<T>): Promise<T> {
  let lastError: unknown;

  for (let attempt = 0; attempt <= RETRY_DELAYS_MS.length; attempt++) {
    try {
      return await call();
    } catch (e) {
      lastError = e;

      const status = e instanceof Anthropic.APIError ? e.status : undefined;
      const retryable = e instanceof Anthropic.APIConnectionError ||
        status === 429 ||
        (status !== undefined && status >= 500);

      if (!retryable || attempt === RETRY_DELAYS_MS.length) break;

      console.error(
        `model call failed (status ${status}), retry ${attempt + 1}`,
      );
      await new Promise((r) => setTimeout(r, RETRY_DELAYS_MS[attempt]));
    }
  }

  if (lastError instanceof Anthropic.APIError) {
    if (lastError.status === 429) {
      throw new HttpError(
        429,
        "ai_rate_limited",
        "The recipe service is busy. Try again in a minute.",
      );
    }

    // 400/401/403 from the provider: a rejected key, an exhausted credit
    // balance, or a request this code built wrongly. None of them is the
    // cook's doing and none is fixable by retrying, so they get a distinct
    // code rather than falling through to `internal_error` -- which should
    // mean "unexpected", and a provider that is switched off is not.
    //
    // The provider's own message goes to the log in full and never to the
    // client: "Your credit balance is too low" is an operator's sentence, and
    // it names the operator's account.
    if (
      lastError.status === 400 || lastError.status === 401 ||
      lastError.status === 403
    ) {
      console.error(
        `model provider refused the request (${lastError.status})`,
        lastError,
      );
      throw new HttpError(
        503,
        "ai_unavailable",
        "The recipe reader is unavailable right now.",
      );
    }
  }
  throw lastError;
}
