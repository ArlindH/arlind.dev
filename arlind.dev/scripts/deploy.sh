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

if [ "$LOCAL" = "$REMOTE" ]; then
    exit 0
fi

logger -t "$LOG_TAG" "Deploying: ${LOCAL:0:7} -> ${REMOTE:0:7}"

git reset --hard origin/main --quiet

hugo --minify --destination "$OUTPUT_DIR"

logger -t "$LOG_TAG" "Deploy OK: now at $(git rev-parse --short HEAD)"
