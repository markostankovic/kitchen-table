# Journal — Phase 3

Verbatim build history for Phase 3 — Serbian / English, moved out of `docs/ROADMAP.md` so the roadmap stays a forward-looking index. Nothing here is authoritative going forward -- see `docs/decisions/` for standing rules, `docs/STATE.md` for current status.

---

## Phase 3 — Serbian / English

### Part 1 — The locale toggle, and the app chrome in two languages

**Status: complete.** Decisions taken during it: D77.

`flutter_localizations` + ARB files, and the locale toggle they exist to
serve — scoped to the app's chrome, not yet to recipe content.

- `lib/core/l10n/arb/app_sr.arb` (template) and `app_en.arb`, generated to a
  committed `lib/core/l10n/generated/` via `l10n.yaml`
- `core/l10n/app_locale.dart`: `appLocaleProvider`, derived from
  `ownProfileProvider.value?.locale`, falling back to Serbian pre-auth
- `AuthRepository.updateLocale`, writing straight to `profiles.locale` — no
  migration needed; the column, its check constraint and
  `profiles_update_own` have existed since migration 2 and nothing had ever
  written to them
- A *Language* segmented button on Settings (*Srpski* / *English*, never
  translated — a language's own name is not chrome)
- Localized: the bottom nav, each tab's own AppBar title (sharing the nav
  label's key), the Settings screen, and sign-in / verify-OTP

**Done when:** switching the language in Settings changes the app's chrome
between Serbian and English immediately, and the choice survives a
force-stop because it lives in `profiles.locale`, not in memory. — **Met**,
verified on the Android emulator against the local stack: a fresh sign-in
renders Serbian with no profile loaded yet (the pre-auth default); switching
to English in Settings changed the nav bar, every tab's AppBar title and the
Settings screen itself immediately, with no restart; force-stopping and
relaunching came back English, confirmed directly against
`profiles.locale`; switching back to Serbian reversed it; and toggling the
language while offline failed loudly with a SnackBar rather than silently
succeeding, since writes are online-only (D12) and this one is no exception.

Everything else — recipes, import, meal plan, shopping list, households —
stays English until the part that owns each of them localizes it in turn,
the same rhythm every phase here has used.

### Part 2 — `recipe_translations`, `translate-recipe`, and the recipe read in the reader's language

**Status: complete.** Decisions taken during it: D78–D81.

`recipe_translations` + RLS, the `translate-recipe` Edge Function, and the
recipe detail screen reading title/description/steps in the reader's locale
-- ingredient and unit names included, closing a gap that had existed since
Phase 1c: the bilingual catalog (D1) had only ever been asked for Serbian,
because nothing anywhere in the app had ever passed anything else into
`RecipeRepository.fetchDetail`'s `locale` parameter. **Review flow is
deliberately out** -- `reviewed_by` and `reviewed_at` ship in this part's
migration, unreachable, the same way `recipes.image_path` (D35) and
`leftover_of_entry_id` (D51) shipped ahead of their writers.

- Migration 17: `recipe_translations`, a child table in the D24 sense (no
  `household_id`, hard delete, cascades with its recipe) that nonetheless
  keeps `created_at`/`updated_at` because a translation is reviewed and
  regenerated in place rather than being step-shaped and inert (D78).
  `recipe_translations_touch_recipe()` -- an after-trigger on
  `meal_plan_entries_touch_plan()`'s own shape -- is what makes a translated
  recipe reach the existing recipe delta fetch with no new cache table:
  `RecipeCache.data` already stores the whole PostgREST row verbatim, and
  `recipe_translations` now rides along inside it, embedded
  (`AppDatabase.schemaVersion` moved to `4` for exactly this reason -- a
  change to the blob's shape, not to a table's columns). `save_recipe_translation`
  refuses an unknown locale and refuses translating into the recipe's own
  `original_locale`, both `security invoker`, both mirroring
  `replace_recipe_lines`'s guard-then-upsert shape
- `translate-recipe`: synchronous, no `import_jobs` row -- one model call
  with no confirm gate in this part, on `match-ingredients`'s shape rather
  than `import-text`'s (D79). `_shared/translate.ts` sends the model no
  ingredient lines at all (they render from the catalog, never per recipe),
  requires Latin-script Serbian as a stated rule rather than an assumption,
  and asks for each translated step's SOURCE position back as an alignment
  key -- `alignSteps` validates the returned positions and refuses, as a
  billed `AiFailure`, rather than silently reordering or dropping a step
  (D80). Idempotent, and translating into a recipe's own original locale
  costs no model call at all
- `RecipeDetail` gains `readingLocale` and `translations`, plus
  `RecipeIngredient.resolvedName`'s pattern one level up -- `displayTitle`/
  `displayDescription`/`displaySteps`/`canTranslate`/
  `isShowingMachineTranslation`, one definition of "which words does this
  reader see" so the AppBar, the body and any later screen cannot disagree
- The detail screen: a *Translate to &lt;language&gt;* overflow item, shown
  only when the reading locale differs from the recipe's own and no
  translation exists yet; a *Machine translation* chip beside the existing
  *Draft* chip; unit names now render in the READER's locale rather than the
  recipe's own `original_locale`, the same fix one column over. This is also
  the recipes feature's first screen to read `AppLocalizations` (D77's
  rhythm, one screen at a time) -- the list and the editor still render in
  English
- D81, the literal fix underneath the feature: `RecipeDetailScreen` and
  `ShoppingListEditor.generate()` now read `appLocaleProvider` and pass it
  through, instead of the hardcoded `'sr'` both had carried since their own
  parts shipped -- `shopping_lists.locale` exists precisely so a generated
  list does not render half-translated after a locale switch (migration
  16's own comment), and had been recording a falsehood the whole time.
  Left alone deliberately: `RecipeEditor.build`'s own `fetchDetail` still
  defaults to `'sr'`, named rather than hidden below

**Done when:** one recipe entered in Serbian reads correctly in English,
ingredient names included, without a second recipe row existing. -- **Met**,
verified against the local stack: `make check` clean in full (`dart
analyze`, `tool/check_layers.dart`, 368 Dart tests, `deno check`/`lint`/`fmt`,
155 Deno tests, and `rls_recipe_translations_test.sql` alongside the other
16 SQL suites, all passing). `rls_recipe_translations_test.sql` asserts the
Done-when itself in the one place a SQL suite can reach it: a Serbian recipe
translated into English reads back its English title through
`recipe_translations`, `ingredient_display_names(..., 'en')` still answers
`brašno` as `flour` on the same recipe's matched line, and
`select count(*) from recipes` for that title stays at exactly 1 throughout
-- no second recipe row, at any point.

Still open, and named here so it is not rediscovered: the emulator walk
every other part in this project has closed with (translate a real recipe,
force-stop, airplane mode, relaunch, confirm it renders from the cache) has
not been run -- this part's verification stopped at the local Postgres
stack and the Dart/Deno test suites. `RecipeEditor.build` reading a hardcoded
`'sr'` (above) is the other open item.

### Part 3 — The translation review flow

**Status: complete.** Decisions taken during it: D82–D86 (plus D87, a
finding rather than a build decision — see below).

Closes the first bullet of Phase 3's old "Still to build" list, and both
items part 2 left open by name: the emulator walk, and `RecipeEditor.build`'s
hardcoded `'sr'`.

- Migration 18: `review_recipe_translation(recipe, loc, new_title,
  new_description, new_steps)` — a sibling of `save_recipe_translation`, not
  a parameter on it, because the two want opposite things from the same
  columns on the same row: the sibling's own `on conflict` resets
  `is_machine_generated`/`reviewed_by`/`reviewed_at` on every re-translation,
  and a review wants the opposite (D82). Updates only, never inserts — review
  edits a translation that exists, on the same door `save_recipe_translation`
  already answers for a locale that doesn't. Refuses a dropped, added or
  renumbered step by checking the incoming positions against the ROW's own
  (not `recipe_steps`'), which is deliberately not treated as rule 6's fourth
  cross-language pair (D82 says why). `security invoker`, no new RLS policy —
  the existing UPDATE policy already covers it. `reviewed_by` is `auth.uid()`,
  never a parameter (D83, on `MatchMethod.manual`'s and
  `link_ingredient_alias`'s own precedent for what a human decision means)
- `RecipeRepository.reviewTranslation` / `RemoteRecipeDataSource
  .reviewTranslation` — online-only (D12), no cache write of its own: the
  trigger migration 17 already has touches the parent recipe, so the
  ordinary `recipeDetailProvider` invalidation re-reads and re-caches the
  whole blob, same as `translate` above it
- `RecipeDetail.canReview` / `.isReviewedTranslation` — `canReview`'s own
  comment states the invariant `canTranslate` and `canReview` are never both
  true at once, and are never both false while reading a foreign locale
- `TranslationReviewDraft` (`domain/`) and `TranslationReviewer`
  (`application/`, on `RecipeEditor`'s precedent — loads once, never watches
  `recipeDetailProvider`) — steps are keyed by position, not a synthetic
  local id: `RecipeDraft`'s rows are added, deleted and dragged, and this
  screen's are not, so position already is the identity (D84)
- `TranslationReviewScreen` — every field pairs the recipe's own original
  text, read-only, directly above the editable translation for it; a fixed
  number of step fields with no add, remove or reorder; no ingredient editor
  anywhere on the screen (D84, D1, D80). New route,
  `/recipes/:recipeId/review`, nested under the detail page so Back returns
  there — no `locale` parameter, the reviewed locale is the reading locale
  (`appLocaleProvider`), the same one-place-per-concern rule D77 and D81
  already established. This feature's second localized screen
- Detail screen: the overflow's *Review translation* item appears exactly
  when `canReview` does, right after where *Translate to …* would be — the
  two are mutually exclusive, so this is also the entire mechanism for "no
  retranslate after a review" (D85). The *Machine translation* chip needed
  no code change to disappear once reviewed: it already reads
  `isShowingMachineTranslation`, which the review sets false. No *Reviewed*
  chip, and the reviewer's name is not shown — this app's chips are caveats,
  not endorsements, and naming the reviewer would cost a `profiles` join in
  `recipeDetailEmbed` that changes the cached blob's shape for a line nobody
  has asked for (D83, priced rather than built)
- `RecipeEditor.build` now reads `appLocaleProvider` (`ref.read`, not
  `ref.watch` — watching would discard whatever the cook had typed on a
  language switch mid-edit) instead of `fetchDetail`'s bare `'sr'` default,
  closing D81's own named consequence: an ingredient chip was rendering in
  Serbian while editing an English recipe. `IngredientLineField`'s own
  `locale:` — the search locale, and the locale a new alias is written in —
  stays `draft.originalLocale`, untouched: display and write are different
  concerns on this screen (D86)
- `shopping_list_screen.dart`'s `_ItemTile` now renders count units in the
  LIST's own stored `locale`, not the reader's current one and not the
  `formatItemQuantity` default it had silently been falling through to since
  D9 shipped — the same class of bug D81 named, one layer over, caught in
  this session rather than left for a later one to rediscover
- Backfilled: part 2 shipped `RecipeDetail`'s five translation getters with
  no Dart test anywhere. `recipe_detail_translation_test.dart` covers all
  seven (the five plus this part's two) across every reading-locale state,
  including the `displayDescription` null-vs-fallback case part 2's own
  comment was written for

**Done when:** a machine translation can be corrected and approved by a
human, and the app shows that it happened. -- **Met**, verified against the
real model (a live `translate-recipe` call, not a stub) on the Android
emulator, not only against the local Postgres stack and the 31 new Dart
tests (`make check` clean in full: `dart analyze`, `tool/check_layers.dart`,
399 Dart tests, `deno check`/`lint`/`fmt`, 155 Deno tests unaffected since no
Edge Function changed, and 19 SQL suites including the new
`review_recipe_translation_test.sql`).

A real Serbian recipe (*Palacinke*, two steps) was translated to English for
real -- *Pancakes*, both steps translated idiomatically, `is_machine_generated
= true` -- and the *Machine translation* chip appeared. Opening Review showed
the Serbian original stacked above each of the three editable fields, exactly
as designed; editing the title to *Crepes* and saving flipped the database
row to `is_machine_generated = false`, `reviewed_by` equal to the signed-in
profile's id and `reviewed_at` set, confirmed by direct query, not just by
the screen. The chip was gone with no further navigation, and the overflow
menu now offered *Review translation* and nothing else -- no retranslate
option, D85 working through the real app. Switching the profile back to
Serbian showed the recipe's own original text and neither menu item, proving
`canReview` gates on the READING locale and not merely on a translation's
existence. Opening the editor on the reviewed recipe while reading English
rendered the ingredient chip as *flour*, not *brašno* -- D86 confirmed live,
the fix this session made to `RecipeEditor.build`.

**The walk also found a real gap, named here rather than left to be
assumed: D87.** Force-stopping the app with the emulator's network disabled
and relaunching cold left the Recipes tab spinning for several minutes
before finally showing `NetworkFailure: No connection` -- not a stale-copy
line, an outright failure, for a recipe whose cache row was confirmed
present and correctly keyed by pulling the on-device SQLite file directly
mid-walk. The cause is one layer up from anything Phase 2 built:
`currentHouseholdIdProvider` has no cache and no client-side timeout, every
household-scoped screen awaits it before touching its own cache at all, and
every prior offline "Done when" in this project was verified from an
already-warm session rather than a cold, offline-from-first-frame one. Every
offline claim this project has made stands for a warm session; none of them
has been proven for a cold one until this walk, and D87 is what keeps that
distinction from quietly disappearing. Re-enabling the network and
relaunching recovered cleanly -- the household resolved, the cached recipe
list rendered its one entry, chrome and content both correct.

### Part 4 — The failure vocabulary, the script fix, and the recipes feature

**Status: complete.** Decisions taken during it: D91-D92.

The "remaining screens" bullet above is ~234 hardcoded English strings
across five features -- three to four times any prior part -- so it splits
three ways rather than landing in one commit the way D77 already warned
against for the chrome alone. This part took the two mechanisms every later
part needs, plus the one feature (recipes) and the `core/` widgets it pulls
in.

Two things were found while planning it, both existing rather than
introduced, and both closed here because the later parts would otherwise
each rediscover them on their own screens.

**D91: `Locale('sr')` alone renders Flutter's OWN chrome in Cyrillic.**
Verified against the pinned SDK: the `'sr'` case in
`generated_material_localizations.dart` picks the Latin bundle only when
`scriptCode == 'Latn'`, and otherwise falls through to the Cyrillic one. The
text-selection toolbar, the back-button tooltip, a date-range picker's own
labels -- every string this app does not supply itself -- had been Cyrillic
since Phase 3 part 1, invisible because the 48 ARB-backed strings this app
does own were always correct. Fixed in one place, on D77's own precedent:
`appLocaleProvider` (`core/l10n/app_locale.dart`) now returns `srLatn`
(`Locale.fromSubtags(languageCode: 'sr', scriptCode: 'Latn')`) instead of a
bare `Locale('sr')`, and `appSupportedLocales` replaces
`AppLocalizations.supportedLocales` everywhere a `MaterialApp` is built --
the generated list carries the scriptless entry, and Flutter's locale
resolution would otherwise hand it straight back unresolved.
`profiles.locale` still stores the bare code; CLAUDE.md's "Locale codes are
`sr` and `en`. Nothing else." is about that column, and every
`appLocaleProvider` consumer reads `.languageCode`, unaffected.

**D92: the failure vocabulary.** ~43 UI sites rendered `AppFailure.message`
raw -- English, unlocalized, no matter which language the rest of the
screen was in. `supabase_failure.dart`'s own comment had already named the
fix: *"it lets Phase 3 localize by code with the server's text as the
fallback."* `FailureCode` (`core/error/app_failure.dart`, pure Dart) is a
34-value enum, one nullable field on `AppFailure` alongside `message`, each
variant defaulting its own code the way it already defaults its message.
`core/error/failure_l10n.dart` -- the sibling file allowed to import
Flutter, on `core/l10n/app_locale.dart`'s own precedent -- renders a code
through the ARB with `localizedFailureMessage`/`localizedErrorMessage`, and
falls back to `message` verbatim when `code` is null. That null case is
deliberate, not an oversight: `quota_exceeded` has to name whose allowance
ran out, `url_not_allowed` deliberately says nothing about why (D45),
`empty_input`/`ai_failed` differ per caller, and Postgres/GoTrue prose is an
unbounded set no client vocabulary can cover -- so those keep the server's
sentence, and everything else gets a code.

Planning this also found nine Edge Function slugs
(`fetch_failed`, `not_html`, `page_too_large`, `image_too_large`,
`job_not_found`, `job_already_done`, `job_not_parsed`, `no_recipe_found`,
`code_generation_failed`) that `supabase_failure.dart`'s switch never
handled at all, silently degrading to `UnknownFailure` with no message --
"that page is too large" was reaching the cook as "Something went wrong."
All nine now have arms and codes.
`test/core/supabase/supabase_failure_test.dart` closes the gap for good: it
parses every `HttpError(<status>, "<slug>"` out of `supabase/functions/**/
*.ts` (the `AiFailure` subclass included) and asserts each has an arm,
rather than trusting the two files to stay in sync by inspection.

The known trap in this design, named so it does not get rediscovered: a
call site that passes a custom `message:` and forgets `code:` silently
keeps the variant's DEFAULT code and renders the wrong sentence, with no
compile error. Three cold-cache throw sites and the `TimeoutException` arm
were exposed by exactly this. Not preventable in Dart -- caught instead by
three `*_repository_offline_test.dart` assertions moved from `.message` to
`.code`, which fail together if a future edit misses one.

- `FailureCode` + `localizedFailureMessage`/`AppFailureL10n.localized` --
  **done**, wired into every application/data throw site (19) and every
  presentation call site with one (~43, across all five features and the
  shared `core/` picker widgets), not just recipes'
- `sr_Latn` -- **done**, `appLocaleProvider` and `appSupportedLocales`
- Recipe screens and the `core/` widgets they force --  **done**:
  `offline_banner.dart`; `recipe_detail_screen.dart`'s last 5 literals;
  `recipe_list_screen.dart` (13); `recipe_edit_screen.dart` (~28, the
  largest); `core/ingredients/widgets/` (`ingredient_line_field.dart`,
  `ingredient_match_chip.dart`, `ingredient_picker_sheet.dart`); `core/
  recipes/widgets/recipe_picker_sheet.dart`
- This repo's first ICU plurals -- `recipeServingsCount` (Serbian
  one/few/other, which English's plain `s` suffix does not reach), plus
  `snackSlotCount` and `ingredientsMatchedCount` added now even though their
  own screens are parts 5-6's job, so the plural vocabulary is complete
  before either part needs a new form
- The Serbian sample hints (`ingredient_line_field.dart`'s example line, the
  match chip's "No match"/suggestion labels, the ingredient picker's
  prompts) are looked up by the RECIPE's own language
  (`lookupAppLocalizations(Locale(widget.locale))`), never the reader's
  chrome locale -- content beside catalog names is never translated per
  recipe (D1), the same reasoning D86 already applied one screen over.
  Failure messages inside those same widgets stay on the reader's chrome
  locale: content follows the recipe, chrome and failures follow the reader
- `make gen-l10n` folded into the `gen` Makefile target, and a new
  `l10n-check` target (wired into `check`) regenerates and diffs
  `lib/core/l10n/generated/` -- the same drift guard part 6b built for
  `display_names_test.sql`, now covering the l10n generator. Verified it
  actually catches drift, not just that it runs

**Done when:** the failure vocabulary is complete and contract-tested for
every feature, Serbian renders Latin everywhere including strings this app
does not own, and the recipes feature reads entirely in the reader's
language including when something goes wrong. -- **Met**, verified against
the local stack (`make check` clean in full -- `dart analyze`,
`tool/check_layers.dart`, 468 Dart tests, up from 417; `deno check`/`lint`/
`fmt`; the Deno suite unaffected since no Edge Function changed; `seed-check`;
all 19 SQL suites; `l10n-check` finding no drift) and end to end on the
Android emulator against the local stack, not only in tests.

Signed in for real (OTP read from Mailpit), created a household, and worked
through the recipes feature from a cold build of this part's changes.
`uiautomator`, not eyeballed coordinates, located every element precisely.
The FAB menu read *Novi recept / Uvezi sa linka / Nalepi recept / Fotografiši
stranicu* -- all four keys -- and the empty state *Još nema recepata.* /
*Dodajte jedan koji znate napamet.* Opening the editor showed every field
label (*Porcije*, *Napisano na* with *Srpski*/*English* left untranslated,
*Status* with *Nacrt*/*Isprobano*, *Oznake*/*Odvojene zarezima*) and the
ingredient hint *2 šolje glatkog brašna* -- looked up by the recipe's own
language, confirmed by typing `krompir` and watching the suggestion chip
read *krompir?*, then a nonsense string and watching it read *Nema
poklapanja*; tapping that chip opened the picker with *Koji sastojak je
„zzzxxq"?*, *Ništa u katalogu se ne poklapa.*, and *Napravi „zzzxxq"* /
*Dodaje ga u katalog domaćinstva* -- correct Serbian typographic quotes
(„…", not "…") throughout. Saving a 4-serving recipe and opening its detail page showed
*4 porcije* -- Serbian's `few` category, not `other` -- then switching the
Settings language toggle to English re-rendered the same page live as
*4 servings*, `recipeServingsCount`'s `other` form, with the whole chrome
(*Draft*, *Ingredients*, *Steps*, *No steps yet.*) following in the same
frame.

**D91 confirmed directly, not only by the widget test that models it.**
Long-pressing a word in the sign-in screen's email field -- before any of
this part's fix existed, this exact gesture would read Cyrillic -- opened the
Latin-script selection toolbar: *Iseci / Kopiraj / Deli / Izaberi sve*.
`test/core/l10n/app_locale_test.dart`'s own assertion
(`MaterialLocalizations.of(context).pasteButtonLabel == 'Nalepi'`) is the
repeatable form of exactly this; both agree.

Not walked on-device: a live failure message and the offline banner under a
real network failure (D92's other half). Toggling the emulator's radios did
not actually sever its route to the local stack, and forcing it further was
not worth the detour -- `failure_l10n_test.dart`'s fallback-and-precedence
cases and `supabase_failure_test.dart`'s full slug table already exercise
every sentence this mechanism can produce; only the "does a real
`SocketException` reach the screen" wiring is unconfirmed live, and that
wiring predates this part.

---

