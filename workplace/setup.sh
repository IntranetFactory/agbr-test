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
VERSION="003"

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

# Install Playwright browsers for agent-browser.
# Uses locally installed playwright-core version for the correct Chromium revision.
echo "Installing Playwright browsers for agent-browser..."
PLAYWRIGHT_CLI=$(find node_modules/.pnpm -maxdepth 4 -name "cli.js" -path "*/playwright-core/cli.js" 2>/dev/null | head -1)
PLAYWRIGHT_INSTALL_OK=false
if [ -n "$PLAYWRIGHT_CLI" ]; then
    echo "Using playwright-core CLI at: $PLAYWRIGHT_CLI"
    if node "$PLAYWRIGHT_CLI" install chromium-headless-shell; then
        PLAYWRIGHT_INSTALL_OK=true
    else
        echo "WARNING: Playwright browser download failed via local CLI, trying compatibility fallback"
    fi
else
    echo "playwright-core not found in local node_modules, falling back to global playwright..."
    if npx --yes playwright install chromium-headless-shell; then
        PLAYWRIGHT_INSTALL_OK=true
    else
        echo "WARNING: Playwright browser download failed, trying compatibility fallback"
    fi
fi

# If browser download failed, try to create a compatibility symlink from any cached headless shell.
if [ "$PLAYWRIGHT_INSTALL_OK" = false ]; then
    BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}"
    # Determine required revision from the globally installed agent-browser's playwright-core
    AGENT_PW_BROWSERS_JSON=$(find /opt/node22/lib/node_modules/agent-browser/node_modules/playwright-core -name "browsers.json" 2>/dev/null | head -1)
    REQUIRED_REVISION=""
    if [ -n "$AGENT_PW_BROWSERS_JSON" ] && command -v python3 &>/dev/null; then
        REQUIRED_REVISION=$(python3 - "$AGENT_PW_BROWSERS_JSON" <<'PYEOF'
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
    if [ -n "$REQUIRED_REVISION" ]; then
        REQUIRED_DIR="$BROWSERS_PATH/chromium_headless_shell-$REQUIRED_REVISION"
        if [ ! -f "$REQUIRED_DIR/INSTALLATION_COMPLETE" ]; then
            echo "Looking for a cached headless shell to use as fallback for revision $REQUIRED_REVISION..."
            EXISTING_SHELL=$(find "$BROWSERS_PATH" -maxdepth 4 \( -name "headless_shell" -o -name "chrome-headless-shell" \) 2>/dev/null | head -1)
            if [ -n "$EXISTING_SHELL" ]; then
                EXISTING_SHELL_DIR="$(dirname "$EXISTING_SHELL")"
                echo "Creating compatibility symlink from $EXISTING_SHELL_DIR"
                mkdir -p "$REQUIRED_DIR/chrome-headless-shell-linux64"
                for f in "$EXISTING_SHELL_DIR"/*; do
                    ln -sf "$f" "$REQUIRED_DIR/chrome-headless-shell-linux64/$(basename "$f")" 2>/dev/null || true
                done
                # Ensure the expected executable name exists regardless of the source binary name
                ln -sf "$EXISTING_SHELL" "$REQUIRED_DIR/chrome-headless-shell-linux64/chrome-headless-shell" 2>/dev/null || true
                touch "$REQUIRED_DIR/INSTALLATION_COMPLETE"
                touch "$REQUIRED_DIR/DEPENDENCIES_VALIDATED"
                echo "Compatibility symlink created for chromium_headless_shell-$REQUIRED_REVISION"
            else
                echo "WARNING: No cached browser found. agent-browser may not work."
            fi
        else
            echo "chromium_headless_shell-$REQUIRED_REVISION already available in cache"
        fi
    else
        echo "WARNING: Could not determine required browser revision. agent-browser may not work."
    fi
fi

# Save the new version
echo "$VERSION" > "$VERSION_FILE"
echo "Workplace updated to version $VERSION"

# Send success message
"$SCRIPT_DIR/message.sh" "workplace setup finished" 2>/dev/null || true