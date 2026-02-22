#!/bin/bash
set -e

# 1. Configuration & Slugs
REPO_NAME=$(basename -s .git $(git config --get remote.origin.url) | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g')
RAW_BRANCH=$(git rev-parse --abbrev-ref HEAD | tr '[:upper:]' '[:lower:]')
BRANCH_TAG=$(echo "$RAW_BRANCH" | sed 's/copilot//g; s/claude//g' | sed 's/[^a-z]//g' | cut -c1-10)-$(date '+%Y%m%d%H%M%S')

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
  echo "🔗 [PREVIEW] Deploying preview: $BRANCH_TAG.$REPO_NAME"

  pnpm wrangler versions upload \
    --name "$REPO_NAME" \
    --preview-alias "$BRANCH_TAG" \
    --tag "$BRANCH_TAG" \
    --message "Preview upload for: $RAW_BRANCH" || { echo "❌ Preview deployment failed" >&2; exit 1; }

  DEPLOY_URL="https://$BRANCH_TAG-$REPO_NAME.$CF_SUBDOMAIN.workers.dev"
fi

CURL_OK=false
for attempt in 1 2 3; do
  SLEEP_SECS=$(( attempt * 3 - 1 ))  # 2, 5, 8 → sleep before retry (skip on first attempt)
  if [[ $attempt -gt 1 ]]; then
    echo "⏳ Waiting ${SLEEP_SECS}s before retry $attempt/3..."
    sleep "$SLEEP_SECS"
  fi
  HTTP_CODE=$(curl -sSL --max-time 15 -o /tmp/deploy_check_body -w "%{http_code}" \
    --stderr /tmp/deploy_check_err "$DEPLOY_URL") && RC=$? || RC=$?
  if [[ $RC -ne 0 ]]; then
    echo "⚠️  curl failed (exit $RC) on attempt $attempt/3:"
    cat /tmp/deploy_check_err >&2
    continue
  fi
  if [[ "$HTTP_CODE" =~ ^[23] ]]; then
    CURL_OK=true
    break
  else
    echo "⚠️  HTTP $HTTP_CODE on attempt $attempt/3"
    cat /tmp/deploy_check_body >&2
  fi
done

if [[ "$CURL_OK" != true ]]; then
  echo "❌ Deploy URL did not become healthy after 3 attempts: $DEPLOY_URL" >&2
fi

echo ""
echo "Deploy URL: $DEPLOY_URL"
printf "# Deploy URL\n\n%s\n" "$DEPLOY_URL" > ../../.preview-url.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/message.sh" "Preview published $DEPLOY_URL"
