# AGENTS.md

## Trigger command: `输出今日内容`

When the user says **"输出今日内容"** , execute the full pipeline in one shot:

1. **Research** — Fetch AI news from qbitai.com (WebFetch) + The Verge/overseas sources (curl via ClashX Pro proxy). Cover both previous-day late-breakers and current-day morning releases.
2. **Write** — Generate `YYYY-MM-DD-daily-ai-hotspots.md` following the daily hotspots format. Comply with all editorial guidelines.
3. **Format** — Run `bash scripts/format-publish.sh <post.md> all` to generate WeChat (HTML), Zhihu (MD), 小红书 (TXT), CSDN (MD), 掘金 (MD).
4. **Push** — `git add . && git commit -m "daily: YYYY-MM-DD AI hotspots" && git push`

Do all four steps without pausing. Do NOT just write the markdown — the platform files must exist too.

## Before anything else

Read `editorial-guidelines.md` — it is the "constitution" of this blog. Every post must comply.

## What this repo is

A Chinese-language (简体中文) AI industry blog. Pure Markdown content — no build system, no tests, no linters.

## Post types (choose the right one)

Three distinct formats, each with different structure:

| Type | Template | Naming |
|------|----------|--------|
| **Deep-dive** | 8-module structure (§3 of guidelines) | `YYYY-MM-DD-{product}-{slug}.md` |
| **Daily hotspots** (日报) | 热点速览 table + 热点详解 sections | `YYYY-MM-DD-daily-ai-hotspots.md` |
| **Investment direction** | Macro analysis + sector tables | `YYYY-MM-DD-investment-direction.md` |

Study at least one existing post of the target type before writing.

## Frontmatter (YAML)

All posts require: `title`, `date`, `product`, `category`, `tags`, `author`, `reading_time`.

Valid categories: `Agentic`, `LLM`, `DevTool`, `Multimodal`, `Infra`, `Application`, `Daily`.

## Hard rules an agent is likely to miss

- **Slug = 3–6 English words describing the thesis, not the product name.** Example: `mindra-agentic-team-orchestrator` not `mindra`.
- **TL;DR is required** — 3 sentences: what / why it's hot / your judgment. Must stand alone.
- **Fact-check 5 red lines** (§5 of guidelines): ≥2 independent sources per core fact, verify against official website, use absolute dates (never "recently"), all links must work, resolve product name collisions.
- **Banned words**: 万能, 颠覆一切, 革命性, 史上最强, 王炸, 炸裂. Use concrete scenarios instead.
- **Emoji**: Only ✅ ⚠️ 🎯 and only in the 博主点评 section.
- **Every post must end with an Update Log** (`> **Update Log**` with dates).
- **First occurrence of key terms**: use 「中文（English）」format (e.g. 编排器（Orchestrator）). Expand abbreviations on first use.
- **Write in short sentences** — one idea per sentence, ≤25 characters on average.

## Editorial priorities — sources to track closely

When compiling daily hotspots, prioritize and seek first-hand overseas sources for these entities:

- **Anthropic** — Claude model updates, safety/interpretability research, API changes, Claude Code releases
- **OpenAI** — model releases (GPT-x), API updates, voice/agent products, governance/legal developments
- **Musk / xAI / SpaceXAI** — Musk-Altman lawsuit, SpaceXAI developments, Colossus datacenter, Terafab
- **DeepSeek, Kimi (Moonshot), 百度, 阿里千问** — major Chinese AI players with rapid release cycles

Target overseas sources directly (The Verge, TechCrunch, CNBC, The Information, official blogs) when they are within allowed domains. Do not rely solely on Chinese-aggregated coverage for these core entities.

## Daily research workflow

When compiling daily hotspots, always cross-reference from overseas mainstream platforms:

- **x.com (Twitter)** — official announcements, researcher posts, breaking news from AI labs and key figures
- **Reddit** — r/MachineLearning, r/singularity, r/LocalLLaMA for community reactions and first-hand discoveries
- **YouTube** — keynote talks, product demos, technical deep dives from major AI conferences and announcements
- **Official blogs** — Anthropic, OpenAI, Google DeepMind, DeepSeek, Kimi, 百度, 阿里千问

Aggregate information from both the *previous day* (late-breaking stories missed in the prior digest) and the *current day* (morning releases). Overseas platforms often break stories during China's nighttime hours.

## Claude Code / web access

`.claude/settings.local.json` controls which domains Claude can fetch. When researching, web access is limited to the domains listed there. Add new domains to this file if a post requires sources from sites not on the allowlist. For the priority entities above, ensure `.claude/settings.local.json` includes their official domains and key news outlets.

## Existing posts live in the root directory

The `posts/`, `_drafts/`, and `quick-takes/` subdirectories described in the guidelines do not exist yet. All published posts are flat in the repo root.

## Daily workflow automation

### Quick start

```bash
# 1. Fetch all sources (via ClashX Pro proxy for overseas)
./scripts/daily-fetch.sh

# 2. Generate the daily post (AI-assisted — do this step with LLM)
#    Output: 2026-MM-DD-daily-ai-hotspots.md in repo root

# 3. Convert to platform formats + commit + push
./scripts/daily-pipeline.sh --continue
```

### Pipeline stages

| Script | Purpose |
|--------|---------|
| `scripts/daily-fetch.sh` | Fetch from qbitai, The Verge, Reddit, etc. Saves raw data to `_data/YYYY-MM-DD/` |
| `scripts/format-publish.sh <post.md> [wechat\|zhihu\|all]` | Convert Markdown to WeChat HTML / Zhihu MD |
| `scripts/daily-pipeline.sh` | Full orchestration: fetch → (AI generate) → format → git push |

### Publishing to platforms

After running `format-publish.sh`:
- **微信公众号**: Open `post-wechat.html`, copy HTML, paste into 公众号后台 → 新建图文 → HTML模式
- **知乎**: Copy `post-zhihu.md`, paste into 知乎文章编辑器
- **小红书**: Copy `post-xiaohongshu.txt`, paste into 小红书 → 发布笔记 (建议添加 AI 相关配图，话题标签已内置)
- **CSDN**: Copy `post-csdn.md`, paste into CSDN Markdown编辑器 → 发布
- **掘金**: Copy `post-juejin.md`, paste into 掘金 Markdown编辑器 → 发布
- **GitHub**: Automatically committed and pushed by `daily-pipeline.sh --continue`

### Remote repository

`git@github.com:Byron4j/AiHotNews.git` — all posts and scripts are pushed here.

### Automation note

The fetch and format steps are fully automated. Content generation (Step 2) requires AI/LLM assistance. The pipeline pauses after Step 1 for AI content generation, then resumes with `--continue` flag for formatting + git push.
