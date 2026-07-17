# Debate-Coach Project

## ⛔ 最高优先级：修改前必须先确认
**对本项目任何文件做任何修改之前，必须先向用户说明要改什么、怎么改、为什么改，等用户明确同意后再动手。** 包括但不限于：编辑 SKILL.md、修改网页、调整协议流程、删除内容、重构章节。禁止"先改再说"。讨论和分析不需要确认，但一碰文件就必须停手等用户点头。

## 🏗️ 开发工作区架构（最高优先级）
**本项目（`Debate-Coach-Backup/`）是唯一开发工作区。所有日常开发、修改、测试、构建在此进行。**

```
Debate-Coach-Backup/          Debate-Coach/
  (开发工作区 ← 当前)           (纯净发布仓库)
  日常所有工作在此              只在稳定版本时更新
                               更新后 commit + push GitHub
```

- **禁止在 `C:/Claude/Project/Debate-Coach/` 修改任何文件** — 那边是纯净发布仓库
- 稳定版本发布流程：Backup 完成 → 打包 handoff → 切换到 Debate-Coach 会话 → 读取 handoff → 更新那边文件 → commit + push
- 对比本地与 GitHub 一致性时，只对比 `Debate-Coach/`（git 仓库）↔ GitHub

## ⛔ 最高优先级：禁止推送 Git
**未经用户明确同意，严禁执行 `git push`、`git commit`、`git tag` 或任何修改 Git 历史的操作。** 只允许只读命令（`git log`、`git diff`、`git status`、`git remote -v` 等）。违反此规则将导致项目不可逆损坏。

## 🔒 最高优先级：受保护目录禁止修改
**`Output/milestone-*-protected/` 及所有里程碑目录中的文件禁止任何修改、删除、覆盖。** 只允许读取、复制到新位置、打开查看。修改保护文件需要用户明确说出"授权修改保护目录"。文件系统已设只读（chmod 444）。

## 🚫 最高优先级：禁止 Python 脚本修改代码
**禁止用任何 Python 脚本（patch_gfl.py、rebuild_en.py、build_zones.py 等）修改 JS/HTML。** 转义层级不可控，已导致循环坏档和 API Token 浪费。唯一安全方式：Edit 工具手改母版 + 浏览器验证 + node 做纯 base64 编码。

## ⛔ 最高优先级：禁止推送到 GitHub 不存在的文件
**同步到 Debate-Coach 发布仓库时，只更新 GitHub 已存在的文件。** GitHub 已明确删除的文件（TERMINOLOGY.md、debate-coach-web-zh.html、debate-coach-web-en.html）禁止重新推送。新增文件需用户逐次明确授权后才能加入 Git 追踪。判断标准：`git ls-tree -r --name-only HEAD` 的输出 = 可更新白名单。

## 📦 APK 打包（每次必读，禁止猜测 JDK 路径）
**JDK 位置（不在 Program Files，在用户目录！）：**
- JDK 17：`C:/Users/Moon/Java/jdk-17.0.16+8`
- JDK 21：`C:/Users/Moon/Java/jdk-21.0.11+10`（当前 capacitor 8.x 需要 21）
- Android SDK：`C:/Users/Moon/AppData/Local/Android/Sdk`

**打包命令：**
```bash
cp Debate-Coach-web.html APK/app/src/main/assets/public/index.html
# 或先 npx cap sync 再复制
cd APK/android
echo "org.gradle.java.home=C:/Users/Moon/Java/jdk-21.0.11+10" >> gradle.properties
export JAVA_HOME="C:/Users/Moon/Java/jdk-21.0.11+10"
./gradlew assembleDebug
# 输出：app/build/outputs/apk/debug/app-debug.apk
```

**禁止**：不要在 `C:\Program Files` 下找 JDK，不在那里。用 `ls /c/Users/Moon/Java/` 直接看可用版本。

## 继承包
- 当前：`Output/handoff-260711/`（v7.6.14，2026-07-11）
- 上一：`Output/handoff-260709/`（v7.6.1，2026-07-09）
- 新 AI 接手时优先阅读 `Output/handoff-260711/快速接手.md`

## 项目来源
继承自 `C:\Claude\Project\BLZJ` 项目，该项目因 token 超出上限无法继续对话后迁移至此。

## 核心资产
- `SKILL.md` — 《辩论筑基》完整知识体系 + 审问协议（v7.4.0）
- `SKILL-EN.md` — 英文版知识库（v7.3.0-en-alpha）
- `debate-coach-web.html` — 三合一网页版（中文版/English BETA/工具箱）
- `Debate-Coach-v7.6.14.apk` — APK 安装包（4.6MB）
- `Output/辩案工作台-Case-Workbench.html` — 辩案工作台独立版
- `Output/软件著作权登记/` — 著作权登记全部材料（v7.6.14）
- `Output/handoff-260711/` — 项目继承包（v7.6.14）
- `Source/` — 原始课件提取、分析文件、早期测试版、V1原版
- `Memory/` — 项目记忆和分析记录
- 协议集成在 `SKILL.md` 第441行（v7）

## 知识来源
《辩论筑基》（精灵·Moon著，2020版+2023Pro版），56个PPTX完整提取。
基于 grill-me（Matt Pocock）审问模式构建。
`Source/all_slides.txt` 为完整课件提取文本。

## 🧹 临时文件纪律（最高优先级）
**`.tmp-*` 文件和 `Output/toolbox-*.html` 是过期缓存，禁止用作工作基础。** 常见错误：用旧版 `Output/toolbox-full-decoded.html`（4工具）覆盖当前 `debate-coach-web.html`（6工具）。

**三合一版工具箱更新标准流程：**
1. 直接从当前 `debate-coach-web.html` 解码 TOOLBOX_B64
2. 替换对应工具的 `_B64` 变量
3. 重新编码写回
4. 中间产物用 `.tmp-*` 前缀，**用完必须立即删除**

```bash
# 标准命令模板（用 node，禁止用 Python 脚本）
node -e "var fs=require('fs'),cwd=process.cwd();
var web=fs.readFileSync(cwd+'/debate-coach-web.html','utf-8');
var m=web.match(/var TOOLBOX_B64=\"([^\"]+)\"/);
var toolbox=Buffer.from(m[1],'base64').toString('utf-8');
// 替换某个 _B64...
var updated=web.replace(/var TOOLBOX_B64=\"([^\"]+)\"/,'var TOOLBOX_B64=\"'+newB64+'\"');
fs.writeFileSync(cwd+'/debate-coach-web.html',updated,'utf-8');"
```

## 工作方式
- 在 Claude Code 中加载 SKILL.md 即可使用纯 Skill 版
- 浏览器打开 debate-coach-web.html 使用网页版（需自备 API Key）
- 协议（v7）集成在 SKILL.md 中


## 术语约束
**复盘或分析辩论比赛时，描述主线形态使用客观术语**：1型主线="有清晰的决胜逻辑"，2型主线="缺乏聚合的决胜锚点"。禁止使用"评委享受""评委痛苦"等主观措辞。结构性交锋的操作使用消化、反转，不用前体系术语"受身"（仅在解释历史概念时加"旧称"标记）。反驳后回应框架使用习惯性交锋/结构性交锋二分，不用前体系四分类"攻守走受"。

**全项目术语标准参见 `TERMINOLOGY.md`**——包含完整旧→新映射表、禁令级别、豁免条件、自检钩子。所有禁令不影响对旧术语的答疑解释（讨论该概念本身时不受限）。

## 知识库修改遍历清单（三轨隔离）

知识库分为三个独立轨道，**互不穿越**——修改哪个轨道的文件，只走该轨道的同步链：

---

### 轨道 A：Claude Code 知识库（SKILL.md / SKILL-EN.md）

**源文件**：`SKILL.md` / `SKILL-EN.md`（根目录）

修改 SKILL.md 或 SKILL-EN.md 后，同步：
1. `.claude/skills/debate-coach/SKILL.md` ← 覆盖（Skill 加载源）
2. `.claude/skills/debate-coach/SKILL-EN.md` ← 覆盖
3. `docs/SKILL.md` ← 覆盖（镜像）
4. `docs/SKILL-EN.md` ← 覆盖（镜像）
5. `C:/Claude/Project/Debate-Coach/SKILL.md` ← 覆盖（GitHub 发布仓库）
6. `C:/Claude/Project/Debate-Coach/SKILL-EN.md` ← 覆盖
7. `C:/Claude/Project/Debate-Coach/docs/SKILL.md` ← 覆盖
8. `C:/Claude/Project/Debate-Coach/docs/SKILL-EN.md` ← 覆盖
9. `CLAUDE.md` ← 如新增项目级约束
10. `TERMINOLOGY.md` ← 如涉及术语变更

**严禁**：修改 SKILL.md 后去碰 `debate-coach-web.html` 或 `评委与复盘AI.html`——它们有自己的知识库。

---

### 轨道 B：网页版教练知识库（Skill-Web.md）

**源文件**：`Skill-Web.md`（根目录）

修改教练教学规则后，同步：
1. `debate-coach-web.html` → B64 解码 → 替换 ZH_B64 中的系统提示词 → 重编码写回
2. `APK/www/index.html` ← 覆盖 `debate-coach-web.html`
3. `APK/android/` → `npx cap sync` → `./gradlew assembleDebug` → 输出 APK
4. 根目录 APK 文件 ← 覆盖
5. `C:/Claude/Project/Debate-Coach/Debate-Coach-web.html` ← 覆盖（GitHub 发布仓库）

**严禁**：修改网页版教练知识库后去碰 SKILL.md——Claude Code 的知识库和网页版的知识库是两套独立系统。

---

### 轨道 C：裁判所分析框架（Skill-Judge.md）

**源文件**：`Skill-Judge.md`（根目录）

修改裁判分析规则后，同步：
1. `Output/评委与复盘AI.html` → Edit 工具手改 `buildSystemPrompt` 函数
2. `debate-coach-web.html` → B64 编码替换 `JUDGE_B64`
3. `APK/www/index.html` ← 覆盖
4. `APK/android/` → `npx cap sync` → `./gradlew assembleDebug` → 输出 APK
5. `Output/评委与复盘AI-final-*.html` ← 覆盖（定版备份）
6. `Output/milestone-*-protected/评委与复盘AI.html` ← 需授权后覆盖
7. `C:/Claude/Project/Debate-Coach/Debate-Coach-web.html` ← 覆盖（GitHub 发布仓库，含更新后的 JUDGE_B64）

**严禁**：修改裁判分析规则后去碰 SKILL.md——裁判所的知识库和 Claude Code 的知识库是两套独立系统。

---

### ⛔ 不动文件
- `Output/milestone-*-protected/`（chmod 444；修改需用户明确授权）
- `Output/软件著作权登记/`（法律文件）
- `Source/`（课件分析原文）
- `翻译备份/`（历史对照）

### 修改方法约束
- 纯文本（SKILL.md 等）：Edit 工具手改
- B64 编码（网页版）：node 解码→替换→重编码（禁止 Python 脚本）
- 验证：每次修改后浏览器打开确认
- 保护版：先 `chmod 644` 解锁，改完 `chmod 444` 恢复