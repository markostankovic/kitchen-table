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
import { AiFailure } from "../_shared/ai.ts";
import { checkQuota, recordUsage } from "../_shared/usage.ts";
import {
  createJob,
  markFailed,
  markNeedsReview,
  markProcessing,
} from "../_shared/jobs.ts";
import { enrich, readRecipeFromContent } from "../_shared/read_recipe.ts";

/**
 * Long enough for a two-column cookbook page typed out, short enough that a
 * paste of somebody's entire clipboard is refused before it is paid for.
 */
const MAX_INPUT_CHARS = 40_000;

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

    // Tier 0. The prompt, the model and the enrichment are in
    // _shared/read_recipe.ts because import-url's fallback and import-photo
    // need all three unchanged.
    const parse = await readRecipeFromContent([
      { type: "text", text: job.text },
    ]);

    await recordUsage(service, {
      ...parse.usage,
      householdId,
      userId,
      functionName: "import-text",
    });

    const { result, usage } = await enrich(caller, parse.value, job.sourceUrl);

    if (usage) {
      await recordUsage(service, {
        ...usage,
        householdId,
        userId,
        functionName: "match-ingredients",
      });
    }

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
