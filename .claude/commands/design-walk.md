---
description: Install the hosted release build on the physical device and walk one surface in sr/en x light/dark
argument-hint: <surface-or-slice-name>
---

Walk the surface named `$ARGUMENTS` on the physical device — e.g.
`recipe-list`, `phase7-part1`, or a slice name.

This is verification, not a slice. `docs/DESIGN.md` § Both languages and §
Light and dark both state rules that **nothing automated catches**: Serbian
runs longer than English, and a colour tuned in one brightness and eyeballed
in the other is how a redesign ends up with an unreadable dark mode. This
command is how those get checked. `docs/STATE.md` lists the walks currently
open.

If `$ARGUMENTS` is empty, read `docs/STATE.md`'s open-device-walk list and ask
the user which one to close.

## 1. Confirm a physical device — not the emulator

`adb` is not on PATH. Prefix:

```
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
```

Run `adb devices -l` and identify the Galaxy by serial. CLAUDE.md's "running
the app" means the physical device: the emulator cannot hold a Google account
at all, so it cannot even reach a signed-in screen.

**If the emulator is attached alongside it, stop and say so.**
`make install-hosted` runs a bare `adb install -r` with no `-s`, which is
ambiguous with two devices. Either ask the user to close the emulator, or
install by serial by hand:

```
flutter build apk --release --dart-define-from-file=env/hosted.json
adb -s <serial> install -r build/app/outputs/flutter-apk/app-release.apk
```

Do not edit the Makefile to work around this.

## 2. Install

`make install-hosted`.

If it fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, a debug-signed build
(from `make run-hosted`) is installed and the two can never overwrite each
other in place. Uninstall first — which clears app data, so Google sign-in
has to happen again afterward. Say that before doing it.

## 3. Walk all four combinations

Order: **sr/light → sr/dark → en/light → en/dark**.

- **Language** is the in-app toggle on the settings screen
  (`lib/features/auth/presentation/settings_screen.dart`).
- **Brightness is not an in-app setting.** `lib/main.dart` sets no
  `themeMode`, so the app follows the system. Switch it with
  `adb -s <serial> shell cmd uimode night yes|no`. If this Samsung build
  refuses that command, say so and fall back to toggling it in the device's
  own Settings rather than skipping the dark pass.

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
