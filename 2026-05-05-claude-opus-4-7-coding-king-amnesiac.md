---
title: Claude Opus 4.7 评测：编码之王与长文本失忆
date: 2026-05-05
product: Claude Opus 4.7
category: LLM
tags: [claude, opus-4-7, model-war, benchmark, coding, long-context]
author:
reading_time: 12 分钟
---

> **TL;DR**
> Anthropic 于 4 月 16 日发布 Claude Opus 4.7，编码能力大幅领先（SWE-Bench Pro 64.3%），视觉分辨率提升 3 倍，但 100 万 token 长上下文召回（MRCR）从 78.3% 暴跌至 32.2%。我的判断：这是 Anthropic IPO 冲刺的「技术强心针」，长文本失忆不是 bug，是路线抉择的代价。

## 同名消歧

本文讨论的 **Claude Opus 4.7** 是 Anthropic 于 2026 年 4 月 16 日发布的旗舰大语言模型（Large Language Model）。为避免混淆，以下实体不在本文讨论范围：

- **Claude.ai**：Anthropic 的聊天网页/应用，运行多种模型（含 Opus 4.7、Sonnet 4.6 等）
- **Claude Code**：Anthropic 的终端 AI 编程助手，默认调用 Opus 4.7 的 `xhigh` 模式（详见本系列第三篇《Claude Code 必知必会》）
- **Claude API**：第三方开发者接入接口，支持 Bedrock、Vertex AI、Azure 等多渠道
- **Claude Mythos**：Anthropic 内部测试的网络安全专用模型，未公开可用

## 一、产品速览卡片

| 字段 | 内容 |
| --- | --- |
| 产品名 | Claude Opus 4.7 |
| 公司 / 团队 | Anthropic（美国旧金山，2017 年成立） |
| 总部 / 国家 | 美国 |
| 前代版本 | Claude Opus 4.6（2026 年 2 月发布） |
| 发布日期 | 2026 年 4 月 16 日 GA；API 默认切换为 4 月 23 日 |
| 官网 | [anthropic.com/claude](https://www.anthropic.com/claude) |
| 一句话定位 | Anthropic 2026 年春季旗舰，编码能力最强但长上下文能力显著退化的「偏科生」 |
| 上线状态 | GA（全面可用） |
| API 定价（输入 / 输出） | $5.00 / $25.00 per million tokens |
| 上下文窗口 | 200K tokens（API）；1M tokens（限时预览，无额外收费） |

## 二、为什么是现在：四月模型大战的硝烟

2026 年 4 月，大模型行业经历了有史以来最密集的发布周期。

4 月 13 日，OpenAI CRO Denise Dresser 的一份内部备忘录被泄露给 The Verge。 memo 中不仅披露了下一代模型代号「Spud」（即后来的 GPT-5.5），还公开质疑 Anthropic 的 300 亿美元年营收「虚增 80 亿」。据多家科技媒体报道，这是两家头部公司首次从「暗斗」升级为「点名互撕」。[[1]](https://letsdatascience.com/blog/openai-sunday-memo-dresser-anthropic-microsoft-spud)

4 月 16 日，Anthropic 放出 Opus 4.7。

4 月 20 日，Moonshot AI 开源 Kimi K2.6（1T 参数，MIT 协议），在 SWE-Bench Pro 上以 58.6% 逼平尚未发布的 GPT-5.5。

4 月 23 日，OpenAI GPT-5.5「Spud」正式上线，距离前代 GPT-5.4 仅六周。

4 月 24 日，DeepSeek V4 Preview 登场，1.6T 参数、1M 上下文、MIT 协议，输入定价 $0.14/M tokens——是 Opus 4.7 的 1/35。

八天之内，四家头部厂商连发四款旗舰。这不是正常的产品迭代节奏，这是 **IPO 前的军备竞赛**。

Anthropic 和 OpenAI 均传出 2026 年下半年 IPO 计划。在估值叙事中，每一分的基准测试（Benchmark）领先、每一美元的营收确认，都直接影响数百亿美金的定价。四月模型大战的本质，是两家公司将技术竞争转化为资本话语权的生死时速。

## 三、核心拆解：Opus 4.7 的技术跃迁与隐性代价

### 3.1 产品形态

Opus 4.7 沿用了 Anthropic 的三档计算模式，但增加了一个新档位：

| 模式 | 适用场景 | 推理深度 |
| --- | --- | --- |
| `low` | 简单问答、聊天 | 最小 |
| `medium` | 常规任务 | 默认 |
| `high` | 复杂分析、代码审查 | 加深 |
| **`xhigh`**（新增） | Agentic 编码、多步骤工具调用 | 最深，Claude Code 默认 |

`xhigh` 是 Opus 4.7 最具产品意义的更新。它不是简单的「再多想一会儿」，而是 Anthropic 首次为 **智能体（Agent）** 场景专门调校的推理档位。在 Claude Code 中，`xhigh` 默认开启，对应本系列第三篇提到的 `/ultrareview` 后台多阶段代码审查能力。

此外，Opus 4.7 引入了 **自适应思考（Adaptive Thinking）**，取代之前的手动「扩展思考（Extended Thinking）」预算。模型根据任务复杂度自行分配推理深度，用户不再需要猜测该选 `high` 还是 `max`。

### 3.2 关键改进：编码、视觉与推理

Opus 4.7 的提升集中在三个维度：编码、视觉、多跳推理。

**编码：从领先到断层领先**

| 基准测试 | Opus 4.6 | Opus 4.7 | 变化 |
| --- | --- | --- | --- |
| SWE-Bench Pro | 53.4% | **64.3%** | +10.9 |
| SWE-Bench Verified | 80.8% | **87.6%** | +6.8 |
| CursorBench | 58% | **70%** | +12 |
| OSWorld-Verified（计算机操作）| 72.7% | **78.0%** | +5.3 |

数据来源：Anthropic 官方公告及第三方评测聚合站 Artificial Analysis。[[2]](https://app.stationx.net/articles/claude-opus-4-7-review)

Cursor CEO Michael Truell 在社交媒体确认，Opus 4.7 在 Cursor 内部 93 任务基准上「将问题解决率提升了 13%」，且解决了 4 个此前 Opus 4.6 和 Sonnet 4.6 均无法完成的任务。[[3]](https://www.dqindia.com/data-and-ai/anthropics-claude-opus-47-launch-transforms-ai-coding-and-visual-tasks-for-everyone-11746197)

10.9 个百分点的 SWE-Bench Pro 提升是什么概念？从 GPT-4 到 GPT-4.5 的同类提升约为 4-5 个百分点。Opus 4.7 在编码赛道拉开了一个身位。

**视觉：从「能看图」到「看得清」**

Opus 4.7 将最大图像分辨率从 1.15 MP 提升至 **3.75 MP**（长边 2,576 像素）。在 XBOW Visual Acuity 测试中，得分从 54.5% 跃升至 **98.5%**——这意味着模型对 UI 截图、工程图纸、医学影像等高密度视觉信息的解析能力发生了质变。

对于 Claude Code 用户，这直接体现在「截图生成代码」的准确率上。一张手机拍的低质量设计稿，Opus 4.6 可能漏掉 1/3 的 UI 细节，Opus 4.7 能还原到像素级。

**多跳推理：Graphwalks 暴涨 20 个点**

Graphwalks（多跳推理基准）从 38.7% 提升至 **58.6%**（+19.9）。这代表模型在「A 影响 B，B 影响 C，C 与 D 的关系是什么」这类链式推理任务上显著增强。对于需要阅读大量代码库、理解跨文件依赖关系的开发者，这是比 SWE-Bench 更贴近日常体验的提升。

### 3.3 那个危险的回归：长上下文失忆

Opus 4.7 并非全面升级。它在长上下文召回上遭遇了一次 **灾难性退化**。

| 基准测试 | Opus 4.6 | Opus 4.7 | 变化 |
| --- | --- | --- | --- |
| MRCR @ 1M tokens | 78.3% | **32.2%** | **−46.1** |
| BrowseComp（网络研究）| 83.7% | **79.3%** | −4.4 |

MRCR（Multi-needle Retrieval in Complex Reasoning）是衡量模型在超长文本中定位特定信息能力的核心测试。1M token 上下文下，Opus 4.6 能找回近 8 成信息，Opus 4.7 只剩 3 成。

这不是小幅波动。46 个百分点的跌幅，意味着如果你把一个大型代码库（比如 50 万行 Python）丢给 Opus 4.7，它可能在第 20 轮对话后「忘记」你最初的要求。对于依赖 Claude Code 进行大规模重构的开发者，这是一个需要严肃对待的警示信号。

Anthropic 官方未在发布博文中重点提及这一退化。第三方评测机构 Artificial Analysis 的独立测试率先暴露了这一数据。[[4]](https://designforonline.com/ai-models/anthropic-claude-opus-4-7/)

**为什么会发生？**

目前业界有两种主要推测：

1. **注意力机制权衡**：为提升编码和多跳推理，模型可能调整了注意力头（Attention Head）的分配策略，将更多容量分配给结构化逻辑推理，而非长距离信息保持。
2. **训练数据分布偏移**：新版本训练语料可能增加了代码和数学比重，减少了长文档（书籍、论文、法律文本）的占比，导致长文本定位能力弱化。

Anthropic 尚未公开回应具体原因。在官方解释出现前，这属于 **未获独立验证的技术推测**。

### 3.4 被忽视的变量：Tokenizer 与隐性成本

Opus 4.7 换用了新版 Tokenizer。据第三方分析，同一文本在新 Tokenizer 下会产生 **1.0–1.35 倍** 的 token 数量。[[5]](https://www.finout.io/blog/claude-opus-4-7-pricing-the-real-cost-story-behind-the-unchanged-price-tag)

这意味着什么？

- 标价未变（$5/$25 per million），但 **实际成本可能上涨 0–35%**
- 1M token 上下文窗口的「实惠感」被稀释——同样长度的文档，现在占用更多 token
- 对于高频 API 调用场景（如 Claude Code 的 agentic 循环），账单膨胀可能比基准测试数字更直接影响用户决策

Finout 的分析报告指出，这种「标价不变、计量单位膨胀」的策略在 SaaS 行业并不罕见，但在 AI API 领域尚属首次。[[5]](https://www.finout.io/blog/claude-opus-4-7-pricing-the-real-cost-story-behind-the-unchanged-price-tag)

## 四、场景实战：什么时候该用 Opus 4.7？

### 场景 1：大规模代码重构（推荐指数：⭐⭐⭐⭐⭐）

**触发条件**：你需要在一个 10 万行以上的代码库中迁移 API、重构模块、或消除技术债。

**执行链路**：

1. 用 Claude Code 打开项目，Opus 4.7 自动以 `xhigh` 模式运行
2. 输入 `/ultrareview` 让模型在后台执行安全、风格、逻辑、测试四阶段审查
3. Opus 4.7 的 Graphwalks 提升使其能追踪跨 5-7 个文件的依赖链
4. 生成补丁（Patch）并应用到本地

**可量化价值**：据 Cursor 内部基准，Opus 4.7 相比 4.6 解决复杂代码任务的成功率提升 13%。在 93 个高难度任务中，4 个「不可能任务」变为「可解决」。

**注意事项**：如果重构涉及阅读整个代码库的历史文档（超过 50 万 token），需警惕 MRCR 退化导致的「上下文失忆」。建议将任务拆分为多个子模块，每次聚焦一个包（Package）。

### 场景 2：UI/设计稿还原（推荐指数：⭐⭐⭐⭐）

**触发条件**：产品经理丢来一张 Figma 截图或手机照片，要求「做出这个页面」。

**执行链路**：

1. 将截图直接粘贴到 Claude Code 或 Claude.ai
2. Opus 4.7 的 3.75 MP 视觉分辨率识别按钮圆角、间距、字体层级
3. 生成 React/Vue/Tailwind 代码，包含响应式断点
4. 如需调整，继续多轮对话迭代

**可量化价值**：XBOW Visual Acuity 从 54.5% → 98.5%，意味着「看错设计稿」的概率从近一半降至接近零。对于前端开发者，这减少了 2-3 轮「返工调像素」的来回。

### 场景 3：百万 token 文档分析（推荐指数：⭐⭐）

**触发条件**：法律合同审查、学术论文综述、大型日志分析。

**执行链路**：

1. 上传 1M token 的 PDF 或日志文件
2. 要求模型提取关键条款、对比多份文件、或定位特定错误

**风险提示**：MRCR @ 1M 仅 32.2%。在 10 次深度问答后，模型可能无法准确定位文档前半部分的细节。对于高stakes 场景（如合同条款审查），建议：

- 使用 Sonnet 4.6（MRCR 保持 78%+）处理长文档
- 或人工拆分文档，每次输入不超过 20 万 token
- 关键结论必须人工复核原文

## 五、生态位与对手：四雄并立的模型战场

### 5.1 横向竞品矩阵（2026 年 4 月旗舰对比）

| 维度 | Claude Opus 4.7 | GPT-5.5 | Kimi K2.6 | DeepSeek V4-Pro |
| --- | --- | --- | --- | --- |
| **SWE-Bench Pro** | **64.3%** | 58.6% | 58.6% | ~53% |
| **MRCR @ 1M** | 32.2% | 未公开 | 未公开 | 未公开 |
| **上下文窗口** | 200K / 1M | 1M | 256K | **1M** |
| **输入定价** | $5.00/M | $5.00/M | ~$0.60/M | **$0.14–$1.74/M** |
| **输出定价** | $25.00/M | $30.00/M | ~$2.50/M | **$0.28–$3.48/M** |
| **协议** | 闭源 API | 闭源 API | **MIT 开源** | **MIT 开源** |
| **发布日期** | 4 月 16 日 | 4 月 23 日 | 4 月 20 日 | 4 月 24 日 |

数据来源：各厂商官方公告及第三方评测聚合。[[2]](https://app.stationx.net/articles/claude-opus-4-7-review)[[6]](https://framia.pro/page/en-US/news/gpt-5-5-vs-claude-opus-4-7)[[7]](https://miraflow.ai/blog/kimi-k2-6-explained-moonshot-ai-open-source-model-ties-gpt-5-5-coding)[[8]](https://simonwillison.net/2026/apr/24/deepseek-v4/)

### 5.2 纵向：在 AI 栈中的位置

Opus 4.7 位于 **基础模型层（Foundation Model Layer）**，向上支撑：

- **应用层**：Claude.ai 聊天、Claude Code 编程助手、第三方 IDE 插件
- **Agent 层**：本系列首篇讨论的 Mindra 等编排器（Orchestrator）需要强大的基础模型作为「Worker」节点的推理引擎
- **协议层**：通过 MCP（Model Context Protocol）向工具层暴露能力

在本系列第三篇《Claude Code 必知必会》中，我们分析了 Claude Code 的四层扩展面（Skills / Hooks / Subagents / Plugins）。Opus 4.7 的 `xhigh` 模式和自适应思考，本质上是将「模型推理能力」产品化为「Agent 执行能力」的关键支撑。没有 Opus 4.7 的编码跃升，Claude Code 的 `/ultrareview` 和 Task Budgets 功能将沦为空壳。

### 5.3 互补与替代

**Opus 4.7 的互补组合**：

- **长文档处理**：搭配 Sonnet 4.6（1M 上下文无额外收费，长文本召回稳定）
- **成本敏感场景**：搭配 DeepSeek V4-Flash（$0.14/M 输入，适合批量分类、摘要）
- **视觉验证**：搭配 Gemini 3.1 Pro（GPQA Diamond 94.3%，科学推理领先）

**Opus 4.7 的替代风险**：

- 如果 Kimi K2.6 或 DeepSeek V4 在后续版本中缩小编码差距，MIT 协议 + 低价的组合将对 Anthropic 的 API 收入构成实质性威胁
- OpenAI 的 GPT-5.5 Pro（$30/$180 per million）虽然昂贵，但在 Terminal-Bench 2.0 上以 82.7% 领先，是终端自动化场景的更强选择

## 六、博主点评：辉煌与隐忧的平衡

**✅ 它解决得好的：**

1. **编码能力的代际差**。64.3% 的 SWE-Bench Pro 不是「略好一点」，是拉开一个身位。对于 AI 编程助手这个 Anthropic 最核心的差异化赛道，Opus 4.7 巩固了护城河。

2. **产品化节奏**。`xhigh`、`/ultrareview`、自适应思考、Task Budgets——这些不是实验室功能，是第一天就在 Claude Code 里可用的产品特性。Anthropic 证明了它能把模型能力转化为开发者体验。

3. **视觉能力的质变**。98.5% 的 XBOW Visual Acuity 让「截图生代码」从玩具变成生产工具。前端开发者的日常工作流将被改写。

**⚠️ 它现在还薄弱的：**

1. **长上下文失忆是结构性退化，不是波动**。46 个百分点的 MRCR 跌幅不可能是训练噪音。Anthropic 选择在发布时淡化这一问题，说明它知道这是代价，但认为编码能力的收益大于长文本的损失。这个判断是否正确，取决于用户场景——对于代码重构是正确选择，对于法律/学术分析是危险选择。

2. **Tokenizer 隐性涨价缺乏透明度**。标价不变但计量单位膨胀，这种策略在用户发现后可能引发信任危机。Anthropic 应当主动披露 Tokenizer 变化对实际成本的影响。

3. **竞争压力被低估**。Kimi K2.6 和 DeepSeek V4 以 MIT 协议 + 1/5 到 1/35 的价格逼近平局性能，开源模型的「足够好用」正在侵蚀闭源模型的定价权。Anthropic 的 $5/$25 定价在 2026 年底可能面临重构压力。

**🎯 12 个月内的关键看点：**

1. **MRCR 能否修复**。如果 Opus 4.8（或 5.0）能同时保持编码优势和恢复长文本能力，Anthropic 将确立不可争议的领先地位。反之，如果退化持续，「用 Sonnet 读长文 + Opus 写代码」的双模型策略将成为用户默认 workaround。

2. **IPO 窗口的叙事战**。Anthropic 需要证明它的技术领先能转化为可持续的定价权，而非被开源模型压缩成「高端小众」。Opus 4.7 的编码优势是论据，Tokenizer 涨价争议和开源压力是反方材料。

3. **Agent 层的绑定深度**。Opus 4.7 的 `xhigh` 模式与 Claude Code 的 tight integration 是一个信号：Anthropic 的护城河不在模型本身，而在「模型 + 工具链 + 开发者工作流」的组合。这种绑定越深，开源替代品的迁移成本越高。

## 七、行动建议（按角色）

- **如果你是开发者**：
  - **立即升级 Claude Code** 到 Opus 4.7，体验 `xhigh` 模式下的编码能力提升。对于日常 CRUD 开发，提升可能不明显；对于复杂重构和跨文件调试，13% 的 Cursor 基准提升值得切换。
  - **长文档场景切换回 Sonnet 4.6**。如果你用 Claude 读论文、审合同、分析日志，1M 上下文的 Sonnet 4.6 在召回稳定性上仍是更优选择。
  - **监控 Token 消耗**。同样的代码库，Opus 4.7 可能产生 1.0–1.35 倍的 token 数。在 Claude Code 的 agentic 循环中，这会被放大。建议先用小规模任务测试账单变化。

- **如果你是 AI PM**：
  - **评估模型路由策略**。不要「All-in Opus 4.7」。按任务类型分流：编码 → Opus 4.7；长文档 → Sonnet 4.6；批量低成本任务 → DeepSeek V4-Flash；科学推理 → Gemini 3.1 Pro。
  - **关注 MRCR 修复进度**。如果你的产品依赖长上下文（如法律 Tech、科研辅助），在 Anthropic 明确修复前，不要向用户承诺「百万 token 精准定位」。
  - **准备多模型 fallback**。开源模型（Kimi K2.6、DeepSeek V4）的性能追赶速度超过预期。在 2026 年 Q3 前，建立至少一条开源模型 fallback 链路。

- **如果你是创业者 / 投资人**：
  - **Anthropic 的估值叙事取决于「编码领先能否持续」**。Opus 4.7 的 SWE-Bench Pro 优势是短期护城河，但 10.9 个百分点的领先是否足以支撑 $30B+ 估值，需要看 GPT-5.6 / Gemini 4 的追赶速度。
  - **开源模型的商业化路径值得关注**。Kimi K2.6（Moonshot）和 DeepSeek V4 选择了 MIT 协议，但它们的盈利模式（API 服务、企业支持、云厂商分成）可能定义下一代 AI 基础设施的经济模型。
  - **IPO 窗口的风险**。如果 Anthropic 和 OpenAI 均在 2026 下半年 IPO，四月模型大战只是序幕。投资者需要区分「真实技术壁垒」和「基准测试军备竞赛的噪音」。MRCR 退化这类「藏不住的问题」在路演中会被放大。

## 八、参考来源

- [1] [OpenAI's Revenue Chief Sent a Sunday Memo. By Monday, It Was Attacking Anthropic, Microsoft, and Its Own Revenue Numbers.](https://letsdatascience.com/blog/openai-sunday-memo-dresser-anthropic-microsoft-spud)
- [2] [Claude Opus 4.7 Review: Everything New in 2026](https://app.stationx.net/articles/claude-opus-4-7-review)
- [3] [Claude Opus 4.7 Review: The Top AI Coding Model of 2026](https://www.dqindia.com/data-and-ai/anthropics-claude-opus-47-launch-transforms-ai-coding-and-visual-tasks-for-everyone-11746197)
- [4] [Anthropic: Claude Opus 4.7 Review | Pricing, Benchmarks & Capabilities (2026)](https://designforonline.com/ai-models/anthropic-claude-opus-4-7/)
- [5] [Claude Opus 4.7 Pricing 2026: The Real Cost Story Behind the "Unchanged" Price Tag](https://www.finout.io/blog/claude-opus-4-7-pricing-the-real-cost-story-behind-the-unchanged-price-tag)
- [6] [GPT-5.5 vs Claude Opus 4.7: Full Benchmark Comparison 2026](https://framia.pro/page/en-US/news/gpt-5-5-vs-claude-opus-4-7)
- [7] [Kimi K2.6 Explained: Moonshot AI's Open-Source Model That Ties GPT-5.5 on Coding (April 2026)](https://miraflow.ai/blog/kimi-k2-6-explained-moonshot-ai-open-source-model-ties-gpt-5-5-coding)
- [8] [DeepSeek V4—almost on the frontier, a fraction of the price](https://simonwillison.net/2026/apr/24/deepseek-v4/)
- [9] [Best AI Models: April + May 2026 Leaderboard (GPT-5.5, Claude Opus 4.7, DeepSeek V4)](https://www.buildfastwithai.com/blogs/best-ai-models-may-2026-leaderboard)
- [10] [DeepSeek V4 Flash 成 OpenClaw 新默认模型（2026.4.24 更新）：成本降 17 倍，Agent 能力全面升级](https://www.cnblogs.com/qiniushanghai/p/19935041)
- [11] [Claude Opus 4.7 Model Specs, Costs & Benchmarks (May 2026)](https://blog.galaxy.ai/model/claude-opus-4-7)
- [12] [Kimi K2.6 vs Claude Opus 4.7：2026 最新旗舰模型深度对比](https://www.cnblogs.com/qiniushanghai/p/19914728)
- [13] [From GPT-5.5 to DeepSeek V4: How Developers Are Building Smarter AI Agents with Multi-Model Routing in 2026](https://aithority.com/machine-learning/from-gpt-5-5-to-deepseek-v4-how-developers-are-building-smarter-ai-agents-with-multi-model-routing-in-2026/)

> **Update Log**
> - 2026-05-05：首发。文中 MRCR 退化原因分析（注意力机制权衡 / 训练数据偏移）为业界推测，未获 Anthropic 官方确认。
> - 2026-05-05：Tokenizer 成本影响数据（1.0–1.35×）来自第三方分析机构 Finout，非 Anthropic 官方披露。
> - 2026-05-05：OpenAI 内部备忘录相关内容综合自多家科技媒体报道，核心事实（Denise Dresser 署名、80 亿美元营收质疑、Spud 代号）待进一步独立验证。
