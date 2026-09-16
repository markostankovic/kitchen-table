## D48 — The recipe's own photo: a second private bucket, signed URLs, upload only on save

**Decided.** Phase 2 part 1 gives `recipes.image_path` (shipped empty since
migration 8, D35) a bucket: `recipe-images`, private, 5 MB, images only, at
`recipe-images/{household_id}/{name}.jpg` — the same shape as `import-uploads`
(D46), reading the household through the same `storage_path_household(text)`
rather than a second copy of it. Four things were decided together.

**A second bucket, not a reuse of `import-uploads`.** An import upload is an
*input* to a job that finishes; a dish photo is part of a recipe that
persists. D46 already said every policy should name its bucket precisely so a
later bucket could not inherit them by accident — this is that later bucket.

**Private, served through signed URLs, not public.** The bucket also holds
photos attached to `ocr` and `url_import` recipes, which D16 makes
permanently household-scoped. A public bucket would put those behind an
unauthenticated URL, exactly the path D16 says does not exist. There is no
public reader in the app regardless — `recipes.visibility` has one legal
value — so this costs one round trip (`createSignedUrlsResult`, batched per
list page) for a guarantee D16 already promised. Revisit only alongside
Phase 4's read-only web page.

**The upload happens inside `RecipeEditor.save()`, never at pick time.** The
edit screen holds a picked photo's bytes in memory (`RecipeImageUpload`) and
previews from them directly; nothing reaches Storage until `save()` is
called, and it uploads before touching the recipe row so the slow step
happens under the cook's finger. An abandoned editor therefore leaves no
orphan object — the same failure mode D46 already lists as open for import
photos is not repeated here by construction, rather than solved for both.

**No UPDATE policy; the old object is deleted after the row is overwritten.**
Same instinct as `import-uploads` and `ai_usage` (D38): replacing a photo
writes a new object under a new name, and the old one is removed once nothing
points at it. Deletion is best-effort — logged and swallowed, never surfaced —
because the recipe itself already saved, and a leftover blob is a smaller
problem than telling the cook their save failed when it didn't.

**Consequence.** `RecipeRepository.uploadImage`/`deleteImage` are the only new
Supabase calls; `_withImageUrls` mirrors `_withDisplayNames`'s one-round-trip
shape and uses `createSignedUrlsResult` rather than the deprecated
`createSignedUrls` specifically so one missing object degrades to no picture
(rule 3) instead of failing the whole list.
