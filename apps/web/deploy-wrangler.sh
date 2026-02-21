#!/bin/bash
set -e

# 1. Configuration & Slugs
REPO_NAME=$(basename -s .git $(git config --get remote.origin.url) | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
RAW_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# Use "prod" as the alias if on main, otherwise the branch name
BRANCH_SLUG=$(echo "$RAW_BRANCH" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')

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

# 4. Logic: Default to Preview unless --prod or --production is passed
if [[ "$*" == *"--prod"* ]] || [[ "$*" == *"--production"* ]]; then
  echo "🚀 [PRODUCTION] Deploying live: $REPO_NAME"

  pnpm wrangler deploy --name "$REPO_NAME" || { echo "❌ Deployment failed" >&2; exit 1; }

  DEPLOY_URL="https://$REPO_NAME.$CF_SUBDOMAIN.workers.dev"
else
  echo "🔗 [PREVIEW] Deploying preview: $BRANCH_SLUG.$REPO_NAME"

  pnpm wrangler versions upload \
    --name "$REPO_NAME" \
    --preview-alias "$BRANCH_SLUG" \
    --tag "$RAW_BRANCH" \
    --message "Preview upload for: $RAW_BRANCH" || { echo "❌ Preview deployment failed" >&2; exit 1; }

  DEPLOY_URL="https://$BRANCH_SLUG-$REPO_NAME.$CF_SUBDOMAIN.workers.dev"
fi

echo ""
echo "Deploy URL: $DEPLOY_URL"
printf "# Deploy URL\n\n%s\n" "$DEPLOY_URL" > ../../.preview-url.md
