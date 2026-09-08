/**
 * SSRF defence for import-url.
 *
 * This is the only place in the project that fetches a URL somebody else
 * chose, and it does so from inside Supabase's network while the handler holds
 * the service role key. An unguarded fetch here reaches `http://kong:8000`,
 * `http://db:5432`, and on a cloud host `http://169.254.169.254/`, which is
 * how a recipe importer becomes a credential exfiltration tool.
 *
 * docs/ROADMAP.md flagged this from Phase 1d part 1 onward and no document had
 * ruled on it. This file is the ruling (D45).
 *
 * Everything except `safeFetch` is a pure function, so the denylist is a thing
 * a test can enumerate rather than a thing that has to be exercised over the
 * network. `url_guard_test.ts` does exactly that.
 *
 * WHAT THIS DOES NOT STOP, stated plainly rather than left to be discovered:
 * DNS rebinding. The address is checked and then `fetch` resolves the name
 * again; Deno offers no way to pin a resolved address to a connection. The
 * window is small and the payoff for an attacker is one request to an internal
 * service whose response they never see -- `safeFetch` returns the body to a
 * parser, and a failed parse fails the job without echoing anything.
 */

import { HttpError } from "./http.ts";

/** Ten seconds. A recipe page that is slower than this is not worth waiting for. */
const TIMEOUT_MS = 10_000;

/** 2 MB. Enough for any recipe page with its inline CSS; far short of a video. */
const MAX_BYTES = 2 * 1024 * 1024;

/** Enough for the http->https and apex->www hops real sites use, and no more. */
const MAX_REDIRECTS = 3;

const USER_AGENT =
  "KitchenTable/1.0 (+recipe import; https://github.com/kitchen-table)";

/**
 * Hostnames that never belong to a public recipe site.
 *
 * The single-label rule is the one that matters most here: inside Docker and
 * inside Supabase's network, services are reachable by bare name -- `kong`,
 * `db`, `auth`, `rest`, `storage`. Enumerating them would be a list to keep up
 * to date; refusing every name with no dot in it is the same protection with
 * nothing to maintain, and no real recipe site is reachable that way.
 */
const BLOCKED_SUFFIXES = [
  ".local",
  ".localhost",
  ".localdomain",
  ".internal",
  ".intranet",
  ".home.arpa",
];

export function isBlockedHost(hostname: string): boolean {
  const host = hostname.toLowerCase();

  if (host.length === 0) return true;
  if (host === "localhost") return true;
  for (const suffix of BLOCKED_SUFFIXES) {
    if (host.endsWith(suffix)) return true;
  }

  // An IPv6 literal arrives from `URL` still wrapped in brackets.
  if (host.startsWith("[") && host.endsWith("]")) {
    return isBlockedAddress(host.slice(1, -1));
  }

  // A dotted-decimal IPv4 literal. Note that `new URL` has ALREADY normalised
  // the integer, octal and hex spellings into this form -- `http://2130706433/`
  // arrives here as `127.0.0.1` -- so there is no second encoding to catch.
  if (/^\d+\.\d+\.\d+\.\d+$/.test(host)) return isBlockedAddress(host);

  // No dot at all: a container name, not a domain.
  if (!host.includes(".")) return true;

  // A trailing dot is the DNS root, and `example.com.` is the same host as
  // `example.com` -- but a bare `.` is not a host.
  if (host === ".") return true;

  return false;
}

/** True if [ip] is anything other than a routable public address. */
export function isBlockedAddress(ip: string): boolean {
  const v4 = parseIpv4(ip);
  if (v4 !== null) return isBlockedIpv4(v4);

  const v6 = parseIpv6(ip);
  if (v6 !== null) return isBlockedIpv6(v6);

  // Unparseable. Refuse rather than guess -- an address shape neither branch
  // recognises is not one to hand to `fetch`.
  return true;
}

function parseIpv4(ip: string): number[] | null {
  const parts = ip.split(".");
  if (parts.length !== 4) return null;

  const octets: number[] = [];
  for (const part of parts) {
    if (!/^\d{1,3}$/.test(part)) return null;
    const value = Number(part);
    if (value > 255) return null;
    octets.push(value);
  }
  return octets;
}

function isBlockedIpv4(o: number[]): boolean {
  const [a, b] = o;

  if (a === 0) return true; // 0.0.0.0/8 "this network"
  if (a === 10) return true; // private
  if (a === 127) return true; // loopback
  if (a === 169 && b === 254) return true; // link-local, incl. 169.254.169.254
  if (a === 172 && b >= 16 && b <= 31) return true; // private
  if (a === 192 && b === 168) return true; // private
  if (a === 100 && b >= 64 && b <= 127) return true; // CGNAT 100.64/10
  if (a === 192 && b === 0 && o[2] === 0) return true; // IETF protocol assignments
  if (a === 192 && b === 0 && o[2] === 2) return true; // TEST-NET-1
  if (a === 198 && (b === 18 || b === 19)) return true; // benchmarking
  if (a === 198 && b === 51 && o[2] === 100) return true; // TEST-NET-2
  if (a === 203 && b === 0 && o[2] === 113) return true; // TEST-NET-3
  if (a >= 224) return true; // multicast 224/4 and reserved 240/4, incl. 255.255.255.255

  return false;
}

/** Eight 16-bit groups, or null. Handles `::` elision and a trailing IPv4. */
function parseIpv6(ip: string): number[] | null {
  let text = ip;

  // A zone index (`fe80::1%eth0`) is not ours to interpret, and a link-local
  // address is refused anyway.
  const zone = text.indexOf("%");
  if (zone >= 0) text = text.slice(0, zone);

  // A trailing dotted-quad, as in `::ffff:127.0.0.1`, becomes two groups.
  const lastColon = text.lastIndexOf(":");
  const tail = lastColon >= 0 ? text.slice(lastColon + 1) : "";
  if (tail.includes(".")) {
    const v4 = parseIpv4(tail);
    if (v4 === null) return null;
    const hi = ((v4[0] << 8) | v4[1]).toString(16);
    const lo = ((v4[2] << 8) | v4[3]).toString(16);
    text = `${text.slice(0, lastColon + 1)}${hi}:${lo}`;
  }

  const halves = text.split("::");
  if (halves.length > 2) return null;

  const toGroups = (part: string): number[] | null => {
    if (part.length === 0) return [];
    const out: number[] = [];
    for (const piece of part.split(":")) {
      if (!/^[0-9a-fA-F]{1,4}$/.test(piece)) return null;
      out.push(parseInt(piece, 16));
    }
    return out;
  };

  const head = toGroups(halves[0]);
  const rest = halves.length === 2 ? toGroups(halves[1]) : null;
  if (head === null) return null;
  if (halves.length === 2 && rest === null) return null;

  if (halves.length === 1) {
    return head.length === 8 ? head : null;
  }

  const tailGroups = rest as number[];
  const missing = 8 - head.length - tailGroups.length;
  if (missing < 0) return null;
  return [...head, ...new Array<number>(missing).fill(0), ...tailGroups];
}

function isBlockedIpv6(g: number[]): boolean {
  const allZero = g.every((x) => x === 0);
  if (allZero) return true; // ::
  if (g.slice(0, 7).every((x) => x === 0) && g[7] === 1) return true; // ::1

  // IPv4-mapped (::ffff:a.b.c.d) and IPv4-compatible (::a.b.c.d). Both carry a
  // v4 address in the low 32 bits, and `::ffff:7f00:1` is `127.0.0.1` wearing a
  // different hat -- so the v4 rules have to run on it.
  const lowSix = g.slice(0, 6);
  const mapped = lowSix.slice(0, 5).every((x) => x === 0) &&
    (g[5] === 0xffff || g[5] === 0);
  if (mapped) {
    const v4 = [g[6] >> 8, g[6] & 0xff, g[7] >> 8, g[7] & 0xff];
    return isBlockedIpv4(v4);
  }

  if ((g[0] & 0xfe00) === 0xfc00) return true; // fc00::/7 unique-local
  if ((g[0] & 0xffc0) === 0xfe80) return true; // fe80::/10 link-local
  if ((g[0] & 0xff00) === 0xff00) return true; // ff00::/8 multicast
  if (g[0] === 0x2001 && g[1] === 0x0db8) return true; // documentation

  return false;
}

/**
 * Parses and vets a URL the client sent, or throws.
 *
 * Called before the job row exists, so a refusal is a synchronous 400 with a
 * code the client can render -- not a queued job that fails a second later.
 * Also called again on every redirect hop, which is the point: a public URL
 * that 302s to the metadata endpoint is the attack this file exists for, and
 * checking only the first URL would miss all of it.
 */
export function parseImportUrl(raw: string): URL {
  let url: URL;
  try {
    url = new URL(raw.trim());
  } catch {
    throw new HttpError(400, "invalid_url", "That does not look like a link.");
  }

  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new HttpError(
      400,
      "url_not_allowed",
      "Only web links can be imported.",
    );
  }

  // Credentials in a URL are never a recipe page, and they would be sent to
  // whatever the host turns out to be.
  if (url.username.length > 0 || url.password.length > 0) {
    throw new HttpError(400, "url_not_allowed", "That link cannot be opened.");
  }

  // A non-default port on a public site is legitimate but rare, and it is how
  // an internal service is usually addressed. Refusing it costs little.
  if (url.port.length > 0 && url.port !== "80" && url.port !== "443") {
    throw new HttpError(400, "url_not_allowed", "That link cannot be opened.");
  }

  if (isBlockedHost(url.hostname)) {
    throw new HttpError(400, "url_not_allowed", "That link cannot be opened.");
  }

  return url;
}

/**
 * Resolves [url]'s hostname and refuses it if any address is private.
 *
 * The literal checks above stop `http://127.0.0.1`; this stops
 * `http://my-evil-domain.example` that happens to have an A record pointing
 * there, which nothing else would catch.
 *
 * If `Deno.resolveDns` is unavailable in this runtime, this logs loudly and
 * returns -- the literal checks still stand, and refusing every import because
 * one defence in depth is missing would be the wrong trade. A resolution that
 * FAILS, by contrast, is fatal: a name that cannot be resolved is not one to
 * hand to `fetch`.
 */
async function assertPublicAddress(url: URL): Promise<void> {
  if (typeof Deno.resolveDns !== "function") {
    console.error(
      "Deno.resolveDns unavailable: import-url is running on hostname " +
        "checks alone, so a public name resolving to a private address is " +
        "not caught",
    );
    return;
  }

  // An IP literal has already been checked directly; there is nothing to look
  // up and resolveDns would fail on it.
  const host = url.hostname;
  if (/^\d+\.\d+\.\d+\.\d+$/.test(host) || host.startsWith("[")) return;

  const addresses: string[] = [];
  for (const type of ["A", "AAAA"] as const) {
    try {
      addresses.push(...await Deno.resolveDns(host, type));
    } catch {
      // A missing AAAA record is normal, so one empty answer is not an error.
      // Both empty is handled below.
    }
  }

  if (addresses.length === 0) {
    throw new HttpError(400, "fetch_failed", "That site could not be reached.");
  }

  for (const address of addresses) {
    if (isBlockedAddress(address)) {
      throw new HttpError(
        400,
        "url_not_allowed",
        "That link cannot be opened.",
      );
    }
  }
}

/**
 * Fetches [url] and returns its body as text.
 *
 * Redirects are followed by hand so each hop can be vetted. `fetch`'s own
 * redirect following would take the first Location without asking.
 */
export async function safeFetch(url: URL): Promise<{ html: string; url: URL }> {
  let current = url;

  for (let hop = 0; hop <= MAX_REDIRECTS; hop++) {
    await assertPublicAddress(current);

    let res: Response;
    try {
      res = await fetch(current, {
        redirect: "manual",
        signal: AbortSignal.timeout(TIMEOUT_MS),
        headers: {
          "User-Agent": USER_AGENT,
          "Accept": "text/html,application/xhtml+xml",
          "Accept-Language": "sr,en;q=0.8",
        },
      });
    } catch (e) {
      console.error(`fetch failed for ${current.hostname}`, e);
      throw new HttpError(
        400,
        "fetch_failed",
        "That page could not be fetched.",
      );
    }

    if (res.status >= 300 && res.status < 400) {
      const location = res.headers.get("location");
      // The body of a redirect is nothing, but it still has to be consumed or
      // the connection leaks.
      await res.body?.cancel();

      if (!location) {
        throw new HttpError(400, "fetch_failed", "That link goes nowhere.");
      }
      // Re-vetted, not trusted. This is the hop that matters.
      current = parseImportUrl(new URL(location, current).toString());
      continue;
    }

    if (!res.ok) {
      await res.body?.cancel();
      throw new HttpError(
        400,
        "fetch_failed",
        "That page could not be fetched.",
      );
    }

    const contentType = res.headers.get("content-type") ?? "";
    if (
      !/^(text\/html|application\/xhtml\+xml|text\/plain)/i.test(contentType)
    ) {
      await res.body?.cancel();
      throw new HttpError(400, "not_html", "That link is not a web page.");
    }

    return { html: await readCapped(res), url: current };
  }

  throw new HttpError(
    400,
    "fetch_failed",
    "That link redirects too many times.",
  );
}

/**
 * Reads at most MAX_BYTES, then gives up.
 *
 * Deliberately not a `Content-Length` check: that header is a claim, and a
 * server that wants to exhaust this worker simply omits it or lies. Counting
 * what actually arrives is the only number that is true.
 */
async function readCapped(res: Response): Promise<string> {
  const body = res.body;
  if (!body) return "";

  const reader = body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      total += value.byteLength;
      if (total > MAX_BYTES) {
        throw new HttpError(400, "page_too_large", "That page is too large.");
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
    await body.cancel().catch(() => {});
  }

  const joined = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    joined.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return new TextDecoder("utf-8", { fatal: false }).decode(joined);
}
