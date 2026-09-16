## D4 — Latin script only for storage and display; accept Cyrillic on input

**Decided.** Everything is stored and displayed in Serbian Latin. Cyrillic input
(OCR of an old cookbook, pasted text) is transliterated at the door and never
stored.

**Why.** User has no need for Cyrillic display. Cyrillic → Latin is
unambiguous; the reverse direction has digraph edge cases (*nadživeti*,
*injekcija*), so always normalize toward Latin.

**Rejected.** Storing both scripts, or a render-time transliterator with a user
preference. Not needed.
