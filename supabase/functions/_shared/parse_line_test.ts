/**
 * Tier 1, Deno side, driven entirely by test/fixtures/ingredient_lines.json.
 *
 * The mirror of test/features/ingredients/ingredient_line_parser_test.dart,
 * asserting the same cases in the same order. That is the point: the fixture
 * is the contract (D5, D31), and a case added there must fail here too, or the
 * importers and the 1c line editor will quietly disagree about what a recipe
 * says.
 *
 * The unit lexicon comes from test/fixtures/unit_aliases.json, which
 * tool/gen_unit_alias_sql.dart also turns into a SQL test asserting the
 * database agrees. So a unit code asserted here is a unit code that exists.
 *
 * Run: make test-functions
 */

import { assertEquals } from "jsr:@std/assert@1";
import {
  EMPTY_LEXICON,
  IngredientLineParser,
  type UnitLexicon,
} from "./parse_line.ts";
import { normalizeText } from "./normalize.ts";

const fixture = (name: string) =>
  new URL(`../../../test/fixtures/${name}`, import.meta.url);

async function lexiconFromFixture(): Promise<UnitLexicon> {
  const raw = JSON.parse(
    await Deno.readTextFile(fixture("unit_aliases.json")),
  ) as Record<string, unknown>;

  const aliases = new Map<string, string>();
  for (const [key, value] of Object.entries(raw)) {
    if (key.startsWith("_")) continue;
    // Both sides normalize before comparing -- the fixture's keys are written
    // as a human writes them, and the parser looks up normalized tokens.
    aliases.set(normalizeText(key), value as string);
  }
  return aliases;
}

interface Case {
  raw: string;
  qty?: [number, number];
  qtyMax?: [number, number];
  unit?: string;
  name?: string;
  note?: string;
  optional?: boolean;
  _comment?: unknown;
}

const parser = new IngredientLineParser(await lexiconFromFixture());

const cases = (JSON.parse(
  await Deno.readTextFile(fixture("ingredient_lines.json")),
) as Case[]).filter((c) => c._comment === undefined);

Deno.test("the fixture actually has cases", () => {
  // The same guard the Dart test carries, with the same number: a fixture that
  // silently emptied would turn every assertion below into a vacuous pass.
  if (cases.length < 25) {
    throw new Error(`expected at least 25 cases, got ${cases.length}`);
  }
});

for (const c of cases) {
  Deno.test(`parses ${JSON.stringify(c.raw)}`, () => {
    const got = parser.parse(c.raw);

    // Rule 3, asserted on every single case: raw_text survives untouched,
    // whatever else the parser did or failed to do.
    assertEquals(got.rawText, c.raw, "rawText must be the line as written");

    if (c.qty === undefined) {
      assertEquals(got.quantity, undefined);
    } else {
      assertEquals(got.quantity?.num, c.qty[0]);
      assertEquals(got.quantity?.den, c.qty[1]);
    }

    if (c.qtyMax === undefined) {
      assertEquals(got.quantity?.maxNum, undefined);
      assertEquals(got.quantity?.maxDen, undefined);
    } else {
      assertEquals(got.quantity?.maxNum, c.qtyMax[0]);
      assertEquals(got.quantity?.maxDen, c.qtyMax[1]);
    }

    assertEquals(got.unitCode, c.unit);
    assertEquals(got.name, c.name);
    assertEquals(got.note, c.note);
    assertEquals(got.isOptional, c.optional ?? false);
  });
}

Deno.test("an empty lexicon still parses everything but the unit", () => {
  // Rule 3 again, from the other direction: the lexicon is injected, and an
  // importer that has not fetched unit_names yet must degrade rather than fail.
  const bare = new IngredientLineParser(EMPTY_LEXICON);
  const got = bare.parse("2 kašike ulja, zagrejano");

  assertEquals(got.rawText, "2 kašike ulja, zagrejano");
  assertEquals(got.quantity, { num: 2, den: 1 });
  assertEquals(got.unitCode, undefined);
  assertEquals(got.name, "kašike ulja");
  assertEquals(got.note, "zagrejano");
});

Deno.test("an empty line is a supported state", () => {
  const got = parser.parse("   ");
  assertEquals(got.rawText, "   ");
  assertEquals(got.name, undefined);
  assertEquals(got.quantity, undefined);
});
