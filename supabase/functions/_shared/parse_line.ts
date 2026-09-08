/**
 * Tier 1 of docs/INGREDIENTS.md's pipeline, Deno side: turn
 * `2 šolje glatkog brašna, prosejano` into a quantity, a unit, a name and a
 * note, deterministically and without reaching for a model.
 *
 * The SECOND implementation of one definition, and a port rather than a
 * rewrite. The first is `lib/features/ingredients/domain/ingredient_line_parser.dart`
 * and both are held to `test/fixtures/ingredient_lines.json` (D31, the D5
 * pattern). It is not written freehand: a case added to that fixture must
 * constrain this file too, or the importers and the line editor will disagree
 * about what a recipe says.
 *
 * The Dart version exists because tier 1 touches no data and a round trip per
 * keystroke would cost the 1c line editor its responsiveness. This one exists
 * because the importers are on the other side of the wire and have no editor
 * to borrow it from.
 *
 * CLAUDE.md rule 3, and the reason a failed parse is not a bug: `rawText` is
 * always the line as written. Everything else is an enhancement. If nothing is
 * recognised, `name` is the whole line and the cook still sees what they typed.
 *
 * No I/O: the unit lexicon is injected, exactly as `UnitCatalog` is in Dart.
 */

import { normalizeText } from "./normalize.ts";

/**
 * A quantity as an exact integer fraction (CLAUDE.md rule 5). Never a float:
 * a third of a cup is a third of a cup, and three of them are one cup, not
 * 0.999.
 */
export interface ParsedQuantity {
  readonly num: number;
  readonly den: number;
  readonly maxNum?: number;
  readonly maxDen?: number;
}

export interface ParsedLine {
  /** Always the line as written (rule 3). */
  readonly rawText: string;
  readonly quantity?: ParsedQuantity;
  /** A `units.code`, never a display name. */
  readonly unitCode?: string;
  /** The LITERAL remainder -- the parser does not de-inflect (D6). */
  readonly name?: string;
  readonly note?: string;
  readonly isOptional: boolean;
}

/**
 * Normalized alias -> `units.code`.
 *
 * The Dart parser reaches its catalog through exactly one method,
 * `UnitCatalog.resolveCode`, so this is the whole of what the lexicon has to
 * be. Importers build it from `unit_names`; the test builds it from
 * `test/fixtures/unit_aliases.json`.
 */
export type UnitLexicon = ReadonlyMap<string, string>;

export const EMPTY_LEXICON: UnitLexicon = new Map();

/** Words that stand in for a number. */
const WORD_QUANTITIES: ReadonlyMap<string, readonly [number, number]> = new Map(
  [
    ["pola", [1, 2] as const],
    ["par", [2, 1] as const],
    ["half", [1, 2] as const],
  ],
);

/**
 * Unicode vulgar fractions, which cookbook scans and pasted web text are full
 * of. `normalize_text` leaves them alone, so they arrive intact.
 */
const VULGAR_FRACTIONS: ReadonlyMap<string, readonly [number, number]> =
  new Map([
    ["½", [1, 2] as const],
    ["⅓", [1, 3] as const],
    ["⅔", [2, 3] as const],
    ["¼", [1, 4] as const],
    ["¾", [3, 4] as const],
    ["⅕", [1, 5] as const],
    ["⅖", [2, 5] as const],
    ["⅗", [3, 5] as const],
    ["⅘", [4, 5] as const],
    ["⅙", [1, 6] as const],
    ["⅚", [5, 6] as const],
    ["⅛", [1, 8] as const],
    ["⅜", [3, 8] as const],
    ["⅝", [5, 8] as const],
    ["⅞", [7, 8] as const],
  ]);

/**
 * Trailing markers that mean "this line is discretionary".
 *
 * `po ukusu` is in this list even though it is also seeded as a unit with
 * family `other`. Where a recipe actually writes it -- at the end of a line --
 * it is a note, not a measurement, and treating it as a note is what lets
 * `so po ukusu` come out as the ingredient `so`. The `to_taste` unit code
 * exists for imports that carry an explicit "to taste" quantity field, and
 * this parser deliberately never emits it.
 */
const OPTIONAL_MARKERS: readonly string[] = [
  "po ukusu",
  "po zelji",
  "opciono",
  "optional",
  "to taste",
  "if desired",
];

/** The three dash characters that appear in real recipe text. */
const DASHES = "-–—";

const PARENTHESISED = /\(([^)]*)\)/g;
const WHITESPACE = /\s+/;

/** A number followed immediately by letters: `500g`, `1,5dl`. */
const NUMBER_UNIT = /^(\d+(?:[.,]\d+)?)([^\d\s]+)$/;
const WHITESPACE_G = /\s+/g;

export class IngredientLineParser {
  /**
   * Injected so the parser stays pure. Pass `EMPTY_LEXICON` and quantities,
   * names and notes still parse -- only unit resolution stops.
   */
  constructor(private readonly units: UnitLexicon = EMPTY_LEXICON) {}

  parse(rawText: string): ParsedLine {
    const notes: string[] = [];

    // 1. Parenthesised text is always a note, wherever it sits.
    let work = rawText.replace(PARENTHESISED, (_match, inner: string) => {
      const trimmed = inner.trim();
      if (trimmed.length > 0) notes.push(trimmed);
      return " ";
    });

    // 2. Everything after the first comma is a note.
    const comma = noteCommaIndex(work);
    if (comma >= 0) {
      const tail = work.slice(comma + 1).trim();
      work = work.slice(0, comma);
      if (tail.length > 0) notes.unshift(tail);
    }

    work = work.replace(WHITESPACE_G, " ").trim();

    // 3. Optional markers, whether they ended up in the notes or are still
    //    trailing the line itself.
    let isOptional = false;
    for (const marker of OPTIONAL_MARKERS) {
      if (notes.some((n) => normalizeText(n) === marker)) {
        isOptional = true;
      }
      const stripped = stripTrailingMarker(work, marker);
      if (stripped !== work) {
        isOptional = true;
        notes.push(work.slice(stripped.length).trim());
        work = stripped;
      }
    }

    // 4. Tokenise once. Originals are kept alongside their normalized forms so
    //    the name comes back as written -- the parser does not de-inflect (D6).
    const tokens: string[] = [];
    for (const token of work.length === 0 ? [] : work.split(WHITESPACE)) {
      const split = this.splitNumberUnit(token);
      if (split === null) {
        tokens.push(token);
      } else {
        tokens.push(split[0], split[1]);
      }
    }
    const normalized = tokens.map(normalizeText);

    let cursor = 0;

    // 5. Quantity.
    const read = this.readQuantity(normalized, cursor);
    let qty: ParsedQuantity | undefined;
    if (read !== null) {
      qty = read[0];
      cursor = read[1];
    }

    // 6. Unit. Two tokens first: `supena kašika` and `čajna kašičica` would
    //    otherwise resolve on their first word alone, or not at all.
    let unitCode: string | undefined;
    if (cursor < normalized.length) {
      if (cursor + 1 < normalized.length) {
        const pair = `${normalized[cursor]} ${normalized[cursor + 1]}`;
        const code = this.units.get(pair);
        if (code !== undefined) {
          unitCode = code;
          cursor += 2;
        }
      }
      if (unitCode === undefined) {
        const code = this.units.get(normalized[cursor]);
        // A unit is only a unit here if something follows it. `2 kašike` on
        // its own line is a quantity of an unnamed thing, but `šolja` alone is
        // far more likely to be somebody's ingredient than a bare unit.
        if (
          code !== undefined &&
          (qty !== undefined || cursor + 1 < normalized.length)
        ) {
          unitCode = code;
          cursor += 1;
        }
      }
    }

    // 7. Whatever is left is the name, verbatim.
    const name = tokens.slice(cursor).join(" ").trim();

    return {
      rawText,
      quantity: qty,
      unitCode,
      name: name.length === 0 ? undefined : name,
      note: notes.length === 0 ? undefined : notes.join(", "),
      isOptional,
    };
  }

  /**
   * Splits `500g` into `500` and `g`, or null if `token` is not that shape.
   *
   * Real recipe pages write the quantity and the unit as one word far more
   * often than not -- `500g beef mince`, `200ml mleka` -- and before this the
   * whole line parsed to no quantity and no unit at all. Found by importing
   * actual pages in Phase 1d part 4, which is exactly the case
   * `test/fixtures/ingredient_lines.json` asks to be told about.
   *
   * Only splits when the tail IS a known unit. Unconditional splitting would
   * be shorter and would also invent a quantity out of any ingredient whose
   * first word happened to start with a digit. The digit-free tail is what
   * keeps `1/2`, `2-3` and `1½` out of here -- each has a digit or a vulgar
   * fraction after the number, and each is already handled below.
   */
  private splitNumberUnit(token: string): [string, string] | null {
    const m = NUMBER_UNIT.exec(token);
    if (m === null) return null;
    if (this.units.get(normalizeText(m[2])) === undefined) return null;
    return [m[1], m[2]];
  }

  /**
   * Reads a quantity starting at `start`. Returns it with the index of the
   * first token after it, or null if the line does not begin with a number.
   */
  private readQuantity(
    tokens: readonly string[],
    start: number,
  ): [ParsedQuantity, number] | null {
    if (start >= tokens.length) return null;

    // `2-3`, `2–3` as a single token.
    const single = readDashRange(tokens, start);
    if (single !== null) return single;

    const first = readValue(tokens, start);
    if (first === null) return null;
    let cursor = start + 1;
    let lowerNum = first;
    let lowerDen = denominatorOf(tokens[start]);

    // A mixed number: `1 1/2`, or `1 ½`.
    if (lowerDen === 1 && cursor < tokens.length) {
      const frac = readPureFraction(tokens[cursor]);
      if (frac !== null) {
        lowerNum = lowerNum * frac[1] + frac[0];
        lowerDen = frac[1];
        cursor += 1;
      }
    }

    // A spaced range: `2 - 3`.
    if (
      cursor + 1 < tokens.length &&
      tokens[cursor].length === 1 &&
      DASHES.includes(tokens[cursor])
    ) {
      const upper = readNumeric(tokens[cursor + 1]);
      if (upper !== null) {
        return [range(lowerNum, lowerDen, upper[0], upper[1]), cursor + 2];
      }
    }

    return [fraction(lowerNum, lowerDen), cursor];
  }
}

/** `2-3` and friends, where the dash is inside the token. */
function readDashRange(
  tokens: readonly string[],
  start: number,
): [ParsedQuantity, number] | null {
  const token = tokens[start];
  for (let i = 1; i < token.length; i++) {
    if (!DASHES.includes(token[i])) continue;
    const lower = readNumeric(token.slice(0, i));
    const upper = readNumeric(token.slice(i + 1));
    if (lower !== null && upper !== null) {
      return [range(lower[0], lower[1], upper[0], upper[1]), start + 1];
    }
  }
  return null;
}

/**
 * The numerator half of a leading value. Paired with `denominatorOf` so a
 * mixed number can be assembled without parsing the same token twice.
 *
 * The Dart original returns a `(int, int)` whose second element is the token
 * count, which is always 1 -- so this returns the numerator alone and the
 * caller advances by one. Same behaviour, one less thing to misread.
 */
function readValue(tokens: readonly string[], index: number): number | null {
  const numeric = readNumeric(tokens[index]);
  if (numeric !== null) return numeric[0];

  const word = WORD_QUANTITIES.get(tokens[index]);
  if (word !== undefined) return word[0];

  return null;
}

function denominatorOf(token: string): number {
  const numeric = readNumeric(token);
  if (numeric !== null) return numeric[1];
  return WORD_QUANTITIES.get(token)?.[1] ?? 1;
}

/** A whole number, fraction, decimal or vulgar fraction in one token. */
function readNumeric(token: string): readonly [number, number] | null {
  if (token.length === 0) return null;

  const pure = readPureFraction(token);
  if (pure !== null) return pure;

  // `1½`
  const last = token.slice(token.length - 1);
  const vulgar = VULGAR_FRACTIONS.get(last);
  if (vulgar !== undefined && token.length > 1) {
    const whole = parseIntStrict(token.slice(0, token.length - 1));
    if (whole !== null) {
      return [whole * vulgar[1] + vulgar[0], vulgar[1]];
    }
  }

  // `1,5` and `1.5`. Serbian writes the decimal comma, but the comma split
  // happens before this, so only a comma with no space around it survives --
  // which is exactly how a decimal is written.
  const dot = token.search(/[.,]/);
  if (dot > 0 && dot < token.length - 1) {
    const whole = parseIntStrict(token.slice(0, dot));
    const fracDigits = token.slice(dot + 1);
    const frac = parseIntStrict(fracDigits);
    if (whole !== null && frac !== null) {
      let denominator = 1;
      for (let i = 0; i < fracDigits.length; i++) denominator *= 10;
      return [whole * denominator + frac, denominator];
    }
  }

  const whole = parseIntStrict(token);
  return whole === null ? null : [whole, 1];
}

/** `1/2`, or a bare vulgar fraction. */
function readPureFraction(token: string): readonly [number, number] | null {
  const vulgar = VULGAR_FRACTIONS.get(token);
  if (vulgar !== undefined) return vulgar;

  const slash = token.indexOf("/");
  if (slash <= 0 || slash === token.length - 1) return null;
  const numerator = parseIntStrict(token.slice(0, slash));
  const denominator = parseIntStrict(token.slice(slash + 1));
  if (numerator === null || denominator === null || denominator === 0) {
    return null;
  }
  return [numerator, denominator];
}

/**
 * Dart's `int.tryParse`, which `parseInt` is not: `parseInt("2kg")` is 2 and
 * `Number("")` is 0. Both would silently invent quantities out of ingredient
 * names.
 */
function parseIntStrict(token: string): number | null {
  if (!/^[+-]?\d+$/.test(token)) return null;
  const value = Number(token);
  return Number.isSafeInteger(value) ? value : null;
}

/** Index of the first comma that separates a note, or -1.
 *
 * A comma between two digits is a Serbian decimal point, not a separator.
 * Splitting on it would turn `1,5 dl vode` into the quantity 1 and the note
 * `5 dl vode` -- silently, and wrong by a factor of ten in the direction
 * nobody checks.
 */
function noteCommaIndex(text: string): number {
  for (let i = 0; i < text.length; i++) {
    if (text[i] !== ",") continue;
    const digitBefore = i > 0 && isDigit(text[i - 1]);
    const digitAfter = i + 1 < text.length && isDigit(text[i + 1]);
    if (digitBefore && digitAfter) continue;
    return i;
  }
  return -1;
}

function isDigit(character: string): boolean {
  const code = character.charCodeAt(0);
  return code >= 0x30 && code <= 0x39;
}

/**
 * Removes `marker` from the end of `text` if it is there, comparing normalized
 * so `po želji` and `po zelji` both strip.
 */
function stripTrailingMarker(text: string, marker: string): string {
  const words = marker.split(" ");
  const tokens = text.length === 0 ? [] : text.split(WHITESPACE);
  if (tokens.length <= words.length) return text;

  const tail = tokens
    .slice(tokens.length - words.length)
    .map(normalizeText)
    .join(" ");
  if (tail !== marker) return text;

  return tokens.slice(0, tokens.length - words.length).join(" ");
}

/**
 * Reduces a fraction and normalises the sign onto the numerator, so that two
 * quantities that mean the same thing compare the same way -- the Dart
 * `Quantity` value type does this in its factory and the fixture asserts the
 * reduced form.
 */
function reduce(numerator: number, denominator: number): [number, number] {
  if (denominator === 0) {
    throw new Error("denominator must not be zero");
  }
  let a = Math.abs(numerator);
  let b = Math.abs(denominator);
  while (b !== 0) {
    const t = b;
    b = a % b;
    a = t;
  }
  const divisor = a === 0 ? 1 : a;
  const sign = denominator < 0 ? -1 : 1;
  return [(sign * numerator) / divisor, (sign * denominator) / divisor];
}

function fraction(numerator: number, denominator: number): ParsedQuantity {
  const [n, d] = reduce(numerator, denominator);
  return { num: n, den: d };
}

function range(
  numerator: number,
  denominator: number,
  maxNumerator: number,
  maxDenominator: number,
): ParsedQuantity {
  const [n, d] = reduce(numerator, denominator);
  const [mn, md] = reduce(maxNumerator, maxDenominator);
  return { num: n, den: d, maxNum: mn, maxDen: md };
}
