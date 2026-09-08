/**
 * The JSON-LD half of import-url.
 *
 * Inline HTML rather than files under test/fixtures/: that directory holds
 * contracts shared across Dart, SQL and Deno, and this is one implementation
 * of one thing. The cases are the shapes real recipe sites actually publish --
 * @graph from WordPress, @type as an array, and recipeInstructions in all four
 * forms it appears in.
 *
 * Run: make test-functions
 */

import { assertEquals } from "jsr:@std/assert@1";
import {
  extractJsonLd,
  findRecipeNode,
  isoDurationToMinutes,
  recipeFromJsonLd,
  stripHtml,
} from "./jsonld.ts";

function page(payload: unknown, opts: { lang?: string } = {}): string {
  const lang = opts.lang ? ` lang="${opts.lang}"` : "";
  return `<!doctype html><html${lang}><head>
<script type="application/ld+json">${JSON.stringify(payload)}</script>
</head><body><p>ignored</p></body></html>`;
}

function parse(html: string) {
  const node = findRecipeNode(extractJsonLd(html));
  return node === null ? null : recipeFromJsonLd(node, html);
}

const MINIMAL = {
  "@context": "https://schema.org",
  "@type": "Recipe",
  name: "Šargarepa torta",
  recipeIngredient: ["200 g šargarepe", "2 šolje glatkog brašna"],
  recipeInstructions: "Zagrejati rernu.\nPomešati sve.",
};

Deno.test("reads a plain Recipe object", () => {
  const got = parse(page(MINIMAL))!;
  assertEquals(got.title, "Šargarepa torta");
  assertEquals(got.ingredients.map((i) => i.rawText), [
    "200 g šargarepe",
    "2 šolje glatkog brašna",
  ]);
  assertEquals(got.steps.map((s) => s.text), [
    "Zagrejati rernu.",
    "Pomešati sve.",
  ]);
});

Deno.test("ingredient lines are verbatim, never reformatted (rule 3)", () => {
  // The same instruction import-text gives the model. parse_line.ts is what
  // pulls a line apart, and it is held to a fixture; re-deriving the quantity
  // here would be a second, untested implementation.
  const got = parse(page({
    ...MINIMAL,
    recipeIngredient: ["1 1/2 šolje mleka", "2-3 kašike ulja, zagrejano"],
  }))!;
  assertEquals(got.ingredients.map((i) => i.rawText), [
    "1 1/2 šolje mleka",
    "2-3 kašike ulja, zagrejano",
  ]);
});

Deno.test("finds a Recipe inside @graph", () => {
  // What every WordPress SEO plugin emits.
  const got = parse(page({
    "@context": "https://schema.org",
    "@graph": [
      { "@type": "WebSite", name: "A food blog" },
      { "@type": "BreadcrumbList" },
      MINIMAL,
    ],
  }))!;
  assertEquals(got.title, "Šargarepa torta");
});

Deno.test("finds a Recipe when @type is an array", () => {
  const got = parse(page({ ...MINIMAL, "@type": ["Recipe", "NewsArticle"] }))!;
  assertEquals(got.title, "Šargarepa torta");
});

Deno.test("finds a Recipe in a top-level array", () => {
  const got = parse(page([{ "@type": "Organization" }, MINIMAL]))!;
  assertEquals(got.title, "Šargarepa torta");
});

Deno.test("reads HowToStep instructions", () => {
  const got = parse(page({
    ...MINIMAL,
    recipeInstructions: [
      { "@type": "HowToStep", text: "Zagrejati rernu." },
      { "@type": "HowToStep", text: "Pomešati sve." },
    ],
  }))!;
  assertEquals(got.steps.map((s) => s.text), [
    "Zagrejati rernu.",
    "Pomešati sve.",
  ]);
});

Deno.test("reads HowToSection instructions", () => {
  const got = parse(page({
    ...MINIMAL,
    recipeInstructions: [
      {
        "@type": "HowToSection",
        name: "Za fil",
        itemListElement: [
          { "@type": "HowToStep", text: "Umutiti jaja." },
          { "@type": "HowToStep", text: "Dodati šećer." },
        ],
      },
    ],
  }))!;
  assertEquals(got.steps.map((s) => s.text), [
    "Umutiti jaja.",
    "Dodati šećer.",
  ]);
});

Deno.test("splits a numbered single-string method into steps", () => {
  // One step containing the whole method is useless to somebody cooking.
  const got = parse(page({
    ...MINIMAL,
    recipeInstructions: "1. Zagrejati rernu.\n2. Pomešati sve.\n",
  }))!;
  assertEquals(got.steps.map((s) => s.text), [
    "Zagrejati rernu.",
    "Pomešati sve.",
  ]);
});

Deno.test("reads servings out of prose", () => {
  assertEquals(
    parse(page({ ...MINIMAL, recipeYield: "4 servings" }))!.servings,
    4,
  );
  assertEquals(parse(page({ ...MINIMAL, recipeYield: "6" }))!.servings, 6);
  assertEquals(
    parse(page({ ...MINIMAL, recipeYield: ["8", "8 portions"] }))!.servings,
    8,
  );
  assertEquals(parse(page(MINIMAL))!.servings, null);
});

Deno.test("reads ISO 8601 durations", () => {
  assertEquals(isoDurationToMinutes("PT30M"), 30);
  assertEquals(isoDurationToMinutes("PT1H"), 60);
  assertEquals(isoDurationToMinutes("PT1H30M"), 90);
  assertEquals(isoDurationToMinutes("P1DT2H"), 1560);
  assertEquals(
    isoDurationToMinutes("PT45S"),
    null,
    "under a minute is nothing",
  );
  assertEquals(isoDurationToMinutes("half an hour"), null);
  assertEquals(isoDurationToMinutes(undefined), null);

  const got = parse(page({ ...MINIMAL, prepTime: "PT20M", cookTime: "PT1H" }))!;
  assertEquals(got.prepMinutes, 20);
  assertEquals(got.cookMinutes, 60);
});

Deno.test("stores attribution, from author or publisher", () => {
  // A standing rule: source_attribution is stored for every import.
  assertEquals(
    parse(page({ ...MINIMAL, author: { "@type": "Person", name: "Ana" } }))!
      .sourceAttribution,
    "Ana",
  );
  assertEquals(
    parse(page({ ...MINIMAL, publisher: { name: "Coolinarika" } }))!
      .sourceAttribution,
    "Coolinarika",
  );
  assertEquals(parse(page(MINIMAL))!.sourceAttribution, null);
});

Deno.test("locale: declared first, then the diacritics", () => {
  assertEquals(
    parse(page({ ...MINIMAL, inLanguage: "sr-RS" }))!.originalLocale,
    "sr",
  );
  assertEquals(parse(page(MINIMAL, { lang: "en-GB" }))!.originalLocale, "en");
  // Undeclared, but the ingredient lines are full of š and ž.
  assertEquals(parse(page(MINIMAL))!.originalLocale, "sr");
  assertEquals(
    parse(page({ ...MINIMAL, recipeIngredient: ["2 cups flour", "1 egg"] }))!
      .originalLocale,
    "en",
  );
});

Deno.test("decodes the entities recipe text is full of", () => {
  const got = parse(page({
    ...MINIMAL,
    name: "Caf&eacute; &amp; Cream",
    recipeIngredient: ["&frac12; cup sugar", "2&nbsp;eggs"],
  }))!;
  assertEquals(got.title, "Café & Cream");
  assertEquals(got.ingredients[0].rawText, "½ cup sugar");
});

Deno.test("a page with no JSON-LD yields null rather than throwing", () => {
  assertEquals(parse("<html><body><h1>A recipe</h1></body></html>"), null);
});

Deno.test("a malformed block does not sink a good one beside it", () => {
  const html = `<html><head>
<script type="application/ld+json">{ this is not json }</script>
<script type="application/ld+json">${JSON.stringify(MINIMAL)}</script>
</head></html>`;
  assertEquals(parse(html)!.title, "Šargarepa torta");
});

Deno.test("a Recipe stub with no ingredients is not a recipe", () => {
  // Better to fall through to the model with the whole page than to write a
  // draft with a title and nothing in it.
  const html = page({ "@type": "Recipe", name: "Just a title" });
  assertEquals(parse(html), null);
});

Deno.test("JSON-LD in a non-Recipe page is ignored", () => {
  assertEquals(
    parse(page({ "@type": "Article", headline: "Not a recipe" })),
    null,
  );
});

Deno.test("stripHtml drops chrome and keeps the line breaks", () => {
  const text = stripHtml(`<html><head><style>p{color:red}</style></head>
<body><nav>Home About</nav>
<h1>Torta</h1>
<ul><li>200 g šargarepe</li><li>2 jaja</li></ul>
<script>var x = 1;</script>
<footer>Copyright</footer></body></html>`);

  // The list has to survive as lines: run them together and the model loses
  // the boundaries that say where one ingredient ends.
  assertEquals(text.includes("200 g šargarepe\n2 jaja"), true);
  assertEquals(text.includes("Home About"), false, "nav is chrome");
  assertEquals(text.includes("var x"), false, "script is not content");
  assertEquals(text.includes("color:red"), false, "style is not content");
  assertEquals(text.includes("Copyright"), false, "footer is chrome");
});
