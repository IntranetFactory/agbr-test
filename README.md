# agbr-test

A template for a **Level 3 front-end coding agent workplace** — a production-grade React monorepo that provisions itself automatically for AI coding agents (Claude Code, GitHub Copilot) and human developers alike. The agent gets a real environment: encrypted secrets, browser automation, a build pipeline, and Cloudflare deployment — not a managed sandbox with guardrails.

Tools like Lovable win on time-to-first-app — but they run the agent in a managed sandbox, store your secrets on their platform, and stop at the edge of their UI. This template is for when you need the agent working in a real pipeline: encrypted secrets committed to the repo, browser automation the agent drives itself, and deployment you control. You own the stack; you pay your own API costs; nothing locks you in.

## Stack

- **Turborepo** — monorepo build orchestration
- **Vite + React 19 + TypeScript** — front-end app
- **Tailwind CSS v4 + shadcn/ui** — styling and components
- **pnpm workspaces** — package management
- **dotenvx** — encrypted environment variables
- **agent-browser** — browser automation and screenshot generation for AI agents
- **Cloudflare (Wrangler)** — front-end deployment target

## Multi-Environment Support

The workplace provisions itself via `workplace/setup.sh` (installs global deps, Playwright browsers, and project dependencies). It is idempotent — versioned so re-runs are skipped when already up to date.

| Environment | How setup runs |
|---|---|
| GitHub Copilot coding agent | `.github/workflows/copilot-setup-steps.yml` runs `setup.sh` before the agent session |
| Claude Code sandbox | `.claude/settings.json` hooks run `setup.sh` on `SessionStart` |
| DevContainer | `postCreateCommand` in `.devcontainer/devcontainer.json` |
| Human clone | `bash workplace/setup.sh` |

> **Known limitation:** `agent-browser` currently fails in the Claude Code web sandbox. DevContainer and GitHub Copilot coding agent work correctly.

## Monorepo Structure

```
├── .agents/skills/agent-browser/   # agent-browser skill (for agents)
├── .claude/                        # Claude Code settings and hooks
├── .devcontainer/                  # DevContainer configuration
├── .github/workflows/              # copilot-setup-steps.yml
├── apps/web/                       # Main React application
│   ├── src/│   
│   ├── wrangler.jsonc              # Cloudflare deployment config
│   └── deploy-wrangler.sh
├── workplace/
│   └── setup.sh                   # Unified setup script (versioned)
├── turbo.json
└── pnpm-workspace.yaml
```

## Using as a Template

When creating a new project from this template, the encrypted `.env` in the template repo was generated with a key you do not have. You need to generate your own key pair and re-encrypt your own secrets before the Copilot agent (or any other environment) can decrypt them.

1. **Generate a new key:**

   ```bash
   dotenvx genkey
   ```

   This creates `.env.keys` containing your `DOTENV_PRIVATE_KEY` and writes the corresponding public key into `.env`.

2. **Set your secrets:**

   ```bash
   dotenvx set CLOUDFLARE_API_TOKEN <your-token>
   dotenvx set CLOUDFLARE_ACCOUNT_ID <your-account-id>
   dotenvx set NOTIFY_WEBHOOK_URL <your-slack-or-compatible-webhook-url>   # optional
   ```

   Each value is encrypted into `.env` using the public key.

3. **Commit the updated `.env`:**

   ```bash
   git add .env
   git commit -m "chore: initialize encrypted secrets"
   ```

4. **Store the private key securely:**

   Copy `DOTENV_PRIVATE_KEY` from `.env.keys` and add it to:
   - **Actions secret** (Settings → Secrets and variables → Actions → `DOTENV_PRIVATE_KEY`) — required for CI.
   - **Copilot environment secret** (Settings → Environments → copilot → `DOTENV_PRIVATE_KEY`) — required for the Copilot coding agent.
   - A secure store (1Password, etc.) as a backup.

## Getting Started

### Human / local clone

```bash
git clone https://github.com/IntranetFactory/agbr-test.git
cd agbr-test
bash workplace/setup.sh
```

### DevContainer

Open in VS Code and choose **Reopen in Container**. Setup runs automatically.

### GitHub Copilot coding agent

The `copilot-setup-steps.yml` workflow runs setup before each agent session. The following one-time configuration is required in your GitHub repository settings:

**Repository secrets** — `DOTENV_PRIVATE_KEY` must be added in two places:
- **Actions** (Settings → Secrets and variables → Actions) — used by CI.
- **Copilot environment** (Settings → Environments → copilot) — used by the Copilot coding agent.

**Allowed domains** (Settings → Copilot → Policies, or your organisation's Copilot network policy):
- `cloudflare.com`
- `workers.dev`
- If you use an external notifications webhook, add that domain as well.

## Development

```bash
pnpm dev          # start all apps
pnpm build        # build all apps
pnpm lint         # lint all apps
```

App available at `http://localhost:5173`.

## Environment Variables

Secrets are managed with [dotenvx](https://dotenvx.com/). Unlike a typical `.env` workflow, the encrypted `.env` file is committed to the repo — values are encrypted with a public key so the file is safe in version control. The private decryption key lives in `.env.keys`, which is gitignored and must never be committed.

| Variable | Required | Description |
|---|---|---|
| `CLOUDFLARE_API_TOKEN` | Yes | Cloudflare API token for Wrangler deployments |
| `CLOUDFLARE_ACCOUNT_ID` | Yes | Cloudflare account ID |
| `NOTIFY_WEBHOOK_URL` | No | Slack or Slack-compatible webhook URL (e.g. Discord) — when set, a notification with the preview URL is sent after each deploy via `workplace/message.sh` |

**First-time setup:** `.env.local` lists the required variables with empty values. Copy it, fill in your secrets, then encrypt:

```bash
cp .env.local .env.local.mine    # or just edit .env.local directly
# fill in real values, then:
dotenvx encrypt
```

This writes the encrypted values into `.env` (committed) and stores the private key in `.env.keys` (gitignored). Keep `.env.keys` somewhere safe — 1Password, a CI secret, etc.

**Adding or rotating a secret:**

```bash
dotenvx set KEY value
```

**Running with secrets decrypted** (dotenvx injects them at runtime):

```bash
dotenvx run -- pnpm dev
```

## Deployment

The web app deploys to **Cloudflare Workers** via Wrangler. Requires `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` set in `.env`. After a successful deploy, `workplace/message.sh` sends a notification with the preview URL — set `NOTIFY_WEBHOOK_URL` to a Slack or Slack-compatible webhook (e.g. Discord) to enable this.

**Branch preview** (default — always generates a preview URL):
```bash
pnpm --filter web preview:wrangler
```

**Production:**
```bash
cd apps/web && bash deploy-wrangler.sh --prod
```

Each branch gets its own preview URL on Cloudflare Workers. The URL is written to `.preview-url.md` at the repo root after deployment, so a human reviewer or `agent-browser` can pick it up without manual copy-paste — the agent can deploy, read the URL, open it in the browser, and verify the result autonomously.

## Browser Automation (agent-browser)

`agent-browser` provides headless browser control for AI agents — navigation, clicks, form fills, snapshots, and screenshots.

```bash
agent-browser open http://localhost:5173
agent-browser screenshot --full apps/web/screenshots/welcome.png
agent-browser snapshot
agent-browser click @ref
agent-browser fill @ref "text"
```

Skill documentation: `.agents/skills/agent-browser/SKILL.md`

> **Note:** `agent-browser` requires Playwright (installed by `setup.sh`). It does not work in the Claude Code web sandbox.

## License

MIT
