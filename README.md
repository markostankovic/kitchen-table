# Kitchen Table

Family recipes, a weekly meal plan and a shopping list built from it. It's
Serbian-first and fully bilingual (sr / en). Everything belongs to a
**household** rather than a person, and every member of the household sees
and edits the same recipes, plan and list. Recipes can be typed in, or
imported from text, a URL or a photo, with AI parsing done on the server.

A Flutter app (Android on a real phone, plus the iOS Simulator for debug
runs) on top of a hosted Supabase backend.

> Coming back after a while? Start with **[Update the app on my phone](#update-the-app-on-my-phone)**,
> then read [`docs/STATE.md`](docs/STATE.md) to see where things stand.

---

## Update the app on my phone

The phone runs a **release build pointed at hosted Supabase**. Sign-in is
Google only.

```sh
git pull
flutter pub get

# 1. Did supabase/migrations/ change? Apply them to hosted. Dry-run first.
supabase migration list --linked
supabase db push --dry-run
make db-push

# 2. Did supabase/functions/ change? Redeploy the Edge Functions.
make functions-deploy

# 3. Plug in the phone (USB debugging on) and install.
make install-hosted
```

`make install-hosted` builds `flutter build apk --release` against
`env/hosted.json` and runs `adb install -r`. App data lives on the server,
so reinstalling keeps it.

Other ways to run against hosted:

| Target | What it does |
|---|---|
| `make install-emulator` | Same release build plus a **Dev login** button (the emulator can't do Google sign-in), installed on the running emulator. It writes the same APK file, so run `install-hosted` again before installing on the phone. |
| `make run-hosted` | `flutter run` against hosted on the attached device, for logs and hot reload. |
| `make run-ios-sim` | Debug build against hosted on the iOS Simulator (`IOS_SIM="iPhone Air"` to choose another). |

`adb` isn't on `PATH`. The make targets add
`~/Library/Android/sdk/platform-tools` themselves. Call it by its full path
if you need it directly.

### If the install fails

- **`INSTALL_FAILED_UPDATE_INCOMPATIBLE` / signature mismatch.** The APK was
  signed with a different key than the installed one. Check
  `android/key.properties` (see below), or uninstall the app from the phone
  first. Only the local cache is lost; the data is on the server.
- **Google sign-in fails on a new build.** The Android OAuth clients are tied
  to the signing key's SHA-1 (D98). The debug and upload keystores are both
  registered; any other key is not.
- **No device found.** Run `~/Library/Android/sdk/platform-tools/adb devices`
  and accept the USB-debugging prompt on the phone.

---

## First-time setup (new machine / fresh clone)

**Tools:** Flutter (stable, 3.47+, Dart ^3.13), Android SDK, Xcode (iOS
Simulator), [Supabase CLI](https://supabase.com/docs/guides/cli), Deno,
Docker Desktop (only for the local stack; its CLI needs
`export PATH="$HOME/.docker/bin:$PATH"`).

**Files that are gitignored and must be recreated:**

| File | From | Holds |
|---|---|---|
| `env/hosted.json` | `env/hosted.example.json` | Hosted project URL + anon key (`supabase projects api-keys`) |
| `env/dev_login.json` | `env/dev_login.example.json` | The emulator's test account credentials |
| `env/local.json` | `env/local.example.json` | Local stack URL + anon key (`supabase status`) |
| `env/android.json` | `env/android.example.json` | Same, via `10.0.2.2` for the emulator |
| `android/key.properties` | `android/key.properties.example` | Release keystore path + passwords (D97) |

The `.jks` keystore and its passwords live in the password manager, outside
the repo. Without `key.properties` the release build falls back to the debug
keystore. It still runs, but it won't install over an upload-signed build.

**Supabase CLI:**

```sh
supabase login
supabase link --project-ref cbajkezfhssrvbdbedqt
```

The Edge Functions need the `ANTHROPIC_API_KEY` secret on hosted
(`supabase secrets set ANTHROPIC_API_KEY=...`). It's already set; set it
again only on a new project. Hosted is on the free tier: `supabase config
push` is blocked there, so auth settings are changed in the dashboard.

---

## Developing

```sh
make help          # every target, with a line each
make gen           # codegen once (l10n + build_runner)
make watch         # codegen continuously
```

Generated files (`*.g.dart`, `*.freezed.dart`, `lib/core/l10n/generated/`)
are committed.

**Before a commit:** `make lint` (dart analyze + the layer-boundary check)
and `make test`. `make check` runs everything CI would, including the Deno
tests and the SQL tests, which need the local database running. `seed-check`
is currently known to be red on `main`.

**The local stack** (`make db-start`, `make db-reset`, `make functions-serve`,
`make run`, `make run-android`) is for debugging the backend itself and for
the SQL test suite. To check a feature, use a hosted release build.

**Other targets:** `make types` regenerates Dart models from the Zod schemas.
`make seed` writes a new ingredient-catalog migration from
`supabase/seeds/*.csv`. `make icons` re-renders the launcher icons.

**How a piece of work goes:** a slice is planned with `/plan-slice`, built
with `/build-slice` in a fresh session, then recorded with `/close-slice`.
Design rounds go through `/design-handoff` and `/plan-slice-ui`.

---

## Tech stack

| Layer | Choice |
|---|---|
| App | Flutter (Android; iOS Simulator for debug) |
| State | Riverpod with `riverpod_generator` |
| Navigation | `go_router` with typed routes |
| Models | `freezed` + `json_serializable` (pure Dart domain) |
| Offline | Drift (SQLite) read cache with delta sync |
| i18n | `flutter_localizations` + ARB files, locales `sr` and `en`, Latin script only |
| Backend | Supabase: Postgres with row-level security, Auth, Storage (recipe photos) |
| Sign-in | Google only: native `google_sign_in`, then `signInWithIdToken` |
| Server code | Supabase Edge Functions (Deno / TypeScript) |
| AI | Anthropic Claude, called **only** from Edge Functions: Opus for import parsing, photo reading and translation; Haiku for ingredient matching. Zod schemas in `supabase/functions/_shared/schema.ts` are the source of truth (`make types`). |

**Edge Functions:** `create-invite`, `redeem-invite` (household invites),
`import-text`, `import-url`, `import-photo` (recipe import),
`match-ingredients`, `translate-recipe`, `translate-tags`.

---

## Project layout

```
lib/
  core/                 # supabase client, router, theme, db, l10n, shared widgets
  features/<name>/      # auth, households, recipes, ingredients, import, meal_plan, shopping_list
    data/               #   repositories, DTOs (the only place Supabase is imported)
    domain/             #   freezed models, pure Dart
    application/        #   @riverpod providers
    presentation/       #   screens, widgets
supabase/
  migrations/           # one timestamped file per change; never edit an applied one
  functions/            # Edge Functions; _shared/ holds schemas, the AI client, usage limits
  tests/                # SQL tests (make test-sql)
  seeds/                # ingredient catalog CSVs
tool/                   # code generators and the layer checker
test/                   # Flutter tests, plus fixtures shared with the server
docs/                   # see below
```

The hard rules (no Supabase outside `data/`, no AI key on the client, no
hard deletes, integer-fraction quantities, ask before adding a package…)
are in [`CLAUDE.md`](CLAUDE.md).

---

## Where to look next

| Question | File |
|---|---|
| Where are we, what's next | [`docs/STATE.md`](docs/STATE.md) |
| What's been built, phase by phase | [`docs/ROADMAP.md`](docs/ROADMAP.md) |
| Layering and dependency rules | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) |
| Tables, columns, RLS | [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md) |
| Ingredient parsing and matching | [`docs/INGREDIENTS.md`](docs/INGREDIENTS.md) |
| Colours, type, shared widgets | [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) |
| Why something is built the way it is | [`docs/decisions/INDEX.md`](docs/decisions/INDEX.md) (code comments cite `Dxx`) |
| Ideas for later | [`docs/IDEAS.md`](docs/IDEAS.md) |
| Prompts for importing recipes from an AI chat | [`docs/guides/`](docs/guides/) |
