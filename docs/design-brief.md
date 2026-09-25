# Design brief — Kitchen Table

**What this file is.** A self-contained packet describing the app, its
constraints and its screens, written to be handed to a design tool
(claude.ai/design) that has never seen the codebase. It is *input*, not
doctrine.

`docs/DESIGN.md` remains the source of truth for what is true in the code
right now. This file restates parts of it for an outside reader, and adds
the content inventory and bilingual data that DESIGN.md has no reason to
carry. When the two disagree, DESIGN.md is right.

Written 2026-09-25, against `main` at `3578266`.

---

## 1. What the app is

A phone app for a family's recipes and their week's cooking. Android and iOS,
Flutter. It is not a social app, not a recipe discovery app, and has no feed —
it holds **your** recipes, the ones a household already cooks.

Four things it does:

1. **Recipes.** Enter by hand, or import by pasting text, a link, or a
   photograph of a cookbook page. An AI pass reads the import and matches each
   ingredient line against a catalog.
2. **Meal plan.** A week of meals, four slots a day — breakfast, lunch,
   dinner, snack. Leftovers can be planned forward.
3. **Shopping list.** Generated from the plan for a date range, grouped by
   shop category, with a collapsed "probably have" section for cupboard staples.
4. **Household.** All data is scoped to a household, not a user. Members are
   invited by a short code. Owner and member roles.

**Who uses it.** A household — realistically two adults, sometimes a parent
and a grown child in different countries. One of them writes recipes in
Serbian, one reads them in English, and the app translates between them. That
bilingual pair is the whole reason the app exists, and it is why the
constraints in §2 are not negotiable.

**Where it is used.** Standing in a kitchen with one hand free, and standing
in a shop. Reading, mostly. Tap targets and legibility at arm's length matter
more than density.

---

## 2. Constraints — fixed, not preferences

- **Two languages, one layout.** Serbian (`sr`) and English (`en`). Every
  screen renders in both. A component that fits English and breaks in Serbian
  is a bug. See §4 for the actual measurements.
- **Serbian in Latin script only.** Never Cyrillic. This is settled.
- **Light and dark are both real**, both followed from the system setting,
  neither is an afterthought. Every colour decision holds in both or it is not
  a decision.
- **Material 3 role system.** The app is Flutter and reads semantic roles off
  `ColorScheme` — `primary`, `onPrimary`, `error`, `errorContainer`,
  `onErrorContainer`, `tertiary`, `onTertiary`, `outline`, `onSurfaceVariant`,
  `surfaceContainerHighest`, `secondaryContainer`, `surface`, `onSurface`.
  **A design that names its own colours (`--brand-500`, "accent blue") cannot
  be consumed.** Any palette has to arrive mapped onto those role names, for
  both brightnesses.
- **Phone-first, portrait.** No tablet layout, no desktop, no landscape
  design work.
- **Bottom navigation, four tabs**, fixed: Recipes / Plan / List / Settings.
  Tab structure is not up for redesign.
- **No new runtime dependencies without asking.** A custom typeface means a
  new package or a bundled font file — it can be proposed, but it is a
  decision to be taken deliberately, not assumed. Same for an icon set or an
  animation library.

---

## 3. The design language today

All of this is **open to revision in the identity pass** unless marked fixed.

### Colour

One seed, `#7A5C3E` — a warm mid brown — through Material 3's
`ColorScheme.fromSeed`, once for light and once for dark. Roles the app
actually reads, and what each means *here*:

| Role | Used for |
|---|---|
| `primary` / `onPrimary` | The one emphasised action — save, confirm, generate. Also the "this is today" highlight on the meal plan. |
| `error` | Inline form validation text only. Never a background. |
| `errorContainer` / `onErrorContainer` | The offline banner's background and its text. |
| `tertiary` / `onTertiary` | The "look here" accent, distinct from primary and error: a 3px left-edge marker on an import line that needs a second look. Dark mode overrides the generated value to `#E7C17E` on `#422C00` because the generated one sat too close to `secondary` to read at 3px. |
| `outline` | Muted icon colour. Never body text. |
| `onSurfaceVariant` | Secondary text sitting beside primary text of the same size. |
| `surfaceContainerHighest` | Chip fill, and filled text-field fill — raised off the background without a border. |
| `secondaryContainer` | A selected filter chip's background, so "selected" reads as colour, not just an outline. |

No raw colour literal appears anywhere except where a role's value is defined.

### Type

Platform default — Roboto on Android, San Francisco on iOS. No custom font.
A screen picks a role for what the text *is*, never a raw size:

| Role | Size / weight | For |
|---|---|---|
| `titleLarge` | 22 / w600 | Screen and dialog titles |
| `titleMedium` | 17 / w600 | Section headings, app bar titles |
| `titleSmall` | 14 / w600 | Field labels, list tile titles |
| `bodyLarge` | 16 / w400 | Primary reading text — recipe steps, ingredient lines |
| `bodyMedium` | 14 / w400 | Default body copy, empty states |
| `bodySmall` | 12 / w400 | Captions, muted text |
| `labelLarge` | 14 / w600 | Buttons, chip labels |
| `labelMedium` | 12 / w500 | Small chip labels, tooltips |

### Spacing

`4 / 8 / 12 / 16 / 24 / 32`. Named `xs` through `xxl`. This scale is in use
across the app and there is no reason to change it — **treat it as fixed**
unless there is a strong argument.

### Shared components today

Only three, each generic and feature-agnostic: a centered error view, a
section heading, and an empty state (icon, title, optional body, optional
action). Everything else is per-screen. **This is the biggest gap** — there is
no card, no list row, no stat/meta line, no badge as a named component, so
every screen invents its own.

---

## 4. The bilingual constraint, measured

Serbian runs longer than English. Across all 255 UI strings the mean length
ratio is **1.12x**, the median **1.04x** — but the mean hides the problem,
which is that the worst cases cluster on short strings in tight places.

**Worst ratios, on strings that sit in buttons, chips and labels:**

| en | sr | ratio |
|---|---|---|
| `No connection.` | `Nema veze sa internetom.` | 1.71x |
| `Add a note instead` | `Dodaj napomenu umesto recepta` | 1.61x |
| `Google sign-in failed. Try again.` | `Prijava Google nalogom nije uspela. Pokušajte ponovo.` | 1.61x |
| `Remove photo` | `Ukloni fotografiju` | 1.50x |
| `No recipes match that.` | `Nema recepata koji se poklapaju.` | 1.45x |
| `Leave household?` | `Napustiti domaćinstvo?` | 1.38x |
| `Name your household` | `Imenujte svoje domaćinstvo` | 1.37x |
| `Choose a photo` | `Izaberi fotografiju` | 1.36x |
| `Sign in with Google` | `Prijavi se Google nalogom` | 1.32x |
| `Join` | `Priključi se` | 3.00x |
| `Bakery` | `Pekarski proizvodi` | 3.00x |
| `Nuts` | `Orašasti plodovi` | 4.00x |
| `Dairy` | `Mlečni proizvodi` | 3.20x |

**The longest strings in the app**, which set the worst case for body copy:

- en: `Everyone in {name} will lose access to its recipes, meal plans and shopping lists. This cannot be undone from the app.` (118)
  sr: `Svi članovi domaćinstva {name} izgubiće pristup njegovim receptima, planovima obroka i listama za kupovinu. Ovo se ne može poništiti iz aplikacije.` (147)
- en: `This recipe does not say how many it serves, so the shopping list cannot scale it.`
  sr: `Ovaj recept ne kaže za koliko porcija je, pa lista za kupovinu ne može da ga preračuna.`
- en: `Paste the whole thing -- ingredients, method, whatever else came with it. Extra text around the recipe is fine.`
  sr: `Nalepite ceo tekst -- sastojke, postupak, šta god je stiglo uz recept. Nije problem ako ima i dodatnog teksta oko recepta.`

**Serbian also has a `few` plural form** that English does not, so counted
strings have three branches instead of two and the middle one is often the
longest: `1 porcija` / `3 porcije` / `5 porcija`.

**Dates format differently, not just translate.** English reads
`Mon, Sep 14`; Serbian reads `pon 14. sep` — different field order and
punctuation, chosen by the locale, not by us. A day-column header that assumes
`Mon 1` will not hold.

**Design every mockup in Serbian first.** If it fits in Serbian it fits in
English. The reverse is how the one confirmed live defect got shipped — see
§5, recipe list.

---

## 5. Screen inventory

Four tabs, plus screens reached from them. Ordered by how much they matter.

### 5.1 Recipe list — tab 1, the front door

A searchable list of the household's recipes.

- **App bar:** title `Recipes` / `Recepti`, an add button with a menu —
  `New recipe` / `Novi recept`, `Paste a recipe` / `Nalepi recept`,
  `Import from a link` / `Uvezi sa linka`, `Photograph a page` /
  `Fotografiši stranicu`.
- **Search field:** `Search recipes` / `Pretraži recepte`. Matches title or
  tag, diacritic- and case-insensitive, in either language.
- **Filter row:** a horizontally scrolling row of chips — a `Favorites` /
  `Omiljeni` toggle first, then one chip per tag the household uses. Scrolls
  horizontally on purpose; a wrapping row would grow downward and eat the list.
- **Each row:** photo thumbnail (often absent), title, a `Draft` / `Nacrt`
  badge when unverified, and a meta line.
- **Empty states:** `No recipes yet.\n\nAdd one you know by heart.` /
  `Još nema recepata.\n\nDodajte jedan koji znate napamet.`, and
  `No recipes match that.` / `Nema recepata koji se poklapaju.`

**Known defect, confirmed on device.** The meta line is a dot-separated run
that does not survive Serbian:

- en: `4 servings · 10 min prep · 10 min cook · ★ 5` — fits on one line
- sr: `4 porcije · 10 min priprema · 10 min kuvanja · ★ 5` — breaks after
  `kuvanja`, orphaning `· ★ 5` on its own line

A dot-separated run is the wrong shape for content that changes length by
30%. **This needs a real answer, not a smaller font.**

### 5.2 Recipe detail — the most-read screen

One recipe, read-only. This is what someone reads while cooking.

- Photo header when there is one; many recipes have none.
- Title, description, a `Draft` / `Nacrt` badge, a `Machine translation` /
  `Mašinski prevod` badge when the text was translated.
- Meta line: servings, prep minutes, cook minutes, a 5-star rating.
- Favorite toggle, edit, and an overflow menu — `Add to meal plan...` /
  `Dodaj u plan...`, `Review translation` / `Pregledaj prevod`,
  `Delete recipe` / `Obriši recept`.
- **`Ingredients` / `Sastojci`** — the part that matters. Each line shows a
  quantity, a unit and a name. A line matched to the catalog renders the
  catalog's name in the reader's language; a line that matched nothing renders
  exactly what the cook typed, which is a fine outcome and must still look
  deliberate. An unmatched line carries a marker (`Not matched to an
  ingredient` / `Nije povezano sa sastojkom`). Some lines are marked
  `optional` / `opciono`.
- **`Steps` / `Koraci`** — numbered prose, `bodyLarge`. Read at arm's length,
  possibly with wet hands.
- Source attribution line when imported, with a muted icon.

**Design questions:** how a matched vs. unmatched ingredient line differs
without looking like an error; how quantities align when they are fractions
(`1/2`, `2 1/4`) rather than decimals; how a long step list stays navigable.

### 5.3 Meal plan — tab 2, the most structurally interesting

A week of meals. The largest and most complex screen in the app.

- **Two views:** `This week` / `Ova nedelja` and `Today` / `Danas`.
- Week navigation: previous / this / next.
- **Seven days × four slots** — `Breakfast` / `Doručak`, `Lunch` / `Ručak`,
  `Dinner` / `Večera`, `Snack` / `Užina`. Most slots are empty on any given
  week; the grid is sparse, and that sparseness should not read as broken.
- Today's column is highlighted with `primary`.
- Each entry is a recipe reference with a servings count, or a free-text note,
  or a **leftover** — `Leftovers: {title}` / `Ostaci: {title}` — pointing back
  at an earlier meal.
- Per-entry menu: open recipe, move up/down, move to another slot, plan
  leftovers, cooking for (servings), remove.
- A warning when something is planned twice in a fortnight:
  `Already planned recently` / `Već nedavno planirano`.

**Design questions:** how seven days fit a phone width at all — the current
screen is the app's biggest layout problem; how an empty slot invites a tap
without shouting; how a leftover reads as derived from another meal rather
than as its own thing.

### 5.4 Shopping list — tab 3

A generated snapshot, not a live document. **There are deliberately no
checkboxes** — a cook reading this in a shop is reading, not editing. Do not
design them in.

- A date-range bar: `This week` / `Ova nedelja`, `Next` / `Sledeća`,
  `Pick dates` / `Izaberi datume`.
- `Generate list` / `Napravi listu`, regenerate, and copy-to-clipboard.
- A generated-at line naming the dates it covers:
  `Generated {date} for {from} – {to}` /
  `Generisano {date} za {from} – {to}`.
- Items grouped by shop category — `Produce` / `Povrće`, `Dairy` /
  `Mlečni proizvodi`, `Meat` / `Meso`, `Bakery` / `Pekarski proizvodi`,
  `Pantry` / `Ostava`, `Spices` / `Začini`, `Fish` / `Riba`, `Fruit` / `Voće`,
  `Nuts` / `Orašasti plodovi`, `Beverages` / `Pića`, `Other` / `Ostalo`.
  **Note how much longer several of these are in Serbian** — up to 4x.
- A collapsed section at the bottom: `Probably have ({count})` /
  `Verovatno imate ({count})`, subtitled `Cupboard staples` /
  `Namirnice iz ostave` — things you likely already own.
- Empty state: `No list yet.` / `Još nema liste.` +
  `Generate one from what you have planned for these dates.`

**A real design problem, unique to this screen.** The list is a document
generated in *one* language and it stays in that language, while the chrome
around it — app bar, buttons, empty state, errors — follows the reader's
current language. So a list generated in English renders in English inside an
otherwise-Serbian app, on purpose. Right now **nothing on screen says so**,
and it reads as a translation bug. It needs a visual answer: some quiet,
non-alarming way of saying "this document is in English."

### 5.5 Import review

Where an AI-read recipe is checked before saving. Reached from three entry
screens (paste / link / photo), each a simple form.

- A progress state — `Queued...` / `U redu čekanja...`,
  `Reading the recipe...` / `Čitanje recepta...`, with
  `This takes a few seconds. You can leave and come back.`
- A confidence summary: `{matched} of {total} matched` /
  `Poklopljeno {matched} od {total}`, and
  `{n} worth a look before saving` / `{n} vredno pažnje pre čuvanja`.
- Editable title, ingredients and method, each ingredient line showing what it
  matched to.
- **Lines flagged for a second look carry a 3px `tertiary` left-edge marker.**
  This is the app's only use of `tertiary` and the reason dark mode overrides
  that role. Any new palette has to keep a third accent that reads at 3px in
  both brightnesses, distinct from both the primary action colour and the
  error colour.
- `Save recipe` / `Sačuvaj recept`, `Discard this import` / `Odbaci ovaj uvoz`.

### 5.6 Recipe editor

The app's longest form. Title, description, photo (camera or gallery),
servings, prep and cook minutes, a written-in language selector, a tested/draft
status, comma-separated tags, a repeating ingredient-line editor with
live catalog matching, and a repeating step editor. Inline validation:
`Enter a title.` / `Unesite naslov.`, `Whole number.` / `Ceo broj.`,
`At least {n}.` / `Najmanje {n}.`

**Design question:** the ingredient line editor is the hard part — quantity,
unit, name and a live match indicator on one phone-width row, in both
languages.

### 5.7 Settings, household, auth

- **Settings:** a short list — language toggle (`sr` / `en`, the only way to
  switch), household, sign out. Minimal, and fine as it is.
- **Household:** members with `Owner` / `Vlasnik` and `Member` / `Član` roles,
  invite codes with expiry (`Expires in {n} days` /
  `Ističe za {n} dana`), copy-code, revoke, rename, remove member, leave,
  delete household. Several destructive confirmations, which is where the
  longest body copy in the app lives.
- **Auth:** a single sign-in screen — Google only, one button. Then either
  `Name your household` / `Imenujte svoje domaćinstvo` or
  `Enter your invite code` / `Unesite svoj pozivni kod`. **This is the first
  thing anyone ever sees and it is currently three centered widgets on a blank
  scaffold.** It carries no identity at all.

### 5.8 Global chrome

- **Bottom nav, four tabs:** `Recipes` / `Recepti`, `Plan` / `Plan`,
  `List` / `Lista`, `Settings` / `Podešavanja`, each with an outlined and a
  filled icon.
- **Offline banner**, above the tab content on every tab:
  `You're offline — showing saved copies. Changes won't save.` /
  `Nema veze -- prikazane su sačuvane kopije. Izmene se neće sačuvati.`
  Drawn in `errorContainer` / `onErrorContainer`. It is a frequent state, not
  an exceptional one — it should inform without alarming.

---

## 6. What to design

### Pass 1 — identity

The visual language, before any screen layout.

Deliverable, and the form it has to take:

1. **A colour system, mapped to Material 3 role names**, for light *and*
   dark — every role in §3's table, with a hex value for each brightness. Not
   a palette with its own names. Include the third accent that must read at
   3px (§5.5).
2. **A type scale mapped to the eight roles** in §3, with size and weight.
   If it proposes a typeface, say which, and note that it is a new dependency
   to be approved rather than assumed.
3. **Shape and elevation**: corner radii, whether cards carry elevation or
   only a surface-tone difference, border treatment.
4. **A sample of the identity applied** — ideally the sign-in screen and one
   recipe card, in Serbian, in both brightnesses.

Tone to aim for: warm, domestic, legible. This is a family's handwritten
recipe box, not a restaurant app and not a productivity tool. The current
brown seed is the right *direction*; whether it is the right value is open.

### Pass 2 — layouts, once the identity has landed

Per surface, in this order: recipe list + detail, meal plan, shopping list,
household + settings, auth + onboarding.

Two specific problems carry over and should be solved, not inherited:

- The recipe meta line that breaks in Serbian (§5.1).
- Seven days of four slots on a phone width (§5.3).

And one component vocabulary question: what shared components should exist
that do not (§3) — a card, a list row, a meta line, a badge.

---

## 7. How the output gets used

The design is a **target**, not code. It gets translated by hand into Flutter
`ThemeData` and widgets. So what is useful coming back is:

- Named values (hex, sp, dp) against role names, not CSS.
- Layout intent and spacing in the 4/8/12/16/24/32 scale.
- Mockups rendered **in Serbian**, in **both brightnesses**.

What is not useful: HTML/CSS components, a framework-specific token file, or
anything that assumes a web layout.

Every design that lands gets checked on a physical Android device across
`sr` × `en` × light × dark before it is considered done. Nothing automated
catches a layout that only fits English.
