/**
 * The Type flow (docs/ARCHITECTURE.md), end to end:
 *
 *   supabase/functions/_shared/schema.ts   (Zod, source of truth)
 *           | z.toJSONSchema
 *   build/schema.json
 *           | quicktype --lang dart --use-freezed
 *   lib/features/import/domain/parsed_recipe.dart
 *
 * Run through `make types`, never by hand. Never hand-edit the output: if the
 * AI parse contract changes, it changes in schema.ts and nowhere else (D18).
 *
 * ARCHITECTURE.md names `zod-to-json-schema` for the first step. That package
 * existed because Zod 3 could not emit JSON Schema itself; Zod 4 can, so the
 * dependency is not added. Same transformation, one fewer thing to keep on a
 * version (CLAUDE.md rule 8 cuts both ways).
 *
 * Only ParsedRecipe is emitted. ModelRecipe is a server-side prompt contract
 * that no client ever receives -- generating Dart for it would put a type in
 * `domain/` that nothing can construct.
 */

import { z } from "zod";
import { ParsedRecipe } from "../supabase/functions/_shared/schema.ts";

const root = new URL("../", import.meta.url);
const schemaPath = new URL("build/schema.json", root);
const outPath = new URL(
  "lib/features/import/domain/parsed_recipe.dart",
  root,
);

// ---------------------------------------------------------------------------
// 1. Zod -> JSON Schema
// ---------------------------------------------------------------------------
// `io: "output"` matters: ParsedIngredientLine has `.default(false)` fields, and
// on the INPUT side those are optional while on the OUTPUT side they are always
// present. The Dart model reads a value the pipeline has already produced, so
// output is the correct side and `isOptional` / `autoAccept` come out
// non-nullable.
const schema = z.toJSONSchema(ParsedRecipe, {
  io: "output",
  target: "draft-7",
});

await Deno.mkdir(new URL("build/", root), { recursive: true });
await Deno.writeTextFile(
  schemaPath,
  `${JSON.stringify(schema, null, 2)}\n`,
);

// ---------------------------------------------------------------------------
// 2. JSON Schema -> Dart
// ---------------------------------------------------------------------------
// Class names come from the `title` on each Zod schema, not from property
// names. Without those titles quicktype derives `Quantity`, `MatchMethod` and
// `Step` from `quantity` / `matchMethod` / `steps`, and the first two collide
// with the real domain types in features/ingredients/domain/. A confirm screen
// importing both would not compile.
const raw = await new Deno.Command("quicktype", {
  args: [
    "--lang", "dart",
    "--src-lang", "schema",
    "--use-freezed",
    "--use-json-annotation",
    "--top-level", "ParsedRecipe",
    "--part-name", "parsed_recipe",
    "--src", schemaPath.pathname,
  ],
  stdout: "piped",
  stderr: "inherit",
}).output();

if (!raw.success) {
  console.error("quicktype failed");
  Deno.exit(1);
}

let dart = new TextDecoder().decode(raw.stdout);

// ---------------------------------------------------------------------------
// 3. Two repairs, each asserted before it is applied
// ---------------------------------------------------------------------------
// Both are quicktype defects rather than anything schema.ts can express, and
// both are applied by exact match so that a future quicktype that stops
// emitting them fails this script loudly instead of silently doing nothing.

// (a) `json.decode` returns dynamic, and analysis_options.yaml sets
//     strict-casts. Without the cast this is an ERROR, not a lint, and
//     `dart analyze` must be clean before any commit.
const undecoded =
  "ParsedRecipe parsedRecipeFromJson(String str) => ParsedRecipe.fromJson(json.decode(str));";
const decoded =
  "ParsedRecipe parsedRecipeFromJson(String str) =>\n    ParsedRecipe.fromJson(json.decode(str) as Map<String, dynamic>);";
if (!dart.includes(undecoded)) {
  console.error(
    "expected quicktype's undecoded fromJson helper; it changed shape.\n" +
      "Check the generated file and update tool/gen_types.ts.",
  );
  Deno.exit(1);
}
dart = dart.replace(undecoded, decoded);

// (b) quicktype writes enum values in SCREAMING_CASE. Renaming them here would
//     mean the JsonValue mapping and the Dart identifier drift apart on the
//     next regeneration, so the lint is suppressed for this file instead --
//     which is what the file being generated actually means.
const header = `// GENERATED CODE -- DO NOT EDIT BY HAND.
//
// Source of truth: supabase/functions/_shared/schema.ts (Zod).
// Regenerate with \`make types\`. Hand-edits are lost on the next run, and a
// hand-mirrored parse contract drifts silently -- rename a field on the server
// and this file quietly reads null (D18).
//
// ignore_for_file: constant_identifier_names

`;

await Deno.writeTextFile(outPath, header + dart);

console.log(`wrote ${outPath.pathname}`);
