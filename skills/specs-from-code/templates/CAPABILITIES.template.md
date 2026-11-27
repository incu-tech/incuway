# Capability map — {{component_name}}

- **Baseline commit:** {{baseline_commit}}
- **Status:** draft <!-- draft | in-review | approved -->

A **capability** is one cohesive thing the component does for someone, observable from outside,
named in business terms ("Issue a refund", not "RefundController"). Each entry point belongs to
**exactly one** capability or is listed under **Excluded** with a reason.

## Capabilities

| CAP | Name | Actor(s) | Entry points | Outbound / stores touched | Usage | Depth | In scope now |
|---|---|---|---|---|---|---|---|
| CAP-01 | … | … | EP-001, EP-004 | … | … | full / light | yes / later |

**Depth:** `full` = every case including errors and side effects; `light` = happy path, error list
and contract only. Base it on risk and usage.

### Why these boundaries

One short paragraph per non-obvious cut, traced to the coupling/graph evidence (shared data,
shared downstream, a graph community or hyperedge). Do not cut by intuition.

## Excluded entry points

Mirrors `exclusion` in `inventory.json` (same EP ids, same reason). `scripts/check_coverage.py`
output: `{{coverage summary line}}`.

| EP | Reason | Recommendation |
|---|---|---|
| EP-0xx | dead-surface candidate (usage 0 in 30d) / health / infra / internal-only | spec later / retire candidate / out of scope |

## Open granularity questions

Split vs. merge questions for the reviewer. Write "none" if there are none.
