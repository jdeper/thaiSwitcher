#!/bin/bash
set -e

APP_NAME="ThaiSwitcher"
BUNDLE_ID="com.thaiswitcher.app"
SOURCES_DIR="$(dirname "$0")/Sources"
RESOURCES_DIR="$(dirname "$0")/Resources"
BUILD_DIR="$(dirname "$0")/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "Building $APP_NAME..."

# Clean
rm -rf "$BUILD_DIR"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Compile
swiftc \
    "$SOURCES_DIR/ThaiConverter.swift" \
    "$SOURCES_DIR/InputSourceManager.swift" \
    "$SOURCES_DIR/LaunchAtLoginManager.swift" \
    "$SOURCES_DIR/KeyboardMonitor.swift" \
    "$SOURCES_DIR/AppDelegate.swift" \
    "$SOURCES_DIR/main.swift" \
    -framework Cocoa \
    -framework Carbon \
    -framework ServiceManagement \
    -target arm64-apple-macos12.0 \
    -O \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy Info.plist
cp "$RESOURCES_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "✓ Built: $APP_BUNDLE"
echo ""
echo "To install: run ./install.sh"
