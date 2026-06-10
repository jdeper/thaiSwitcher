#!/bin/bash
set -e

APP_NAME="ThaiSwitcher"
BUILD_DIR="$(dirname "$0")/build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
INSTALL_DIR="/Applications"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "App not built yet. Run ./build.sh first."
    exit 1
fi

# Stop any running instance
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5

# Copy to /Applications
echo "Installing $APP_NAME to $INSTALL_DIR..."
cp -R "$APP_BUNDLE" "$INSTALL_DIR/"

# Remove quarantine flag (so macOS doesn't block it on first run)
xattr -cr "$INSTALL_DIR/$APP_NAME.app"

echo "✓ Installed to $INSTALL_DIR/$APP_NAME.app"
echo ""
echo "Launch the app:"
echo "  open /Applications/$APP_NAME.app"
echo ""
echo "On first launch:"
echo "  1. Click 'Open System Settings' when prompted"
echo "  2. Enable $APP_NAME under Privacy & Security → Accessibility"
echo "  3. Relaunch: open /Applications/$APP_NAME.app"
echo "  4. Click 'TS' in the menu bar → 'Launch at Login' to enable auto-start"
