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
 * The calling user's id, or a 401.
 *
 * Goes through `auth.getUser()`, which round-trips to the Auth server and
 * verifies the signature. Deliberately not a local base64 decode of the JWT:
 * an unverified `sub` claim is attacker-controlled, and this value decides
 * which household somebody joins.
 */
export async function requireCaller(req: Request): Promise<string> {
  const authorization = req.headers.get("Authorization");
  if (!authorization) {
    throw new HttpError(401, "unauthenticated", "Please sign in again.");
  }

  const caller = createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_ANON_KEY"),
    {
      auth: { persistSession: false },
      global: { headers: { Authorization: authorization } },
    },
  );

  const { data, error } = await caller.auth.getUser();
  if (error || !data.user) {
    throw new HttpError(401, "unauthenticated", "Please sign in again.");
  }
  return data.user.id;
}

/**
 * The caller's household, or null if they are in none.
 *
 * Ordered by the membership's own created_at, whereas
 * HouseholdRepository.fetchCurrent() orders by the household's. The two agree
 * as long as a user is only ever in one household, which redeem-invite
 * enforces by rejecting a second. Revisit both together if that ever changes.
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
