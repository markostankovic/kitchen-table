## D16 — Imported cookbook content is permanently household-scoped

**Decided.** Recipes with `source_type = 'ocr'` or `'url_import'` keep
`visibility = 'household'` with no path to a public shared corpus. `source_url`
or book attribution is stored and displayed.

**Why.** Cookbook prose is copyrighted and OCR is reproduction. Private
household use is defensible; republishing is not.
