#!/bin/bash
set -e

# 1. Configuration & Slugs
REPO_NAME=$(basename -s .git $(git config --get remote.origin.url) | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
RAW_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# Use "prod" as the alias if on main, otherwise the branch name
BRANCH_SLUG=$(echo "$RAW_BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
# Cloudflare Workers tag limit is 25 characters
BRANCH_TAG=$(echo "$BRANCH_SLUG" | cut -c1-25)

# 2. Fetch Cloudflare Workers subdomain
if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
  echo "Error: CLOUDFLARE_API_TOKEN is not set" >&2
  exit 1
fi

ACCOUNT_ID=$(curl -s "https://api.cloudflare.com/client/v4/accounts" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  | jq -r '.result[0].id')
echo "Account ID: $ACCOUNT_ID"

CF_SUBDOMAIN=$(curl -s "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/subdomain" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  | jq -r '.result.subdomain')
echo "Workers subdomain: $CF_SUBDOMAIN"

# 3. Build
pnpm run build

# 4. wrangler fails to publish when running in Copilot sandbox, the GitHub GoProxy seems to be non standard compliant
#    Load a GoProxy compatibility fix so wrangler/undici sends Title-Case
#    Content-Length headers that the MITM proxy can parse.
#    Only apply this fix when running inside the GitHub Copilot sandbox.
if [[ -n "$COPILOT_AGENT_CALLBACK_URL" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  export NODE_OPTIONS="--require ${SCRIPT_DIR}/fix-copilot-proxy-compat.cjs${NODE_OPTIONS:+ $NODE_OPTIONS}"
fi

# 5. Logic: Default to Preview unless --prod or --production is passed
if [[ "$*" == *"--prod"* ]] || [[ "$*" == *"--production"* ]]; then
  echo "🚀 [PRODUCTION] Deploying live: $REPO_NAME"

  pnpm wrangler deploy --name "$REPO_NAME" || { echo "❌ Deployment failed" >&2; exit 1; }

  DEPLOY_URL="https://$REPO_NAME.$CF_SUBDOMAIN.workers.dev"
else
  echo "🔗 [PREVIEW] Deploying preview: $BRANCH_SLUG.$REPO_NAME"

  pnpm wrangler versions upload \
    --name "$REPO_NAME" \
    --preview-alias "$BRANCH_SLUG" \
    --tag "$BRANCH_TAG" \
    --message "Preview upload for: $RAW_BRANCH" || { echo "❌ Preview deployment failed" >&2; exit 1; }

  DEPLOY_URL="https://$BRANCH_SLUG-$REPO_NAME.$CF_SUBDOMAIN.workers.dev"
fi

echo ""
echo "Deploy URL: $DEPLOY_URL"
printf "# Deploy URL\n\n%s\n" "$DEPLOY_URL" > ../../.preview-url.md
