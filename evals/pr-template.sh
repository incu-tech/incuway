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

TEMPLATE=".github/PULL_REQUEST_TEMPLATE.md"
SKILL="skills/incu-way-prepare-pr/SKILL.md"

[ -f "$ROOT_DIR/$TEMPLATE" ] || fail "$TEMPLATE is missing"

for section in "## Summary" "## Type of change" "## Root cause / motivation" \
  "## What changed" "## Testing" "## Breaking changes" "## Related issues"; do
  require_contains "$TEMPLATE" "$section"
done

# incu-way-prepare-pr must point to the template as the fixed body structure, not just
# leave it as a passive file nobody reads.
require_contains "$SKILL" "PULL_REQUEST_TEMPLATE.md"
require_contains "$SKILL" "never a free-form essay"

printf 'PASS: the PR template exists with its fixed sections, and incu-way-prepare-pr enforces it\n'
