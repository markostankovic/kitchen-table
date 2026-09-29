# D133 — The app is portrait-only
**Status:** active
**Touches:** lib/main.dart, android/app/src/main/AndroidManifest.xml, ios/Runner/Info.plist

**Decided.**
- `main()` calls `SystemChrome.setPreferredOrientations([portraitUp])` before
  `runApp`.
- Android's `MainActivity` sets `android:screenOrientation="portrait"`, so
  nothing rotates before Flutter starts.
- iPhone's `UISupportedInterfaceOrientations` is Portrait only.
  `UISupportedInterfaceOrientations~ipad` keeps all four, because iPad
  multitasking requires them. The Dart call still locks the app there.

**Why.** The user asked for rotation to be disabled, and no screen is laid
out for landscape.

**Rejected.**
- Landscape layouts. Nobody asked for them, and the phone-first layouts
  (D53, Phase 7 part 4) don't have one.
- Cutting the iPad list too. That would need `UIRequiresFullScreen` and
  would opt out of multitasking for no gain.

**Consequences.** On the emulator, forcing `user_rotation 1` left the app at
`ROTATION_0`. Revisit this if a tablet layout is ever planned.
