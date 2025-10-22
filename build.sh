#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PROJECT="RoxyDependencies.xcodeproj"
SCHEME="RoxyDependencies"
BUILD_DIR="./build"
XCFRAMEWORK_NAME="RoxyDependencies.xcframework"
CONFIGURATION="Release"
IDENTITY="iPhone Distribution: Obss Bilisim Bilgisayar Hizmetleri Danismanlik Sanayi Ve Ticaret Limited Sirketi"

DEVICE_ARCHIVE="$BUILD_DIR/$SCHEME-iOS.xcarchive"
SIMULATOR_ARCHIVE="$BUILD_DIR/$SCHEME-iOS-Simulator.xcarchive"

# Clean previous build
rm -rf "$BUILD_DIR"

echo "📦 Archiving for iOS devices..."
xcodebuild clean -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" -destination "generic/platform=iOS"
xcodebuild clean -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIGURATION" -destination "generic/platform=iOS Simulator"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS" \
  -archivePath "$DEVICE_ARCHIVE" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=NO \
  OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"

echo "📦 Archiving for iOS Simulator..."
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -destination "generic/platform=iOS Simulator" \
  -archivePath "$SIMULATOR_ARCHIVE" \
  SKIP_INSTALL=NO \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=NO \
  OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"

echo "🔗 Creating XCFramework..."
xcodebuild -create-xcframework \
  -framework "$DEVICE_ARCHIVE/Products/Library/Frameworks/$SCHEME.framework" \
  -framework "$SIMULATOR_ARCHIVE/Products/Library/Frameworks/$SCHEME.framework" \
  -output "$BUILD_DIR/$XCFRAMEWORK_NAME"

echo "Signing the ${XCFRAMEWORK_NAME}" for distribution
codesign --timestamp -v --sign "${IDENTITY}" "$BUILD_DIR/$XCFRAMEWORK_NAME"

echo "✅ Done. Output: $BUILD_DIR/$XCFRAMEWORK_NAME"