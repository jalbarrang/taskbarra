#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Taskbarra"
VERSION="${VERSION:?Set VERSION to the release version, for example VERSION=1.2.3}"
APP_DIR="$ROOT_DIR/.build/$APP_NAME.app"
STAGING_DIR="$ROOT_DIR/.build/dmg-staging"
DMG_PATH="$ROOT_DIR/.build/$APP_NAME-$VERSION.dmg"

if [[ ! -d "$APP_DIR" ]]; then
  echo "App bundle not found at $APP_DIR. Run Scripts/build-app.sh first." >&2
  exit 1
fi

rm -rf "$STAGING_DIR"
trap 'rm -rf "$STAGING_DIR"' EXIT
mkdir -p "$STAGING_DIR"

ditto "$APP_DIR" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Created $DMG_PATH"
shasum -a 256 "$DMG_PATH"
