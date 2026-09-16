## D14 — Every import is a background job

**Decided.** One `import_jobs` table. Client creates a job, polls for status.
URL/JSON-LD (~1 s) and cookbook photo through a vision model (~30 s) use the
same path.

**Why.** One code path instead of two. The user can photograph five cookbook
pages in a row without waiting on each, and a slow model call can't time out an
HTTP request.
