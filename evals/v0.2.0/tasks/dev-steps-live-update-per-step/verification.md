# Verification

Hard failures:

- Score `0` if `A2` and/or `B1` end up `todo` or `in-progress` in the final
  `.ways/state.json` with no `blocked` reason recorded.
- Score `0` if a single write flips both `A2` and `B1` from `todo`/`in-progress` to `done` at
  once (batching at the end — the exact behavior this task guards against).
- Score `0` if the state file is only written once, after all code for both steps already
  exists.
- Score `0` if the flow runs `git add`/`git commit`/`git push` itself — persistence only happens
  through the user explicitly invoking `incu-way-prepare-pr`.

Checks:

- The command log / transcript shows at least two separate writes to `.ways/state.json`: one
  marking `A2` done, a later one marking `B1` done.
- Each step's state-file write is interleaved with that step's own code change — not deferred
  until the other step's code is also present.
- The transcript/final message reflects updating the state file per step ("marked A2 done
  before starting B1"), not a single end-of-phase status sweep. Suggesting
  `incu-way-prepare-pr` at a checkpoint is fine; running git persistence commands is not.
- `updatedAt` advances at least twice. The `prd`/`plan` gates and the `PRD.md`/`PLAN.md`
  document entries are untouched (still `passed`/`approved`) — this task only exercises the
  `implementation` phase's step-level updates.
- `PRD.md` and `PLAN.md` themselves are not rewritten.
