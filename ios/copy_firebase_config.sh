#!/bin/bash

# Script to copy GoogleService-Info.plist to the app bundle
# This bypasses the need to modify the Xcode project file

echo "Copying GoogleService-Info.plist to app bundle..."

# Get the build directory from environment variables
BUILT_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR}"
CONTENTS_FOLDER_PATH="${CONTENTS_FOLDER_PATH}"

if [ -z "$BUILT_PRODUCTS_DIR" ] || [ -z "$CONTENTS_FOLDER_PATH" ]; then
    echo "Error: Build environment variables not set"
    exit 1
fi

# Source file
SOURCE_FILE="Runner/GoogleService-Info.plist"

# Destination directory
DEST_DIR="${BUILT_PRODUCTS_DIR}/${CONTENTS_FOLDER_PATH}"

# Check if source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: GoogleService-Info.plist not found at $SOURCE_FILE"
    exit 1
fi

# Create destination directory if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy the file
cp "$SOURCE_FILE" "$DEST_DIR/"

if [ $? -eq 0 ]; then
    echo "✅ GoogleService-Info.plist copied successfully to $DEST_DIR"
else
    echo "❌ Failed to copy GoogleService-Info.plist"
    exit 1
fi
