# ways/ — incuway as the first way family

These are the **`ways/v1alpha1` artifacts** that describe incuway's own flows as installable *ways* —
incuway is the **first way family**. A way lives with the skills it packages, so these manifests stay
here in incuway. The `ways` **CLI, contract, and program docs** live in the
[`ways` repo](https://github.com/Incubator-it/ways) (`docs/program/`).

| Artifact | Kind | What |
|---|---|---|
| `/way.yaml` (repo root) | Way | `incu/incu-way` — the **installable** family bundle (all `skills/*`). |
| `incu-dev/way.yaml` | Way | `incu/dev` — the gated feature-development flow (→ `skills/incu-way-development`). |
| `incu-bugs/way.yaml` | Way | `incu/bugs` — the bug-fixing flow (→ `skills/incu-way-bugs`). |
| `rulepacks/incu-base/way.yaml` | RulePack | `incu/base-conventions` — shared security + branch-flow rules. |
| `contracts/*.yaml` | SlotContract | `vcs-host`, `sast`, `sca`, `code-quality` capability interfaces. |
| `bindings/*.yaml` | Binding | github → vcs-host; snyk → sast/sca; sonarqube → code-quality. |

## Install (with `ways.sh`)

`ways.sh add` clones the source, requires a `way.yaml` **at the repo root**, and refuses bundled
paths that escape the bundle (`..`) — so the root `/way.yaml` (`incu/incu-way`) is the installable
manifest; it packages all `skills/*` in one way. The per-flow manifests here stay as the
canonical per-way descriptions.

```bash
ways.sh add github:incu-tech/incu-way    # or: ways.sh add /path/to/incu-way
```

The plan shows the 10 skills (→ skills.sh) and the executable surface; on approval it writes
`ways.yaml` + `ways.lock` in the target project. Commit those two files: `ways.sh install`
(`--frozen` for CI) reproduces the project's ways from them at the exact pinned versions.

## Validate (with `ways.sh`)

```bash
# schema-valid
ways.sh validate way.yaml ways/incu-dev/way.yaml ways/incu-bugs/way.yaml
# conformant (Ways)
ways.sh conformance way.yaml ways/incu-dev/way.yaml ways/incu-bugs/way.yaml
```

All three ways are **schema-valid** and **conformant** under `ways/v1alpha1`. Contract gaps found while
authoring these were fed back to the contract — see `docs/program/slices/02-incu-dev-pilot/CONTRACT-FEEDBACK.md`
in the [`ways` repo](https://github.com/Incubator-it/ways).

## Versioning

Each Ways artifact exposes its install/update version in `metadata.version`. The repo-wide incuway
skill bundle version lives in the root `VERSION` file and each `skills/*/SKILL.md` frontmatter.
