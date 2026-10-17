# 交叉校对：C04 威尼斯晚餐

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-17
- 35 条：35 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### C04/tavolo/npc1 — ✅ OK

- **it**：Buonasera! Prego.
- **zh**：晚上好！请进。

### C04/tavolo/npc2 — ✅ OK

- **it**：Buonasera, benvenuto!
- **zh**：晚上好，欢迎光临！

### C04/tavolo/choice1 — ✅ OK

- **✔ 正确选项**：Buonasera! Avete un tavolo per una persona?

补充：口语中也常把 per una persona 简化成 per uno（Avete un tavolo per uno? / C'è un tavolo per uno?）。

### C04/tavolo/choice2 — ✅ OK

- **✘ 错误选项**：Buonasera! Ho un tavolo per una persona?
- **feedback**：Ho 是“我有”。问店里有没有位子用 Avete…?；订过位才说 Ho prenotato un tavolo。

### C04/tavolo/choice3 — ✅ OK

- **✘ 错误选项**：Buonasera! Sono un tavolo per una persona.
- **feedback**：Sono 是“我是”，这句成了“我是一张一人桌”。

### C04/menu/npc1 — ✅ OK

- **it**：Certo, si accomodi. Ecco il menù.
- **zh**：有，请坐。这是菜单。

### C04/menu/npc2 — ✅ OK

- **it**：Sì, prego, da questa parte. Ecco il menù.
- **zh**：有，请这边走。这是菜单。

### C04/menu/choice1 — ✅ OK

- **✔ 正确选项**：Grazie. Che cosa mi consiglia?

### C04/menu/choice2 — ✅ OK

- **✘ 错误选项**：Grazie. Che cosa le consiglio?
- **feedback**：le consiglio 是“我推荐给您”，主客颠倒了。请对方推荐说 Che cosa mi consiglia?

### C04/menu/choice3 — ✅ OK

- **✘ 错误选项**：Grazie. Il conto, per favore.
- **feedback**：Il conto 是结账，你才刚坐下。

### C04/consiglio/npc1 — ✅ OK

- **it**：Le consiglio il risotto al nero di seppia, è tipico di Venezia. Ha allergie o intolleranze?
- **zh**：我推荐墨鱼汁烩饭，是威尼斯特色。您有过敏或不耐受吗？

### C04/consiglio/npc2 — ✅ OK

- **it**：Stasera le sarde in saor sono buonissime. Ha qualche allergia?
- **zh**：今晚的醋渍沙丁鱼特别好吃。您有什么过敏吗？

### C04/consiglio/npc3 — ✅ OK

- **it**：Le consiglio gli spaghetti alle vongole. Ha allergie?
- **zh**：我推荐蛤蜊意面。您有过敏吗？

### C04/consiglio/choice1 — ✅ OK

- **✔ 正确选项**：Sì, sono allergico ai crostacei.

### C04/consiglio/choice2 — ✅ OK

- **✘ 错误选项**：Sì, ho allergico ai crostacei.
- **feedback**：说自己的状态用 Sono：Sono allergico a…。ho 是“我有”，后面不能接 allergico。

### C04/consiglio/choice3 — ✅ OK

- **✘ 错误选项**：Sì, sono crostacei.
- **feedback**：少了 allergico ai，这句成了“我是虾蟹”。

### C04/dolce/npc1 — ✅ OK

- **it**：Tutto bene? Desidera un dolce o un caffè?
- **zh**：还满意吗？要甜点或咖啡吗？

### C04/dolce/npc2 — ✅ OK

- **it**：Allora, tutto bene? Un dolce, un caffè?
- **zh**：怎么样，还满意吗？来份甜点、来杯咖啡吗？

### C04/dolce/choice1 — ✅ OK

- **✔ 正确选项**：No, grazie. Il conto, per favore.

### C04/dolce/choice2 — ✅ OK

- **✘ 错误选项**：No, grazie. Il coperto, per favore.
- **feedback**：coperto 是座位费。叫结账说 Il conto, per favore。

### C04/dolce/choice3 — ✅ OK

- **✘ 错误选项**：No, grazie. Il menù, per favore.
- **feedback**：这是要菜单。吃完了要结账：Il conto, per favore。

### C04/conto/npc1 — ✅ OK

- **it**：Ecco il conto: sono ventotto euro, coperto compreso.
- **zh**：这是账单：一共二十八欧，含座位费。
- **answer**：28 €（干扰项：8 €、38 €）

### C04/conto/npc2 — ✅ OK

- **it**：Ecco a lei: trentasei euro, con il coperto.
- **zh**：给您：三十六欧，含座位费。
- **answer**：36 €（干扰项：6 €、26 €）

### C04/conto/npc3 — ✅ OK

- **it**：Sono quarantadue euro, coperto compreso.
- **zh**：一共四十二欧，含座位费。
- **answer**：42 €（干扰项：32 €、24 €）

### C04/conto/choice1 — ✅ OK

- **✔ 正确选项**：Posso pagare con la carta?

### C04/conto/choice2 — ✅ OK

- **✘ 错误选项**：Posso pagare con il coperto?
- **feedback**：coperto 是座位费，不是付款方式。问能不能刷卡：Posso pagare con la carta?

### C04/conto/choice3 — ✅ OK

- **✘ 错误选项**：Ho pagato con la carta?
- **feedback**：这句是“我刷卡付过了吗？”。问能不能刷卡用 Posso pagare con la carta?

### C04/acqua/npc1 — ✅ OK

- **it**：Va bene, allora niente crostacei. Da bere? Acqua naturale o frizzante?
- **zh**：好的，那就不放虾蟹。喝点什么？不带气的水还是带气的？

### C04/acqua/choice1 — ✅ OK

- **✔ 正确选项**：Naturale, grazie.

补充：不带气的水除了最通用的 acqua naturale，有时也会听到服务员说 acqua liscia（而微气泡水叫 leggera 或 leggermente frizzante）。

### C04/acqua/choice2 — ✅ OK

- **✘ 错误选项**：Sì, grazie.
- **feedback**：对方问的是不带气还是带气，二选一，回答 Sì 等于没回答。

### C04/acqua/choice3 — ✅ OK

- **✘ 错误选项**：Il conto, per favore.
- **feedback**：Il conto 是结账，饭还没吃呢。

### C04/vino/npc1 — ✅ OK

- **it**：Va bene, allora niente crostacei. Da bere, un bicchiere di vino?
- **zh**：好的，那就不放虾蟹。喝的呢，来杯葡萄酒吗？

### C04/vino/choice1 — ✅ OK

- **✔ 正确选项**：No, grazie. Un'acqua naturale, per favore.

补充：口语中直接说 Un'acqua naturale 就能表示要一瓶（或一份）不带气的水，也可以完整说 Una bottiglia d'acqua naturale。

### C04/vino/choice2 — ✅ OK

- **✘ 错误选项**：No, grazie. Uno acqua naturale, per favore.
- **feedback**：acqua 是阴性、元音开头，要说 un'acqua。uno 只用在 s+辅音或 z 开头的阳性词前。

### C04/vino/choice3 — ✅ OK

- **✘ 错误选项**：No, grazie. Sono allergico all'acqua.
- **feedback**：这句成了“我对水过敏”。要水就说 Un'acqua naturale, per favore。
