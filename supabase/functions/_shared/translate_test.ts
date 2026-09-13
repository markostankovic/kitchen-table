/**
 * `alignSteps` and the prompt's own Latin-script rule (Phase 3, part 2).
 *
 * `--allow-read` only (see `make test-functions`), so nothing here touches
 * the network -- `translateRecipe` itself is not exercised, only the part of
 * it that can be tested without a model call.
 *
 * Run: make test-functions
 */

import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { alignSteps, TRANSLATE_SYSTEM_PROMPT } from "./translate.ts";

Deno.test("a correct round trip preserves order and text", () => {
  const source = [{ position: 0, text: "a" }, { position: 1, text: "b" }];
  const returned = [
    { position: 1, text: "B" },
    { position: 0, text: "A" },
  ];
  assertEquals(alignSteps(source, returned), [
    { position: 0, text: "A" },
    { position: 1, text: "B" },
  ]);
});

Deno.test("a dropped position throws", () => {
  const source = [{ position: 0, text: "a" }, { position: 1, text: "b" }];
  const returned = [{ position: 0, text: "A" }];
  assertThrows(() => alignSteps(source, returned));
});

Deno.test("an extra position throws", () => {
  const source = [{ position: 0, text: "a" }];
  const returned = [{ position: 0, text: "A" }, { position: 1, text: "B" }];
  assertThrows(() => alignSteps(source, returned));
});

Deno.test("a duplicated position throws, even with the right count", () => {
  const source = [{ position: 0, text: "a" }, { position: 1, text: "b" }];
  const returned = [{ position: 0, text: "A" }, { position: 0, text: "A2" }];
  assertThrows(() => alignSteps(source, returned));
});

Deno.test("no source steps and no returned steps is a valid, empty match", () => {
  assertEquals(alignSteps([], []), []);
});

Deno.test("the prompt states the Latin-script rule", () => {
  // A guard on the prompt text itself, the same instinct every fixture-driven
  // test file here carries: deleting the sentence that stops Cyrillic output
  // should fail a test, not silently ship a prompt that no longer says so.
  if (!TRANSLATE_SYSTEM_PROMPT.includes("Latin script")) {
    throw new Error(
      "TRANSLATE_SYSTEM_PROMPT no longer states the Latin-script rule (D4)",
    );
  }
});
