# D96 — Email OTP is retired in favour of Google sign-in, not fixed
**Status:** active
**Touches:** lib/features/auth/, supabase/config.toml, supabase/templates/magic_link.html, docs/ROADMAP.md

**Decided.** Google sign-in becomes the only way into the app. Apple sign-in
follows, gated on App Store distribution rather than optional. Email OTP --
`requestOtp` / `verifyOtp`, both sign-in screens, their ARB strings,
`FailureCode.codeNotAccepted`, `supabase/templates/magic_link.html` and its
`config.toml` block -- is removed once Google is proven working, not before.
Household invite codes are a different system and are unaffected.

**Why.** Hosted email sign-in cannot work on the free tier: the built-in
sender refuses any custom template, so the mail arrives with no code to type
(D95). Making it work costs either custom SMTP -- a new third-party service,
CLAUDE.md rule 8 -- or a paid plan, to keep an inbox round trip that Google
sign-in removes anyway. The template is also the single thing that blocks
`supabase config push` from carrying *any* auth setting, so deleting it is
what makes hosted auth git-manageable at all -- including
`[auth.external.google]`, which pushes fine. Verified: with the template block
out of the payload the same push succeeded and hosted went from minting
8-character codes to 6.

**Rejected.** Custom SMTP, which buys a worse sign-in flow and a service to
maintain. A paid plan, for the same flow. Keeping both paths -- ROADMAP Part 3
originally said "alongside the existing OTP methods" -- which leaves the
template in `config.toml`, and so leaves every hosted auth setting
unpushable, to serve a fallback for users who lack a Google account on an
Android-first family app.

**Consequences.** Google sign-in must be added and proven on hosted *before*
the OTP code is removed; deleting the only working sign-in path first leaves
the app unsignable-into. Until then the template block stays enabled locally
and is commented out for the duration of any `config push`. Local
development loses its frictionless Mailpit sign-in when OTP goes -- the
replacement is minting a token via `POST /auth/v1/admin/generate_link` rather
than keeping a dev-only button in the UI, which would mean not actually
deleting the code. Apple is a release gate: App Store Guideline 4.8 requires
an equivalent privacy-preserving option wherever a third-party login is
offered, so Google-only ships for personal signing and TestFlight but not to
the store.
