# 交叉校对：L05 咖啡吧点单

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-17
- 6 条：6 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### L05/intro — ✅ OK

<details><summary>intro 原文</summary>

> 点单句框 Prendo… / Vorrei…：Prendo 是“我要”，直接；Vorrei 是“我想要”，更客气。后面直接接东西，再加 per favore：Prendo un cappuccino. / Vorrei un caffè, per favore.
>
> 在意大利点 un caffè，端上来的就是一小杯浓缩咖啡。
>
> 吧台的流程：客人多的吧台通常先到收银台（cassa）点单付款、拿小票（scontrino），再把小票交给吧台。收银员常问 Al banco o al tavolo?：站在吧台喝（al banco）通常比坐下（al tavolo）便宜。也有小店是先喝后付，拿不准就问 Si paga prima?（是先付钱吗？）。

</details>

### L05-01 — ✅ OK

- **it**：Prendo un cappuccino.
- **zh**：我要一杯卡布奇诺。
- **note**：cappuccino 有两组双辅音：cap-puc-CI-no，pp 和 cc 前都要停一拍。日语外来语カプチーノ把这两拍都省了，别照着它读。

### L05-02 — ✅ OK

- **it**：Vorrei un caffè, per favore.
- **zh**：请给我一杯咖啡。
- **note**：在意大利点 un caffè，端上来的就是一小杯浓缩咖啡。Vorrei 的 rr 要颤，重音在后面：vor-REI。

### L05-03 — ✅ OK

- **it**：Al banco.
- **zh**：站在吧台喝。
- **note**：回答 “Al banco o al tavolo?”（站着喝还是坐下）。坐下通常更贵。

### L05-04 — ✅ OK

- **it**：Un cappuccino e una brioche, per favore.
- **zh**：请来一杯卡布奇诺和一个羊角面包。
- **note**：羊角面包在威尼斯常叫 brioche（法语词，照法语读，结尾是 sh 音），在那不勒斯和罗马叫 cornetto。

补充：如果在罗马或那不勒斯换用阳性名词 cornetto，前面的不定冠词要相应变为 un（Un cappuccino e un cornetto）。

### L05-05 — ✅ OK

- **it**：Al banco o al tavolo?
- **zh**：站在吧台喝，还是坐下？
- **note**：收银员常问的话，听懂就行。回答 Al banco 或 Al tavolo。tavolo 重音在倒数第三个音节：TA-vo-lo。
