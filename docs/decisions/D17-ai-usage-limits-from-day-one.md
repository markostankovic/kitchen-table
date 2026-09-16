## D17 — AI usage limits from day one

**Decided.** `ai_usage` rows per call; a per-household monthly cap checked
before every model call in `_shared/usage.ts`.

**Why.** An OCR retry loop can burn real money even at family scale. Cheap now,
awkward to bolt on later.
