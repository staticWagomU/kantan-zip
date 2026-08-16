#!/usr/bin/env bash
# SPMのreleaseビルドを KantanZip.app に包む。
# 配布時はこの後 codesign + notarytool が必要（plan.md「配布手順」参照）。
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release

APP=build/KantanZip.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/KantanZipApp "$APP/Contents/MacOS/KantanZip"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>KantanZip</string>
    <key>CFBundleIdentifier</key>
    <string>com.staticwagomu.kantanzip</string>
    <key>CFBundleName</key>
    <string>KantanZip</string>
    <key>CFBundleDisplayName</key>
    <string>KantanZip</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDevelopmentRegion</key>
    <string>ja</string>
</dict>
</plist>
PLIST

echo "作成しました: $APP"
