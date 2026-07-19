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
  require_contains "$file" "## Isolation setup"
  require_contains "$file" "Do you want me to work in a new branch in the current checkout, or create a separate git worktree?"
  require_contains "$file" "Use the user's answer exactly"
  require_contains "$file" "Stop after asking; do not create a branch or worktree until the user chooses one."
  require_contains "$file" "If the current checkout has uncommitted changes, stop and ask before switching branches or creating a worktree."
  require_contains "$file" "### Option A — Branch in current checkout"
  require_contains "$file" "### Option B — Separate worktree"
  require_contains "$file" "git switch develop"
  require_contains "$file" "git pull --ff-only"
  require_contains "$file" "git fetch origin develop"
  require_contains "$file" "Create worktrees only under \`.worktrees/\`. Do not ask the user for a path."
  require_contains "$file" "mkdir -p .worktrees"
  require_contains "$file" "origin/develop"
  require_not_contains "$file" "## Worktree setup"
  require_not_contains "$file" "## Branch setup"
  require_not_contains "$file" "<absolute path to the worktree>"
  require_not_contains "$file" "worktree only"
  require_not_contains "$file" "create the isolated worktree"
  require_not_contains "$file" "right after the worktree"
  require_not_contains "$file" "worktree just created"
done

require_contains "skills/incu-way-init/claude.template.md" "## Work isolation first"
require_contains "skills/incu-way-init/claude.template.md" "Do you want me to work on a new branch in the current checkout, or to create a separate git worktree?"
require_contains "skills/incu-way-init/claude.template.md" "Use exactly the option the user picks."
require_contains "skills/incu-way-init/claude.template.md" "Stop after asking; do not create a branch or worktree until the user chooses one."
require_contains "skills/incu-way-init/claude.template.md" "### Option A — Branch in the current checkout"
require_contains "skills/incu-way-init/claude.template.md" "### Option B — Separate worktree"
require_contains "skills/incu-way-init/claude.template.md" "Create worktrees only under \`.worktrees/\`. Do not ask the user for a path."
require_contains "skills/incu-way-init/claude.template.md" "mkdir -p .worktrees"
require_contains "skills/incu-way-init/claude.template.md" "origin/develop"
require_not_contains "skills/incu-way-init/claude.template.md" "## Worktree primero"
require_not_contains "skills/incu-way-init/claude.template.md" "dentro del worktree"
require_not_contains "skills/incu-way-init/claude.template.md" "worktree only"


printf 'PASS: isolation choice workflow is enforced\n'
