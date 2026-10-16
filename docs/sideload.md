# 用 SideStore 装到 iPhone

免费 Apple ID 签出来的 app 只能用 7 天，SideStore 负责在手机上续签。第一次安装需要一台 Windows 电脑，之后都在手机上完成。

官方说明：[准备工作](https://docs.sidestore.io/docs/installation/prerequisites) · [安装](https://docs.sidestore.io/docs/installation/install)。下面是按官方步骤整理的顺序，界面文字以官方文档和实际界面为准。

## 一、电脑上（只做一次）

1. 装 iTunes。官方推荐用 Apple 官网的版本，不行再试 Microsoft Store 版或 Apple Devices。
2. 下载并安装 iloader（推荐 MSI 版）。

## 二、手机上（只做一次）

1. 在 App Store 装 LocalDevVPN，打开后点 Connect，按提示允许添加 VPN 配置。
2. 之后在 SideStore 里安装、更新、续签时，都要让 LocalDevVPN 保持连接，并且连着 Wi-Fi（官方说明蜂窝数据不行）。

## 三、装 SideStore

1. 用数据线连接 iPhone 和电脑；手机上提示“信任此电脑”时点信任并输入密码。
2. 打开 iloader，登录你的 Apple 账号（自己在 iloader 里输入），选中设备，点 “Install SideStore (Stable)”。
3. 手机上：设置 → 通用 → VPN 与设备管理，在“开发者 App”下选你的 Apple 账号，点信任。
4. 如果系统要求：设置 → 隐私与安全性，拉到最下面打开“开发者模式”，手机会重启。
5. 打开 LocalDevVPN 点 Connect，再打开 SideStore，用同一个 Apple 账号登录。
6. 在 “My Apps” 里点 SideStore 旁边的 “7 DAYS” 续签一次；如果提示新建签名证书，点确认。

## 四、装 Mamma mia!

1. 在 iPhone 的 Safari 里打开本仓库的 Releases 页，下载最新的 `MammaMia.ipa`（会存进「文件」的“下载”）。
   也可以从 Actions 里 `ipa` 工作流的运行记录下载，那是一个 zip，需要先在「文件」里解压。
2. LocalDevVPN 保持连接，在 SideStore 的 “My Apps” 里点 “+”，选刚下载的 `MammaMia.ipa`。
3. 打开 app，在「今日 → 诊断与日志」里核对版本号和提交号，确认装的是最新构建。

## 五、马上测一次续签

装好后立刻在 “My Apps” 里点 Mamma mia! 旁边的天数续签一次，看它是否重新变回 7 天。
能续成功，说明手机上续签这条路在你的 iOS 版本上走得通；失败的话，把 SideStore 的报错截图发回来。

## 记住这几条

- 免费账号最多同时装 3 个侧载 app（SideStore 自己算一个），每周最多新注册 10 个 App ID。
- 签名 7 天过期。过期后 app 打不开，但数据还在，续签后恢复。
- 每次装新版本也会刷新 7 天的期限。
- 旅途中每到一个有 Wi-Fi 的地方就顺手续一次，别等快过期再续。
