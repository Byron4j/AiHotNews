---
title: Codex Pets：OpenAI 给 Agent 装上"在场感"
date: 2026-05-05
product: Codex Pets
category: DevTool
tags: [openai, codex, agent-ux, skills, pixel-art, pets, hatch-pet]
author: Byron
reading_time: 13 分钟
---

> **TL;DR**
>
> 1. **是什么**：Codex Pets 是 OpenAI 在 5 月 4 日给 Codex 桌面应用上线的**可选动画化同伴**——一个常驻最上层的像素小宠物，用三种状态（运行 / 待审 / 就绪）实时反映你 Agent 线程的进度。
> 2. **为什么火**：上线 24 小时内，社区站点（codex-pets.net、codexpets.app）和 Goku、Clippy、Sam Altman 等自定义形象瞬间刷屏；OpenAI 同步推出"晒宠物赢 ChatGPT Pro 30 天"活动。
> 3. **我的判断**：表面是"玩具"，本质是 **Agent 时代的 UX 范式革新第一形态**——异步 Agent 必须解决"在场感"问题，谁先把这个习惯养成，谁就锁定下一代开发者的桌面。

---

## ⚠️ 同名/相关产品消歧

- 本文讨论的是 **OpenAI Codex 桌面应用** 内置的 Pets 功能（[官方文档：developers.openai.com/codex/app/settings](https://developers.openai.com/codex/app/settings)）。
- 与之**形似而神不似**的 **Anthropic Claude Code "Buddy"**：2026-04-01 上线，2026-04-09 被官方下架（详见对照章节）。
- **Coding Pets**（codingpets.com）、**CodexPets.app**、**Codex Pet Share** 等都是社区衍生站点，非 OpenAI 官方资产。
- 早年的 OpenAI Codex（2021，已弃用的代码补全 API）与本文产品**不是同一个**——本文的是 2025 年底重启的 Codex 产品线。

---

## 一、产品速览卡片

| 字段 | 内容 |
| --- | --- |
| 产品名 | Codex Pets |
| 所属公司 | OpenAI |
| 上线日期 | 2026-05-04（同期更新含 config imports、TUI 增强等）|
| 平台 | Codex 桌面应用，Windows + macOS |
| 产品形态 | 桌面悬浮覆盖层（Floating Overlay）+ 像素动画 + 状态指示器 |
| 内置宠物 | 8 个，含 Codex（默认蓝）、Dewey（鸭子）、Rocky（《Project Hail Mary》梗）、BSOD（蓝屏致敬）等 |
| 自定义机制 | `hatch-pet` 技能（Skill），可基于代码风格 / 上传图片 / 描述生成 |
| 收费 | 免费（包含在 Codex 应用中）|
| 官方活动 | 限时比赛：10 名最受官方青睐的自定义宠物，获 30 天 ChatGPT Pro |

> Codex Pets **不写代码、不参与对话**。它的全部使命就是"被瞄一眼就知道 Agent 在干嘛"。

---

## 二、为什么是现在：行业痛点切入

回想你过去一周用 AI 编码的体验：

- 你让 Codex 跑一个长任务（重构、依赖升级、跑测试套件）
- 你切到浏览器查文档，10 分钟后回来
- 看屏幕：**Codex 是跑完了？卡住了？还是在等我授权一个危险命令？**
- 你不得不切回去看一眼

这就是**异步 Agent（Asynchronous Agent）的"消失感"问题**。

进度条解决不了它——因为 Agent 的进度本质不是线性的，可能在第 3 步突然要你授权一个 `rm -rf node_modules`，也可能在第 7 步因为 API 限流陷入静默重试。

PCWorld 的评测一针见血（[原文](https://www.pcworld.com/article/3131011/i-love-my-new-codex-ai-pet-and-now-i-want-one-in-every-app.html)）：

> "如果你死盯着应用窗口，你能看到 Agent 在等你审批；但只要你切到别的窗口去多任务，你就很容易错过——一个空闲的 Agent 在那儿干瞪眼，时间就这么浪费了。"

业界已经在尝试各种解法：

- **桌面通知**：太突兀，关闭率 80%+
- **Slack/邮件提醒**：跨上下文，注意力打散
- **Dock 角标**：信息密度不够
- **状态行（statusline）**：藏在 IDE 里，切窗就看不见

OpenAI 选了一个**反直觉但可能正确**的答案：**给 Agent 一个具象的"宠物身体"，让它在你桌面任何地方都能被你"瞥见"**。

这背后的设计哲学是：**人脑对"生物体"的注意力优先级高于对"数字 UI"的注意力优先级**——一个会动的小鸭子比一个进度条更容易被你的余光捕捉到。

---

## 三、核心拆解：产品与架构

### 3.1 产品形态：桌面级在场感

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│   你的浏览器                                         │
│                            ┌─────┐                  │
│   你的 IDE                 │ 🐤  │ ←─ Dewey  常驻   │
│                            └──┬──┘   桌面最上层     │
│                               │                     │
│                               ▼                     │
│                        ┌──────────────┐             │
│                        │  正在运行：   │             │
│                        │  npm install │             │
│                        └──────────────┘             │
│                                                     │
│   Slack                                             │
│                                                     │
└─────────────────────────────────────────────────────┘
            (Codex 应用本身可以最小化)
```

宠物**始终位于桌面所有窗口之上**，可拖拽到任意位置。它显示的不是"宠物的心情"，而是**当前 Agent 线程的状态**。

### 3.2 三种状态：极简但够用

| 状态 | 视觉表现 | 含义 |
| --- | --- | --- |
| Running（运行中）| 宠物动作 + 思考气泡显示当前任务 | Agent 正在执行命令 |
| Waiting（等待审批）| 思考气泡内**红色时钟**图标 | Agent 卡在一个需要你确认的命令 |
| Ready（就绪审阅）| 思考气泡内**绿色对勾** | Agent 完成任务，等你 review |

三态设计的简洁是**故意的**——它对应了 Agent 工作流中真正需要"瞥一眼"就能决定下一步的三个分叉。

更妙的是：**宠物可点击**。点击宠物等于在原线程里"回话"，把一个被动状态指示器升级成了**轻量级双向通道**。

### 3.3 技术架构：覆盖层 + 状态机 + 技能系统

```
┌─────────────────────────────────────────────────────┐
│                  Codex Desktop App                  │
│                                                     │
│   ┌─────────────────┐    ┌──────────────────────┐  │
│   │ Agent Thread    │───▶│ Thread State Machine │  │
│   │ (Running task)  │    │ Running/Wait/Ready   │  │
│   └─────────────────┘    └─────────┬────────────┘  │
│                                    │ event           │
│                                    ▼                 │
│   ┌──────────────────────────────────────────────┐  │
│   │       Pet Overlay Renderer (always on top)   │  │
│   │   ┌────────────┐    ┌─────────────────────┐ │  │
│   │   │ Spritesheet│───▶│ Animation State     │ │  │
│   │   │ (pixel art)│    │ + Speech Bubble     │ │  │
│   │   └────────────┘    └─────────────────────┘ │  │
│   └──────────────────────────────────────────────┘  │
│                          ▲                          │
│   ┌──────────────────────┴───────────────────────┐  │
│   │   Skills System                              │  │
│   │   ├── hatch-pet      (生成自定义宠物)         │  │
│   │   ├── 其他官方/社区 skill                     │  │
│   │   └── 用户自定义 skill                        │  │
│   └──────────────────────────────────────────────┘  │
│                                                     │
│   Local Storage: ~/.codex/pets/{pet-id}/           │
│     ├── pet-card.json    (角色卡)                  │
│     └── animations/      (各状态 spritesheets)     │
└─────────────────────────────────────────────────────┘
```

四个关键设计决策：

1. **覆盖层独立于应用窗口**：Codex 主窗口最小化，宠物仍然在
2. **状态由线程状态机驱动**：Agent 状态变化 → 宠物动画 + 气泡变化，不是宠物在轮询
3. **技能系统（Skills）作为扩展点**：`hatch-pet` 就是一个 Skill，OpenAI 把宠物生成做成**可被替换的扩展**而非硬编码
4. **本地化存储**：宠物存于本地 `~/.codex` 目录，方便分享、社区交易

> **博主小注**：Codex 把宠物做成 Skill 而非内置功能，是个被严重低估的信号。这意味着 **OpenAI 在为 Codex 构建一个 Skill Store 经济**。今天是 hatch-pet，明天就可能是 hatch-statusbar、hatch-soundpack——任何"主观体验"都可以变成可分发的 Skill。

### 3.4 hatch-pet 技能：把代码风格变成宠物外观

这是产品最有意思的设计——你的宠物**不是 OpenAI 给你的，而是从你自己的代码里"长"出来的**。

完整工作流：

```bash
# 1. 安装技能
$skill-installer hatch-pet

# 2. 重载技能
# Cmd+K (Mac) / Ctrl+K (Windows) → "Force Reload Skills"

# 3. 召唤宠物（基于最近代码风格）
$hatch-pet create a new pet inspired by my recent projects

# 或：上传一张图（你家狗的照片）
/hatch  # 然后跟随 UI 上传

# 或：直接描述
$hatch-pet create a little goblin coding companion
```

技能内部做了什么（据[官方文档](https://developers.openai.com/codex/app/settings)）：

```
recent commits + code language stats
        ↓
character generation (LLM)
        ↓
pet-card.json (personality, name, color palette)
        ↓
spritesheet generation (image model, multi-state frames)
        ↓
register into Codex client
        ↓
restart Codex → pet ready
```

最妙的彩蛋：**你最近写 Rust 居多，孵出来的宠物大概率是螃蟹（Ferris 致敬）**。这种"代码即角色"的设计，把开发者身份认同直接物化成可分享的资产。

---

## 四、场景实战：典型 Use Case

### 场景 1：长任务后台运行 + 你切窗多任务

**触发**：你让 Codex 跑 `更新所有依赖到最新版本并跑回归测试`。

**执行链路**：
```
你输入 prompt → Codex 启动 Agent 线程 → 你切到 Slack 回消息
        ↓
Agent 跑 npm-check-updates → 宠物：跑步动画 + "checking 24 packages"
        ↓
Agent 准备执行 npm install → 宠物：红色时钟 + "Approve npm install?"
        ↓
你余光瞥见红色时钟 → 一键 Cmd+Tab 回 Codex 审批
        ↓
Agent 跑测试 → 宠物：思考动画 + "running 142 tests"
        ↓
全绿 → 宠物：绿色对勾 + "Ready for review"
```

**价值**：原来需要"周期性切回去看"的焦虑，被压缩成"看到红/绿就动"。

### 场景 2：多 Agent 线程并行

**触发**：高级用户同时跑 3 个 Codex 线程（一个写新功能、一个跑测试、一个查 bug）。

**执行链路**：
```
桌面上 3 只宠物分别绑定 3 个线程：
   🐤 Dewey   → 线程 A：开发新功能（Running）
   🦀 Ferris  → 线程 B：跑回归测试（Waiting，红色时钟）
   👾 Goblin  → 线程 C：查 bug（Ready，绿色对勾）

点击 Ferris → 跳转到线程 B 审批
点击 Goblin → 跳转到线程 C 看结果
```

**价值**：把"窗口管理"从 IDE 搬到桌面级别。**这是 Codex 在为"开发者同时驾驭 N 个 Agent"做铺垫**——这个范式才是 2026 编程的真正变化。

> **判断**：当下宠物只支持单线程绑定，但从架构看（每个 pet 独立 spritesheet + 状态机），多线程多宠物只是产品决策时间问题。如果 OpenAI 不做，社区也会通过 Skill 做出来。

### 场景 3：团队共享自定义宠物

**触发**：团队 Lead 用 hatch-pet 基于公司 Logo 生成了一只"公司吉祥物"宠物。

**执行链路**：
```
Lead 在自己的 Codex 上 hatch 出宠物 → 本地 ~/.codex/pets/acme-mascot/
        ↓
打包目录 → 上传到 codex-pet-share.pages.dev 或团队 Gist
        ↓
团队成员下载 → 解压到自己的 ~/.codex/pets/
        ↓
Settings → Appearance → Pets → 选中 acme-mascot
        ↓
全队桌面上都有同一只小动物 = 一种轻量企业文化资产
```

**价值**：把"开发者身份"延伸到了"团队身份"。**这是任何 SaaS 都梦寐以求但极难做到的——情感粘性**。

---

## 五、生态位与对手

### 5.1 横向对比：Codex Pets vs Claude Code Buddy

[Apiyi.com 的对照分析](https://help.apiyi.com/codex-pets-vs-claude-code-buddy-feature-comparison.html)做了非常清晰的拆解，我在此基础上做提炼：

| 维度 | Codex Pets | Claude Code Buddy |
| --- | --- | --- |
| 厂商 | OpenAI | Anthropic |
| 上线时间 | 2026-05-04 | 2026-04-01 |
| 当前状态 | **持续运营** | **2026-04-09 被官方下架**，仅存在 8 天 |
| 形态 | 8 个内置 + 无限自定义 | 18 个 + 5 个稀有度 |
| 风格 | 桌面像素动画 | 终端 ASCII art |
| 是否参与对话 | **否**（避免干扰）| **是**（情感陪伴）|
| 设计哲学 | 生产力工具（信号导向）| 电子宠物（陪伴导向）|
| 自定义方式 | hatch-pet skill | 收集养成（已开源 MCP 重建）|

**关键洞察**：Buddy 选择了"陪伴"路线，Pets 选择了"信号"路线。**8 天的差距，决定了哪种叙事更经得起企业级用户考验**。

我的分析：Buddy 之所以快速下架，可能不是因为产品差，而是它**让 Agent 更"萌"了，但没有解决任何工作流问题**。在 ToB 语境里，"可爱"是减分项。OpenAI 学聪明了——把可爱当壳子，把 UX 真问题（异步在场感）当核。

### 5.2 纵向位置：Codex 的 Skills 生态

```
┌─────────────────────────────────────────────────────┐
│  Codex 应用层                                        │
│  ├── 主对话窗口                                      │
│  ├── 设置 / Permission Profiles                      │
│  └── Pets Overlay  ◀── 由 hatch-pet skill 驱动      │
├─────────────────────────────────────────────────────┤
│  Skills System  ◀── 真正的扩展面                    │
│  ├── hatch-pet           （生成宠物）                │
│  ├── OpenAI Docs         （内置文档）                │
│  ├── 第三方 skills       （未来 Skill Store）        │
│  └── 用户自定义 skills   （本地）                    │
├─────────────────────────────────────────────────────┤
│  Codex Agent Engine                                 │
│  ├── MultiAgentV2        （多智能体）                │
│  ├── Permission System   （沙箱 + 审批）             │
│  └── External Agent Import （新增 config imports）  │
├─────────────────────────────────────────────────────┤
│  GPT-5.5 / gpt-image-2 / 模型层                     │
└─────────────────────────────────────────────────────┘
```

值得注意的是：本次更新除了 Pets，**最有战略意义的其实是 [config imports](https://www.testingcatalog.com/openai-adds-animated-pets-and-config-imports-to-codex/)**——可以从其他工具（暗指 Claude Code、Cursor）一键导入设置、插件、Agent、项目配置。

**Pets 是糖衣，config imports 是炮弹**。这两件事一起出现绝非巧合：**OpenAI 在用情感钩子 + 迁移成本归零，对 Claude Code 用户做正面挖角**。

### 5.3 互补：可以与哪些 Skill 组合

- `hatch-pet` + 团队代码规范 Skill → 全队拥有同样色调的"代码风格宠物"
- `hatch-pet` + 项目元数据 Skill → 不同 repo 切换时宠物自动变身
- 未来可能的 `pet-soundpack` Skill → 给宠物加音效（Slack 风格的 ding）

---

## 六、博主点评：机会、风险与窗口

我得旗帜鲜明地说：**这不是一个"可爱小功能"，这是 Agent UX 的关键里程碑**。但同时它也有非常具体的局限。

### ✅ 它解决得好的

- **精准命中"异步 Agent 在场感"这个真痛点**：进度条、通知、Dock 角标全都试过了，宠物是第一个让"瞥一眼"成本接近零的方案
- **三态设计的克制**：没有炫技搞 10 种状态，就是 Running/Wait/Ready——**对应了 Agent 工作流真正的决策分叉**
- **把扩展性做成 Skill**：不内置、不绑定，意味着 OpenAI 把"主观体验设计"开放给社区。**这是 Skill Store 经济的第一块多米诺骨牌**
- **同步推 config imports**：用情感钩子掩护商业意图——挖 Claude Code 用户。**这是产品策略教科书级操作**
- **从 Buddy 8 天下架中学到了正确教训**：可爱必须服务于 UX，而非反过来

### ⚠️ 它现在还薄弱的

- **单线程绑定**：今天只能给当前线程一只宠物。多 Agent 并行场景（前面场景 2）还没有官方支持
- **可访问性（Accessibility）盲区**：色盲用户看红/绿状态怎么办？盲人用屏幕阅读器怎么用？官方文档里没看到说明
- **企业部署阻力**：在严肃的金融/医疗 IT 部门，"桌面常驻动画"很可能被列入禁用清单。OpenAI 还需要拿出"企业模式（关闭装饰元素，保留状态指示）"
- **像素艺术审美门槛**：不是所有开发者都喜欢 8-bit 风格。一旦审美疲劳，留存会陡降
- **Skill 安全模型不透明**：`hatch-pet` 是官方的，但未来的第三方 Skill 一旦能改宠物动画，能不能在动画里钓鱼诱导？这块需要明确的 Skill 沙箱

### 🎯 12 个月内的关键看点

1. **多线程多宠物**会不会作为正式特性出现——这是判断 OpenAI 是否真把"驾驭 N 个 Agent"当严肃 use case 的试金石
2. **Skill Store 是否启动**——如果 hatch-pet 之后还有 5+ 官方/合作 Skill 上线，意味着 Codex 走 App Store 化路线
3. **企业模式是否推出**——决定 Codex 能不能拿下 Fortune 500 客户
4. **竞品反应**：Cursor、Windsurf、Claude Code（如果它再上 Buddy 2.0）会不会跟进类似设计——大概率会，但**第一吃螃蟹的占领心智红利**
5. **可访问性补丁**：状态指示器是否增加形状/纹理双编码（不仅靠颜色）
6. **是否会出现"宠物市场"**：付费高端宠物、IP 联名（迪士尼宠物、漫威宠物）——OpenAI 自己不做，社区也会做

---

## 七、行动建议（按角色）

### 👨‍💻 如果你是开发者

- **立刻 hatch 一只**：基于最近 7 天代码生成一只宠物，体验"代码 → 角色"这个隐性的身份化过程
- **用多窗口环境刻意测试**：把 Codex 最小化、切到浏览器/Slack，验证宠物在你余光中的可感知度（这是产品的核心价值）
- **关注 Skill 系统**：别只把 hatch-pet 当玩具，**去研究它是怎么注册到 Codex 的**——这套 Skill 机制会是未来 Codex 生态的入口
- **如果你是 Rust/Go/Python 开发者**：试试看会孵出什么，社区已经在收集"语言 vs 宠物形态"的对照表

### 🧠 如果你是 AI PM

- **把"Agent UX 三态"作为你产品的设计语言**：Running / Waiting / Ready 这三态，可以无差别套到任何异步 Agent 产品上。**今天就更新你的设计 spec**
- **审视你产品的"在场感"**：用户在你 Agent 跑后台任务时，能不能"瞥一眼"知道状态？如果不能，你输给的不是 Codex，是**用户的注意力预算**
- **重新评估"装饰元素"的产品价值**：行业过去 5 年都在反对"无意义动画"，但 Codex 证明了**当动画绑定了功能信号，它就不再是装饰**
- **学 OpenAI 的双轨发布**：Pets（情感）+ config imports（迁移）——把硬商业战术包在软体验里，是高段位玩法

### 💰 如果你是创业者 / 投资人

- **创业者**：Codex Pets 的 Skill 机制开启了"AI 应用插件经济"的实证。**机会在 Skill 而非宠物**——你能不能做出第一个让开发者愿意付费的 Codex Skill？想象 GitHub Marketplace 在 Codex 内的样子
- **创业者（衍生）**：宠物社区站点（codex-pets.net、codexpets.app）今天还是用爱发电，**它们会很快需要变现路径**——付费宠物、IP 联名、训练自定义模型——这是个有明确热度的微赛道
- **投资人**：观察 Codex 是否在 12 个月内推出 Skill Store 货币化。如果是，OpenAI 在 Codex 这条线上是要做 GitHub-level 的开发者平台，估值锚点会从 ChatGPT 拆出来重估
- **战略观察**：Pets + config imports 的组合拳意味着**OpenAI 进入了"挖竞品用户"的攻势期**。Anthropic、Cursor 接下来 6 个月会被显著挤压，留意它们的反击节奏

---

## 八、参考来源

**官方一手**
- [Codex 设置文档（Pets 章节）](https://developers.openai.com/codex/app/settings)
- [Codex 应用主页](https://developers.openai.com/codex/app)
- [Codex Changelog](https://developers.openai.com/codex/changelog)
- [Codex GitHub Releases](https://github.com/openai/codex/releases)

**第三方分析**
- [Dataconomy：OpenAI Adds Codex Pets Animated Overlay To Coding Tool](https://dataconomy.com/2026/05/04/openai-adds-codex-pets-animated-overlay-to-coding-tool/)
- [Engadget：OpenAI introduces AI-generated pets for its Codex app](https://www.engadget.com/2162796/openai-introduces-ai-generated-pets-for-its-codex-app/)
- [TechBriefly：OpenAI launches Codex Pets to track coding progress in real-time](https://techbriefly.com/2026/05/04/openai-launches-codex-pets-to-track-coding-progress-in-real-time/)
- [TestingCatalog：OpenAI adds animated Pets and config imports to Codex](https://www.testingcatalog.com/openai-adds-animated-pets-and-config-imports-to-codex/)
- [PCWorld：I love my new Codex AI pet — and now I want one in every app](https://www.pcworld.com/article/3131011/i-love-my-new-codex-ai-pet-and-now-i-want-one-in-every-app.html)
- [Digital Trends：OpenAI's Codex now has a tiny AI pet](https://www.digitaltrends.com/computing/openais-codex-now-has-a-tiny-ai-pet-that-keeps-you-updated-while-you-code/)
- [Cybernews：OpenAI's Codex introduces AI pets to help developers vibe-code](https://cybernews.com/ai-news/openai-codex-pets-vibe-code/)
- [Technobezz：OpenAI Launches Codex Pets with Pixel Art Companions](https://www.technobezz.com/news/openai-launches-codex-pets-with-pixel-art-companions-and-custom-creator-tool)
- [AlternativeTo：Codex launches animated Pets](https://alternativeto.net/news/2026/5/codex-launches-animated-pets/)

**对比研究**
- [Apiyi.com：Codex Pets 与 Claude Code Buddy 完整对比（中文）](https://help.apiyi.com/codex-pets-vs-claude-code-buddy-feature-comparison.html)

**社区生态**
- [codingpets.com](http://codingpets.com/)
- [codex-pets.net](https://codex-pets.net/)
- [codexpets.app](https://www.codexpets.app/)
- [Codex Pet Share](https://codex-pet-share.pages.dev/)

---

> **Update Log**
> - 2026-05-05：首发。8 个内置宠物名称仅确认 4 个（Codex / Dewey / Rocky / BSOD），其余 4 个名称来自官方应用 Settings → Appearance → Pets，本文未独立验证。Claude Code Buddy 的 18 种 / 5 稀有度数据来自 Apiyi.com 二手分析，未与 Anthropic 官方公告交叉验证。如出现新证据，将在此追加。
