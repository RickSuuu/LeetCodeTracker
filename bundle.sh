#!/bin/bash
# Build and bundle LeetCodeTracker as a macOS .app

set -e

echo "🔨 Building..."
swift build -c release

APP_NAME="LeetCodeTracker"
APP_DIR="${APP_NAME}.app"
CONTENTS="${APP_DIR}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

rm -rf "${APP_DIR}"
mkdir -p "${MACOS}" "${RESOURCES}"

cp ".build/release/${APP_NAME}" "${MACOS}/${APP_NAME}"

# Copy icon
if [ -f "AppIcon.icns" ]; then
    cp "AppIcon.icns" "${RESOURCES}/AppIcon.icns"
    echo "📎 Icon copied"
fi

cat > "${CONTENTS}/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>LeetCodeTracker</string>
    <key>CFBundleDisplayName</key>
    <string>LeetCode 热题 100</string>
    <key>CFBundleIdentifier</key>
    <string>com.leetcode.tracker</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>LeetCodeTracker</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
</dict>
</plist>
EOF

echo ""
echo "✅ ${APP_DIR} 打包完成！"
echo "📍 位置: $(pwd)/${APP_DIR}"
echo ""
echo "运行: open ${APP_DIR}"
