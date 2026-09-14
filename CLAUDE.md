# CLAUDE.md

Instructions for Claude Code when working in this repository.

## About the project

`incuway` is the central repository of **workflow skills and templates** for software projects. It contains the gated workflows that Claude must follow when developing features, fixing bugs, and remediating security vulnerabilities.

See `README.md` for the full project context.

## Structure

```
/
  README.md                        # What this repo is, project context
  CLAUDE.md                        # This file
  skills/
    incu-way-init/
      SKILL.md                     # Repo onboarding flow: greenfield vs brownfield bootstrap (3 gates)
      claude.template.md           # Base CLAUDE.md template (bundled here so it travels with `ways add`)
    incu-way-docs/
      SKILL.md                     # Codebase architecture/functional documentation flow (2–3 gates)
    incu-way-arch-assessment/
      SKILL.md                     # Architectural assessment flow: rate quality attributes, findings, recommendations (2–3 gates)
    incu-way-security-validation/
      SKILL.md                     # Ruleset compliance review (OWASP/ASVS/CWE) control-by-control (2–3 gates)
    incu-way-threat-model/
      SKILL.md                     # Small STRIDE threat model on current work or new code (2–3 gates)
    incu-way-po/
      SKILL.md                     # Ticket/requirements refinement flow: raw need → development-ready tickets (3 gates)
    incu-way-development/
      SKILL.md                     # Feature development flow (Phase 0–5, 5 gates)
    incu-way-bugs/
      SKILL.md                     # Bug-fixing flow (Phase 0–7, 2 gates)
    snyk-remediation/
      SKILL.md                     # Snyk security remediation flow (Phase 0–6, 5 gates)
    incu-way-prepare-pr/
      SKILL.md                     # User-invoked commit/push/PR skill — the only skill that touches git persistence
  way.yaml                         # Installable WayFamily manifest (ways/v1alpha1) — members + shared skills/knowledge/slots
  ways/
    incu-dev/, incu-bugs/,         # The three member Ways (one gated work-item flow each,
    incu-security/                 # referenced by way.yaml spec.members)
    rulepacks/
      state-contract/              # Canonical .ways/state.json contract, placed as an always-on rule on `ways add`
      incu-base/                   # Baseline conventions (security, branch-flow)
  docs/
    validation/                    # Eval summaries for shipped skill releases
  evals/
    versioning.sh                  # Eval guarding skill-frontmatter/VERSION coherence (--fix to sync)
    isolation-choice.sh            # Eval guarding the branch/worktree choice
    no-auto-commit.sh              # Eval guarding that no flow commits/pushes/opens PRs itself
    gitignore-hygiene.sh           # Eval guarding the .gitignore entries incu-way-init writes
    v0.2.0/                        # Behavior eval suite (task/rubric style)
```

## Ways artifacts: the family and its members

The root `way.yaml` is a **`kind: WayFamily`** (`incu/incu-way`) — it declares no `flow` of its own
(that is a schema error on a family). It *references* three **member Ways**, one per gated
work-item flow, and carries the payload shared across them:

| Member id | Manifest | Way | Flow | Driven by |
|---|---|---|---|---|
| `dev` | `ways/incu-dev/way.yaml` | `incu/dev` | feature — 8 phases, 5 gates | `skills/incu-way-development` |
| `bugs` | `ways/incu-bugs/way.yaml` | `incu/bugs` | bug — 9 phases, 2 gates | `skills/incu-way-bugs` |
| `security` | `ways/incu-security/way.yaml` | `incu/security` | security — 8 phases, 5 gates | `skills/snyk-remediation` |

Rules to keep this coherent when editing:

- **Members are the flows that keep state.** The analytical/bootstrap flows (init, docs, po,
  arch-assessment, security-validation, threat-model) and `prepare-pr` are **shared skills** of the
  family, not members — they produce a document under `docs/` and keep no `state.json`.
- **Member phase ids match the state contract enums** (`feature` / `bug` / `security` in
  `ways/rulepacks/state-contract/rules/state-contract.md`). Change one, change the other.
- **Skills are declared at the family level, never inside a member.** A member is installed from its
  own directory, so a `path: ../../skills/…` would escape the bundle and fail the install.
- **Shared payload lives only in the family** (state-contract, security, branch-flow rules; the four
  capability slots and their default bindings). A member declares only what is specific to it (e.g.
  `ways/incu-dev/rules/conventions.md`) plus its own `needs` — the effective slot set is the union.
- After any change: `ways validate` + `ways conformance` on the family and every member (see
  `ways/README.md`). The family check re-runs full Way conformance on each bundled member, so a
  broken member drops the family to `schema-valid`.

## State tracking: `.ways/state.json`

The gated flows (`feature` / `bug` / `security`) keep **one** `.ways/state.json` per
worktree/branch (`ways/v1alpha1`). Its **format and life cycle are not restated here** — they
live in the always-on `state-contract` rule (`ways/rulepacks/state-contract/`), enforced by
`state.schema.json` in the ways package. Each flow's SKILL.md carries only its flow-specific
values (branch, initial phase, documents, gates) in a short "State tracking" section. The
analytical flows (docs, arch-assessment, security-validation, threat-model, po) are **stateless** —
a report under `docs/`, no `state.json`.

## Global config: `~/.ways/config.yaml`

A **user/machine-level** file, never part of any repo — it's how incu-way, installed once
globally, still behaves per-repo instead of imposing the same structure everywhere.

```yaml
# ~/.ways/config.yaml
blacklist:
  - argenprop
linkedRepos:
  hrscheme:
    - hrs-webapp
    - hrs-backend
    - hrs-landing
    - hrs-esco-matching
    - hrs-admin
```

- **`blacklist`** — repos incu-way should never impose its structure on (a repo with its
  own flow and doc conventions already). Matched loosely against the current repo's git
  remote `owner/repo` slug, or its local directory name when there's no remote — an entry
  like `argenprop` matches any of those forms. **Every** incu-way skill checks this first,
  before Phase 0, before writing or asking anything else: if the current repo matches, say
  so and ask whether to proceed anyway (a one-off exception) or stop.
- **`linkedRepos`** — named groups of repos that make up one multi-repo product (e.g.
  `hrscheme`'s five repos). Used during discovery (`incu-way-po`, `incu-way-development`,
  `incu-way-bugs`) to name sibling repos a change might affect, even when the request only
  mentions one of them. **This is a fallback, not the primary source**: a hub repo's own
  `CLAUDE.md` can declare a `repos:` section for its product, and that always wins when
  present — it's versioned with the product and visible to the whole team, which a
  personal machine-level file can never be. `linkedRepos` only fills in when no hub
  declaration exists yet (a new or informally-tracked product).
- The file is optional everywhere. Missing file, missing key, or no match for the current
  repo — proceed exactly as if it didn't exist.

## What each skill does

### `incu-way-init`
Onboards a repository into incu-way. Phase 0 detects **greenfield** (new, empty repo) vs **brownfield** (existing application — the common case) vs **already initialized** (refresh). Flow: orientation + mode detection → confirm mode/scope (gate 1) → branch/worktree (`chore/incu-way-init`; creates `develop`/`main` if missing) → scaffold (CLAUDE.md from template, PRD.md, docs/ tree, .ways/) → documentation (brownfield: invokes `incu-way-docs`; greenfield: records intended architecture) → review (gate 2) → PR (gate 3). It is a **bootstrap flow**: it *creates* `.ways/` but does **not** maintain a `state.json` (that model is only for feature/bug/security work items).

### `incu-way-docs`
Documents (or refreshes) the architecture and, when warranted, the functional behavior of an existing codebase. Invoked by `incu-way-init` during brownfield onboarding (writes into the init branch, no separate PR) or run standalone (`docs/{slug}` branch → PR). Flow: survey + inventory → documentation map (gate 1) → author docs (traceable to `file:line`, no invention, conflicts recorded) → validated Mermaid diagrams → review (gate 2) → PR (gate 3, standalone only). Output lives in `docs/architecture/` and `docs/functional/`. Also a documentation flow — no `state.json`.

### `incu-way-arch-assessment`
Assesses the architecture of a codebase, a module, or the current branch's diff against quality attributes and design principles (coupling/cohesion, layering/hexagonal adherence, SoC, scalability, maintainability, testability). Produces a traceable, rated report with findings (severity = architectural risk), a tech-debt register, and prioritized recommendations — it assesses, it does **not** implement fixes. Runs standalone (`assess/arch-{slug}` branch → PR) or **embedded** in another flow (writes into the caller's branch, no separate PR; e.g. `incu-way-development` evaluating a design at planning). Output: `docs/assessments/arch/{slug}/ASSESSMENT.md`. Assessment flow — no `state.json`.

### `incu-way-security-validation`
Validates code, a module, or the current branch's diff against common security rulesets (OWASP Top 10, OWASP API Top 10, OWASP ASVS, CWE Top 25) control-by-control, marking each control pass/fail/N-A/needs-review with traceable evidence and routing the fails to the right remediation flow. **Complements `snyk-remediation`** (automated SAST/SCA) — it catches design/logic/authz issues scanners miss; it does not replace the scans. Runs standalone (`assess/secval-{slug}` branch → PR) or **embedded** (e.g. `incu-way-development` at its validation gate). Output: `docs/security/validation/{slug}/VALIDATION.md`. Assessment flow — no `state.json`.

### `incu-way-threat-model`
Builds a small, focused STRIDE threat model for the current work or new code — decomposes into assets, actors, entry points, and trust boundaries, enumerates threats with a validated Mermaid DFD, rates risk, and records mitigations + residual risk. Scaled to the change (depth follows risk). Runs standalone (`assess/threat-{slug}` branch → PR) or **embedded** (e.g. `incu-way-development` right after the PLAN, so mitigations become plan tasks). Identifies threats — implementing a mitigation is a task in the calling flow or a follow-up item. Output: `docs/security/threat-models/{slug}/THREAT-MODEL.md`. Assessment flow — no `state.json`.

### `incu-way-po`
Turns a raw need, idea, or client request into **development-ready tickets** before any development flow starts. Phase 0 surveys the affected repositories (multi-repo aware — e.g. a product spanning web + API + workers) and runs a feasibility pass traceable to code: what the system supports today, what is possible, what is not without larger work, and which cross-repo contracts change. Flow: intake + feasibility survey → scope and ticket split (gate 1) → branch/worktree (`po/{slug}`) → one `docs/requirements/{slug}/TICKET.md` per ticket → **Definition of Ready** review (gate 2 — no ticket leaves with unresolved open questions unless explicitly deferred) → hand-off (optional Jira sync, **only on explicit user request**) → PR (gate 3). `incu-way-development` / `incu-way-bugs` consume the TICKET.md in their Phase 0, so discovery verifies instead of re-deriving. Analytical flow — no `state.json`.

### `incu-way-development`
Full life cycle for new features. Explicit gates at each phase prevent Claude from writing code before the user approves the PRD and the plan. Flow: orientation → branch or worktree choice → PRD (gate 1) → PLAN (gate 2) → implementation → validation + scans (gate 3) → PR feat→develop (gate 4) → PR develop→main (gate 5).

### `incu-way-bugs`
Life cycle for reported or discovered bugs. The only critical gate is the FIX_PLAN before writing any fix code. Flow: orientation → branch or worktree choice → BUG.md → ANALYSIS.md → reproduction test (that fails) → FIX_PLAN (gate) → fix → validation + scans → PR.

### `snyk-remediation`
Complete process for scanning and remediating SAST + SCA vulnerabilities. Flow: scan → findings table (gate 1: user chooses scope) → branch or worktree choice → FINDINGS.md → PLAN.md (gate 2) → fix per finding → re-scan → RESOLUTION.md (gate 3) → PR fix→develop (gate 4) → PR develop→main (gate 5). Drives the `incu/security` member way (`ways/incu-security/way.yaml`), which is the `way` value its `state.json` records.

### `incu-way-prepare-pr`
The only skill that runs `git add`, `git commit`, `git push`, or `gh pr create`. Every other skill only writes files and *suggests* invoking this one at checkpoints and before opening a PR — none of them call it automatically or run those git commands themselves. It only runs when the **user** explicitly asks for it (by name, or "commit this", "push this", "prepare the PR"). Operates on whatever the caller's current item is (reads `.ways/state.json` if present) but keeps no state file of its own.

### `skills/incu-way-init/claude.template.md`
Template for the `CLAUDE.md` of new projects, bundled inside `incu-way-init` so it travels with `ways add`. It contains the mandatory sections (Security, Work isolation, Development workflow, Bug workflow) already filled in with the universal rules, plus sections with `[TODO: ...]` to customize per project.

## SKILL.md conventions

- **Mandatory frontmatter:** `name` (kebab-case, matches the folder name), `version` (matches `VERSION` for shipped skills), and `description` (one line, used as the invocation trigger).
- **Explicit gates:** each gate ends with a canonical phrase in bold and the `**Stop.**` instruction. Do not omit it.
- **Isolation first:** every skill that produces files asks whether to use a branch in the current checkout or a separate worktree before writing any doc or code.
- **No auto-commits:** no skill runs `git add`, `git commit`, `git push`, or `gh pr create` itself. `incu-way-prepare-pr` is the only skill that touches git persistence, and only when the user explicitly invokes it; every other skill may only suggest invoking it.
- **Security scans in all validation:** the three scans (Snyk SAST, Snyk SCA, SonarQube) appear in the validation checklist of `incu-way-development` and `incu-way-bugs`.
- **Uniform branch flow:** `feat/{slug}` or `fix/{slug}` → `develop` → `main`, always via PR, never a direct merge.
- **Language:** all docs in this repo (SKILL.md, claude.template.md, CLAUDE.md, READMEs) are written in English.

## How to add or modify a skill

1. Create a `skills/{skill-name}/` folder with a `SKILL.md` inside it.
2. Make sure the frontmatter has `name`, `version`, and `description`.
3. Include explicit gates, an explicit isolation choice (branch or worktree), and a validation checklist with security scans.
4. For version bumps, edit `VERSION`, run `bash evals/versioning.sh --fix` to sync every skill frontmatter, then `bash evals/versioning.sh` to verify.
5. Run `./evals/isolation-choice.sh` if the change touches isolation, branch, or worktree; run `./evals/no-auto-commit.sh` if it touches committing, pushing, or PR creation; run `./evals/gitignore-hygiene.sh` if it touches `.gitignore` guidance.
6. Update or add tasks in `evals/v0.2.0/` when the change affects observable agent behavior.
7. Declare the skill in the root `way.yaml` under `spec.skills` (with its `uses` slot ids) — that is
   what places it on `ways add`. A skill that is **not** listed there never installs.
8. If the skill is a new **gated work-item flow** (it keeps a `.ways/state.json`), also add a member
   Way: `ways/{name}/way.yaml` (`kind: Way`, its own phases/gates/generates/`state`) plus an entry in
   the family's `spec.members`. Then re-run `ways validate` + `ways conformance` on the family and
   the new member. Keep its phase ids aligned with the state contract enums.
9. Update this CLAUDE.md if the new skill is part of the mandatory set.
10. Open a PR `feat/{slug}` → `main` (this repo has no `develop` branch).

## Security

When modifying any skill or template, do not introduce instructions that:
- Skip approval gates.
- Allow writing code before the user approves a plan.
- Suggest doing a direct merge to `main` or `develop`.
- Bypass security scans.
- Commit, push, or open a PR automatically from within a flow — that only happens through the user explicitly invoking `incu-way-prepare-pr`.

## Don't do

- Don't add unnecessary gates that stall the flow without real value.
- Don't modify the canonical gate phrases (the ones that say `**Stop. Do not proceed until…**`) without reviewing the impact on all the skills that reference them.
- Don't do `git push --force` to `main`.
- Don't skip git hooks (`--no-verify`).
- Don't run `git add`, `git commit`, `git push`, or `gh pr create` from inside any flow other than `incu-way-prepare-pr`, and never without the user explicitly asking for that action right now.
