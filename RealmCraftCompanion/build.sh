#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
DEFAULT_APP_ROOT="${TMPDIR:-/private/tmp}/realmcraft-companion-build-$(date +%Y%m%d-%H%M%S)-$$"
APP="${REALMCRAFT_APP_OUTPUT:-$DEFAULT_APP_ROOT/RealmCraft Companion.app}"
BUILD_DIR="${REALMCRAFT_BUILD_DIR:-$PWD/.build}"
BUILD_CACHE="${REALMCRAFT_MODULE_CACHE:-${TMPDIR:-/tmp}/realmcraft-swift-module-cache}"

python3 - "$APP" <<'OUTPUT_CHECK'
import sys
from pathlib import Path

requested = Path(sys.argv[1]).expanduser()
if not requested.is_absolute():
    requested = Path.cwd() / requested
destination = requested.parent.resolve(strict=False) / requested.name

if requested.is_symlink():
    raise SystemExit(f"Refusing symlink build destination: {requested}")
if destination.exists():
    raise SystemExit(f"Refusing existing build destination: {destination}\nChoose a fresh REALMCRAFT_APP_OUTPUT path.")
if destination == Path("/Applications") or Path("/Applications") in destination.parents:
    raise SystemExit(f"Refusing application installation destination: {destination}\nBuild a fresh bundle, then install it separately after verification.")
OUTPUT_CHECK

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$BUILD_DIR" "$BUILD_CACHE"
for ARCH in arm64 x86_64; do
    xcrun swiftc -swift-version 5 -target "$ARCH-apple-macos14.0" -O -whole-module-optimization -module-cache-path "$BUILD_CACHE" Sources/*.swift -o "$BUILD_DIR/RealmCraftLibrary-$ARCH" -framework SceneKit -framework SwiftUI -framework AppKit -framework CryptoKit -framework WebKit -framework AVFoundation -framework Speech
done
python3 make_localizations.py
cp -R Resources/. "$APP/Contents/Resources/"
python3 - "$APP/Contents/Resources" <<'CLEAN'
import sys, shutil
from pathlib import Path
for folder in Path(sys.argv[1]).rglob('__pycache__'):
    shutil.rmtree(folder)
CLEAN
python3 package_source.py "$APP/Contents/Resources/CommunitySource.zip"
lipo -create "$BUILD_DIR/RealmCraftLibrary-arm64" "$BUILD_DIR/RealmCraftLibrary-x86_64" -output "$APP/Contents/MacOS/RealmCraftLibrary"
xcrun swift -module-cache-path "$BUILD_CACHE" icon.swift "$BUILD_DIR/AppIcon.iconset"
python3 make_icon.py "$BUILD_DIR/AppIcon.iconset" "$APP/Contents/Resources/AppIcon.icns"
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
<key>CFBundleShortVersionString</key><string>1.7.54</string>
<key>CFBundleVersion</key><string>76</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSDocumentsFolderUsageDescription</key><string>RealmCraft-Spielstände in deiner lokalen Library sichern und importieren.</string>
<key>NSDownloadsFolderUsageDescription</key><string>Vorhandene RealmCraft-Backups zum Importieren finden.</string>
<key>NSMicrophoneUsageDescription</key><string>Deine Fragen an den Companion über das Mac-Mikrofon aufnehmen. Aufnahme startet nur im Gesprächsbereich.</string>
<key>NSSpeechRecognitionUsageDescription</key><string>Gesprochene Fragen lokal auf diesem Mac in Text umwandeln.</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
xattr -r -d com.apple.FinderInfo "$APP" 2>/dev/null || true
xattr -r -d com.apple.ResourceFork "$APP" 2>/dev/null || true
chmod 0755 "$APP/Contents/MacOS/RealmCraftLibrary"
codesign --force --sign - "$APP"
codesign --verify --deep "$APP"
echo "Built: $APP"
