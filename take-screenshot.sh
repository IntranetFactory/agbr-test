#!/bin/bash

# Script to start dev server and take a screenshot of the welcome page

set -e  # Exit on error

echo "Starting Vite dev server..."
npm run dev &
DEV_PID=$!

# Wait for the server to start
echo "Waiting for dev server to be ready..."
sleep 10

# Take a screenshot
echo "Taking screenshot..."
npx agent-browser open http://localhost:5173
sleep 3
npx agent-browser screenshot --full screenshots/welcome.png

echo "Screenshot saved to screenshots/welcome.png"

# Kill the dev server
echo "Stopping dev server..."
kill $DEV_PID

echo "Done!"
