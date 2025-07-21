#!/bin/bash

# Constants
SCRIPT_NAME="oswp"
SOURCE_SCRIPT="${SCRIPT_NAME}.sh"
DEST_DIR="/usr/local/bin"
TARGET_PATH="${DEST_DIR}/${SCRIPT_NAME}"

# Check if source file exists
if [[ ! -f "$SOURCE_SCRIPT" ]]; then
  echo "[ERROR] Source script '${SOURCE_SCRIPT}' not found in current directory."
  exit 1
fi

# Make executable
chmod +x "$SOURCE_SCRIPT"

# Install or update logic
if [[ -f "$TARGET_PATH" ]]; then
  echo "[INFO] Updating existing '${SCRIPT_NAME}' script..."
else
  echo "[INFO] Installing '${SCRIPT_NAME}' script..."
fi

# Move script to destination
mv -f "$SOURCE_SCRIPT" "$TARGET_PATH"

# Verify installation
if [[ -x "$TARGET_PATH" ]]; then
  echo "[OK] '${SCRIPT_NAME}' is now installed at: $TARGET_PATH"
else
  echo "[ERROR] Failed to install '${SCRIPT_NAME}'."
  exit 1
fi

# Clean up the parent folder if this script was run from inside a git clone/folder
INSTALLER_DIR="$(pwd)"
cd ..
if [[ -d "$INSTALLER_DIR" ]]; then
  rm -rf "$INSTALLER_DIR"
  echo "[INFO] Cleaned up installer directory: $INSTALLER_DIR"
fi

exit 0
