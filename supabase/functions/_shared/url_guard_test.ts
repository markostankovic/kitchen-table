/**
 * The SSRF denylist, enumerated.
 *
 * `parseImportUrl` is the only thing standing between a recipe importer and
 * every service reachable from inside Supabase's network, so it is tested as a
 * table rather than by example: each row is a URL and the verdict it must get.
 * A rule that stops working fails one named row here instead of failing
 * silently in production.
 *
 * Pure -- no network, no permissions beyond what `make test-functions` grants.
 *
 * Run: make test-functions
 */

import { assert, assertEquals } from "jsr:@std/assert@1";
import { HttpError } from "./http.ts";
import {
  isBlockedAddress,
  isBlockedHost,
  parseImportUrl,
} from "./url_guard.ts";

function verdict(raw: string): "allowed" | string {
  try {
    parseImportUrl(raw);
    return "allowed";
  } catch (e) {
    if (e instanceof HttpError) return e.code;
    throw e;
  }
}

// ---------------------------------------------------------------------------
// Blocked
// ---------------------------------------------------------------------------

const BLOCKED: [string, string][] = [
  // The loopback, spelled every way a URL can spell it. `new URL` normalises
  // the integer, octal and hex forms to dotted-decimal before we ever see
  // them, which is why one rule catches all four.
  ["http://127.0.0.1/", "127.0.0.1"],
  ["http://127.0.0.1:54321/", "the local Supabase gateway"],
  ["http://localhost/", "localhost by name"],
  ["http://localhost:54321/", "localhost with the API port"],
  ["http://2130706433/", "127.0.0.1 as a decimal integer"],
  ["http://0x7f.0.0.1/", "127.0.0.1 with a hex first octet"],
  ["http://017700000001/", "127.0.0.1 in octal"],
  ["http://127.1/", "127.0.0.1 in short form"],
  ["http://[::1]/", "the IPv6 loopback"],
  ["http://[::ffff:127.0.0.1]/", "the IPv4-mapped loopback"],
  ["http://[::]/", "the unspecified address"],

  // The cloud metadata endpoint. On a hosted runtime this is the one that
  // hands out credentials.
  ["http://169.254.169.254/latest/meta-data/", "the cloud metadata endpoint"],
  ["http://169.254.170.2/", "the ECS task metadata endpoint"],

  // Docker and Supabase service names. Single-label hostnames are refused as a
  // class, so there is no list of service names to keep up to date.
  ["http://kong:8000/", "the Supabase gateway by container name"],
  ["http://db:5432/", "Postgres by container name"],
  ["http://auth/", "the auth service by container name"],
  ["http://supabase_kong_kitchen-table/", "the container's full name"],
  ["http://host.docker.internal/", "the Docker host escape hatch"],
  ["http://something.local/", "an mDNS name"],
  ["http://api.internal/", "an internal TLD"],

  // Private ranges.
  ["http://10.0.0.1/", "10/8"],
  ["http://172.16.0.1/", "172.16/12, low end"],
  ["http://172.31.255.254/", "172.16/12, high end"],
  ["http://192.168.1.1/", "192.168/16"],
  ["http://100.64.0.1/", "carrier-grade NAT"],
  ["http://0.0.0.0/", "the unspecified address"],
  ["http://255.255.255.255/", "broadcast"],
  ["http://224.0.0.1/", "multicast"],
  ["http://[fd00::1]/", "IPv6 unique-local"],
  ["http://[fe80::1]/", "IPv6 link-local"],

  // Schemes that are not the web.
  ["file:///etc/passwd", "the file scheme"],
  ["gopher://example.com/", "an exotic scheme"],
  ["data:text/html,<h1>hi", "a data URL"],
  ["ftp://example.com/", "ftp"],

  // Shapes that are legitimate on the web but are how internal services get
  // addressed in practice.
  ["http://user:pass@example.com/", "credentials in the URL"],
  ["http://example.com:8080/", "a non-standard port"],
  ["http://example.com:22/", "ssh's port"],

  ["not a url at all", "a string that is not a URL"],
  ["", "an empty string"],
];

for (const [url, why] of BLOCKED) {
  Deno.test(`blocks ${why}: ${url || "(empty)"}`, () => {
    const got = verdict(url);
    assert(
      got === "invalid_url" || got === "url_not_allowed",
      `expected a refusal, got ${got}`,
    );
  });
}

// ---------------------------------------------------------------------------
// Allowed
// ---------------------------------------------------------------------------

const ALLOWED: string[] = [
  "https://www.seriouseats.com/classic-panzanella-salad-recipe",
  "http://example.com/recipes/1",
  "https://example.com:443/x",
  "http://example.com:80/x",
  "https://recepti.coolinarika.com/recept/torta/",
  "https://sub.domain.example.co.uk/a/b?c=d#e",
  // A public address that merely looks close to a private range.
  "http://172.32.0.1/",
  "http://11.0.0.1/",
  "http://192.169.0.1/",
  "http://100.128.0.1/",
  "http://126.0.0.1/",
  "http://128.0.0.1/",
];

for (const url of ALLOWED) {
  Deno.test(`allows ${url}`, () => {
    assertEquals(verdict(url), "allowed");
  });
}

// ---------------------------------------------------------------------------
// Boundaries, where an off-by-one would open a hole
// ---------------------------------------------------------------------------

Deno.test("the 172.16/12 range stops exactly where it should", () => {
  assertEquals(isBlockedAddress("172.15.255.255"), false);
  assertEquals(isBlockedAddress("172.16.0.0"), true);
  assertEquals(isBlockedAddress("172.31.255.255"), true);
  assertEquals(isBlockedAddress("172.32.0.0"), false);
});

Deno.test("the 100.64/10 range stops exactly where it should", () => {
  assertEquals(isBlockedAddress("100.63.255.255"), false);
  assertEquals(isBlockedAddress("100.64.0.0"), true);
  assertEquals(isBlockedAddress("100.127.255.255"), true);
  assertEquals(isBlockedAddress("100.128.0.0"), false);
});

Deno.test("169.254/16 is blocked in full, not just the metadata address", () => {
  // Blocking only 169.254.169.254 would leave every other link-local service
  // reachable, and there is no reason a recipe lives on any of them.
  assertEquals(isBlockedAddress("169.254.0.1"), true);
  assertEquals(isBlockedAddress("169.254.169.254"), true);
  assertEquals(isBlockedAddress("169.253.255.255"), false);
});

Deno.test("an unparseable address is refused rather than guessed at", () => {
  assertEquals(isBlockedAddress("999.999.999.999"), true);
  assertEquals(isBlockedAddress("not-an-address"), true);
  assertEquals(isBlockedAddress(""), true);
});

Deno.test("a single-label hostname is blocked, a dotted one is not", () => {
  assertEquals(isBlockedHost("kong"), true);
  assertEquals(isBlockedHost("db"), true);
  assertEquals(isBlockedHost("example.com"), false);
});

Deno.test("refusals carry a code the client can render", () => {
  // `default:` in _fromFunction drops the server's message entirely, so a code
  // that is not mapped shows the cook nothing useful.
  assertEquals(verdict("file:///etc/passwd"), "url_not_allowed");
  assertEquals(verdict("http://169.254.169.254/"), "url_not_allowed");
  assertEquals(verdict("nonsense"), "invalid_url");
});
