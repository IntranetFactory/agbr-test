#!/bin/bash

# Script to take a screenshot of the welcome page using agent-browser
# This script:
# 1. Starts the Vite dev server
# 2. Opens the application in a headless browser
# 3. Captures a full-page screenshot
# 4. Saves it to apps/web/screenshots/welcome.png

set -e

# Trap to ensure cleanup happens even if script fails
cleanup() {
  echo "Stopping development server..."
  if [ -n "$DEV_PID" ]; then
    # Kill the process group
    kill -TERM -$DEV_PID 2>/dev/null || true
    # Also kill any remaining node/vite processes on port 5173 gracefully first
    lsof -ti:5173 | xargs -r kill -TERM 2>/dev/null || true
    sleep 1
    # Force kill if still running
    lsof -ti:5173 | xargs -r kill -9 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo "Starting development server..."
cd "$(dirname "$0")/../apps/web"

# Start dev server in background with new process group using setsid
setsid pnpm dev &
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
  exit 1
fi

# Take screenshot
echo "Taking screenshot..."
cd ../..

# Run agent-browser commands with error handling
if ! agent-browser open http://localhost:5173/; then
  echo "Error: Failed to open browser"
  exit 1
fi

if ! agent-browser wait --load networkidle; then
  echo "Error: Page failed to load"
  exit 1
fi

if ! agent-browser screenshot --full apps/web/screenshots/welcome.png; then
  echo "Error: Failed to take screenshot"
  exit 1
fi

agent-browser close

echo "✓ Screenshot saved to apps/web/screenshots/welcome.png"
