# 交叉校对：L04 数字 0–20 与价格

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-17
- 6 条：6 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### L04/intro — ✅ OK

<details><summary>intro 原文</summary>

> 0–20：zero, uno, due, tre, quattro, cinque, sei, sette, otto, nove, dieci, undici, dodici, tredici, quattordici, quindici, sedici, diciassette, diciotto, diciannove, venti。
>
> 11–16 以 -dici 结尾，重音都在倒数第三个音节（UN-di-ci、DO-di-ci）；17–19 以 dici- 开头。最容易听混的是 due（2）／dodici（12）、tre（3）／tredici（13）、sei（6）／sedici（16）：听到 -dici 就是十几。
>
> 价格的说法是“欧元数 + e + 分数”：tre euro e cinquanta = 3.50 欧。口语里常省掉 euro，只说 tre e cinquanta。euro 的 eu 是从 e 滑到 u，两个元音都要读出来，不是外来语ユーロ的 yu；复数不变：un euro、due euro。店员报总价常用 Sono…：Sono dodici euro，这里的 Sono 是“一共是”，不是“我是”。

</details>

### L04-01 — ✅ OK

- **it**：Quanto costa?
- **zh**：多少钱？
- **note**：问一样东西的价钱。指着东西问可以说 Quanto costa questo?（这个多少钱？），问好几样用 Quanto costano?（这些多少钱？）。qu 读 kw，接近英语 quick 的 qu；不像的是英语的 k 送气，这里不送气，也不能按拼音 q 读。重音在 QUAN：QUAN-to。

### L04-02 — ✅ OK

- **it**：Quanto costa un biglietto?
- **zh**：一张票多少钱？
- **note**：Quanto costa 后面直接接东西，换成 un caffè、un cornetto 都行。

### L04-03 — ✅ OK

- **it**：Quant'è?
- **zh**：一共多少钱？
- **note**：结账时问总价最常用，是 Quanto è 的缩写；重音在最后的 è：quan-TÈ。

### L04-04 — ✅ OK

- **it**：Sono dodici euro.
- **zh**：一共十二欧。
- **note**：店员报价的说法，这里的 Sono 是“一共是”。dodici（12）别听成 due（2）：听到 -dici 就是十几。

### L04-05 — ✅ OK

- **it**：Tre euro e cinquanta.
- **zh**：三欧五十（3.50 欧）。
- **note**：cinquanta（50）和 quindici（15）容易混：-anta 是几十，-dici 是十几。
