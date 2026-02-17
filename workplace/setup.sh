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
VERSION="002"

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

echo "Installing project dependencies with pnpm..."
pnpm install --frozen-lockfile

# Install Playwright browsers using the locally installed playwright-core version.
# This ensures the correct Chromium revision matching agent-browser's playwright-core
# dependency, rather than whatever global playwright version happens to be installed.
echo "Installing Playwright browsers for agent-browser..."
PLAYWRIGHT_CLI=$(find node_modules/.pnpm -maxdepth 4 -name "cli.js" -path "*/playwright-core/cli.js" 2>/dev/null | head -1)
if [ -n "$PLAYWRIGHT_CLI" ]; then
    echo "Using playwright-core CLI at: $PLAYWRIGHT_CLI"
    node "$PLAYWRIGHT_CLI" install --with-deps chromium
else
    echo "playwright-core not found in local node_modules, falling back to global playwright..."
    npx --yes playwright install --with-deps chromium
fi

# Save the new version
echo "$VERSION" > "$VERSION_FILE"
echo "Workplace updated to version $VERSION"

# Send success message
"$SCRIPT_DIR/message.sh" "workplace setup finished" 2>/dev/null || true