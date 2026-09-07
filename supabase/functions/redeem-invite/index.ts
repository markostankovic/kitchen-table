/**
 * redeem-invite -- join the household behind a six-digit code.
 *
 * An Edge Function because it writes household_members, which no client may.
 *
 * KNOWN LIMITATION. Claiming the invite and inserting the membership are two
 * PostgREST calls, not one transaction. If the insert fails, the claim is
 * rolled back by hand (see `compensate` below), but an isolate killed between
 * the two leaves the code burned and the user not a member; recovery is to ask
 * for a new code. That is acceptable at family scale. If it ever isn't, the
 * fix is a direct postgres connection and a real transaction -- not a
 * SECURITY DEFINER RPC, which would split the trust boundary in two.
 */

import {
  HttpError,
  jsonResponse,
  readJsonBody,
  withHttp,
} from "../_shared/http.ts";
import { requireCaller, serviceClient } from "../_shared/auth.ts";
import { parseInviteCode } from "../_shared/invite_code.ts";

Deno.serve(withHttp(async (req: Request): Promise<Response> => {
  const body = await readJsonBody(req);
  const code = parseInviteCode(body.code);
  const userId = await requireCaller(req);
  const service = serviceClient();

  const nowIso = new Date().toISOString();

  // What the caller is already a member of. Drives both the idempotent-retry
  // case and the single-household rule below.
  const { data: memberships, error: membershipError } = await service
    .from("household_members")
    .select("household_id")
    .eq("user_id", userId);
  if (membershipError) throw membershipError;

  const memberOf = new Set(
    (memberships ?? []).map((m) => m.household_id as string),
  );

  /** The newest row for this code, live or spent, to explain a failed claim. */
  const probe = async () => {
    const { data, error } = await service
      .from("household_invites")
      .select("id, household_id, expires_at, used_at, used_by")
      .eq("code", code)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (error) throw error;
    return data;
  };

  const householdName = async (householdId: string) => {
    const { data, error } = await service
      .from("households")
      .select("name")
      .eq("id", householdId)
      .maybeSingle();
    if (error) throw error;
    return (data?.name as string | undefined) ?? "";
  };

  // Peek before claiming, so that "you are already in this household" does not
  // burn a code that somebody else still needs -- the "Mum taps it twice" case.
  const { data: live, error: liveError } = await service
    .from("household_invites")
    .select("id, household_id, expires_at")
    .eq("code", code)
    .is("used_at", null)
    .maybeSingle();
  if (liveError) throw liveError;

  if (live) {
    const householdId = live.household_id as string;

    if (memberOf.has(householdId)) {
      return jsonResponse({
        householdId,
        householdName: await householdName(householdId),
        alreadyMember: true,
      });
    }

    // The app has no notion of an active household -- fetchCurrent() returns
    // the first membership -- so a second one would silently decide which
    // household you see by creation order. Reject rather than half-support it.
    if (memberOf.size > 0) {
      throw new HttpError(
        409,
        "already_in_household",
        "This account is already in a household. Sign in with a different "
          + "account to join this one.",
      );
    }
  }

  // The claim. A conditional UPDATE, not SELECT-then-UPDATE: under read
  // committed the loser blocks on the row lock, re-evaluates its WHERE after
  // the winner commits, and updates zero rows. SELECT-then-UPDATE would let
  // one invite grant two memberships.
  const { data: claimed, error: claimError } = await service
    .from("household_invites")
    .update({ used_by: userId, used_at: nowIso })
    .eq("code", code)
    .is("used_at", null)
    .gt("expires_at", nowIso)
    .select("id, household_id")
    // Safe: the partial unique index guarantees at most one live row per code.
    .maybeSingle();
  if (claimError) throw claimError;

  if (!claimed) {
    const found = await probe();

    if (!found) {
      throw new HttpError(404, "invite_not_found", "That code is not valid.");
    }

    if (found.used_at !== null) {
      // Our own earlier redemption: the response was lost, not the write.
      if (
        found.used_by === userId &&
        memberOf.has(found.household_id as string)
      ) {
        return jsonResponse({
          householdId: found.household_id,
          householdName: await householdName(found.household_id as string),
          alreadyMember: true,
        });
      }
      throw new HttpError(
        409,
        "invite_already_used",
        "That code has already been used.",
      );
    }

    // Unused, so it was the expiry guard that rejected it.
    throw new HttpError(
      410,
      "invite_expired",
      "That code has expired. Ask for a new one.",
    );
  }

  const householdId = claimed.household_id as string;

  const { error: insertError } = await service
    .from("household_members")
    // 'owner' is reserved for create_household()'s creator.
    .insert({ household_id: householdId, user_id: userId, role: "adult" });

  if (insertError) {
    // They joined by some other path between the peek and here. The invite is
    // spent, but the outcome the caller wanted is true, so report success.
    if (insertError.code === "23505") {
      return jsonResponse({
        householdId,
        householdName: await householdName(householdId),
        alreadyMember: true,
      });
    }

    // Give the code back. The `used_by` predicate means a concurrent re-claim
    // that already won is left alone.
    const { error: compensateError } = await service
      .from("household_invites")
      .update({ used_by: null, used_at: null })
      .eq("id", claimed.id)
      .eq("used_by", userId);
    if (compensateError) {
      console.error("failed to release invite after a failed join", {
        invite: claimed.id,
        compensateError,
      });
    }
    throw insertError;
  }

  return jsonResponse({
    householdId,
    householdName: await householdName(householdId),
    alreadyMember: false,
  });
}));
