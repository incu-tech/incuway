# Specs from Code: the `incu/specs-from-code` way

Member `specs` of the `incu/incu-way` family. The flow is driven by
[`skills/specs-from-code`](../../skills/specs-from-code/SKILL.md).

Point it at an existing component and it reads the code to work out what that component does,
then writes it down as functional specs you can review, sign and test against. It works on any
stack, including polyglot repos.

The code is the source of truth. Existing docs, READMEs and API specs are read and cross-checked
against it, and every place where they disagree with the code ends up as a question for you to
answer.

## When to use it

- Before a migration or rewrite, to get a signed functional baseline of the old system.
- To build a black-box test suite, since every rule comes with its inputs, exact errors and side
  effects.
- To onboard a team onto an undocumented or legacy component.
- To refine tickets against a system nobody has written down.
- To refresh specs after the code changed. Only the affected capabilities are specified again.

It is not meant for designing features that do not exist yet.

## What you get

```
docs/specs/{slug}/
  inventory.json     every entry point, outbound call, data store and config key, with evidence
  INVENTORY.md       human summary of the inventory
  CAPABILITIES.md    entry points grouped into capabilities (Gate 1)
  {cap-id}-{slug}/   one folder per capability (Gate 2, signed one by one)
    SPEC.md          behavior, not structure: rules, interactions, exact errors, side effects
    contract.*       OpenAPI / AsyncAPI / GraphQL SDL / contract.md, by entry-point kind
    QUESTIONS.md     closed questions, none left open at sign-off
  README.md          index + coverage matrix (every entry point accounted for exactly once)
```

Every business rule cites `path:line`, a config key or usage data. A rule with no code evidence is
marked **(unverified)** and gets a question. Configuration is recorded by name only, and secret
values are never copied.

## How it runs

```
discovery → inventory → capability map ──[Gate 1]──→ specs, one capability at a time ──[Gate 2 each]──→ coverage → PR ──[Gate 3]──→ done
```

1. Orientation. The skill works out whether this is a new run or a refresh, then asks for the
   scope (the whole repo, a folder or one deployable) and whether to work in a branch or a
   worktree. It detects the stacks and reads the existing docs. If you have a usage export
   (access logs, APM, queue metrics), it uses it to mark entry points that nobody calls.
2. Inventory. It lists every way the outside world can trigger behavior: HTTP routes, webhooks,
   queue consumers, cron jobs, CLIs, UI routes and library exports. `inventory.json` is
   validated against the bundled schema.
3. Capability map (Gate 1). Entry points are grouped into capabilities with business names, or
   excluded with a reason, and `scripts/check_coverage.py` confirms none was left out. You
   approve the boundaries, the depth of each spec and what is in scope for this run.
4. Specs (Gate 2, per capability). For each capability it traces the behavior from the handler
   down to persistence and outbound calls, writes a contract that fits the entry-point kind and
   draws Mermaid diagrams. A final check removes framework and class names from the spec. You
   sign each spec separately.
5. Coverage and PR (Gate 3). It writes the index and coverage matrix and runs the coverage check
   again. Then it tells you what to commit, and you commit and open the PR yourself.

The skill only pauses at the three gates and at the branch-or-worktree question. Progress is kept
in `.ways/state.json`, so a large component can be specified over several sessions.

## Guarantees

The skill writes only under `docs/specs/{slug}/` and to `.ways/state.json`, and never touches
application code or config. It never runs `git add`, `commit` or `push` and never opens a PR. At
each checkpoint it suggests `incu-way-prepare-pr`, which commits and opens the PR when you ask.

Unknown values are recorded as `null` with a warning, or as a question in the spec. Usage numbers
come only from a source you provide.

It needs no scanners. Besides the family's `vcs-host` slot for the PR, it uses `git`, Python 3 for
the coverage check, and any JSON Schema validator for the inventory (`ajv-cli` via `npx`, or
`check-jsonschema`).

It talks to you in your language and writes the artifacts in the language of the repo's existing
docs, or in English when there are none.

## Install

```bash
ways add github:incu-tech/incuway --members specs    # this flow plus the family's shared payload
```

As with every member, the shared payload installs too: all the family skills, the state contract
and the baseline rules.

Then ask for it in plain words, e.g. "extract what this service does into specs", "documentá qué
hace este worker", or invoke `/specs-from-code`.

## Layout

```
ways/specs-from-code/
  way.yaml                                kind: Way · incu/specs-from-code (member `specs`)
  rules/conventions.md                    always-on: behavior not structure, evidence, no secrets
skills/specs-from-code/                   declared by the family (/way.yaml)
  SKILL.md                                the gated flow
  schemas/inventory.schema.json           stack-agnostic inventory contract
  scripts/check_coverage.py               every entry point assigned or excluded, exactly once
  templates/                              INVENTORY, CAPABILITIES, SPEC, QUESTIONS, INDEX
  references/entry-point-detection.md     where to look, per stack
```

The `.ways/state.json` format comes from the family's always-on `state-contract` rule, which lists
the `analysis/specs` phases.

## Validate

```bash
ways validate ways/specs-from-code/way.yaml
ways conformance ways/specs-from-code/way.yaml     # → conformant
```
