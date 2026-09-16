## D45 — The SSRF policy for `import-url`

**Decided.** `supabase/functions/_shared/url_guard.ts`. http/https only, no
credentials in the URL, no non-standard port, a denylist covering every private
and reserved IPv4 and IPv6 range, every single-label hostname, a DNS resolution
check on every hostname, redirects followed by hand with each hop re-vetted, a
10-second timeout, a 2 MB ceiling counted from bytes that actually arrive, and
a Content-Type check. The URL is vetted before a job row exists, so a refusal is
a synchronous 400.

**Why.** `import-url` is the only place in the project that opens a connection
to a host somebody else chose, and it does so from inside Supabase's network
holding the service role key. Unguarded it reaches `http://kong:8000`,
`http://db:5432` and, on a cloud host, `http://169.254.169.254/` — which is how
a recipe importer becomes a credential exfiltration tool.

**Why single-label hostnames as a class.** Inside Docker and inside Supabase's
network, services are reachable by bare name. Enumerating them would be a list
to maintain; refusing every name with no dot in it is the same protection with
nothing to keep up to date, and no real recipe site is reachable that way.

**Why the helper returns null rather than raising.** An exception inside a
policy or a guard is not a refusal. `storage_path_household` (D46) makes the
same choice for the same reason.

**What it does not stop.** DNS rebinding between the check and the connect.
Deno's `fetch` cannot pin a resolved address. Written in the file rather than
left to be discovered.
