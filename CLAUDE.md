# Mamma mia! — 给编码代理的约定

自用的意大利语旅行学习 iOS app：中文讲解，12 个万能句框 × 旅行场景，FSRS 复习，示范音频离线可用。
没有本地 Mac：代码推到 GitHub，Actions 的 macOS runner 编译并产出未签名 IPA，用免费 Apple ID + SideStore 侧载。

## 目录

- `project.yml`：XcodeGen 工程定义。只改它，不手改 `.xcodeproj`（已 gitignore，CI 每次重新生成）。
- `App/`：SwiftUI 界面，Swift 5 语言模式。只放界面和 iOS 专属能力（录音、识别、通知）。
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
- app 里没有音频的句子会退回 iOS 自带的意大利语语音。挑战剧本可以用 `voice` 指定角色的声线。

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

- 真实行程、酒店地址、航班、过敏、住址等个人数据不进仓库，也不在编译时写进 app，一律在 app 里导入。`Content/trip.json` 会被 CI 拦下。
- 仓库只放 `Content/trip.example.json`（假日期）。
- 巡礼层只用地名、用户自己拍的照片和原创图形；不放原作截图、角色形象、台词原文或 logo。

## 内容规则

- 句子状态依次是 draft → checked（交叉校对）→ native（母语者抽检，可选）→ audio_ok（音频听审过）。没校对过的不许标 checked。
- 状态不是 draft 的句子必须带 `checkedText`，且等于 `it`：审核结论只对审过的那段原文有效，改了原文就要重新校对或退回 draft（`validate_content.py` 会拦）。
- 对陌生人一律用 Lei；自述句用阳性（Sono arrivato、Sono stanco）。
- 只教“怎么问”，不写死票价、营业时间这类会变的事实。
- 句子里不写用到日：由场景的 `neededAt`（`first` / `last` / `city:<id>` / `event:<id>`）和导入的行程推算。
- 音频文件名是哈希；manifest 的键是 `"<voice>|<speed>|<text>"`，必须和 `AudioManifest.key` 以及 `tools/` 里的实现保持一致。
- 单元 id 是 `Lxx` / `Cxx`，句子 id 是 `Lxx-nn`；`lessons/Lxx.json` 的文件名要和 `unit` 一致。
- 只有复习里的自评会更新 FSRS 记忆状态。上课只是把句子的卡加进来（新卡），挑战只记成绩，都不改卡片状态。
- 每句默认两张卡：听辨（listen）和回忆（recall），各自调度；复习时同一句的两张卡不连着出。

## 工作方式

- 从分支开 PR 合入 main；改了 App/、Packages/ 或 project.yml 的 PR 会触发 ios-build。
- 真机上没有 Xcode 控制台：排查问题时往 `AppLog` 写日志，用户在「今日 → 诊断与日志」里分享出来。
