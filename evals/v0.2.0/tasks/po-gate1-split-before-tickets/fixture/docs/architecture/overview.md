# Architecture Overview

- `src/contacts.ts` — contact listing, search, and tagging logic (server-side).
- REST API consumed by the web frontend; the mobile app (separate repo) talks to the
  same API but is versioned and released independently.
- No background-job infrastructure; all requests are synchronous.
