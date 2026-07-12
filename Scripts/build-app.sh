#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-debug}"
APP_NAME="Taskbarra"
BUNDLE_ID="gg.dreki.taskbarra"
LOCAL_CODESIGN_IDENTITY="Taskbarra Local"
BUILD_DIR="$ROOT_DIR/.build/$CONFIGURATION"
APP_DIR="$ROOT_DIR/.build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

cd "$ROOT_DIR"

if [[ -n "${TASKBARRA_CODESIGN_IDENTITY:-}" ]]; then
  CODESIGN_IDENTITY="$TASKBARRA_CODESIGN_IDENTITY"
elif security find-identity -v -p codesigning 2>/dev/null | grep -F "\"$LOCAL_CODESIGN_IDENTITY\"" >/dev/null; then
  CODESIGN_IDENTITY="$LOCAL_CODESIGN_IDENTITY"
else
  CODESIGN_IDENTITY="-"
fi

swift build -c "$CONFIGURATION"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

if [[ -n "${VERSION:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS_DIR/Info.plist"
fi
if [[ -n "${BUILD_NUMBER:-}" ]]; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$CONTENTS_DIR/Info.plist"
fi

codesign --force --sign "$CODESIGN_IDENTITY" \
  --identifier "$BUNDLE_ID" \
  --entitlements "$ROOT_DIR/Resources/Taskbarra.entitlements" \
  "$APP_DIR" >/dev/null

DESIGNATED_REQUIREMENT="$(codesign -d --requirements - "$APP_DIR" 2>&1 | sed -n 's/^#* *designated => *//p')"

echo "Built $APP_DIR"
echo "Version: $(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$CONTENTS_DIR/Info.plist") ($(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$CONTENTS_DIR/Info.plist"))"
echo "Signed with identity: $CODESIGN_IDENTITY"
echo "Designated requirement: $DESIGNATED_REQUIREMENT"
if [[ "$CODESIGN_IDENTITY" == "-" ]]; then
  echo "Run ./Scripts/setup-local-codesign.sh once to preserve macOS permissions across rebuilds."
fi
