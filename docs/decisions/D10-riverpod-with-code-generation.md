## D10 — Riverpod with code generation

**Decided.** `riverpod` + `riverpod_generator` + `riverpod_lint`, plus
`go_router` (typed routes), `freezed`, `json_serializable`.

**Why.** The real constraint is drift across many AI-assisted sessions.
Codegen means a provider has exactly one legal shape, so a wrong one is a
compile error rather than a review comment. `AsyncValue` matches the app's
shape (nearly every screen is loading/error/data over a Supabase query).
Riverpod also has the most training data, so generated code matches existing
code.

**Rejected.**
- BLoC — comparably rigid, but boilerplate-to-logic ratio is too high for one
  person.
- setState / Provider / GetX — not enough structure to resist drift.
