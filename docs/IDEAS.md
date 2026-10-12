# Ideas

Raw future product ideas — not vetted, not prioritized, not committed to.
Capture here so a fleeting thought isn't lost; nothing here is a promise to
build it.

Not `docs/ROADMAP.md`'s numbered phases (already-ordered, committed future work) and
not `docs/decisions/OPEN.md` (technical follow-ups tied to a specific
decision id). An idea only becomes real work when a human copies it into
`docs/ROADMAP.md` by hand and deletes the line here.

---

- collections (grouping recipes; tags themselves already exist)
- Scale recipe
- Stale shopping-list warning
- add Readme
- add more snacks in Meal plan - between main
- 2026-09-25 — Shopping list quantities with a Serbian decimal comma (`1,5 kg`, not `1.5 kg`) when the list is in Serbian
- 2026-09-25 — Shopping list count units read awkwardly (`3 kom jaje`); drop or rephrase `kom` for countable items
- 2026-09-25 — Genitive ingredient names on the shopping list (`500 g kiselog kupusa`, as the Garden mock shows); needs a genitive form in the ingredient catalog
- 2026-09-29 — Rename the launcher label to "Za stolom" (proposed alongside the part 10b logo, not adopted; the label stays "Kitchen Table" in both locales, D130).
- 2026-10-12 — Multi-language app, English by default: user picks their native language from a dropdown (Settings + first-launch/sign-in picker, names shown in their own language, e.g. "Srpski", "Deutsch"; design to be requested from Claude Design). Scope: Latin-script European languages only (keeps D4). Split "app language" from "content languages": (1) UI chrome — any curated Latin-script language via new ARB files, flip template to app_en.arb, pre-auth default English (reverses D77) — one slice; (2) replace hard-coded check (locale in ('sr','en')) on profiles, ingredient_names, unit_names, recipe_translations, tag names with a shared locales list/table, via new migrations; (3) later, per language on demand: content support — ingredient names, units, line parsing (D6 is Serbian-tuned), and recipe translation into the reader's locale on demand instead of "both locales at once" (D109). Touches CLAUDE.md's "Serbian-first, bilingual" and "sr and en, nothing else" rules, plus D77, D91, D109.
- 2026-10-12 — multiple households per user
