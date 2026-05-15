#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_tool() {
  local tool="$1"
  local install_hint="$2"

  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: required tool '$tool' is not installed or not in PATH" >&2
    echo "       $install_hint" >&2
    exit 127
  fi
}

swift_format() {
  if command -v swift-format >/dev/null 2>&1; then
    swift-format "$@"
  else
    xcrun swift-format "$@"
  fi
}

require_tool swiftlint "Install with: brew install swiftlint"
require_tool semgrep "Install with: brew install semgrep"
if ! command -v swift-format >/dev/null 2>&1 && ! xcrun --find swift-format >/dev/null 2>&1; then
  echo "error: required tool 'swift-format' is not installed or not available through xcrun" >&2
  echo "       Install with: brew install swift-format, or install/select Xcode" >&2
  exit 127
fi

echo "==> swift-format lint"
swift_format lint --recursive Sources Tests Package.swift

echo "==> swiftlint"
swiftlint lint --strict

echo "==> semgrep"
semgrep scan --config .semgrep --error --quiet

echo "==> core tests"
swift run TaskbarraCoreTests

echo "==> build app bundle"
./Scripts/build-app.sh

echo "==> all checks passed"
