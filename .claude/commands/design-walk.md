---
description: Install the hosted release build on the Galaxy or the emulator and walk one surface in sr/en x light/dark
argument-hint: <surface-or-slice-name>
---

Walk the surface named `$ARGUMENTS` on a device running the hosted release build — e.g.
`recipe-list`, `phase7-part1`, or a slice name.

This is verification, not a slice. `docs/DESIGN_SYSTEM.md` § Both languages and §
Light and dark both state rules that **nothing automated catches**: Serbian
runs longer than English, and a colour tuned in one brightness and eyeballed
in the other is how a redesign ends up with an unreadable dark mode. This
command is how those get checked. `docs/STATE.md` lists the walks currently
open.

If `$ARGUMENTS` is empty, read `docs/STATE.md`'s open-device-walk list and ask
the user which one to close.

## 1. Pick the device — the Galaxy or the emulator

`adb` is not on PATH. Prefix:

```
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
```

Run `adb devices -l`. Either target is a valid walk. Both run the same
release APK against hosted Supabase:

- **The Galaxy** (physical, by serial). It is the only one that can do Google
  sign-in, so a check that needs a real Google account runs here. That covers
  the Google button's busy/failure path, a brand-new account landing via
  `on_auth_user_created`, and a second *Google* account.
- **The emulator** (`emulator-5554`). It cannot hold a Google account, so it
  signs in through D125's `Dev login` button
  (`test-user@kitchen-table.test`). Everything behind sign-in walks the same.
  Colour, type, and Serbian width are the build's, not the device's. The
  emulator's screen is not the Galaxy's, so name the device in the report.
  If a check needs Google, say it was not reached rather than calling the
  walk clean on it.

**If both are attached**, `make install-hosted`'s bare `adb install -r` is
ambiguous. Install by serial by hand instead:

```
flutter build apk --release --dart-define-from-file=env/hosted.json
adb -s <serial> install -r build/app/outputs/flutter-apk/app-release.apk
```

Do not edit the Makefile to work around this.

## 2. Install

- Galaxy: `make install-hosted`.
- Emulator: `make install-emulator`, which is the same hosted release APK plus
  `env/dev_login.json`. It writes the same output path, so rebuild with
  `install-hosted` before putting a build on the phone.

If it fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, a debug-signed build
(from `make run-hosted`) is installed and the two can never overwrite each
other in place. Uninstall first — which clears app data, so Google sign-in
has to happen again afterward. Say that before doing it.

## 3. Walk all four combinations

Order: **sr/light → sr/dark → en/light → en/dark**.

- **Language** is the in-app toggle on the settings screen
  (`lib/features/auth/presentation/settings_screen.dart`).
- **Brightness** is also an in-app setting: the `Svetla` / `Tamna`
  (`Light` / `Dark`) segments in the same screen's Izgled group (D128). The
  app ignores the phone's own dark mode, so `adb shell cmd uimode night
  yes|no` does **not** switch it. Use `uimode` only to confirm that
  (phone dark + app `Svetla` must stay light), and reset it to `no`
  afterward.
- Both toggles belong to the walk account: language is saved on its hosted
  profile, and the theme on the device. Put both back where you found them
  (normally `Srpski` / `Svetla`) before reporting.

## 4. Screenshot each, and read the screenshots properly

```
adb -s <serial> shell screencap -p /sdcard/s.png
adb -s <serial> pull /sdcard/s.png <local>
```

For taps, do not eyeball coordinates off the screenshot as displayed in
conversation — it is downscaled, and scaling a visual estimate back up
consistently misses small targets. Instead:

- `adb -s <serial> shell uiautomator dump /sdcard/ui.xml`, pull it, and grep
  `bounds="..."` off the `content-desc` of the target — Flutter's semantics
  tree exposes labeled, bounded elements this way; or
- crop the raw pulled PNG with PIL and read the target's centre off the
  crop's own pixel coordinates.

Spaces in `adb shell input text` must be written `%s`, and never use
`KEYCODE_BACK` to dismiss the keyboard — `go_router` pops the route and an
unsaved draft is gone.

## 5. Judge

Against the two rules with no automated check:

- **Serbian.** Anything that truncates, wraps badly, or overflows in `sr`
  where `en` fits is a bug, not a rendering detail.
- **Dark.** Every colour decision has to hold in both brightnesses. Check
  contrast on muted roles especially — `outline` and `onSurfaceVariant` are
  where this fails first.

Note that `test/core/l10n/arb_parity_test.dart` checks only that keys exist on
both sides. It says nothing about width.

## 6. Report, and update the loop list

Report per combination: what was checked, and what was found. Attach or name
the screenshots.

Then update `docs/STATE.md`'s open-device-walk list — this is the one write
this command makes:

- Walk clean → remove that bullet and correct the count in the bold line
  above the list.
- Walk found a defect → leave the bullet, and record what broke so the fixing
  slice has it.

Do not touch `docs/journal/`, `docs/decisions/` or `docs/ROADMAP.md` — those
stay `/close-slice`'s job.
