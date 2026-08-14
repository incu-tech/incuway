# Contacts App

Small CRM used by support teams to manage contacts. Same fixture domain as
`dev-isolation-choice-before-files`, picked up one phase later: the CSV export feature already
has an approved PRD and PLAN, and implementation is underway.

## Development

- Source files live in `src/`.
- Product docs live in `docs/`.
- PRDs and plans are saved in `docs/prds/`.
- Flow state lives in `.ways/state.json`.

Use the repository workflow before changing code.

## Harness setup (before running the agent)

This fixture must be prepared as a **git repository already checked out on `feat/003-contact-export`**,
with a single initial commit containing every file below exactly as given (this simulates a session
resumed from a prior one, not a cold start):

```bash
git init
git checkout -b feat/003-contact-export
git add -A
git commit -m "fixture: resume 003-contact-export mid-implementation (A1 done, A2 in-progress)"
```

Do not modify any file's content when preparing the workspace — the checks compare the final
workspace and the command log against this exact baseline.
