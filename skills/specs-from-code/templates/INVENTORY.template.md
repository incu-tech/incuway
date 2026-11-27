# Inventory — {{component_name}}

> Human-readable summary of `inventory.json` (the source of truth for the numbers below). Short
> enough to paste into a chat. Every row traces to `inventory.json` evidence.

- **Component:** {{component_name}} (`{{slug}}`) · **Kind:** {{kind}}
- **Scope:** {{scope_paths}}
- **Baseline commit:** {{baseline_commit}}
- **Generated:** {{date}}
- **Knowledge graph:** {{absent | current | stale (paths)}}
- **Usage source:** {{source + window | none: dead-surface analysis is structure-only}}

## Stacks

| Language | Runtime | Frameworks | Paths |
|---|---|---|---|

## Inbound surface ({{n}} entry points)

| EP | Kind | Trigger | Handler | Auth | Usage |
|---|---|---|---|---|---|
| EP-001 | http | `GET /…` | `path:line` | … | null |

## Outbound and data

| Id | Kind | Target | Used by |
|---|---|---|---|

| Store | Kind | Technology | Entities | Access |
|---|---|---|---|---|

## Behavior-changing configuration

| Key | Kind | Secret | Affects |
|---|---|---|---|

## Tests

Types, frameworks, coverage (or `null` with the reason).

## Warnings

Copied verbatim from `inventory.json` `warnings[]`. Never empty: write "none" if there are none.
