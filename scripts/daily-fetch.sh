#!/bin/bash
# daily-fetch.sh — Fetch AI news from all configured sources
# Usage: ./scripts/daily-fetch.sh [YYYY-MM-DD]
#        or just: ./scripts/daily-fetch.sh (uses today's date)
#
# Dependencies: curl, python3 (for HTML parsing), bash >= 4
# Overseas sites require ClashX Pro proxy to be running

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/sources.sh"

DATE="${1:-$(date +%Y-%m-%d)}"
DATA_DIR="$SCRIPT_DIR/../_data/$DATE"
mkdir -p "$DATA_DIR"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  AI Hot News — Daily Source Fetcher     ║"
echo "║  Date: $DATE                              ║"
echo "╚══════════════════════════════════════════╝"

# ─── 1. Chinese sources ───
section_header "1. Chinese platforms"
fetch_save "量子位(qbitai)"   "${CN_SOURCES[qbitai]}"     "$DATA_DIR/qbitai.html"
fetch_save "机器之心"         "${CN_SOURCES[jiqizhixin]}"  "$DATA_DIR/jiqizhixin.html"

# ─── 2. Overseas sources ───
section_header "2. Overseas platforms"
fetch_save "The Verge AI"    "${EN_SOURCES[verge_ai]}"    "$DATA_DIR/verge_ai.html"
fetch_save "TechCrunch AI"   "${EN_SOURCES[tc_ai]}"       "$DATA_DIR/tc_ai.html"
fetch_save "CNBC Tech"       "${EN_SOURCES[cnbc_tech]}"   "$DATA_DIR/cnbc_tech.html"
fetch_save "OpenAI Blog"     "${EN_SOURCES[openai_blog]}"  "$DATA_DIR/openai_blog.html"
fetch_save "Anthropic Blog"  "${EN_SOURCES[anthropic_blog]}" "$DATA_DIR/anthropic_blog.html"

# ─── 3. Reddit ───
section_header "3. Reddit communities"
for sub in ml singularity localllama; do
    key="$sub"
    fetch_save "r/${sub}" "${REDDIT_SOURCES[$key]}" "$DATA_DIR/reddit_${sub}.json"
done

# ─── 4. Parse and summarize ───
section_header "4. Extracted headlines"

echo ""
echo "=== 量子位 最新文章 ==="
parse_qbitai "$DATA_DIR/qbitai.html" 2>/dev/null || echo "(parse failed)"

echo ""
echo "=== The Verge AI 最新文章 ==="
parse_verge "$DATA_DIR/verge_ai.html" 2>/dev/null | head -15 || echo "(parse failed)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Fetch complete. Raw data saved to:"
echo "  $DATA_DIR/"
echo ""
echo "  Next: generate the daily post with AI,"
echo "  then commit it to the repo."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
