## D38 — `ai_usage` is an append-only ledger, with no lifecycle columns

**Decided.** `ai_usage` carries `household_id` and therefore falls under rule 4
as written, but gets neither `updated_at` nor `deleted_at`. A row is inserted
once by the service role immediately after a model call and never touched
again.

**Why.** The same shape of exception as D25, for a different reason. A ledger
whose rows can be updated is not a ledger, and a tombstoned cost row is a hole
in a cost audit that still bills. D17 put usage limits in from day one so that
an OCR retry loop cannot quietly burn money; a ledger that can be edited or
hidden would give that mechanism nothing solid to stand on.

**Consequence, stated so it is a choice rather than a surprise.** There is no
way to correct a mis-recorded row and no way to hide one. Both are correct for
money. If usage ever needs resetting per billing period, that is a column
recording the period, not a delete.

`household_ai_limits` does get `updated_at` — caps are meant to be tuned — and
no `deleted_at`, because its primary key *is* the household id and it cascades.
