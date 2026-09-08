/**
 * The import_jobs lifecycle, in one place.
 *
 * D14 makes every import a background job, which means every importer repeats
 * the same four moves: create the row, mark it processing, mark it
 * needs_review with a result, or mark it failed with a reason. import-text is
 * the first caller; import-url and import-photo are the reason this is not
 * inline in it.
 *
 * Every function here takes the SERVICE client, and that is not a convenience.
 * import_jobs has no INSERT and no UPDATE policy at all (D39) -- the client's
 * entire write surface is finish_import_job and dismiss_import_job -- so a
 * caller-scoped client could not write any of these transitions.
 */

import type { SupabaseClient } from "@supabase/supabase-js";
import { HttpError } from "./http.ts";
import { assertMember } from "./auth.ts";
import type { ParsedRecipeT } from "./schema.ts";

export type ImportKind = "url" | "photo" | "text";

export interface NewJob {
  readonly householdId: string;
  readonly userId: string;
  readonly kind: ImportKind;
  readonly inputUrl?: string | null;
  readonly inputText?: string | null;
  readonly inputStoragePath?: string | null;
}

/** Inserts a queued job and returns its id. */
export async function createJob(
  service: SupabaseClient,
  job: NewJob,
): Promise<string> {
  const { data, error } = await service
    .from("import_jobs")
    .insert({
      household_id: job.householdId,
      created_by: job.userId,
      kind: job.kind,
      input_url: job.inputUrl ?? null,
      input_text: job.inputText ?? null,
      input_storage_path: job.inputStoragePath ?? null,
      status: "queued",
    })
    .select("id")
    .single();

  if (error) throw error;
  return data.id as string;
}

export async function markProcessing(
  service: SupabaseClient,
  jobId: string,
): Promise<void> {
  const { error } = await service
    .from("import_jobs")
    .update({ status: "processing" })
    .eq("id", jobId);
  if (error) throw error;
}

/**
 * The successful terminal state for the machine half of an import.
 *
 * `needs_review`, never `done`. D8: import never writes a recipe silently, and
 * only `finish_import_job` moves a job to done -- after a person has looked.
 */
export async function markNeedsReview(
  service: SupabaseClient,
  jobId: string,
  result: ParsedRecipeT,
): Promise<void> {
  const { error } = await service
    .from("import_jobs")
    .update({ status: "needs_review", result })
    .eq("id", jobId);
  if (error) throw error;
}

/**
 * Records why an import failed, in the same {error, message} vocabulary the
 * HTTP layer uses -- so a job that failed days ago can still say why, in words
 * the client already knows how to translate (`_fromFunction` in
 * lib/core/supabase/supabase_failure.dart).
 *
 * Never throws. It is called from a catch block, and a failure to record a
 * failure must not replace the original one.
 */
export async function markFailed(
  service: SupabaseClient,
  jobId: string,
  cause: unknown,
): Promise<void> {
  const code = cause instanceof HttpError ? cause.code : "internal_error";
  const message = cause instanceof HttpError
    ? cause.message
    : "Something went wrong reading that recipe.";

  // The real error goes to the log in full. Only the safe pair goes in the row,
  // which the client reads -- an internal message must not reach it, exactly as
  // withHttp decided for the synchronous path.
  console.error(`import job ${jobId} failed`, cause);

  const { error } = await service
    .from("import_jobs")
    .update({ status: "failed", error_code: code, error_message: message })
    .eq("id", jobId);

  if (error) console.error(`could not mark job ${jobId} failed`, error);
}

/**
 * A job the caller may see, or a 404.
 *
 * Reads on the SERVICE client, so RLS is not there to catch a mistake and the
 * membership check is written out -- `assertMember`, the same one create-invite
 * and redeem-invite use. Two round trips rather than an embedded join because
 * import_jobs has no foreign key to household_members to traverse; the route
 * runs through households, which PostgREST cannot name in one hop.
 *
 * A job in another household is a 404 and not a 403, deliberately: "not
 * available" is all a stranger should learn about whether an id exists.
 */
export async function loadJobForCaller(
  service: SupabaseClient,
  jobId: string,
  userId: string,
): Promise<{
  id: string;
  householdId: string;
  kind: ImportKind;
  status: string;
  result: ParsedRecipeT | null;
}> {
  const { data, error } = await service
    .from("import_jobs")
    .select("id, household_id, kind, status, result")
    .eq("id", jobId)
    .is("deleted_at", null)
    .maybeSingle();

  if (error) throw error;
  if (!data) {
    throw new HttpError(404, "job_not_found", "That import is not available.");
  }

  const householdId = data.household_id as string;
  try {
    await assertMember(service, userId, householdId);
  } catch {
    throw new HttpError(404, "job_not_found", "That import is not available.");
  }

  return {
    id: data.id as string,
    householdId,
    kind: data.kind as ImportKind,
    status: data.status as string,
    result: (data.result ?? null) as ParsedRecipeT | null,
  };
}
