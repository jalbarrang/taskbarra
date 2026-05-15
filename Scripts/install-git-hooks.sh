#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

git config core.hooksPath .githooks
chmod +x .githooks/commit-msg Scripts/validate-conventional-commit.sh

echo "Configured git hooks path: .githooks"
echo "Conventional Commits validation is now enforced by commit-msg."
