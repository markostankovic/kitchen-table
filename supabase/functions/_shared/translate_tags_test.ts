/**
 * `alignTags` and the prompt's own key-echo and Latin-script rules (Phase 6,
 * part 1b).
 *
 * `--allow-read` only (see `make test-functions`), so nothing here touches
 * the network -- `translateTags` itself is not exercised, only the part of
 * it that can be tested without a model call, on `translate_test.ts`'s own
 * shape.
 *
 * Run: make test-functions
 */

import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import {
  alignTags,
  type TagToTranslate,
  TRANSLATE_TAGS_SYSTEM_PROMPT,
} from "./translate_tags.ts";

const requested: TagToTranslate[] = [
  { key: "brzo", label: "Brzo" },
  { key: "posno", label: "posno" },
];

Deno.test("an exact key match passes and returns sorted by key", () => {
  const returned = [
    { key: "posno", sr: "Posno", en: "Lenten" },
    { key: "brzo", sr: "Brzo", en: "Quick" },
  ];
  assertEquals(alignTags(requested, returned), [
    { key: "brzo", sr: "Brzo", en: "Quick" },
    { key: "posno", sr: "Posno", en: "Lenten" },
  ]);
});

Deno.test("a missing key throws", () => {
  const returned = [{ key: "brzo", sr: "Brzo", en: "Quick" }];
  assertThrows(() => alignTags(requested, returned));
});

Deno.test("an extra key throws", () => {
  const returned = [
    { key: "brzo", sr: "Brzo", en: "Quick" },
    { key: "posno", sr: "Posno", en: "Lenten" },
    { key: "ljuto", sr: "Ljuto", en: "Spicy" },
  ];
  assertThrows(() => alignTags(requested, returned));
});

Deno.test("a duplicated key throws, even with the right count", () => {
  const returned = [
    { key: "brzo", sr: "Brzo", en: "Quick" },
    { key: "brzo", sr: "Brzo2", en: "Quick2" },
  ];
  assertThrows(() => alignTags(requested, returned));
});

Deno.test("no requested tags and no returned tags is a valid, empty match", () => {
  assertEquals(alignTags([], []), []);
});

Deno.test("the prompt states the key-echo and Latin-script rules", () => {
  // A guard on the prompt text itself, `translate_test.ts`'s own instinct:
  // deleting the sentence that stops Cyrillic output, or the one that pins
  // the key, should fail a test rather than silently ship a weaker prompt.
  if (!TRANSLATE_TAGS_SYSTEM_PROMPT.includes("Latin script")) {
    throw new Error(
      "TRANSLATE_TAGS_SYSTEM_PROMPT no longer states the Latin-script rule (D4)",
    );
  }
  if (!TRANSLATE_TAGS_SYSTEM_PROMPT.includes("UNCHANGED")) {
    throw new Error(
      "TRANSLATE_TAGS_SYSTEM_PROMPT no longer states the key-echo rule",
    );
  }
});
