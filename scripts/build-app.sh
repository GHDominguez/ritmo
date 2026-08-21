#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h:h}"
APP_DIR="$PROJECT_DIR/dist/Ritmo.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
BUILD_DIR="$PROJECT_DIR/.build-native"
APP_VERSION="${RITMO_VERSION:-1.0.0}"
BUILD_NUMBER="${RITMO_BUILD_NUMBER:-1}"

cd "$PROJECT_DIR"
mkdir -p "$BUILD_DIR"
clang \
    -fobjc-arc \
    -fmodules \
    -fmodules-cache-path="$BUILD_DIR/ModuleCache" \
    -fblocks \
    -O2 \
    -arch arm64 \
    -arch x86_64 \
    -mmacosx-version-min=14.0 \
    -I "$PROJECT_DIR/Native" \
    "$PROJECT_DIR"/Native/RitmoCore.m \
    "$PROJECT_DIR"/Native/RitmoModel.m \
    "$PROJECT_DIR"/Native/RitmoUI.m \
    "$PROJECT_DIR"/Native/main.m \
    -framework Cocoa \
    -framework QuartzCore \
    -o "$BUILD_DIR/Ritmo"

mkdir -p "$MACOS_DIR"
cp "$BUILD_DIR/Ritmo" "$MACOS_DIR/Ritmo"

mkdir -p "$CONTENTS_DIR"
cp "$PROJECT_DIR/support/Info.plist" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleShortVersionString -string "$APP_VERSION" "$CONTENTS_DIR/Info.plist"
plutil -replace CFBundleVersion -string "$BUILD_NUMBER" "$CONTENTS_DIR/Info.plist"

codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
