# Ingredient matching

This is the product's differentiator. A shopping list that says
`brašno — 800 g` once, from a Serbian recipe and an English one, is the demo
that sells the app. Everything here exists to make that work.

## The pipeline

Given a raw ingredient line, resolve it to an `ingredient_id`. Tiers run in
order; stop at the first hit.

```
raw_text: "2 šolje glatkog brašna, prosejano"
   │
   ├─ 1. LINE PARSE  → qty 2, unit 'šolja', name "glatko brašno", note "prosejano"
   │
   ├─ 2. EXACT       normalize_text(name) == ingredient_names.normalized_name
   │                 (locale is a TIE-BREAK, never a filter -- `flour` must
   │                 still reach brašno and render in Serbian)
   │                 → 'exact' if the ingredient's display name matched,
   │                   'alias' if any other spelling did. Both confidence 1.0
   │
   ├─ 3. FUZZY       similarity(normalized, candidates) > 0.4, pg_trgm
   │                 → 'fuzzy', confidence = similarity
   │                 Only auto-accept above 0.75. Below that, present as a
   │                 suggestion on the confirm screen.
   │
   ├─ 4. LLM         batched: ALL unresolved lines of a recipe in ONE call
   │                 → 'llm', confidence from the model's own signal
   │
   └─ 5. CREATE      new ingredient, is_verified = false
                     → 'llm' or 'manual' depending on origin
```

**Every resolution writes back.** When tier 3, 4, or 5 resolves a string that
wasn't already an alias, insert an `ingredient_names` row for it. That string
now resolves at tier 2 forever, for every household. The cost curve drops fast
because ingredient strings are Zipf-distributed — a few hundred strings cover
most of everything anyone will ever write.

**The confirm screen is tier 0 in effect.** When a human accepts or corrects a
line (D8), write the alias with `source = 'user'`, `match_method = 'manual'`,
confidence 1.0. Human-confirmed links are never overwritten by a later
re-matching pass.

## Line parsing

**Implemented in `lib/features/ingredients/domain/ingredient_line_parser.dart`,
in pure Dart (D31).** Not in Postgres: it touches no data, and a round trip per
line would cost the 1c line editor its responsiveness and break offline entry
in Phase 2. Phase 1d adds `supabase/functions/_shared/parse_line.ts` for the
importers, asserted against the same fixture.

`test/fixtures/ingredient_lines.json` is the contract, in exactly the role
`normalization.json` plays below. Add a case every time a real recipe line
surprises you; every implementation is then held to it.

The parsed `name` is the **literal remainder**: `2 šolje glatkog brašna` yields
`glatkog brašna`, in the genitive. De-inflecting it would be stemming, which D6
rejects — landing the inflected form is what the seeded aliases and the trigram
tier are for.

Do this deterministically before reaching for a model. Most lines are
`[quantity] [unit] [name][, note]`.

- Quantities: `2`, `1/2`, `1 1/2`, `1½`, `2-3`, `2–3`, `2 - 3`, `½`, `pola`,
  `par`, and the Serbian decimal comma `1,5` → 3/2.
  Parse to `qty_num`/`qty_den`; ranges fill `qty_max_*`. Unicode fraction
  characters map to fractions. `pola` → 1/2.
  **The decimal comma is a trap**: notes split on the first comma, so the split
  has to skip a comma flanked by digits or `1,5 dl vode` becomes quantity 1 and
  the note `5 dl vode` — wrong by a factor of ten, silently.
  `po` is deliberately NOT parsed as "half": it far more often means "each",
  and a wrong number is worse than the null parse rule 3 already supports.
- Units: match against `unit_names.normalized_name`. Serbian units are often
  inflected or abbreviated — `kašika`, `kašike`, `kašiku`, `kš`, `k.`, `šolja`,
  `šolje`, `dl`, `gr`, `kom`, `komada`. Seed aliases generously.
- Notes: everything after the first comma, plus parenthesised text.
  `sitno seckan`, `prosejano`, `na sobnoj temperaturi`, `po ukusu`.
- Optional markers: `opciono`, `po želji`, `po ukusu`, `optional`, `to taste`,
  `if desired`. These become a note and set `is_optional`.
  `po ukusu` is also seeded as a unit with family `other`, but where recipes
  actually write it — trailing the line — it is a note, which is what lets
  `so po ukusu` resolve to *so*.

If the deterministic parse fails, keep `raw_text` and leave structured fields
null. That is a supported state, not a bug.

## Normalization

Single definition, mirrored in three places (Postgres, Dart, Deno). Order
matters:

1. lowercase
2. Cyrillic → Latin, **digraphs first**: њ→nj, љ→lj, џ→dz, ђ→dj, ћ→c, ж→z,
   then the single-character map
3. Latin diacritics: č→c, ć→c, š→s, ž→z, **đ→dj**
4. collapse whitespace, trim

Step 3's đ→dj is why `unaccent` alone is not enough — it produces `d`, which
splits *đuveč* from someone typing *djuvec*.

`test/fixtures/normalization.json` is the contract. Minimum cases:

```json
[
  ["ćufte", "cufte"],
  ["Ćufte", "cufte"],
  ["ћуфте", "cufte"],
  ["đuveč", "djuvec"],
  ["djuveč", "djuvec"],
  ["Đuveč", "djuvec"],
  ["šargarepa", "sargarepa"],
  ["Njegoš", "njegos"],
  ["  bela   pavlaka ", "bela pavlaka"],
  ["ЖЕЛЕ", "zele"]
]
```

Add a case every time a real string surprises you.

## Serbian inflection

No stemmer (D6). Two mitigations:

**Trigram threshold.** `šargarepe` vs `šargarepa` scores well above 0.4.
`brašna` vs `brašno` likewise. This absorbs most case endings.

A **prefix arm** sits alongside it, and autocomplete does not work without one:
`similarity('sargarepa', 'sarg')` is 0.36, below the threshold, so four letters
of a nine-letter word would return nothing. Prefix hits report their true
similarity rather than an inflated confidence, so they stay suggestions instead
of auto-accepting.

**Explicit aliases on the curated core.** For the ~200 seeded ingredients, add
the forms that actually appear in recipe text — usually nominative, genitive
singular, and genitive plural, since recipes say *dve kašike brašna* and
*200 g šargarepe*.

Watch for the failure mode where a short word fuzzy-matches the wrong thing
(*so* / *soja*, *luk* / *luka*). Enforce a minimum length of 4 characters before
the fuzzy tier fires; shorter strings must hit exact or go to the LLM.

**All three constants — the 4-character floor, the 0.4 threshold and the 0.75
auto-accept line — live only inside `search_ingredients` (D31.)** It returns
`auto_accept` already computed. Do not reintroduce any of them in Dart.

## Catalog seeding

Seed ~200 ingredients as `is_verified = true`, weighted heavily toward what a
Serbian household actually cooks with. Everything else auto-creates.

**Built.** `supabase/seeds/ingredients.csv` (200 rows) and
`supabase/seeds/ingredient_names.csv` (618 rows), turned into a generated
idempotent migration by `tool/gen_ingredient_seed.dart` (`make seed`). Not
`supabase/seed.sql`, which never reaches production — see D29.
`tool/seed_csv.dart` validates the CSVs before any SQL is generated, and
`test/features/ingredients/seed_csv_test.dart` runs the same checks under
`flutter test`.

Seed format, a CSV per ingredient plus a CSV of names:

```csv
# ingredients.csv
key,parent_key,category,default_unit_family,is_pantry_staple
brasno_glatko,brasno,pantry,mass,false
brasno,,pantry,mass,false
kajmak,,dairy,mass,false
pavlaka_kisela,,dairy,volume,false
so,,pantry,mass,true

# ingredient_names.csv
ingredient_key,locale,name,is_display_name
brasno_glatko,sr,glatko brašno,true
brasno_glatko,en,all-purpose flour,true
brasno_glatko,sr,brašno glatko,false
brasno,sr,brašno,true
brasno,sr,brašna,false
brasno,en,flour,true
kajmak,sr,kajmak,true
kajmak,en,kajmak,true
```

Serbian-specific items no external dataset will have — seed these by hand:

> kajmak, pavlaka (slatka / kisela), ajvar, pinđur, urnebes, vegeta, suvo meso,
> slanina, kulen, sudžuk, čvarci, prezle, mladi sir, feta/beli sir, kore za
> pitu, gotova kora, aleva paprika (slatka / ljuta), šećer u prahu, prašak za
> pecivo, kvasac (suvi / sveži), gustin, mineralna voda, rakija, seckani
> paradajz, paradajz pire, začin C, majčina dušica, vlašac, celer list

Also seed the boring high-frequency ones: flour, sugar, salt, eggs, milk,
butter, oil, water, onion, garlic, potato, carrot, tomato, pepper, rice, pasta,
chicken, beef, pork, cheese, yogurt.

Mark as `is_pantry_staple = true`: salt, water, black pepper, cooking oil,
sugar. Households override via `household_pantry_prefs`.

## Re-matching later

Because every row carries `match_method` and `match_confidence` (D7), improving
the matcher is a background job, not a migration:

```sql
-- safe to re-run: never touches human decisions
update recipe_ingredients
set ...
where match_method in ('fuzzy','llm')
  and match_confidence < 0.9;
```

This is the reason those columns exist. Do not drop them.

## Quality checks worth having early

- Count of `is_verified = false` ingredients used in more than one recipe →
  these are merge candidates.
- Count of `recipe_ingredients` with null `ingredient_id` → matcher coverage.
- Distribution of `match_method` → how much the LLM tier is actually costing.

A simple admin screen showing these three is worth building in Phase 2.
