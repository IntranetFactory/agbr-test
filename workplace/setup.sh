#!/bin/bash

# Current script version
VERSION="002"

# Setup workplace script
# This script configures the environment and dependencies after checkout

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to send messages (wrapper around message.sh)
send_message() {
    local message="$1"
    "$SCRIPT_DIR/message.sh" "$message" 2>/dev/null || true
}

# Error handler function
error_handler() {
    local exit_code=$?
    local line_number=$1
    local error_message="workplace setup failed at line $line_number with exit code $exit_code"
    echo "$error_message"
    send_message "$error_message"
    exit $exit_code
}

# Set up error trap
trap 'error_handler ${LINENO}' ERR
set -e


# Path to the version file
VERSION_FILE=".workplace-version"

# Send start message with environment variables
echo "Starting workplace setup..."
echo "SECRET: ${SECRET:+[set]}"
echo "VARIABLE: ${VARIABLE:-not set}"
send_message "workplace setup started - SECRET: ${SECRET:+[set]}, VARIABLE: ${VARIABLE:-not set}"

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
    send_message "workplace setup finished - version $VERSION"
    exit 0
fi

echo "Updating workplace from $CURRENT_VERSION to $VERSION..."

# Install global dependencies
echo "Installing agent-browser globally..."
npm install -g agent-browser

echo "Installing dotenvx globally..."
npm install -g @dotenvx/dotenvx

echo "Installing cloudflare wrangler globally..."
npm install -g wrangler

echo "Installing Playwright browsers..."
npx --yes playwright install --with-deps chromium

echo "Installing project dependencies with pnpm..."
pnpm install --frozen-lockfile

# Save the new version
echo "$VERSION" > "$VERSION_FILE"
echo "Workplace updated to version $VERSION"

# Send success message
send_message "workplace setup finished - version $VERSION"
