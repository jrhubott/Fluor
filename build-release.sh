#!/bin/bash
set -euo pipefail

SCHEME="Fluor"
CONFIG="Release"
APP_NAME="Fluor.app"
DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

echo "Building $SCHEME ($CONFIG)..."
export DEVELOPER_DIR
BUILD_OUTPUT=$(xcodebuild -scheme "$SCHEME" -configuration "$CONFIG" build 2>&1)

# Extract the built products directory from build settings
BUILT_PRODUCTS_DIR=$(xcodebuild -scheme "$SCHEME" -configuration "$CONFIG" -showBuildSettings 2>/dev/null \
    | awk -F= '/BUILT_PRODUCTS_DIR/ { gsub(/^[ \t]+/, "", $2); print $2; exit }')

APP_PATH="$BUILT_PRODUCTS_DIR/$APP_NAME"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: Build product not found at $APP_PATH"
    exit 1
fi

echo "Build succeeded."
echo "Copying $APP_NAME to /Applications..."

# Remove existing version if present
if [ -d "/Applications/$APP_NAME" ]; then
    rm -rf "/Applications/$APP_NAME"
fi

cp -R "$APP_PATH" "/Applications/$APP_NAME"

echo "Installed /Applications/$APP_NAME"
