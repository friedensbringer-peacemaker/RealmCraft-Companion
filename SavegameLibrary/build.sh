#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
APP="${REALMCRAFT_APP_OUTPUT:-$PWD/../RealmCraft Companion.app}"
BUILD_CACHE="${TMPDIR:-/tmp}/realmcraft-swift-module-cache"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" .build "$BUILD_CACHE"
for ARCH in arm64 x86_64; do
    xcrun swiftc -swift-version 5 -target "$ARCH-apple-macos14.0" -O -whole-module-optimization -module-cache-path "$BUILD_CACHE" Sources/Library.swift Sources/Setup.swift Sources/SetupView.swift Sources/HelpView.swift Sources/Localization.swift Sources/WindowFramePersistence.swift Sources/CompanionView.swift Sources/ResourcesView.swift Sources/MapsView.swift Sources/MapLocalization.swift Sources/ChestsView.swift Sources/main.swift -o ".build/RealmCraftLibrary-$ARCH" -framework SwiftUI -framework AppKit -framework CryptoKit -framework WebKit
done
python3 make_localizations.py
cp -R Resources/. "$APP/Contents/Resources/"
python3 package_source.py "$APP/Contents/Resources/CommunitySource.zip"
lipo -create .build/RealmCraftLibrary-arm64 .build/RealmCraftLibrary-x86_64 -output "$APP/Contents/MacOS/RealmCraftLibrary"
xcrun swift -module-cache-path "$BUILD_CACHE" icon.swift .build/AppIcon.iconset
python3 make_icon.py .build/AppIcon.iconset "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>RealmCraft Companion</string>
<key>CFBundleDisplayName</key><string>RealmCraft Companion</string>
<key>CFBundleIdentifier</key><string>at.local.realmcraft.savegames</string>
<key>CFBundleExecutable</key><string>RealmCraftLibrary</string>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>CFBundleLocalizations</key><array><string>de</string><string>en</string></array>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.1.0</string>
<key>CFBundleVersion</key><string>5</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSDocumentsFolderUsageDescription</key><string>RealmCraft-Spielstände in deiner lokalen Library sichern und importieren.</string>
<key>NSDownloadsFolderUsageDescription</key><string>Vorhandene RealmCraft-Backups zum Importieren finden.</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
xattr -d com.apple.FinderInfo "$APP" 2>/dev/null || true
codesign --force --sign - "$APP"
echo "Built: $APP"
