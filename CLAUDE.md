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

## 🗂️ 文件关系速查（新会话先读 · 开发基准）

**网页版开发基准**（v9.2.1+：编辑对应真源 → 通过共享 `standalone-pages` / 专用同步脚本写入 `DC_PAGES` → 浏览器回归 → 发布）：

| 基准文件 | 身份 | 对齐状态 |
|---|---|---|
| `debate-coach-web.html` | **正式单文件网页母版 / GH 发布基准**。v9.2.1+ 使用 `DC_PAGES` 可读字符串内嵌 ZH/EN/JUDGE/TOOLBOX/LANG/JUDGE_ENTRY/EXAM 七个完整 HTML；Toolbox 内以 `TOOL_HTML` 内嵌 9 工具×中英，运行时由同源 `iframe.srcdoc` 加载。禁止恢复根部 Base64 + `atob/TextDecoder/document.write` 旧加载链。 | 当前发布线 = v9.2.1 |
| `toolbox.html`（独立壳）+ 13 工具页 | **线上 InfinityFree 专用外置形态**（1MB 限制）；工具页唯一来源 = Backup 根目录（manifest 指纹校验） | ⚠️ 仅线上使用，GH 已撤除 |
| `Output/裁判所2.0.html` | **裁判所青春版单页母版**（发布时同步到 `DC_PAGES.JUDGE`） | 独立真源，发布前由 verify 检查 |
| `Skill-Web.md` | 教练网页（`DC_PAGES.ZH`）知识库源（已含 8 候选重构） | 发布前由 verify 检查 |
| `Skill-Judge.md` | 裁判页对应独立 skill（v9.0.0-Final-B 两轮提示词） | ⚠️ 未与 GH 裁判页对齐，勿当裁判页源 |

**单文件交付铁原则（用户规定）**：GH/下载/本地/APK 必须一文件全功能——正式母版 `DC_PAGES.TOOLBOX` 内的 `TOOL_HTML` 内嵌全部工具（iframe/srcdoc 隔离），不得依赖外部工具页文件。InfinityFree 在线是唯一 1MB 限制例外（保持外置壳+独立页）。

**Agent 单文件交付 Skill 开发基准**：
- `SKILL.md`（合一版，当前 178KB）：Coach 全套知识库 + 阶段 C 青春版裁判所 C1-C11 协议，**Agent 端单文件交付 Skill 的开发基准文件**。四副本（Backup 根 / `Debate-Coach/SKILL.md` / `.claude/skills/debate-coach/` / `Test/.claude/skills/debate-coach/`）哈希一致 = `9b846074`（2026-08-15 术语统一后同步）。旧版 Test 安装副本（195KB，`58334411`，7/21）已归档至 `Output/归档-SKILL-260816/`。
- ⚠️ `Debate-Judge/SKILL.md` 是 Backup 根旧教练基座（无 C 阶段移植）的残留拷贝，勿混用。

## ⛔ 最高优先级：禁止推送 Git
**未经用户明确同意，严禁执行 `git push`、`git commit`、`git tag` 或任何修改 Git 历史的操作。** 只允许只读命令（`git log`、`git diff`、`git status`、`git remote -v` 等）。违反此规则将导致项目不可逆损坏。

## ⛔ 最高优先级：唯一路径与网络纪律（禁止新建任何工作区域）
**本地 Git 工作路径只有 1 个：`C:\Claude\Project\Debate-Coach\`**（唯一 git 仓库，remote=MoonTzai/debate-coach）。**开发工作区只有 1 个：本项目（`Debate-Coach-Backup/`）。**
- 禁止 `git init`、`git clone`、`git worktree`、新建任何其他 git 仓库/工作区/克隆目录
- 禁止新建任何平行工程（APK 唯一工程为 `APK/`）
- 历史遗留仓库（Debate-Grill*/worktree/web-check）已归档至 `Output/归档-Git-260815/`，不得恢复为工作区
- **推送/联网前先跑 `node scripts/proxy.cjs --set`**（自动探测可用代理端口 → 写入 git 全局 → 清除发布仓库 local 残留；`--check` 只探测不修改）
- **网络故障协议**：网络失败时**禁止新建目录、克隆、备用工作区、新仓库、换路径**。固定流程：`node scripts/proxy.cjs --check` 检查代理 → 原路径重试 → 仍失败则停下向用户报告，等待指示
- 与 GH 对比时：**先 `git fetch origin` 再用 `origin/main`**（本地跟踪引用会过期，直接看本地 refs 会误判远程状态——2026-08 已因此误判过一次）

## 🔒 最高优先级：受保护目录禁止修改
**`Output/milestone-*-protected/` 及所有里程碑目录中的文件禁止任何修改、删除、覆盖。** 只允许读取、复制到新位置、打开查看。修改保护文件需要用户明确说出"授权修改保护目录"。文件系统已设只读（chmod 444）。

## 🚫 最高优先级：禁止 Python 脚本修改代码
**禁止用任何 Python 脚本（patch_gfl.py、rebuild_en.py、build_zones.py 等）修改 JS/HTML。** 转义层级不可控，已导致循环坏档和 API Token 浪费。唯一安全方式：Edit 工具手改母版 + 浏览器验证 + node 做纯 base64 编码。

## ⛔ 最高优先级：禁止推送到 GitHub 不存在的文件
**同步到 Debate-Coach 发布仓库时，只更新 GitHub 已存在的文件。** GitHub 已明确删除的文件（TERMINOLOGY.md、debate-coach-web-zh.html、debate-coach-web-en.html）禁止重新推送。新增文件需用户逐次明确授权后才能加入 Git 追踪。判断标准：`git ls-tree -r --name-only HEAD` 的输出 = 可更新白名单。

## 📦 APK 打包（唯一工程 `APK/`，唯一命令 `scripts/package.cjs`）
**唯一工程**：`APK/`（`android/` gradle 工程 + `www/` web 资产 + `capacitor.config.json`）。所有历史残留（根 `android/`、根 `www/`、`APK/app/`、旧安装包等）已归档至 `Output/归档-APK-260815/`，**禁止重建任何平行工程**。

**JDK 位置（不在 Program Files，在用户目录！）：**
- JDK 21：`C:/Users/Moon/Java/jdk-21.0.11+10`（capacitor 8.x 需要 21）
- Android SDK：`C:/Users/Moon/AppData/Local/Android/Sdk`

**唯一命令（全部内含断言，禁止手工删拷）：**
```bash
node scripts/package.cjs --copy-only   # 同步 master → APK/www + 字节/tag 断言（日常同步）
node scripts/package.cjs --gradle      # 同步 + cap copy → gradle 构建 → APK 内提取复核
```
内部流程：先删后拷破 gradle 文件锁 → 字节/tag 断言 → `npx cap copy`（写 `APK/android/app/src/main/assets/public/`，**勿用 cap sync**——会重置 versionCode）→ `gradlew assembleDebug --rerun-tasks`（JAVA_HOME=JDK21 自动设置，破增量缓存）→ 从 APK 提取 `assets/public/index.html` 与 master 逐字节比对。
产物：`APK/android/app/build/outputs/apk/debug/app-debug.apk` → 复制为根目录 `Debate-Coach-APK-v8.0.7.apk`（发布基准）。

**禁止**：不要在 `C:\Program Files` 下找 JDK；不要手工 `rm/cp` APK/www 或 assets（gradle 守护进程文件锁会静默失败返回0）；不要 `npx cap sync`（会重置原生工程 versionCode）；不要在根目录重建 capacitor 工程。

## 🛠️ 发布与检视模块（scripts/ —— 发布前必跑 verify）

**规则：发布/检视一律用下方 node 模块，禁止再写一次性 Python 脚本**（旧 dump_*/analyze_*/patch_*/push_*/test_* 等 79 个已归档至 `Output/归档-脚本-260815/`，根目录仅保留 build_inf_v805.py / extract_docx.py / count_docx.py）。

| 模块 | 用法 | 职责 |
|---|---|---|
| `node scripts/verify.cjs` / `node scripts/verify.cjs --release` | 两级验证门 | 默认=本地预检：严格校验 `DC_PAGES` 7 页面、旧根 B64/loader 为 0、Skill-Web/ZH、C 协议、字典、工具 manifest 等；尚未同步的发布镜像仅 WARN。`--release`=发布门：APK、htdocs、纯净发布仓库等下游镜像也必须一致，否则 FAIL。共享解析统一走 `scripts/standalone-pages.cjs`。 |
| `node scripts/inspect.cjs` | `节点名 [行区间]` 或 `节点名 --grep <正则>` | 检视解码页，替代旧 dump_*.py。`--list` 列块 |
| `node scripts/package.cjs` | `--copy-only` / `--gradle` | APK 打包：先删后拷破锁 → 字节/tag 断言（含 13 工具页清单）→（--gradle）构建 → APK 内提取复核（内置 zip 解析，支持中文文件名） |
| `node scripts/export-tools.cjs` | `--emit` / `--check` / `--diff` | 工具箱工具页唯一来源维护：--emit 幂等重打补丁（返回按钮/主题键/lang-toggle/样式），--check 校验 manifest 与残留，--diff 功能差异裁决（旧母版导出时代遗留） |
| `node scripts/i18n/build-judge-dict.cjs` | `--check` / `--emit` / `--splice` | 裁判所字典唯一来源 `scripts/i18n/judge-map.json`。加翻译改 JSON；`--splice` 才写回母版 |
| `node scripts/proxy.cjs` | `--set`（默认）/ `--check` | 自动探测可用代理端口（7897/8001）→ 写 git 全局 → 清发布仓库 local 残留。**推送/联网前必跑** |

**发布顺序：改源（MD/JSON）→ 生成/编码 → `node scripts/verify.cjs` 全绿 → 打包 → `node scripts/proxy.cjs --set` → 推送。**

## 继承包
- 当前：`Output/handoff-260711/`（v7.6.14，2026-07-11）
- 上一：`Output/handoff-260709/`（v7.6.1，2026-07-09）
- 新 AI 接手时优先阅读 `Output/handoff-260711/快速接手.md`

## 项目来源
继承自 `C:\Claude\Project\BLZJ` 项目，该项目因 token 超出上限无法继续对话后迁移至此。

## 核心资产
- `SKILL.md` — 《辩论筑基》完整知识体系 + 审问协议（v7.4.0）
- `SKILL-EN.md` — 英文版知识库（v7.3.0-en-alpha）
- `debate-coach-web.html` — **网页版正式单文件交付**（v9.2.1+：`DC_PAGES` 七页面全内嵌；Toolbox 的 `TOOL_HTML` 内嵌 9 工具×中英；同源 iframe.srcdoc；无根部可执行 HTML Base64 loader）
- `toolbox.html` + 13 独立工具页 — 工具箱**线上外置形态**（唯一来源 Backup 根，manifest 指纹校验；仅 InfinityFree 1MB 限制场景使用）
- `Debate-Coach-APK-v8.0.7.apk` — APK 安装包（5.99MB，内嵌工具箱+8候选知识库；历史版本归档于 `Output/归档-APK-260815/`）
- `Output/辩案工作台-Case-Workbench.html` — 辩案工作台独立版
- `Output/软件著作权登记/` — 著作权登记全部材料（v7.6.14）
- `Output/handoff-260711/` — 项目继承包（v7.6.14）
- `Coach2.0/` — 测试开发子项目（重构方案设计.md + 工具箱内嵌版母版 + 备份归档）
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
1. 根目录 13 个工具页是工具真源；先在对应根文件完成修改与验证
2. 运行 `node scripts/export-tools.cjs --check` 校验工具真源与 manifest
3. 重新编码写回
4. 中间产物用 `.tmp-*` 前缀，**用完必须立即删除**

```bash
# 标准命令模板（用 node，禁止用 Python 脚本）
node -e "var fs=require('fs'),cwd=process.cwd();
var web=fs.readFileSync(cwd+'/debate-coach-web.html','utf-8');
// v9.2.1+ 禁止自行解析/替换 TOOLBOX_B64；统一走共享载体适配器
var toolbox=Buffer.from(m[1],'base64').toString('utf-8');
// 将根目录工具真源同步进正式单文件：
// node scripts/export-tools.cjs --sync-master
fs.writeFileSync(cwd+'/debate-coach-web.html',updated,'utf-8');"
```

## 工作方式
- 在 Claude Code 中加载 SKILL.md 即可使用纯 Skill 版
- 浏览器打开 debate-coach-web.html 使用网页版（需自备 API Key）
- 协议（v7）集成在 SKILL.md 中


## 术语约束
**复盘或分析辩论比赛时，描述主线形态使用客观术语**：1型主线="有清晰的决胜逻辑"，2型主线="缺乏聚合的决胜锚点"。禁止使用"评委享受""评委痛苦"等主观措辞。结构性交锋的操作使用消化、反转，不用前体系术语"受身"（仅在解释历史概念时加"旧称"标记）。反驳后回应框架使用习惯性交锋/结构性交锋二分，不用前体系四分类"攻守走受"。

**全项目术语标准参见 SKILL.md 中的"术语标准"章节（§术语映射表 + §教练禁令全文 + §自检钩子）**——包含完整旧→新映射表、禁令级别、豁免条件、自检钩子。TERMINOLOGY.md 已被 GitHub 删除（内容已嵌入 SKILL.md）。所有禁令不影响对旧术语的答疑解释（讨论该概念本身时不受限）。

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
10. SKILL.md 术语标准章节 ← 如涉及术语变更

**严禁**：修改 SKILL.md 后去碰 `debate-coach-web.html` 或 `裁判所2.0.html`——它们有自己的知识库。

---

### 轨道 B：网页版教练知识库（Skill-Web.md）

**源文件**：`Skill-Web.md`（Backup 工作区根目录，不在 GitHub 发布仓库中）

修改教练教学规则后，同步：
1. 编辑 `Skill-Web.md`（裸 MD，人类可读，git diff 友好）
2. `debate-coach-web.html` → 通过 `scripts/standalone-pages.cjs` 读取/更新 `DC_PAGES.ZH`；禁止自行做 Base64 解码/重编码
3. `node scripts/package.cjs --copy-only`（同步 master → APK/www + 断言）
4. `node scripts/package.cjs --gradle`（cap copy + 构建 + APK 内提取复核）→ 产物复制为根目录安装包
5. `C:/Claude/Project/Debate-Coach/Debate-Coach-web.html` ← 覆盖（GitHub 发布仓库）

⚠️ Skill-Web.md 于 2026-07-21 从 ZH_B64 反向导出重新对齐（1601 行）。此前版本（190 行，Jul 18）已过时。

**严禁**：修改网页版教练知识库后去碰 SKILL.md——Claude Code 的知识库和网页版的知识库是两套独立系统。

---

### 轨道 C：裁判所分析框架（Skill-Judge.md）

**源文件**：`Skill-Judge.md`（Backup 工作区根目录，不在 GitHub 发布仓库中）

**重要**：裁判所有两个 HTML 入口——
- **网页版内嵌**：`Debate-Coach-web.html` 中的 `DC_PAGES.JUDGE`（可读字符串载体，单文件内嵌）
- **单页母版**：`Output/裁判所2.0.html`（106KB，独立 HTML，内嵌 buildSystemPrompt 函数）
- 两者共用 Skill-Judge.md 作为规则源

修改裁判分析规则后，同步：
1. 编辑 `Skill-Judge.md`（裸 MD，人类可读，git diff 友好）
2. `Output/裁判所2.0.html` → Edit 工具手改 `buildSystemPrompt` 函数
3. `debate-coach-web.html` → 通过共享 `standalone-pages` 适配器更新 `DC_PAGES.JUDGE`，并做浏览器回归
4. `node scripts/package.cjs --copy-only`（同步 master → APK/www + 断言）
5. `node scripts/package.cjs --gradle`（cap copy + 构建 + APK 内提取复核）→ 产物复制为根目录安装包
6. `C:/Claude/Project/Debate-Coach/Debate-Coach-web.html` ← 覆盖（GitHub 发布仓库，含更新后的 `DC_PAGES.JUDGE`）

⚠️ `评委与复盘AI.html` 已于 2026-07-21 归档删除（过时双轮架构）。裁判所单页母版现为 `裁判所2.0.html`。
⚠️ Skill-Judge.md 于 2026-07-21 从 JUDGE_B64 反向导出更新至 223 行，并新增"理论基础速查"区块。

**严禁**：修改裁判分析规则后去碰 SKILL.md——裁判所的知识库和 Claude Code 的知识库是两套独立系统。

---

### 🆕 轨道 D：架构补偿（@skill-only，仅 Agent-Skill 端）

架构补偿是针对 Agent-Skill 端在单次推理中因上下文特征产生的特定偏差的补偿性文本。这些补偿**仅对 Agent-Skill 端有效**——网页版和裁判所用 HTML class 强制格式，不需要架构补偿。

- **存放位置**：SKILL.md 中，用 `<!-- @skill-only -->...<!-- /@skill-only -->` 包裹（用于构建脚本剥离）
- **同步**：仅覆盖 Agent-Skill 副本，不碰 Web/APK/MD 源
- **@skill-only 内容剥离命令**：从 SKILL.md 生成网页版知识库时，始终先执行过滤，再编码 B64：
  ```bash
  sed '/<!-- @skill-only -->/,/<!-- \/@skill-only -->/d' SKILL.md | [后续 B64 编码]
  ```
  这行命令会自动删除所有 `<!-- @skill-only -->...<!-- /@skill-only -->` 包裹的段落，确保架构补偿不会泄漏到网页版/APK 端。
- **示例**：C3 格式排他声明、三项禁止、C3/C5 区分标记、α→β→γ 交叉引用锚定、输出后自检
- **禁止**：架构补偿文本出现在网页版/APK 中

---

---

### ⛔ 不动文件
- `Output/milestone-*-protected/`（chmod 444；修改需用户明确授权）
- `Output/软件著作权登记/`（法律文件）
- `Source/`（课件分析原文）
- `翻译备份/`（历史对照）

### 修改方法约束
- 纯文本（SKILL.md 等）：Edit 工具手改
- 正式单文件页面载体（v9.2.1+）：统一通过 `scripts/standalone-pages.cjs` 读写 `DC_PAGES`；工具页通过 `export-tools --sync-master` 写回。旧 B64 仅用于历史版本只读兼容，禁止恢复为现行发布机制。
- 验证：每次修改后浏览器打开确认
- 保护版：先 `chmod 644` 解锁，改完 `chmod 444` 恢复
