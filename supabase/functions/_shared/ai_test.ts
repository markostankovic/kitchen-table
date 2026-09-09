/**
 * The arithmetic behind the spending cap.
 *
 * `cost_micros` is the number D17's cost cap is compared against, and it is
 * computed in exactly one place. If it is wrong, the cap is wrong in the same
 * direction and nothing else in the system notices -- there is no second
 * source to disagree with it. Hence a test for what looks like a multiplication.
 *
 * Run: make test-functions
 */

import { assertEquals } from "jsr:@std/assert@1";
import { costMicros, MODEL_CAPABILITIES, MODELS, PRICING } from "./ai.ts";

Deno.test("every model the code can select has a price", () => {
  // The guard that matters when a model id changes: an unpriced model records
  // cost_micros = 0, which silently makes the cost cap unreachable.
  for (const model of Object.values(MODELS)) {
    if (!PRICING[model]) {
      throw new Error(`MODELS.${model} has no entry in PRICING`);
    }
  }
});

Deno.test("every model the code can select declares its capabilities", () => {
  // The guard that would have caught tier 4 being broken from the day it was
  // written. `callStructured` used to send `thinking: adaptive` to every
  // model; Haiku 4.5 answers that with a 400, and the best-effort catch above
  // tier 4 turned the 400 into a silent degradation that lasted three parts.
  for (const model of Object.values(MODELS)) {
    if (!MODEL_CAPABILITIES[model]) {
      throw new Error(`MODELS.${model} has no entry in CAPABILITIES`);
    }
  }
});

Deno.test("Haiku 4.5 is not sent adaptive thinking", () => {
  // Named explicitly rather than left to the loop above, because this exact
  // pairing is the bug.
  assertEquals(MODEL_CAPABILITIES[MODELS.MATCHING].adaptiveThinking, false);
  assertEquals(MODEL_CAPABILITIES[MODELS.PROSE].adaptiveThinking, true);
});

Deno.test("Opus 5 at one million tokens each way", () => {
  // $5 in + $25 out = $30 = 30_000_000 micro-dollars.
  assertEquals(costMicros("claude-opus-5", 1_000_000, 1_000_000), 30_000_000);
});

Deno.test("Haiku 4.5 at one million tokens each way", () => {
  // $1 in + $5 out = $6.
  assertEquals(costMicros("claude-haiku-4-5", 1_000_000, 1_000_000), 6_000_000);
});

Deno.test("a realistic import rounds to whole micro-dollars", () => {
  // A cookbook page: ~3k in, ~1.5k out on Opus 5.
  //   3000 * 5 / 1e6  = $0.015
  //   1500 * 25 / 1e6 = $0.0375
  //   total $0.0525 -> 52500 micros
  assertEquals(costMicros("claude-opus-5", 3_000, 1_500), 52_500);
});

Deno.test("a sub-micro call does not round away to nothing", () => {
  // One input token on Haiku is $0.000001 exactly -- one micro-dollar. The
  // floor of this is where a per-call cost silently becomes free.
  assertEquals(costMicros("claude-haiku-4-5", 1, 0), 1);
});

Deno.test("an unpriced model records zero rather than throwing", () => {
  // Deliberate: losing a parsed recipe because the price table is stale would
  // be a worse trade than under-counting one call. The row still lands with
  // its token counts, so the gap is visible in the ledger.
  assertEquals(costMicros("claude-not-a-model", 1_000, 1_000), 0);
});
