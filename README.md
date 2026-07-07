# Debate-Grill · 《辩论筑基》体系 · 辩论教练式Grill Skill

> **请注意 / Please Note**：本 skill 仅供华语辩论训练，严禁商业用途。完整免费视频课程见 YouTube 和 Bilibili。For Chinese-language debate training only. Non-commercial use only. Free courses on YouTube & Bilibili.

> **本 skill 的审问模式基于 [grill-me](https://github.com/mattpocock/grill-me)（Matt Pocock / Total TypeScript）构建，感谢 Matt Pocock 的开创性工作，也感谢王伯元学弟分享启发 grill-me 在辩论中的应用。**

基于《辩论筑基》（精灵·Moon著，2020版+2023Pro版，56课件+SmartArt全量提取）全套理念、知识体系与操作框架的 AI 辩论教练式问答 skill。

**自包含**——不需另行学习《辩论筑基》。安装后 AI 即深度理解筑基全部术语与框架，可逐层引导出论、穷举攻防路径、进行结构性交锋分析。

### ⚠️ 重要声明

**本 Skill 的回答基于 AI 学习《辩论筑基》课件（而非视频讲解），与精灵的理解和本意必然存在错漏偏差，知识性内容请以精灵的视频讲解为准，本 Skill 会话内容仅供参考！！！仅供参考！！！仅供参考！！！**

## 快速安装

### Claude Code

```bash
mkdir -p .claude/skills/debate-grill
cp SKILL.md .claude/skills/debate-grill/
```

然后 `/reload-plugins` 或重启 Claude Code。调用方式：直接输入辩题和持方即可自动激活，或输入"答疑"进入概念模式。也可配置 slash command 后输入 `/debate-grill`。

### ChatGPT Custom GPT

1. 打开 ChatGPT → Explore GPTs → Create
2. 在 Instructions 字段粘贴 SKILL.md 全文
3. Name: "辩论筑基教练"
4. Description: "基于《辩论筑基》体系的辩论审问教练"

注意：ChatGPT 的 Instructions 字段有长度限制。如果超出，可去掉协议（从 `# 协议` 开始的部分），只保留知识库（第一卷到第十卷）。协议可通过对话开始时手动粘贴。

### Cursor

```bash
mkdir -p .cursor/rules
cp SKILL.md .cursor/rules/debate-grill.md
```

在 Cursor 中，skill 作为 rule 生效。可通过 `@debate-grill` 引用。

### GitHub Copilot

```bash
cp SKILL.md .github/copilot-instructions.md
```

### 通用（API / 任意 LLM）

将 SKILL.md 的内容作为 system prompt 传入即可。例如 OpenAI API：

```python
import openai
response = openai.ChatCompletion.create(
    model="gpt-4",
    messages=[
        {"role": "system", "content": open("SKILL.md").read()},
        {"role": "user", "content": "辩题：在校大学生创业利大于弊，持方：正方"}
    ]
)
```

## 使用方式

安装后，向 AI 输入辩题和持方。Skill 会先确认你的需求（从零出论 / 攻防准备 / 自由问答），然后逐层引导：

1. **从零出论**：确认辩题持方 → 选择出论或攻防模式 → 确认赛制（可跳过） → 辩题关键词定义 → 选择切入视角 → 建立标准 → 挖掘价值 → 穷举三类反驳 → 结构性交锋（消化/反转） → 预判主线
2. **备赛攻防**：两路径——架构攻防（防守自检→对手预判→碰撞防守→主动进攻→决胜推演）或单点攻防（自检→三种反驳穷举→逐类反击→单点整合）。支持传辩/奥瑞冈/BP 三种赛制
3. **赛后复盘**：主线类型判断 → 三维模型得失分析 → 内容深度评估
4. **自由问答**：无需准备辩题，提出任何辩论相关问题——实战困境、技术选择、策略判断、赛制疑问、训练方法等，基于筑基体系全面解答

教练会给出方向选项和推荐，以合作式访谈引导你逐步构建架构。所有交互遵循"术语+白话双轨"原则——使用筑基术语时连带自然语言解释。

### 网页版

如果你不想安装任何 AI 客户端，可以直接使用独立网页版：

用浏览器打开 `debate-grill-web.html`，输入 DeepSeek API Key（从 [platform.deepseek.com](https://platform.deepseek.com) 获取）即可使用。网页版内置完整的《辩论筑基》知识体系，支持导出/导入会话记录、深色/浅色主题切换、移动端适配。

## 知识覆盖

本 skill 内置筑基完整知识体系，十卷覆盖（这里是AI乱总结的，但我不知道怎么改=。=，具体以视频教学为准吧……）：

| 卷 | 内容 |
|----|------|
| 第一卷 | 世界观与哲学基础（五观念、Burke新修辞学、证明-说服二象性、不协调而获视角2×2网格、戏剧主义） |
| 第二卷 | 统一语法A→B→C模型（论证本质、三种反驳穷举、对立成因、全谱系统一） |
| 第三卷 | 环节操作技术（申论/驳论/质询/自由辩） |
| 第四卷 | 立论架构（讨论范围/标准/价值阶梯/双层结构/三境界） |
| 第五卷 | 主线、总结与结构性交锋（主线/三向总结/消化反转/主线转型） |
| 第六卷 | 价值系统（真价值vs假价值/上位批判/价值反转/价值表达） |
| 第七卷 | 出论与备战（三法+进阶/备赛九要素/攻防体系/切战场/受身论） |
| 第八卷 | 评判、赛制与争议（三维模型/需根解损/合题性/可辩性四层根源） |
| 第九卷 | Pro版原理贯通（论点=论证/立论=大论点/逻辑链vs演绎塔/主线终极统一） |
| 第十卷 | 胜负观与元原则 |

### ⚠️ 重要声明

**本 Skill 的回答基于 AI 学习《辩论筑基》课件（而非视频讲解），与精灵的理解和本意必然存在错漏偏差，知识性内容请以精灵的视频讲解为准，本 Skill 会话内容仅供参考！！！仅供参考！！！仅供参考！！！**

## 测试鸣谢

感谢以下朋友的测试与反馈：

- **王伯元**
- **蒼神幻影**

---

## 许可与署名

本 skill 基于《辩论筑基》（精灵·Moon著，YouTube & Bilibili 搜索"辩论筑基"或"精灵Moon"可看完整免费视频课程）体系构建。

- Skill 文件本身：CC BY-NC-SA 4.0（非商业使用）
- 《辩论筑基》课件权利归属：精灵·Moon
- 使用本 skill 生成的辩论内容如大量复现筑基特有术语与框架，建议标注"基于《辩论筑基》（精灵·Moon著）"
- 学术引用（Burke新修辞学、Rosch原型理论、Entman框架理论等）：遵循学术引用规范
