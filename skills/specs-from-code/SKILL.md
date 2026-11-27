---
name: specs-from-code
version: 0.1.2
description: Extract what existing code actually does, straight from the source, into development-grade functional specs. Works on any component (service, web app, worker, function, CLI or library; any stack, polyglot included). The code is the source of truth and docs are only cross-checked. Produces a schema-validated inventory of entry points and dependencies, a capability map, and one signed behavioral SPEC.md + contract + closed-question QUESTIONS.md per capability, with a coverage matrix proving every entry point is accounted for. Use it whenever someone wants to know, recover or document what a codebase does from the outside (endpoints, webhooks, queues, cron jobs, CLIs, business rules, exact errors, side effects), especially for undocumented or legacy systems, before a migration, rewrite, black-box test suite, onboarding or ticket refinement, or to resume or refresh specs under docs/specs/. Also triggers on Spanish requests such as "extraer la funcionalidad del código", "qué hace este servicio", "documentar el sistema legacy", "relevar la funcionalidad", "specs funcionales" or "baseline funcional antes de migrar", even when the skill is not named. Not for writing specs of features that do not exist yet.
---

# Specs from Code (inventory → capabilities → specs)

A gate-driven workflow that extracts the functionality of **existing code** from the code itself
and turns it into a **functional baseline**: what the component does, observable from outside,
written so that someone could rebuild it, test it as a black box, or reason about changing it,
**without reading the code**.

It is **stack-agnostic**. The output is defined by contracts (`schemas/inventory.schema.json` and
the templates in `templates/`), not by a scanner. You produce the inventory by reading the code,
using a knowledge graph when one exists and any stack-specific tool that helps. The result must
satisfy the schema whatever the stack, including polyglot repos.

It needs no scanner, tool binding or external service beyond `git`, which it uses for isolation
and the baseline commit. Narrative architecture docs (if the repo
has them) are read as input and not duplicated. The signed specs are the input for a migration, a
rewrite, a black-box test suite, or ticket refinement.

This is a gated work-item flow (`flow: analysis/specs`). It keeps a `.ways/state.json`, because a
component with many capabilities is specified over several sessions and each capability is signed
separately. See **State tracking**.

**Read-only over behavior.** This flow never modifies application code or config. It writes only
under `docs/specs/{slug}/` and `.ways/state.json`.

**Language.** Talk to the user in their language. Write the artifacts in the language of the
repo's existing docs (English when there are none), so the specs read like the rest of the repo.
Contract names (paths, fields, statuses, error codes) stay verbatim whatever the language.

**Pacing.** The flow stops only at the three gates and at the isolation question. Between them,
keep going: Phase 1 runs straight into Phase 2, and Phase 4 straight into Phase 5.

---

## Phase 0 — Orientation, mode and scope (read-only)

**Goal:** know what you are specifying and how before writing anything.

1. **Mode.** Look for a previous run under `docs/specs/{slug}/`. `inventory.json` is the marker,
   because it is written first; `README.md` only exists once a run reached Phase 4.
   - **New:** no `inventory.json`.
   - **Refresh:** `inventory.json` exists. Its baseline is `component.baselineCommit`. Run
     `git diff --name-only {baseline}..HEAD -- {scopePaths}` and map each changed file to the entry
     points and spec rules whose evidence cites it. The refresh re-inventories, and re-specs
     **only the affected capabilities**. Everything else keeps its signature. Keep existing EP ids
     stable (a reviewer's notes refer to them); new entry points get the next free id, and removed
     ones are reported, not renumbered. If the previous run stopped before Gate 1 (no approved
     `CAPABILITIES.md`), say so: the refresh resumes from the capability map with the new
     inventory.
2. **Scope.** Confirm the component boundary with the user if it is not obvious: the whole repo, a
   sub-folder/module, or one deployable in a monorepo. Derive `{slug}` from it (kebab-case, e.g.
   `payments-api`, `checkout-web`). Ask the scope question **in the same message** as the
   isolation question below, so the user answers both in one round trip.
3. **Stacks.** Detect every language/framework in scope using
   `references/entry-point-detection.md` §1. Say what you found, including when there is more
   than one.
4. **Existing knowledge.** Read `README.md`, `PRD.md`, `docs/architecture/`, `docs/functional/`,
   `docs/requirements/` and any API specs (OpenAPI/AsyncAPI/proto/GraphQL SDL) already in the
   repo. If a knowledge graph exists (`graphify-out/graph.json`), check its freshness against the
   scope paths (`absent` / `current` / `stale` + which paths), as in
   `references/entry-point-detection.md` §5.
5. **Usage source.** Ask whether a usage export is available (gateway/access logs, APM, queue
   metrics, analytics). It is optional. Without one, the dead-surface analysis is
   **structure-only**, and you state that now.

**Exit criteria. Be able to state:** mode, scope paths, slug, stacks, graph status, existing docs
read, and whether usage data is available.

## Isolation setup

Ask the user how they want to isolate the work before writing:

> Do you want me to work in a new branch in the current checkout, or create a separate git worktree?

Use the user's answer exactly.
Stop after asking; do not create a branch or worktree until the user chooses one.

If the current checkout has uncommitted changes, stop and ask before switching branches or creating a worktree.
Untracked files that come from installing the way itself (`.claude/`, `.ways/`, `ways.yaml`,
`ways.lock`, `*-lock.json`) do not count: a new branch carries them along untouched, so mention
them and continue. Do flag that a worktree created from `origin/develop` will **not** contain them
while they are uncommitted. The session already has the skill loaded, so the flow still works, but
the user should commit the way installation if teammates will run it from that worktree.

### Option A — Branch in current checkout

```bash
# Run from the repo root
git switch develop
git pull --ff-only
git switch -c specs/{slug}
```

### Option B — Separate worktree

Create worktrees only under `.worktrees/`. Do not ask the user for a path.

```bash
# Run from the repo root
git fetch origin develop
mkdir -p .worktrees
git worktree add .worktrees/specs-{slug} -b specs/{slug} origin/develop
```

If the repo has no `develop` branch, use its default branch in place of `develop` above and say
so. Then create `.ways/state.json` (see **State tracking**).

---

## Phase 1 — Inventory

**Goal:** a complete, evidenced map of the component's inbound surface, outbound calls, data
and behavior-changing configuration.

1. Enumerate entry points by `kind` using `references/entry-point-detection.md` §2. **Confirm the
   owner of every signal** before you classify it (an annotation on a client interface is an
   outbound call, and a route in a test is not an entry point). With a current graph, take the
   owner relations and grouping from it, and use code reading to cross-check. A disagreement
   between the two is a finding: resolve it against the code.
2. Enumerate outbound calls, data stores and configuration (§3). Record **names only** for
   configuration. Never copy secrets, tokens or connection strings.
3. Attach **evidence** to every item (`source` + `ref`). `graph-inferred` and `docs` evidence is
   allowed in the inventory, but it is labelled as such.
4. Join the usage data if provided (§4). Never estimate usage. Record what the metric actually
   counts when it differs from "calls" (e.g. queue receives include redeliveries).
5. Write `docs/specs/{slug}/inventory.json`. It **must validate** against
   `schemas/inventory.schema.json` (bundled with this skill). The schema uses `format: date-time`,
   so the validator needs format support or it rejects the schema itself. Commands known to work:

   ```bash
   check-jsonschema --schemafile <skill>/schemas/inventory.schema.json docs/specs/{slug}/inventory.json
   # or, with Node available (downloads ajv on first use):
   npx -y -p ajv-cli@5 -p ajv-formats@3 ajv validate --spec=draft2020 -c ajv-formats \
     -s <skill>/schemas/inventory.schema.json -d docs/specs/{slug}/inventory.json
   ```

   If no validator can run (no Node, no network, no Python package), say so explicitly and check
   the required fields by hand. **Never report it as validated when it was not**: a reviewer
   trusts that word, and the inventory is the base for everything after it.
6. Write `docs/specs/{slug}/INVENTORY.md` from `templates/INVENTORY.template.md`.
7. Relay every `warnings[]` entry to the user verbatim.

## Phase 2 — Capability map

**Goal:** group entry points into capabilities that can each be specified and signed on their own.

- Propose **capabilities by use-case** (business-named, observable), minimizing shared state
  between them. Seed candidates from graph communities/hyperedges when a current graph exists.
  A community is finer-grained than a capability, so group communities. Do not map one
  community to one capability.
- Assign **every** entry point to exactly one capability, or list it under **Excluded** with a
  reason (dead-surface candidate, health/infra, internal-only) and a recommendation.
- Propose a **depth** per capability (`full` / `light`) from risk and usage, and which
  capabilities are **in scope now** vs. a later run.
- Write `docs/specs/{slug}/CAPABILITIES.md` from `templates/CAPABILITIES.template.md`. In
  `inventory.json`, set `capability` on each assigned entry point, and on each excluded one set
  `capability: null` plus `exclusion: { reason, recommendation }`. The inventory then carries the
  whole assignment, so coverage can be checked by a script instead of by reading markdown.
- Run `python3 <skill>/scripts/check_coverage.py docs/specs/{slug}/inventory.json`. It needs only
  the standard library and exits non-zero if any entry point is unassigned, both assigned and
  excluded, or duplicated. Fix the map until it passes, and quote its summary line at the gate.

### Gate 1 — Capability map review

Present the capability table, the excluded entry points, the depth/scope proposal and the open
granularity questions (split vs. merge).

Say: **"Capability map ready. Review the boundaries, exclusions and scope."**

**Stop. Do not proceed until the user has approved the capability map and the scope.**

When approved, generate `steps` in `.ways/state.json`, one per in-scope capability
(`CAP-01 — Issue a refund`), all `todo`.

## Phase 3 — Specs (one capability at a time)

**Goal:** for each in-scope capability, a behavioral spec that a reviewer can sign.

For each capability (mark its step `in-progress`):

1. **Reverse-engineer behavior** from code, config and usage. Cover every interaction: input,
   auth/preconditions in order, happy path, **every error with its exact observable result**,
   side effects and their timing, idempotency/ordering, downstream timeouts/retries/failure
   behavior, and behavior-changing config. Read the code paths fully (handlers → domain →
   persistence/outbound); do not stop at the handler signature.
2. Write in `docs/specs/{slug}/{cap-id}-{cap-slug}/`:
   - `SPEC.md` from `templates/SPEC.template.md`. Every business rule cites evidence. A rule
     backed only by `docs`/`graph-inferred` evidence is marked **(unverified)** and gets a question.
   - **The contract, by entry-point kind** (a capability whose entry points have several kinds
     gets one contract file per kind, e.g. a queue consumer plus an operator CLI →
     `contract.asyncapi.yaml` + `contract.md`): `http`/`webhook` → `contract.openapi.yaml`
     (OpenAPI 3.1); `message` → `contract.asyncapi.yaml` (AsyncAPI 3.0: payload schema, ack
     semantics, which failures ack vs. redeliver); `graphql` → `contract.graphql` (the SDL subset
     this capability owns); `grpc` → reference the `.proto` and write `contract.md` with the
     error-status mapping; `cli`/`schedule`/`ui-route`/`library-export`/other → `contract.md`
     (commands + exit codes, trigger + inputs, screens + user actions, public signatures). If the
     repo already ships a contract, reference it and record the discrepancies you found. Do not
     silently fork it.
   - `QUESTIONS.md` from `templates/QUESTIONS.template.md`. Questions must be closed, and the file is
     never empty by omission.
3. **Diagrams:** at least the sequence diagram of the main path (and a state diagram when an entity
   has a life cycle), in Mermaid. Validate that each renders before writing it, e.g. save it to a
   scratch `.mmd` file and run `npx -y @mermaid-js/mermaid-cli@11 -i d.mmd -o d.svg`. If no
   renderer can run, say the diagrams were not render-checked rather than implying they were.
4. **Leakage self-check.** Grep the SPEC.md for the framework, library and annotation names of
   the stacks detected in Phase 0 (and `@[A-Z]` for annotations), and for class names taken from
   the handlers. Rewrite every hit as behavior. Names of external contracts (a field, a topic, an
   HTTP path) are behavior and stay.
5. Set the SPEC.md document to `in-review` and present it for sign-off.

### Gate 2 — Spec sign-off (per capability)

Present the spec, the contract and `QUESTIONS.md`. Every question must be `answered` or explicitly
`deferred`. None stays `open`. Batch several capabilities into one review only if the user asks.

Say: **"Spec for {CAP-id} ready. Answer or defer each open question, then sign off."**

**Stop. Do not proceed until the user has signed off on this capability's spec.**

On sign-off, fill **Approved by / at** in the SPEC.md, set its status `approved`, mark the step
`done`, and continue with the next capability. The `spec` gate in `.ways/state.json` passes only
when **every in-scope capability** is approved.

## Phase 4 — Coverage and index

**Goal:** prove nothing was silently dropped and leave one entry point for readers.

- Write `docs/specs/{slug}/README.md` from `templates/INDEX.template.md`: the spec table, the
  **coverage matrix** (every EP in `inventory.json` appears exactly once, as specified, excluded or
  deferred to a later run), and the consolidated deferred questions.
- Check the coverage mechanically: re-run `scripts/check_coverage.py` on `inventory.json`, then
  confirm the README's coverage matrix lists the same EP ids with the same assignment. Report the
  counts, and any EP left unaccounted. Zero unaccounted is required.
- **Refresh mode:** list the specs that changed, the specs that stayed valid (with their original
  signature), and any new entry points added since the baseline.

## Phase 5 — PR

This skill never runs `git add`, `git commit`, `git push` or opens a PR itself. Tell the user the
specs are ready to persist: the commit should contain `docs/specs/{slug}/` **and**
`.ways/state.json` together, and the PR goes `specs/{slug}` → `develop`. Suggest invoking
**`incu-way-prepare-pr`**, which does both when the user asks for it.

### Gate 3 — PR review

Say: **"Specs are ready for PR. Invoke `incu-way-prepare-pr` when you want to commit and open it."**

**Stop. Do not proceed until the user has reviewed the PR.** The flow is `done` when it merges.

---

## Authoring rules (non-negotiable)

- **Behavior, not structure.** No framework, class, layer or annotation names in specs.
- **Traceable.** Every rule and every interaction field cites `path:line`, a config key, or the
  usage data.
- **No invention.** Unknown means `null` plus a warning (inventory) or a closed question (spec).
  Document what the code does, not what it should do. When code and docs disagree, the code
  describes current behavior; record the conflict as a question.
- **Exact errors.** An error is a condition plus the exact observable result (status/exit
  code/screen plus body shape), not "returns 400".
- **No secrets.** Configuration is recorded by name; example payloads use synthetic values.

## Acceptance criteria

- `inventory.json` validates against `schemas/inventory.schema.json` (or the user was told it
  could not be validated and why). `warnings[]` was relayed.
- Every entry point is accounted for exactly once in the coverage matrix (0 unaccounted), and
  `scripts/check_coverage.py` passes on `inventory.json`.
- Every in-scope capability has `SPEC.md` (approved, signed), one contract per entry-point kind
  it contains, and a `QUESTIONS.md` with no `open` question.
- Specs pass the leakage self-check.
- Application code and config are untouched; nothing was committed by this skill.

## State tracking — `.ways/state.json`

Follow the **ways/v1alpha1 state contract**, the canonical `.ways/state.json` format, shipped as
the **always-on `state-contract` rule** that `ways add` places into the project, so it is already
in your context (no path to follow). Its source in this repo, for maintainers, is
`ways/rulepacks/state-contract/`. Do not copy or invent a schema in this skill.

Flow-specific values:
- `flow`: `analysis/specs`
- `way`: `incu/specs-from-code` · `discipline`: `analysis` (optionally `wayVersion` from the way manifest)
- Branch pattern: `specs/{slug}`
- Initial `phase`: `discovery`
- `isolationType`: `branch` or `worktree`, from the isolation setup
- Documents: `docs/specs/{slug}/INVENTORY.md`, `docs/specs/{slug}/CAPABILITIES.md`, then one
  `docs/specs/{slug}/{cap-id}-{cap-slug}/SPEC.md` per in-scope capability (added when Gate 1
  passes), and `docs/specs/{slug}/README.md`
- Gates: `capability-map`, `spec`, `pr`

**Update points (phase → what to write):**

| When | `phase` | Documents / gates / steps |
|------|---------|---------------------------|
| Isolation set up | `discovery` | all documents `pending` |
| Inventory written | `analysis/inventory` | `INVENTORY.md` → `done` |
| Capability map drafted | `analysis/capability-map` | `CAPABILITIES.md` → `in-review` |
| **Gate passed (capability map)** | `analysis/spec` | `CAPABILITIES.md` → `approved`; gate `capability-map` → `passed`; add one `SPEC.md` document per in-scope capability (`pending`); **generate `steps`, one per in-scope capability, all `todo`** |
| Working on a capability | `analysis/spec` | its step → `in-progress`; its `SPEC.md` → `draft`, then `in-review` |
| **Capability signed** | `analysis/spec` | its `SPEC.md` → `approved`; its step → `done`. Write the file **per capability, immediately** |
| **All in-scope capabilities signed** | `analysis/coverage` | gate `spec` → `passed` |
| Index + coverage written | `pr` | `README.md` → `done` |
| PR opened | `pr` | gate `pr` → still `pending`; set its `url` |
| PR merged | `done` | gate `pr` → `passed` |

Do not commit `.ways/state.json` yourself. Only write it. When the user wants to persist a
checkpoint (e.g. after each signed capability), suggest invoking `incu-way-prepare-pr`, which
commits it together with the docs of that transition.

## Output layout

```
docs/specs/{slug}/
  README.md                       # index + coverage matrix + deferred questions
  INVENTORY.md                    # human summary
  inventory.json                  # validates against schemas/inventory.schema.json
  CAPABILITIES.md                 # capability map (Gate 1)
  {cap-id}-{cap-slug}/            # one per in-scope capability (Gate 2 each)
    SPEC.md
    contract.openapi.yaml | contract.asyncapi.yaml | contract.graphql | contract.md  (one per kind)
    QUESTIONS.md
```

Bundled with this skill: `schemas/inventory.schema.json` (the inventory contract),
`templates/` (one per artifact), `references/entry-point-detection.md` (where to look, per
stack) and `scripts/check_coverage.py` (entry-point assignment check, standard library only).
