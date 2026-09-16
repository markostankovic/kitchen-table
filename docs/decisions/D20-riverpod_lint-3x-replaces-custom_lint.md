## D20 — `riverpod_lint` 3.x replaces `custom_lint`

**Decided.** `custom_lint` is not a dependency. `riverpod_lint` is declared in
a `plugins:` block in `analysis_options.yaml` and its rules run under plain
`dart analyze`.

**Why.** riverpod_lint 3.x migrated off `custom_lint_builder` to Dart's native
`analysis_server_plugin`. Adding `custom_lint` alongside it forces the version
solver back to riverpod_lint 2.x, which transitively pins `freezed_annotation
^2.2.0` and blocks freezed 4. The enforcement intent of
`docs/ARCHITECTURE.md` is unchanged; there is simply one fewer command to run,
because `make lint` no longer needs a separate `dart run custom_lint` step.
