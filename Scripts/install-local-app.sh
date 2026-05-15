#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Taskbarra"
SOURCE_APP="$ROOT_DIR/.build/$APP_NAME.app"
INSTALL_DIR="${TASKBARRA_INSTALL_DIR:-/Applications}"
TARGET_APP="$INSTALL_DIR/$APP_NAME.app"

"$ROOT_DIR/Scripts/build-app.sh"

mkdir -p "$INSTALL_DIR"
rm -rf "$TARGET_APP"
cp -R "$SOURCE_APP" "$TARGET_APP"

# TCC/Accessibility permissions are tied to the app identity. Launching from a stable
# location avoids accumulating entries for throwaway build paths during local testing.
echo "Installed $TARGET_APP"
echo "Open it with: open '$TARGET_APP'"
