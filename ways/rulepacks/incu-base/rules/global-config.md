# Global config: `~/.ways/config.yaml`

A **user/machine-level** file, never part of any repo, it's how incu-way, installed once
globally, still behaves per-repo instead of imposing the same structure everywhere. This rule
travels with every installed way (`incu-base` is `applicability: always`), so consumer repos
have this schema even though it's not part of their own `CLAUDE.md`.

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

- **`blacklist`**, repos incu-way should never impose its structure on (a repo with its
  own flow and doc conventions already). Matched loosely against the current repo's git
  remote `owner/repo` slug, or its local directory name when there's no remote, an entry
  like `argenprop` matches any of those forms. **Every** incu-way skill checks this first,
  before Phase 0, before writing or asking anything else: if the current repo matches, say
  so and ask whether to proceed anyway (a one-off exception) or stop.
- **`linkedRepos`**, named groups of repos that make up one multi-repo product (e.g.
  `hrscheme`'s five repos). Used during discovery (`incu-way-po`, `incu-way-development`,
  `incu-way-bugs`) to name sibling repos a change might affect, even when the request only
  mentions one of them. **This is a fallback, not the primary source**: a hub repo's own
  `CLAUDE.md` can declare a `repos:` section for its product, and that always wins when
  present, it's versioned with the product and visible to the whole team, which a
  personal machine-level file can never be. `linkedRepos` only fills in when no hub
  declaration exists yet (a new or informally-tracked product).
- The file is optional everywhere. Missing file, missing key, or no match for the current
  repo, proceed exactly as if it didn't exist.
