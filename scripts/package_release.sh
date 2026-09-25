#!/bin/bash
# Builds a universal (Apple Silicon + Intel) Release of Abrar and packages it as a DMG.
# Usage: scripts/package_release.sh <version> [build-number]
# Output: build/release/Abrar-<version>.dmg and its .sha256
set -euo pipefail

VERSION=${1:?usage: package_release.sh <version> [build-number]}
BUILD=${2:-1}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DERIVED="$ROOT/build/ReleaseData"
OUT="$ROOT/build/release"
APP="$DERIVED/Build/Products/Release/Abrar.app"
DMG="$OUT/Abrar-$VERSION.dmg"

cd "$ROOT"
"$ROOT/scripts/generate_project.sh"
xcodebuild -project Abrar.xcodeproj -scheme Abrar -configuration Release \
    -derivedDataPath "$DERIVED" -disableAutomaticPackageResolution \
    ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
    MARKETING_VERSION="$VERSION" CURRENT_PROJECT_VERSION="$BUILD" \
    CODE_SIGN_IDENTITY=- \
    clean build | grep -E "error:|BUILD (SUCCEEDED|FAILED)"

codesign --verify --deep --strict "$APP"
echo "Architectures: $(lipo -archs "$APP/Contents/MacOS/Abrar")"

STAGING=$(mktemp -d)
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
mkdir -p "$OUT"
rm -f "$DMG"
hdiutil create -quiet -volname "Abrar $VERSION" -srcfolder "$STAGING" -format UDZO "$DMG"
rm -rf "$STAGING"

(cd "$OUT" && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
echo "Packaged $DMG ($(du -h "$DMG" | cut -f1))"
