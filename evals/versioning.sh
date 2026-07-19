#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"
MODE="${1:-check}"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[ "$MODE" = "check" ] || [ "$MODE" = "--fix" ] || fail "usage: $0 [--fix]"

[ -f "$VERSION_FILE" ] || fail "VERSION file is missing"

version="$(tr -d '[:space:]' < "$VERSION_FILE")"
[ -n "$version" ] || fail "VERSION is empty"

for file in "$ROOT_DIR"/skills/*/SKILL.md; do
  if [ "$MODE" = "--fix" ]; then
    tmp="$(mktemp)"
    awk -v version="$version" '
      BEGIN { frontmatter=0; wrote=0 }
      /^---$/ { frontmatter++; print; next }
      frontmatter == 1 && /^name:/ { print; print "version: " version; wrote=1; next }
      frontmatter == 1 && /^version:/ { next }
      { print }
      END { if (!wrote) exit 1 }
    ' "$file" > "$tmp" || fail "${file#$ROOT_DIR/} has invalid frontmatter"
    mv "$tmp" "$file"
  fi

  skill_version="$(awk '
    /^---$/ { frontmatter++; next }
    frontmatter == 1 && /^version:[[:space:]]*/ { print $2; found=1; exit }
    END { if (!found) exit 1 }
  ' "$file")" || fail "${file#$ROOT_DIR/} is missing frontmatter version"

  [ "$skill_version" = "$version" ] || fail "${file#$ROOT_DIR/} has version $skill_version, expected $version"
done

printf 'PASS: skill versions match VERSION (%s)\n' "$version"
