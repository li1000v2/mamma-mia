# 交叉校对：L01 发音①：拼读规则

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-17
- 6 条：6 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### L01/intro — ✅ OK

<details><summary>intro 原文</summary>

> 意大利语基本是怎么写就怎么读，这一课记四条规则。先听每个词的示范音频，再对照规则看拼写；下面借日语、英语和拼音帮你找到那个音，每条都写了哪里不像，最后以音频为准。
>
> 1. c、g 在 e、i 前读软音：ce、ci 的辅音接近英语 church 的 ch，日语チ的辅音也差不多；ge、gi 接近英语 jam 的 j，日语ジ的辅音也差不多。不像的地方：英语的 ch 常带一口气，意大利语不送气；日语ジ夹在元音中间时常读得很松，舌头不完全堵住，意大利语的 gi 每次都要先堵住再放开。ci、gi 后面再跟 a、o、u 时，i 本身不发音，只表示前面读软音：ciao 是 cia-o 两个音节，giorno 是 gior-no。在 a、o、u 前读硬音 k、g：caffè、gola。
> 2. 想在 e、i 前读硬音，就加一个 h：che、chi 读 ke、ki，ghe、ghi 读 ge、gi（chiesa、anche、spaghetti）。h 本身不发音。
> 3. gn 接近日语にゃ行的辅音（gnocchi、bagno）；不像的地方：夹在两个元音之间时要读长一点。gli 的 g 不发音，舌面整个贴住上颚发 l，接近拼音的 l 但舌头抬高；不像的地方：日语リャ是舌尖弹一下，这里舌面贴住不动。gli 后面再跟元音时，i 也不单独发音：biglietto、famiglia。
> 4. sc 在 e、i 前读 sh，接近英语 she 的 sh（uscita、pesce），夹在两个元音之间要读长；sci 后面再跟 a、o、u 时，i 也不发音：lasciare 的 scia 只是 sh 加 a。在 a、o、u 前，以及 sch，都读 sk（scusi；pesche 桃子 ≠ pesce 鱼）。
>
> 还有一条最容易被母语带偏：辅音连在一起时，中间不加元音。scusi 开头的 sc 是一口气的 sk，不要读出“su”；pr、gr、str 也一样。英语里本来就有这类连缀（school、price、street），可以借英语的感觉。

</details>

### L01-01 — ✅ OK

- **it**：Ciao!
- **zh**：你好！／再见！
- **note**：cia 里的 i 不发音，只表示 c 读软音：ciao 是 cia-o 两个音节，不是 ci-a-o 三个。只对朋友用；对店员、陌生人说 Buongiorno，下午起改说 Buonasera。

### L01-02 — ✅ OK

- **it**：chiesa
- **zh**：教堂
- **note**：ch 是硬音 k；chie 是一个音节，chiesa 是 CHIE-sa 两个音节。两个元音之间的 s，北方多读 z，中南部常读 s，两种都对。

### L01-03 — ✅ OK

- **it**：gnocchi
- **zh**：意式土豆团子
- **note**：gn 接近日语にゃ行的辅音；cchi 是双辅音加硬音，c 前要停一拍，像日语促音っ。重音在 GNOC：GNOC-chi。gn 夹在两个元音之间要读长，比如 bagno（洗手间）。

⚠️ 最小对立词 chi/cchi：TTS 单独念词时双辅音可能不够长，音频需要人工听。

### L01-04 — ✅ OK

- **it**：biglietto
- **zh**：票
- **note**：gli 的 g 不发音，glie 是一个音节，舌面贴住上颚，不是舌尖弹一下；tt 前要停一拍，像促音っ。重音在 GLIET：bi-GLIET-to。买船票、火车票、门票都用这个词。

### L01-05 — ✅ OK

- **it**：uscita
- **zh**：出口
- **note**：sc 在 i 前读 sh，接近英语 she 的 sh；后面的 i 照常读出来，不像 ciao 里的 i 那样不发音。sc 夹在两个元音之间要读长一点。重音在 SCI：u-SCI-ta。车站和景点到处是 USCITA 的牌子。
