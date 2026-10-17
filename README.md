# Mamma mia! 意大利语巡礼

自用的意大利语旅行学习 app（iOS 26 起）。中文讲解，12 个万能句框 × 旅行场景，30 课 + 10 个情境挑战，FSRS 间隔复习，示范音频离线可用。联网时还可以和 AI 扮演的角色自由对话（用自己的 Google key，在「对话 → 在线对话设置」里填），只作加练。

## 装到手机上

没有 Mac 也能装：GitHub Actions 编出未签名的 IPA，用免费 Apple ID 通过 SideStore 侧载，每 7 天续签一次。步骤见 [docs/sideload.md](docs/sideload.md)。

## 目录

| 路径 | 内容 |
| --- | --- |
| `App/` | SwiftUI 界面 |
| `Packages/MammaCore/` | 调度、判定、内容解析（Linux 上可测） |
| `Content/` | 课程数据和 JSON Schema |
| `Audio/` | 预生成的示范音频和 manifest |
| `tools/` | 内容校验等脚本 |
| `project.yml` | XcodeGen 工程定义 |

开发约定见 [CLAUDE.md](CLAUDE.md)。

## 个人数据

仓库是公开的。行程、酒店地址这类个人数据不进仓库，在 app 里填写（「随身 → 填写行程」），只存在手机上和导出的进度备份里；仓库里的 `Content/trip.example.json` 用的是假日期。
