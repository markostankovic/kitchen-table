## D39 — Clients never write `import_jobs`

**Decided.** RLS on `import_jobs`, `ai_usage` and `household_ai_limits` grants
`SELECT` and nothing else. No INSERT policy, no UPDATE policy, no DELETE
policy. The job row is created by the import Edge Function on the service role,
and the client's entire write surface is two `security definer` functions,
`finish_import_job` and `dismiss_import_job`.

**Why.** RLS cannot restrict which *columns* an update touches. A policy
permissive enough to let the confirm screen set `recipe_id` is permissive enough
to let any client set `status = 'needs_review'` with a hand-written `result` —
which would turn the import queue into an arbitrary-JSON store that the confirm
screen renders and a human is then asked to trust.

Creating the row server-side also means the household is resolved from the
caller's membership rather than named by the client, which is the same argument
`create-invite` makes.

**Consequence.** Those two functions are `security definer` and therefore
bypass RLS, so each writes its membership check out by hand — the rule
`_shared/auth.ts` states for the service-role client, applied in SQL. Note this
is the opposite choice from D36's `replace_recipe_lines`, which could be
`security invoker` precisely because `recipe_ingredients` *has* write policies.
