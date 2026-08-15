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

FILE="skills/incu-way-prepare-pr/SKILL.md"

# The commit message format is the real Conventional Commits spec, not a repo-invented one.
require_contains "$FILE" "conventionalcommits.org"
require_contains "$FILE" "\`feat\`, \`fix\`, \`docs\`, \`style\`, \`refactor\`, \`perf\`, \`test\`, \`build\`, \`ci\`,"
require_contains "$FILE" "imperative mood"
require_contains "$FILE" "BREAKING CHANGE:"
require_contains "$FILE" "Closes #123"

# assess/ branches must map to a real Conventional Commits type (docs), never an invented one.
require_contains "$FILE" "an assessment/threat-model/security-validation report is documentation"
require_not_contains "$FILE" "assess({slug})"

# Atomic commits and the squash-merge PR title rule.
require_contains "$FILE" "One logical change per commit"
require_contains "$FILE" "The PR title is a Conventional Commits header"

printf 'PASS: incu-way-prepare-pr documents real Conventional Commits + atomic-commit practice\n'
