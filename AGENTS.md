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

> ⚠️ **Screenshots must be taken from the Cloudflare preview URL, never from localhost.**
> Read `.preview-url.md` after deployment and open that URL before screenshotting.

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
2. Use `pnpm dev` during development for fast Vite feedback (localhost is for iteration only)
3. `pnpm build` — confirm no build errors
4. `pnpm preview:wrangler` — deploy to Cloudflare via turbo (**run from repo root**)
5. Read `.preview-url.md` — this is the only valid URL for verification screenshots
```bash
   cat .preview-url.md   # e.g. https://abc123.your-project.workers.dev
```
6. `agent-browser open <url-from-.preview-url.md>` — **use this URL, not localhost**
7. `agent-browser screenshot --full screenshots/YYYYMMDDHHMMSS-<short-title>.png`
8. Confirm the screenshot URL/title bar reflects the Cloudflare domain, not localhost
9. Include screenshot path, description, and confidence score in your result comment

> ❌ **A screenshot taken from `localhost` or `127.0.0.1` does not count as verification.**
> The task is not complete until a screenshot from the `.preview-url.md` URL is saved.

## PR Description Requirements — MANDATORY FOR EVERY PR

Every PR description submitted via **report_progress** **MUST** include both of the following. No exceptions.

### 1. Preview URL — show the full URL, not hidden link text

Always include the Cloudflare preview URL read from `.preview-url.md` as a **bare URL** so it is fully visible to the reviewer. Do NOT hide it behind link text like "Live preview →".

```markdown
## Preview
https://copilot-<branch>-agbr-test.ma532.workers.dev
```

> ❌ **Wrong:** `[Live preview →](https://copilot-...)` — hides the URL behind text
> ✅ **Correct:** `https://copilot-...` — the full URL is visible

### 2. Screenshots embedded in the PR — use absolute raw GitHub URLs

Relative paths like `screenshots/file.png` do **not** render in GitHub PR descriptions because GitHub resolves images from the default branch (`main`), not the PR branch. Always use the absolute `raw.githubusercontent.com` URL.

URL format:
```
https://raw.githubusercontent.com/IntranetFactory/agbr-test/<branch-name>/screenshots/YYYYMMDDHHMMSS-short-title.png
```

```markdown
## Screenshots
![description](https://raw.githubusercontent.com/IntranetFactory/agbr-test/<branch-name>/screenshots/YYYYMMDDHHMMSS-short-title.png)
```

> ❌ **Wrong:** `![alt](screenshots/file.png)` — broken image in PR (relative path, not merged yet)
> ✅ **Correct:** `![alt](https://raw.githubusercontent.com/IntranetFactory/agbr-test/<branch>/screenshots/file.png)`

> ⚠️ Screenshots mentioned only in comments do NOT satisfy this requirement. They must be **visible inline** in the PR description itself so reviewers can see them without clicking.

### Example `prDescription` for report_progress

```markdown
- [x] Changed heading to show URL

## Preview
https://copilot-my-branch-agbr-test.ma532.workers.dev

## Screenshots
![Home page heading showing window.location.href](https://raw.githubusercontent.com/IntranetFactory/agbr-test/copilot/my-branch/screenshots/20240315143022-checkout-flow.png)
```
