#!/bin/bash
# Builds CustomCalendarURL.app with its Calendar extension embedded.
# Usage: Scripts/build.sh [debug|release] [swift build flags…]
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-release}"
shift || true
APP="build/CustomCalendarURL.app"
APPEX="$APP/Contents/PlugIns/CustomCalendarURLExtension.appex"

swift build -c "$CONFIG" "$@"
BIN="$(swift build -c "$CONFIG" --show-bin-path)"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APPEX/Contents/MacOS"
cp "$BIN/CustomCalendarURL" "$APP/Contents/MacOS/CustomCalendarURL"
cp Resources/Info.plist "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
# Compiles the Icon Composer file into Assets.car, plus an .icns for macOS
# before 26. Info.plist names both via CFBundleIconName and CFBundleIconFile.
mkdir -p "$APP/Contents/Resources"
xcrun actool Resources/CalendarCustomURL.icon \
    --compile "$APP/Contents/Resources" \
    --app-icon CalendarCustomURL --include-all-app-icons \
    --platform macosx --target-device mac --minimum-deployment-target 14.0 \
    --output-partial-info-plist build/icon-partial.plist \
    --warnings --errors --output-format human-readable-text
cp "$BIN/CustomCalendarURLExtension" "$APPEX/Contents/MacOS/CustomCalendarURLExtension"
cp Resources/Extension/Info.plist "$APPEX/Contents/Info.plist"

# Ad-hoc signatures: enough for local use. The extension is signed first, with
# its sandbox entitlements, since signing the app seals what is inside it.
# Replace "-" with a real identity to distribute.
codesign --force --sign - --timestamp=none \
    --entitlements Resources/Extension/Extension.entitlements "$APPEX"
codesign --force --sign - --timestamp=none "$APP"

echo "Built $APP"
