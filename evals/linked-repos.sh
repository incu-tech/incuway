#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_contains() {
  local file="$1"
  local text="$2"

  grep -Fq "$text" "$ROOT_DIR/$file" || fail "$file is missing required text: $text"
}

# The three skills that do multi-repo discovery must resolve linked repos the same way:
# a hub repo's own CLAUDE.md `repos:` section always wins (versioned with the product,
# team-visible); ~/.ways/config.yaml's linkedRepos is only a fallback for products that
# haven't declared one yet.
discovery_files=(
  "skills/incu-way-po/SKILL.md"
  "skills/incu-way-development/SKILL.md"
  "skills/incu-way-bugs/SKILL.md"
)

for file in "${discovery_files[@]}"; do
  require_contains "$file" '`repos:`'
  require_contains "$file" 'wins'
  require_contains "$file" '`linkedRepos`'
  require_contains "$file" '`~/.ways/config.yaml`'
done

# The schema itself is documented once, canonically, in CLAUDE.md, and states the priority
# explicitly so a reader never has to infer it from the skills alone.
require_contains "CLAUDE.md" "linkedRepos:"
require_contains "CLAUDE.md" "This is a fallback, not the primary source"

printf 'PASS: incu-way-po/development/bugs resolve linked repos with the hub CLAUDE.md taking priority\n'
