# Project Context

> **Agent-maintained file.** Update this file after every major task with project-specific discoveries, architecture notes, and progress. This is your working memory for this codebase.

## Architecture

- **Monorepo** managed by pnpm workspaces + Turborepo (`turbo.json`)
- Primary app: `apps/web` — a React SPA

## Tech Stack (`apps/web`)

| Layer        | Technology                        |
| ------------ | --------------------------------- |
| Framework    | React 19                          |
| Language     | TypeScript 5.9                    |
| Build / Dev  | Vite 7 (HMR on `localhost:5173`)  |
| Styling      | Tailwind CSS 4                    |
| Components   | shadcn/ui (Radix primitives + CVA + `cn()` utility) |
| Linting      | ESLint 9                          |
| Deployment   | Cloudflare Workers (via Wrangler) |

### Useful dev shortcuts

```bash
pnpm --filter web dev      # start only the web app in dev mode
pnpm --filter web build    # build only the web app
pnpm --filter web lint     # lint only the web app
```

### Path alias

`@` is mapped to `apps/web/src` via Vite config and `tsconfig.app.json`.

## Discovery Log

<!-- Append new entries at the top. Format: YYYY-MM-DD — description -->

_No entries yet._
