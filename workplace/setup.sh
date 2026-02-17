#!/bin/bash

# Setup workplace script
# This script is now just a convenience wrapper around "pnpm install"
# The actual setup logic is in postinstall.sh which runs automatically

echo "🚀 Running workspace setup..."
echo ""
echo "This will run 'pnpm install' which automatically:"
echo "  1. Installs project dependencies"
echo "  2. Configures Git hooks (via 'prepare' script)"
echo "  3. Installs agent-browser and Playwright (via 'postinstall' script)"
echo ""

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

# Just run pnpm install - it will trigger prepare and postinstall
pnpm install

echo ""
echo "✅ Workspace setup complete!"
echo ""
echo "To verify your setup, run: bash workplace/check-setup.sh"

# Send success message
"$SCRIPT_DIR/message.sh" "workplace setup finished" 2>/dev/null || true
