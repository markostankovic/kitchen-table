## D76 — The global offline banner lives in `core/net/`, and does not replace the per-screen "saved copy" lines

**Decided.** `OfflineBanner` (`lib/core/net/offline_banner.dart`), rendered
by `AppShell` above the tab body — one instance, visible on every tab
including Settings, on `Reachability.offline` only, never on
`Reachability.unknown`. The per-screen "Showing your saved copy — no
connection." lines the shopping list (part 5) and the meal plan (this part)
already render stay exactly as they were.

**Why.** The two say different things. The banner says "the phone cannot
reach the server, and nothing you change will save" — a fact about the
session, true on every screen including one (Settings) with no cache of its
own to ever be stale. The per-screen line says "this particular list/week is
not what the server has right now" — a narrower claim about the data
actually on screen, rendered only where a cache hit is showing. Deleting the
narrower line in favour of the banner, to avoid the appearance of
duplication, would lose the provenance claim, which is the one a cook
actually needs standing next to a list before trusting it.

`Reachability.unknown` is deliberately excluded: it means no read has
completed yet this session (`network_status.dart`'s own definition), and a
banner rendered before anything has actually failed would be a guess dressed
as a fact — the same discipline the per-screen line already followed.

This supersedes the note at the bottom of `shopping_list_screen.dart`'s
`_GeneratedAt` doc comment, which called a global banner "part 7's job" —
updated in place rather than left to contradict the code, since it shipped
in part 6b instead.

**Rejected.**
- Replacing the per-screen lines with the banner alone — loses the
  provenance claim above for no gain; the two cost one small widget each and
  answer different questions.
- Showing the banner on `Reachability.unknown` too, so a cold start with no
  network never looks falsely "online" — considered and rejected: the first
  read after launch resolves `unknown` within moments in the common case,
  and a banner that can flash on before the first real signal is a worse
  failure than a half-second gap with no banner at all.
