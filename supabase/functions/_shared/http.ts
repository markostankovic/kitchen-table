/**
 * HTTP plumbing shared by every Edge Function.
 *
 * The error body shape defined here -- `{error, message}` -- is the entire
 * contract with the Dart side. `runGuarded` in
 * `lib/core/supabase/supabase_failure.dart` switches on the `error` code to
 * pick an AppFailure. Change the shape here, change it there.
 */

export const corsHeaders: Record<string, string> = {
  // These functions authenticate on the Authorization header and never on a
  // cookie, so there are no credentials to protect with an origin pin.
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

/** An error with a machine-readable code the client can branch on. */
export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
  ) {
    super(message);
    this.name = "HttpError";
  }
}

export function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/**
 * Wraps a handler with the parts every function repeats: the preflight, the
 * method guard, and turning a thrown [HttpError] into its response.
 *
 * Anything else that escapes is a bug, so it is logged in full and answered
 * with a generic 500 -- an internal message must not reach the client.
 */
export function withHttp(
  handler: (req: Request) => Promise<Response>,
): (req: Request) => Promise<Response> {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }

    try {
      if (req.method !== "POST") {
        throw new HttpError(405, "method_not_allowed", "Use POST.");
      }
      return await handler(req);
    } catch (e) {
      if (e instanceof HttpError) {
        return jsonResponse({ error: e.code, message: e.message }, e.status);
      }
      console.error("unhandled error", e);
      return jsonResponse(
        { error: "internal_error", message: "Something went wrong." },
        500,
      );
    }
  };
}

/** The request body as an object. Absent or malformed JSON is a 400. */
export async function readJsonBody(
  req: Request,
): Promise<Record<string, unknown>> {
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
    throw new HttpError(400, "invalid_body", "Expected a JSON body.");
  }
  if (typeof raw !== "object" || raw === null || Array.isArray(raw)) {
    throw new HttpError(400, "invalid_body", "Expected a JSON object.");
  }
  return raw as Record<string, unknown>;
}

/**
 * The request body as an object, where sending no body at all is allowed and
 * reads as `{}`. For functions that took no body before `householdId` (D168):
 * an older client that still sends none gets [requireHousehold]'s 400
 * `invalid_household`, not a 400 `invalid_body`. A body that IS sent gets
 * [readJsonBody]'s checks.
 */
export async function readOptionalJsonBody(
  req: Request,
): Promise<Record<string, unknown>> {
  const text = await req.text();
  if (text.trim().length === 0) return {};
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    throw new HttpError(400, "invalid_body", "Expected a JSON body.");
  }
  if (typeof raw !== "object" || raw === null || Array.isArray(raw)) {
    throw new HttpError(400, "invalid_body", "Expected a JSON object.");
  }
  return raw as Record<string, unknown>;
}
