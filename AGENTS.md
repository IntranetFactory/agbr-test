# Agent Instructions

## Environment

The workspace is provisioned automatically via `workplace/setup.sh` on session start. The following are installed globally and available on PATH:

- `agent-browser` — headless browser automation
- `dotenvx` — secret decryption
- `wrangler` — Cloudflare deployment
- `pnpm` — package manager

Do not re-run `setup.sh` manually unless the environment appears broken.

## Commands
```bash
pnpm dev              # start all apps in dev mode (Vite HMR at http://localhost:5173)
pnpm build            # build all apps
pnpm lint             # lint all apps
```

## Development vs. Completion

### During development — fast iteration
Use `pnpm dev` (or `pnpm --filter web dev`) for instant Vite HMR feedback while writing code. Use this freely during a task for rapid iteration. Localhost is a development tool only — **it is not a completion gate**.

### Task completion — mandatory
A task is **not complete** until it has been deployed to a Cloudflare branch preview and verified there. Do not mark a task done based on localhost behaviour alone.

## Secrets

Secrets are encrypted in `.env` and decrypted at runtime by dotenvx. The private key is provided via the `DOTENV_PRIVATE_KEY` environment variable (`.env.keys` does not exist in this sandbox). To run a command with secrets available:
```bash
dotenvx run -- <command>
```

To add or update a secret:
```bash
dotenvx set KEY value
```

Never expose or log secret values.

## Deployment

Branch previews deploy to Cloudflare Workers. After deployment, the preview URL is written to `.preview-url.md` at the repo root.
```bash
pnpm --filter web preview:wrangler   # deploy preview, writes URL to .preview-url.md
```

Read `.preview-url.md` to get the URL — do not guess or construct it manually.

Production deploy:
```bash
cd apps/web && bash deploy-wrangler.sh --prod
```

## Browser Automation

Use `agent-browser` to verify deployed output or test the running dev server.
```bash
agent-browser open <url>
agent-browser snapshot                   # get accessibility tree with element refs
agent-browser click @ref
agent-browser fill @ref "value"
agent-browser screenshot --full <path>
```

Full skill documentation: `.agents/skills/agent-browser/SKILL.md`

> **Limitation:** `agent-browser` does not work in the Claude Code web sandbox. It works in DevContainer and GitHub Copilot agent environments.

## Screenshots

All verification screenshots **must** be saved to the `screenshots/` folder at the repo root.

Filename format: `YYYYMMDDHHMMSS-<short-title>.png`
Example: `20240315143022-checkout-flow.png`

When referencing a screenshot in task results or comments, always include:
- The filename/path
- A short description of what the screenshot shows
- A confidence score (0–100%) reflecting how well the screenshot demonstrates that the task requirements have been met

Example result comment:
```
Screenshot: screenshots/20240315143022-checkout-flow.png
Description: Cloudflare preview showing the completed checkout flow with all three steps visible and the confirm button enabled.
Confidence: 92% — all acceptance criteria visible; minor responsive layout not tested on mobile.
```

## Verification Workflow

When asked to implement and verify a change:

1. Make the change
2. Use `pnpm dev` during development for fast Vite feedback
3. `pnpm build` — confirm no build errors
4. `pnpm --filter web preview:wrangler` — deploy to Cloudflare (**run from repo root**)
5. Read `.preview-url.md` for the preview URL
6. `agent-browser open <url>` then `agent-browser snapshot` / `screenshot` to verify
7. Save screenshot to `screenshots/YYYYMMDDHHMMSS-<short-title>.png`
8. Include screenshot path, description, and confidence score in your result comment
9. Task is complete only after steps 4–8 are done