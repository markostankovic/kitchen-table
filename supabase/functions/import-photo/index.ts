/// <reference types="npm:@supabase/functions-js@2/src/edge-runtime.d.ts" />
/**
 * import-photo -- read a recipe off a photograph of a cookbook page.
 *
 * D15: the page goes STRAIGHT to a vision model, not OCR-then-parse. The hard
 * part of a printed page is layout -- two columns, sidebar ingredient lists,
 * headnotes mixed with method -- and OCR throws layout away before anything
 * can use it. The layout rules the model needs live in RECIPE_SYSTEM_PROMPT
 * beside the rules the other two importers use, because it is one job with a
 * different attachment.
 *
 * The image is already in Storage when this is called: the client uploads it
 * to `import-uploads/{household_id}/{uuid}.jpg` and sends the path. Keeping it
 * there rather than posting bytes is what lets a failed job be re-run against
 * the same photograph instead of asking somebody to find the book again.
 */

import {
  HttpError,
  jsonResponse,
  readJsonBody,
  withHttp,
} from "../_shared/http.ts";
import {
  callerClient,
  requireCaller,
  resolveHousehold,
  serviceClient,
} from "../_shared/auth.ts";
import { AiFailure, type ContentBlock, MODELS } from "../_shared/ai.ts";
import { checkQuota, recordUsage } from "../_shared/usage.ts";
import {
  createJob,
  markFailed,
  markNeedsReview,
  markProcessing,
} from "../_shared/jobs.ts";
import { enrich, readRecipeFromContent } from "../_shared/read_recipe.ts";

const BUCKET = "import-uploads";

/**
 * The vision model's own ceiling is 5 MB per image after base64. The client
 * downscales to 1600px before uploading and the bucket refuses more than
 * 10 MB, so this is the third of three and exists to give a clear reason when
 * the other two are somehow got past.
 */
const MAX_IMAGE_BYTES = 4 * 1024 * 1024;

/** What the vision endpoint accepts. Anything else is refused before it is paid for. */
const ALLOWED_MEDIA = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
] as const;

type AllowedMedia = typeof ALLOWED_MEDIA[number];

Deno.serve(withHttp(async (req: Request): Promise<Response> => {
  const userId = await requireCaller(req);
  const service = serviceClient();
  // Captured while the request still exists; the background task outlives it,
  // and search_ingredients needs the caller's RLS (D31).
  const caller = callerClient(req);

  const membership = await resolveHousehold(service, userId);
  if (!membership) {
    throw new HttpError(404, "no_household", "You are not in a household yet.");
  }

  const body = await readJsonBody(req);
  const path = typeof body.storagePath === "string"
    ? body.storagePath.trim()
    : "";

  if (path.length === 0) {
    throw new HttpError(400, "empty_input", "There is no photo to import.");
  }

  // The household is re-derived from the path and compared to the caller's own
  // membership. The storage policy already stops a cross-household UPLOAD;
  // this stops a caller naming somebody else's EXISTING object in a job they
  // create -- the same argument create-invite makes about not letting a client
  // name a household.
  const prefix = path.split("/")[0];
  if (prefix !== membership.householdId) {
    throw new HttpError(
      400,
      "invalid_storage_path",
      "That photo does not belong to this household.",
    );
  }

  await checkQuota(service, membership.householdId);

  const jobId = await createJob(service, {
    householdId: membership.householdId,
    userId,
    kind: "photo",
    inputStoragePath: path,
  });

  EdgeRuntime.waitUntil(
    process({
      service,
      caller,
      jobId,
      householdId: membership.householdId,
      userId,
      path,
    }),
  );

  return jsonResponse({ jobId, status: "queued" }, 202);
}));

interface Job {
  service: ReturnType<typeof serviceClient>;
  caller: ReturnType<typeof callerClient>;
  jobId: string;
  householdId: string;
  userId: string;
  path: string;
}

/**
 * The half that runs after the response.
 *
 * Nothing in here may throw: there is no request left to turn an exception
 * into a status code, and an unhandled rejection would leave the job stuck in
 * `processing` with nothing to say why.
 */
async function process(job: Job): Promise<void> {
  const { service, caller, jobId, householdId, userId } = job;

  try {
    await markProcessing(service, jobId);

    const { data, error } = await service.storage
      .from(BUCKET)
      .download(job.path);

    if (error || !data) {
      // Includes the case where the client sent a path it never uploaded to.
      // The synchronous check above proved the caller may WRITE there; it
      // could not prove anything is actually there.
      console.error(`import-photo ${jobId}: cannot read ${job.path}`, error);
      throw new HttpError(
        404,
        "image_not_found",
        "That photo could not be read.",
      );
    }

    const bytes = new Uint8Array(await data.arrayBuffer());
    if (bytes.byteLength > MAX_IMAGE_BYTES) {
      throw new HttpError(400, "image_too_large", "That photo is too large.");
    }

    const mediaType = mediaTypeOf(data.type, job.path);

    const content: ContentBlock[] = [
      {
        type: "image",
        source: {
          type: "base64",
          media_type: mediaType,
          data: base64(bytes),
        },
      },
      {
        // The image alone is the whole input, but a model answers a question
        // better than it answers a silence -- and this is where the fact that
        // it is a PHOTOGRAPH of a page, rather than a screenshot of text, is
        // stated.
        type: "text",
        text:
          "This is a photograph of a page from a cookbook. Read the recipe on it.",
      },
    ];

    const parse = await readRecipeFromContent(content, MODELS.VISION);

    await recordUsage(service, {
      ...parse.usage,
      householdId,
      userId,
      functionName: "import-photo",
    });

    if (parse.value.ingredients.length === 0) {
      throw new HttpError(
        400,
        "no_recipe_found",
        "There is no recipe on that photo.",
      );
    }

    // No sourceUrl: a photograph has none. Attribution, if the page names a
    // book or an author, comes from the model reading it -- which is what the
    // standing rule about storing source_attribution for every import needs.
    const { result, usage } = await enrich(caller, parse.value, null);

    if (usage) {
      await recordUsage(service, {
        ...usage,
        householdId,
        userId,
        functionName: "match-ingredients",
      });
    }

    await markNeedsReview(service, jobId, result);
  } catch (e) {
    if (e instanceof AiFailure) {
      await recordUsage(service, {
        ...e.usage,
        householdId,
        userId,
        functionName: "import-photo",
      });
    }
    // The object is deliberately LEFT in the bucket. A failed job can then be
    // re-run against the same photograph, which is the reason for putting it
    // in Storage rather than posting the bytes.
    await markFailed(service, jobId, e);
  }
}

/**
 * The media type to declare to the model.
 *
 * Storage's own `type` is whatever the client claimed on upload, so it is
 * checked rather than trusted, and the extension is the fallback for an object
 * uploaded without one. HEIC is not in the model's list even though the bucket
 * accepts it -- an iPhone can produce one, and it is better to say so than to
 * send it and get an opaque 400.
 */
function mediaTypeOf(reported: string | undefined, path: string): AllowedMedia {
  const claimed = (reported ?? "").split(";")[0].trim().toLowerCase();
  if ((ALLOWED_MEDIA as readonly string[]).includes(claimed)) {
    return claimed as AllowedMedia;
  }

  const ext = path.slice(path.lastIndexOf(".") + 1).toLowerCase();
  if (ext === "jpg" || ext === "jpeg") return "image/jpeg";
  if (ext === "png") return "image/png";
  if (ext === "webp") return "image/webp";
  if (ext === "gif") return "image/gif";

  throw new HttpError(
    400,
    "not_an_image",
    "That file is not a photo the reader can open.",
  );
}

/**
 * Base64 without blowing the stack.
 *
 * `String.fromCharCode(...bytes)` is the one-liner every example uses and it
 * throws on a few megabytes -- the spread becomes a few million arguments.
 * Chunking is the fix, and 8 KB is comfortably under any argument limit.
 */
function base64(bytes: Uint8Array): string {
  const CHUNK = 8192;
  let binary = "";
  for (let i = 0; i < bytes.length; i += CHUNK) {
    binary += String.fromCharCode(...bytes.subarray(i, i + CHUNK));
  }
  return btoa(binary);
}
