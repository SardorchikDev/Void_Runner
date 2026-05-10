#!/bin/bash
# Build Void Runner for Windows - creates a standalone .exe

set -e

GAME_NAME="VoidRunner"
LOVE_VERSION="11.5"
BUILD_DIR="/home/sardor/Return-by-death/build"
GAME_DIR="/home/sardor/Return-by-death/game"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "=== Building ${GAME_NAME}.love ==="
cd "$GAME_DIR"
rm -f "$BUILD_DIR/${GAME_NAME}.love"
zip -9 -r "$BUILD_DIR/${GAME_NAME}.love" . -x "*.git*"

echo "=== Downloading LÖVE for Windows ==="
cd "$BUILD_DIR"
if [ ! -d "love-${LOVE_VERSION}-win64" ]; then
    if [ ! -f "love-${LOVE_VERSION}-win64.zip" ]; then
        echo "Downloading love-${LOVE_VERSION}-win64.zip..."
        wget -q "https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-win64.zip"
    fi
    echo "Extracting..."
    unzip -q -o "love-${LOVE_VERSION}-win64.zip"
fi

echo "=== Creating standalone .exe ==="
cd "love-${LOVE_VERSION}-win64"
cat love.exe "$BUILD_DIR/${GAME_NAME}.love" > "$BUILD_DIR/${GAME_NAME}.exe"

echo "=== Packaging final zip ==="
cd "$BUILD_DIR"
rm -f "${GAME_NAME}-Windows.zip"

# Create a clean folder with just the game files
mkdir -p "${GAME_NAME}-Windows"
cp "${GAME_NAME}.exe" "${GAME_NAME}-Windows/"
cp love-${LOVE_VERSION}-win64/*.dll "${GAME_NAME}-Windows/"
cp love-${LOVE_VERSION}-win64/license.txt "${GAME_NAME}-Windows/" 2>/dev/null || true

# Zip it up
zip -9 -r "${GAME_NAME}-Windows.zip" "${GAME_NAME}-Windows"

echo ""
echo "=== DONE! ==="
echo "Standalone exe: $BUILD_DIR/${GAME_NAME}.exe"
echo "Distribution zip: $BUILD_DIR/${GAME_NAME}-Windows.zip"
echo ""
echo "To distribute: Send the zip file. Users unzip and double-click ${GAME_NAME}.exe"
