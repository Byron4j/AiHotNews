#!/bin/bash
# Source definitions and fetch helpers for daily AI news pipeline
# Requires: curl (via ClashX Pro proxy for overseas sites)

set -euo pipefail

# ---------- Source endpoints ----------

# Chinese platforms
declare -A CN_SOURCES
CN_SOURCES[qbitai]="https://www.qbitai.com/"
CN_SOURCES[jiqizhixin]="https://www.jiqizhixin.com/"
CN_SOURCES[36kr]="https://36kr.com/"

# Overseas platforms (accessed via ClashX Pro proxy)
declare -A EN_SOURCES
EN_SOURCES[verge_ai]="https://www.theverge.com/ai-artificial-intelligence"
EN_SOURCES[tc_ai]="https://techcrunch.com/category/artificial-intelligence/"
EN_SOURCES[cnbc_tech]="https://www.cnbc.com/technology/"
EN_SOURCES[openai_blog]="https://openai.com/index/"
EN_SOURCES[anthropic_blog]="https://www.anthropic.com/blog"

# Reddit endpoints (JSON)
declare -A REDDIT_SOURCES
REDDIT_SOURCES[ml]="https://www.reddit.com/r/MachineLearning/hot.json?limit=10"
REDDIT_SOURCES[singularity]="https://www.reddit.com/r/singularity/hot.json?limit=10"
REDDIT_SOURCES[localllama]="https://www.reddit.com/r/LocalLLaMA/hot.json?limit=10"

# ---------- Fetch helpers ----------

# Fetch and save raw HTML to file
fetch_save() {
    local name="$1"
    local url="$2"
    local outfile="$3"
    echo "  Fetching ${name} (${url:0:60}...)"
    curl -sL --max-time 20 "$url" > "$outfile" 2>/dev/null || {
        echo "    ⚠️ Failed: ${name}"
        echo "(fetch failed)" > "$outfile"
    }
}

# Extract qbitai article headers from raw HTML
parse_qbitai() {
    local file="$1"
    grep -oE '<a[^>]*href="(https://www\.qbitai\.com/2026/[^"]+)"[^>]*>[^<]+</a>' "$file" 2>/dev/null | \
        grep -vE '(热门|加载|关于量子|加入我们|商务合作|扫码)' | \
        head -15
}

# Extract The Verge article titles and URLs from raw HTML
parse_verge() {
    local file="$1"
    python3 -c "
import sys, re
with open('$file', 'r') as f:
    text = f.read()
# Find unique Verge article URLs (article IDs ~925000+ are recent)
seen = set()
for m in re.finditer(r'https://www\.theverge\.com/(?:ai-artificial-intelligence|tech|games|report|policy)/(?:92[5-9]\d{3,4}|93\d{3,4})/[a-z0-9-]+', text):
    url = m.group(0)
    if url not in seen:
        seen.add(url)
        print(url)
" 2>/dev/null
}

# Parse The Verge article meta description
fetch_verge_meta() {
    local url="$1"
    curl -sL --max-time 10 "$url" 2>/dev/null | \
        grep -oE '<meta[^>]*name="description"[^>]*content="([^"]+)"' | \
        sed 's/<meta[^>]*name="description"[^>]*content="//;s/"$//'
}

# Print timestamped header
section_header() {
    local title="$1"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $title"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
