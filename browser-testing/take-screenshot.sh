#!/bin/bash

# Script to take a screenshot of the welcome page using agent-browser
# This script:
# 1. Starts the Vite dev server
# 2. Opens the application in a headless browser
# 3. Captures a full-page screenshot
# 4. Saves it to apps/web/screenshots/welcome.png

set -e

echo "Starting development server..."
cd "$(dirname "$0")/../apps/web"

# Start dev server in background
pnpm dev &
DEV_PID=$!

# Wait for server to be ready with polling
echo "Waiting for server to start..."
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if curl -s http://localhost:5173 > /dev/null 2>&1; then
    echo "Server is ready!"
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  sleep 1
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
  echo "Error: Server failed to start within 30 seconds"
  kill $DEV_PID 2>/dev/null || true
  exit 1
fi

# Take screenshot
echo "Taking screenshot..."
cd ../..
agent-browser open http://localhost:5173/
agent-browser wait --load networkidle
agent-browser screenshot --full apps/web/screenshots/welcome.png
agent-browser close

# Stop dev server and all child processes
echo "Stopping development server..."
kill -- -$DEV_PID 2>/dev/null || true

echo "✓ Screenshot saved to apps/web/screenshots/welcome.png"
