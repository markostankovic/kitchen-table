/**
 * The AI spending gate (D17): both caps checked before every model call, one
 * ledger row recorded after it.
 *
 * "Cheap now, awkward to bolt on later" is the whole argument. An OCR retry
 * loop can burn real money even at family scale, and a cap added after the
 * first surprise bill is a cap that was added too late.
 *
 * Both functions take the service-role client. `ai_usage` and
 * `household_ai_limits` are readable by members through RLS and writable by
 * nobody -- there is no policy that would let a caller-scoped client insert a
 * usage row, deliberately (D39).
 */

import type { SupabaseClient } from "@supabase/supabase-js";
import { HttpError } from "./http.ts";
import type { AiUsage } from "./ai.ts";

/**
 * Throws unless the household is inside BOTH of its monthly caps.
 *
 * docs/DATA_MODEL.md says both, D17's prose says "a cap"; both is the stricter
 * reading and the one the table's two columns describe. A cost cap alone lets
 * a loop of cheap calls run all month, and a call cap alone lets one enormous
 * request through.
 *
 * The month window and the comparison live in `ai_quota_status`, not here.
 * That is the same instinct as D31's "the 0.75 line lives only in
 * search_ingredients": a threshold with two homes has two behaviours, and this
 * one is only testable in the place `make test-sql` can reach.
 */
export async function checkQuota(
  service: SupabaseClient,
  householdId: string,
): Promise<void> {
  const { data, error } = await service
    .rpc("ai_quota_status", { household: householdId })
    .maybeSingle();

  if (error) throw error;

  // Fail CLOSED. A quota check that could not run is not a quota check, and
  // the failure mode of guessing "probably fine" is a bill.
  if (!data) {
    throw new HttpError(
      503,
      "quota_unavailable",
      "Could not check this household's AI usage. Try again.",
    );
  }

  const status = data as {
    calls_this_month: number;
    cost_micros_this_month: number;
    monthly_call_cap: number;
    monthly_cost_cap_micros: number;
    within_caps: boolean;
  };

  if (!status.within_caps) {
    // The numbers go in the log, not in the message. The client shows this
    // text to a cook, and "you have used 500 of 500 calls" is a support
    // ticket rather than an explanation.
    console.error(
      `quota exceeded for household ${householdId}: ` +
        `${status.calls_this_month}/${status.monthly_call_cap} calls, ` +
        `${status.cost_micros_this_month}/${status.monthly_cost_cap_micros} micros`,
    );
    throw new HttpError(
      429,
      "quota_exceeded",
      "This household has used its AI allowance for the month.",
    );
  }
}

export interface UsageRecord extends AiUsage {
  readonly householdId: string;
  /** Null for a scheduled pass with no user behind it. */
  readonly userId: string | null;
  readonly functionName: string;
}

/**
 * Writes one ledger row. Never throws into the caller's path.
 *
 * A failed ledger write must not fail an import that already succeeded: the
 * cook would lose a recipe over a bookkeeping problem, and the model call has
 * been billed either way. It is logged loudly instead, because a silent gap in
 * the ledger is how a cap stops working without anyone noticing.
 *
 * Called AFTER the model call, including when the call failed -- a refusal or
 * a malformed reply still spent tokens, and those are exactly the calls worth
 * counting.
 */
export async function recordUsage(
  service: SupabaseClient,
  record: UsageRecord,
): Promise<void> {
  const { error } = await service.from("ai_usage").insert({
    household_id: record.householdId,
    user_id: record.userId,
    function_name: record.functionName,
    model: record.model,
    input_tokens: record.inputTokens,
    output_tokens: record.outputTokens,
    cost_micros: record.costMicros,
  });

  if (error) {
    console.error("failed to record ai_usage", {
      householdId: record.householdId,
      functionName: record.functionName,
      model: record.model,
      costMicros: record.costMicros,
      error,
    });
  }
}
