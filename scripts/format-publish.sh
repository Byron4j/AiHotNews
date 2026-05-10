#!/bin/bash
# format-publish.sh — Convert daily Markdown post to platform-specific formats
# Usage: ./scripts/format-publish.sh <post.md> [wechat|zhihu|xiaohongshu|csdn|juejin|all]
#
# Output files are saved alongside the original post:
#   post-wechat.html       — 微信公众号 rich text HTML
#   post-zhihu.md          — 知乎 compatible Markdown
#   post-xiaohongshu.txt   — 小红书 highlight summary (short-form notes)
#   post-csdn.md           — CSDN compatible Markdown
#   post-juejin.md         — 掘金 compatible Markdown

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

POST="${1:-}"
PLATFORM="${2:-all}"

if [ -z "$POST" ] || [ ! -f "$POST" ]; then
    echo "Usage: ./format-publish.sh <post.md> [wechat|zhihu|xiaohongshu|csdn|juejin|all]"
    exit 1
fi

BASENAME="${POST%.md}"
TITLE=$(head -10 "$POST" | grep '^title:' | sed 's/^title: //' | xargs)
SLUG=$(basename "$BASENAME")

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  AI Hot News — Platform Formatter       ║"
echo "║  Post: $SLUG                            ║"
echo "╚══════════════════════════════════════════╝"

# ─── WeChat 公众号 format ───
convert_wechat() {
    local input="$1" output="$BASENAME-wechat.html"
    echo "  → Generating 微信公众号 HTML: $output"

    python3 -c "
import sys, re

with open('$input', 'r') as f:
    md = f.read()

md = re.sub(r'^---.*?---\n', '', md, flags=re.DOTALL)

def md_to_wechat(text):
    lines = text.split('\n')
    result = []
    in_table = False
    in_code = False
    in_quote = False

    for line in lines:
        if line.startswith('\`\`\`'):
            if in_code:
                result.append('</code></pre>')
                in_code = False
            else:
                lang = line[3:].strip() or 'text'
                result.append('<pre style=\"background:#f5f5f5;padding:12px;border-radius:4px;overflow-x:auto;font-size:14px;line-height:1.6;\"><code>')
                in_code = True
            continue

        if in_code:
            result.append(line)
            continue

        if line.startswith('> '):
            if not in_quote:
                result.append('<blockquote style=\"border-left:4px solid #1890ff;padding:8px 12px;margin:12px 0;color:#555;background:#f0f7ff;border-radius:0 4px 4px 0;\">')
                in_quote = True
            result.append(line[2:])
            continue
        elif in_quote:
            result.append('</blockquote>')
            in_quote = False

        if line.startswith('## '):
            result.append(f'<h2 style=\"font-size:20px;color:#1a1a1a;margin:24px 0 12px;padding-bottom:8px;border-bottom:2px solid #1890ff;\">{line[3:]}</h2>')
            continue
        if line.startswith('### '):
            result.append(f'<h3 style=\"font-size:17px;color:#333;margin:20px 0 8px;\">{line[4:]}</h3>')
            continue

        if '|' in line and line.strip().startswith('|'):
            if not in_table:
                result.append('<table style=\"width:100%;border-collapse:collapse;margin:12px 0;font-size:14px;\"><tbody>')
                in_table = True
            cells = [c.strip() for c in line.split('|') if c.strip()]
            if all(c.startswith('-') or c.startswith(':') for c in cells):
                continue
            row_tag = 'th' if not any('<t' in r for r in result[-3:]) else 'td'
            row = ''.join(f'<{row_tag} style=\"border:1px solid #ddd;padding:8px 10px;text-align:left;\">{c}</{row_tag}>' for c in cells)
            result.append(f'<tr>{row}</tr>')
            continue
        elif in_table:
            result.append('</tbody></table>')
            in_table = False

        line = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', line)

        if line.strip() == '---':
            result.append('<hr style=\"border:none;border-top:1px solid #eee;margin:24px 0;\">')
            continue

        line = re.sub(r'\[([^\]]+)\]\(([^\)]+)\)', r'<a href=\"\2\" style=\"color:#1890ff;\">\1</a>', line)

        if line.strip() == '':
            result.append('<br>')
            continue

        result.append(f'<p style=\"font-size:15px;line-height:1.8;color:#333;margin:8px 0;\">{line}</p>')

    if in_table: result.append('</tbody></table>')
    if in_quote: result.append('</blockquote>')
    if in_code: result.append('</code></pre>')
    return '\n'.join(result)

html = md_to_wechat(md)
tmpl = f'''<section style=\"font-family:-apple-system,BlinkMacSystemFont,'Segoe UI','PingFang SC','Hiragino Sans GB','Microsoft YaHei',sans-serif;max-width:680px;margin:0 auto;padding:16px;\">
{html}
</section>'''
with open('$output', 'w') as f:
    f.write(tmpl)
print(f'    Done → $output')
"
}

# ─── 知乎 format ───
convert_zhihu() {
    local input="$1" output="$BASENAME-zhihu.md"
    echo "  → Generating 知乎 Markdown: $output"

    cp "$input" "$output"
    python3 -c "
with open('$output', 'r') as f:
    content = f.read()
content = content.replace('\`\`\`python', '\`\`\`text')
content = content.replace('\`\`\`bash', '\`\`\`text')
with open('$output', 'w') as f:
    f.write(content)
"
    echo "    Done → $output"
}

# ─── 小红书 format (highlight summary) ───
convert_xiaohongshu() {
    local input="$1" output="$BASENAME-xiaohongshu.txt"
    echo "  → Generating 小红书 笔记: $output"

    python3 -c "
import sys, re, textwrap

with open('$input', 'r') as f:
    content = f.read()

# Extract key sections
heading_pattern = re.compile(r'^##\s+(.+)$', re.MULTILINE)
subheading_pattern = re.compile(r'^###\s+(.+)$', re.MULTILINE)
table_row_pattern = re.compile(r'^\|\s*(.+?)\s*\|\s*(.+?)\s*\|$', re.MULTILINE)
bold_pattern = re.compile(r'\*\*(.+?)\*\*')
link_pattern = re.compile(r'\[([^\]]+)\]\([^\)]+\)')

headings = [m.group(1) for m in heading_pattern.finditer(content)]
subs = [m.group(1) for m in subheading_pattern.finditer(content)]

# Build summary
lines = []
lines.append('🤖 AI Hot News 今日速报')
lines.append('')
lines.append('📌 核心主线：')

# Extract TL;DR
tldr_match = re.search(r'> \*\*TL;DR\*\*\s*\n>(.+?)(?:\n\n|\n##)', content, re.DOTALL)
if tldr_match:
    tldr = tldr_match.group(1).strip()
    tldr = re.sub(r'>\s*', '', tldr)
    tldr = re.sub(r'\*\*', '', tldr)
    tldr = tldr[:180]
    lines.append(tldr)
    lines.append('')

# Extract event highlights from the 热点速览 table (first table only)
# Limit to content between 热点速览 and 热点详解 headings
hotspot_section = re.search(r'##\s+一、今日热点速览\s*\n\s*\n(.*?)##\s+二、热点详解', content, re.DOTALL)
if hotspot_section:
    table_text = hotspot_section.group(1)
    table_rows = table_row_pattern.findall(table_text)
    seen = set()
    for event, impact in table_rows:
        event = event.strip()
        # Skip header rows, separators, single-word items, and already seen
        if event in ('事件', '------') or event in seen or len(event) < 6:
            continue
        seen.add(event)
        event = bold_pattern.sub(r'\1', event)
        event = link_pattern.sub(r'\1', event)
        event = event[:55]
        lines.append(f'🔥 {event}')

lines.append('')
lines.append('━' * 30)
lines.append('')

# Industry insights — extract key points from 趋势判断 section
trend_section = re.search(r'##\s+三、趋势判断\s*\n\s*\n(.*?)(?=\n##\s|$)', content, re.DOTALL)
if trend_section:
    trend_text = trend_section.group(1)
    # Extract sub-headings (###) from trend section — these are the key insights
    insight_headers = re.findall(r'^###\s+\d+\.\d+\s+(.+)$', trend_text, re.MULTILINE)
    for h in insight_headers[:4]:
        h = link_pattern.sub(r'\1', h)
        h = bold_pattern.sub(r'\1', h)
        if len(h) > 8:
            lines.append(f'💡 {h[:50]}')
    # If no sub-headings found, extract bold text
    if not insight_headers:
        trend_titles = bold_pattern.findall(trend_text)
        for t in trend_titles[:4]:
            t = link_pattern.sub(r'\1', t)
            if len(t) > 5 and len(t) < 40:
                lines.append(f'💡 {t}')
else:
    for h in headings[1:4]:
        h_clean = link_pattern.sub(r'\1', h)
        if len(h_clean) < 40:
            lines.append(f'💡 {h_clean}')

lines.append('')
lines.append('━' * 30)
lines.append('')
lines.append('📱 关注「AI Hot News」获取每日深度解读')
lines.append('#AI #人工智能 #科技日报 #AIGC')

result = '\n'.join(lines)

with open('$output', 'w') as f:
    f.write(result)
print(f'    Done → $output (小红书笔记上限约1000字)')
"
}

# ─── CSDN format ───
convert_csdn() {
    local input="$1" output="$BASENAME-csdn.md"
    echo "  → Generating CSDN Markdown: $output"

    python3 -c "
import re, datetime

with open('$input', 'r') as f:
    content = f.read()

# Extract frontmatter fields
title = 'AI Hot News'
date = ''
tags = ''
for line in content.split('\n'):
    if line.startswith('title: '):
        title = line.replace('title: ', '').strip()
    if line.startswith('date: '):
        date = line.replace('date: ', '').strip()
    if line.startswith('tags: '):
        tags = line.replace('tags: ', '').strip('[]').strip()

# Strip YAML frontmatter
body = re.sub(r'^---.*?---\n', '', content, flags=re.DOTALL)

# Remove HTML-only elements that CSDN may not support well
body = re.sub(r'<br>', '', body)

# Remove WeChat-specific markers
body = re.sub(r'> \*\*⚠️ 博主提示\*\*.*?(?=\n\n|\n##)', '', body, flags=re.DOTALL)

# CSDN heading: add spaces after # (standard MD)
body = re.sub(r'^##(?=\S)', '## ', body, flags=re.MULTILINE)
body = re.sub(r'^###(?=\S)', '### ', body, flags=re.MULTILINE)

# Fix broken table borders (ensure | at start/end of each table row)
def fix_tables(text):
    lines = text.split('\n')
    result = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.strip().startswith('|') and i+1 < len(lines) and lines[i+1].strip().startswith('|'):
            # In a table block
            result.append(line)
            i += 1
            while i < len(lines) and lines[i].strip().startswith('|'):
                result.append(lines[i])
                i += 1
            continue
        result.append(line)
        i += 1
    return '\n'.join(result)

body = fix_tables(body)

out = body
if date:
    out = f'> 📅 发布于 {date}\n\n' + out
if tags:
    tag_list = [t.strip() for t in tags.split(',') if t.strip()]
    out = out + '\n\n---\n'
    out = out + ' '.join(f'\`{t}\`' for t in tag_list[:6])

with open('$output', 'w') as f:
    f.write(out)
print(f'    Done → $output')
"
}

# ─── 掘金 (Juejin) format ───
convert_juejin() {
    local input="$1" output="$BASENAME-juejin.md"
    echo "  → Generating 掘金 Markdown: $output"

    python3 -c "
import re

with open('$input', 'r') as f:
    content = f.read()

# Extract frontmatter
title = 'AI Hot News'
tags = ''
date = ''
for line in content.split('\n'):
    if line.startswith('title: '):
        title = line.replace('title: ', '').strip()
    if line.startswith('date: '):
        date = line.replace('date: ', '').strip()
    if line.startswith('tags: '):
        tags = line.replace('tags: ', '').strip('[]').strip()

# Strip YAML frontmatter
body = re.sub(r'^---.*?---\n', '', content, flags=re.DOTALL)

# Remove <br> tags (掘金 uses standard MD)
body = re.sub(r'<br>', '', body)

# 掘金 supports GFM well. Add a info header
header = ''
if date:
    header += f'> 📅 {date}\n'
header += '\n'

# Tag line at bottom
tag_list = [t.strip() for t in tags.split(',') if t.strip() and len(t.strip()) > 1]
if tag_list:
    body += '\n\n---\n'
    body += ' | '.join(f'\`{t}\`' for t in tag_list[:8])

out = header + body

with open('$output', 'w') as f:
    f.write(out)
print(f'    Done → $output')
"
}

# ─── Main dispatch ───
case "$PLATFORM" in
    wechat)
        convert_wechat "$POST"
        ;;
    zhihu)
        convert_zhihu "$POST"
        ;;
    xiaohongshu|xhs)
        convert_xiaohongshu "$POST"
        ;;
    csdn)
        convert_csdn "$POST"
        ;;
    juejin|jj)
        convert_juejin "$POST"
        ;;
    all|*)
        convert_wechat "$POST"
        convert_zhihu "$POST"
        convert_xiaohongshu "$POST"
        convert_csdn "$POST"
        convert_juejin "$POST"
        ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Formatting complete. Publish now:"
echo ""
echo "  微信公众号 → $BASENAME-wechat.html"
echo "      后台 → 新建图文 → HTML模式粘贴"
echo ""
echo "  知乎       → $BASENAME-zhihu.md"
echo "      编辑器直接粘贴 Markdown"
echo ""
echo "  小红书     → $BASENAME-xiaohongshu.txt"
echo "      复制文本 → 发布笔记 (可在APP里加配图)"
echo ""
echo "  CSDN       → $BASENAME-csdn.md"
echo "      Markdown编辑器导入"
echo ""
echo "  掘金       → $BASENAME-juejin.md"
echo "      Markdown编辑器导入"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
