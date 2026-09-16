## D21 — `fromJson` / `toJson` are exempt from the raw-map ban

**Decided.** `tool/check_layers.dart` does not flag `Map<String, dynamic>` on
lines declaring `fromJson` or `toJson`.

**Why.** CLAUDE.md rule 1 bans `Map<String, dynamic>` outside `data/`, but
CLAUDE.md also mandates `freezed` + `json_serializable` for *all* models, and a
generated `fromJson` necessarily takes a raw map. A literal reading of rule 1
would ban the exact pattern the stack requires. What rule 1 protects against is
untyped maps used as the currency *between* layers — not the one constructor
that turns a map into a typed model.
