# Agent Instructions

## Project Overview

This is a React SPA monorepo using pnpm workspaces and Turborepo. The web app lives in `apps/web/` and is built with Vite, TypeScript, Tailwind CSS, and shadcn/ui.

## Setup

Before doing any work, install dependencies:

```bash
cd /home/user/agbr-test
pnpm install
```

## Building

Build the web app using pnpm from the `apps/web/` directory:

```bash
pnpm --filter web build
```

Do **not** use `npx vite build` directly — Vite is a workspace dependency, not globally installed.

## Dev Server

Start the dev server:

```bash
pnpm --filter web dev
```

Note: The default port is 5173, but if it's in use Vite will auto-increment (5174, 5175, etc.). Check the terminal output for the actual URL.

## agent-browser / Playwright Setup

`agent-browser` uses Playwright under the hood and requires a matching Chromium browser binary. This is the most common source of setup issues.

### Required setup before using agent-browser

1. **Install project dependencies first** (this installs `agent-browser`):
   ```bash
   pnpm install
   ```

2. **Check which Playwright version agent-browser uses**:
   ```bash
   # Find the playwright-core version bundled with agent-browser
   cat node_modules/agent-browser/node_modules/playwright-core/package.json | grep '"version"'
   # Or if hoisted:
   find node_modules -path "*/agent-browser*" -name "package.json" | head -1
   ```

3. **Install the matching Chromium browser**. Playwright expects a specific browser build at a specific path. If the expected version can't be downloaded (e.g., network restrictions), create a symlink from an existing Chromium install:
   ```bash
   # First, see what path Playwright expects (run agent-browser and check the error):
   npx agent-browser open http://localhost:5173
   # Error will show something like:
   #   Executable doesn't exist at /root/.cache/ms-playwright/chromium_headless_shell-1208/...

   # Check what's already installed:
   ls /root/.cache/ms-playwright/

   # If a different version exists (e.g., chromium-1194), symlink it:
   mkdir -p /root/.cache/ms-playwright/chromium_headless_shell-1208/chrome-headless-shell-linux64/
   ln -sf /root/.cache/ms-playwright/chromium-1194/chrome-linux/chrome \
          /root/.cache/ms-playwright/chromium_headless_shell-1208/chrome-headless-shell-linux64/chrome-headless-shell
   ```

   Replace version numbers (`1208`, `1194`) with whatever your environment actually has.

### Using agent-browser

There is a helper script at `browser-testing/take-screenshot.sh` for taking screenshots. For manual use:

```bash
# Start the dev server first (in background or another terminal)
pnpm --filter web dev &

# Open, snapshot, screenshot, close
npx agent-browser open http://localhost:5173
npx agent-browser snapshot -i
npx agent-browser screenshot --full apps/web/screenshots/welcome.png
npx agent-browser close
```

Screenshots should always be saved to `apps/web/screenshots/`. This is the convention used by `browser-testing/take-screenshot.sh`.

### Key files

| Path | Description |
|------|-------------|
| `apps/web/src/Welcome.tsx` | Home page component |
| `apps/web/src/App.tsx` | Root React component (renders Welcome) |
| `apps/web/src/main.tsx` | React entry point |
| `apps/web/screenshots/` | Screenshot output directory |
| `browser-testing/take-screenshot.sh` | Screenshot helper script |
