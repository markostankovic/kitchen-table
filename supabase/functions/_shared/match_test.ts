/**
 * The matcher's decision logic, without the network.
 *
 * `matchFromCatalog` and `matchWithModel` are mostly I/O, and what is worth
 * testing in them is not the round trip -- it is the two rules that decide
 * what happens to a line, both of which are easy to break and silent when
 * broken:
 *
 *   1. rule 3: every line keeps its rawText no matter which tier touched it.
 *   2. D31: auto-accept is the server's word, never recomputed from a number.
 *
 * Run: make test-functions
 */

import { assertEquals } from "jsr:@std/assert@1";
import { parseLines, unresolved } from "./match.ts";
import { normalizeText } from "./normalize.ts";
import type { UnitLexicon } from "./parse_line.ts";

const lexicon: UnitLexicon = new Map([
  [normalizeText("g"), "g"],
  [normalizeText("kašike"), "tbsp"],
  [normalizeText("šolje"), "cup"],
]);

Deno.test("parseLines keeps rawText on every line (rule 3)", () => {
  const raw = [
    { rawText: "200 g šargarepe" },
    { rawText: "za posluživanje" },
    { rawText: "   " },
  ];
  const lines = parseLines(raw, lexicon);

  assertEquals(lines.map((l) => l.rawText), raw.map((r) => r.rawText));
});

Deno.test("parseLines fills structure without claiming a match", () => {
  const [line] = parseLines([{ rawText: "200 g šargarepe" }], lexicon);

  assertEquals(line.quantity, { num: 200, den: 1, maxNum: null, maxDen: null });
  assertEquals(line.unitCode, "g");
  assertEquals(line.name, "šargarepe");
  // Structure is tier 1. Nothing here has consulted the catalog yet, so a
  // line that parsed perfectly is still unmatched -- which is the state rule 3
  // says must render.
  assertEquals(line.ingredientId, null);
  assertEquals(line.matchMethod, null);
  assertEquals(line.autoAccept, false);
});

Deno.test("a line that parses to nothing still becomes a line", () => {
  const [line] = parseLines([{ rawText: "   " }], lexicon);
  assertEquals(line.rawText, "   ");
  assertEquals(line.name, null);
  assertEquals(line.quantity, null);
});

Deno.test("section is carried through, not derived", () => {
  const [line] = parseLines(
    [{ rawText: "2 kašike ulja", section: "Za fil" }],
    lexicon,
  );
  assertEquals(line.section, "Za fil");
});

Deno.test("unresolved sends the auto-accepted lines nowhere", () => {
  const lines = parseLines(
    [{ rawText: "200 g šargarepe" }, { rawText: "2 kašike ulja" }],
    lexicon,
  );
  lines[0] = { ...lines[0], autoAccept: true, ingredientId: "x" };

  // Only line 1. Tier 4 is the expensive tier and must never be asked about
  // something the database already settled.
  assertEquals(unresolved(lines), [1]);
});

Deno.test("unresolved DOES include a match the server would not auto-accept", () => {
  // The case tier 3 is worst at and tier 4 is best at: a fuzzy hit under the
  // line. Sending only the wholly unmatched lines would throw it away, and the
  // cook would be left confirming a guess by hand that the model could have
  // settled.
  const lines = parseLines([{ rawText: "200 g šargarepe" }], lexicon);
  lines[0] = {
    ...lines[0],
    ingredientId: "maybe",
    matchMethod: "fuzzy",
    matchConfidence: 0.5,
    autoAccept: false,
  };

  assertEquals(unresolved(lines), [0]);
});

Deno.test("a line with no name is never sent to the model", () => {
  // "   " parses to no name. There is nothing to ask about, and asking would
  // spend tokens on whitespace.
  const lines = parseLines([{ rawText: "   " }], lexicon);
  assertEquals(unresolved(lines), []);
});
