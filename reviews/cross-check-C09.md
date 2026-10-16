# 交叉校对：C09 突发状况

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 33 条：32 条 OK，1 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 需要看的条目

- **C09/aiuto/npc2**：建议，场景是在药店，药剂师说的“Desidera?”译成“您要点什么？”听起来像餐厅或咖啡馆点单，在药店说“您需要什么？”更自然。

## 逐条结果

### C09/aiuto/npc1 — ✅ OK

- **it**：Buongiorno, mi dica.
- **zh**：您好，您需要什么？

### C09/aiuto/npc2 — ✏️ 建议修改

- **it**：Buonasera! Desidera?
- **zh**：晚上好！您要点什么？

| 字段 | 级别 | 问题 | 建议写法 |
| --- | --- | --- | --- |
| zh | 建议 | 场景是在药店，药剂师说的“Desidera?”译成“您要点什么？”听起来像餐厅或咖啡馆点单，在药店说“您需要什么？”更自然。 | 晚上好！您需要什么？ |

### C09/aiuto/choice1 — ✅ OK

- **✔ 正确选项**：Aiuto! Mi hanno rubato il portafoglio!

### C09/aiuto/choice2 — ✅ OK

- **✘ 错误选项**：Aiuto! Ho rubato il portafoglio!
- **feedback**：Ho rubato 是“我偷了”，这句成了你偷了钱包。被偷要说 Mi hanno rubato…

### C09/aiuto/choice3 — ✅ OK

- **✘ 错误选项**：Aiuto! Ho bisogno di un portafoglio!
- **feedback**：这是“我需要一个钱包”，听起来像要买钱包。被偷要说 Mi hanno rubato il portafoglio。

### C09/come_sta/npc1 — ✅ OK

- **it**：Allora chiami subito il 112, è il numero per le emergenze. Ma lei come si sente? È un po' pallido.
- **zh**：那您马上打 112，这是紧急电话。您自己感觉怎么样？脸色有点白。

### C09/come_sta/npc2 — ✅ OK

- **it**：Va bene. Prima chiami il 112, poi vada alla polizia. Ma lei sta bene?
- **zh**：好。先打 112，再去警察局。您还好吗？

### C09/come_sta/choice1 — ✅ OK

- **✔ 正确选项**：Non mi sento bene. Ho mal di testa.

### C09/come_sta/choice2 — ✅ OK

- **✘ 错误选项**：Mi sento bene. Ho mal di testa.
- **feedback**：Mi sento bene 是“我感觉很好”，和头疼矛盾。前面要加 Non。

### C09/come_sta/choice3 — ✅ OK

- **✘ 错误选项**：Sono mal di testa.
- **feedback**：Sono 是“我是”。说头疼用 Ho：Ho mal di testa。

### C09/farmaco/npc1 — ✅ OK

- **it**：Allora le do qualcosa per il mal di testa. Sono sei euro e trenta.
- **zh**：那我给您拿点治头疼的。一共六欧三十。
- **answer**：6.30 €（干扰项：6.13 €、16.30 €）

### C09/farmaco/npc2 — ✅ OK

- **it**：Ecco, questo è per il mal di testa. Sono sette euro e quaranta.
- **zh**：给您，这是治头疼的。一共七欧四十。
- **answer**：7.40 €（干扰项：7.14 €、17.40 €）

### C09/farmaco/npc3 — ✅ OK

- **it**：Ecco qua, per il mal di testa. Sono nove euro e sessanta.
- **zh**：给您，治头疼的。一共九欧六十。
- **answer**：9.60 €（干扰项：9.16 €、19.60 €）

### C09/farmaco/choice1 — ✅ OK

- **✔ 正确选项**：Posso pagare con il telefono?

### C09/farmaco/choice2 — ✅ OK

- **✘ 错误选项**：Posso pagare in contanti?
- **feedback**：现金在被偷的钱包里。这次要问能不能用手机付：con il telefono。

### C09/farmaco/choice3 — ✅ OK

- **✘ 错误选项**：Posso pagare il telefono?
- **feedback**：少了 con，这句成了“我能付这部手机的钱吗？”。用手机付是 pagare con il telefono。

### C09/taxi/npc1 — ✅ OK

- **it**：Sì, certo. La polizia però è un po' lontana: in taxi sono dieci minuti.
- **zh**：可以。不过警察局有点远，打车要十分钟。
- **answer**：10 分钟（干扰项：12 分钟、20 分钟）

### C09/taxi/npc2 — ✅ OK

- **it**：Sì, certo. La polizia però è un po' lontana: in taxi sono quindici minuti.
- **zh**：可以。不过警察局有点远，打车要十五分钟。
- **answer**：15 分钟（干扰项：5 分钟、50 分钟）

### C09/taxi/npc3 — ✅ OK

- **it**：Sì, certo. La polizia però è un po' lontana: in taxi sono venti minuti.
- **zh**：可以。不过警察局有点远，打车要二十分钟。
- **answer**：20 分钟（干扰项：2 分钟、12 分钟）

### C09/taxi/choice1 — ✅ OK

- **✔ 正确选项**：Mi può chiamare un taxi, per favore?

### C09/taxi/choice2 — ✅ OK

- **✘ 错误选项**：Mi può chiamare un medico?
- **feedback**：medico 是医生。你要的是出租车：Mi può chiamare un taxi?

### C09/taxi/choice3 — ✅ OK

- **✘ 错误选项**：Mi può pagare un taxi?
- **feedback**：pagare 是“付钱”，这句成了请她替你付车费。叫车是 chiamare。

### C09/coraggio/npc1 — ✅ OK

- **it**：Certo, lo chiamo subito. Coraggio, e buona fortuna!
- **zh**：好的，我马上叫。挺住，祝您好运！

### C09/coraggio/npc2 — ✅ OK

- **it**：Fatto: il taxi arriva subito. Coraggio!
- **zh**：叫好了，车马上就到。挺住！

### C09/passaporto/npc1 — ✅ OK

- **it**：Oh no! Le hanno rubato anche il passaporto?
- **zh**：哎呀！护照也被偷了吗？

### C09/passaporto/npc2 — ✅ OK

- **it**：Mi dispiace! Anche il passaporto?
- **zh**：真遗憾！护照也被偷了吗？

### C09/passaporto/choice1 — ✅ OK

- **✔ 正确选项**：No, solo il portafoglio.

### C09/passaporto/choice2 — ✅ OK

- **✘ 错误选项**：Sì, solo il portafoglio.
- **feedback**：Sì 是“对，护照也被偷了”，和 solo il portafoglio（只有钱包）矛盾。

### C09/passaporto/choice3 — ✅ OK

- **✘ 错误选项**：No, ho perso il passaporto.
- **feedback**：这是“没有，我把护照弄丢了”，前后矛盾。护照还在，就说 No, solo il portafoglio。

### C09/numero/npc1 — ✅ OK

- **it**：Deve chiamare la polizia. Sa che numero chiamare?
- **zh**：您得报警。知道打哪个号码吗？

### C09/numero/choice1 — ✅ OK

- **✔ 正确选项**：Sì, il 112.

补充：意大利语里电话号码前常加阳性定冠词 il；112 在意大利既可以按百位数读作 centododici，也常逐个数字读作 uno-uno-due。

### C09/numero/choice2 — ✅ OK

- **✘ 错误选项**：Sì, il 110.
- **feedback**：110 是中国的报警电话。在意大利和整个欧盟打 112。

### C09/numero/choice3 — ✅ OK

- **✘ 错误选项**：Sì, il 911.
- **feedback**：911 是美国的紧急电话。在意大利和整个欧盟打 112。
