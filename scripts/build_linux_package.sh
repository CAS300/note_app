#!/bin/bash
# Helper script to build the PKGBUILD for Arch/CachyOS

set -e

echo "========================================="
echo "   Note App Linux PKGBUILD Build Script  "
echo "========================================="

# Ensure we are in the project root
if [ ! -d "packaging/linux" ]; then
  echo "Error: Run this script from the project root."
  exit 1
fi

echo "Step 1: Copying project files for local makepkg..."
# Create a temporary build directory
BUILD_DIR="/tmp/note-app-build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy the whole project (excluding build and hidden folders) to the build directory
rsync -av --exclude='.git' --exclude='build' --exclude='.dart_tool' ./ "$BUILD_DIR/"

echo "Step 2: Running makepkg..."
cd "$BUILD_DIR/packaging/linux"
# Update PKGBUILD to point source to the synced folder
sed -i 's|source=("local://../../")|source=("local://../")|g' PKGBUILD

makepkg -sfc

echo "Step 3: Copying output artifacts..."
cd - > /dev/null
cp "$BUILD_DIR"/packaging/linux/*.pkg.tar.zst ./build/ || echo "No .pkg.tar.zst found or build directory not created. Package was successfully built but not moved. Check $BUILD_DIR/packaging/linux/"

echo "========================================="
echo "Build Complete!"
echo "Check the /build folder for the generated .pkg.tar.zst file (if moved successfully)"
echo "To install, run: sudo pacman -U build/note-app*.pkg.tar.zst"
echo "========================================="
