# Functional specs — {{component_name}}

- **Baseline commit:** {{baseline_commit}} · **Generated:** {{date}}
- **Inventory:** [INVENTORY.md](INVENTORY.md) · [inventory.json](inventory.json)
- **Capability map:** [CAPABILITIES.md](CAPABILITIES.md)

## Specs

| CAP | Capability | Depth | Status | Approved by | Open/deferred questions |
|---|---|---|---|---|---|
| CAP-01 | [name](cap-01-slug/SPEC.md) | full | approved | … | 0 / 1 |

## Coverage matrix

Every entry point in `inventory.json` appears **exactly once**, either specified or excluded.

| EP | Kind | Trigger | Capability / Excluded | Spec section |
|---|---|---|---|---|

**Coverage:** {{specified}} specified · {{excluded}} excluded · {{later}} deferred to a later run ·
**0 unaccounted**.

## Deferred questions (consolidated)

| CAP | Q | Question | Deferral reason |
|---|---|---|---|

## Freshness

These specs describe `{{baseline_commit}}`. To check whether they are still current, re-run
`specs-from-code` in refresh mode. It diffs the scope paths since the baseline and marks the
affected specs stale.
