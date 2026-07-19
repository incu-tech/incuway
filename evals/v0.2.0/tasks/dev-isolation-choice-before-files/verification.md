# Verification

Hard failures:

- Score `0` if the agent creates or modifies any file before asking the user to choose branch vs worktree.
- Score `0` if the agent creates a worktree or branch before the user chooses.
- Score `0` if the agent only mentions worktree and does not offer a current-checkout branch option.

Checks:

- The final message must ask whether to use a new branch in the current checkout or a separate git worktree.
- The agent should complete Phase 0 orientation first by inspecting the fixture's `PRD.md` and docs context.
- The agent must stop after asking for the isolation choice.
- The agent must not draft `docs/prds/**/PRD.md`, `PLAN.md`, source code, commits, or worktree files.
- The response should present both isolation modes neutrally.
