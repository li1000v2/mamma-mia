# Mamma mia!：GitHub 语言学习项目调研与借鉴建议

调研日期：2026-10-16（Asia/Tokyo）  
用途：为 Mamma mia! 的课程、复习、听说训练、情境挑战和内容工具提供设计依据。  
范围：9 个语言学习相关项目，以及计划已选用的 `swift-fsrs` 组件。

本文以《Mamma mia! 意大利语巡礼 App 设计 v0.2》为产品背景，并对照了当前工作区的开发约定和部分源码。场景例子是教学设计示例，不包含真实行程日期、酒店、航班或个人资料。

## 1. 核心结论

Mamma mia! 可以围绕现有 SwiftUI + MammaCore 架构吸收以下设计：

| 要解决的问题 | 首选参考 | 建议吸收的能力 |
| --- | --- | --- |
| 复习时“听得懂”和“说得出”混在一起 | Anki | 内容与卡片分离，不同检索方向分别调度，关联卡适当错开 |
| 对话练习容易变成无目标闲聊 | Immergo | 任务、角色、完成目标，以及带练／挑战模式 |
| 录音对比操作繁琐 | FluentAnyLang | 逐句听、复述、自动录音、连续对比的完整流程 |
| 批量生成课程后容易出现数据和音频错误 | LibreLingo、Idiomap | 内容与界面分离，结构校验与语义校验共同把关 |
| 对话结束后纠错没有进入后续学习 | OpenLingo、Sotto | 对话反馈进入复习，再由薄弱点影响下一次练习 |
| 学到的是孤立词，实际开口仍困难 | Lute、VocabSieve | 保留词组、词形关系、原句和使用语境 |

最适合直接作为现有工程依赖的仍是 `swift-fsrs`。其他项目的主要价值在产品流程、内容结构和局部实现思路；它们大多使用 Web 或 Python 技术栈，接入原生 iOS 通常需要重新实现相应交互。

本次没有找到可直接替换当前工程、同时满足中文零基础课程、意大利旅行场景、离线内容、原生 iOS 和行程驱动复习的完整项目。这是本次检索范围内的结果，不代表 GitHub 上不存在其他候选。

## 2. 调研方法与证据边界

### 2.1 如何筛选

检索覆盖了 language learning、offline、spaced repetition、speaking、roleplay、shadowing、sentence mining 和 SwiftUI 等方向。选择依据依次为：

1. 能否改善 Mamma mia! 的核心学习任务。
2. 是否存在可阅读的仓库、文档或实现文件。
3. 是否有清楚的数据结构或交互流程可借鉴。
4. 与离线使用、个人学习、短时间练习的匹配程度。
5. 仓库维护信息和复用边界。

没有用 star 数量作为学习效果或实现质量的评分。

### 2.2 本文中三类表述的含义

- **文档确认**：项目 README 或官方手册明确描述的能力。
- **源码抽查确认**：本次读取了相关实现文件，确认存在相应结构或逻辑。
- **Mamma mia! 建议**：根据上述材料提出的设计，不代表参考项目已经实现。

本次没有安装运行候选项目，没有测试其意大利语识别准确率、音频质量、手机离线稳定性、延迟或学习效果。README 中的功能宣称不能替代这些实测。对当前 Mamma mia! 工作区也只做了静态读取，没有运行构建或修改业务代码。

### 2.3 仓库快照

以下数据来自本次读取的 GitHub 仓库元数据。最近 push 日期取 API 返回的 UTC 日期；它可能涉及非默认分支，不等于最近正式发布。许可列记录仓库或 README 的声明，不把代码许可自动扩展到课程、录音、图片或外部数据。

| 项目 | Stars | 最近 push（UTC） | 状态 | 代码许可记录 | 主要借鉴方式 |
| --- | ---: | --- | --- | --- | --- |
| [Anki](https://github.com/ankitects/anki) | 32,044 | 2026-10-16 | 未归档 | AGPL-3.0-or-later，含其他许可文件 | 学习模型与调度交互 |
| [Immergo](https://github.com/ZackAkil/immersive-language-learning-with-live-api) | 510 | 2026-04-30 | 未归档 | Apache-2.0 | 任务设计、提示词组织、结果结构 |
| [FluentAnyLang](https://github.com/Jim-Elijah/fluent-any-lang) | 2 | 2026-10-11 | 未归档 | README 声明 MIT，指向 package.json | 听说练习交互 |
| [LibreLingo](https://github.com/kantord/LibreLingo) | 2,632 | 2026-06-19 | 已归档 | AGPL-3.0；课程可能另有许可 | 内容组织和构建工具设计 |
| [Idiomap](https://github.com/JesusOrihuela/idiomap) | 0 | 2026-09-29 | 未归档 | MIT；内容来源另列 | 内容检查与离线资源组织 |
| [OpenLingo](https://github.com/pretzelai/openlingo) | 88 | 2026-05-27 | 未归档 | MIT | 练习结构、对话与复习衔接 |
| [Sotto](https://github.com/affromero/Sotto) | 20 | 2026-10-15 | 未归档 | AGPL-3.0 | 薄弱词汇驱动后续内容 |
| [Lute](https://github.com/LuteOrg/lute-v3) | 1,590 | 2026-09-05 | 未归档 | MIT | 词组与词形关系 |
| [VocabSieve](https://github.com/FreeLanguageTools/vocabsieve) | 544 | 2025-08-15 | 未归档 | GPL-3.0 | 保留语境的收藏与制卡流程 |
| [swift-fsrs](https://github.com/open-spaced-repetition/swift-fsrs) | 105 | 2026-05-25 | 未归档 | MIT | 已选用的 Swift 调度组件 |

Anki 的详细许可说明见 [LICENSE](https://github.com/ankitects/anki/blob/main/LICENSE)。FluentAnyLang 的许可声明见 [README](https://github.com/Jim-Elijah/fluent-any-lang/blob/master/README.md)。LibreLingo 的归档状态和课程许可说明见其[仓库首页](https://github.com/kantord/LibreLingo)。

## 3. Anki：把“学习材料”和“测试能力”分开

### 已确认的优点

Anki 用 note 保存一份内容，再通过不同卡片模板测试不同方向；识别和主动回忆的表现分别记录。学习流程包含新卡、学习、复习和重学状态，回答后由用户自评。它还可以暂时隐藏同一 note 的关联卡，减少同次练习中的答案提示。依据：[基础概念](https://docs.ankiweb.net/manual/getting-started)、[学习与关联卡处理](https://docs.ankiweb.net/manual/studying)。

### 对 Mamma mia! 的价值

同一句 `Posso pagare con la carta?` 可以派生出不同任务：

| 练习方向 | 给学习者什么 | 检查什么 |
| --- | --- | --- |
| 听辨 | 播放意大利语音频 | 是否理解“能刷卡吗” |
| 回忆 | 显示“询问能否刷卡” | 是否能主动说出表达 |
| 换词 | 给出已学过的新动作或物品 | 是否能使用句框组织新句子 |

**建议：** 三类表现独立记录，并共用一个句子来源。听辨成功不应自动证明主动表达已掌握。

正式复习时，可以优先避免同句卡相邻出现：刚听完原声，马上做中文意图回忆，容易把短时记忆误当作稳定掌握。教学阶段则可以保留“听完立刻复述”，因为两种场景的目的不同。

### 如何控制工作量

- 不要求每句话都立即生成全部题型；先选最能服务该句用途的卡片。
- 继续按实际首次开始的卡片数量控制每日新卡预算。
- 自评说明应区分“想不出来”和“想得慢但正确”；错因标签与 FSRS 等级可以分别记录。
- 先实现本次会话内的关联卡避让，再观察是否需要整天隐藏。

### 当前工程与剩余工作

当前 `ReviewScheduler.swift` 已使用 `CardID(phraseID, kind)`，并定义听辨、回忆、换词和最小对立类型。因此“按能力区分卡片”已有结构基础。

本次抽查的 `ReviewQueue.swift` 中没有看到基于同一 `phraseID` 的关联卡避让逻辑；这是建议继续补充的位置。是否覆盖所有界面调用路径，仍需后续检查。

借鉴优先级：**P0，高。** 主要吸收模型和交互，继续使用现有 Swift 调度实现。

## 4. Immergo：让对话围绕明确任务展开

### 已确认的优点

Immergo 使用 Gemini Live 进行语音角色扮演，区分教学模式与沉浸模式。场景数据包含标题、描述、难度和 NPC 角色，示例有点咖啡和买车票。界面代码定义了 `complete_mission` 工具，用于提交任务结果与反馈。依据：[README](https://github.com/ZackAkil/immersive-language-learning-with-live-api)、[任务数据](https://github.com/ZackAkil/immersive-language-learning-with-live-api/blob/main/src/data/missions.json)、[对话实现](https://github.com/ZackAkil/immersive-language-learning-with-live-api/blob/main/src/components/view-chat.js)。

### 对 Mamma mia! 的价值

**建议把一个场景拆成四个要素：**

1. 情境：学习者现在在哪里，要办什么事。
2. NPC 角色：谁在接待，允许说什么难度的语言。
3. 任务目标：哪些需求必须表达出来。
4. 关键信息：哪些价格、时间、方向或站台必须听懂。

例如咖啡吧挑战可检查：点了正确的饮品和数量、回答站着喝还是坐下、理解总价、完成付款沟通。课程可以预设几种有效说法，而不是只有一句固定答案。

### 带练模式与挑战模式

| 维度 | 带练模式建议 | 挑战模式建议 |
| --- | --- | --- |
| 中文帮助 | 按需展示解释和意图 | 按统一规则计入提示次数 |
| 节奏 | 可以暂停、重听、重说 | 保持较完整的对话流程 |
| 结果 | 显示已练习和需重练的表达 | 显示目标完成、关键信息和提示使用情况 |
| 完成后 | 给少量可立即使用的提示 | 保存可复查的挑战结果 |

### 复用边界

Immergo 使用在线实时语音，不能据此证明离线剧本可用，也不能用它的演示推断当前方案的延迟。它的结果工具由模型触发；Mamma mia! 的离线挑战应继续用确定的剧本状态和答案规则判定。

源项目的表现等级涉及流利度和接近母语水平。对本项目，结果应优先表达任务有没有办成、哪些信息没有听懂，保持“不做发音打分”的既定范围。

借鉴优先级：**P0 采用任务结构，P2 参考在线角色设置。**

## 5. FluentAnyLang：减少听说训练中的操作负担

### 已确认的优点

FluentAnyLang 用字幕切分材料，提供逐句跳转、循环、变速、句间停顿、同步跟读和听后复述；支持比较原声与录音、保存多次尝试、添加背景噪声，以及本地数据备份。依据：[README](https://github.com/Jim-Elijah/fluent-any-lang/blob/master/README.md)。以上为文档确认，未在 iPhone 上实测。

### 对 Mamma mia! 的价值

v0.2 已经提出原声与录音交替播放。进一步可把它做成一个连续交互：

```text
播放原声 → 留出开口时间 → 录音 → 播放原声 → 播放自己的录音 → 重试或下一句
```

**建议默认采用听后复述。** 初学者先完整听一句，再自己说；同步跟读作为熟悉句子的后续练习方式。字幕可以在初次听音时隐藏，在需要帮助或对比时揭示。

### 可渐进加入的细节

- 每句保留最近一次录音，用户主动收藏后才长期保留更多版本。
- 暂停和重新开始有明确状态，减少误触后不知道是否正在录音的情况。
- 跟读速度与示范音频版本分开表示，避免把播放减速和重新合成的慢速示范混为一谈。
- 在后期挑战中加入可调的咖啡吧或车站环境声，检查关键信息能否听懂。

### 复用边界

首版已经有预生成短句，不需要同步引入整套视频、字幕、波形编辑和媒体库。背景声练习也需要验证可懂度，不能只把音量调高就当作有效难度提升。

借鉴优先级：**P1 连续听说流程；P2 环境声。**

## 6. LibreLingo：课程内容有独立的生产流程

### 已确认的优点

LibreLingo 将 YAML 课程、加载工具、JSON 导出和学习界面分开。它提供独立的 Python 课程加载与导出工具，说明内容可以在界面之外处理。原仓库已归档，README 指向其他维护分支。依据：[仓库说明](https://github.com/kantord/LibreLingo)。

### 对 Mamma mia! 的价值

当前 JSON 方向已经匹配这种设计。建议继续明确内容层次：

```text
句框与词汇 → 句子 → 练习定义 → 课程单元 → 情境挑战
                  ↘ 音频清单
```

句子的意大利语、中文意思和审核状态有唯一来源。课程和剧本通过稳定 ID 引用它；同一句出现在多处时，尽量避免复制成无法同步修订的多份文本。

### 应借鉴的工程做法

- 内容作者能单独校验数据，不必启动 iOS App 才发现错误。
- 内容校验失败时，报告文件、条目 ID 和具体原因。
- 给课程内容增加版本信息，使发布后修改可追踪。
- 修改原文后，明确哪些音频和听审结果需要重新生成或失效。

### 复用边界

无需为了参考 LibreLingo 将现有 JSON 改成 YAML。它最有价值的是内容与播放器的职责划分。原仓库归档也意味着，若要直接依赖其中代码，需要另外评估维护和迁移成本。

借鉴优先级：**P0，高。**

## 7. Idiomap：内容校验要检查“结构之外的关系”

### 已确认的优点

Idiomap 是使用静态 Web 技术的学习项目，内容存为 JSON，音频预生成，并组织每日练习。源码中的检查脚本覆盖规范化后的重复表达、变体标签重复、旧字段残留、缺失音频标识及其长度等问题。依据：[README](https://github.com/JesusOrihuela/idiomap)、[check-content.mjs](https://github.com/JesusOrihuela/idiomap/blob/main/tools/check-content.mjs)。

### 对 Mamma mia! 的价值

JSON Schema 能检查字段和类型，但跨文件引用、同句变体、音频与原文是否对应，还需要额外规则。建议建立下列检查清单：

| 检查 | 应发现的问题 | 建议行为 |
| --- | --- | --- |
| ID 唯一性与引用 | 句子 ID 冲突，课程引用不存在的句子 | 报错并指出来源 |
| 原文与音频映射 | 文本已修改，但仍绑定旧音频 | 要求重建映射或重新生成 |
| 声线与语速覆盖 | 已完成听审的句子少了某个必需版本 | 阻止作为完整内容发布 |
| 表达变体 | 两个变体实际上相同，或没有标注用途 | 报错或提示人工复核 |
| 关键信息题 | 广播变体说的是某站台，答案却来自另一变体 | 检查变体与答案绑定 |
| 审核状态 | 尚未校对的内容被标记为可正式发布 | 按发布规则处理 |
| 重复表达 | 同一表达重复起草成多个来源条目 | 提示合并或记录重复理由 |

重复检测不应简单禁止同一句用于多个场景。更合理的做法是共用句子 ID，允许多个场景引用；确有教学原因的独立变体则保留说明。

### 当前工程与剩余工作

当前 `tools/validate_content.py` 已检查 Schema、音频 manifest 文件存在性，以及 `audio_ok` 句子的声线／语速覆盖。内容审核也已有阶段状态。这些属于已有基础，不应重新列为从零开发。

后续重点是评估变体去重、原文更新后的听审失效、发布内容清单与完整性检查能否覆盖整套课程。Idiomap 的脚本检查不能代替意大利语语法和自然度审核。

借鉴优先级：**P0，高。**

## 8. OpenLingo：用结构化练习连接对话与复习

### 已确认的优点

OpenLingo 的 AI 导师可使用学习者记忆和 SRS 工具，并在对话中呈现练习。源码为不同题型定义了明确结构：翻译题可包含替代答案 `acceptAlso`，多种练习包含复习目标 `srsWords`。其复习实现使用 SM-2。依据：[README](https://github.com/pretzelai/openlingo)、[练习 Schema](https://github.com/pretzelai/openlingo/blob/main/lib/content/exercise-schema.ts)、[SRS 实现](https://github.com/pretzelai/openlingo/blob/main/lib/srs.ts)。

### 对 Mamma mia! 的价值

**建议把在线反馈拆成结构化结果：**

- 学习者想表达的意图。
- 原回答和建议表达。
- 简短中文解释。
- 对应句框、场景及错因。
- 是否建议进入复习。

这样才能从反馈卡进入后续练习，避免纠正只是一段读完就丢失的文字。

### 多个答案怎样用于离线挑战

同一意图可以接受多种经过审核的表达。判定时需要区分：

1. 意图是否正确。
2. 物品、数量、目的地等关键部分是否正确。
3. 说法是否属于已审核的可接受变体。
4. 识别是否不足以判断，需要用户确认或切换点选。

关键词匹配必须注意否定词；只有命中目的地或物品名，并不一定代表需求表达正确。这是对 Mamma mia! 的判定建议，不是本次确认 OpenLingo 已解决的能力。

### 复用边界

保留 FSRS，不引入第二套 SM-2 调度。AI 建议表达先进入待确认或待审核状态，避免绕过既有内容质量流程。也应限制每轮新增卡片数量，符合每天的学习预算。

借鉴优先级：**P1 完善练习结构；P2 对话反馈与复习衔接。**

## 9. Sotto：让薄弱内容在新语境中再次出现

### 已确认的优点

Sotto 的文档描述了基于学习者目标组织课程、以到期词汇生成听力、未通过部分换题练习，以及独立的日常练习入口。它把课程与复习数据连接起来。依据：[README](https://github.com/affromero/Sotto)。本次主要依据文档，未验证生成质量和运行效果。

### 对 Mamma mia! 的价值

现有错因分类可以进一步决定后续材料：

| 最近的困难 | 下一次建议安排 |
| --- | --- |
| 没听清价格 | 使用已审核的不同价格音频，重新提取金额 |
| 忘记请求帮助的句框 | 在另一场景中提出相同沟通意图 |
| 数量表达有误 | 用不同物品和数量做短练习 |
| 没听懂改站台 | 选择另一条站台变更广播，检查旧、新站台的区别 |

这样的复习既保留目标，又改变表面内容，适合检验是否能迁移到真实场景。

### 从离线模板起步

不必一开始实时生成所有材料。可以先给已审核题目标记 `targetFrame`、`errorType`、`scene` 等信息，再从题库里选择符合最近薄弱点的变体。

数字和目的地替换需要配套正确音频与答案，优先准备成完整审核过的变体。在线生成以后再作为补充，生成内容与已审核课程保持可区分的状态。

### 复用边界

完整 CEFR 课程、知识图谱和多技能评分会显著扩大本项目范围。优先吸收“薄弱点影响下一次材料”这一个能力；不会因为它的完整平台采用某种学习法，就推断其效果已经得到验证。

借鉴优先级：**P1 离线选题；P2 在线生成变化。**

## 10. Lute：把常用表达当成可以整体使用的单位

### 已确认的优点

Lute 支持单词、多词表达和父子词条关系。根词条的解释可用于相关词形，例句检索也能覆盖关联词形。依据：[仓库](https://github.com/LuteOrg/lute-v3)、[官方手册](https://luteorg.github.io/lute-manual/)。

### 对 Mamma mia! 的价值

旅行口语中，不少表达适合整体记忆，例如“外带”“我需要……”和“能帮我……吗”。建议允许内容把多个词标成一个学习单位，并为它提供完整的中文意图和例句。

词形关系可以作为简短补充：遇到动词变化时，点击查看它与原形、已学形式之间的联系。界面默认仍服务当前句框，避免一次展示完整变位表。

### 最小实现

- 内容中增加可选的表达组或关联词形 ID。
- 在句子中标出当前要学的整块表达。
- 点击后先显示这句话中的意思，再显示关联形式。
- 复习仍以句子和意图为主，必要时才拆成单词练习。

借鉴优先级：**P1 内容标注。** 全功能阅读器可在旅行学习主流程稳定后再评估。

## 11. VocabSieve：收藏时保留为什么需要这句话

### 已确认的优点

VocabSieve 面向句子采集和 Anki 制卡，能把目标词、原句、解释及发音一起保存；支持本地词典和音频资源、词形还原及阅读标注导入。依据：[README](https://github.com/FreeLanguageTools/vocabsieve)。

### 对 Mamma mia! 的价值

建议在课程和对话记录中提供“收藏这句”，同时保留：

- 原句及中文意图。
- 来自哪个课程或场景。
- 为什么收藏，例如“刚才没能主动说出来”。
- 对应音频和内容版本。
- 收藏后是否加入复习。

收藏和加入复习可以分开：有些句子只是旅行时想快速出示，有些才需要反复练习。两个动作使用同一个内容来源，可避免重复维护文本。

### 复用边界

先处理 App 内已有内容。外部网页抓取、电子书导入、大型词典和自动句子采集，会超出首版目标。若以后导出 Anki，建议从简单的文本或 CSV 导出开始，另行验证音频及卡片模板兼容性。

借鉴优先级：**P1 收藏和语境信息；导出作为后续扩展。**

## 12. swift-fsrs：现有选型继续使用，配置要可验证

上游 README 明确说明支持 FSRS-6，同时保留 FSRS-5 参数。默认示例使用 19 项参数走 FSRS-5，FSRS-6 示例显式传入 `FSRSDefaults.defaultWv6`。包定义中提供 `FSRS` library target，最低 Swift tools 版本为 5.10。依据：[README](https://github.com/open-spaced-repetition/swift-fsrs/blob/main/README.md)、[Package.swift](https://github.com/open-spaced-repetition/swift-fsrs/blob/main/Package.swift)。

**对当前项目的更正与确认：** 前一轮调研提醒“接入时需要显式启用 FSRS-6”，属于集成注意点。本次读取工作区后确认，这里已经显式传入 `defaultWv6`，不是尚未修复的问题。

当前工程观察到：

- `Packages/MammaCore/Package.swift` 固定依赖 revision：`4fbaf20184d62f82a9f44f343337c61a2c5483e9`。
- `ReviewScheduler.swift` 显式使用 `FSRSDefaults.defaultWv6`。
- `SchedulingTests.swift` 已有 `usesFSRS6Parameters` 测试声明。

本次未执行该测试，因此这里只确认实现和测试存在，不报告测试通过。

后续建议保留参数版本、卡片状态和复习日志的可追踪性。行程加推应通过本项目调度层表达，并定义“只是看过”“完成一次自评复习”“挑战中用过”分别怎样影响记忆状态。

## 13. 与当前工作区的对应关系

本节记录 2026-10-16 本次读取时的工作区状态，包含尚未提交的文件，不代表已合入、已发布或已通过真机验证。文件路径均相对于项目根目录。

| 能力 | 本次观察到的基础 | 调研后的下一步 |
| --- | --- | --- |
| FSRS-6 | `ReviewScheduler.swift` 显式使用 v6 参数 | 保持版本和回归测试，不重复实现算法 |
| 不同卡型独立记录 | `CardID` 包含 `phraseID` 与 `kind` | 验证界面与持久化始终使用完整 ID |
| 每日队列 | `ReviewQueue.swift` 区分学习、复习、新卡 | 评估关联卡避让与时间预算 |
| 课程审核状态 | Schema 已有 `draft / checked / native / audio_ok` | 增加或确认内容修订后的审核失效规则 |
| 音频覆盖 | 校验脚本检查 manifest 文件及审核完成句子的声线、语速 | 完善发布清单和实际播放验收 |
| 离线挑战 | 已有剧本、随机变体、追问、关键信息题与提示计数结构 | 继续核对任务目标、多个有效表达和输入方式记录 |
| 学习记录 | `StudyProgress.swift` 保存卡片、复习、课程和挑战结果 | 扩展错因、场景来源及与后续选题的关联 |
| 行程用到日 | 场景使用 `neededAt`，由导入行程解析 | 保持个人数据与公开内容分离，验证跨日边界 |

主要本地依据：

- `CLAUDE.md`、`README.md`。
- `Packages/MammaCore/Package.swift`。
- `Packages/MammaCore/Sources/MammaCore/Scheduling/ReviewScheduler.swift`。
- `Packages/MammaCore/Sources/MammaCore/Scheduling/ReviewQueue.swift`。
- `Packages/MammaCore/Sources/MammaCore/Progress/StudyProgress.swift`（调研期间由 `Progress.swift` 更名，保存前已重新读取确认）。
- `Packages/MammaCore/Sources/MammaCore/Dialogue/DialogueScript.swift`。
- `Packages/MammaCore/Sources/MammaCore/Dialogue/DialoguePlanner.swift`。
- `Content/schema/lesson.schema.json`、`Content/schema/dialogue.schema.json`。
- `tools/validate_content.py`。

## 14. 建议的数据关系

以下是讨论用的概念结构，不是现有 JSON 格式，也不表示已经实现。优先通过增量字段与适配保持现有进度数据兼容。

### 14.1 内容、卡片、练习事件分别负责什么

| 对象 | 保存什么 | 为什么分开 |
| --- | --- | --- |
| 句子内容 | 原文、中文、句框、场景、审核状态、修订版本 | 多处使用同一份可靠内容 |
| 复习卡片 | 内容 ID、卡片类型、FSRS 状态 | 不同能力可以有不同熟练度 |
| 练习事件 | 时间、回答方式、提示、错因、关联场景 | 能追溯一次练习发生了什么 |
| 挑战结果 | 目标完成、关键信息、提示使用、参与方式 | 区分“选对答案”和“自己说出来” |
| 音频清单 | 文本／声线／语速到文件的映射，以及生成与审核信息 | 内容修改后能发现旧音频 |

### 14.2 挑战结果示意

```json
{
  "challengeId": "C_DEMO",
  "mode": "challenge",
  "inputMode": "choice",
  "goals": [
    { "id": "order_item", "completed": true },
    { "id": "choose_service", "completed": true }
  ],
  "keyInformation": { "correct": 1, "total": 1 },
  "hints": { "intent": 1, "frame": 0, "fullSentence": 0 },
  "weakItems": [
    { "phraseId": "L_DEMO-01", "kind": "recall", "reason": "could_not_retrieve" }
  ]
}
```

这是面向结果记录的示例。任务定义、允许的输入方式、提示次数计算和通过条件应由另一份明确规则决定。P0 点选式挑战可以保留当前通关目标，同时记录输入方式；P1 增加口语后，才有依据呈现“点选完成”和“口语完成”的差异。

### 14.3 内容修改后的处理

建议区分修订影响：

- 仅修正中文标点：通常不需要重生成意大利语音频。
- 修改意大利语原文：相关音频及听审结果需要重新确认。
- 修改可接受答案或关键槽位：重新校验相关挑战。
- 修改教学解释：不应无条件清空学习者的复习历史。

通过稳定 ID 保留学习记录，通过内容版本记录变化。音频生成元数据可进一步记录模型及配置版本，是否纳入缓存键需结合当前生成管线决定。

## 15. 建议的学习流程

### 15.1 约 15 分钟的一次学习

| 环节 | 时间预算示例 | 设计重点 |
| --- | ---: | --- |
| 到期复习 | 6 分钟 | 独立检索，关联卡适当错开 |
| 一个句框的微课 | 2 分钟 | 中文解释和一个具体使用意图 |
| 听、复述、对比 | 4 分钟 | 连续操作，减少按钮切换 |
| 一个短场景或变体 | 3 分钟 | 用刚学的表达完成任务 |

这是可调整的预算示例，不是对每个学习者完成速度的预测。复习积压时优先减少新内容。

### 15.2 约 5 分钟的忙碌模式

直接进入少量到期复习和一个最需要的表达；结束后显示本次完成内容。保留手动继续的入口，避免把未做完的完整课程变成压力。

### 15.3 对话反馈如何进入下一次练习

```mermaid
flowchart LR
    A[情境练习] --> B[记录卡住的意图和错因]
    B --> C[确认或审核建议表达]
    C --> D[创建或更新对应复习卡]
    D --> E[到期复习]
    E --> F[在另一场景中再次使用]
    F --> B
```

重复遇到同一表达时应复用现有卡片；额外的被动曝光与正式作答分别记录。是否更新 FSRS，应取决于有没有实际进行该卡片所要求的检索和评价。

## 16. 建议优先级与验收标准

以下是基于调研的候选任务，尚未自动变成开发承诺。已有功能优先验证和补齐，再考虑新增范围。

| 编号 | 优先级 | 候选工作 | 可观察的验收结果 | 参考 |
| --- | --- | --- | --- | --- |
| R01 | P0 | 核对不同卡型独立保存 | 同一句听辨成功后，回忆卡不会自动变成已掌握 | Anki |
| R02 | P0 | 会话内关联卡避让 | 有其他可用题目时，同句不同卡型不立即相邻；学习步骤不被错误阻塞 | Anki |
| R03 | P0 | 明确挑战目标和提示口径 | 每个挑战能展示目标、关键信息结果及一致的提示计数 | Immergo |
| R04 | P0 | 补齐内容关系校验 | 错误引用、错误变体答案及发布内容缺音频能够被定位 | Idiomap、LibreLingo |
| R05 | P0 | 明确修订与审核关系 | 意大利语正文修改后，不会沿用失效的音频听审结论 | LibreLingo、Idiomap |
| R06 | P1 | 连续听说对比流程 | 一句话能完成听、录、对比、重试；中途暂停后状态明确 | FluentAnyLang |
| R07 | P1 | 支持已审核的有效表达 | 同一意图的合法变体能通过；关键否定、数量或目的地变化不会被忽略 | OpenLingo |
| R08 | P1 | 薄弱点驱动离线选题 | 近期某类错误能提高对应已审核练习出现的机会 | Sotto |
| R09 | P1 | 收藏句子与来源 | 收藏后能回到原场景，重复收藏不会生成重复内容 | VocabSieve |
| R10 | P1 | 标记整体表达和关联词形 | 用户能看懂本句里的表达块，并按需查看相关形式 | Lute |
| R11 | P2 | 在线反馈进入复习 | 反馈有结构，确认后进入正确卡型，并遵守新增预算 | OpenLingo |
| R12 | P2 | 场景噪声练习 | 可调背景声且能随时关闭，关键内容保持可听和可复盘 | FluentAnyLang |

建议首个验证切片只覆盖一课与一个短挑战：同一句生成听辨与回忆卡，做一次完整听说练习，完成场景，保存结果，再检查下一次队列。先确认数据和学习过程能够连起来，再扩充整套课程。

## 17. 复用策略与后续验证

### 17.1 三种复用方式

| 方式 | 适合的对象 | 本项目建议 |
| --- | --- | --- |
| 直接依赖 | 独立、可测试的算法组件 | 继续使用已固定版本的 swift-fsrs |
| 参考结构后实现 | 任务数据、练习 Schema、内容检查规则 | 在 MammaCore 和现有工具中实现，并沿用当前命名和存储约定 |
| 体验参考 | 逐句练习、提示揭示、收藏、结果呈现 | 用 SwiftUI 做小范围原型，再用实际课程验证 |

若后续引入具体代码或资源，记录仓库、文件、提交版本和相应许可。代码、课程、音频、图片分别确认来源；这份调研本身不授权复制任何第三方素材。

### 17.2 值得实测的问题

1. 一句话的多种题型是否让每日队列膨胀，如何选择最必要的卡型。
2. 关联卡避让在短会话里是否导致题量不足，应该等待、换题还是允许继续。
3. 意大利语离线识别对初学者、双辅音、数字和地名的表现。
4. 听后复述与同步跟读在当前学习阶段哪个更容易完成。
5. 多个正确表达、否定词与识别缺词怎样影响挑战判定。
6. 对话反馈转卡后，学习者下一次能否在不同场景中用出来。
7. 所需内容和音频在完全离线状态下是否能从头完成一课及一个挑战。

这些问题需要课程样例和真机结果，不能由仓库 stars、README 或模型生成的评分替代。

## 18. 主要来源索引

正文已在相关结论附近引用来源。以下索引用于后续复查，分支链接会随上游更新。

| 编号 | 来源 | 本次用途 |
| --- | --- | --- |
| S01 | [Anki 仓库](https://github.com/ankitects/anki) | 项目身份与仓库元数据 |
| S02 | [Anki 基础概念](https://docs.ankiweb.net/manual/getting-started) | note、card、检索方向与内容复用 |
| S03 | [Anki 学习手册](https://docs.ankiweb.net/manual/studying) | 自评、关联卡与学习流程 |
| S04 | [Anki LICENSE](https://github.com/ankitects/anki/blob/main/LICENSE) | 许可声明及例外 |
| S05 | [Immergo README](https://github.com/ZackAkil/immersive-language-learning-with-live-api) | 模式、技术栈与功能范围 |
| S06 | [Immergo missions.json](https://github.com/ZackAkil/immersive-language-learning-with-live-api/blob/main/src/data/missions.json) | 任务与角色数据 |
| S07 | [Immergo view-chat.js](https://github.com/ZackAkil/immersive-language-learning-with-live-api/blob/main/src/components/view-chat.js) | 模式提示词和完成任务工具 |
| S08 | [FluentAnyLang README](https://github.com/Jim-Elijah/fluent-any-lang/blob/master/README.md) | 跟读、复述、对比、背景声、本地数据 |
| S09 | [LibreLingo 仓库](https://github.com/kantord/LibreLingo) | 归档状态、课程加载与导出 |
| S10 | [Idiomap README](https://github.com/JesusOrihuela/idiomap) | 内容、音频及每日队列 |
| S11 | [Idiomap check-content.mjs](https://github.com/JesusOrihuela/idiomap/blob/main/tools/check-content.mjs) | 内容语义校验 |
| S12 | [OpenLingo README](https://github.com/pretzelai/openlingo) | 学习者记忆、对话工具与复习 |
| S13 | [OpenLingo exercise-schema.ts](https://github.com/pretzelai/openlingo/blob/main/lib/content/exercise-schema.ts) | 题型结构、替代答案与复习目标 |
| S14 | [OpenLingo srs.ts](https://github.com/pretzelai/openlingo/blob/main/lib/srs.ts) | 确认 SM-2 实现 |
| S15 | [Sotto README](https://github.com/affromero/Sotto) | 到期词汇驱动听力与练习 |
| S16 | [Lute 仓库](https://github.com/LuteOrg/lute-v3) | 项目、技术栈与许可 |
| S17 | [Lute 手册](https://luteorg.github.io/lute-manual/) | 多词表达与父子词条 |
| S18 | [VocabSieve README](https://github.com/FreeLanguageTools/vocabsieve) | 句子采集、本地资源与 Anki 制卡 |
| S19 | [swift-fsrs README](https://github.com/open-spaced-repetition/swift-fsrs/blob/main/README.md) | FSRS-5／6 参数差异 |
| S20 | [swift-fsrs Package.swift](https://github.com/open-spaced-repetition/swift-fsrs/blob/main/Package.swift) | Swift 包定义 |

