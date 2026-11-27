# Spec — {{capability_name}} ({{cap_id}})

> **Behavior, not structure.** This spec describes what the component does, observable from
> outside: inputs → outputs and side effects. It must not name frameworks, annotations, classes or
> layers. Anyone should be able to build an equivalent implementation (or a black-box test suite)
> from it without reading the code.

- **Component:** {{component_name}} · **Baseline commit:** {{baseline_commit}}
- **Entry points:** {{EP ids}} · **Depth:** {{full | light}}
- **Status:** draft <!-- draft | in-review | approved -->
- **Approved by / at:** — <!-- filled at the spec gate -->

## 1. Overview

What this capability does in business terms: who triggers it, why, and where it sits in the larger
flow.

## 2. Business rules

Numbered and testable. Each rule is an observable input → output / side effect and cites its
evidence (`path:line`, config key, or usage data). A rule backed only by `docs` or
`graph-inferred` evidence is marked **(unverified)** and has a matching question in `QUESTIONS.md`.

- **BR-1** — … *(evidence: `path:line`)*
- **BR-2** — …

## 3. Interactions

One subsection per entry point. The fields that apply depend on its kind.

### {{EP-id}} · {{kind}} · {{trigger}}

- **Input:** shape of the request/message/arguments/user action (fields, types, required/optional,
  validation rules).
- **Preconditions / auth:** who may trigger it, and the checks in the order they apply.
- **Happy path:** the result: status + exact body, emitted message, exit code + output, or
  resulting screen/state.
- **Errors / alternative outcomes:** one row each, with the exact observable result:

  | Condition | Result (status / exit code / screen) | Body or message (exact shape) |
  |---|---|---|

- **Side effects:** data written, messages published, downstream calls, files, notifications, and
  when each happens (before/after the response, transactional or not).
- **Idempotency / ordering / concurrency:** is a repeat safe, and keyed on what? Ordering
  assumptions (messages)? Locking?
- **Downstream behavior:** per outbound call: timeout, retries, and what the caller observes when
  it fails.
- **Configuration that changes behavior:** flags/switches and their effect.
- **Usage:** {{usage | null}}

## 4. Data

Entities this capability reads or writes, the fields that matter to its behavior, and invariants
(uniqueness, state transitions). Use a state diagram (Mermaid `stateDiagram-v2`) when an entity has
a life cycle.

## 5. Flow

A Mermaid `sequenceDiagram` of the main path through actors, the component and its downstreams.
Validate it before writing (it must render).

## 6. Non-functional observations

Only what is observable and evidenced: timeouts, rate limits, pagination limits, payload size
limits, caching (TTL), audit/logging of business events. Do not speculate.

## 7. Contract

Link to the contract artifact for this capability (`contract.openapi.yaml`,
`contract.asyncapi.yaml`, `contract.graphql`, or `contract.md` for cli/schedule/ui/library). The
contract and this spec must agree.

## 8. Open questions

Everything that could not be established from code, config or usage lives in `QUESTIONS.md` as
**closed questions**. This spec cannot be approved while any question is `open` (only `answered` or
explicitly `deferred`).
