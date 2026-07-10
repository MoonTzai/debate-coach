# Debate-Coach · 《辩论筑基》 · 辩论教练 · AI Grill Skill

Debate-Coach — An AI debate coaching grill skill grounded in the *Debate Universal Grammar (辩论筑基)* system.

> **声明**：本工具仅供技术学习使用。用户须自行承担使用 API 产生的全部法律及费用风险。
>
> **Disclaimer**: This tool is provided for technical learning purposes only. Users are solely responsible for all legal and cost risks arising from API usage.

---

> 本 skill 的审问模式基于 [grill-me](https://github.com/mattpocock/grill-me)（Matt Pocock / Total TypeScript）构建，感谢 Matt Pocock 的开创性工作，也感谢王伯元学弟分享启发 grill-me 在辩论中的应用、并主力完成iOS端APP的开发工作。

> The questioning protocol is built on [grill-me](https://github.com/mattpocock/grill-me) by Matt Pocock (Total TypeScript). Deep gratitude to Matt for his pioneering work, and to 王伯元 for sharing the inspiration to apply grill-me to debate and for leading the iOS app development.

---

基于《辩论筑基》（精靈Moon著，2020版+2023Pro版，56课件+SmartArt全量提取）全套理念、知识体系与操作框架的 AI 辩论教练式问答 skill。

An AI debate-coaching skill grounded in the full conceptual framework, knowledge system, and operational methods of *Debate Universal Grammar* (精靈Moon, 2020 edition + 2023 Pro edition, 56 courseware files with complete SmartArt extraction).

**自包含**——不需另行学习《辩论筑基》。安装后 AI 即深度理解筑基全部术语与框架，可逐层引导出论、穷举攻防路径、进行结构性交锋分析。

**Self-contained** — no prior study of the source material required. Once installed, the AI has deep knowledge of all DUG terminology and frameworks: it can guide case construction step by step, exhaust attack-defense pathways, and conduct structural clash analysis.

---

### ⚠️ 重要声明 / Important Disclaimer

**本 Skill 的回答基于 AI 学习《辩论筑基》课件（而非视频讲解），与精灵的理解和本意必然存在错漏偏差，知识性内容请以精灵的视频讲解为准（Bilibili/YouTube 免费放送），本 Skill 会话内容仅供参考！！！仅供参考！！！仅供参考！！！**

**This skill's responses are produced by AI trained on the Debate Universal Grammar courseware (slides, not video lectures). Discrepancies with the author's understanding and intent are inevitable. For authoritative knowledge, always refer to the video lectures (free on Bilibili/YouTube). Conversations with this skill are for reference only.**

---

## 使用方式 / How to Use

### 网页版 / APP 客户端 / Web Version / APK Client

如果你不想安装任何 AI 客户端，可以直接使用独立网页版（安卓手机用户也可安装网页版封装的 APK，比浏览器打开更为易用）：

If you'd rather not install any AI client, use the standalone web version (Android users can also install the packaged APK, which is more user-friendly than opening in a browser):

用浏览器打开 `debate-coach-web.html`，输入 DeepSeek API Key（从 [platform.deepseek.com](https://platform.deepseek.com) 获取）即可使用。也支持自定义填入第三方 API 地址和模型名（如 GLM-5.2、Kimi、Qwen 等），只要兼容 OpenAI `/v1/chat/completions` 格式（Bearer Token + SSE streaming）即可。注意：部分供应商提供多种接口格式，请选择其 OpenAI 兼容地址填入。网页版/APP客户端内置完整的《辩论筑基》知识体系，支持导出/导入会话记录、深色/浅色主题切换、移动端适配。

Open `debate-coach-web.html` in your browser, enter a DeepSeek API key (get one at [platform.deepseek.com](https://platform.deepseek.com)), and you're ready to go. You can also configure a custom third-party API endpoint and model name (e.g. GLM-5.2, Kimi, Qwen, etc.) — any service compatible with the OpenAI `/v1/chat/completions` format (Bearer Token + SSE streaming) will work. Note: some providers offer multiple API formats — be sure to select their OpenAI-compatible `/v1/chat/completions` endpoint. The web version/APK client has the full DUG knowledge base built in, and supports session export/import, dark/light theme switching, and mobile-friendly layout.

### 全功能完整版 / Full-Featured Complete Version

全功能完整版需安装 AI 客户端并载入本 Skill，与网页版/APP客户端共享同一套《辩论筑基》知识体系和教练逻辑。区别在于 Skill 版嵌入 AI 客户端（Claude Code、Cursor 等）内运行，结合客户端 API 能力，可对本地文件（包括但不限于文稿、视频、音频）进行分析使用，也可结合知识库和 AI 按要求生成文件，适合深度备赛、训练、教学场景。

The Full-Featured Complete Version requires an AI client with this Skill installed. It shares the same DUG knowledge base and coaching logic as the web version/APK client. The difference is that the Skill runs inside an AI client (Claude Code, Cursor, etc.) with full access to the client's API capabilities — it can analyze local files (including documents, video, and audio), and can generate files on demand by combining the knowledge base with AI, making it ideal for deep tournament prep, training, and teaching scenarios.

安装 AI 客户端并安装本 Skill 后，向 AI 输入辩题和持方。Skill 会先确认你的需求（从零出论 / 攻防准备 / 自由问答），然后逐层引导：

Once you've installed an AI client and this Skill, enter a debate topic and your side. The skill will first confirm what you need (case construction / attack-defense prep / Q&A), then guide you layer by layer:

1. **从零出论 / Case Construction**：确认辩题持方 → 选择出论或攻防模式 → 确认赛制（可跳过） → 辩题关键词定义 → 选择切入视角 → 建立标准 → 挖掘价值 → 穷举三类反驳 → 结构性交锋（消化/反转） → 预判主线

   Confirm topic & side → choose case construction or attack-defense mode → confirm format (skippable) → define keywords → choose framing angle → establish criteria → uncover values → exhaust three types of rebuttal → structural clash (absorption/reversal) → anticipate main thread.

2. **备赛攻防 / Pre-tournament Attack-Defense Prep**：两路径——架构攻防（防守自检→对手预判→碰撞防守→主动进攻→决胜推演）或单点攻防（自检→三种反驳穷举→逐类反击→单点整合）。支持传辩/奥瑞冈/BP 三种赛制。

   Two paths: structural prep (self-audit → opponent prediction → defensive fortification → proactive offense → decisive scenario planning) or single-point prep (self-audit → exhaust three rebuttal types → counter each → integrate). Supports traditional Chinese debate, Oregon-style policy debate, and British Parliamentary.

3. **赛后复盘 / Post-match Review**：主线类型判断 → 三维模型得失分析 → 内容深度评估

   Identify main-thread type → analyze gains/losses via the three-dimensional judging model → assess content depth.

4. **自由问答 / Q&A**：无需准备辩题，提出任何辩论相关问题——实战困境、技术选择、策略判断、赛制疑问、训练方法等，基于筑基体系全面解答。

   No debate topic needed — ask any debate-related question: tactical dilemmas, technique choices, strategy judgments, format questions, training methods, etc. Answered comprehensively through the DUG framework.

教练会给出方向选项和推荐，以合作式访谈引导你逐步构建架构。所有交互遵循"术语+白话双轨"原则——使用筑基术语时连带自然语言解释。

The coach provides directional options with recommendations, guiding you through a collaborative interview. All interactions follow the "term + plain-language dual track" principle — every DUG term is accompanied by a natural-language explanation.

### 英文版 / English Version

如需使用英文版，将 `SKILL-EN.md` 安装到对应 AI 客户端即可（安装方式见上方各客户端说明）。英文版覆盖 ~90% 内容，尚在完善中。网页版/APP客户端内置中英文切换，无需额外安装。

For the English version, install `SKILL-EN.md` into your AI client (see installation instructions above for each client). The English version covers ~90% of the content and is still being refined. The web version/APK client has built-in Chinese/English switching — no extra installation needed.

> **请注意**：因教材所限，本 skill 目前仅针对华语辩论进行了调试，对英语辩论完全不适配，而且主流英语辩论和华语辩论流行的一般性辩论也大相径庭，相关英语功能仅供娱乐与参考。完整免费视频课程见 YouTube 和 Bilibili（搜索"辩论筑基"或"精靈Moon"）。
>
> **Please note**: Due to the nature of its source material, this skill is currently calibrated only for Chinese-language debate. It is wholly unsuited to English-language debate, whose mainstream formats differ fundamentally from the generalist style prevalent in Chinese-language debate. Any English-language functionality is for entertainment and reference only. Free video courses are available on YouTube and Bilibili (search "辩论筑基" or "精靈Moon").

---

## 快速安装 / Quick Install

### Claude Code

```bash
mkdir -p .claude/skills/debate-coach
cp SKILL.md .claude/skills/debate-coach/
```

然后 `/reload-plugins` 或重启 Claude Code。调用方式：直接输入辩题和持方即可自动激活，或输入"答疑"进入自由问答模式。也可配置 slash command 后输入 `/debate-coach`。

Then `/reload-plugins` or restart Claude Code. To invoke: type a debate topic and your side, or type `答疑` for Q&A mode. You can also configure a slash command: `/debate-coach`.

### ChatGPT Custom GPT

1. 打开 ChatGPT → Explore GPTs → Create
2. 在 Instructions 字段粘贴 SKILL.md 全文
3. Name: `辩论筑基教练`
4. Description: `基于《辩论筑基》体系的辩论审问教练`

1. Open ChatGPT → Explore GPTs → Create
2. Paste the full text of SKILL.md into the Instructions field
3. Name: `辩论筑基教练`
4. Description: `基于《辩论筑基》体系的辩论审问教练`

注意：ChatGPT 的 Instructions 字段有长度限制。如果超出，可去掉协议部分（从 `# 协议` 开始），只保留知识库（第一卷到第十卷）。协议可在对话开始时手动粘贴。

Note: ChatGPT's Instructions field has a character limit. If you exceed it, remove the protocol section (starting from `# 协议`) and keep only the knowledge base (Volumes 1–10). You can paste the protocol manually at the start of each conversation.

### Cursor

```bash
mkdir -p .cursor/rules
cp SKILL.md .cursor/rules/debate-coach.md
```

在 Cursor 中，skill 作为 rule 生效。可通过 `@debate-coach` 引用。

In Cursor, the skill takes effect as a rule. Reference it via `@debate-coach`.

### GitHub Copilot

```bash
cp SKILL.md .github/copilot-instructions.md
```

### 通用 / Generic (API / Any LLM)

将 SKILL.md 的内容作为 system prompt 传入即可。例如 OpenAI API：

Use the contents of SKILL.md as the system prompt. Example with the OpenAI API:

```python
import openai
response = openai.ChatCompletion.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": open("SKILL.md").read()},
        {"role": "user", "content": "辩题：在校大学生创业利大于弊还是弊大于利，持方：正方"}
    ]
)
```

---

## 知识覆盖 / Knowledge Coverage

本 skill 内置筑基完整知识体系，十卷覆盖（这里是AI乱总结的，但我不知道怎么改=。=，具体以视频教学为准吧……）：

This skill embeds the complete DUG knowledge system across ten volumes (AI-generated summary — take with salt; refer to the actual video lectures):

| 卷 / Vol. | 内容 / Content |
|-----------|----------------|
| 第一卷 | 世界观与哲学基础（五观念、Burke新修辞学、证明-说服二象性、不协调而获视角2×2网格、戏剧主义）<br>Worldview & philosophical foundations (five core concepts, Burke's New Rhetoric, proof-persuasion duality, perspective-by-incongruity 2×2 grid, dramatism) |
| 第二卷 | 统一语法A→B→C模型（论证本质、三种反驳穷举、对立成因、全谱系统一）<br>Universal grammar A→B→C model (nature of argument, three rebuttal types, opposing causalities, full-spectrum unification) |
| 第三卷 | 环节操作技术（申论/驳论/质询/自由辩）<br>Speech-event techniques (constructive speech, rebuttal, cross-examination, free debate) |
| 第四卷 | 立论架构（讨论范围/标准/价值阶梯/双层结构/三境界）<br>Case architecture (discussion scope, criteria, value ladder, dual-layer structure, three realms) |
| 第五卷 | 主线、总结与结构性交锋（主线/三向总结/消化反转/主线转型）<br>Main thread, summary & structural clash (main thread, three-directional summary, absorption/reversal, main-thread transformation) |
| 第六卷 | 价值系统（真价值vs假价值/上位批判/价值反转/价值表达）<br>Value systems (true vs. false values, higher-order critique, value reversal, value expression) |
| 第七卷 | 出论与备战（三法+进阶/备赛九要素/攻防体系/切战场/受身论）<br>Case-building & tournament prep (three methods + advanced, nine prep elements, attack-defense system, battlefield segmentation, ukemi theory) |
| 第八卷 | 评判、赛制与争议（三维模型/需根解损/合题性/可辩性四层根源）<br>Judging, formats & disputes (three-dimensional model, needs-plan-advantages, topicality, four roots of debatability) |
| 第九卷 | Pro版原理贯通（论点=论证/立论=大论点/逻辑链vs演绎塔/主线终极统一）<br>Pro edition integrative principles (argument = argumentation, case = macro-argument, logic chain vs. deductive tower, ultimate unification of main thread) |
| 第十卷 | 胜负观与元原则<br>Views on winning & losing, and meta-principles |

### ⚠️ 重要声明 / Important Disclaimer

**本 Skill 的回答基于 AI 学习《辩论筑基》课件（而非视频讲解），与精灵的理解和本意必然存在错漏偏差，知识性内容请以精灵的视频讲解为准（Bilibili/YouTube 免费放送），本 Skill 会话内容仅供参考！！！仅供参考！！！仅供参考！！！**

**This skill's responses are produced by AI trained on the Debate Universal Grammar courseware (slides, not video lectures). Discrepancies with the author's understanding and intent are inevitable. For authoritative knowledge, always refer to the video lectures (free on Bilibili/YouTube). Conversations with this skill are for reference only.**

---

## 测试鸣谢 / Acknowledgements

感谢以下朋友的测试与反馈 / Thanks to the following for testing and feedback:

- **王伯元**
- **蒼神幻影**

---

## 许可与署名 / License & Attribution

本 skill 基于《辩论筑基》（精靈Moon著，YouTube & Bilibili 搜索"辩论筑基"或"精靈Moon"可看完整免费视频课程）体系构建。

This skill is built on the *Debate Universal Grammar (辩论筑基)* system by 精靈Moon (free full video courses on YouTube & Bilibili — search "辩论筑基" or "精靈Moon").

- Skill 文件本身 / Skill files: CC BY-NC-SA 4.0（非商业使用 / non-commercial use）
- 《辩论筑基》课件权利归属 / Courseware rights: 精靈Moon
- 使用本 skill 生成的辩论内容如大量复现筑基特有术语与框架，建议标注"基于《辩论筑基》（精靈Moon著）" / When debate content generated with this skill extensively reproduces DUG-specific terminology and frameworks, please attribute: "基于《辩论筑基》（精靈Moon著）"
- 学术引用（Burke新修辞学、Rosch原型理论、Entman框架理论等）遵循学术引用规范 / Academic citations (Burke's New Rhetoric, Rosch's Prototype Theory, Entman's Framing Theory, etc.) follow standard academic practice
