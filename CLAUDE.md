# Mamma mia! — 给编码代理的约定

自用的意大利语旅行学习 iOS app：中文讲解，12 个万能句框 × 旅行场景，FSRS 复习，示范音频离线可用。
没有本地 Mac：代码推到 GitHub，Actions 的 macOS runner 编译并产出未签名 IPA，用免费 Apple ID + SideStore 侧载。

## 目录

- `project.yml`：XcodeGen 工程定义。只改它，不手改 `.xcodeproj`（已 gitignore，CI 每次重新生成）。
- `App/`：SwiftUI 界面，Swift 5 语言模式。只放界面和 iOS 专属能力（录音、识别、通知）。
- `App/Assets.xcassets/AppIcon.appiconset/`：app 图标，一张 1024×1024、不带透明通道的 PNG，圆角由 iOS 切。
- `Packages/MammaCore/`：调度、判定、内容解析。只依赖 Foundation 和 swift-fsrs，不许 import UIKit / SwiftUI / SwiftData，保证 Linux 上能测。
- `Content/`：课程数据（JSON），整个文件夹打包进 app；`schema/` 是 JSON Schema。
- `Audio/`：生成的 .m4a 和 `manifest.json`。
- `tools/`：Python 工具。
- `reviews/`：交叉校对报告（`cross-check-<单元>.md`）。
- `.github/workflows/`：CI。

## 编译与测试

- MammaCore：`swift test --package-path Packages/MammaCore`（CI 用 `swift:6.3-noble` 容器）。测试也会校验 `Content/` 的跨文件引用。
- 内容：`pip install -r tools/requirements.txt` 后跑 `python tools/validate_content.py`。
- App：`ios-build` 在 macos-26 + Xcode 26.6 上编译模拟器版本；`ipa` 手动触发或推 `v*` tag 出未签名 IPA，tag 同时发 Release。
- 部署目标 iOS 26。GitHub 上的 Xcode 27 还是预览版，没有用到 iOS 27 SDK 的需求就不换。
- swift-fsrs 固定在 main 的一个提交：FSRS-6 只在 main 上，最新 tag v5.0.0 还是 FSRS-5。升级时改 `Package.swift` 里的 revision。
- 本地没有 Mac，编译错误只能从 CI 日志看（`gh run view --log-failed`）。

## 示范音频

- `python tools/gen_audio.py` 生成缺的音频（`--dry-run` 只列清单，`--prune` 删掉没人用的）。需要 ffmpeg，key 从环境变量或仓库根目录的 `.env` 读（`GOOGLE_API_KEY`、`GOOGLE_CLOUD_PROJECT_NUMBER`）。`.env` 已 gitignore，key 不许打印、不许提交。
- 声线和模型在 `tools/tts_voices.json`；改了声线就把它的 `rev` 加一，对应音频会全部重生成。
- 原速只把意大利语原文发给 TTS，不带风格指令：实测带指令时模型会把指令也念出来，systemInstruction 也不支持。慢速是原速录音用 ffmpeg `atempo` 放慢。
- 每段新音频都用 `checkModel` 转写回来和原文比对，对不上会重试；还对不上就在输出里报 warning，需要人去听。
- 人工听审前先跑 `python tools/audio_review.py`（默认第 1 周，`--week N` 换周，`--limit`/`--only` 限范围）：gemini-4-argon 用 HIGH 思考档逐段听，结果按文件名缓存在 `reviews/audio-screen-cache.json`，连同音频内容的哈希（重新生成的音频文件名不变，内容变了就重筛），可疑片段写进 `reviews/audio-screen-week<N>.md`，同名 `.html` 可在浏览器里逐条点听。它不判断双辅音长短（实测会自信地判错），含双辅音的句子只备注“双辅音需人工听”；改了提示词就把脚本里的 `PROMPT_REV` 加一，旧结果会重筛。拥堵时模型偶尔不思考、或没听音频就作答（判没问题，转写却和原文毫不相干），这种答案会换成 WAV 再试一次，还不行就不进缓存，重跑会重筛。被标出的片段会再用 `checkModel` 转写一遍写进报告（只看词对不对，不管发音），因为 Argon 偶尔会编出不相干的整句。
- 粗筛标出的录音用 `python tools/regen_audio.py` 处理（`--dry-run` 先看清单，`--only` 限范围）：一条录音是一个声线说一句，原速和慢速一起判。先复筛现在的版本，两次都干净就保留（原来是误报）；否则最多生成 4 个新版本，复筛两次都干净才替换；都不干净就留最好的一版记为仍可疑，下次运行再试。文件名不变，决定记在 `reviews/audio-regen-log.json`，报告在 `reviews/audio-regen.md`。
- 调 Gemini 的并发最多 8 路（`gen_audio.py` 的 `MAX_PARALLEL`，所有工具的 `--workers` 都被压在它以内）：2026-10-16 一天发了几千次请求、最高 40 路并发后，项目被 Google Cloud Trust & Safety 以“违反服务条款”为由停用（HTTP 403）。工具遇到 401/403/404 会立即停；不要换项目或换账号绕过封禁。
- app 里没有音频的句子会退回 iOS 自带的意大利语语音。挑战剧本可以用 `voice` 指定角色的声线。

## 开口说（离线识别）

- `App/Services/SpeechService.swift`：SpeechAnalyzer + SpeechTranscriber（it_IT），设备不支持就退到 DictationTranscriber，再不行只保留录音对比和自评。模型经 AssetInventory 下载，状态显示在「诊断、日志与备份」。
- 判定在 MammaCore 的 `Speech/`：识别结果和目标句逐词对齐，忽略大小写、标点和重音，只判断“对方能不能听懂”，不打发音分。
- 识别只是提示：复习照旧自评打分。挑战里说出的回复按选项的词匹配，对不上就点选；选项之间要差至少一个听得出的词，只差标点或重音的两个选项只能点选。

## 行程与用到日

- 用户在「随身 → 填写行程」里填：`course.json` 的 `cities` 里各城市的到达日和离开日（意大利当地日期，换城市那天首尾相接），每站可选酒店名称和地址，可选忌口（欧盟 1169/2011 附件二的 14 类过敏原，加一句备注）。`course.json` 的 `events` 是每年日期固定的节日，行程覆盖到就自动加上。
- 行程存在 `StudyProgress.trip`，和学习进度同一个文件，导出的备份里也有。它是可选字段：没有行程就不写这个键；读不出来时只丢掉行程，学习记录照常载入。行程的任何字段都不写进 `AppLog`。
- 场景的 `neededAt` 按行程算出每句的用到日（`ContentBundle.needByDays`）。`boostCandidates`（`BoostPolicy`：提前 5 天、用到日预计记忆率低于 0.95）选出的卡加进当天复习；用到日在这 5 天内的卡排在前面，越早用到越靠前。加练卡就是普通复习。
- 酒店和忌口现在只存着，等 P2 的出示卡来用。

## 交叉校对

- `python tools/cross_check.py --week 1`（或列单元 id：`L03 C01`；`--dry-run` 只打印请求）把单元分批发给 gemini-4-argon 审，报告写到 `reviews/cross-check-<单元>.md`。key 同上，云端环境由 network secret 注入 `x-goog-api-key`。
- 审：语法、对陌生人用 Lei、地道程度和地区差异、中文翻译、note／intro 里的假名和拼音提示、剧本选项的对错和 feedback。Argon 思考级别只能 LOW／MEDIUM／HIGH，默认 HIGH。
- 只审文字，不评判音频；Argon 判断双辅音长短不可靠。报告会给 pala／palla 这类最小对立词加备注：TTS 单独念词时双辅音可能不够长，音频要人工听。
- 工具不改内容文件。按报告手动改完、确认没问题的句子才标 `checked`，同时把 `checkedText` 设成当时的 `it`。

## 免费 Apple ID 的限制

- 只有一个 app target，不加任何扩展（小组件等）：扩展也占 3 个侧载名额。
- 不用 APNs 推送、iCloud、App Groups 等需要付费开发者账号的能力；提醒用本地通知。
- 不改 bundle ID。每周重装都要保住学习记录，持久化格式只做加法改动。

## 隐私（仓库是公开的）

- 真实行程、酒店地址、航班、过敏、住址等个人数据不进仓库，也不在编译时写进 app，一律在 app 里填写或导入。`Content/trip.json` 会被 CI 拦下。测试里的行程也只用假日期。
- 仓库只放 `Content/trip.example.json`（假日期）。
- 巡礼层只用地名、用户自己拍的照片和原创图形；不放原作截图、角色形象、台词原文或 logo。

## 内容规则

- 句子状态依次是 draft → checked（交叉校对）→ native（母语者抽检，可选）→ audio_ok（音频听审过）。没校对过的不许标 checked。
- 状态不是 draft 的句子必须带 `checkedText`，且等于 `it`：审核结论只对审过的那段原文有效，改了原文就要重新校对或退回 draft（`validate_content.py` 会拦）。
- 对陌生人一律用 Lei；自述句用阳性（Sono arrivato、Sono stanco）。
- 发音讲解：
  - 先听示范音频，再看近似写法；标准永远是音频，加上和自己录音的对比。
  - 搭桥只讲“某个音像什么”，可以借日语假名、拼音或英语，但不给整个词的假名或拼音转写。只有在对比长短、重音时才用假名片段（如 パッラ／パーラ）。
  - 每个搭桥后面跟一句“哪里不像”。
  - 明确提醒母语干扰：辅音连缀（pr、gr、str、sc）和词尾辅音（per、con、non）中间、后面都不加元音；u 要圆唇，日语う是扁的；外来语片假名不可信（カプチーノ、ユーロ）；重音靠响和长，不靠高低；拼音只借“b、d、g 不送气”这一点，c、q、x、r 不按拼音读，拼音的 b、d、g 是清音。
  - 英语只用在它更像的地方：辅音连缀、词尾辅音，以及 sh、ch、j（对应 sci、ci、gi）。英语的双元音、弱化元音和送气不要带进来。
- 只教“怎么问”，不写死票价、营业时间这类会变的事实。
- 句子里不写用到日：由场景的 `neededAt`（`first` / `last` / `city:<id>` / `event:<id>`）和用户填的行程推算。`city:`、`event:` 后面的 id 要在 `course.json` 的 `cities`、`events` 里。
- 音频文件名是哈希；manifest 的键是 `"<voice>|<speed>|<text>"`，必须和 `AudioManifest.key` 以及 `tools/` 里的实现保持一致。
- 单元 id 是 `Lxx` / `Cxx`，句子 id 是 `Lxx-nn`；`lessons/Lxx.json` 的文件名要和 `unit` 一致。
- 只有复习里的自评会更新 FSRS 记忆状态。上课只是把句子的卡加进来（新卡），挑战只记成绩，都不改卡片状态。
- 每句默认两张卡：听辨（listen）和回忆（recall），各自调度；复习时同一句的两张卡不连着出。

## 工作方式

- 从分支开 PR 合入 main；改了 App/、Packages/ 或 project.yml 的 PR 会触发 ios-build。
- 真机上没有 Xcode 控制台：排查问题时往 `AppLog` 写日志，用户在「今日 → 诊断与日志」里分享出来。
