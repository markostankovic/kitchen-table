/**
 * translate-tags -- mints the sr/en spelling pair for every tag in the
 * caller's household that does not have one yet (Phase 6, part 1b).
 *
 * An Edge Function for the same reason as `translate-recipe`: it costs money
 * and holds the model key (CLAUDE.md rule 2). Takes no request body, on
 * `create-invite`'s own shape -- the household is resolved server-side from
 * the caller's membership, never named by the client (D107's read path
 * already resolves `(tag_key, locale)` the same way, with no household
 * argument either).
 *
 * Idempotent, and on a household whose vocabulary is already fully paired it
 * makes no model call at all -- `match-ingredients`' and `translate-recipe`'s
 * own stated property, here for the same reason.
 *
 * Fired best-effort and unawaited from `RecipeEditor.save()` (D109); nothing
 * about this function itself assumes that caller, but its answer -- a
 * `written` count and nothing else the client needs -- is shaped for it.
 */

/// <reference types="npm:@supabase/functions-js@2/src/edge-runtime.d.ts" />

import { HttpError, jsonResponse, withHttp } from "../_shared/http.ts";
import {
  callerClient,
  requireCaller,
  resolveHousehold,
  serviceClient,
} from "../_shared/auth.ts";
import { checkQuota, recordUsage } from "../_shared/usage.ts";
import { AiFailure } from "../_shared/ai.ts";
import { normalizeText } from "../_shared/normalize.ts";
import {
  type TagToTranslate,
  type TagTranslation,
  translateTags,
} from "../_shared/translate_tags.ts";

const LOCALES = ["sr", "en"] as const;

interface ExistingRow {
  readonly id: string;
  readonly deletedAt: string | null;
}

Deno.serve(withHttp(async (req: Request): Promise<Response> => {
  const userId = await requireCaller(req);
  const service = serviceClient();
  // The caller's own client for every read and write below: RLS is what
  // should decide, not this function, on `translate-recipe`'s own stated
  // reason.
  const caller = callerClient(req);

  const membership = await resolveHousehold(service, userId);
  if (!membership) {
    throw new HttpError(
      404,
      "no_household",
      "You are not in a household yet.",
    );
  }
  const householdId = membership.householdId;

  // The household's tag vocabulary, derived from its own recipes -- the same
  // grouping `RecipeTag.vocabularyOf` does in Dart: normalize each tag into
  // a key, drop the empty ones, and keep the alphabetically-first original
  // spelling per key as the label shown to the model.
  const { data: recipeRows, error: recipesError } = await caller
    .from("recipes")
    .select("tags")
    .eq("household_id", householdId)
    .is("deleted_at", null);
  if (recipesError) throw recipesError;

  const spellingsByKey = new Map<string, string[]>();
  for (const row of recipeRows ?? []) {
    for (const tag of (row.tags as string[] | null) ?? []) {
      const key = normalizeText(tag);
      if (key.length === 0) continue;
      const spellings = spellingsByKey.get(key);
      if (spellings) {
        spellings.push(tag);
      } else {
        spellingsByKey.set(key, [tag]);
      }
    }
  }
  const vocabulary = new Map<string, string>();
  for (const [key, spellings] of spellingsByKey) {
    vocabulary.set(key, [...spellings].sort()[0]);
  }

  // Every existing pair for this household, deliberately NOT filtered by
  // deleted_at -- recipe_tag_names_unique (migration 21) is a total index,
  // so a soft-deleted row still occupies its slot and has to be revived by
  // id rather than re-inserted into.
  const { data: existingRows, error: namesError } = await caller
    .from("recipe_tag_names")
    .select("id, tag_key, locale, deleted_at")
    .eq("household_id", householdId);
  if (namesError) throw namesError;

  const existing = new Map<string, ExistingRow>();
  for (const row of existingRows ?? []) {
    existing.set(`${row.tag_key}|${row.locale}`, {
      id: row.id as string,
      deletedAt: row.deleted_at as string | null,
    });
  }

  // A key "needs" work when either locale has no row at all or only a
  // soft-deleted one. An alive row -- curated, user or an earlier llm pair
  // -- is never overwritten, so a key with both locales already alive costs
  // nothing further.
  const work: TagToTranslate[] = [];
  let alreadyPaired = 0;
  for (const [key, label] of vocabulary) {
    const needsAny = LOCALES.some((locale) => {
      const row = existing.get(`${key}|${locale}`);
      return !row || row.deletedAt !== null;
    });
    if (needsAny) {
      work.push({ key, label });
    } else {
      alreadyPaired++;
    }
  }

  // Nothing to do must never cost a token -- match-ingredients' and
  // translate-recipe's own stated property, checked before checkQuota and
  // before any model call.
  if (work.length === 0) {
    return jsonResponse({ householdId, written: 0, skipped: alreadyPaired });
  }

  await checkQuota(service, householdId);

  let translations: TagTranslation[];
  try {
    const result = await translateTags(work);
    translations = result.value;
    await recordUsage(service, {
      ...result.usage,
      householdId,
      userId,
      functionName: "translate-tags",
    });
  } catch (e) {
    // A refusal or a mismatched reply still spent tokens -- translate-recipe's
    // own reasoning for recording a failed call rather than losing it.
    if (e instanceof AiFailure) {
      await recordUsage(service, {
        ...e.usage,
        householdId,
        userId,
        functionName: "translate-tags",
      });
    }
    throw e;
  }

  // The caller's own client again: RLS decides whether each write is
  // allowed, not this function. Plain inserts for a missing slot, update-by-
  // id for a soft-deleted one -- never a PostgREST upsert, because
  // recipe_tag_names_unique is an expression index (coalesce(household_id,
  // '000...')) that `onConflict: 'tag_key,locale,household_id'` cannot
  // match.
  let written = 0;
  for (const translation of translations) {
    for (const locale of LOCALES) {
      const name = locale === "sr" ? translation.sr : translation.en;
      const row = existing.get(`${translation.key}|${locale}`);

      if (!row) {
        const { error } = await caller.from("recipe_tag_names").insert({
          tag_key: translation.key,
          name,
          locale,
          household_id: householdId,
          source: "llm",
        });
        if (error) throw error;
        written++;
      } else if (row.deletedAt !== null) {
        const { error } = await caller
          .from("recipe_tag_names")
          .update({ name, source: "llm", deleted_at: null })
          .eq("id", row.id);
        if (error) throw error;
        written++;
      }
      // else: an alive row already exists for this slot and is never
      // overwritten (this slice's own decision).
    }
  }

  return jsonResponse({ householdId, written, skipped: alreadyPaired });
}));
