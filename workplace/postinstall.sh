#!/bin/bash

# Post-install hook
# This runs automatically after pnpm install to complete workspace setup
# This is called by the "postinstall" script in package.json

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Stop if workplace version is >= script version
if [ "$CURRENT_VERSION" -ge "$VERSION" ]; then
    echo "✓ Workplace is up to date (version $CURRENT_VERSION)"
    exit 0
fi

echo "📦 Setting up workspace (version $CURRENT_VERSION → $VERSION)..."

# Install global dependencies if not already installed
if ! command -v agent-browser &> /dev/null; then
    echo "Installing agent-browser globally..."
    npm install -g agent-browser
else
    echo "✓ agent-browser already installed"
fi

# Install Playwright browsers if not already installed
PLAYWRIGHT_CACHE="$HOME/.cache/ms-playwright"
if [ ! -d "$PLAYWRIGHT_CACHE" ] || ! find "$PLAYWRIGHT_CACHE" -maxdepth 1 -type d -name "chromium*" | grep -q .; then
    echo "Installing Playwright browsers..."
    npx --yes playwright install --with-deps chromium
else
    echo "✓ Playwright browsers already installed"
fi

# Verify Husky hooks are configured
echo "Verifying Git hooks configuration..."
EXPECTED_HOOKS_PATH=".husky/_"
HOOKS_PATH=$(git config core.hooksPath || echo "")
if [ "$HOOKS_PATH" != "$EXPECTED_HOOKS_PATH" ]; then
    echo "WARNING: Git hooks not configured properly. Expected core.hooksPath=$EXPECTED_HOOKS_PATH"
    echo "This should have been set by the 'prepare' script. Something went wrong."
    exit 1
else
    echo "✓ Git hooks configured"
fi

# Save the new version
echo "$VERSION" > "$VERSION_FILE"
echo "✓ Workplace setup complete (version $VERSION)"

# Send success message
"$SCRIPT_DIR/message.sh" "workplace setup finished" 2>/dev/null || true
