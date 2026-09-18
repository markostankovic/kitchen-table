# Kitchen Table -- developer commands.
#
# `make lint` and `make test` must both be clean before any commit (CLAUDE.md).

DART_DEFINE := --dart-define-from-file=env/local.json

.PHONY: help gen watch lint lint-functions test test-functions test-sql seed \
	seed-check l10n-check db-reset db-start db-stop db-push config-push \
	types check functions-serve functions-deploy run run-android run-hosted \
	install-hosted

help:
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-17s %s\n", $$1, $$2}'

gen: ## Run code generation once
	flutter gen-l10n
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
	dart run tool/gen_unit_alias_sql.dart
	dart run tool/gen_display_name_sql.dart
	@for f in supabase/tests/*.sql; do \
		echo "--- $$f"; \
		supabase db query --file "$$f" || exit 1; \
	done

# NOTE: seed-check is its own step and NOT folded into test-sql. test-sql can
# regenerate normalization_test.sql in place, because that file is a test.
# The catalog seed is a migration, and an applied migration is never rewritten
# (CLAUDE.md) -- so the only thing that can catch an edited CSV with no
# migration behind it is an explicit check. Different guarantees, different
# targets.
check: lint lint-functions test test-functions seed-check test-sql l10n-check ## Everything CI would run

seed: ## Emit a new catalog seed migration from supabase/seeds/*.csv
	dart run tool/gen_ingredient_seed.dart --new-migration

seed-check: ## Fail if the seed CSVs changed without a new seed migration
	dart run tool/gen_ingredient_seed.dart --check

# `flutter: generate: true` in pubspec.yaml means `flutter run`/`flutter test`
# regenerate lib/core/l10n/generated/ themselves, silently -- so an ARB edit
# with no `make gen` run first can commit a stale generated file with nobody
# noticing (the same gap part 6b closed for display_names_test.sql via
# gen_display_name_sql.dart). This is that check for the l10n generator.
l10n-check: ## Fail if the ARB files changed without regenerating lib/core/l10n/generated
	flutter gen-l10n
	git diff --exit-code -- lib/core/l10n/generated

db-start: ## Start the local Supabase stack
	supabase start

db-stop: ## Stop the local Supabase stack
	supabase stop

db-reset: ## Rebuild the local database from migrations
	supabase db reset

# The two targets that write to the linked hosted project. Both are one-way:
# read what they print before confirming. db-push applies every migration the
# remote has not seen; config-push replaces the whole remote [auth] block with
# what config.toml says, not just the keys you changed.
db-push: ## Apply pending migrations to the linked hosted project
	supabase migration list --linked
	supabase db push

config-push: ## Push config.toml (auth settings, email templates) to the linked project
	supabase config push

# NOTE: every deno invocation passes --config explicitly. Deno resolves its
# import map from the nearest deno.json to the CWD, and these run from the repo
# root, which has none -- without the flag `import { z } from "zod"` is simply
# "not a dependency".
DENO_CONFIG := --config supabase/functions/deno.json

test-functions: ## Deno tests for the shared Edge Function modules
	deno test $(DENO_CONFIG) --allow-read supabase/functions/_shared/

lint-functions: ## Typecheck, lint and format-check the Edge Functions
	deno check $(DENO_CONFIG) supabase/functions/_shared/*.ts \
		supabase/functions/*/index.ts
	deno lint $(DENO_CONFIG) supabase/functions/
	deno fmt $(DENO_CONFIG) --check supabase/functions/

functions-serve: ## Serve the Edge Functions locally, with hot reload
	supabase functions serve

functions-deploy: ## Deploy the Edge Functions to the linked project
	supabase functions deploy create-invite redeem-invite \
		import-text import-url import-photo match-ingredients \
		translate-recipe

run: ## Run the app on iOS/desktop (requires env/local.json)
	flutter run $(DART_DEFINE)

# The Android emulator cannot reach 127.0.0.1 -- that address resolves to the
# emulator itself. 10.0.2.2 is its alias for the host loopback.
run-android: ## Run the app on the Android emulator (requires env/android.json)
	flutter run --dart-define-from-file=env/android.json

# The hosted project. Same binary, different compile-time config (D95) -- the
# only way to exercise a real inbox, a real device, or the deployed Edge
# Functions. Local stays the default; reach for this deliberately.
run-hosted: ## Run the app against hosted Supabase (requires env/hosted.json)
	flutter run --dart-define-from-file=env/hosted.json

# The pair for a real device rather than `flutter run` over USB debug: a
# signed *release* build, and a way to sign into it once installed. Sign in
# with Google on the device once it's installed.
install-hosted: ## Build a release APK against hosted Supabase and install it on the attached device
	flutter build apk --release --dart-define-from-file=env/hosted.json
	@PATH="$$HOME/Library/Android/sdk/platform-tools:$$PATH" adb install -r build/app/outputs/flutter-apk/app-release.apk

types: ## Regenerate Dart models from the Zod schemas
	@# docs/ARCHITECTURE.md, "Type flow". schema.ts is the source of truth for
	@# every AI-facing shape (D18); the Dart below is generated and must never
	@# be hand-edited.
	deno run $(DENO_CONFIG) --allow-read --allow-write --allow-run=quicktype \
		tool/gen_types.ts
	dart format lib/features/import/domain/parsed_recipe.dart
	dart run build_runner build
