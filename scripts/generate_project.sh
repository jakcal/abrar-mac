#!/bin/bash
# Generates Abrar.xcodeproj and installs the committed Package.resolved so builds use pinned dependency versions.
# After updating packages in Xcode, copy the new resolved file back to the repo root and commit it:
#   cp Abrar.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved Package.resolved
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SWIFTPM="$ROOT/Abrar.xcodeproj/project.xcworkspace/xcshareddata/swiftpm"

cd "$ROOT"
xcodegen -q
mkdir -p "$SWIFTPM"
cp "$ROOT/Package.resolved" "$SWIFTPM/Package.resolved"
