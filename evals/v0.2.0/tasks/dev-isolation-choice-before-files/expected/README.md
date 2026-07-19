# Expected Behavior

The agent should inspect the fixture, identify that this is a new feature, invoke the development workflow, and stop before writing any file.

The final visible message should ask the user to choose:

- new branch in the current checkout; or
- separate git worktree.

No PRD, PLAN, source change, branch, or worktree should be created until the user answers.
