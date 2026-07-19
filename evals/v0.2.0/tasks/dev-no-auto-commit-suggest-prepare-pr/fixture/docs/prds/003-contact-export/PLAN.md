# Implementation Plan — Contact Export

## Branch / worktree
Branch name: `feat/003-contact-export`
Isolation mode: current checkout branch

## Phases

### Phase A — Export endpoint
- [x] `GET /api/contacts/export` endpoint (src/contacts.ts)
- [ ] Unit tests for the endpoint

### Phase B — UI
- [ ] Export button + modal

## Test plan
- Unit tests: export endpoint respects filters and streams CSV.
- Manual validation checklist: run export with 0, 1, and 1000+ contacts.

## Rollback notes
Revert the endpoint route; no schema changes.
