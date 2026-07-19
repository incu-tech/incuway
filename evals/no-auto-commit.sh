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

require_not_contains() {
  local file="$1"
  local text="$2"

  if grep -Fq "$text" "$ROOT_DIR/$file"; then
    fail "$file contains forbidden text: $text"
  fi
}

# Flow skills must never run git commit/push or gh pr create themselves — they only
# suggest invoking incu-way-prepare-pr.
flow_skill_files=(
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

for file in "${flow_skill_files[@]}"; do
  require_contains "$file" "incu-way-prepare-pr"
  require_not_contains "$file" "gh pr create \\"
done

# incu-way-init is the sole, explicitly-confirmed exception: it may still bootstrap an
# empty initial commit / missing develop branch, but only after asking first.
require_contains "skills/incu-way-init/SKILL.md" "empty initial commit to establish"
require_contains "skills/incu-way-init/SKILL.md" "\`develop\` doesn't exist yet."

# incu-way-prepare-pr is the only skill allowed to actually run these commands, and only
# on explicit user request.
require_contains "skills/incu-way-prepare-pr/SKILL.md" "user explicitly asks"
require_contains "skills/incu-way-prepare-pr/SKILL.md" "git push -u origin {branch}"
require_contains "skills/incu-way-prepare-pr/SKILL.md" "gh pr create --base {base}"

# The universal rule must be documented where humans and downstream projects will read it.
require_contains "CLAUDE.md" "No auto-commits:"
require_contains "CLAUDE.md" "incu-way-prepare-pr"
require_contains "skills/incu-way-init/claude.template.md" "## Committing and PRs (UNIVERSAL RULE)"
require_contains "skills/incu-way-init/claude.template.md" "incu-way-prepare-pr"

# The state file is written on every transition but committed only via incu-way-prepare-pr.
# The canonical lifecycle lives in the state-contract rulepack (travels with `ways add`).
require_contains "ways/rulepacks/state-contract/rules/state-contract.md" "incu-way-prepare-pr"
require_not_contains "ways/rulepacks/state-contract/rules/state-contract.md" "The state file **is committed** together with the documents and the code on each"

printf 'PASS: no skill auto-commits, auto-pushes, or auto-opens a PR\n'
