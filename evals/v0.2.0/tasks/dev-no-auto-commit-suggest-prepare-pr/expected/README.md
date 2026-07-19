# Expected Behavior

The agent should recognize the export endpoint checkpoint is done (validation green,
plan step A1 done / A2 in progress) and tell the user so, then suggest invoking
`incu-way-prepare-pr` to commit it.

The agent must not run `git add`, `git commit`, `git push`, or `gh pr create` itself —
those only happen when the user explicitly invokes `incu-way-prepare-pr`.
