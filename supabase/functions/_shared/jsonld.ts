/**
 * schema.org Recipe out of a web page, without a model and without an HTML
 * parser.
 *
 * "JSON-LD first, LLM fallback" (docs/ROADMAP.md) is worth the code because
 * most recipe sites publish a complete, exact Recipe object for Google, and
 * reading it costs nothing, takes a millisecond, and cannot hallucinate. The
 * model is for the pages that do not.
 *
 * No DOM library (rule 8). `<script type="application/ld+json">` blocks are
 * found by regex and handed to `JSON.parse`, which is not the fragile move it
 * looks like: a `</script>` inside JSON has to be escaped or the browser ends
 * the script early too, so the regex boundary is the same one every real
 * parser honours.
 */

import type { ModelRecipeT } from "./schema.ts";

const SCRIPT_RE =
  /<script[^>]*type\s*=\s*["']application\/ld\+json["'][^>]*>([\s\S]*?)<\/script>/gi;

/** Every JSON-LD payload on the page. Unparseable blocks are skipped. */
export function extractJsonLd(html: string): unknown[] {
  const out: unknown[] = [];

  for (const match of html.matchAll(SCRIPT_RE)) {
    const raw = match[1].trim();
    if (raw.length === 0) continue;
    try {
      out.push(JSON.parse(raw));
    } catch {
      // A single malformed block is not a reason to give up on the page --
      // sites routinely ship one broken blob alongside a good one.
    }
  }
  return out;
}

function typesOf(node: Record<string, unknown>): string[] {
  const raw = node["@type"];
  if (typeof raw === "string") return [raw];
  if (Array.isArray(raw)) return raw.filter((t) => typeof t === "string");
  return [];
}

/**
 * The first Recipe anywhere in the payloads.
 *
 * Walks three shapes that all occur in the wild: a bare object, a top-level
 * array, and `@graph` (which WordPress plugins emit for essentially every
 * page). `@type` is itself either a string or an array.
 */
export function findRecipeNode(
  nodes: unknown[],
): Record<string, unknown> | null {
  const queue: unknown[] = [...nodes];
  let guard = 0;

  while (queue.length > 0 && guard++ < 1000) {
    const node = queue.shift();
    if (Array.isArray(node)) {
      queue.push(...node);
      continue;
    }
    if (node === null || typeof node !== "object") continue;

    const record = node as Record<string, unknown>;
    if (typesOf(record).some((t) => t === "Recipe" || t.endsWith("/Recipe"))) {
      return record;
    }
    if (Array.isArray(record["@graph"])) queue.push(...record["@graph"]);
  }
  return null;
}

/** `PT1H30M` -> 90. Null for anything that is not a duration. */
export function isoDurationToMinutes(value: unknown): number | null {
  if (typeof value !== "string") return null;
  const m = /^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:\d+S)?)?$/.exec(
    value.trim(),
  );
  if (!m) return null;
  const days = Number(m[1] ?? 0);
  const hours = Number(m[2] ?? 0);
  const minutes = Number(m[3] ?? 0);
  const total = days * 1440 + hours * 60 + minutes;
  return total > 0 ? total : null;
}

/** The first plain string out of a value that may be a string, object or list. */
function textOf(value: unknown): string | null {
  if (typeof value === "string") {
    const trimmed = decodeEntities(value).trim();
    return trimmed.length > 0 ? trimmed : null;
  }
  if (Array.isArray(value)) {
    for (const item of value) {
      const text = textOf(item);
      if (text !== null) return text;
    }
    return null;
  }
  if (value !== null && typeof value === "object") {
    const record = value as Record<string, unknown>;
    return textOf(record.name ?? record.text ?? record["@value"]);
  }
  return null;
}

/** `recipeYield` is "4", "4 servings", "Serves 4", or a list of those. */
function servingsOf(value: unknown): number | null {
  const text = textOf(value);
  if (text === null) return null;
  const m = /\d+/.exec(text);
  if (!m) return null;
  const n = Number(m[0]);
  return n > 0 && n < 1000 ? n : null;
}

/**
 * `recipeInstructions` in all four shapes sites actually publish: one string
 * with newlines, an array of strings, an array of HowToStep, and HowToSection
 * wrapping `itemListElement`.
 */
function stepsOf(value: unknown): { text: string }[] {
  const out: { text: string }[] = [];

  const walk = (node: unknown, depth: number): void => {
    if (depth > 4) return;

    if (typeof node === "string") {
      // One blob with newlines or numbered lines is a real shape, and one
      // step containing the whole method is useless to a cook.
      for (const piece of decodeEntities(node).split(/\r?\n+/)) {
        const text = stripHtml(piece).trim().replace(/^\d+[.)]\s*/, "");
        if (text.length > 0) out.push({ text });
      }
      return;
    }
    if (Array.isArray(node)) {
      for (const item of node) walk(item, depth + 1);
      return;
    }
    if (node !== null && typeof node === "object") {
      const record = node as Record<string, unknown>;
      if (Array.isArray(record.itemListElement)) {
        walk(record.itemListElement, depth + 1);
        return;
      }
      walk(record.text ?? record.name, depth + 1);
    }
  };

  walk(value, 0);
  return out;
}

/** Book, author or site -- whatever credits the source (a standing rule). */
function attributionOf(node: Record<string, unknown>): string | null {
  return textOf(node.author) ??
    textOf(node.publisher) ??
    textOf(node.sourceOrganization);
}

const HTML_LANG_RE = /<html[^>]*\blang\s*=\s*["']?([a-zA-Z-]+)/i;

/**
 * `sr` or `en`, in that order of evidence: what the page declares, then what
 * the ingredient lines look like.
 *
 * `recipes.original_locale` is NOT NULL and only takes those two values, so
 * something has to decide. The diacritic test is a heuristic and is meant to
 * be: it is wrong only for a Serbian recipe written without diacritics, which
 * the confirm screen lets a human correct, and locale is a tie-break rather
 * than a filter in matching anyway (D31).
 */
function localeOf(
  node: Record<string, unknown>,
  html: string,
  lines: string[],
): "sr" | "en" {
  const declared = textOf(node.inLanguage) ?? HTML_LANG_RE.exec(html)?.[1];
  if (declared) {
    const tag = declared.toLowerCase();
    if (tag.startsWith("sr") || tag.startsWith("hr") || tag.startsWith("bs")) {
      return "sr";
    }
    if (tag.startsWith("en")) return "en";
  }
  return /[šđčćžŠĐČĆŽ]/.test(lines.join(" ")) ? "sr" : "en";
}

/**
 * A schema.org Recipe as the same `ModelRecipe` shape a model would return, so
 * everything downstream -- parse, match, confirm -- is one code path (D14's
 * argument, one layer down).
 *
 * Returns null when the node has no ingredients: a Recipe object with no
 * `recipeIngredient` is a stub, and the LLM fallback will do better with the
 * page than this would with the stub.
 */
export function recipeFromJsonLd(
  node: Record<string, unknown>,
  html: string,
): ModelRecipeT | null {
  const title = textOf(node.name) ?? textOf(node.headline);
  if (title === null) return null;

  const rawIngredients = node.recipeIngredient ?? node.ingredients;
  const lines: string[] = [];
  if (Array.isArray(rawIngredients)) {
    for (const item of rawIngredients) {
      // Rule 3, and the same instruction import-text gives the model: the line
      // as published, not reformatted. parse_line.ts is what pulls it apart.
      const text = textOf(item);
      if (text !== null) lines.push(text);
    }
  } else {
    const single = textOf(rawIngredients);
    if (single !== null) lines.push(single);
  }

  if (lines.length === 0) return null;

  return {
    title,
    description: textOf(node.description),
    servings: servingsOf(node.recipeYield),
    prepMinutes: isoDurationToMinutes(node.prepTime),
    cookMinutes: isoDurationToMinutes(node.cookTime) ??
      isoDurationToMinutes(node.totalTime),
    originalLocale: localeOf(node, html, lines),
    sourceAttribution: attributionOf(node),
    ingredients: lines.map((rawText) => ({ rawText, section: null })),
    steps: stepsOf(node.recipeInstructions),
  };
}

const DROP_ELEMENTS =
  /<(script|style|noscript|svg|nav|footer|header|form|iframe)\b[^>]*>[\s\S]*?<\/\1>/gi;

/**
 * Page text for the LLM fallback.
 *
 * Crude on purpose. The prompt already tells the model the text may be messy
 * and to find the recipe in it, so spending a dependency on a real DOM to
 * produce slightly tidier input would buy very little.
 */
export function stripHtml(html: string): string {
  return decodeEntities(
    html
      .replace(DROP_ELEMENTS, " ")
      .replace(/<!--[\s\S]*?-->/g, " ")
      // Block-level tags become newlines so an ingredient list does not arrive
      // as one run-on sentence -- which would cost the model the line breaks
      // that tell it where one ingredient ends.
      .replace(/<\/(p|div|li|tr|h[1-6]|section|article)>/gi, "\n")
      .replace(/<br\s*\/?>/gi, "\n")
      .replace(/<[^>]+>/g, " "),
  )
    .replace(/[ \t\f\v]+/g, " ")
    .replace(/\n\s*\n\s*\n+/g, "\n\n")
    .split("\n")
    .map((line) => line.trim())
    .join("\n")
    .trim();
}

/**
 * The HTML 4 Latin-1 entity names, which occupy U+00A0..U+00FF in exactly this
 * order. Generated from the range rather than typed out: 96 hand-written
 * mappings is 96 chances to transpose two of them, and recipe text is full of
 * `&eacute;`, `&uuml;` and `&frac12;`.
 */
const LATIN1_NAMES =
  "nbsp iexcl cent pound curren yen brvbar sect uml copy ordf laquo not shy " +
  "reg macr deg plusmn sup2 sup3 acute micro para middot cedil sup1 ordm " +
  "raquo frac14 frac12 frac34 iquest Agrave Aacute Acirc Atilde Auml Aring " +
  "AElig Ccedil Egrave Eacute Ecirc Euml Igrave Iacute Icirc Iuml ETH Ntilde " +
  "Ograve Oacute Ocirc Otilde Ouml times Oslash Ugrave Uacute Ucirc Uuml " +
  "Yacute THORN szlig agrave aacute acirc atilde auml aring aelig ccedil " +
  "egrave eacute ecirc euml igrave iacute icirc iuml eth ntilde ograve " +
  "oacute ocirc otilde ouml divide oslash ugrave uacute ucirc uuml yacute " +
  "thorn yuml";

const ENTITIES: Record<string, string> = (() => {
  const map: Record<string, string> = {
    amp: "&",
    lt: "<",
    gt: ">",
    quot: '"',
    apos: "'",
    // Deliberately a plain space rather than U+00A0. A non-breaking space in
    // an ingredient line is invisible and survives every whitespace collapse
    // that uses \s -- and `2\u00a0eggs` would then not tokenise.
    nbsp: " ",
    mdash: "—",
    ndash: "–",
    hellip: "…",
    lsquo: "\u2018",
    rsquo: "\u2019",
    ldquo: "\u201c",
    rdquo: "\u201d",
    bull: "•",
    frac13: "⅓",
    frac23: "⅔",
    minus: "−",
  };

  LATIN1_NAMES.split(" ").forEach((name, index) => {
    // The explicit entries above win: `nbsp` is the one place we deliberately
    // disagree with the standard.
    if (map[name] === undefined) {
      map[name] = String.fromCodePoint(0xa0 + index);
    }
  });

  return map;
})();

function decodeEntities(text: string): string {
  // `[a-zA-Z][a-zA-Z0-9]*` and not `[a-zA-Z]+`: the fraction entities carry
  // digits, and `&frac12;` is exactly the one a recipe uses.
  return text.replace(
    /&(#x?[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);/g,
    (whole, body) => {
      if (body.startsWith("#x") || body.startsWith("#X")) {
        const code = parseInt(body.slice(2), 16);
        return Number.isFinite(code) ? String.fromCodePoint(code) : whole;
      }
      if (body.startsWith("#")) {
        const code = parseInt(body.slice(1), 10);
        return Number.isFinite(code) ? String.fromCodePoint(code) : whole;
      }
      // Exact first: entity names are case-sensitive, and `&Eacute;` is a
      // different letter from `&eacute;`. The lowercase retry is only for the
      // structural ones that sites sometimes shout (`&AMP;`).
      return ENTITIES[body] ?? ENTITIES[body.toLowerCase()] ?? whole;
    },
  );
}
