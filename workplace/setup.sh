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
    "$SCRIPT_DIR/message.sh" "$error_message" 2>/dev/null || true
    exit $exit_code
}

# Set up error trap
trap 'error_handler ${LINENO}' ERR
set -e

# Current script version
VERSION="004"

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
    "$SCRIPT_DIR/message.sh" "workplace setup finished" 2>/dev/null || true
    exit 0
fi

"$SCRIPT_DIR/message.sh" "Updating workplace from $CURRENT_VERSION to $VERSION..." 2>/dev/null || true

# Install global dependencies
npm install -g agent-browser

# Install project dependencies
pnpm install --frozen-lockfile

# Install Playwright browsers for agent-browser.
# Strategy: determine the revision required by the installed agent-browser, wipe any existing
# (potentially broken/outdated) installation for that revision, then do a clean install
# with --with-deps so OS-level shared libraries are also installed.

BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"

# Find the playwright-core CLI bundled with the locally installed agent-browser
PLAYWRIGHT_CLI=$(find node_modules/.pnpm -maxdepth 4 -name "cli.js" -path "*/playwright-core/cli.js" 2>/dev/null | head -1)
if [ -z "$PLAYWRIGHT_CLI" ]; then
    # Fall back to global agent-browser's playwright-core
    PLAYWRIGHT_CLI=$(find /opt/node*/lib/node_modules/agent-browser/node_modules/playwright-core -name "cli.js" 2>/dev/null | head -1)
fi

# Determine the revision required by this playwright-core
REQUIRED_REVISION=""
if [ -n "$PLAYWRIGHT_CLI" ]; then
    BROWSERS_JSON="$(dirname "$PLAYWRIGHT_CLI")/../../browsers.json"
    if [ -f "$BROWSERS_JSON" ] && command -v python3 &>/dev/null; then
        REQUIRED_REVISION=$(python3 - "$BROWSERS_JSON" <<'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
for b in data.get('browsers', []):
    if b.get('name') == 'chromium-headless-shell':
        print(b.get('revision', ''))
        break
PYEOF
)
    fi
fi

# Wipe any existing installation for the required revision so we start clean
if [ -n "$REQUIRED_REVISION" ]; then
    REQUIRED_DIR="$BROWSERS_PATH/chromium_headless_shell-$REQUIRED_REVISION"
    if [ -d "$REQUIRED_DIR" ]; then
        "$SCRIPT_DIR/message.sh" "Removing existing browser installation at $REQUIRED_DIR..." 2>/dev/null || true
        rm -rf "$REQUIRED_DIR"
    fi
fi

# Fresh install with --with-deps to also pull in OS shared libraries
if [ -n "$PLAYWRIGHT_CLI" ]; then
    if node "$PLAYWRIGHT_CLI" install --with-deps chromium-headless-shell; then
        "$SCRIPT_DIR/message.sh" "Playwright browser installed successfully" 2>/dev/null || true
    else
        "$SCRIPT_DIR/message.sh" "WARNING: Playwright browser install failed. agent-browser may not work." 2>/dev/null || true
    fi
else
    "$SCRIPT_DIR/message.sh" "WARNING: playwright-core CLI not found. agent-browser may not work." 2>/dev/null || true
fi

# Save the new version
echo "$VERSION" > "$VERSION_FILE"

"$SCRIPT_DIR/message.sh" "workplace setup finished" 2>/dev/null || true
