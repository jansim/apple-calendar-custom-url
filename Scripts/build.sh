#!/bin/bash
# Builds CustomURL.app with its Calendar extension embedded.
# Usage: Scripts/build.sh [debug|release] [swift build flags…]
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
shift || true
APP="build/CustomURL.app"
APPEX="$APP/Contents/PlugIns/CustomURLExtension.appex"

swift build -c "$CONFIG" "$@"
BIN="$(swift build -c "$CONFIG" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APPEX/Contents/MacOS"
cp "$BIN/CustomURL" "$APP/Contents/MacOS/CustomURL"
cp Resources/Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
cp "$BIN/CustomURLExtension" "$APPEX/Contents/MacOS/CustomURLExtension"
cp Resources/Extension/Info.plist "$APPEX/Contents/Info.plist"

# Ad-hoc signatures: enough for local use. The extension is signed first, with
# its sandbox entitlements, since signing the app seals what is inside it.
# Replace "-" with a real identity to distribute.
codesign --force --sign - --timestamp=none \
    --entitlements Resources/Extension/Extension.entitlements "$APPEX"
codesign --force --sign - --timestamp=none "$APP"

echo "Built $APP"
