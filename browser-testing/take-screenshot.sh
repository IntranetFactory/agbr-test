#!/bin/bash

# Script to start dev server and take a screenshot of the welcome page

set -e  # Exit on error

cd "$(dirname "$0")/../apps/web"

echo "Starting Vite dev server..."
pnpm dev &
DEV_PID=$!

# Wait for the server to be ready with health check
echo "Waiting for dev server to be ready..."
timeout=30
elapsed=0
while ! curl -s http://localhost:5173 > /dev/null 2>&1; do
  sleep 1
  elapsed=$((elapsed + 1))
  if [ $elapsed -ge $timeout ]; then
    echo "Timeout waiting for dev server"
    kill $DEV_PID 2>/dev/null || true
    exit 1
  fi
done
echo "Dev server is ready!"

# Take a screenshot
echo "Taking screenshot..."
npx agent-browser open http://localhost:5173
sleep 3
npx agent-browser screenshot --full screenshots/welcome.png

echo "Screenshot saved to apps/web/screenshots/welcome.png"

# Kill the dev server
echo "Stopping dev server..."
kill $DEV_PID

echo "Done!"
