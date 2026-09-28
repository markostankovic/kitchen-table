# D125 — Emulator builds get an email/password dev-login button, gated on compile-time defines
**Status:** active
**Touches:** lib/core/env/env.dart, lib/features/auth/data/auth_repository.dart, lib/features/auth/presentation/sign_in_screen.dart, env/dev_login.example.json, Makefile

**Decided.** `make install-emulator` builds the same hosted release APK as
`make install-hosted`, plus `--dart-define-from-file=env/dev_login.json`. That
file supplies `DEV_LOGIN_EMAIL` and `DEV_LOGIN_PASSWORD`. When both are set
(`Env.hasDevLogin`), the sign-in screen shows an outlined "Dev login:
<email>" button under Google's. The button calls
`AuthRepository.signInWithPassword`, which uses `runGuarded` like
`signInWithGoogle`. Any other build leaves both defines empty and looks
exactly as before. The account (`test-user@kitchen-table.test`) was created
by hand in the hosted dashboard with auto-confirm, so no email is ever sent.
`env/dev_login.json` is gitignored under the existing `env/*.json` rule.
`env/dev_login.example.json` is committed to show the shape. The button's
label is not localized: it is developer chrome and no user sees it, in the
same way the brand name is not localized.

**Why.** An emulator cannot complete Google sign-in, because the native
chooser needs Play Services and a signed-in Google account. That left no way
to exercise a hosted build on an emulator, and CLAUDE.md says a slice is seen
working on a hosted build. Email/password needs no mail round trip, so the
free-tier SMTP gap that retired OTP (D96) does not apply. Hosted's Email
provider is on by default. Verified on `Pixel_9`: the button signed in and
the redirect moved on to create-household.

**This narrows D96's consequences.** D96 rejected "keeping a dev-only
button in the UI". That rejection was about *local* development after OTP
removal: the button would have been a reason not to delete the OTP code, and
`generate_link` against the local stack replaces it. D125's button serves
emulator builds against *hosted*, where `generate_link` would need the
service-role key on the developer's machine. It is not the OTP path either:
nothing of the removed code comes back, and it sends no email. D96's
retirement of OTP stands. D96's file stays as written, and this decision is
the record of the narrowing.

**Rejected.**
- A Google Play system image, so that the real chooser runs on the emulator.
  This is still viable and tests the real path. It needs a Google account
  signed into every emulator, though, and it cannot be scripted for driving
  an emulator unattended.
- A debug-only gate (`kDebugMode`). That would contradict "running the app
  means a release build" (CLAUDE.md). The defines are the gate instead, and
  they are equally absent from every build that does not ask for them.
- Committed credentials, or credentials in `env/hosted.json`. With the
  latter, `make install-hosted` would put the button on the phone.

**Consequences.** Anything passed as a dart-define can be read back out of
the APK, so an `install-emulator` build must never be distributed. The
account is a throwaway and belongs to its own household.
`install-emulator` writes to the same
`build/app/outputs/flutter-apk/app-release.apk` as `install-hosted`, so
rebuild with `install-hosted` before installing on the phone. The target
installs with `adb -e`, so it needs a running emulator. Apple sign-in (D96's
release gate) is unaffected: the button never reaches a store build.
