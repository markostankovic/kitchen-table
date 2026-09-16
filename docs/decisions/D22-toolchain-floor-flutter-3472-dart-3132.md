## D22 — Toolchain floor: Flutter 3.47.2 / Dart 3.13.2

**Decided.** The project requires Dart >= 3.13. `pubspec.yaml` pins
`sdk: ^3.13.2`.

**Why.** freezed 4.x, riverpod_lint 3.1.9 and riverpod_generator 4.0.9 all
require analyzer 13, which requires Dart 3.13. On Dart 3.12 no combination of
these resolves — pub's own diagnostic recommends upgrading the SDK.

**Consequence, and it will bite again.** `riverpod_lint` depends on `riverpod`
at an **exact** version (3.1.9 → `riverpod 3.4.3`). So `flutter_riverpod` and
`riverpod_annotation` cannot be bumped independently: all four move in
lockstep, or version solving fails with an error that misleadingly blames
`freezed_annotation`.
