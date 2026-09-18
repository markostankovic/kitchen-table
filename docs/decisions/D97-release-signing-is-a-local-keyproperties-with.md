# D97 — Release signing is a local `key.properties` with a debug-build fallback
**Status:** active
**Touches:** android/app/build.gradle.kts, android/key.properties.example, .gitignore, Makefile

**Decided.** Release builds sign with a real upload keystore read from
`android/key.properties` (gitignored; `android/key.properties.example` is
the committed template) when the file is present, falling back to the debug
keystore when it is absent -- a fresh clone or CI still produces a release
APK. The keystore itself lives outside the repo entirely (password manager),
generated once with `keytool`, mirroring the `env/*.json` /
`env/*.example.json` split (D95) for the same reason: a real secret plus a
committed template that explains where it comes from.

**Why.** Personal installs and TestFlight need a signature that survives
reinstalls, and `android/app/build.gradle.kts` had carried
"TODO: Add your own signing config" since the project was created. Staying
on the debug keystore becomes untenable once TestFlight or the Play Store
enter the picture -- Apple's notarization and Play's app-signing both reject
a debug-signed binary (the same Apple constraint D96 already named for
Sign in with Apple). Doing the real thing now, while the only thing at
stake is whether `make install-hosted` still works, costs one `keytool`
invocation; doing it later costs the same invocation under store-submission
time pressure.

**Rejected.** Keeping the debug keystore until store distribution is
actually being prepared -- defers a one-time setup cost to a moment that
already has TestFlight/Play Console configuration competing for attention,
and risks discovering the debug-signing rejection then rather than now.

**Consequences.** The keystore file and its passwords are the user's own
responsibility to keep (password manager, per CLAUDE.md rule 2's secrets
split) -- losing them means losing the ability to publish updates under this
`applicationId`. Every release-build path (`make install-hosted`, any future
CI) must keep working through the fallback, since neither a fresh clone nor
a CI runner will have the file.
