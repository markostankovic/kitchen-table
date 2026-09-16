## D8 — Human confirm step on every import

**Decided.** Import never writes a recipe silently. The user reviews parsed
ingredients before save. Confirmed lines write alias rows with
`match_method = 'manual'`.

**Why.** This single screen is the quality mechanism for the whole catalog. It
turns catalog curation into a side effect of normal use. Design it for speed:
accept-all by default, edit the odd line out.
