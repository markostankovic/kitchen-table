# D177 — Sign-in drops the illustration per design round 4
**Status:** active — supersedes the illustration half of D137 #1
**Touches:** lib/features/auth/presentation/sign_in_screen.dart, lib/core/theme/app_sizes.dart, test/features/auth/sign_in_screen_test.dart, docs/DESIGN_SYSTEM.md

**Decided.** The sign-in screen has no illustration. The lockup leads the
content block, then the tagline, then the failure line when there is one.
The block stays centred vertically in the space above the pinned Google
button (`Expanded` → `Center` → `SingleChildScrollView` → `Column`, as
before).
- `SignInIllustration` (the `CustomPainter` recipe card) and its file are
  deleted, and so is the `xxl + sm` (40) gap under it.
- `AppSizes.signInIllustration` (176) is removed, with its § Size and
  motion row and the `assets/recipe-card.png` row in § Token map.
- Nothing else on the screen moves. The lockup (a light or dark PNG, English
  in `sr`), its 48 height, the `lg` to the tagline, the outlined neutral
  52dp button (D137 #2) and the dev-login button (D125) stand.
- No asset goes away: the painter never used the bundle's PNG, so
  `assets/brand/`, `pubspec.yaml` and `tool/gen_app_icons.py` are untouched.

**Why.** Design round 4
(`docs/design/handoffs/2026-10-16-round-4-recipe-detail-signin/`) removes
the illustration from the sign-in frame. The rest of the mock (padding
`0 24 32`, lockup 48, tagline margin `16 16 0`, button 52) already matched
the code, so deleting the illustration and its gap was the whole change.

**Rejected.**
- Keeping `AppSizes.signInIllustration` for later. A token with no caller
  is drift; it can come back with a new illustration.
- Top-aligning the shorter block. The canvas keeps it centred, and the
  pinned button already gives the screen its bottom anchor.
- Moving any other spacing to fill the space. The mock didn't ask for it.

**Consequences.** A widget test checks the lockup `Image` is the first
child of its nearest `Column`, so an illustration coming back would fail
it on purpose. D137 #2–#4 are unaffected.
