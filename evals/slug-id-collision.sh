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

# Skills that assign a sequential zero-padded ID must check beyond the current checkout —
# a counter that only sees `docs/prds/`/`docs/requirements/`/`docs/bugs/` in this branch
# collides the moment two items are worked in parallel across worktrees/branches.
id_assigning_files=(
  "skills/incu-way-development/SKILL.md"
  "skills/incu-way-po/SKILL.md"
  "skills/incu-way-bugs/SKILL.md"
)

for file in "${id_assigning_files[@]}"; do
  require_contains "$file" "git worktree list"
  require_contains "$file" "Fetch the default branch"
  require_contains "$file" "one past the highest"
  # Scanning more places isn't enough on its own: two agents can scan at the same instant
  # and compute the same id. A same-machine lock across scan-and-reserve is what actually
  # closes that (see incu-tech/incuway PR #6 review).
  require_contains "$file" "git rev-parse --git-common-dir"
  require_contains "$file" "mkdir \"\$LOCK\""
  require_contains "$file" "before releasing the lock"
  # The old shallow phrasing (only checks the current checkout) must not survive verbatim.
  require_not_contains "$file" "check both to find"
  require_not_contains "$file" "Check existing slugs in \`docs/bugs/\` for the next ID."
done

printf 'PASS: PRD/ticket/bug slug IDs are checked across worktrees + the remote default branch\n'
