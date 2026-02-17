#!/bin/bash

# Check workspace setup status
# This script verifies that the workspace is properly configured

echo "🔍 Checking workspace setup..."
echo

# Check if pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm is not installed"
    echo "   Install with: npm install -g pnpm@10.29.3"
    exit 1
else
    echo "✅ pnpm is installed: $(pnpm --version)"
fi

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
    echo "❌ node_modules directory not found"
    echo "   Run: bash workplace/setup.sh"
    exit 1
else
    echo "✅ node_modules directory exists"
fi

# Check if Husky hooks are configured
HOOKS_PATH=$(git config core.hooksPath || echo "")
if [ "$HOOKS_PATH" != ".husky/_" ]; then
    echo "❌ Git hooks not configured (core.hooksPath=$HOOKS_PATH)"
    echo "   Run: bash workplace/setup.sh"
    exit 1
else
    echo "✅ Git hooks configured"
fi

# Check if workplace version file exists
if [ ! -f ".workplace-version" ]; then
    echo "❌ Workplace not initialized (.workplace-version missing)"
    echo "   Run: bash workplace/setup.sh"
    exit 1
else
    VERSION=$(cat .workplace-version)
    echo "✅ Workplace initialized (version $VERSION)"
fi

# Check if agent-browser is installed
if ! command -v agent-browser &> /dev/null; then
    echo "⚠️  agent-browser not found globally"
    echo "   It may be installed locally in node_modules"
else
    echo "✅ agent-browser is installed globally"
fi

# Check if Playwright browsers are installed
PLAYWRIGHT_CACHE="$HOME/.cache/ms-playwright"
if [ ! -d "$PLAYWRIGHT_CACHE" ] || [ -z "$(ls -A "$PLAYWRIGHT_CACHE" 2>/dev/null | grep chromium)" ]; then
    echo "⚠️  Playwright Chromium not found in cache"
    echo "   Run: npx playwright install chromium"
else
    echo "✅ Playwright browsers installed"
fi

echo
echo "🎉 Workspace is properly configured!"
