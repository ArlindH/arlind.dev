#!/bin/bash
set -euo pipefail

# Auto-deploy script - polls origin/main, deploys only if new commits exist
# Called by cron every 3 minutes

SITE_DIR="/root/projects/arlind.dev"
OUTPUT_DIR="/var/www/arlind.dev"
LOG_TAG="arlind-deploy"

cd "$SITE_DIR"

git fetch origin main --quiet

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

# Check if the site has been built at the current commit
BUILT_MARKER="$OUTPUT_DIR/.built-commit"
BUILT_COMMIT=""
if [ -f "$BUILT_MARKER" ]; then
    BUILT_COMMIT=$(cat "$BUILT_MARKER")
fi

if [ "$LOCAL" = "$REMOTE" ] && [ "$BUILT_COMMIT" = "$LOCAL" ]; then
    exit 0
fi

if [ "$LOCAL" != "$REMOTE" ]; then
    logger -t "$LOG_TAG" "Deploying: ${LOCAL:0:7} -> ${REMOTE:0:7}"
    git reset --hard origin/main --quiet
else
    logger -t "$LOG_TAG" "Rebuilding at ${LOCAL:0:7} (not yet deployed)"
fi

hugo --minify --destination "$OUTPUT_DIR"
git rev-parse HEAD > "$BUILT_MARKER"

logger -t "$LOG_TAG" "Deploy OK: now at $(git rev-parse --short HEAD)"
