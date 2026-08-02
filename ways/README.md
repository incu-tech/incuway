# ways/ — incuway as a way family

These are the **`ways/v1alpha1` artifacts** that describe incuway's own flows as installable *ways*.
The root `/way.yaml` is a **`kind: WayFamily`**: it *references* the member ways (each keeps its own
flow) and carries the payload shared across them. A way lives with the skills it packages, so these
manifests stay here in incuway. The `ways` **CLI** is published on npm as
[`@incu/ways`](https://www.npmjs.com/package/@incu/ways) (`npm install -g @incu/ways`), which also
carries the `ways/v1alpha1` contract these artifacts are validated against.

| Artifact | Kind | What |
|---|---|---|
| `/way.yaml` (repo root) | **WayFamily** | `incu/incu-way` — the **installable** family: 3 member ways + the shared skills, rules and slots. |
| `incu-dev/way.yaml` | Way (member `dev`) | `incu/dev` — the gated feature-development flow (8 phases, 5 gates) → `skills/incu-way-development`. |
| `incu-bugs/way.yaml` | Way (member `bugs`) | `incu/bugs` — the bug-fixing flow (9 phases, 2 gates) → `skills/incu-way-bugs`. |
| `incu-security/way.yaml` | Way (member `security`) | `incu/security` — the security-remediation flow (8 phases, 5 gates) → `skills/snyk-remediation`. |
| `rulepacks/incu-base/way.yaml` | RulePack | `incu/base-conventions` — shared security + branch-flow rules. |
| `rulepacks/state-contract/way.yaml` | RulePack | `incu/state-contract` — the canonical `.ways/state.json` contract. |
| `contracts/*.yaml` | SlotContract | `vcs-host`, `sast`, `sca`, `code-quality` capability interfaces. |
| `bindings/*.yaml` | Binding | github → vcs-host; snyk → sast/sca; sonarqube → code-quality. |

## Why a family and not one Way

incuway ships **three genuinely different gated flows**: feature (5 gates, PRD → PLAN → scans → two
PRs), bug (2 gates, a hard stop at the FIX_PLAN), and security (5 gates, starting with a
findings-scope gate). A single `Way` has exactly one `flow`, so the old root manifest had to declare
the feature flow *as if* it were the whole repo's — a fiction. A `WayFamily` has **no `flow` of its
own**: each member declares its own phases, gates, generated documents and state pointer, and the
family declares once what they all share.

**Members** (`spec.members`) — the gated *work-item* flows. They own a `.ways/state.json` life cycle
(one state file per worktree/branch) and their phase ids match the `feature` / `bug` / `security`
phase enums of the state contract, so what a manifest declares and what a skill writes to state are
the same vocabulary.

**Shared payload** — everything every member needs, declared once: the skills, the always-on rules
(state contract, security, branch flow), the capability slots with their default bindings, and
`requires`. It installs **regardless** of which members the consumer picks, because members depend
on it.

The other flows (`init`, `docs`, `po`, and the three assessment flows) are **not** members: they
produce a document under `docs/` and keep no work-item state, so they are not gated *work-item* ways.
They travel as shared skills, alongside `incu-way-prepare-pr` — the only skill allowed to touch git
persistence.

## Layout — why the skills are declared at the family level

A member way is installed **from its own directory**: the CLI copies `ways/<member>/` and refuses
bundled paths that escape it (`..`). A member therefore cannot point at `../../skills/…`. incuway
keeps a single `skills/` tree at the repo root, so **the family declares all ten skills** (including
the three that drive the members) and each member manifest describes only the flow those skills
execute. Deliberate trade-off: `--members bugs` installs one member way but still places the full
skill set.

## Install

```bash
ways add github:incu-tech/incuway                       # whole family: 3 members + shared payload
ways add github:incu-tech/incuway --members dev,bugs    # a subset of the flows
ways add /path/to/incuway                               # from a local checkout
```

`ways add` clones the source and requires a `way.yaml` **at the repo root** — that root manifest is
this family. The plan shows the member ways, the 10 skills (→ skills.sh) and the rules (→ steering)
as **one reviewable unit**; on approval it writes `ways.yaml` + `ways.lock` in the target project,
with one entry per installed member plus an umbrella entry for the family. Commit those two files:
`ways install` (`--frozen` for CI) reproduces the project's ways from them at the exact pinned
versions.

Interactively, `ways add` offers a member picker with every member pre-selected — deselect the flows
you don't want.

## Validate

```bash
# schema-valid (every artifact in the repo)
ways validate way.yaml ways/incu-*/way.yaml ways/rulepacks/*/way.yaml ways/contracts/*.yaml ways/bindings/*.yaml
# conformant — the family check also runs full Way conformance on every bundled member
ways conformance way.yaml ways/incu-dev/way.yaml ways/incu-bugs/way.yaml ways/incu-security/way.yaml
```

All artifacts are **schema-valid**; the family and its three members are **conformant** under
`ways/v1alpha1`. `ways doctor` is per-way, not per-family — point it at a member
(`ways doctor ways/incu-dev/way.yaml`) or run `ways doctor` in project mode.

`kind: WayFamily` needs a `ways` CLI that ships it —
[`@incu/ways`](https://www.npmjs.com/package/@incu/ways) v0.3.0 or later. Contract gaps found while
authoring these artifacts were fed back into the contract itself.

## Versioning

Each Ways artifact exposes its install/update version in `metadata.version` — the family and each
member version independently (the family went to `2.0.0` when it stopped being a fake single Way).
The repo-wide incuway skill bundle version lives in the root `VERSION` file and each
`skills/*/SKILL.md` frontmatter.
