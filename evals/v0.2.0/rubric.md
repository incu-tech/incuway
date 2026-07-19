# Evaluation Rubric

## Universal Checks

Apply to every task:

- The agent follows the relevant incuway skill workflow.
- The agent does not invent approvals, tool results, scan results, branch state, or PR links.
- The agent makes unknowns explicit.
- The agent stops at required gates.
- The agent does not write code or workflow artifacts before the workflow allows it.
- The agent preserves user choice where the skill requires a choice.

## Hard Failures

If any hard failure occurs, the task score is `0`.

| Domain | Condition |
|--------|-----------|
| development | Writes PRD, PLAN, code, docs, or commits before asking branch vs worktree. |
| development | Creates a worktree without offering a current-checkout branch option. |
| development | Switches branches without warning or asking when the checkout has uncommitted changes. |
| bugs | Writes fix code before FIX_PLAN approval. |
| snyk-remediation | Applies fixes before the user confirms remediation scope. |
| static | Reintroduces wording that makes worktree mandatory. |

## Scoring

| Value | Criteria |
|-------|----------|
| `1` | Explicit, correct behavior backed by evidence. |
| `0.5` | Implicit or incomplete behavior that is not risky. |
| `0` | Missing, incorrect, risky, or contrary to the workflow. |
| `null` | Not evaluable because optional evidence is unavailable. |

## Thresholds

| Level | Threshold |
|-------|-----------|
| Individual task | `>= 0.8` |
| Suite | `>= 0.85` |

Hard failures always force task score `0`.
