# Kitchen Table -- developer commands.
#
# `make lint` and `make test` must both be clean before any commit (CLAUDE.md).

DART_DEFINE := --dart-define-from-file=env/local.json

.PHONY: help gen watch lint test test-sql db-reset db-start db-stop types check

help:
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

gen: ## Run code generation once
	dart run build_runner build

watch: ## Run code generation continuously
	dart run build_runner watch -d

lint: ## Analyze + enforce layer boundaries
	dart analyze
	dart run tool/check_layers.dart

test: ## Dart/Flutter tests
	flutter test

# NOTE: `supabase db query` sends the file as a single prepared statement, so
# each test file must contain exactly ONE statement. In practice that means
# wrapping everything -- including any DDL -- in a single `do $$ ... $$;` block
# and using EXECUTE for the DDL.
test-sql: ## Regenerate generated SQL, then run every test in supabase/tests/
	dart run tool/gen_normalization_sql.dart
	@for f in supabase/tests/*.sql; do \
		echo "--- $$f"; \
		supabase db query --file "$$f" || exit 1; \
	done

check: lint test test-sql ## Everything CI would run

db-start: ## Start the local Supabase stack
	supabase start

db-stop: ## Stop the local Supabase stack
	supabase stop

db-reset: ## Rebuild the local database from migrations
	supabase db reset

run: ## Run the app on iOS/desktop (requires env/local.json)
	flutter run $(DART_DEFINE)

# The Android emulator cannot reach 127.0.0.1 -- that address resolves to the
# emulator itself. 10.0.2.2 is its alias for the host loopback.
run-android: ## Run the app on the Android emulator (requires env/android.json)
	flutter run --dart-define-from-file=env/android.json

types: ## Regenerate Dart models from the Zod schemas (Phase 1d)
	@echo "make types is not wired up yet."
	@echo ""
	@echo "It generates lib/features/import/domain/parsed_recipe.dart from"
	@echo "supabase/functions/_shared/schema.ts via zod-to-json-schema +"
	@echo "quicktype (docs/ARCHITECTURE.md, 'Type flow')."
	@echo ""
	@echo "Blocked until Phase 1d, which is when schema.ts first exists."
	@echo "It also needs deno and quicktype, neither of which is installed."
	@echo ""
	@echo "This target fails on purpose rather than silently doing nothing:"
	@echo "a no-op here would look like a successful regeneration."
	@exit 1
