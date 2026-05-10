---
title: Claude Code 必知必会：被 80% 用户忽略的扩展面
date: 2026-05-05
product: Claude Code
category: DevTool
tags: [anthropic, claude-code, skills, hooks, subagents, plugins, mcp, channels]
author: Byron
reading_time: 18 分钟
---

> **TL;DR**
> 1. **是什么**：Claude Code 是 Anthropic 的终端原生 Agentic 编码工具，SWE-bench Verified **80.8%**，Token 效率比 Cursor 高 5.5×。
> 2. **为什么必知必会**：它真正的护城河不在 LLM，而在 **Skills / Hooks / Subagents / Plugins** 四层扩展面——而 80% 的用户从未碰过其中任何一个。
> 3. **我的判断**：2026 年 3–5 月连发 Plugin Marketplace、Channels、Opus 4.7 三连击，Anthropic 正在把 Claude Code 从"AI CLI"重塑为"开发者平台"。**没用上扩展面，等于只买了车壳没要发动机。**

---

## ⚠️ 同名/相关产品消歧

- **Claude Code**：本文主角，Anthropic 官方的命令行/多端 Agentic 编码工具，文档：[code.claude.com](https://code.claude.com/docs/en/changelog)
- **Claude.ai**：网页/移动端聊天产品，**不是** Claude Code
- **Claude API / Anthropic API**：模型 API，是 Claude Code 的底层依赖之一
- **Claude Agent SDK**（前身 `claude-code` SDK）：把 Claude Code 当库嵌入自己应用的 SDK
- **Claude Code Buddy**：2026-04-01 上线 / 04-09 下架的实验性"电子宠物"，已退役
- **Claude Managed Agents**：2026-04-01 起进入 public beta 的服务端托管 Agent，与 Claude Code 同源不同部署形态

---

## 一、产品速览卡片

| 字段 | 内容 |
| --- | --- |
| 产品名 | Claude Code |
| 公司 | Anthropic |
| 一句话定位 | 终端优先、可深度扩展的 Agentic 编码工具 |
| 主要平台 | macOS / Linux / Windows（Git Bash）+ VS Code / JetBrains / Desktop / Web |
| 当前模型 | Opus 4.7（含 xhigh effort level）/ Sonnet 4.6 / Haiku 4.5 |
| 价格 | $20/月（Pro）/ Max（高额度）/ Team / Enterprise |
| 关键基准 | SWE-bench Verified **80.8%**，Token 效率比 Cursor 高 5.5×；MRCR v2（1M context, Opus 4.6）76% |
| 扩展面 | **Skills / Hooks / Subagents / Plugins** 四层 |
| 官方文档 | [code.claude.com/docs](https://code.claude.com/docs/en/changelog) |

> 性能数据来源：[NxCode 2026 对比评测](https://www.nxcode.io/resources/news/codex-vs-cursor-vs-claude-code-2026)、[Builder.io 评测](https://www.builder.io/blog/codex-vs-claude-code)。

---

## 二、为什么是现在：行业痛点切入

2026 年 3–5 月，Claude Code 连放三个大招：

1. **2026-03-20**：v2.1.80 发布 [Channels](https://code.claude.com/docs/en/channels)（research preview）——MCP 服务器**反向**向 session push 事件
2. **2026-04**：[Plugin Marketplace](https://code.claude.com/docs/en/discover-plugins) 走向成熟，官方 + 社区市场（[buildwithclaude.com](https://buildwithclaude.com/) 收录 508+，[aitmpl.com](https://www.aitmpl.com/plugins/) 收录 340 plugins + 1367 skills）
3. **2026-05**：Opus 4.7 + xhigh effort level 上线，Sonnet 4.6 成默认

**但真正值得讲的不是这些功能，而是它们组合起来揭示的趋势**——Anthropic 的标准化"三连跳"：

```
2024 末    →    MCP（Model Context Protocol）
              连接 AI 与工具/数据的通用标准
2025-10    →    Agent Skills
              可被任何 AI 平台加载的能力模块
2026-04    →    Plugin Marketplace
              把以上一切打包分发的渠道
```

**这是教科书级的"协议→模块→分发"三步走**。每一步都把扩展能力下沉成行业标准。Anthropic 没有像 Cursor 那样去抢"主编辑器"位置，也没有像 Codex 那样去赌"云端异步"——它在做**开发者扩展生态**这件慢但深的事。

而绝大多数 Claude Code 用户的认知还停留在：「我对它说话，它写代码」。

[ofox.ai 的总结](https://ofox.ai/blog/claude-code-hooks-subagents-skills-complete-guide-2026/)很扎心：

> "Claude Code ships with three extensibility layers that most users never touch."

这就是张力所在——**你已经付钱买了一个平台，但你只在用它的聊天框**。

---

## 三、核心拆解：四大扩展层

把 Claude Code 想成一个**洋葱**，从外到内是这样的：

```
┌─────────────────────────────────────────────────────┐
│   外壳：Chat / Plan Mode / TUI                      │ ← 80% 用户停在这里
├─────────────────────────────────────────────────────┤
│   第 1 层：Skills（技能）                           │
│             可重用的提示模板 / 工作流                │
├─────────────────────────────────────────────────────┤
│   第 2 层：Hooks（钩子）                            │
│             25 个生命周期点的确定性脚本              │
├─────────────────────────────────────────────────────┤
│   第 3 层：Subagents（子智能体）                    │
│             独立上下文 + 可指派不同模型              │
├─────────────────────────────────────────────────────┤
│   第 4 层：Plugins（插件）                          │
│             把以上三者打包通过 Marketplace 分发      │
├─────────────────────────────────────────────────────┤
│   底座：MCP（工具）/ Channels（事件）/ 模型层       │
└─────────────────────────────────────────────────────┘
```

我们一层层拆。

### 3.1 Skills：可重用工作流

**Skill 就是一个有元数据的 Markdown 文件**。它告诉 Claude Code"在什么场景做什么事"。

最小例子：

```markdown
---
name: pr-review
description: Run a structured PR review covering security, performance, tests
---

When invoked, do the following in order:
1. Read the diff via `git diff main...HEAD`
2. For each changed file, check:
   - Security: SQL injection, XSS, secrets in code
   - Performance: N+1 queries, unnecessary re-renders
   - Tests: are critical paths covered?
3. Output a structured report with severity tags.
```

存在 `.claude/skills/pr-review.md`，自动获得 `/pr-review` 斜杠命令。

**2026 年的关键变化**（[Claude Code Changelog](https://code.claude.com/docs/en/changelog)）：

- **斜杠命令与 Skills 已统一**——`.claude/commands/` 仍兼容，但 `.claude/skills/` 是推荐位
- 每个 skill 自动获得 `/slash-command` 接口
- `/skills` 现在支持模糊搜索（type-to-filter）

> **判断**：Skills 是四层中最先该掌握的。如果你团队里同样的 Prompt 已经被复制粘贴 3 次以上——那就是该写成 Skill 的信号。

### 3.2 Hooks：在 25 个生命周期点拦截

Hooks 是 Claude Code 最被低估的能力。它们的关键特征是**确定性**——不靠 LLM 理解，靠代码执行。

> "Without hooks, every safeguard depends on the model understanding your instructions. With hooks, you enforce rules at the system level." — [ofox.ai](https://ofox.ai/blog/claude-code-hooks-subagents-skills-complete-guide-2026/)

**最常用的几个事件**：

| 事件 | 时机 | 典型用途 |
| --- | --- | --- |
| `UserPromptSubmit` | 用户提交 prompt 时 | 注入项目规约、阻止敏感请求 |
| `PreToolUse` | 工具调用前 | **核心安全检查点**：阻止 `rm -rf /`、阻止读取 `.env` |
| `PostToolUse` | 工具调用后 | 跑 lint、跑 typecheck、记审计日志 |
| `PermissionRequest` | Claude 请求权限时 | 自动批准白名单、自动拒绝黑名单 |
| `Stop` / `SubagentStop` | Claude 或子智能体结束时 | 强制继续、生成 summary |
| `PreCompact` | 上下文压缩前 | 备份完整对话 |

最小例子（`.claude/settings.json`）：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "/usr/local/bin/block-dangerous-commands.sh"
        }]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "npm run lint --silent || true"
        }]
      }
    ]
  }
}
```

**2026 年的关键变化**：

- `PostToolUse` 现在带 `duration_ms`（工具执行耗时）——可以做性能预算
- `hookSpecificOutput.updatedToolOutput` 允许 hook 改写工具输出（之前只 MCP 能做）
- 修复 `permissions.deny` 不能覆盖 hook 的 `permissionDecision: "ask"` 的 bug
- Windows 走 Git Bash，hooks 跨平台真正可用

> **判断**：Hooks 是把"AI 协作"从"全靠模型自觉"变成"系统级强制"的唯一方式。**任何严肃团队，第一周就该把"禁写 secrets"、"PR 前必跑 lint"做成 hook，而不是写在 CLAUDE.md 里"求"模型遵守。**

### 3.3 Subagents：独立上下文 + 可省钱

Subagent 也是 Markdown 文件 + YAML frontmatter，存 `.claude/agents/`。

**核心价值有两个**：

1. **上下文隔离**：subagent 跑搜索、看日志、做研究，**详细输出留在自己的窗口里**，只有总结回到主会话——主上下文窗口不被污染
2. **成本优化**：可以给 subagent 指派 cheaper 模型（Haiku/Sonnet）做苦工，主对话保留 Opus 做推理

最小例子：

```markdown
---
name: log-investigator
description: Search logs for the root cause of a given error
model: haiku  # 用便宜模型跑
tools: [Read, Grep, Glob, Bash]
---

When given an error message:
1. Find recent log files
2. Grep for the error and surrounding context
3. Trace the call stack
4. Return a 200-word summary with file:line references
```

主会话调用：

```
Agent({ subagent_type: "log-investigator", prompt: "Investigate the 502 errors from yesterday" })
```

**2026 年的关键变化**：

- Subagent 的 MCP 服务器**并行**初始化（之前串行，多 server 时启动很慢）
- `CLAUDE_CODE_FORK_SUBAGENT=1` 在非交互模式可用
- 修复了 `model: opus/sonnet/haiku` 在 Bedrock/Vertex/Foundry 静默降级到老版本的 bug
- Ctrl+F 杀所有后台 agent（之前是 ESC×2）

> **判断**：Subagent 是 80% 用户从没用过、但能立刻省钱的能力。**把"翻日志""读大文件""搜代码"这种 grunt work 全部 subagent 化 + 配 Haiku，一个月 token 账单能直接砍 30–50%。**

### 3.4 Plugins：把上述三者打包分发

Plugin = 把 skills / hooks / subagents / MCP servers 打包成一个**可一键安装**的扩展。

**核心模型**：

```
┌──────────────────────────────────────────────────────┐
│  Marketplace（catalog） = 插件目录                   │
│  例：claude-plugins-official、buildwithclaude.com    │
│                                                      │
│  ┌────────┐   ┌────────┐   ┌────────┐               │
│  │ Plugin │   │ Plugin │   │ Plugin │               │
│  │   A    │   │   B    │   │   C    │   ...         │
│  └────────┘   └────────┘   └────────┘               │
│      ↓            ↓            ↓                    │
│   GitHub      GitLab      私有 Git                  │
│   （Plugin 实际寄宿在哪里都行）                       │
└──────────────────────────────────────────────────────┘
```

**关键架构洞察**（[ice-ice-bear 深度拆解](https://ice-ice-bear.github.io/posts/2026-04-03-claude-code-plugin-marketplace/)）：

> "Marketplaces don't HOST plugins. They INDEX them."

Marketplace 只是目录，plugin 可以分布在任意地方。这跟 npm 的理念完全不同。

**安装命令**：

```bash
# 添加官方 marketplace（默认已加）
/plugin marketplace add anthropic-official

# 添加第三方 marketplace
/plugin marketplace add https://github.com/owner/repo

# 安装具体 plugin
/plugin install code-intelligence@claude-plugins-official

# 打开管理面板
/plugin
```

**官方 Marketplace 已收录的集成**：

GitHub、GitLab、Atlassian、Linear、Notion、Figma、Vercel、Supabase、Slack、Sentry，以及 C/C++/Go/Java/Python/Rust/Swift/TypeScript 的 **LSP（语言服务器协议）插件**——后者让 Claude Code 真正具备了"跳转定义""引用查找""类型错误检查"的 IDE 级能力。

**2026 年踩坑提示**（[ice-ice-bear](https://ice-ice-bear.github.io/posts/2026-04-03-claude-code-plugin-marketplace/)）：

> "Relative paths in marketplace.json are a subtle footgun. They work only when users add the marketplace via Git ... If you distribute your marketplace.json via a direct URL, relative paths silently fail to resolve."

构建自家 Marketplace 时**始终用绝对 Git 路径**，不要用相对路径。

> **判断**：Plugin Marketplace 是 Claude Code 真正的"飞轮"。**今天你只是装一个 LSP plugin，下一个季度你可能就在自己写 plugin 卖。**

### 3.5 底座：MCP + Channels（双向通道）

Hooks/Subagents/Skills/Plugins 之上，还有两个底层管道：

| 管道 | 方向 | 状态 |
| --- | --- | --- |
| **MCP（Model Context Protocol）** | Claude → 外部工具 | 稳定 |
| **Channels** | 外部事件 → Claude | research preview（v2.1.80, 2026-03-20）|

[Channels 发布博文](https://www.vibesparking.com/en/blog/ai/claude-code/changelog/2026-03-20-claude-code-2180-channels-mcp-push-messages/)的描述非常精准：

> "The tool that could only speak when spoken to just learned to raise its hand."

Channels 让 MCP 服务器能**主动 push** 消息到 Claude session。研究预览阶段已支持 Telegram、Discord、iMessage。最猎奇的进展：[GitHub issue #15359](https://github.com/openai/codex/issues/15359) 显示 Channels 已与 Codex App Server 实现双向桥接——也就是 **Claude Code 和 Codex 可以在同一个 session 里互相调用**。

**这意味着什么？** 异步开发的范式正在从"你 polling Claude"变成"系统 push Claude"。CI 失败、监控告警、PR 评论等事件可以直接进入 Claude session 让它"代为响应"——你睡觉时它在干活。

---

## 四、场景实战：典型 Use Case

### 场景 1：把项目规约从 CLAUDE.md 升级为系统级 Hook

**痛点**：你在 CLAUDE.md 里写了"不要直接修改 main 分支""敏感数据走 .env.example 模板"——但 Claude 经常"忘记"。

**实操**：

```bash
# .claude/hooks/block-main-edit.sh
#!/usr/bin/env bash
input=$(cat)  # hook 从 stdin 读 JSON

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
if [ "$current_branch" = "main" ]; then
  echo '{"permissionDecision": "deny", "reason": "禁止在 main 分支直接修改"}' 
  exit 0
fi
```

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Edit|Write",
      "hooks": [{ "type": "command", "command": ".claude/hooks/block-main-edit.sh" }]
    }]
  }
}
```

**价值**：从"求模型自觉"变成"系统级铁规则"。**Hook 不会幻觉**。

### 场景 2：用 Subagent 把 token 账单砍一半

**痛点**：让 Opus 跑"翻 24 小时的 nginx 日志找 502 根因"，token 飞快烧掉。

**实操**：

```markdown
---
name: log-grunt
description: 翻日志找根因，输出 ≤200 字摘要
model: haiku
tools: [Read, Grep, Glob, Bash]
---
```

主会话只用 Opus 做"读了摘要后的判断"，重活全交给 Haiku subagent。

**价值**：[NxCode 评测](https://www.nxcode.io/resources/news/codex-vs-cursor-vs-claude-code-2026)指出 Claude Code 已经比 Cursor token 效率高 5.5×，**再叠 subagent 优化，对比 Cursor 的成本差距能拉到 10× 量级**。

### 场景 3：用 Channels 做"睡觉时 Claude 替你接 CI 失败"

**痛点**：CI 在凌晨挂了，第二天上班才发现，整个团队被卡住。

**实操**：

```bash
# 1. 启用 Channels（research preview）
claude --channels=ci-webhook

# 2. 配置 plugin（在白名单内的 channel plugin）
/plugin install ci-webhook@claude-plugins-official
```

CI 失败 → webhook → channel push → Claude 自动 read 失败日志 → 生成修复 PR → push 到团队 Discord。

**价值**：异步开发的真正范式。**你的 Claude 在"看着"你的工程系统**。

### 场景 4：把团队 SOP 打包成 Plugin 全员同步

**痛点**：5 个工程师手工配各自的 hooks、skills，配置漂移严重。

**实操**：

```
team-plugin/
├── .claude-plugin/marketplace.json
├── plugins/
│   └── acme-sop/
│       ├── plugin.json
│       ├── skills/
│       │   ├── pr-review.md
│       │   └── deploy-checklist.md
│       ├── hooks/settings.json
│       └── agents/log-grunt.md
```

push 到内部 GitLab → 团队执行：

```bash
/plugin marketplace add git@gitlab.acme.com:platform/team-plugin
/plugin install acme-sop@team-plugin
```

**价值**：从"复制粘贴 SOP"变成"一键装规约"。**研发组织的工程文化第一次有了可分发的载体**。

---

## 五、生态位与对手

### 5.1 横向对比：Claude Code vs Cursor vs Codex CLI

数据综合自 [NxCode 2026](https://www.nxcode.io/resources/news/codex-vs-cursor-vs-claude-code-2026)、[CodeAgentSwarm 2026](https://www.codeagentswarm.com/en/guides/claude-code-vs-cursor-vs-codex)、[Builder.io](https://www.builder.io/blog/codex-vs-claude-code)：

| 维度 | Claude Code | Cursor | Codex CLI / Desktop |
| --- | --- | --- | --- |
| 形态 | 终端 + 多 IDE 扩展 | AI 原生 IDE（VS Code 分叉）| 终端 + 桌面应用 |
| 入门价 | $20/月 | $20/月 | 含在 ChatGPT Plus $20/月 |
| SWE-bench Verified | **80.8%** | — | — |
| Token 效率（同任务）| 33K，无错 | 188K，有错 | — |
| Context | 200K（Opus 4.6 1M beta）| 200K 标称，70–120K 实测 | — |
| 扩展面 | **Skills/Hooks/Subagents/Plugins**（4 层）| Composer + Cursor Rules | Skills（含 hatch-pet 等） |
| 异步能力 | Channels（研究预览）| 无 | 强（云端 VM） |
| 主战场 | 复杂重构、严肃项目、平台扩展 | 快速 daily editing | "开任务、走人"的并行作业 |

**我的判断**：三家走的是**互补**而非互替的路线。

- **Cursor** 押"主编辑器"——速度优先
- **Codex** 押"云端异步"——并行优先
- **Claude Code** 押"终端 + 扩展面"——深度 + 平台优先

**Plugin Marketplace 是 Claude Code 唯一的"长期不可被简单 copy"的护城河**。Cursor 抄 Composer 上手即用的 UX 容易，但要抄一个有 508+ 第三方 plugin 的生态，得有 18 个月的耐心。

### 5.2 纵向位置：扩展协议栈

```
┌────────────────────────────────────────────────────┐
│   Plugin Marketplace（分发层）                     │  ← 2026 新增
├────────────────────────────────────────────────────┤
│   Skills / Hooks / Subagents（行为层）             │  ← 2025–2026 成熟
├────────────────────────────────────────────────────┤
│   MCP（工具协议）+ Channels（事件协议）            │  ← 2024 起 / 2026 新增
├────────────────────────────────────────────────────┤
│   Claude Models（Opus 4.7 / Sonnet 4.6 / Haiku 4.5）│
└────────────────────────────────────────────────────┘
```

注意 MCP **同时**被 Codex、ChatGPT、其他 Agent 框架使用——它已经是 Linux Foundation 旗下 [Agentic AI Foundation](https://akka.io/blog/mcp-a2a-acp-what-does-it-all-mean) 的标准。**Anthropic 把自己的扩展协议捐了出去当行业标准，再用上层产品（Claude Code + Plugin Marketplace）做差异化**。这是高段位玩法。

### 5.3 互补：可以与什么组合

- **Claude Code（深度）+ Cursor（速度）**：最常见的"双工具流"，daily editing 用 Cursor，复杂重构切 Claude Code
- **Claude Code + Codex Desktop**：通过 Channels 跨家协作（已被验证可双向调用）
- **Claude Code + 自家 LSP plugin**：把 Code Intelligence 真正打开，跳转定义/引用/类型检查
- **Claude Code + Channels + 监控**：把 Sentry/Datadog 接成 channel，让 Claude 实时响应告警

---

## 六、博主点评：机会、风险与窗口

我必须旗帜鲜明：**Claude Code 是 2026 年最被低估的开发者平台**。但它也有非常具体的盲区。

### ✅ 它解决得好的

- **扩展面深度业内第一**：四层叠加 + Plugin Marketplace + Channels，没有第二个家做到这个完整度
- **Token 效率 + 模型质量都领先**：5.5× token 节省 + 80.8% SWE-bench，性价比已经无可争议
- **协议捐赠的高段位策略**：MCP 进 Linux Foundation，自己做上层差异化——和苹果做 Webkit / 谷歌做 Android 思路同源
- **Hooks 让 AI 工程化**：第一个把"AI 协作"从"模型自觉"变成"系统级强制"的工具
- **Subagent 直接砍成本**：把 grunt work 配便宜模型，是当下最实在的省钱手段

### ⚠️ 它现在还薄弱的

- **学习曲线陡**：四层扩展 + 几十个事件 + plugin marketplace 自有规则——新手很容易被劝退
- **官方文档分散**：Skills/Hooks/Subagents/Plugins/Channels 文档分散在 [code.claude.com](https://code.claude.com/docs/en/changelog)、GitHub、社区博客之间，没有一个"必读 30 分钟"的入门套件
- **企业版 plugin 安全模型还嫩**：`strictKnownMarketplaces` 是有了，但**没有 plugin 沙箱**——任何 plugin 都能以你的权限执行任意代码。Cursor 的 plugin 体系也有同样问题，但 Cursor 用户习惯了 VS Code 扩展安全风险；Claude Code 用户群体则普遍对此无意识
- **Channels 依赖 claude.ai 登录**：Console / API key 用户用不了——B 端覆盖度还不够
- **使用上限的 7 天周窗口**：高强度日常使用偶尔会撞上 Pro 限额——重度用户必须升 Max

### 🎯 12 个月内的关键看点

1. **Plugin Marketplace 货币化**：是否出现付费 plugin？是否上 marketplace fee？这是判断"开发者 App Store"叙事是否成立的金线
2. **Channels 退出研究预览**：能否进 GA？能否支持 Console / API key 登录？决定企业部署能不能起飞
3. **Plugin 沙箱**：能否加入隔离机制？这是企业入场的硬门槛
4. **Subagent 多模型混用**的标准化：Opus 主 + Haiku 苦工的模式能不能成为"出厂默认"
5. **跨家 Agent 桥接**：Claude Code ↔ Codex 双向调用是临时趣闻还是长期标准
6. **国内适配**：Anthropic 主体目前不直接服务中国，国内是否会有团队基于 Claude Agent SDK 打造类 Claude Code 的产品（已有迹象，需观察）

---

## 七、行动建议（按角色）

### 👨‍💻 如果你是开发者

**第一周必做**：
- 在 `.claude/skills/` 放至少 3 个 Skill（你最常用的 prompt 模板）
- 在 `.claude/settings.json` 配置一个 `PreToolUse` hook 阻止 `rm -rf` 等危险命令
- 在 `.claude/agents/` 加一个 `log-grunt`-style 的 Haiku subagent 跑日志/搜索

**第一月升级**：
- 装 [code-intelligence plugin](https://github.com/anthropics/claude-plugins-official) 打开 LSP——告别"AI 看不到类型错误"
- 浏览 [buildwithclaude.com](https://buildwithclaude.com/) 找到至少 1 个能立刻省时间的社区 plugin
- 试着用 Channels 把 Discord / iMessage 接进来（如果你是 claude.ai 登录用户）

**第一季度突破**：
- 把团队的 SOP 打包成内部 Marketplace，用 Git 私有仓库分发
- 给重度任务（重构、迁移）配 Opus 4.7 + xhigh effort，体验和 Cursor 的差距

### 🧠 如果你是 AI PM

- **先把"扩展面"作为产品设计语言学起来**：Skills/Hooks/Subagents/Plugins 的分层模式可以**无差别套**到任何 Agent 类产品
- **Hook = 你产品里的"系统级守护"**：用户对 Agent 的不信任，根源是"模型自觉"。Hook 是答案
- **重新审视 plugin 经济**：如果你做 Agent 类产品，你 9 个月内一定会面对"用户能不能扩展我"这个问题——提前看 Anthropic 的"协议→模块→分发"三步，避免重新发明
- **关注 Channels 范式**：你的 Agent 是被动响应还是主动接 push？这是 2026 年 Agent 产品最容易拉开差距的点

### 💰 如果你是创业者 / 投资人

- **创业者**：Plugin Marketplace 已经有 1300+ skills，**这就是 npm 早期的样子**。机会在两个层面：
  1. **垂直 Plugin 创业**：做 SRE 团队、安全团队、数据团队的专用 plugin 套装，按 seat 收费
  2. **Marketplace 工具链**：plugin 测试框架、版本管理、私有 marketplace 托管——任何 npm 上有的工具，Claude Code Marketplace 都缺
- **投资人**：观察两个信号
  1. Anthropic 是否把 Marketplace 收入作为独立财务披露——证明它已是战略业务
  2. 是否出现专做 Claude Code Plugin 的种子轮项目（类似当年 npm 周边的小生态创业潮）
- **战略判断**：Anthropic 不打算做"主编辑器"也不打算做"云端 VM 异步"，它选了**最难复制但回报最大的路线——开发者协议+生态**。如果你看好"AI 编程工具最终会平台化"，Claude Code 是当下最接近答案的标的

---

## 八、参考来源

**官方一手**
- [Claude Code 官方文档](https://code.claude.com/docs/en/changelog)
- [Claude Code Channels 文档](https://code.claude.com/docs/en/channels)
- [Plugin Marketplace 文档](https://code.claude.com/docs/en/discover-plugins)
- [Claude Code GitHub 仓库](https://github.com/anthropics/claude-code)
- [Claude Code CHANGELOG](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md)
- [Claude Agent SDK (TypeScript)](https://github.com/anthropics/claude-agent-sdk-typescript/blob/main/CHANGELOG.md)
- [官方 Plugin Marketplace](https://github.com/anthropics/claude-plugins-official)
- [Anthropic 平台 Release Notes](https://platform.claude.com/docs/en/release-notes/overview)

**技术深度**
- [ofox.ai：Hooks/Subagents/Skills 完整指南](https://ofox.ai/blog/claude-code-hooks-subagents-skills-complete-guide-2026/)
- [alexop.dev：Claude Code Full Stack 解析](https://alexop.dev/posts/understanding-claude-code-full-stack/)
- [ice-ice-bear：Plugin Marketplace 深度拆解](https://ice-ice-bear.github.io/posts/2026-04-03-claude-code-plugin-marketplace/)
- [Vibe Sparking：Channels v2.1.80 Changelog](https://www.vibesparking.com/en/blog/ai/claude-code/changelog/2026-03-20-claude-code-2180-channels-mcp-push-messages/)
- [blakecrosley.com：Claude Code CLI 完整指南](https://blakecrosley.com/guides/claude-code)

**评测对比**
- [NxCode：Codex vs Cursor vs Claude Code 2026](https://www.nxcode.io/resources/news/codex-vs-cursor-vs-claude-code-2026)
- [Builder.io：Codex vs Claude Code](https://www.builder.io/blog/codex-vs-claude-code)
- [CodeAgentSwarm：Honest Comparison 2026](https://www.codeagentswarm.com/en/guides/claude-code-vs-cursor-vs-codex)

**社区生态**
- [buildwithclaude.com（508+ 扩展）](https://buildwithclaude.com/)
- [claudemarketplaces.com（社区目录）](https://claudemarketplaces.com/)
- [aitmpl.com（340 plugins + 1367 skills）](https://www.aitmpl.com/plugins/)
- [awesome-claude-code（GitHub 精选）](https://github.com/hesreallyhim/awesome-claude-code)

**跨家协作**
- [GitHub Issue：Claude Code Channels ↔ Codex App Server 双向桥](https://github.com/openai/codex/issues/15359)

---

> **Update Log**
> - 2026-05-05：首发。SWE-bench 80.8%、Token 效率 5.5×、MRCR v2 76% 等性能数据来源于第三方评测，非 Anthropic 官方公告。Plugin Marketplace 总数（508+ / 340 / 1367）为各社区站点自报数据，未独立验证。Channels 仍处于 research preview，使用条件可能变化。如出现重大版本更新或数据修订，将在此追加。
