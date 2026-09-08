/**
 * The Deno half of D5, held to the same fixture as Dart and Postgres.
 *
 * `test/fixtures/normalization.json` is the contract. A case added there
 * constrains all three implementations, which is the entire point of having
 * one file rather than three test suites (CLAUDE.md rule 6).
 *
 * Run: make test-functions
 */

import { assertEquals } from "jsr:@std/assert@1";
import { normalizeText } from "./normalize.ts";

const FIXTURE = new URL(
  "../../../test/fixtures/normalization.json",
  import.meta.url,
);

const pairs = JSON.parse(await Deno.readTextFile(FIXTURE)) as string[][];

Deno.test("the fixture actually has cases", () => {
  // Mirrors the Dart parser test's guard: a fixture that silently emptied
  // would turn every assertion below into a vacuous pass.
  if (pairs.length < 15) {
    throw new Error(`expected at least 15 cases, got ${pairs.length}`);
  }
});

for (const [input, expected] of pairs) {
  Deno.test(`normalizes ${JSON.stringify(input)}`, () => {
    assertEquals(normalizeText(input), expected);
  });
}
