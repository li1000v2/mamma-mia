# 交叉校对：L10 时间与营业时间

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 6 条：5 条 OK，1 条建议修改（其中 1 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 需要看的条目

- **L10-05**：错误，quindici 的重音在第一音节（['kwinditʃi]），应标为 QUIN-di-ci，而不是 quin-DI-ci。

## 逐条结果

### L10/intro — ✅ OK

<details><summary>intro 原文</summary>

> 句框 A che ora…?（几点……？）后面接动词：A che ora apre?（几点开门？）、A che ora chiude?（几点关门？）。问的是店、博物馆，所以用“它”的形式 apre、chiude。L09 学过的 A che ora è la colazione? 也是这个句框。
>
> 回答“几点”用 alle + 数字：alle nove（9 点）、alle dieci（10 点）。只有 1 点特殊，说 all'una。
>
> 时刻表和营业时间都用 24 小时制，读法是“小时 e 分钟”，和日语「15時30分」一样把两个数连起来：15:30 = alle quindici e trenta，21:15 = alle ventuno e quindici。口语里也常用 12 小时制：alle tre e mezza（三点半）。营业时间常说成 dalle… alle…（从……到……）：dalle nove alle diciotto（9 点到 18 点）。
>
> 门口的牌子：APERTO（营业中）、CHIUSO（关门）。小店中午可能关一段时间，节假日也常有变化。营业时间会变，以当天门口的告示和官网为准。
>
> 发音先听示范音频，标准是音频；note 里的近似说法只帮你找音，不是读法。apre 的 pr、trenta 的 tr 中间都不加元音。

</details>

### L10-01 — ✅ OK

- **it**：A che ora apre?
- **zh**：几点开门？
- **note**：apre 是 aprire（开）的“它”的形式，读 A-pre。pr 像英语 pray 的 pr；哪里不像：英语的 p 送气、r 卷舌，这里 p 不送气，r 是舌尖弹一下。回答：Alle nove（9 点）、Alle dieci e mezza（10 点半）。

### L10-02 — ✅ OK

- **it**：A che ora chiude?
- **zh**：几点关门？
- **note**：chiude 读 CHIU-de：ch 是 k，不送气，像拼音 g（拼音的 g 本来就是清音）；哪里不像：拼音的 g 不接 i，chiu 要保持硬的 k，别滑成拼音的 jiu。u 要圆唇。问具体的地方就加在后面：A che ora chiude il museo?

### L10-03 — ✅ OK

- **it**：È aperto oggi?
- **zh**：今天开门吗？
- **note**：aperto 是“开着的”，读 a-PER-to，r 弹一下直接接 t，中间不加元音。反义词是 chiuso（关着的）。也跟着阴阳性变（L07）：il museo、il negozio 用 aperto；la farmacia、la chiesa 用 aperta：È aperta oggi?

### L10-04 — ✅ OK

- **it**：No, oggi è chiuso.
- **zh**：不，今天不开门。
- **note**：听懂就行。chiuso 读 CHIU-so，和 chiude 同一个开头。门口写着 CHIUSO 就是关门；chiuso per ferie 是“休假，暂停营业”。

### L10-05 — ✏️ 建议修改

- **it**：Alle quindici e trenta.
- **zh**：下午三点半（15:30）。
- **note**：24 小时制：alle + 小时 + e + 分钟。quindici（quin-DI-ci，15）别听成 cinque（CIN-que，5）；trenta（TREN-ta，30）别听成 tredici（TRE-di-ci，13），tr 中间不加元音。口语也说 alle tre e mezza。

| 字段 | 级别 | 问题 | 建议写法 |
| --- | --- | --- | --- |
| note | 错误 | quindici 的重音在第一音节（['kwinditʃi]），应标为 QUIN-di-ci，而不是 quin-DI-ci。 | 24 小时制：alle + 小时 + e + 分钟。quindici（QUIN-di-ci，15）别听成 cinque（CIN-que，5）；trenta（TREN-ta，30）别听成 tredici（TRE-di-ci，13），tr 中间不加元音。口语也说 alle tre e mezza。 |
