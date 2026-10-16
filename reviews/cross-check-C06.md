# 交叉校对：C06 节日里的那不勒斯

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 33 条：33 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### C06/aperto/npc1 — ✅ OK

- **it**：Buonasera!
- **zh**：晚上好！

### C06/aperto/npc2 — ✅ OK

- **it**：Buonasera, prego!
- **zh**：晚上好，请进！

### C06/aperto/choice1 — ✅ OK

- **✔ 正确选项**：Buonasera. È aperto anche oggi?

补充：问店家是否营业，除了用单数 È aperto…?（指店铺，或对店主用尊称 Lei），日常也很常用复数 Siete aperti anche oggi?（你们今天也开门吗？）。

### C06/aperto/choice2 — ✅ OK

- **✘ 错误选项**：Buonasera. È aperto anche domani?
- **feedback**：domani 是明天。你要问的是今天：oggi。

### C06/aperto/choice3 — ✅ OK

- **✘ 错误选项**：Buonasera. Sono aperto anche oggi?
- **feedback**：sono 是“我是”，这句成了“我今天也开门吗”。问店家用 È aperto…?

### C06/chiude/npc1 — ✅ OK

- **it**：Sì, siamo aperti! Ma oggi è festa e chiudiamo prima.
- **zh**：开着呢！不过今天过节，我们关得早。

### C06/chiude/npc2 — ✅ OK

- **it**：Certo, entri pure! Oggi però è festa: chiudiamo presto.
- **zh**：当然，请进！不过今天过节，我们早关门。

### C06/chiude/choice1 — ✅ OK

- **✔ 正确选项**：A che ora chiude oggi?

补充：因为店员刚用了复数 chiudiamo（我们关门），这里除了用单数 chiude（指店铺或尊称您），也常顺着对方说 A che ora chiudete oggi?（你们今天几点关门？）。

### C06/chiude/choice2 — ✅ OK

- **✘ 错误选项**：A che ora apre oggi?
- **feedback**：apre 是开门。店已经开着，你要问几点关门：chiude。

### C06/chiude/choice3 — ✅ OK

- **✘ 错误选项**：A che ora chiudo oggi?
- **feedback**：chiudo 是“我关门”。问店家几点关门要说 chiude。

### C06/orario/npc1 — ✅ OK

- **it**：Oggi chiudiamo alle ventuno.
- **zh**：今天我们 21 点关门。
- **answer**：21:00（干扰项：20:00、23:00）

### C06/orario/npc2 — ✅ OK

- **it**：Oggi chiudiamo alle diciannove e trenta.
- **zh**：今天我们 19 点半关门。
- **answer**：19:30（干扰项：17:30、09:30）

### C06/orario/npc3 — ✅ OK

- **it**：Oggi chiudiamo alle diciotto.
- **zh**：今天我们 18 点关门。
- **answer**：18:00（干扰项：16:00、08:00）

### C06/orario/choice1 — ✅ OK

- **✔ 正确选项**：Allora, una margherita da portare via, per favore. Quanto devo aspettare?

补充：问等待时间除了 Quanto devo aspettare?，在实际生活中也很常听到店员或顾客说 Quanto c'è da aspettare?（要等多久？）。

### C06/orario/choice2 — ✅ OK

- **✘ 错误选项**：Allora, una margherita da mangiare qui, per favore. Quanto devo aspettare?
- **feedback**：da mangiare qui 是在店里吃。这次要外带：da portare via。

### C06/orario/choice3 — ✅ OK

- **✘ 错误选项**：Allora, una margherita da portare via, per favore. Quanto devo pagare?
- **feedback**：pagare 是付钱。想问要等多久，要说 aspettare。

### C06/attesa/npc1 — ✅ OK

- **it**：Circa venti minuti: oggi c'è tanta gente!
- **zh**：大概 20 分钟，今天人很多！
- **answer**：20 分钟（干扰项：10 分钟、12 分钟）

### C06/attesa/npc2 — ✅ OK

- **it**：Dieci minuti, più o meno.
- **zh**：10 分钟左右。
- **answer**：10 分钟（干扰项：2 分钟、20 分钟）

### C06/attesa/npc3 — ✅ OK

- **it**：Un quarto d'ora, più o meno.
- **zh**：一刻钟左右。
- **answer**：15 分钟（干扰项：4 分钟、30 分钟）

### C06/auguri/npc1 — ✅ OK

- **it**：Ecco la sua margherita. Buone feste!
- **zh**：这是您的玛格丽特。节日快乐！

### C06/auguri/npc2 — ✅ OK

- **it**：Ecco a lei, e buone feste!
- **zh**：给您，节日快乐！

### C06/auguri/choice1 — ✅ OK

- **✔ 正确选项**：Grazie, buone feste anche a lei!

补充：回祝对方节日快乐时，除了 buone feste anche a lei，日常也很常说 Grazie, altrettanto!（谢谢，您也是/同乐！）。

### C06/auguri/choice2 — ✅ OK

- **✘ 错误选项**：Prego, buone feste!
- **feedback**：prego 是“不客气”。对方把披萨递给你，你要说 Grazie。

### C06/auguri/choice3 — ✅ OK

- **✘ 错误选项**：Grazie, buon appetito anche a lei!
- **feedback**：buon appetito 是“请慢用”，吃饭时才说。回节日祝福要说 buone feste anche a lei。

### C06/bere/npc1 — ✅ OK

- **it**：Vuole anche qualcosa da bere?
- **zh**：还要点喝的吗？

### C06/bere/choice1 — ✅ OK

- **✔ 正确选项**：No, grazie. Basta così.

### C06/bere/choice2 — ✅ OK

- **✘ 错误选项**：Sì, grazie. Basta così.
- **feedback**：Sì 是“要”，和 Basta così（就这些）矛盾。

### C06/bere/choice3 — ✅ OK

- **✘ 错误选项**：No, prego.
- **feedback**：prego 是“不客气”或“请”，拒绝时说 No, grazie。

### C06/pagamento/npc1 — ✅ OK

- **it**：Contanti o carta?
- **zh**：现金还是刷卡？

### C06/pagamento/npc2 — ✅ OK

- **it**：Paga in contanti o con la carta?
- **zh**：您付现金还是刷卡？

### C06/pagamento/choice1 — ✅ OK

- **✔ 正确选项**：Con la carta, grazie.

补充：日常口语里也可以直接简略回答“Carta, grazie.”。

### C06/pagamento/choice2 — ✅ OK

- **✘ 错误选项**：In contanti, grazie.
- **feedback**：这是付现金。这次的任务是刷卡：Con la carta。

### C06/pagamento/choice3 — ✅ OK

- **✘ 错误选项**：Con la cassa, grazie.
- **feedback**：cassa 是收银台。刷卡说 con la carta。
