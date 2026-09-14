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

# incu-way-prepare-pr is the only skill that ever opens a PR, so it's the one gate
# that has to strip internal attribution (names, Slack channels/dates, quotes) before
# anything ships to a public repo.
FILE="skills/incu-way-prepare-pr/SKILL.md"

require_contains "$FILE" "Public-repo content check"
require_contains "$FILE" "isPrivate"
require_contains "$FILE" "Treat it as public whenever the check says so, or whenever it can't be run"
require_contains "$FILE" "A person's name, handle, or initials"
require_contains "$FILE" "The name of an internal channel"
require_contains "$FILE" "A verbatim quote or close paraphrase of an internal conversation"

# The check has to cover the whole outgoing diff, not just the PR body/branch/commit
# message: a linked document (BUG.md's Context, a PRD's intake notes) that this PR itself
# adds or modifies ships to the public repo too, and has to be sanitized, not just avoided
# in the PR text (see incu-tech/incuway PR #5 review).
require_contains "$FILE" "covers the entire outgoing diff"
require_contains "$FILE" "git diff {base}...{branch}"
require_contains "$FILE" "Sanitize that document"

# The 11-type allowlist is an org policy choice, not a claim about the Conventional
# Commits spec itself (which only defines feat/fix, and doesn't close off the type set).
require_contains "$FILE" "Incu org policy"

printf 'PASS: public-repo PRs are checked for internal-attribution leaks across the whole diff, and the commit-type list is labeled as org policy\n'
