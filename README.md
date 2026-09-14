# incuway

Workflow skills and templates for AI coding agents, created and maintained by [Incu](https://incu.tech).

## What this is

`incuway` is a set of **structured skills** that define how an AI coding agent (Claude Code, Cursor, Windsurf, etc.) should approach software development: new features, bug fixing, and security remediation. Each skill implements a flow with explicit approval gates — the agent does not advance to the next phase without the user's confirmation.

## Installation

```bash
npx skills add https://github.com/incu-tech/incuway.git
```

This installs all available skills in the detected agent (Claude Code, Cursor, Windsurf, etc.) at the global or project level, depending on what you choose in the interactive prompt.

For non-interactive environments like Codex/Conductor, use:

```bash
npx skills add https://github.com/incu-tech/incuway.git --yes
```

### Install a specific skill

```bash
npx skills add https://github.com/incu-tech/incuway.git --skill incu-way-development
```

### Install as a way family

The repo is also an installable **WayFamily** (`way.yaml`, `ways/v1alpha1`): the three gated
work-item flows as **member ways** — `incu/dev` (feature), `incu/bugs` (bug), `incu/security`
(security remediation), each with its own phases and gates — plus the payload they share: the
other skills, the always-on knowledge rules (state contract, security and branch-flow
conventions), and the capability slots with their default bindings.

```bash
npm install -g @incu/ways                               # the ways CLI (v0.3.0+)

ways add github:incu-tech/incuway                       # the whole family
ways add github:incu-tech/incuway --members dev,bugs    # just the flows you want
```

One plan, one approval; `ways.yaml` + `ways.lock` record the family and the members you
installed. See [`ways/README.md`](./ways/README.md) for the artifacts and how to validate them.

## Included skills

| Skill | Invocation | Description |
|-------|-----------|-------------|
| `incu-way-init` | `/incu-way-init` | Onboard a repo into incu-way: detect greenfield vs brownfield, scaffold CLAUDE.md + docs/ + branch model, drive the documentation of existing code |
| `incu-way-docs` | `/incu-way-docs` | Document or refresh the architecture and (if needed) the functional behavior of an existing codebase |
| `incu-way-arch-assessment` | `/incu-way-arch-assessment` | Assess architecture (a repo, a module, or the branch diff) against quality attributes — rated findings + prioritized recommendations |
| `incu-way-security-validation` | `/incu-way-security-validation` | Validate code against common rulesets (OWASP Top 10/ASVS/API, CWE Top 25) control-by-control — complements the Snyk scans |
| `incu-way-threat-model` | `/incu-way-threat-model` | Build a small STRIDE threat model for the current work or new code — DFD, threats, mitigations, residual risk |
| `incu-way-po` | `/incu-way-po` | Turn a raw need into development-ready tickets — feasibility validated against code, cross-repo gaps mapped, open questions closed before development starts |
| `incu-way-development` | `/incu-way-development` | Full life cycle for new features: PRD → plan → implementation → validation → PR |
| `incu-way-bugs` | `/incu-way-bugs` | Life cycle for bugs: documentation → analysis → reproduction test → fix → PR |
| `snyk-remediation` | `/snyk-remediation` | SAST + SCA scanning with Snyk, findings triage, remediation plan and PR |
| `incu-way-prepare-pr` | `/incu-way-prepare-pr` | The only skill that commits, pushes, or opens PRs — every other flow defers git persistence to it, and it only runs when you explicitly invoke it |

> **Start here in a new repo.** Run `/incu-way-init` first — it bootstraps the project
> (CLAUDE.md, `docs/`, `develop`/`main`, `.ways/`) and, for an existing application
> (the common case), documents its architecture so the other flows have real context.

## Versioning

Three version numbers coexist on purpose:

- **`VERSION`** — the skill-bundle version, mirrored in every `skills/*/SKILL.md`
  frontmatter so installed skills can report exactly which incuway release they came
  from. To bump it: edit `VERSION`, run `bash evals/versioning.sh --fix` to sync the
  frontmatters, then `bash evals/versioning.sh` to verify.
- **Ways artifacts** (`way.yaml` and `ways/**/way.yaml`) keep their own
  `metadata.version` — the family and each member way version independently; update those
  only when the corresponding WayFamily, Way, RulePack, Contract, or Binding changes.
- **The behavior eval suite** (`evals/v0.2.0/`) is named after the skill-improvement
  release it was written to validate; the suite evolves with the flows' observable
  behavior, not in lockstep with `VERSION`.

## Included template

`skills/incu-way-init/claude.template.md` is the starting point for the `CLAUDE.md` of any new project. It includes the mandatory sections pre-filled and `[TODO: ...]` markers to customize. It is bundled inside the `incu-way-init` skill so it travels with `ways add`; normally `incu-way-init` copies and fills it for you.

```bash
cp path/to/incu-way/skills/incu-way-init/claude.template.md ./CLAUDE.md
# Fill in the sections marked with [TODO: ...]
```

## Repo hygiene: what goes in `.gitignore`

`incu-way-init` always adds `.claude/` and `.agents/` to `.gitignore` — they hold
placement output from `skills.sh`/`hooks.sh` (plus, for `.claude/`, Claude Code's own
local settings), and every bit of it is regenerated from `ways.lock` /
`skills-lock.json` / `steering-lock.json` by `ways install`. Treat them like
`node_modules`: never commit, never ask.

`.ways/` is different — it's **not** a blanket-ignore. `.ways/state.json` is a
work-item's live phase/gate state and **must stay tracked** (resume-by-branch depends
on it being committed via `incu-way-prepare-pr`). If the project also uses the `ways`
CLI, ignore only its cache: add `.ways/cache/`, never the whole `.ways/`.

## Design principles

- **Gate-driven:** no skill allows advancing without explicit user approval at the critical points.
- **Isolation-first:** all work starts by asking the user whether they prefer a branch in the current checkout or a separate worktree, before touching `develop` or `main`.
- **Security-by-default:** the validation of each skill includes Snyk (SAST + SCA) and SonarQube scans.
- **No auto-commits:** flows only write files; committing, pushing, and opening PRs happen exclusively through `incu-way-prepare-pr`, on your explicit request.
- **Project-agnostic:** the flows work on any stack or language — the conventions specific to each project live in its own `CLAUDE.md`.

## Contributing

1. Create a `feat/{slug}` branch from `main`.
2. Add or edit the skill in `skills/{name}/SKILL.md`.
3. Keep the gates, the explicit isolation choice (branch or worktree), and the security scans in any new skill.
4. Bump `VERSION` and the changed skill frontmatter versions when shipping a skill change.
5. Open a PR to `main`.

## Evals

```bash
bash evals/versioning.sh
bash evals/isolation-choice.sh
bash evals/no-auto-commit.sh
```

`versioning.sh` checks that every skill frontmatter version matches `VERSION` (run with
`--fix` to sync them). `isolation-choice.sh` checks that skills keep asking whether the
user prefers a branch in the current checkout or a separate worktree. `no-auto-commit.sh`
checks that no flow commits, pushes, or opens PRs itself.

The behavior suite lives in `evals/v0.2.0/`. It ships no runner of its own: a subagent or external harness must run a task, capture evidence, and report against `verification.md` and `rubric.md`.

Available tasks:

- `evals/v0.2.0/tasks/dev-isolation-choice-before-files`: verifies that the agent does orientation and stops to ask branch vs worktree before writing PRD, plan, code, or docs.
- `evals/v0.2.0/tasks/dev-no-auto-commit-suggest-prepare-pr`: verifies that the agent never commits, pushes, or opens a PR itself and suggests `incu-way-prepare-pr` instead.
- `evals/v0.2.0/tasks/po-gate1-split-before-tickets`: verifies that the PO flow stops at Gate 1 (scope and ticket split) before drafting any ticket.

## License

[MIT](./LICENSE)
