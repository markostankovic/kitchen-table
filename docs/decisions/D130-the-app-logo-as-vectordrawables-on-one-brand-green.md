# D130 — The app logo is "bowl on the table", drawn as hand-written VectorDrawables on the one brand-green colour resource the splash already uses, and centred on the launch screen
**Status:** active
**Touches:** android/app/src/main/res/, ios/Runner/Assets.xcassets/, ios/Runner/Base.lproj/LaunchScreen.storyboard, tool/gen_app_icons.py, Makefile, docs/design/logo/, docs/DESIGN_SYSTEM.md

**Decided.**
1. **The mark is Claude Design's "bowl on the table"**: steam and a table in
   `#FFF7EC` (`surface`), a `#FFDEA4` bowl (`secondaryContainer`) with a
   `#AC3F25` band (`tertiary`), on `#366A35` (`primary`). The sources are
   `docs/design/logo/` and `docs/design/app-logo.pdf`.
   `android-adaptive-foreground.svg` is the source of truth for the shapes.
2. **Android's adaptive, themed and launch marks are hand-written
   VectorDrawables** (`drawable/ic_launcher_foreground.xml`,
   `ic_launcher_monochrome.xml`), with path data copied from the SVGs. The
   themed icon cuts the band out of the bowl with a straight cut: the bowl is
   drawn as a rim and a base, because VectorDrawable has no mask.
3. **One brand-green colour resource**: the adaptive icon's background is
   `@color/splash_background`, the same resource as the launch screen.
4. **The raster icons** (the legacy `mipmap-*` PNGs for API 24–25, iOS
   `AppIcon`, iOS `LaunchImage`) are rendered by `tool/gen_app_icons.py`
   (`make icons`) through headless Chrome and PIL, and committed. The iOS
   icons are opaque RGB and not pre-rounded.
5. **The launch screen gets the mark** (amends D128 §5's "no icon"): the
   foreground centred on a 288dp canvas before Android 12, and as
   `windowSplashScreenAnimatedIcon` on 12+. The green stays the same in both
   phone modes, with no `values-night`. iOS's `LaunchScreen.storyboard` turns
   the same green, with the same mark.
6. **The launcher label stays "Kitchen Table"** in both locales, and there is
   no in-app lockup: the sign-in screen is unchanged.

**Why.**
- The user chose the logo and chose to put the mark on the splash. D128's
  green was already the brand colour, so the icon ground and the splash
  can't drift apart if the colour lives in one resource.
- 288dp is Android 12's canvas for a splash icon without a background, so
  the mark is the same size either side of 12.
- A straight band cut in the themed icon: the SVG mask's rounded band ends
  differ by slivers too small to see at icon size.

**Rejected.**
- `flutter_launcher_icons` or any other icon package (rule 8).
- A second colour resource for the icon background.
- "Za stolom" as the launcher label. It was proposed, not adopted
  (`docs/IDEAS.md`).
- Shipping the Literata lockups or an in-app wordmark in this slice.

**Consequences.**
- When `docs/design/logo/` changes, run `make icons` *and* edit the two
  VectorDrawables by hand. The script doesn't touch them.
- The script needs Google Chrome in /Applications, and
  `--default-background-color=00000000` (hex RGBA). With `0`, Chrome exits
  without writing a screenshot.
- If the brand green changes, `values/colors.xml`, the SVGs, the storyboard
  colour and the rendered PNGs all change with it.
