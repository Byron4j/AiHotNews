#!/bin/bash
# daily-pipeline.sh — Full daily workflow: fetch → generate → format → publish
# Usage: ./scripts/daily-pipeline.sh
#
# This is the master orchestration script for the daily AI hotspots workflow.
# It runs the full pipeline:
#   1. Fetch sources from all platforms
#   2. Prompt AI to generate the markdown post
#   3. Convert to platform-specific formats (WeChat, Zhihu, etc.)
#   4. Commit and push to GitHub

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
DATE="${1:-$(date +%Y-%m-%d)}"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  AI Hot News — Daily Pipeline           ║"
echo "║  Date: $DATE                              ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Step 1: Fetch
echo "▶ Step 1/4: Fetching sources..."
bash "$SCRIPT_DIR/daily-fetch.sh" "$DATE"

# Step 2: AI generation hint
POST_FILE="$ROOT_DIR/${DATE}-daily-ai-hotspots.md"
echo ""
echo "▶ Step 2/4: AI content generation"
echo ""
echo "  ┌─────────────────────────────────────────┐"
echo "  │  Raw data is ready at:                   │"
echo "  │  _data/$DATE/                            │"
echo "  │                                          │"
echo "  │  Please generate the daily post now:     │"
echo "  │  1. Read editorial-guidelines.md         │"
echo "  │  2. Read _data/$DATE/ source files       │"
echo "  │  3. Write $POST_FILE                     │"
echo "  │                                          │"
echo "  │  Then re-run:                            │"
echo "  │  ./scripts/daily-pipeline.sh --continue  │"
echo "  └─────────────────────────────────────────┘"
echo ""

# If --continue flag, proceed to format
if [ "${1:-}" = "--continue" ] || [ "${2:-}" = "--continue" ]; then
    echo "▶ Step 3/4: Formatting for platforms..."
    if [ -f "$POST_FILE" ]; then
        bash "$SCRIPT_DIR/format-publish.sh" "$POST_FILE" all
    else
        echo "  ⚠️ Post not found: $POST_FILE"
        echo "  Generate the post first, then run with --continue"
        exit 1
    fi

    # Step 4: Git commit & push
    echo "▶ Step 4/4: Git commit & push..."
    cd "$ROOT_DIR"
    git add "$POST_FILE" "${POST_FILE%.md}-wechat.md" "${POST_FILE%.md}-zhihu.md" "${POST_FILE%.md}-xiaohongshu.txt" "${POST_FILE%.md}-csdn.md" "${POST_FILE%.md}-juejin.md" 2>/dev/null || true
    git add "_data/$DATE/" 2>/dev/null || true
    git add . 2>/dev/null || true
    git commit -m "daily: $DATE AI hotspots digest" 2>/dev/null || echo "  (nothing new to commit)"
    git push origin main 2>/dev/null || echo "  ⚠️ Push failed — check remote/git config"

    echo ""
    echo "╔══════════════════════════════════════════╗"
    echo "║  Pipeline complete!                      ║"
    echo "║                                          ║"
    echo "║  Publish now:                            ║"
    echo "║  • WeChat: ${POST_FILE%.md}-wechat.md    ║"
    echo "║  • Zhihu:  ${POST_FILE%.md}-zhihu.md     ║"
    echo "║  • 小红书: ${POST_FILE%.md}-xiaohongshu.txt ║"
    echo "║  • CSDN:   ${POST_FILE%.md}-csdn.md      ║"
    echo "║  • 掘金:   ${POST_FILE%.md}-juejin.md    ║"
    echo "╚══════════════════════════════════════════╝"
fi
