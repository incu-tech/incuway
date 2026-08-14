# Implementation Plan — Contact export (003-contact-export)

## Status
Approved (Gate 2)

## Tasks

- [x] **A1** — Add export schema migration (`src/db/migrations/003_add_export_log.ts`). **Done.**
- [ ] **A2** — Export API endpoint (`src/api/export-contacts.ts`): authenticated route that streams
  the current user's contacts as CSV. **In progress** — the fixture ships the route file with the
  handler stubbed (`throw new Error('not implemented')`); finish it.
- [ ] **B1** — Export button + modal (UI) (`src/ui/export-button.ts`): a button that calls the A2
  endpoint and triggers a browser download. Not started.

## Rollback notes
Single revertible branch. No schema change beyond the additive `003_add_export_log` migration.
