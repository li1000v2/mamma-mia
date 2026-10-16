# 交叉校对：showcards 出示卡

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-17
- 20 条：19 条 OK，1 条建议修改（其中 1 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 需要看的条目

- **allergen/fish**：错误，与欧盟法规 (EU) No 1169/2011 附件二（Allegato II）第 4 项的意大利语原文不一致。法规原文及意大利餐厅过敏原表使用的标准表述是“Pesce e prodotti a base di pesce”，而非“Pesce e prodotti della pesca”。

## 逐条结果

### go-to-address — ✅ OK

- **it**：Vorrei andare a questo indirizzo.
- **zh**：我想去这个地址。

### allergic-to — ✅ OK

- **it**：Sono allergico a questi alimenti:
- **zh**：我对以下食物过敏：

### not-even-a-little — ✅ OK

- **it**：Non posso mangiarli, neanche in piccole quantità.
- **zh**：一点点也不能吃。

### tell-the-cook — ✅ OK

- **it**：Può avvisare il cuoco, per favore?
- **zh**：能请您告诉厨师吗？

### speak-slowly — ✅ OK

- **it**：Parlo poco italiano. Può parlare più piano?
- **zh**：我意大利语说得不好，您能说慢一点吗？

### call-112 — ✅ OK

- **it**：Chiami il 112, per favore!
- **zh**：请帮我打 112！

### allergen/gluten — ✅ OK

- **it**：Cereali contenenti glutine

### allergen/crustaceans — ✅ OK

- **it**：Crostacei e prodotti a base di crostacei

### allergen/eggs — ✅ OK

- **it**：Uova e prodotti a base di uova

### allergen/fish — ✏️ 建议修改

- **it**：Pesce e prodotti della pesca

| 字段 | 级别 | 问题 | 建议写法 |
| --- | --- | --- | --- |
| it | 错误 | 与欧盟法规 (EU) No 1169/2011 附件二（Allegato II）第 4 项的意大利语原文不一致。法规原文及意大利餐厅过敏原表使用的标准表述是“Pesce e prodotti a base di pesce”，而非“Pesce e prodotti della pesca”。 | Pesce e prodotti a base di pesce |

### allergen/peanuts — ✅ OK

- **it**：Arachidi e prodotti a base di arachidi

### allergen/soybeans — ✅ OK

- **it**：Soia e prodotti a base di soia

### allergen/milk — ✅ OK

- **it**：Latte e prodotti a base di latte (incluso lattosio)

### allergen/nuts — ✅ OK

- **it**：Frutta a guscio

### allergen/celery — ✅ OK

- **it**：Sedano e prodotti a base di sedano

### allergen/mustard — ✅ OK

- **it**：Senape e prodotti a base di senape

### allergen/sesame — ✅ OK

- **it**：Semi di sesamo e prodotti a base di semi di sesamo

### allergen/sulphites — ✅ OK

- **it**：Anidride solforosa e solfiti

### allergen/lupin — ✅ OK

- **it**：Lupini e prodotti a base di lupini

### allergen/molluscs — ✅ OK

- **it**：Molluschi e prodotti a base di molluschi
