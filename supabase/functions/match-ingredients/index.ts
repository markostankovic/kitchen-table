/**
 * match-ingredients -- re-run the matcher over an import job's lines.
 *
 * An Edge Function because tier 4 costs money and holds the model key
 * (docs/ARCHITECTURE.md). The pipeline itself lives in `_shared/match.ts`, so
 * the importers run it in-process rather than making an HTTP hop to this
 * function -- this is the standalone entry point, not the only way in.
 *
 * It takes a job id and rewrites that job's `result`. It cannot write
 * `recipe_ingredients`, because at this point in the flow there is no recipe:
 * D8 puts a human between an import and a saved recipe, so the only thing
 * there is to annotate is the draft.
 *
 * What it is for: a job that came back with several unmatched lines, where the
 * catalog has since grown -- somebody confirmed those strings on another
 * import -- and re-matching is worth a second look before the cook edits nine
 * lines by hand. It is idempotent, and re-running it on a fully matched job
 * makes no model call at all.
 *
 * Unlike import-text this is synchronous: there is no prose to read, so the
 * work is a handful of RPCs and at most one small model call. A job id in, a
 * job id out.
 */

import {
  HttpError,
  jsonResponse,
  readJsonBody,
  withHttp,
} from "../_shared/http.ts";
import { callerClient, requireCaller, serviceClient } from "../_shared/auth.ts";
import { checkQuota, recordUsage } from "../_shared/usage.ts";
import { loadJobForCaller, markNeedsReview } from "../_shared/jobs.ts";
import { loadUnitLexicon, matchRecipeLines } from "../_shared/match.ts";
import { AiFailure } from "../_shared/ai.ts";
import type { ParsedRecipeT } from "../_shared/schema.ts";

Deno.serve(withHttp(async (req: Request): Promise<Response> => {
  const userId = await requireCaller(req);
  const service = serviceClient();
  const caller = callerClient(req);

  const body = await readJsonBody(req);
  const jobId = typeof body.jobId === "string" ? body.jobId : "";
  if (jobId.length === 0) {
    throw new HttpError(400, "invalid_body", "A job id is required.");
  }

  const job = await loadJobForCaller(service, jobId, userId);

  if (!job.result) {
    throw new HttpError(
      409,
      "job_not_parsed",
      "That import has not been read yet.",
    );
  }
  // A job whose recipe is already saved is finished. Rewriting its result
  // would change what the confirm screen shows for a decision already made,
  // and D8's whole point is that the human decision is the one that stands.
  if (job.status === "done") {
    throw new HttpError(
      409,
      "job_already_done",
      "That import has already been saved.",
    );
  }

  await checkQuota(service, job.householdId);

  const previous: ParsedRecipeT = job.result;
  const lexicon = await loadUnitLexicon(caller);

  // Re-parsed from rawText rather than reusing the stored structure, so an
  // improved parse_line.ts reaches old jobs. rawText is the one field that is
  // always there to re-derive from (rule 3), which is what makes that safe.
  let matched;
  try {
    matched = await matchRecipeLines(
      caller,
      previous.ingredients.map((line) => ({
        rawText: line.rawText,
        section: line.section ?? null,
      })),
      previous.originalLocale,
      lexicon,
    );
  } catch (e) {
    // A refusal or a malformed reply still spent tokens. Recording them here
    // and rethrowing is what keeps the cap honest about the calls that cost
    // money and produced nothing.
    if (e instanceof AiFailure) {
      await recordUsage(service, {
        ...e.usage,
        householdId: job.householdId,
        userId,
        functionName: "match-ingredients",
      });
    }
    throw e;
  }

  if (matched.usage) {
    await recordUsage(service, {
      ...matched.usage,
      householdId: job.householdId,
      userId,
      functionName: "match-ingredients",
    });
  }

  await markNeedsReview(service, jobId, {
    ...previous,
    ingredients: matched.lines,
  });

  return jsonResponse({
    jobId,
    matched: matched.lines.filter((l) => l.ingredientId !== null).length,
    total: matched.lines.length,
  });
}));
