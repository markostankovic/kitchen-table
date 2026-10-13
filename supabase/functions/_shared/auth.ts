/**
 * Caller identity and household resolution.
 *
 * Every invite function runs TWO clients, and the distinction matters:
 *
 *   * [callerClient] carries the caller's JWT and is used for exactly one
 *     thing -- asking the Auth server who they are.
 *   * [serviceClient] holds the service role key, bypasses RLS entirely, and
 *     does all the reading and writing.
 *
 * Because the service client has no policy behind it, the trust boundary is
 * this file and the two handlers, not the database. Every query it runs must
 * carry its own explicit predicate.
 */

import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { HttpError } from "./http.ts";

export type HouseholdRole = "owner" | "adult";

function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`missing env var ${name}`);
  return value;
}

/** Bypasses RLS. Every query it runs needs its own explicit predicate. */
export function serviceClient(): SupabaseClient {
  return createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false } },
  );
}

/**
 * A client carrying the caller's JWT, so RLS sees the caller.
 *
 * Needed by anything that calls a `security invoker` function on the caller's
 * behalf. `search_ingredients` is the live example (D31): run on the service
 * client it bypasses RLS and returns EVERY household's private aliases, which
 * is a cross-household leak that looks like a working search. Run on this one
 * it returns the caller's, which is what the function was written to do.
 *
 * Throws a 401 if there is no Authorization header at all. It does NOT verify
 * the token -- [requireCaller] does that, and every handler calls it first.
 */
export function callerClient(req: Request): SupabaseClient {
  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    throw new HttpError(401, "unauthenticated", "Please sign in again.");
  }

  return createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_ANON_KEY"),
    {
      auth: { persistSession: false },
      global: { headers: { Authorization: authorization } },
    },
  );
}

/**
 * The calling user's id, or a 401.
 *
 * Goes through `auth.getUser()`, which round-trips to the Auth server and
 * verifies the signature. Deliberately not a local base64 decode of the JWT:
 * an unverified `sub` claim is attacker-controlled, and this value decides
 * which household somebody joins.
 */
export async function requireCaller(req: Request): Promise<string> {
  const caller = callerClient(req);

  const { data, error } = await caller.auth.getUser();
  if (error || !data.user) {
    throw new HttpError(401, "unauthenticated", "Please sign in again.");
  }
  return data.user.id;
}

/**
 * The caller's oldest household, or null if they are in none.
 *
 * Legacy fallback for clients that send no `householdId` (D168): an APK
 * installed before the explicit id keeps working. Only [requireHousehold]
 * calls it. Delete in slice B (`multi-household-b`), once every client sends
 * the id.
 *
 * Ordered by the membership's own created_at, whereas
 * HouseholdRepository.fetchCurrent() orders by the household's. The two agree
 * as long as a user is only ever in one household, which redeem-invite
 * enforces by rejecting a second.
 */
export async function resolveHousehold(
  service: SupabaseClient,
  userId: string,
): Promise<{ householdId: string; role: HouseholdRole } | null> {
  const { data, error } = await service
    .from("household_members")
    .select("household_id, role")
    .eq("user_id", userId)
    .order("created_at", { ascending: true })
    .limit(1)
    .maybeSingle();

  if (error) throw error;
  if (!data) return null;
  return {
    householdId: data.household_id as string,
    role: data.role as HouseholdRole,
  };
}

/** The caller's role in [householdId], or a 403. */
export async function assertMember(
  service: SupabaseClient,
  userId: string,
  householdId: string,
): Promise<HouseholdRole> {
  const { data, error } = await service
    .from("household_members")
    .select("role")
    .eq("user_id", userId)
    .eq("household_id", householdId)
    .maybeSingle();

  if (error) throw error;
  if (!data) {
    throw new HttpError(
      403,
      "not_a_member",
      "You are not a member of that household.",
    );
  }
  return data.role as HouseholdRole;
}

const UUID_SHAPE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * The household a request acts on, and the caller's role in it (D168).
 *
 * The client names it as `householdId` in the body, and [assertMember] checks
 * it: the client may not name a household it does not belong to, and this is
 * what holds it to that. Call it before any quota check, job row or read
 * keyed on the id -- the service client has no RLS behind it (D31).
 *
 * A body with no `householdId` falls back to [resolveHousehold] (legacy, see
 * there). A body WITH one never falls back: a non-member gets the 403.
 */
export async function requireHousehold(
  service: SupabaseClient,
  userId: string,
  body: Record<string, unknown>,
): Promise<{ householdId: string; role: HouseholdRole }> {
  const requested = body.householdId;

  if (requested === undefined) {
    const membership = await resolveHousehold(service, userId);
    if (!membership) {
      throw new HttpError(
        404,
        "no_household",
        "You are not in a household yet.",
      );
    }
    return membership;
  }

  if (typeof requested !== "string" || !UUID_SHAPE.test(requested)) {
    throw new HttpError(
      400,
      "invalid_household",
      "householdId must be a household id.",
    );
  }

  const role = await assertMember(service, userId, requested);
  return { householdId: requested, role };
}
