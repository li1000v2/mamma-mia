# 交叉校对：C08 竞技场与圣地

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 32 条：32 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### C08/ticket/npc1 — ✅ OK

- **it**：Buongiorno! Mi dica.
- **zh**：早上好！您要什么？

### C08/ticket/npc2 — ✅ OK

- **it**：Buongiorno, prego.
- **zh**：早上好，您请说。

### C08/ticket/choice1 — ✅ OK

- **✔ 正确选项**：Un biglietto intero, per favore.

### C08/ticket/choice2 — ✅ OK

- **✘ 错误选项**：Un biglietto ridotto, per favore.
- **feedback**：ridotto 是优惠票，要符合条件才能买。这次的任务是买全价票：intero。

### C08/ticket/choice3 — ✅ OK

- **✘ 错误选项**：Un biglietto per Napoli, per favore.
- **feedback**：这是在火车站买去那不勒斯的票（L14）。这里要的是门票：Un biglietto intero。

### C08/price/npc1 — ✅ OK

- **it**：Sono sedici euro, grazie. Ecco il biglietto.
- **zh**：十六欧，谢谢。这是您的票。
- **answer**：16 €（干扰项：6 €、60 €）

### C08/price/npc2 — ✅ OK

- **it**：Sono diciotto euro, grazie. Ecco il biglietto.
- **zh**：十八欧，谢谢。这是您的票。
- **answer**：18 €（干扰项：8 €、80 €）

### C08/price/npc3 — ✅ OK

- **it**：Sono ventiquattro euro, grazie. Ecco il biglietto.
- **zh**：二十四欧，谢谢。这是您的票。
- **answer**：24 €（干扰项：14 €、40 €）

### C08/price/choice1 — ✅ OK

- **✔ 正确选项**：Grazie. Dov'è l'ingresso?

### C08/price/choice2 — ✅ OK

- **✘ 错误选项**：Grazie. Dov'è l'uscita?
- **feedback**：uscita 是出口（L01）。入口是 ingresso：Dov'è l'ingresso?

### C08/price/choice3 — ✅ OK

- **✘ 错误选项**：Grazie. Quanto costa l'ingresso?
- **feedback**：票已经买好了，这句又在问门票多少钱。问入口在哪儿：Dov'è l'ingresso?

### C08/entrance/npc1 — ✅ OK

- **it**：L'ingresso? Giri a destra, è lì.
- **zh**：入口？往右转，就在那儿。
- **answer**：往右转（干扰项：往左转、一直往前走）

### C08/entrance/npc2 — ✅ OK

- **it**：L'ingresso? Giri a sinistra, è lì.
- **zh**：入口？往左转，就在那儿。
- **answer**：往左转（干扰项：往右转、一直往前走）

### C08/entrance/npc3 — ✅ OK

- **it**：L'ingresso? Vada sempre dritto, è lì.
- **zh**：入口？一直往前走，就在那儿。
- **answer**：一直往前走（干扰项：往右转、往左转）

### C08/entrance/choice1 — ✅ OK

- **✔ 正确选项**：Grazie! Mi può fare una foto?

补充：请别人帮自己拍照也可以把代词 mi 放在动词原形后面，说成 Può farmi una foto?，两种说法完全等价、都很常用。

### C08/entrance/choice2 — ✅ OK

- **✘ 错误选项**：Grazie! Posso fare una foto?
- **feedback**：Posso…? 是“我能……吗”，这句是问“我能拍照吗”。请对方帮你拍：Mi può fare una foto?

### C08/entrance/choice3 — ✅ OK

- **✘ 错误选项**：Grazie! Mi può fare un caffè?
- **feedback**：这是请对方给你做一杯咖啡。拍照是 fare una foto。

### C08/photo/npc1 — ✅ OK

- **it**：Va bene! Uno, due, tre… ecco fatto. Come mai proprio qui?
- **zh**：好！一、二、三……拍好了。怎么特地在这儿拍？

### C08/photo/npc2 — ✅ OK

- **it**：Va bene! Sorrida… ecco fatto. Perché proprio qui?
- **zh**：好！笑一个……拍好了。为什么偏偏在这儿拍？

### C08/photo/choice1 — ✅ OK

- **✔ 正确选项**：Sono un fan di JoJo!

补充：意大利人读 JoJo 时通常按英语习惯读作“乔乔”（近似イタリア语的 Giogio），全称是 Le bizzarre avventure di JoJo。

### C08/photo/choice2 — ✅ OK

- **✘ 错误选项**：Sono JoJo!
- **feedback**：这成了“我就是 JoJo”。“我是……迷”要说 Sono un fan di…

### C08/photo/choice3 — ✅ OK

- **✘ 错误选项**：Ho un fan di JoJo!
- **feedback**：Ho 是“我有”，这句成了“我有一个 JoJo 迷”。说自己是什么用 Sono…

### C08/bye/npc1 — ✅ OK

- **it**：Ah, JoJo! Qui ne vengono tanti. Buona visita!
- **zh**：啊，JoJo！来这儿的粉丝可多了。祝您参观愉快！

### C08/bye/npc2 — ✅ OK

- **it**：Ah, JoJo! Allora benvenuto a Roma. Buona visita!
- **zh**：啊，JoJo！那欢迎来到罗马。祝您参观愉快！

### C08/ancora/npc1 — ✅ OK

- **it**：Certo! Ecco fatto. Va bene così?
- **zh**：当然！拍好了。这样行吗？

### C08/ancora/choice1 — ✅ OK

- **✔ 正确选项**：Ancora una, per favore.

### C08/ancora/choice2 — ✅ OK

- **✘ 错误选项**：Ancora uno, per favore.
- **feedback**：foto 是阴性（la foto），要说 Ancora una。

### C08/ancora/choice3 — ✅ OK

- **✘ 错误选项**：Ho fatto una foto.
- **feedback**：这是“我拍了一张照片”。请对方再拍一张：Ancora una, per favore。

### C08/premere/npc1 — ✅ OK

- **it**：Certo! Dove devo premere?
- **zh**：当然！按哪里？

补充：除了 premere，意大利人在日常口语里也常说 Dove schiaccio?（我按哪儿？）。

### C08/premere/choice1 — ✅ OK

- **✔ 正确选项**：Basta premere qui.

### C08/premere/choice2 — ✅ OK

- **✘ 错误选项**：Basta così.
- **feedback**：Basta così 是“就这些”。对方问按哪儿，要说 Basta premere qui。

### C08/premere/choice3 — ✅ OK

- **✘ 错误选项**：Devo premere qui?
- **feedback**：这是在问“我该按这里吗”。你是要告诉对方按哪儿：Basta premere qui。
