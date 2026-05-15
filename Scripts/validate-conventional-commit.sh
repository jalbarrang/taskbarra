#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <commit-message-file>" >&2
  exit 2
fi

message_file="$1"
subject="$(grep -v '^#' "$message_file" | sed '/^[[:space:]]*$/d' | head -n 1)"

if [[ -z "$subject" ]]; then
  echo "error: commit message subject is empty" >&2
  exit 1
fi

# Git-generated messages that should remain valid without rewriting.
case "$subject" in
  Merge\ *|Revert\ *|fixup\!*|squash\!*)
    exit 0
    ;;
esac

conventional_regex='^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-zA-Z0-9._/-]+\))?(!)?: .{1,}$'

if [[ "$subject" =~ $conventional_regex ]]; then
  exit 0
fi

cat >&2 <<'EOF'
error: commit message must follow Conventional Commits.

Expected format:
  <type>[optional scope]: <description>
  <type>[optional scope]!: <description>

Allowed types:
  build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test

Examples:
  feat(taskbar): render app icons
  fix(ax): refresh windows after Space changes
  docs: document local build flow
  chore!: drop macOS 13 support
EOF

exit 1
