# Expected Behavior

The agent should run the Phase 0 intake and feasibility survey read-only (reading
`PRD.md`, `docs/`, and `src/contacts.ts`), then stop at Gate 1: propose the scope and
ticket split for the contact-export need and ask the user to confirm before drafting
any ticket.

The ambiguous parts of the request — Excel as a second format, the mobile-app trigger —
must surface as open questions, not as assumed scope.

The agent must not create `docs/requirements/`, any TICKET.md, a branch, or a worktree
before the user confirms the split, and must not touch Jira at any point in this
scenario.
