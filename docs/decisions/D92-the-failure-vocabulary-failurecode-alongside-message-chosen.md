## D92 — The failure vocabulary: `FailureCode` alongside `message`, chosen where D77 already chose the reader's locale

**Decided.** `FailureCode` (`core/error/app_failure.dart`, pure Dart, rule
7) is a 34-value enum; `AppFailure` gains a nullable `code` field alongside
the existing `message`, and each of the seven sealed variants defaults its
own code the way it already defaults its message.
`core/error/failure_l10n.dart` — the sibling file allowed to import
Flutter, on `core/l10n/app_locale.dart`'s own precedent (`tool/
check_layers.dart` derives a layer only from `lib/features/<name>/<layer>/`,
so nothing under `lib/core/` is subject to rule 7's ban) — renders a
failure through `localizedFailureMessage`/`localizedErrorMessage`/
`AppFailureL10n.localized`.

**The invariant, one sentence.** `code == null` means, and only means, that
`message` came from somewhere that knows more than this client does — a
Postgres `raise exception`, GoTrue, a model's own refusal — and is shown
verbatim; otherwise the code wins outright and `message` is only ever a log
line. `supabase_failure.dart`'s own header had already named this as
Phase 3's job: *"it lets Phase 3 localize by code with the server's text as
the fallback."*

**Why the carve-outs stay uncoded, each checked against the actual source
rather than assumed.** `quota_exceeded` was expected to need the server's
sentence to say *whose* allowance ran out — checked against
`_shared/usage.ts` and found not to: the numbers go to `console.error`
specifically so the wire message can be one fixed, fully localizable
sentence, so `quota_exceeded` gets `FailureCode.aiAllowanceUsedUp` after
all. `url_not_allowed` genuinely cannot be coded: `url_guard.ts` throws four
different sentences under the one slug depending on which check fired, and
D45's guard deliberately never says more than that. `empty_input` and
`ai_failed` differ per caller or carry a model's own dynamic refusal text —
both keep a code for the *degenerate* arm only, when the server sent no
message of its own. Postgres check-constraint and GoTrue prose are
unbounded sets no client-side vocabulary can cover.

**The nine-slug gap, found while building the vocabulary rather than
assumed closed.** `supabase_failure.dart`'s own header claims it and
`_shared/http.ts` "are the two ends of the same contract," but nothing had
verified that until this part: nine of the 33 slugs the Edge Functions
actually throw (`fetch_failed`, `not_html`, `page_too_large`,
`image_too_large`, `job_not_found`, `job_already_done`, `job_not_parsed`,
`no_recipe_found`, `code_generation_failed`) had no arm at all and fell to
`default: UnknownFailure(cause: e)` — which passes no `message`, so "that
page is too large" was reaching a cook as "Something went wrong." All nine
now have arms and codes.
`test/core/supabase/supabase_failure_test.dart`'s slug-contract test is
what keeps this closed: it parses every `HttpError(<status>, "<slug>"` out
of `supabase/functions/**/*.ts` — the `AiFailure extends HttpError`
subclass included, which a naive single-pattern regex misses — and asserts
each has an arm, rather than trusting the two files to stay in sync by
inspection the way the header comment alone had.

**The known trap, named so it is not rediscovered.** Because each variant
defaults its own code, a call site that passes a custom `message:` and
forgets `code:` silently keeps the variant's *default* code and renders the
wrong sentence, with no compile error — `NetworkFailure(message: 'No
connection, and no saved plan on this phone yet.')` would otherwise render
the generic "No connection." instead. This is not preventable in Dart (a
`required` base parameter still lets a subclass default it), so it is
caught the only way it can be: the three `*_repository_offline_test.dart`
cold-cache assertions moved from checking `.message` to checking `.code`,
which fail together if a future edit misses one. Four sites were exposed
by exactly this and fixed in the same commit as the mechanism: the three
cold-cache throws and the `TimeoutException` arm in `supabase_failure.dart`.

**Rejected.**
- Replacing `message` with a required code — deletes `toString()`'s
  usefulness for logs and a crash reporter, and removes the escape hatch
  every carve-out above depends on; a new server slug would have to ship a
  client enum value and two ARB strings before it could surface at all,
  worse than today's degrade-to-`UnknownFailure`-with-server-text.
- A `String localize(AppLocalizations)` method per variant instead of a
  free function over an enum — would put a Flutter type inside
  `app_failure.dart`, contradicting that file's own "Pure Dart. No Flutter
  imports." header even though the checker would not catch it; also the
  wrong axis, since `ValidationFailure` alone carries eight distinct
  sentences that would each need their own inner switch regardless.
- A bare `String` key instead of an enum — no exhaustiveness (the `switch`
  in `failure_l10n.dart` has no `default` arm specifically so a new code
  fails to compile without a sentence), no compile error on a typo, and it
  re-invents the ARB key namespace one indirection away from it.
