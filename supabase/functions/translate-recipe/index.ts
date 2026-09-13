/**
 * translate-recipe -- one recipe's title, description and steps, into the
 * other of `sr` / `en` (Phase 3, part 2).
 *
 * An Edge Function because it costs money and holds the model key
 * (docs/ARCHITECTURE.md). Synchronous, on `match-ingredients`' own shape
 * rather than `import-text`'s: there is one model call and no confirm
 * screen in this part, so a job row would be ceremony over `import_jobs`'
 * own import-shaped columns. A recipe id and a target locale in, a saved
 * translation out.
 *
 * Idempotent, and on the recipe's own original_locale it makes no model call
 * at all -- `match-ingredients`' own stated property, here for the same
 * reason.
 *
 * Ingredient lines never travel through this function. They are never
 * translated per recipe (D1) -- they render from the catalog at read time --
 * so the recipe is read here without its `recipe_ingredients` at all.
 */

/// <reference types="npm:@supabase/functions-js@2/src/edge-runtime.d.ts" />

import {
  HttpError,
  jsonResponse,
  readJsonBody,
  withHttp,
} from "../_shared/http.ts";
import { callerClient, requireCaller, serviceClient } from "../_shared/auth.ts";
import { checkQuota, recordUsage } from "../_shared/usage.ts";
import { AiFailure } from "../_shared/ai.ts";
import { translateRecipe } from "../_shared/translate.ts";

const LOCALES = new Set(["sr", "en"]);

Deno.serve(withHttp(async (req: Request): Promise<Response> => {
  const userId = await requireCaller(req);
  const service = serviceClient();
  // The caller's own client, not the service client: RLS is what decides
  // whether this recipe is visible at all, and a household-scoped select
  // through it turns "not a member" and "does not exist" into the same 404
  // for free, the same shape loadJobForCaller gives a foreign import job.
  const caller = callerClient(req);

  const body = await readJsonBody(req);
  const recipeId = typeof body.recipeId === "string" ? body.recipeId : "";
  const targetLocale = typeof body.targetLocale === "string"
    ? body.targetLocale
    : "";
  if (recipeId.length === 0 || !LOCALES.has(targetLocale)) {
    throw new HttpError(
      400,
      "invalid_body",
      "A recipe id and a target locale (sr or en) are required.",
    );
  }

  const { data: recipe, error: recipeError } = await caller
    .from("recipes")
    .select(
      "id, household_id, title, description, original_locale, recipe_steps(position, text)",
    )
    .eq("id", recipeId)
    .is("deleted_at", null)
    .maybeSingle();

  if (recipeError) throw recipeError;
  if (!recipe) {
    throw new HttpError(
      404,
      "recipe_not_found",
      "That recipe is not available.",
    );
  }

  const householdId = recipe.household_id as string;
  const originalLocale = recipe.original_locale as string;

  // Before any model call, on match-ingredients' own precedent: nothing to
  // do here should never cost a token.
  if (targetLocale === originalLocale) {
    throw new HttpError(
      400,
      "same_locale",
      "This recipe is already written in that language.",
    );
  }

  await checkQuota(service, householdId);

  const steps = (recipe.recipe_steps as { position: number; text: string }[])
    .toSorted((a, b) => a.position - b.position);

  let translation;
  try {
    translation = await translateRecipe(
      {
        title: recipe.title as string,
        description: (recipe.description as string | null) ?? null,
        steps,
      },
      targetLocale as "sr" | "en",
    );
  } catch (e) {
    // A refusal or a malformed reply still spent tokens -- match-ingredients'
    // own reasoning for recording a failed call rather than losing it.
    if (e instanceof AiFailure) {
      await recordUsage(service, {
        ...e.usage,
        householdId,
        userId,
        functionName: "translate-recipe",
      });
    }
    throw e;
  }

  await recordUsage(service, {
    ...translation.usage,
    householdId,
    userId,
    functionName: "translate-recipe",
  });

  // The caller's own client: save_recipe_translation is security invoker, and
  // RLS is what should decide whether this write is allowed, not this
  // function.
  const { error: saveError } = await caller.rpc("save_recipe_translation", {
    recipe: recipeId,
    loc: targetLocale,
    new_title: translation.value.title,
    new_description: translation.value.description,
    new_steps: translation.value.steps,
  });
  if (saveError) throw saveError;

  return jsonResponse({ recipeId, locale: targetLocale });
}));
