# 交叉校对：C05 威尼斯→那不勒斯

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 27 条：27 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### C05/ticket/npc1 — ✅ OK

- **it**：Buongiorno, mi dica.
- **zh**：【售票员】早上好，您要什么？

### C05/ticket/npc2 — ✅ OK

- **it**：Buongiorno! Prego, dica.
- **zh**：【售票员】早上好！请说。

### C05/ticket/choice1 — ✅ OK

- **✔ 正确选项**：Buongiorno. Un biglietto per Napoli, per favore.

### C05/ticket/choice2 — ✅ OK

- **✘ 错误选项**：Buongiorno. Un biglietto da Napoli, per favore.
- **feedback**：da 是“从”，这句成了“从那不勒斯出发的票”。去哪儿用 per：per Napoli。

### C05/ticket/choice3 — ✅ OK

- **✘ 错误选项**：Buongiorno. Un binario per Napoli, per favore.
- **feedback**：binario 是站台，票是 biglietto。

### C05/andata/npc1 — ✅ OK

- **it**：Solo andata o andata e ritorno?
- **zh**：【售票员】单程还是往返？

### C05/andata/npc2 — ✅ OK

- **it**：Andata e ritorno o solo andata?
- **zh**：【售票员】往返还是单程？

### C05/andata/choice1 — ✅ OK

- **✔ 正确选项**：Solo andata, per favore. Da quale binario parte?

补充：口语中问“从几号站台出发”也常说 Da che binario parte?，和 Da quale binario parte? 一样自然。

### C05/andata/choice2 — ✅ OK

- **✘ 错误选项**：Andata e ritorno, per favore. Da quale binario parte?
- **feedback**：andata e ritorno 是往返。你到了那不勒斯还要去罗马，不回威尼斯，买单程就行：Solo andata。

### C05/andata/choice3 — ✅ OK

- **✘ 错误选项**：Solo andata, per favore. Da quale biglietto parte?
- **feedback**：biglietto 是票。问站台要说 Da quale binario parte?

### C05/biglietto/npc1 — ✅ OK

- **it**：Dal binario tre. Ecco il biglietto: carrozza otto, posto ventidue.
- **zh**：【售票员】从 3 号站台出发。给您票：8 号车厢，22 号座位。
- **answer**：8 号车厢（干扰项：18 号车厢、3 号车厢）

### C05/biglietto/npc2 — ✅ OK

- **it**：Dal binario tre. Ecco a lei: carrozza sei, posto quattordici.
- **zh**：【售票员】从 3 号站台出发。给您：6 号车厢，14 号座位。
- **answer**：6 号车厢（干扰项：16 号车厢、14 号车厢）

### C05/biglietto/npc3 — ✅ OK

- **it**：Dal binario tre. Ecco il biglietto: carrozza dodici, posto sette.
- **zh**：【售票员】从 3 号站台出发。给您票：12 号车厢，7 号座位。
- **answer**：12 号车厢（干扰项：2 号车厢、7 号车厢）

### C05/ritardo/npc1 — ✅ OK

- **it**：Attenzione. Il treno per Napoli Centrale è in ritardo di circa quindici minuti. Ci scusiamo per il disagio.
- **zh**：【广播】请注意，开往那不勒斯中央车站的火车晚点约 15 分钟。给您带来不便，敬请谅解。
- **answer**：15 分钟（干扰项：50 分钟、5 分钟）

### C05/ritardo/npc2 — ✅ OK

- **it**：Attenzione. Il treno per Napoli Centrale partirà con un ritardo di circa quaranta minuti. Ci scusiamo per il disagio.
- **zh**：【广播】请注意，开往那不勒斯中央车站的火车将晚点约 40 分钟出发。给您带来不便，敬请谅解。
- **answer**：40 分钟（干扰项：14 分钟、4 分钟）

### C05/ritardo/npc3 — ✅ OK

- **it**：Attenzione. Il treno per Napoli Centrale è in ritardo di circa venticinque minuti. Ci scusiamo per il disagio.
- **zh**：【广播】请注意，开往那不勒斯中央车站的火车晚点约 25 分钟。给您带来不便，敬请谅解。
- **answer**：25 分钟（干扰项：35 分钟、20 分钟）

### C05/cambio/npc1 — ✅ OK

- **it**：Attenzione! Il treno per Napoli Centrale partirà dal binario cinque anziché dal binario tre.
- **zh**：【广播】请注意！开往那不勒斯中央车站的火车改从 5 号站台出发，不是 3 号站台。
- **answer**：5 号站台（干扰项：3 号站台、15 号站台）

### C05/cambio/npc2 — ✅ OK

- **it**：Attenzione! Il treno per Napoli Centrale, anziché dal binario tre, partirà dal binario sette.
- **zh**：【广播】请注意！开往那不勒斯中央车站的火车不从 3 号站台出发，改从 7 号站台出发。
- **answer**：7 号站台（干扰项：3 号站台、17 号站台）

### C05/cambio/npc3 — ✅ OK

- **it**：Attenzione! Il treno per Napoli Centrale partirà dal binario tredici anziché dal binario tre.
- **zh**：【广播】请注意！开往那不勒斯中央车站的火车改从 13 号站台出发，不是 3 号站台。
- **answer**：13 号站台（干扰项：3 号站台、30 号站台）

### C05/occupato/npc1 — ✅ OK

- **it**：Sì? Mi dica.
- **zh**：【乘客】嗯？有什么事吗？

### C05/occupato/choice1 — ✅ OK

- **✔ 正确选项**：Scusi, questo è il mio posto.

### C05/occupato/choice2 — ✅ OK

- **✘ 错误选项**：Scusi, questo è il suo posto.
- **feedback**：il suo posto 是“您的座位”，等于说对方坐对了。自己的座位是 il mio posto。

### C05/occupato/choice3 — ✅ OK

- **✘ 错误选项**：Scusi, questo è il mio binario.
- **feedback**：binario 是站台。车上的座位是 posto。

### C05/capotreno/npc1 — ✅ OK

- **it**：Buongiorno, biglietto, prego.
- **zh**：【列车员】您好，请出示车票。

### C05/capotreno/choice1 — ✅ OK

- **✔ 正确选项**：Ecco. Scusi, dov'è il mio posto?

### C05/capotreno/choice2 — ✅ OK

- **✘ 错误选项**：Ecco. Scusi, dov'è il binario?
- **feedback**：你已经上车了。binario 是站台，座位是 posto：dov'è il mio posto?

### C05/capotreno/choice3 — ✅ OK

- **✘ 错误选项**：Ecco. Scusi, quanto costa il posto?
- **feedback**：这是问座位多少钱。票已经买好了，要问的是座位在哪儿：Dov'è…?
