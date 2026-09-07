/**
 * Invite code generation and validation.
 *
 * Separate from the handlers because these two functions are the only pure,
 * testable logic in either one -- everything else is glue whose risky part
 * (the SQL) is covered by supabase/tests/rls_invites_test.sql. When deno
 * arrives for `make types` in Phase 1d, `deno test` starts here.
 */

import { HttpError } from "./http.ts";

const CODE_SPACE = 1_000_000;

/**
 * A uniformly random six-digit code, zero-padded.
 *
 * crypto.getRandomValues rather than Math.random(): a code that grants access
 * to household data should not be inferable from a previously issued one, and
 * Math.random() is seeded per-isolate.
 */
export function randomInviteCode(): string {
  // 2^32 is not a multiple of 1e6, so a bare `% 1e6` would favour the low
  // codes. Reject the incomplete final bucket instead.
  const limit = Math.floor(0x1_0000_0000 / CODE_SPACE) * CODE_SPACE;
  const buf = new Uint32Array(1);
  let n: number;
  do {
    crypto.getRandomValues(buf);
    n = buf[0];
  } while (n >= limit);
  return String(n % CODE_SPACE).padStart(6, "0");
}

/** Throws a 400 unless [raw] is exactly six digits. */
export function parseInviteCode(raw: unknown): string {
  const trimmed = typeof raw === "string" ? raw.trim() : "";
  if (!/^\d{6}$/.test(trimmed)) {
    throw new HttpError(400, "invalid_code", "Enter the six-digit code.");
  }
  return trimmed;
}
