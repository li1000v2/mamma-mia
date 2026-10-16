# 交叉校对：C10 罗马一日通关

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 45 条：45 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### C10/colazione/npc1 — ✅ OK

- **it**：Buongiorno! Cosa le preparo?
- **zh**：早上好！给您做点什么？

### C10/colazione/npc2 — ✅ OK

- **it**：Buongiorno, prego!
- **zh**：早上好，您请说！

### C10/colazione/choice1 — ✅ OK

- **✔ 正确选项**：Un cappuccino e un cornetto, per favore.

补充：在罗马和中南部点羊角面包说 cornetto 最地道（北方常说 brioche）。

### C10/colazione/choice2 — ✅ OK

- **✘ 错误选项**：Ho un cappuccino e un cornetto.
- **feedback**：Ho 是“我有”。点单直接说要的东西加 per favore，或者用 Prendo… / Vorrei…

### C10/colazione/choice3 — ✅ OK

- **✘ 错误选项**：Posso un cappuccino e un cornetto?
- **feedback**：Posso 后面要接动词原形，比如 Posso avere…?（可以给我……吗？）。点单直接说要的东西加 per favore 最简单。

### C10/metro/npc1 — ✅ OK

- **it**：Cerca il Colosseo? Prenda la metro B, direzione Laurentina: sono tre fermate.
- **zh**：您找斗兽场？坐地铁 B 线，往 Laurentina 方向，坐三站。
- **answer**：3 站（干扰项：13 站、2 站）

### C10/metro/npc2 — ✅ OK

- **it**：Cerca il Colosseo? Prenda la metro B, direzione Laurentina: sono due fermate.
- **zh**：您找斗兽场？坐地铁 B 线，往 Laurentina 方向，坐两站。
- **answer**：2 站（干扰项：12 站、3 站）

### C10/metro/npc3 — ✅ OK

- **it**：Cerca il Colosseo? Prenda la metro B, direzione Laurentina: sono quattro fermate.
- **zh**：您找斗兽场？坐地铁 B 线，往 Laurentina 方向，坐四站。
- **answer**：4 站（干扰项：14 站、3 站）

### C10/metro/choice1 — ✅ OK

- **✔ 正确选项**：Grazie mille, è molto gentile!

### C10/metro/choice2 — ✅ OK

- **✘ 错误选项**：Prego, è molto gentile!
- **feedback**：prego 是“不客气”，是别人向你道谢时说的。道谢说 Grazie。

### C10/metro/choice3 — ✅ OK

- **✘ 错误选项**：Grazie mille, sono molto gentile!
- **feedback**：sono 是“我是”，这句成了夸自己客气。夸对方用 è（您是）：È molto gentile。

### C10/colosseo/npc1 — ✅ OK

- **it**：Buongiorno! Il primo orario disponibile è alle undici e trenta. Va bene?
- **zh**：您好！最早能约到的入场时间是十一点半，可以吗？
- **answer**：11:30（干扰项：12:30、11:13）

### C10/colosseo/npc2 — ✅ OK

- **it**：Buongiorno! Il primo orario disponibile è alle dieci e quindici. Va bene?
- **zh**：您好！最早能约到的入场时间是十点十五分，可以吗？
- **answer**：10:15（干扰项：12:15、10:50）

### C10/colosseo/npc3 — ✅ OK

- **it**：Buongiorno! Il primo orario disponibile è alle tredici e venti. Va bene?
- **zh**：您好！最早能约到的入场时间是十三点二十分，可以吗？
- **answer**：13:20（干扰项：3:20、13:12）

### C10/colosseo/choice1 — ✅ OK

- **✔ 正确选项**：Va bene. Un biglietto intero, per favore.

### C10/colosseo/choice2 — ✅ OK

- **✘ 错误选项**：Va bene. Due biglietti interi, per favore.
- **feedback**：这是两张。你一个人，只要一张：Un biglietto intero。

### C10/colosseo/choice3 — ✅ OK

- **✘ 错误选项**：Non va bene. Un biglietto intero, per favore.
- **feedback**：Non va bene 是“不行”，后面又要买票，前后矛盾。时间可以就说 Va bene。

### C10/pranzo/npc1 — ✅ OK

- **it**：Buongiorno! Ha già scelto?
- **zh**：您好！点好了吗？

### C10/pranzo/npc2 — ✅ OK

- **it**：Allora, cosa le porto?
- **zh**：那么，给您上点什么？

### C10/pranzo/choice1 — ✅ OK

- **✔ 正确选项**：Vorrei una carbonara, per favore.

补充：中文常把 carbonara 译作“培根蛋酱意面”，不过正宗罗马做法用的是风干猪颊肉（guanciale）和羊奶干酪（pecorino romano），不放培根和奶油。

### C10/pranzo/choice2 — ✅ OK

- **✘ 错误选项**：Ho mangiato una carbonara.
- **feedback**：Ho mangiato 是“我吃过了”，说的是已经发生的事。点菜用 Vorrei… 或 Prendo…

### C10/pranzo/choice3 — ✅ OK

- **✘ 错误选项**：Il conto, per favore.
- **feedback**：这是要结账。你还没点菜呢。

### C10/negozio/npc1 — ✅ OK

- **it**：Le piace questo cappello? Costa quindici euro.
- **zh**：您喜欢这顶帽子吗？十五欧。
- **answer**：15 €（干扰项：5 €、50 €）

### C10/negozio/npc2 — ✅ OK

- **it**：Le piace questo cappello? Costa dodici euro.
- **zh**：您喜欢这顶帽子吗？十二欧。
- **answer**：12 €（干扰项：2 €、20 €）

### C10/negozio/npc3 — ✅ OK

- **it**：Le piace questo cappello? Costa diciotto euro.
- **zh**：您喜欢这顶帽子吗？十八欧。
- **answer**：18 €（干扰项：8 €、80 €）

### C10/negozio/choice1 — ✅ OK

- **✔ 正确选项**：Sì, lo prendo.

### C10/negozio/choice2 — ✅ OK

- **✘ 错误选项**：Sto solo guardando, grazie.
- **feedback**：这是“我只是看看”。这次你想买：Lo prendo。

### C10/negozio/choice3 — ✅ OK

- **✘ 错误选项**：Sì, lo prende.
- **feedback**：prende 是“您买／他买”，变成让店员买了。自己买说 Lo prendo。

### C10/taxi/npc1 — ✅ OK

- **it**：Buonasera! Dove la porto?
- **zh**：晚上好！送您去哪儿？

### C10/taxi/npc2 — ✅ OK

- **it**：Buonasera, dove andiamo?
- **zh**：晚上好，去哪儿？

### C10/taxi/choice1 — ✅ OK

- **✔ 正确选项**：All'aeroporto di Fiumicino, per favore.

### C10/taxi/choice2 — ✅ OK

- **✘ 错误选项**：Dov'è l'aeroporto di Fiumicino?
- **feedback**：这是问机场在哪儿。司机问你去哪儿，直接说目的地：All'aeroporto di Fiumicino, per favore。

### C10/taxi/choice3 — ✅ OK

- **✘ 错误选项**：Alla stazione Termini, per favore.
- **feedback**：这是去 Termini 火车站。这次要去机场。

### C10/arrivo/npc1 — ✅ OK

- **it**：Perfetto. Con questo traffico ci vogliono quaranta minuti.
- **zh**：好的。这个路况要四十分钟。
- **answer**：40 分钟（干扰项：14 分钟、50 分钟）

### C10/arrivo/npc2 — ✅ OK

- **it**：Va bene. Ci vogliono circa trenta minuti.
- **zh**：好的。大概要三十分钟。
- **answer**：30 分钟（干扰项：13 分钟、40 分钟）

### C10/arrivo/npc3 — ✅ OK

- **it**：D'accordo. Oggi c'è traffico: ci vogliono cinquanta minuti.
- **zh**：好的。今天堵车，要五十分钟。
- **answer**：50 分钟（干扰项：15 分钟、60 分钟）

### C10/bere/npc1 — ✅ OK

- **it**：E da bere?
- **zh**：喝点什么？

### C10/bere/npc2 — ✅ OK

- **it**：Qualcosa da bere?
- **zh**：要喝点什么吗？

### C10/bere/choice1 — ✅ OK

- **✔ 正确选项**：Un'acqua naturale, per favore.

补充：在罗马及意大利中南部，不带气的水除了说 acqua naturale，也很常说 acqua liscia。

### C10/bere/choice2 — ✅ OK

- **✘ 错误选项**：Un'acqua frizzante, per favore.
- **feedback**：frizzante 是带气的。不带气的水是 acqua naturale。

### C10/bere/choice3 — ✅ OK

- **✘ 错误选项**：Ho sete, per favore.
- **feedback**：Ho sete 是“我渴了”，服务员还是不知道你要喝什么。直接说要的东西：Un'acqua naturale, per favore。

### C10/buono/npc1 — ✅ OK

- **it**：Tutto bene? Le piace la carbonara?
- **zh**：还满意吗？carbonara 合您口味吗？

### C10/buono/choice1 — ✅ OK

- **✔ 正确选项**：Sì, è buonissima, grazie!

### C10/buono/choice2 — ✅ OK

- **✘ 错误选项**：Sì, sono buonissimo, grazie!
- **feedback**：sono 是“我是”，这句成了“我非常好吃”。夸菜说 È buonissima（它非常好吃）。

### C10/buono/choice3 — ✅ OK

- **✘ 错误选项**：Sì, ho fame, grazie!
- **feedback**：Ho fame 是“我饿了”。对方问的是菜好不好吃。
