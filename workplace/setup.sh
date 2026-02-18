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

# ── Playwright browser check (runs every session, outside version gate) ────

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
    BROWSERS_JSON="$(dirname "$PLAYWRIGHT_CLI")/browsers.json"
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

BROWSER_READY=false
if [ -n "$REQUIRED_REVISION" ]; then
    REQUIRED_DIR="$BROWSERS_PATH/chromium_headless_shell-$REQUIRED_REVISION"
    CANDIDATE="$REQUIRED_DIR/chrome-headless-shell-linux64/chrome-headless-shell"

    if [ -f "$CANDIDATE" ] && [ -x "$CANDIDATE" ]; then
        # Exact revision already installed
        "$SCRIPT_DIR/message.sh" "Browser r$REQUIRED_REVISION already installed, skipping installation" 2>/dev/null || true
        BROWSER_READY=true
    else
        # Look for any installed chromium_headless_shell revision and find its executable
        EXISTING_DIR=$(find "$BROWSERS_PATH" -maxdepth 1 -name "chromium_headless_shell-*" -not -name "chromium_headless_shell-$REQUIRED_REVISION" -type d 2>/dev/null | head -1)
        if [ -n "$EXISTING_DIR" ]; then
            # Find the actual executable regardless of internal directory structure
            EXISTING_EXE=$(find "$EXISTING_DIR" -type f \( -name "headless_shell" -o -name "chrome-headless-shell" \) 2>/dev/null | head -1)
            if [ -n "$EXISTING_EXE" ] && [ -x "$EXISTING_EXE" ]; then
                # Create the exact path structure the required revision expects, symlinking the exe
                mkdir -p "$REQUIRED_DIR/chrome-headless-shell-linux64"
                ln -sfn "$EXISTING_EXE" "$REQUIRED_DIR/chrome-headless-shell-linux64/chrome-headless-shell"
                "$SCRIPT_DIR/message.sh" "Symlinked $(basename "$EXISTING_DIR") -> chromium_headless_shell-$REQUIRED_REVISION" 2>/dev/null || true
                BROWSER_READY=true
            fi
        fi
    fi
fi

# ── Version gate (runs only when upgrading) ────────────────────────────────

# Current script version
VERSION="007"

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

# Install Playwright browsers if not already ready from the check above
if [ "$BROWSER_READY" = false ]; then
    # Wipe any existing (broken/partial) installation for the required revision
    if [ -n "$REQUIRED_REVISION" ]; then
        if [ -d "$REQUIRED_DIR" ] && [ ! -L "$REQUIRED_DIR" ]; then
            "$SCRIPT_DIR/message.sh" "Removing existing browser installation at $REQUIRED_DIR..." 2>/dev/null || true
            rm -rf "$REQUIRED_DIR"
        fi
    fi

    # Fresh install with --with-deps to also pull in OS shared libraries
    if [ -n "$PLAYWRIGHT_CLI" ]; then
        INSTALL_OUTPUT_FILE=$(mktemp)
        if node "$PLAYWRIGHT_CLI" install --with-deps chromium-headless-shell 2>&1 | tee "$INSTALL_OUTPUT_FILE"; then
            "$SCRIPT_DIR/message.sh" "Playwright browser installed successfully" 2>/dev/null || true
        else
            # Extract the download URL from playwright's output so it can be whitelisted
            DOWNLOAD_URL=$(grep -oP 'from \Khttps?://\S+' "$INSTALL_OUTPUT_FILE" | head -1)
            rm -f "$INSTALL_OUTPUT_FILE"
            if [ -n "$DOWNLOAD_URL" ]; then
                "$SCRIPT_DIR/message.sh" "ERROR: Playwright browser download failed (CDN blocked). Whitelist this URL: $DOWNLOAD_URL" 2>/dev/null || true
            else
                "$SCRIPT_DIR/message.sh" "ERROR: Playwright browser download failed (CDN blocked)." 2>/dev/null || true
            fi
            exit 1
        fi
        rm -f "$INSTALL_OUTPUT_FILE"
    else
        "$SCRIPT_DIR/message.sh" "ERROR: playwright-core CLI not found. Cannot install browser." 2>/dev/null || true
        exit 1
    fi
fi

# Save the new version
echo "$VERSION" > "$VERSION_FILE"

"$SCRIPT_DIR/message.sh" "workplace setup finished" 2>/dev/null || true
