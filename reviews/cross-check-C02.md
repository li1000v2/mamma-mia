# 交叉校对：C02 咖啡吧全流程

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 19 条：19 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### C02/order/npc1 — ✅ OK

- **it**：Buongiorno, dica!
- **zh**：早上好，您要点什么？

补充：口语中店员也常说“Buongiorno, mi dica!”。

### C02/order/choice1 — ✅ OK

- **✔ 正确选项**：Buongiorno! Un cappuccino e una brioche, per favore.

补充：羊角面包在意大利北部（如威尼斯、米兰）常叫 una brioche，而在中南部（如佛罗伦萨、罗马）通常叫 un cornetto。

### C02/order/choice2 — ✅ OK

- **✘ 错误选项**：Buongiorno! Ho un cappuccino e una brioche.
- **feedback**：Ho 是“我有”。点单直接说要的东西加 per favore，或者用 Prendo…

### C02/order/choice3 — ✅ OK

- **✘ 错误选项**：Buongiorno! Sono un cappuccino e una brioche.
- **feedback**：Sono 是“我是”，这句成了“我是一杯卡布奇诺和一个羊角面包”。

### C02/price/npc1 — ✅ OK

- **it**：Sono tre euro e cinquanta.
- **zh**：一共三欧五十。
- **answer**：3.50 €（干扰项：3.15 €、13.50 €）

### C02/price/npc2 — ✅ OK

- **it**：Sono due euro e ottanta.
- **zh**：一共两欧八十。
- **answer**：2.80 €（干扰项：2.18 €、12.80 €）

### C02/price/npc3 — ✅ OK

- **it**：Sono cinque euro e sessanta.
- **zh**：一共五欧六十。
- **answer**：5.60 €（干扰项：5.16 €、15.60 €）

### C02/price/choice1 — ✅ OK

- **✔ 正确选项**：Posso pagare con la carta?

### C02/price/choice2 — ✅ OK

- **✘ 错误选项**：Posso pagare in contanti?
- **feedback**：这句是问能不能付现金，这次的任务是刷卡。

### C02/price/choice3 — ✅ OK

- **✘ 错误选项**：Posso mangiare con la carta?
- **feedback**：mangiare 是“吃”。付钱是 pagare。

### C02/receipt/npc1 — ✅ OK

- **it**：Certo. Ecco lo scontrino.
- **zh**：当然。这是您的小票。

### C02/banco/npc1 — ✅ OK

- **it**：Al banco o al tavolo?
- **zh**：站在吧台喝，还是坐下？

### C02/banco/choice1 — ✅ OK

- **✔ 正确选项**：Al banco.

### C02/banco/choice2 — ✅ OK

- **✘ 错误选项**：Al tavolo, per favore.
- **feedback**：这是要坐下，坐下通常更贵。这次的任务是站着喝。

### C02/banco/choice3 — ✅ OK

- **✘ 错误选项**：Al bagno.
- **feedback**：bagno 是洗手间。

### C02/altro/npc1 — ✅ OK

- **it**：Altro?
- **zh**：还要别的吗？

### C02/altro/choice1 — ✅ OK

- **✔ 正确选项**：No, grazie. Basta così.

### C02/altro/choice2 — ✅ OK

- **✘ 错误选项**：Sì, grazie. Basta così.
- **feedback**：Sì 是“要”，和 Basta così（就这些）矛盾。

### C02/altro/choice3 — ✅ OK

- **✘ 错误选项**：No, prego.
- **feedback**：prego 是“不客气”或“请”，拒绝时说 No, grazie。
