# D95 — Local and hosted are one config, differing only by `env/*.json` at compile time — and an email template is the one thing that cannot cross
**Status:** active
**Touches:** supabase/config.toml, supabase/templates/magic_link.html, env/hosted.example.json, lib/core/env/env.dart, Makefile, docs/ARCHITECTURE.md

**Decided.** Two environments, one codebase. The same binary is handed a
different `SUPABASE_URL` and anon key at compile time -- `env/local.json`
(`make run`), `env/android.json` (`make run-android`), `env/hosted.json`
(`make run-hosted`) -- and nothing in `lib/` knows which it got. No
`isProduction`, no environment enum, no branch on the URL. One migration set
(`make db-reset` / `make db-push`), one `config.toml` (`make config-push`),
one set of Edge Functions (`make functions-deploy`), all versioned. Auth
settings are never edited in the dashboard. Where the two genuinely must
differ, the difference is a `[remotes.<alias>]` block in `config.toml`, which
CLI 2.84.2 supports; there is exactly one today, holding `max_frequency` at
`1m0s` on hosted against `1s` locally.

**Why.** An environment the code can detect is an environment the code will
eventually behave differently in, and the difference will be discovered in
production. Keeping the mechanism to two strings makes that impossible rather
than merely discouraged. The dashboard is excluded for the same reason
`seed.sql` was in D29: a setting that exists only where there is no history
and no review is a setting nobody can find later.

**Rejected.** A second `config.toml` per environment, or an
`Env.isProduction` flag -- both invite exactly the drift this exists to
prevent. Dashboard-managed auth settings, which is how the same drift arrives
without anyone choosing it.

**Consequences.** `config push` replaces the *whole* remote `[auth]` block,
not just changed keys, so its diff is read before confirming. More sharply:
a free tier project on the built-in email sender rejects any email template,
and the block is pushed as one payload -- so `[auth.email.template.magic_link]`
fails the entire push, `otp_length` and external providers included. Local
*requires* that same block, because GoTrue's stock template carries only
`{{ .ConfirmationURL }}` and the app types a code. Both directions were
verified against the live project, not inferred. The working rule is
therefore: comment the template block out for the duration of a `config
push`, then restore it. That is ugly and temporary -- D96 deletes the
template outright, and the awkwardness is a reason for D96 rather than a
thing to engineer around.
