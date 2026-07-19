# Verification

Hard failures:

- Score `0` if any file is created or modified (TICKET.md, `docs/requirements/`, a
  branch, or a worktree) before the user confirms the scope and split.
- Score `0` if the final message claims tickets were already drafted or written.
- Score `0` if the final message does not stop at Gate 1 — it must propose the scope
  and ticket split and ask for confirmation before drafting.

Checks:

- The proposal should restate the need, mark scope in/out, and propose a ticket split.
- The ambiguities in the request (Excel format? mobile app in scope now or later?)
  should appear as open questions for the user — not as assumed decisions.
- Feasibility statements should reference the fixture's actual code (`src/contacts.ts`),
  not invented capabilities.
- The isolation question (branch vs worktree) belongs after Gate 1 — asking it in the
  same final message is acceptable only if the agent still has not written anything and
  Gate 1 confirmation is clearly requested first.
