---
name: incu-way-prepare-pr
version: 0.1.2
description: The only skill in this repo that runs `git add`, `git commit`, `git push`, or `gh pr create`. Invoke ONLY when the user explicitly asks to commit, push, or open/prepare a PR (e.g. "commit this", "commit progress", "push this branch", "prepare the PR", "open the PR"). No other incu-way skill may invoke this automatically or run those git commands itself — they may only suggest it to the user.
---

# Prepare PR / Commit Changes

The single place where incu-way work gets persisted to git. Every other flow in this
repo only **writes files** and **suggests** running this skill at natural checkpoints —
none of them commit, push, or open a PR on their own. This list is deliberately not
enumerated here: any current or future incu-way flow follows the same rule, so there is
nothing to keep in sync when a skill is added, renamed, or removed.

**The real gate against self-invocation is the frontmatter `description` above**, not
this paragraph — skill matching happens off that description before any body text is
read, so "Invoke ONLY when the user explicitly asks" has to live there to actually work.
This body is a second line of defense for whoever ends up reading this file directly: if
you are a caller skill, don't invoke this skill yourself — say something like *"This
checkpoint is ready. Run `incu-way-prepare-pr` (or ask me to) when you want to commit
it."* and stop there.

---

## Step 1 — Locate context

```bash
git branch --show-current
```

Derive `{slug}` the same way the flows do (branch without its `feat/` | `fix/` |
`fix/security-` | `chore/` | `docs/` | `assess/` prefix). If
`.ways/state.json` exists, read it
(do not write to it yet) to know the
`flow`, `phase`, and which gate/document this checkpoint corresponds to. If it doesn't
exist (e.g. assessment/documentation flows with no item file, or a plain ad hoc
"commit this" request), proceed without it.

## Step 2 — Show exactly what would be committed

```bash
git status --short
git diff --stat
git diff --stat --staged
```

Present this to the user before touching anything. If nothing is staged or changed,
say so and stop — there is nothing to commit.

## Step 3 — Propose a commit message

Every commit is [**Conventional Commits**](https://www.conventionalcommits.org/en/v1.0.0/),
no exceptions:

```
<type>(<scope>)<!>: <description>

<body>

<footer>
```

**type** — one of `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`,
`chore`, `revert`. This exact list is an **Incu org policy**, not the Conventional Commits
spec itself (the spec only defines semantic meaning for `feat`/`fix`; it doesn't close off
the set of types). The policy exists to keep history greppable and consistent across every
incu-tech repo: there is no repo-specific type outside this list, pick the closest one
(usually `chore`) rather than inventing a new one. Don't guess it, the calling flow's own
SKILL.md already documents the commit-message format for its phase (look for a "commit
message format" / "suggested commit message" section near the checkpoint the user is at),
or infer it from the branch prefix:

| Branch prefix | type | scope |
|---|---|---|
| `feat/{slug}` | `feat` | `{slug}` |
| `fix/{slug}` | `fix` | `{slug}` |
| `fix/security-{slug}` | `fix` | `security` |
| `chore/{slug}` | `chore` | `{slug}` (omit if repo-wide, e.g. a version bump touching every file) |
| `docs/{slug}` | `docs` | `{slug}` |
| `assess/{slug}` | `docs` | `{slug}` (an assessment/threat-model/security-validation report is documentation — never invent a non-standard type like `assess:`) |

If neither the branch prefix nor the calling flow's own format section makes the type
obvious, ask the user rather than guess.

**description** — imperative mood ("add", never "added"/"adds"), lowercase right after the
colon, no trailing period, short enough that the whole `type(scope): description` line
stays under ~72 columns. It states *what* changed; the body carries *why*.

**`!`** — append immediately after the scope (or the type, if there's no scope) only when
this commit breaks a documented contract: a schema, a public CLI flag, an on-disk format,
anything a downstream consumer depends on. Always paired with a `BREAKING CHANGE:` footer
explaining what breaks and how to adapt — never one without the other, and never used for
an internal refactor with no externally observable break.

**Body** — one blank line after the description, then prose wrapped at ~72 columns.
Explains the reasoning a diff alone can't show: why this approach over an alternative, what
it replaces, what a reviewer needs to know that isn't obvious from the code. It is never a
restatement of the diff line by line, and it's optional for a change small enough that the
description already says everything (a one-line typo fix doesn't need a body).

**Footer** — one blank line after the body: `Closes #123` / `Refs #123` for an issue this
resolves or relates to (only when one genuinely exists in this repo — never fabricate a
number), and `BREAKING CHANGE: <description>` whenever `!` was used above.

**Atomicity.** One logical change per commit — each one should build and pass its own
tests/evals in isolation, so a future `git bisect` or a revert of just this commit never
drags in unrelated work. If the state file `.ways/state.json` changed alongside other
files, it's committed **together with** them in the same commit (it's metadata about that
same change, not a separate one) — but if more than one *unrelated* logical unit of work is
staged/dirty (e.g. two unrelated checkpoints, or a drive-by refactor riding along with an
unrelated feature), say so and propose splitting into separate commits rather than bundling
them silently.

### Gate — commit confirmation

Say: **"About to commit: {file list}. Message: `{proposed message}`. Confirm before I run `git add` / `git commit`."**

**Stop. Do not run `git add` or `git commit` until the user confirms.**

Only after explicit confirmation, stage exactly the reviewed files and commit.

## Step 4 — Push and PR (only if the user asks for this too)

Do not assume a commit implies the user also wants to push or open a PR. Ask:

> Do you also want me to push `{branch}` and open a PR to `{base}`?

If yes, draft the title/body. **The body always follows the fixed structure in
`.github/PULL_REQUEST_TEMPLATE.md`** — Summary, Type of change, Root cause / motivation,
What changed, Testing, Breaking changes, Related issues — never a free-form essay instead
of it, and never dropping a section (write "None" / "N/A" rather than omit one that
doesn't apply, except "Related issues", which is deleted entirely when there is none). The
calling flow's own "PR body" section (in its SKILL.md) supplies the *content* that goes
into these sections — links to its docs under "What changed", its validation checklist
under "Testing", and so on — but the section structure itself always comes from the
template, not from the flow. Show the drafted title/body to the user.

**The PR title is a Conventional Commits header** (`type(scope): description`, same rules
as Step 3) — most repos here squash-merge, so the title *becomes* the permanent commit
message. If the branch carries more than one commit with different types, pick the type of
the change a reviewer would call the point of the PR (usually the last, most substantial
one), not just the first commit's.

### Public-repo content check (before drafting the body)

Check whether `{base}`'s repo is public: `gh repo view {owner}/{repo} --json isPrivate -q .isPrivate`.
Treat it as public whenever the check says so, or whenever it can't be run — never
assume private by default.

If the repo is public, the title, body, branch name, and commit messages must never
carry:

- A person's name, handle, or initials — not the reporter, not a reviewer, not anyone
  quoted in an internal conversation.
- The name of an internal channel (Slack or otherwise), or a date tied to one.
- A verbatim quote or close paraphrase of an internal conversation (Slack, a meeting,
  a DM).

Keep the technical substance — what broke, why, what changed, how it was validated —
under a source-free framing (e.g. "reportado internamente", "detectado durante uso
real").

**This check covers the entire outgoing diff, not just the PR text.** Run
`git diff {base}...{branch} --name-only` and look at every file this PR actually adds or
changes, not only the PR body/branch/commit message. If a document this PR is introducing
or modifying (a BUG.md's `Context`, a PRD's intake notes, etc.) names someone or cites an
internal thread, that content ships to the public repo the moment this PR merges. Leaving
it "in the doc itself" doesn't protect anything once the doc is part of a public diff.
Sanitize that document (strip the name/channel/quote, reframe it the same source-free way
as the PR body) before opening the PR, don't just avoid repeating it in the PR text.

A document that names someone but was already committed to the repo in an **earlier**
PR/commit, and that this PR's diff doesn't touch, is out of scope here. This check is
about what this PR itself ships, not a retroactive audit of the whole repo's history.

If the repo is private, none of this applies — write the PR normally.

### Gate — push/PR confirmation

Say: **"About to push `{branch}` and open a PR: `{base}` ← `{branch}`, title `{title}`. Confirm before I push and open it."**

**Stop. Do not run `git push` or `gh pr create` until the user confirms.**

Only after explicit confirmation:

```bash
git push -u origin {branch}
gh pr create --base {base} --head {branch} --title "{title}" --body "{body}"
```

Share the resulting PR URL with the user.

## Step 5 — Update state (if a state file exists)

If `.ways/state.json` exists and a PR was just opened, set the matching
`gates[].url` to the PR link as part of the work already confirmed in Step 4 — this is
metadata about the action just taken, not a new unannounced action, so it does not need
its own separate gate. If the PR gate should now read `passed` (e.g. it was merged
externally and the user is only recording that here), update its `status` too.

---

## What NOT to do

- Do not invoke yourself automatically from within another skill's flow — you only run
  when the user explicitly asks in the current turn.
- Do not commit, push, or open a PR without the explicit confirmation gates above, even
  if the user invoked you directly — invoking this skill starts the conversation, it is
  not itself the confirmation.
- Do not bundle unrelated changes into one commit without calling it out first.
- Do not merge PRs. Opening a PR is in scope; merging is always a separate, explicit
  user action outside this skill.
