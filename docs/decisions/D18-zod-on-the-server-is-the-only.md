## D18 — Zod on the server is the only schema definition; Dart models are generated

**Decided.** `zod-to-json-schema` → `quicktype` → freezed Dart models, wired as
`make types`.

**Why.** Hand-mirroring the AI parse contract in Dart drifts silently: rename a
field on the server, the Dart parser quietly reads null, and the bug surfaces
three screens later.
