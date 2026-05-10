#!/bin/bash
# format-publish.sh — Convert daily Markdown post to platform-specific formats
# Usage: ./scripts/format-publish.sh <post.md> [wechat|zhihu|toutiao|all]
#
# Output files are saved alongside the original post:
#   post-wechat.html   — WeChat 公众号 format
#   post-zhihu.md      — Zhihu-compatible markdown
#   post-toutiao.html  — Toutiao/百家号 rich text

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

POST="${1:-}"
PLATFORM="${2:-all}"

if [ -z "$POST" ] || [ ! -f "$POST" ]; then
    echo "Usage: ./format-publish.sh <post.md> [wechat|zhihu|toutiao|all]"
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
    echo "  → Generating WeChat 公众号 HTML: $output"

    python3 -c "
import sys, re

with open('$input', 'r') as f:
    md = f.read()

# Strip YAML frontmatter
md = re.sub(r'^---.*?---\n', '', md, flags=re.DOTALL)

# Simple markdown → WeChat-safe HTML
def md_to_wechat(text):
    lines = text.split('\n')
    result = []
    in_table = False
    in_code = False
    in_quote = False

    for line in lines:
        # Code block
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

        # Quote
        if line.startswith('> '):
            if not in_quote:
                result.append('<blockquote style=\"border-left:4px solid #1890ff;padding:8px 12px;margin:12px 0;color:#555;background:#f0f7ff;border-radius:0 4px 4px 0;\">')
                in_quote = True
            result.append(line[2:])
            continue
        elif in_quote:
            result.append('</blockquote>')
            in_quote = False

        # Headings
        if line.startswith('## '):
            result.append(f'<h2 style=\"font-size:20px;color:#1a1a1a;margin:24px 0 12px;padding-bottom:8px;border-bottom:2px solid #1890ff;\">{line[3:]}</h2>')
            continue
        if line.startswith('### '):
            result.append(f'<h3 style=\"font-size:17px;color:#333;margin:20px 0 8px;\">{line[4:]}</h3>')
            continue

        # Table (simplified — WeChat supports basic HTML tables)
        if '|' in line and line.strip().startswith('|'):
            if not in_table:
                result.append('<table style=\"width:100%;border-collapse:collapse;margin:12px 0;font-size:14px;\"><tbody>')
                in_table = True
            cells = [c.strip() for c in line.split('|') if c.strip()]
            if all(c.startswith('-') or c.startswith(':') for c in cells):
                continue  # skip separator row
            row_tag = 'th' if not any('<t' in r for r in result[-3:]) else 'td'
            row = ''.join(f'<{row_tag} style=\"border:1px solid #ddd;padding:8px 10px;text-align:left;\">{c}</{row_tag}>' for c in cells)
            result.append(f'<tr>{row}</tr>')
            continue
        elif in_table:
            result.append('</tbody></table>')
            in_table = False

        # Bold/italic
        line = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', line)
        line = re.sub(r'「(.+?)（(.+?)）」', r'<strong>\1（\2）</strong>', line)

        # Horizontal rules
        if line.strip() == '---':
            result.append('<hr style=\"border:none;border-top:1px solid #eee;margin:24px 0;\">')
            continue

        # Links
        line = re.sub(r'\[([^\]]+)\]\(([^\)]+)\)', r'<a href=\"\2\" style=\"color:#1890ff;\">\1</a>', line)

        # Empty lines
        if line.strip() == '':
            result.append('<br>')
            continue

        result.append(f'<p style=\"font-size:15px;line-height:1.8;color:#333;margin:8px 0;\">{line}</p>')

    if in_table: result.append('</tbody></table>')
    if in_quote: result.append('</blockquote>')
    if in_code: result.append('</code></pre>')

    return '\n'.join(result)

html = md_to_wechat(md)

# Wrap in WeChat-safe container
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
    echo "  → Generating 知乎 format: $output"

    cp "$input" "$output"
    # Zhihu supports standard markdown well — minor tweaks
    # Remove code fence language tags (Zhihu ignores them)
    python3 -c "
with open('$output', 'r') as f:
    content = f.read()
# Zhihu uses \`\`\`text not \`\`\`python
content = content.replace('\`\`\`python', '\`\`\`text')
content = content.replace('\`\`\`bash', '\`\`\`text')
# Zhihu doesn't support HTML in tables well — leave as-is
with open('$output', 'w') as f:
    f.write(content)
"
    echo "    Done → $output"
}

# ─── Main ───
case "$PLATFORM" in
    wechat)
        convert_wechat "$POST"
        ;;
    zhihu)
        convert_zhihu "$POST"
        ;;
    all|*)
        convert_wechat "$POST"
        convert_zhihu "$POST"
        ;;
esac

echo ""
echo "  Formatting complete."
echo "  Copy the HTML into the platform's rich text editor."
echo "  WeChat: Open 公众号后台 → 新建图文 → 切换到HTML模式粘贴"
echo ""
