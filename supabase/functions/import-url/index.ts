/// <reference types="npm:@supabase/functions-js@2/src/edge-runtime.d.ts" />
/**
 * import-url -- read a recipe off a web page.
 *
 * An Edge Function for all three reasons at once (docs/ARCHITECTURE.md): it
 * holds the model API key, it fetches third-party pages, and it is slow. The
 * middle one is the dangerous one -- this is the only place in the project
 * that opens a connection to a host somebody else chose, and it does so from
 * inside Supabase's network holding the service role key. Everything that
 * makes that safe is in `_shared/url_guard.ts` (D45), and the URL is vetted
 * BEFORE a job row exists so a refusal is a synchronous 400.
 *
 * JSON-LD first, model second. Most recipe sites publish a complete
 * schema.org Recipe for Google; reading it is free, instant and cannot
 * hallucinate. The model is for the pages that do not.
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
import { parseImportUrl, safeFetch } from "../_shared/url_guard.ts";
import {
  extractJsonLd,
  findRecipeNode,
  recipeFromJsonLd,
  stripHtml,
} from "../_shared/jsonld.ts";
import type { ModelRecipeT } from "../_shared/schema.ts";

/**
 * How much of a stripped page to hand the model.
 *
 * The same ceiling import-text puts on a paste, for the same reason: a page
 * longer than this is a listing or an archive, not a recipe, and the tokens
 * would be spent finding that out.
 */
const MAX_PAGE_CHARS = 40_000;

Deno.serve(withHttp(async (req: Request): Promise<Response> => {
  const userId = await requireCaller(req);
  const service = serviceClient();
  // Captured while the request still exists; the background task outlives it.
  const caller = callerClient(req);

  const membership = await resolveHousehold(service, userId);
  if (!membership) {
    throw new HttpError(404, "no_household", "You are not in a household yet.");
  }

  const body = await readJsonBody(req);
  const raw = typeof body.url === "string" ? body.url : "";
  if (raw.trim().length === 0) {
    throw new HttpError(400, "empty_input", "There is no link to import.");
  }

  // Throws invalid_url or url_not_allowed. Synchronous and before the job row,
  // so somebody who pasted a bad link is told immediately rather than being
  // handed a job id that fails a second later.
  const url = parseImportUrl(raw);

  // Up front, not lazily. It was tempting to skip this when JSON-LD succeeds,
  // since that path makes no model call -- but tier 4 still runs on whatever
  // the catalog could not match, so a real recipe almost always costs
  // something. Checking here also means a household at its cap gets a 429 and
  // no job row, rather than a queue of jobs that exist only to fail.
  await checkQuota(service, membership.householdId);

  const jobId = await createJob(service, {
    householdId: membership.householdId,
    userId,
    kind: "url",
    inputUrl: url.toString(),
  });

  EdgeRuntime.waitUntil(
    process({
      service,
      caller,
      jobId,
      householdId: membership.householdId,
      userId,
      url,
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
  url: URL;
}

/**
 * The half that runs after the response.
 *
 * Nothing in here may throw: there is no request left to turn an exception
 * into a status code, and an unhandled rejection would leave the job stuck in
 * `processing` with nothing to say why.
 */
async function process(job: Job): Promise<void> {
  const { service, caller, jobId, householdId, userId } = job;

  try {
    await markProcessing(service, jobId);

    // Redirects are followed by hand and re-vetted at every hop, so the URL
    // that comes back is the one actually read -- which is what gets stored as
    // source_url and displayed (D16).
    const { html, url: finalUrl } = await safeFetch(job.url);

    const node = findRecipeNode(extractJsonLd(html));
    let model: ModelRecipeT | null = node === null
      ? null
      : recipeFromJsonLd(node, html);

    if (model !== null) {
      console.log(`import-url ${jobId}: read JSON-LD, no model call`);
    } else {
      const text = stripHtml(html).slice(0, MAX_PAGE_CHARS);
      if (text.length < 200) {
        // Too little to be a recipe. Failing here rather than paying for a
        // model call that can only answer "there is nothing here".
        throw new HttpError(
          400,
          "no_recipe_found",
          "There is no recipe on that page.",
        );
      }

      const parse = await readRecipeFromContent([{ type: "text", text }]);
      await recordUsage(service, {
        ...parse.usage,
        householdId,
        userId,
        functionName: "import-url",
      });
      model = parse.value;
    }

    if (model.ingredients.length === 0) {
      throw new HttpError(
        400,
        "no_recipe_found",
        "There is no recipe on that page.",
      );
    }

    const { result, usage } = await enrich(
      caller,
      model,
      finalUrl.toString(),
    );

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
    // A call that failed after billing still has to be counted, or the cap
    // stops seeing the calls that spent tokens and produced nothing.
    if (e instanceof AiFailure) {
      await recordUsage(service, {
        ...e.usage,
        householdId,
        userId,
        functionName: "import-url",
      });
    }
    await markFailed(service, jobId, e);
  }
}
