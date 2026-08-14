# Expected Behavior

The agent resumes on `feat/003-contact-export`, reads `.ways/state.json`, and reports that
`A1` is done, `A2` is in-progress, and `B1` is todo.

It then, in order:

1. Finishes `A2` (`src/api/export-contacts.ts`) and immediately updates `.ways/state.json`
   marking `A2` `done` — **before** starting `B1`. It may suggest invoking
   `incu-way-prepare-pr` as a checkpoint, but it does not run git persistence commands itself.
2. Implements `B1` (`src/ui/export-button.ts` or equivalent) and immediately updates the state
   file marking `B1` `done`.

At no point does it defer both status flips to a single state-file write at the end of the
phase, and at no point does it run `git add`/`git commit`/`git push`/`gh pr create` itself. The
`prd`/`plan` gates, `PRD.md`, and `PLAN.md` are left exactly as the fixture had them — this
task is scoped to the `implementation`-phase step cadence, not the earlier gates.
