# D99 — `FailureCode.codeNotAccepted` survives email-OTP removal
**Status:** active
**Touches:** lib/core/error/app_failure.dart, lib/core/supabase/supabase_failure.dart, lib/core/l10n/arb/app_sr.arb, supabase/config.toml

**Decided.** `FailureCode.codeNotAccepted` (and its `failureCodeNotAccepted`
ARB string, in both languages) survives Phase 4 part 4's removal of email
OTP. Only its OTP-specific references went: `auth_repository.dart`'s
`verifyOtp` throw site, the "and the client-side 'verifyOTP returned no
user' case" clause in the enum's doc comment, and the matching clause in
`app_sr.arb`'s `@failureCodeNotAccepted` description. `[auth.email]` also
stays enabled server-side in `config.toml`, with `otp_length` / `otp_expiry`
untouched.

**Why.** `supabase_failure.dart` maps the invite-redemption Edge Function's
`invalid_code` / `invalid_body` / `method_not_allowed` slugs onto this same
code, and `supabase_failure_test.dart` asserts it. Household invite codes
are a separate system from sign-in (D96 says so explicitly) and were never
actually in scope for this removal. Both D96's own removal list and
`docs/ROADMAP.md`'s Part 4 entry named `codeNotAccepted` for deletion
anyway — written when the plan was drafted, before anyone re-checked what
else the code carried. Leaving `[auth.email]` enabled is the smallest diff:
nothing about this slice, or part 3's identity-linking work, showed any
dependency on disabling it.

**Rejected.** Splitting the invite slugs onto a new, invite-only
`FailureCode` to keep `codeNotAccepted` purely OTP-shaped — pure churn, since
the invite call sites and their test already assert the shared code and
nothing about D92's one-code-one-sentence rule requires the split. Disabling
`[auth.email]` entirely — no evidence it needs to be off, and doing it here
would be a guess dressed as a cleanup.

**Consequences.** `docs/decisions/D96-*.md` keeps its original removal list
uncorrected — read it as the plan at the time, not the outcome; this
decision is the amendment, and D96's status stays `active`. Any future slice
touching invite failures must remember `codeNotAccepted` is shared, not
OTP-only. Local sign-in now requires a device that can hold a Google
account (part 3's finding, unchanged): the Android emulator stays UI-only
and cannot verify a real sign-in, including this slice's own removal.
