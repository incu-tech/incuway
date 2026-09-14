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

# Every incu-way skill (except incu-way-prepare-pr, which imposes no repo structure of its
# own) must check the global blacklist before doing anything else — a repo opted out of
# incu-way should never get its structure imposed, even when the skill is installed
# globally.
skill_files=(
  "skills/incu-way-init/SKILL.md"
  "skills/incu-way-docs/SKILL.md"
  "skills/incu-way-arch-assessment/SKILL.md"
  "skills/incu-way-security-validation/SKILL.md"
  "skills/incu-way-threat-model/SKILL.md"
  "skills/incu-way-po/SKILL.md"
  "skills/incu-way-development/SKILL.md"
  "skills/incu-way-bugs/SKILL.md"
  "skills/snyk-remediation/SKILL.md"
)

for file in "${skill_files[@]}"; do
  require_contains "$file" "Repo eligibility check (before anything else)"
  require_contains "$file" '`~/.ways/config.yaml`'
  require_contains "$file" '`blacklist`'
  require_contains "$file" "ask whether to proceed anyway"
done

# The schema itself is documented once, canonically, in CLAUDE.md.
require_contains "CLAUDE.md" "## Global config: \`~/.ways/config.yaml\`"
require_contains "CLAUDE.md" "blacklist:"
require_contains "CLAUDE.md" "Matched loosely against the current repo's git"

printf 'PASS: every incu-way skill checks the global repo blacklist before anything else\n'
