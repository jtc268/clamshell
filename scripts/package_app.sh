#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Clamshell"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
EXECUTABLE="$ROOT/.build/release/$APP_NAME"
HELPER="$DIST/clamshell-helper"

cd "$ROOT"
swift build -c release >&2
mkdir -p "$DIST"
clang -O2 -Wall -Wextra "$ROOT/helper/clamshell-helper.c" -o "$HELPER" >&2

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$EXECUTABLE" "$APP/Contents/MacOS/$APP_NAME"
cp "$HELPER" "$APP/Contents/Resources/clamshell-helper"
cp "$ROOT/packaging/Info.plist" "$APP/Contents/Info.plist"

if [[ -f "$ROOT/assets/AppIcon.icns" ]]; then
  cp "$ROOT/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

codesign --force --deep --sign - "$APP" >/dev/null

echo "$APP"
