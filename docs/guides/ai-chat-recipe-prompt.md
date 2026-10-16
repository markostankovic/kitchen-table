# Generating a recipe in an AI chat for paste import

A prompt for getting a recipe out of an external AI chat (Claude, ChatGPT, …)
in a shape that the paste import reads cleanly.

## Why plain text, not JSON

Paste import (`supabase/functions/import-text/`) already runs a model that
turns prose into structure (`ModelRecipe` in
`supabase/functions/_shared/schema.ts`), so asking the chat for JSON gains
nothing. What matters is the **ingredient lines**. The model returns those
verbatim, and deterministic code reads them: `parse_line.ts` takes the
quantity and unit, then `match.ts` matches the ingredient. A line in the
patterns of `test/fixtures/ingredient_lines.json` comes back with its
quantity, unit and ingredient filled in, and the review screen has less to
flag.

## What the parser likes

| Do | Why |
|---|---|
| One ingredient per line, quantity first, then unit, then name: `200 g brašna` | That order is what `parse_line.ts` reads |
| Seeded units only: `g, kg, ml, dl, l, kašičica, kašika, šolja, čaša, kom, čen, glavica, veza, kriška, kesica, konzerva, prstohvat` | Anything else is left without a unit |
| `1/2`, `1 1/2`, `½`, `1,5`, ranges `2-3` | Become exact integer fractions or ranges |
| Notes after a comma or in brackets: `2 šolje brašna, prosejano` | Become the line's note, so the name stays clean for matching |
| `po ukusu` / `po želji` / `(opciono)` at the **end** of a line: `so po ukusu`, `100 g kajmaka (opciono)` | Marks the line optional |
| No `k.` or `kaš.` | Deliberately not parsed, because they're ambiguous |
| Section headings on their own line: `Za fil:` | Become ingredient sections or method headings |
| Times written in steps: `pecite 25 minuta` | Become a step timer |
| An aside between steps on its own unnumbered line, as a sentence: `Testo može i dan ranije.` | Becomes a note between steps; a closing `Napomena` section becomes the recipe's notes instead |
| `Porcije`, `Priprema` and `Kuvanje` stated explicitly | Fill servings, prep time and cook time |
| Servings as one whole number (`4`, not `4-6` or `1 tepsija`), times in whole minutes | The fields are positive integers; anything else comes back empty |
| Latin script with full diacritics (č, ć, š, ž, đ) | Display is Latin only, and the text is shown as written |

Tags are not imported (`ModelRecipe` has no tags field), so asking for them
does nothing. Leave out a "source" line: the import would save it as the
recipe's attribution, and a chat bot isn't a real source.

## Prompt template (Serbian)

```
Napiši recept za: <JELO / ŽELJE, npr. "posna musaka sa sočivom za 4 osobe, bez rerne duže od 45 min">

Vrati SAMO recept, bez uvoda i komentara, tačno u ovom formatu, latinicom:

<Naziv recepta>

<Jedna ili dve rečenice o jelu.>

Porcije: <broj>
Priprema: <broj> minuta
Kuvanje: <broj> minuta

Sastojci:
<podnaslov ako ima više delova, npr. "Za testo:">
- <količina> <jedinica> <namirnica>, <napomena ako treba>

Postupak:
<podnaslov na svom redu ako postupak ima više delova, npr. "Za testo:">
1. <korak>
2. <korak>
<savet između koraka, ako ga ima: rečenica bez broja>
3. <korak>

Napomena:
- <saveti, ako ih ima>

Pravila za sastojke:
- Jedan sastojak po redu, količina UVEK prva, pa jedinica, pa namirnica.
- Koristi samo ove jedinice, napisane cele: g, kg, ml, dl, l, kašičica, kašika, šolja, čaša, kom, čen, glavica, veza, kriška, kesica, konzerva, prstohvat.
- Razlomci kao 1/2 ili 1 1/2; decimale sa zarezom (1,5 dl); raspon kao 2-3.
- Napomenu o obradi stavi posle zareza ili u zagradu ("1 glavica luka, sitno seckana").
- Začine bez količine piši kao "so po ukusu".
- Sastojak koji može da se izostavi završi sa "(opciono)" ili ", po želji".
- Porcije su jedan ceo broj, a vremena u celim minutima.
- Piši sa svim kvačicama (č, ć, š, ž, đ).
- Bez skraćenica tipa "k." ili "kaš.", bez podebljanog teksta.
U koracima navedi vreme brojem kad postoji ("pecite 25 minuta").
Savet koji važi između dva koraka napiši kao zasebnu rečenicu bez broja, tačno na tom mestu; opšte savete stavi u "Napomena" na kraju.
```

## Prompt template (English)

```
Write a recipe for: <DISH / WISHES>

Return ONLY the recipe, no intro or commentary, in exactly this format:

<Recipe title>

<One or two sentences about the dish.>

Servings: <number>
Prep: <number> minutes
Cook: <number> minutes

Ingredients:
<subheading if the recipe has parts, e.g. "For the dough:">
- <quantity> <unit> <ingredient>, <note if needed>

Method:
<subheading on its own line if the method has parts, e.g. "For the dough:">
1. <step>
2. <step>
<tip between steps, if any: a sentence without a number>
3. <step>

Notes:
- <tips, if any>

Ingredient rules:
- One ingredient per line, quantity ALWAYS first, then unit, then ingredient.
- Use only these units, spelled out: g, kg, ml, l, tsp, tbsp, cup, oz, lb, clove, can, pinch.
- Fractions as 1/2 or 1 1/2; ranges as 2-3.
- Put preparation notes after a comma or in brackets ("1 onion, finely chopped").
- Write seasoning without a quantity as "salt to taste".
- End an ingredient that can be left out with "(optional)" or ", if desired".
- Servings is one whole number; times are whole minutes.
- No abbreviations beyond the units above, no bold text.
In steps, state times as numbers where there is one ("bake for 25 minutes").
A tip that belongs between two steps goes on its own unnumbered line as a sentence, right where it applies; general tips go in "Notes" at the end.
```

## What a good reply looks like

```
Posna musaka sa sočivom

Sočna posna musaka sa slojevima krompira i sočiva, za porodični ručak.

Porcije: 4
Priprema: 20 minuta
Kuvanje: 45 minuta

Sastojci:
Za fil:
- 200 g crvenog sočiva
- 1 glavica crnog luka, sitno seckana
- 2 čena belog luka
- 2 kašike ulja
- 1 kašičica slatke paprike
- so po ukusu
Za slojeve:
- 1 kg krompira (oljuštenog)
- 2 dl biljnog mleka

Postupak:
1. Sočivo operite i kuvajte 15 minuta.
2. Na ulju dinstajte luk 5 minuta, dodajte beli luk i papriku.
Fil može da se pripremi i dan ranije.
3. ...

Napomena:
- Može se pripremiti dan ranije.
```

Copy everything from the title down into the paste import. The limit is
40,000 characters. Each import counts against the household's monthly AI
allowance, and nothing is saved until the review screen. The lines it flags
are the ingredient matches it wasn't sure about.

If the unit seed or the parser's rules change, update the unit lists and
rules here to match.
