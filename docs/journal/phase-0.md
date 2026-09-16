# Journal — Phase 0

Verbatim build history for Phase 0 — Foundations, moved out of `docs/ROADMAP.md` so the roadmap stays a forward-looking index. Nothing here is authoritative going forward -- see `docs/decisions/` for standing rules, `docs/STATE.md` for current status.

---

## Phase 0 — Foundations

**Status: complete** (`392ab96`). Decisions taken during it: D19–D24.

No product features. This exists so nothing later has to be undone.

- `flutter create`, package structure per ARCHITECTURE.md, empty feature folders
- `analysis_options.yaml` strict, `riverpod_lint` wired via `plugins:` (D20)
- `tool/check_layers.dart` — fails if `presentation/` imports `data/`, or if
  `supabase_flutter` appears outside `data/` and `core/supabase/`
- `build_runner` working; one throwaway freezed model to prove it
- Supabase project + local `supabase start`; migration 1 = extensions,
  `normalize_text()`, `updated_at` trigger function
- `TextNormalizer` in Dart + `test/fixtures/normalization.json` + tests on both
  sides (Dart test, and a SQL test that asserts the same pairs)
- `go_router` shell with four empty tabs
- Makefile: `types`, `gen`, `lint`, `db-reset`

**Done when:** `dart analyze` is clean, layer check passes, normalization tests
pass in both Dart and Postgres, app runs and navigates between four blank tabs.

---

