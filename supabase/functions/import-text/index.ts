/// <reference types="npm:@supabase/functions-js@2/src/edge-runtime.d.ts" />
/**
 * import-text -- turn a pasted block of text into a reviewable recipe draft.
 *
 * An Edge Function because it holds the model API key (CLAUDE.md rule 2) and
 * because it needs to be slow: reading a page of prose takes long enough that
 * it cannot sit inside the request that started it (docs/ARCHITECTURE.md, "an
 * Edge Function exists if and only if it needs a secret, needs to be trusted,
 * or needs to be slow").
 *
 * So the response is the job id and nothing else. The work continues after it
 * on `EdgeRuntime.waitUntil`, and the client polls import_jobs (D14). That is
 * the same path a 30-second cookbook photo will take -- one code path, which
 * is the whole argument for the queue.
 *
 * The household is resolved server-side from the caller's membership. As in
 * create-invite, the client has no business naming a household it might not
 * belong to.
 */

import {
  HttpError,
  jsonResponse,
  readJsonBody,
  withHttp,
} from "../_shared/http.ts";
import {
  callerClient,
  requireCaller,
  resolveHousehold,
  serviceClient,
} from "../_shared/auth.ts";
import { AiFailure, callStructured, MODELS } from "../_shared/ai.ts";
import { checkQuota, recordUsage } from "../_shared/usage.ts";
import {
  createJob,
  markFailed,
  markNeedsReview,
  markProcessing,
} from "../_shared/jobs.ts";
import { loadUnitLexicon, matchRecipeLines } from "../_shared/match.ts";
import { ModelRecipe, type ParsedRecipeT } from "../_shared/schema.ts";

/**
 * Long enough for a two-column cookbook page typed out, short enough that a
 * paste of somebody's entire clipboard is refused before it is paid for.
 */
const MAX_INPUT_CHARS = 40_000;

const SYSTEM = `You read a block of text containing a recipe and return it as \
structured data.

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

Deno.serve(withHttp(async (req: Request): Promise<Response> => {
  const userId = await requireCaller(req);
  const service = serviceClient();
  // Captured now, while the request still exists. The background task below
  // outlives it, and search_ingredients needs the caller's RLS (D31) -- the
  // service role would see every household's private aliases.
  const caller = callerClient(req);

  const membership = await resolveHousehold(service, userId);
  if (!membership) {
    throw new HttpError(404, "no_household", "You are not in a household yet.");
  }

  const body = await readJsonBody(req);
  const text = typeof body.text === "string" ? body.text.trim() : "";
  const sourceUrl = typeof body.sourceUrl === "string" ? body.sourceUrl : null;

  if (text.length === 0) {
    throw new HttpError(400, "empty_input", "There is nothing to import.");
  }
  if (text.length > MAX_INPUT_CHARS) {
    throw new HttpError(
      400,
      "input_too_large",
      "That is too much text to read at once.",
    );
  }

  // Before the job row, not after. A household over its cap should be told so
  // synchronously, rather than getting a job id that fails a second later --
  // and a queue of jobs that exist only to fail is how a retry loop starts.
  await checkQuota(service, membership.householdId);

  const jobId = await createJob(service, {
    householdId: membership.householdId,
    userId,
    kind: "text",
    inputText: text,
    inputUrl: sourceUrl,
  });

  // Everything past here is the client's problem to poll for, not to wait on.
  EdgeRuntime.waitUntil(
    process({
      service,
      caller,
      jobId,
      householdId: membership.householdId,
      userId,
      text,
      sourceUrl,
    }),
  );

  return jsonResponse({ jobId, status: "queued" }, 202);
}));

interface Job {
  service: ReturnType<typeof serviceClient>;
  caller: ReturnType<typeof callerClient>;
  jobId: string;
  householdId: string;
  userId: string;
  text: string;
  sourceUrl: string | null;
}

/**
 * The half that runs after the response.
 *
 * Nothing in here may throw: there is no request left to turn an exception
 * into a status code, and an unhandled rejection in a background task leaves
 * the job stuck in `processing` forever with nothing to say why.
 */
async function process(job: Job): Promise<void> {
  const { service, caller, jobId, householdId, userId } = job;

  try {
    await markProcessing(service, jobId);

    // Tier 0: the model reads prose and returns lines. It is not asked for
    // quantities, units or ingredient ids -- parse_line.ts and
    // search_ingredients produce those exactly, and asking for them again
    // would replace exact work with a guess (D41).
    const parse = await callStructured({
      model: MODELS.PROSE,
      schema: ModelRecipe,
      system: SYSTEM,
      content: [{ type: "text", text: job.text }],
    });

    await recordUsage(service, {
      ...parse.usage,
      householdId,
      userId,
      functionName: "import-text",
    });

    const lexicon = await loadUnitLexicon(caller);
    const matched = await matchRecipeLines(
      caller,
      parse.value.ingredients.map((line) => ({
        rawText: line.rawText,
        section: line.section ?? null,
      })),
      parse.value.originalLocale,
      lexicon,
    );

    if (matched.usage) {
      await recordUsage(service, {
        ...matched.usage,
        householdId,
        userId,
        functionName: "match-ingredients",
      });
    }

    const result: ParsedRecipeT = {
      ...parse.value,
      sourceUrl: job.sourceUrl,
      ingredients: matched.lines,
      steps: parse.value.steps,
    };

    await markNeedsReview(service, jobId, result);
  } catch (e) {
    // A call that failed AFTER billing still has to be counted, or the cap
    // silently stops seeing the most expensive calls there are: the ones that
    // spent tokens and produced nothing. AiFailure carries its own usage for
    // exactly this, so the catch does not have to guess.
    if (e instanceof AiFailure) {
      await recordUsage(service, {
        ...e.usage,
        householdId,
        userId,
        functionName: "import-text",
      });
    }
    await markFailed(service, jobId, e);
  }
}
