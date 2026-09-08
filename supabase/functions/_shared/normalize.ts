/**
 * Text normalization, Deno side.
 *
 * The THIRD implementation of one definition (D5, CLAUDE.md rule 6). The other
 * two are `normalize_text()` in Postgres (migration 1) and `TextNormalizer` in
 * `lib/core/text/text_normalizer.dart`, and all three are verified against the
 * same list in `test/fixtures/normalization.json`.
 *
 * This file was ported from the Dart one line for line and must stay that way.
 * It is not written freehand and it is not "improved" independently -- two
 * implementations that silently disagree is the worst failure mode in the
 * system, because diacritic-insensitive search and every ingredient match tier
 * assume identical output on every side.
 *
 * Change one, change all three, run `make test-functions` and `make test-sql`.
 */

/**
 * Cyrillic letters whose Latin form is more than one character.
 *
 * These must run BEFORE the single-character map: `њ` is one codepoint but two
 * Latin letters, so a 1:1 translation cannot express it.
 */
const CYRILLIC_DIGRAPHS: ReadonlyArray<readonly [string, string]> = [
  ["њ", "nj"],
  ["љ", "lj"],
  ["џ", "dz"],
  ["ђ", "dj"],
  ["ћ", "c"],
  ["ж", "z"],
];

/** 1:1 Cyrillic -> Latin. Parallel strings, indexed together. */
const CYRILLIC_FROM = "абвгдезијклмнопрстуфхцчш";
const CYRILLIC_TO = "abvgdezijklmnoprstufhccs";

/**
 * Latin diacritics.
 *
 * `đ` -> `dj` is the reason Postgres `unaccent` is not usable here: it produces
 * `d`, which splits *đuveč* from a user typing *djuvec* (D5/D19).
 */
const LATIN_DIACRITICS: ReadonlyArray<readonly [string, string]> = [
  ["č", "c"],
  ["ć", "c"],
  ["š", "s"],
  ["ž", "z"],
  ["đ", "dj"],
];

const WHITESPACE = /\s+/g;

/** Every key of both maps, for one pass instead of eleven `replaceAll`s. */
const SINGLE_PASS = new Map<string, string>([
  ...CYRILLIC_DIGRAPHS,
  ...LATIN_DIACRITICS,
]);

/**
 * Returns `input` lowercased, transliterated to Latin, stripped of diacritics,
 * with whitespace collapsed and trimmed.
 *
 * Punctuation is deliberately preserved: the ingredient line parser already
 * splits notes off at the first comma, so stripping it here would only make two
 * representations of the same line normalize identically when they should not.
 *
 * The Dart version runs the digraph map, then the 1:1 table, then the Latin
 * diacritics as three separate passes. This does all three in one walk over the
 * runes, which is equivalent because the three key sets are disjoint and no
 * replacement produces a character that another rule would then rewrite --
 * every output is plain ASCII.
 */
export function normalizeText(input: string): string {
  const lowered = input.toLowerCase();

  let out = "";
  for (const char of lowered) {
    const mapped = SINGLE_PASS.get(char);
    if (mapped !== undefined) {
      out += mapped;
      continue;
    }
    const index = CYRILLIC_FROM.indexOf(char);
    out += index >= 0 ? CYRILLIC_TO[index] : char;
  }

  return out.replace(WHITESPACE, " ").trim();
}
