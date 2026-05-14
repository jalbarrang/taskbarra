#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-debug}"
APP_NAME="Taskbarra"
BUNDLE_ID="gg.dreki.taskbarra"
BUILD_DIR="$ROOT_DIR/.build/$CONFIGURATION"
APP_DIR="$ROOT_DIR/.build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

swift build -c "$CONFIGURATION"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Ad-hoc signing keeps Gatekeeper and Accessibility identity stable enough for local development.
# Distribution signing/notarization will be handled in a later release task.
codesign --force --sign - \
  --identifier "$BUNDLE_ID" \
  --entitlements "$ROOT_DIR/Resources/Taskbarra.entitlements" \
  "$APP_DIR" >/dev/null

echo "Built $APP_DIR"
