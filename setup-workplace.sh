#!/bin/bash

# Setup workplace script
# This script configures the environment and dependencies after checkout

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
    exit 0
fi

echo "Updating workplace from $CURRENT_VERSION to $VERSION..."

# Install global dependencies
echo "Installing agent-browser globally..."
if ! npm install -g agent-browser; then
    echo "Error: Failed to install agent-browser globally"
    exit 1
fi

echo "Installing agent-browser dependencies..."
# agent-browser install --with-deps
if ! npx --yes playwright install-deps chromium; then
    echo "Error: Failed to install agent-browser dependencies"
    exit 1
fi

echo "Installing project dependencies with pnpm..."
if ! pnpm install --frozen-lockfile; then
    echo "Error: Failed to install project dependencies"
    exit 1
fi

# Save the new version
echo "$VERSION" > "$VERSION_FILE"
echo "Workplace updated to version $VERSION"
