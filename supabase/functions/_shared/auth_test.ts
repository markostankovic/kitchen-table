/**
 * `requireHousehold` and `readOptionalJsonBody` (D168): which household a
 * request acts on, and the body it is read from.
 *
 * The service client is a minimal fake over `household_members` that covers
 * the one chain these helpers use: `.from().select().eq()…[.order().limit()]
 * .maybeSingle()`. Nothing here touches the network.
 *
 * Run: make test-functions
 */

import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import type { SupabaseClient } from "@supabase/supabase-js";
import { requireHousehold } from "./auth.ts";
import { HttpError, readOptionalJsonBody } from "./http.ts";

interface MemberRow {
  user_id: string;
  household_id: string;
  role: "owner" | "adult";
  created_at: string;
}

function fakeService(rows: MemberRow[]): SupabaseClient {
  const query = (filtered: MemberRow[]) => ({
    select: () => query(filtered),
    eq: (column: keyof MemberRow, value: string) =>
      query(filtered.filter((row) => row[column] === value)),
    order: (column: keyof MemberRow) =>
      query(
        [...filtered].sort((a, b) => a[column].localeCompare(b[column])),
      ),
    limit: (n: number) => query(filtered.slice(0, n)),
    maybeSingle: () =>
      Promise.resolve({ data: filtered[0] ?? null, error: null }),
  });
  return { from: () => query(rows) } as unknown as SupabaseClient;
}

const USER = "user-1";
const HOME = "11111111-1111-4111-8111-111111111111";
const WEEKEND = "22222222-2222-4222-8222-222222222222";
const STRANGERS = "33333333-3333-4333-8333-333333333333";

const service = fakeService([
  {
    user_id: USER,
    household_id: WEEKEND,
    role: "adult",
    created_at: "2026-10-02T00:00:00Z",
  },
  {
    user_id: USER,
    household_id: HOME,
    role: "owner",
    created_at: "2026-10-01T00:00:00Z",
  },
  {
    user_id: "user-2",
    household_id: STRANGERS,
    role: "owner",
    created_at: "2026-09-01T00:00:00Z",
  },
]);

async function rejectsWith(
  promise: Promise<unknown>,
  status: number,
  code: string,
): Promise<void> {
  const error = await assertRejects(() => promise, HttpError);
  assertEquals([error.status, error.code], [status, code]);
}

Deno.test("requireHousehold: a member gets the household they named", async () => {
  assertEquals(
    await requireHousehold(service, USER, { householdId: WEEKEND }),
    { householdId: WEEKEND, role: "adult" },
  );
});

Deno.test("requireHousehold: a non-member is a 403, never a fallback", async () => {
  await rejectsWith(
    requireHousehold(service, USER, { householdId: STRANGERS }),
    403,
    "not_a_member",
  );
});

Deno.test("requireHousehold: a malformed id is a 400", async () => {
  for (const householdId of ["", "not-a-uuid", 42, null]) {
    await rejectsWith(
      requireHousehold(service, USER, { householdId }),
      400,
      "invalid_household",
    );
  }
});

Deno.test("requireHousehold: no id falls back to the oldest membership", async () => {
  assertEquals(
    await requireHousehold(service, USER, {}),
    { householdId: HOME, role: "owner" },
  );
});

Deno.test("requireHousehold: no id and no membership is a 404", async () => {
  await rejectsWith(
    requireHousehold(service, "nobody", {}),
    404,
    "no_household",
  );
});

function post(body?: string): Request {
  return new Request("http://localhost/fn", { method: "POST", body });
}

Deno.test("readOptionalJsonBody: no body reads as {}", async () => {
  assertEquals(await readOptionalJsonBody(post()), {});
  assertEquals(await readOptionalJsonBody(post("  ")), {});
});

Deno.test("readOptionalJsonBody: an object comes back as sent", async () => {
  assertEquals(
    await readOptionalJsonBody(post(JSON.stringify({ householdId: HOME }))),
    { householdId: HOME },
  );
});

Deno.test("readOptionalJsonBody: an array or bad JSON is a 400", async () => {
  await rejectsWith(readOptionalJsonBody(post("[]")), 400, "invalid_body");
  await rejectsWith(readOptionalJsonBody(post("{")), 400, "invalid_body");
});
