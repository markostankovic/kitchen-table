# Active slices

Transient handoff files written by `/plan-slice` and consumed by
`/build-slice`, one per in-flight slice of work. `/close-slice` deletes the
file when the slice is recorded into `docs/journal/`, `docs/decisions/`,
`docs/STATE.md`, and `docs/ROADMAP.md`.

Nothing here is meant to survive past the slice it describes. If a file in
this directory is stale (its slice already shipped, per `git log`), delete
it rather than trusting it.
