#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if command -v swift-format >/dev/null 2>&1; then
  echo "==> swift-format lint"
  swift-format lint --recursive Sources Tests Package.swift
else
  echo "==> swift-format not installed; skipping format lint"
  echo "    Install with: brew install swift-format"
fi

if command -v swiftlint >/dev/null 2>&1; then
  echo "==> swiftlint"
  swiftlint lint --strict
else
  echo "==> swiftlint not installed; skipping SwiftLint"
  echo "    Install with: brew install swiftlint"
fi

echo "==> core tests"
swift run TaskbarraCoreTests

echo "==> build app bundle"
./Scripts/build-app.sh

echo "==> all checks passed"
