/**
 * create-invite -- mint a six-digit code for the caller's household.
 *
 * An Edge Function rather than an RPC because it writes household_invites,
 * which no client may (docs/ARCHITECTURE.md: "anything granting access to
 * household data is not client logic").
 *
 * Takes no request body. The household is resolved server-side from the
 * caller's membership -- the client has no business naming a household it
 * might not belong to.
 */

import { HttpError, jsonResponse, withHttp } from "../_shared/http.ts";
import {
  requireCaller,
  resolveHousehold,
  serviceClient,
} from "../_shared/auth.ts";
import { randomInviteCode } from "../_shared/invite_code.ts";

const EXPIRY_DAYS = 7;
const MAX_ATTEMPTS = 5;

Deno.serve(withHttp(async (req: Request): Promise<Response> => {
  const userId = await requireCaller(req);
  const service = serviceClient();

  const membership = await resolveHousehold(service, userId);
  if (!membership) {
    throw new HttpError(
      404,
      "no_household",
      "You are not in a household yet.",
    );
  }

  // No role check. `owner` and `adult` are both trusted adults -- there is no
  // restricted role in the check constraint to protect against. This is
  // deliberate, not an oversight.

  const expiresAt = new Date(
    Date.now() + EXPIRY_DAYS * 24 * 60 * 60 * 1000,
  ).toISOString();

  // Insert and retry on conflict rather than pre-checking the code: a
  // pre-check is TOCTOU (two concurrent creates both pass it) and you need
  // the conflict handler regardless, so the extra round trip buys only a
  // false sense of safety.
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    const { data, error } = await service
      .from("household_invites")
      .insert({
        household_id: membership.householdId,
        code: randomInviteCode(),
        created_by: userId,
        expires_at: expiresAt,
      })
      .select("id, household_id, code, created_by, created_at, expires_at")
      .single();

    if (!error) {
      // token is deliberately not returned. Nothing reads it until the Phase 4
      // web layer, and an unused link secret in a response body is how it leaks.
      return jsonResponse({
        id: data.id,
        householdId: data.household_id,
        code: data.code,
        createdBy: data.created_by,
        createdAt: data.created_at,
        expiresAt: data.expires_at,
      });
    }

    // 23505: the partial unique index caught a collision with a live code.
    if (error.code !== "23505") throw error;
  }

  throw new HttpError(
    503,
    "code_generation_failed",
    "Could not generate a code. Try again.",
  );
}));
