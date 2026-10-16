# 交叉校对：C07 罗马问路

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 32 条：32 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### C07/ask/npc1 — ✅ OK

- **it**：Sì? Mi dica.
- **zh**：嗯？您说。

### C07/ask/npc2 — ✅ OK

- **it**：Prego, mi dica.
- **zh**：您请说，什么事？

### C07/ask/choice1 — ✅ OK

- **✔ 正确选项**：Scusi, dov'è il Colosseo?

### C07/ask/choice2 — ✅ OK

- **✘ 错误选项**：Scusi, dove sono il Colosseo?
- **feedback**：Dove sono…? 用来问复数的东西，比如 i bagni。斗兽场只有一个，用 Dov'è…?

### C07/ask/choice3 — ✅ OK

- **✘ 错误选项**：Scusi, quanto costa il Colosseo?
- **feedback**：这是问“斗兽场多少钱”。问在哪儿用 Dov'è…?

### C07/far/npc1 — ✅ OK

- **it**：Guardi, è un po' lontano da qui. Le conviene prendere la metro.
- **zh**：您看，离这儿有点远。您最好坐地铁。

### C07/far/npc2 — ✅ OK

- **it**：Eh, a piedi è lontano. Meglio prendere la metro.
- **zh**：嗯，走路去挺远的。最好坐地铁。

### C07/far/choice1 — ✅ OK

- **✔ 正确选项**：C'è una fermata della metro qui vicino?

### C07/far/choice2 — ✅ OK

- **✘ 错误选项**：Quanto costa la metro?
- **feedback**：这是问地铁多少钱。任务是问附近有没有地铁站：C'è … qui vicino?

### C07/far/choice3 — ✅ OK

- **✘ 错误选项**：Dov'è la fermata del vaporetto?
- **feedback**：vaporetto 是威尼斯的水上巴士（L08），罗马要坐的是 metro。

### C07/way/npc1 — ✅ OK

- **it**：Sì: vada sempre dritto e prenda la seconda a sinistra. La metro è lì.
- **zh**：有：一直往前走，第二个路口左转。地铁站就在那儿。
- **answer**：直走，第二个路口左转（干扰项：直走，第二个路口右转、直走，第一个路口左转）

### C07/way/npc2 — ✅ OK

- **it**：Sì: vada dritto fino al semaforo, poi giri a destra. La metro è lì.
- **zh**：有：直走到红绿灯，然后右转。地铁站就在那儿。
- **answer**：走到红绿灯，右转（干扰项：走到红绿灯，左转、走到十字路口，右转）

### C07/way/npc3 — ✅ OK

- **it**：Sì: prenda la prima a destra, poi all'incrocio giri a sinistra. La metro è lì.
- **zh**：有：第一个路口右转，然后到十字路口左转。地铁站就在那儿。
- **answer**：第一个路口右转，到十字路口再左转（干扰项：第一个路口左转，到十字路口再右转、第三个路口右转，到十字路口再左转）

### C07/way/choice1 — ✅ OK

- **✔ 正确选项**：Grazie! E dove devo scendere?

补充：问“在哪站下车”除了 Dove devo scendere?，日常也很常说 A che fermata devo scendere?

### C07/way/choice2 — ✅ OK

- **✘ 错误选项**：Grazie! E dove devo salire?
- **feedback**：salire 是“上车”。问在哪站下车要用 scendere：Dove devo scendere?

### C07/way/choice3 — ✅ OK

- **✘ 错误选项**：Grazie! E dove devo scrivere?
- **feedback**：scrivere 是“写”（L03 的 Me lo può scrivere?）。下车是 scendere。

### C07/stop/npc1 — ✅ OK

- **it**：Alla fermata Colosseo. Da qui sono due fermate.
- **zh**：在斗兽场站下。从这儿坐两站。
- **answer**：2 站（干扰项：12 站、3 站）

### C07/stop/npc2 — ✅ OK

- **it**：Alla fermata Colosseo. Da qui sono tre fermate.
- **zh**：在斗兽场站下。从这儿坐三站。
- **answer**：3 站（干扰项：13 站、2 站）

### C07/stop/npc3 — ✅ OK

- **it**：Alla fermata Colosseo. Da qui sono sei fermate.
- **zh**：在斗兽场站下。从这儿坐六站。
- **answer**：6 站（干扰项：16 站、7 站）

### C07/stop/choice1 — ✅ OK

- **✔ 正确选项**：Grazie mille!

### C07/stop/choice2 — ✅ OK

- **✘ 错误选项**：Prego!
- **feedback**：prego 是别人道谢后你回的“不客气”。这里该你道谢：Grazie mille!

### C07/stop/choice3 — ✅ OK

- **✘ 错误选项**：Mamma mia!
- **feedback**：Mamma mia 是“我的天哪”，用来感叹，不是道谢。

### C07/bye/npc1 — ✅ OK

- **it**：Prego! Buona giornata!
- **zh**：不客气！祝您今天愉快！

### C07/bye/npc2 — ✅ OK

- **it**：Di niente! Buona visita!
- **zh**：没什么！祝您玩得开心！

### C07/piedi/npc1 — ✅ OK

- **it**：Il Colosseo? Ci va a piedi?
- **zh**：斗兽场？您走着去吗？

### C07/piedi/choice1 — ✅ OK

- **✔ 正确选项**：È lontano?

### C07/piedi/choice2 — ✅ OK

- **✘ 错误选项**：Sono lontano?
- **feedback**：Sono 是“我是”，这句成了“我很远吗？”。问那个地方远不远：È lontano?

### C07/piedi/choice3 — ✅ OK

- **✘ 错误选项**：Quanto costa a piedi?
- **feedback**：这是问“走路去要多少钱”。问远不远：È lontano?

### C07/mappa/npc1 — ✅ OK

- **it**：Il Colosseo? Ha una mappa sul telefono?
- **zh**：斗兽场？您手机上有地图吗？

### C07/mappa/choice1 — ✅ OK

- **✔ 正确选项**：Sì. Me lo può indicare sulla mappa?

### C07/mappa/choice2 — ✅ OK

- **✘ 错误选项**：Sì. Posso indicare sulla mappa?
- **feedback**：Posso…? 是“我能……吗”，成了你要自己指。请对方指给你看用 Me lo può…?

### C07/mappa/choice3 — ✅ OK

- **✘ 错误选项**：Sì, ho perso la mappa.
- **feedback**：这句是“对，我把地图弄丢了”，前后矛盾。请对方在地图上指：Me lo può indicare sulla mappa?
