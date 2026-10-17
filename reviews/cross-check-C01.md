# 交叉校对：C01 听不懂也不慌

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-17
- 18 条：18 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### C01/fast/npc1 — ✅ OK

- **it**：Buongiorno! Allora, oggi abbiamo cornetti alla crema, al cioccolato e integrali: cosa le do?
- **zh**：早上好！今天有奶油、巧克力和全麦的羊角面包，您要什么？

补充：羊角面包在罗马、那不勒斯等中南部地区叫 cornetto，而在威尼斯等北方地区常叫 brioche（不过说 cornetto 店员也都听得懂）。

### C01/fast/choice1 — ✅ OK

- **✔ 正确选项**：Scusi, non ho capito. Più piano, per favore.

### C01/fast/choice2 — ✅ OK

- **✘ 错误选项**：Sì, grazie.
- **feedback**：还没听懂对方在问什么就说“好的，谢谢”，会答非所问。听不懂时先直说没听懂。

### C01/fast/choice3 — ✅ OK

- **✘ 错误选项**：Non capito.
- **feedback**：少了 ho：要说 Non ho capito。

### C01/slow/npc1 — ✅ OK

- **it**：Cornetti: crema, cioccolato o integrale?
- **zh**：羊角面包：奶油的、巧克力的，还是全麦的？

### C01/slow/choice1 — ✅ OK

- **✔ 正确选项**：Un cornetto al cioccolato, per favore.

### C01/slow/choice2 — ✅ OK

- **✘ 错误选项**：Una cioccolata, per favore.
- **feedback**：cioccolata 是热巧克力饮料。巧克力馅的面包说 al cioccolato。

### C01/slow/choice3 — ✅ OK

- **✘ 错误选项**：Ho un cornetto al cioccolato.
- **feedback**：Ho 是“我有”。点东西直接说要的东西，再加 per favore。

### C01/price/npc1 — ✅ OK

- **it**：Sono un euro e venti.
- **zh**：一共一欧二十。

### C01/price/npc2 — ✅ OK

- **it**：Un euro e trenta, grazie.
- **zh**：一欧三十，谢谢。

### C01/price/choice1 — ✅ OK

- **✔ 正确选项**：Me lo può scrivere?

### C01/price/choice2 — ✅ OK

- **✘ 错误选项**：Lo scrivo io.
- **feedback**：这是“我来写”。要请对方写：Me lo può scrivere?

### C01/price/choice3 — ✅ OK

- **✘ 错误选项**：Può pagare?
- **feedback**：这是“您能付钱吗”，变成你让店员付钱了。

### C01/bye/npc1 — ✅ OK

- **it**：Certo, ecco. Grazie e buona giornata!
- **zh**：当然，给您。谢谢，祝您今天愉快！

### C01/altro/npc1 — ✅ OK

- **it**：Altro?
- **zh**：还要别的吗？

### C01/altro/choice1 — ✅ OK

- **✔ 正确选项**：No, grazie. Basta così.

### C01/altro/choice2 — ✅ OK

- **✘ 错误选项**：Sì, grazie. Basta così.
- **feedback**：Sì 是“要”，和 Basta così（就这些）矛盾。

### C01/altro/choice3 — ✅ OK

- **✘ 错误选项**：No, prego.
- **feedback**：prego 是“不客气”或“请”，拒绝时说 No, grazie。
