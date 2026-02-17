#!/bin/bash

# Setup workplace script
# This script configures the environment and dependencies after checkout

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Error handler function
error_handler() {
    local exit_code=$?
    local line_number=$1
    local error_message="workplace setup failed at line $line_number with exit code $exit_code"
    echo "$error_message"
    "$SCRIPT_DIR/message.sh" "$error_message" 2>/dev/null || true
    exit $exit_code
}

# Set up error trap
trap 'error_handler ${LINENO}' ERR
set -e

# Current script version
VERSION="001"

# Path to the version file
VERSION_FILE=".workplace-version"

# Read current workplace version, default to 000 if not exists
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE")
else
    CURRENT_VERSION="000"
fi

echo "Current workplace version: $CURRENT_VERSION"
echo "Script version: $VERSION"

# Stop if workplace version is >= script version
if [ "$CURRENT_VERSION" -ge "$VERSION" ]; then
    echo "Workplace is up to date (version $CURRENT_VERSION). Skipping setup."
    "$SCRIPT_DIR/message.sh" "workplace setup finished" 2>/dev/null || true
    exit 0
fi

echo "Updating workplace from $CURRENT_VERSION to $VERSION..."

# Install global dependencies
echo "Installing agent-browser globally..."
npm install -g agent-browser

echo "Installing agent-browser dependencies..."
# agent-browser install --with-deps
npx --yes playwright install --with-deps chromium

echo "Installing project dependencies with pnpm..."
pnpm install --frozen-lockfile

# Verify Husky hooks are configured
echo "Verifying Git hooks configuration..."
HOOKS_PATH=$(git config core.hooksPath || echo "")
if [ "$HOOKS_PATH" != ".husky/_" ]; then
    echo "WARNING: Git hooks not configured properly. Expected core.hooksPath=.husky/_"
    echo "Attempting to fix by running pnpm prepare..."
    pnpm prepare
    HOOKS_PATH=$(git config core.hooksPath || echo "")
    if [ "$HOOKS_PATH" = ".husky/_" ]; then
        echo "✓ Git hooks configured successfully"
    else
        echo "ERROR: Could not configure Git hooks"
        exit 1
    fi
else
    echo "✓ Git hooks already configured"
fi

# Save the new version
echo "$VERSION" > "$VERSION_FILE"
echo "Workplace updated to version $VERSION"

# Send success message
"$SCRIPT_DIR/message.sh" "workplace setup finished" 2>/dev/null || true
