# 交叉校对：C03 抵达威尼斯

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 33 条：33 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### C03/aeroporto/npc1 — ✅ OK

- **it**：Buongiorno, mi dica!
- **zh**：早上好，您要什么？

### C03/aeroporto/npc2 — ✅ OK

- **it**：Buongiorno! Prego.
- **zh**：早上好！请讲。

### C03/aeroporto/choice1 — ✅ OK

- **✔ 正确选项**：Buongiorno! Un biglietto per Piazzale Roma, per favore.

### C03/aeroporto/choice2 — ✅ OK

- **✘ 错误选项**：Buongiorno! Una biglietto per Piazzale Roma, per favore.
- **feedback**：biglietto 以 -o 结尾，是阳性，要用 un：un biglietto。

### C03/aeroporto/choice3 — ✅ OK

- **✘ 错误选项**：Buongiorno! Ho un biglietto per Piazzale Roma.
- **feedback**：Ho 是“我有”，这句成了“我有一张票”。买票直接说要的东西，再加 per favore。

### C03/piazzale/npc1 — ✅ OK

- **it**：Buongiorno! Posso aiutarla?
- **zh**：您好！需要帮忙吗？

### C03/piazzale/npc2 — ✅ OK

- **it**：Buongiorno, mi dica.
- **zh**：您好，请说。

### C03/piazzale/choice1 — ✅ OK

- **✔ 正确选项**：Scusi, quale linea va a Rialto? E devo validare il biglietto?

补充：“验票/打票”除了 validare，在意大利公共交通中也很常说 convalidare 或 obliterare。

### C03/piazzale/choice2 — ✅ OK

- **✘ 错误选项**：Scusi, dov'è Rialto? E devo validare il biglietto?
- **feedback**：Dov'è Rialto? 是问 Rialto 在哪儿。要问坐哪条船：Quale linea va a Rialto?

### C03/piazzale/choice3 — ✅ OK

- **✘ 错误选项**：Scusi, quale linea va a Rialto? E ho validato il biglietto?
- **feedback**：ho validato 是“我验过了”，这句成了“我验过票了吗？”。问要不要验票用 Devo validare il biglietto?

### C03/linea/npc1 — ✅ OK

- **it**：Per Rialto, la linea uno. E sì, il biglietto si valida prima di salire.
- **zh**：去 Rialto 坐 1 号线。对，票要在上船前验。
- **answer**：1 号线（干扰项：11 号线、2 号线）

### C03/linea/npc2 — ✅ OK

- **it**：Prenda la linea due. E il biglietto lo deve validare prima di salire.
- **zh**：坐 2 号线。票得在上船前验一下。
- **answer**：2 号线（干扰项：12 号线、1 号线）

### C03/hotel/npc1 — ✅ OK

- **it**：Buonasera e benvenuto! Ha una prenotazione?
- **zh**：晚上好，欢迎！您有预订吗？

### C03/hotel/npc2 — ✅ OK

- **it**：Buonasera! Ha prenotato?
- **zh**：晚上好！您预订了吗？

### C03/hotel/choice1 — ✅ OK

- **✔ 正确选项**：Sì, ho prenotato una camera a nome di…

补充：报名字时除了 a nome di…，直接说 a nome…（不加 di）在口语里也很常见。

### C03/hotel/choice2 — ✅ OK

- **✘ 错误选项**：Sì, prenotato una camera a nome di…
- **feedback**：少了 ho：说已经做过的事要用 ho + 过去分词，ho prenotato。

### C03/hotel/choice3 — ✅ OK

- **✘ 错误选项**：Sì, ho prenotare una camera a nome di…
- **feedback**：prenotare 是原形。ho 后面要接过去分词：ho prenotato。

### C03/tassa/npc1 — ✅ OK

- **it**：Perfetto, grazie. C'è anche la tassa di soggiorno: sono dodici euro in tutto. Contanti o carta?
- **zh**：好的，谢谢。另外还有城市税，一共十二欧。现金还是刷卡？
- **answer**：12 €（干扰项：2 €、20 €）

### C03/tassa/npc2 — ✅ OK

- **it**：Perfetto, grazie. C'è anche la tassa di soggiorno: sono quindici euro in tutto. Contanti o carta?
- **zh**：好的，谢谢。另外还有城市税，一共十五欧。现金还是刷卡？
- **answer**：15 €（干扰项：5 €、50 €）

### C03/tassa/npc3 — ✅ OK

- **it**：Perfetto, grazie. C'è anche la tassa di soggiorno: sono sedici euro in tutto. Contanti o carta?
- **zh**：好的，谢谢。另外还有城市税，一共十六欧。现金还是刷卡？
- **answer**：16 €（干扰项：6 €、60 €）

### C03/tassa/choice1 — ✅ OK

- **✔ 正确选项**：Con la carta, grazie.

补充：回答“刷卡”也可以直接简略说 Carta, grazie. 或 Con carta, grazie.。

### C03/tassa/choice2 — ✅ OK

- **✘ 错误选项**：Con la camera, grazie.
- **feedback**：camera 是“房间”。刷卡是 con la carta。

### C03/tassa/choice3 — ✅ OK

- **✘ 错误选项**：Sì, grazie.
- **feedback**：对方问的是现金还是刷卡，二选一，回答 Sì 等于没回答。

### C03/documento/npc1 — ✅ OK

- **it**：Mi dà un documento, per favore?
- **zh**：请给我一下您的证件。

### C03/documento/npc2 — ✅ OK

- **it**：Il passaporto, per favore.
- **zh**：请出示护照。

### C03/documento/choice1 — ✅ OK

- **✔ 正确选项**：Ecco il passaporto.

### C03/documento/choice2 — ✅ OK

- **✘ 错误选项**：Ecco lo scontrino.
- **feedback**：scontrino 是小票。前台要的是证件：Ecco il passaporto。

### C03/documento/choice3 — ✅ OK

- **✘ 错误选项**：No, grazie.
- **feedback**：入住登记一定要看证件，不能说“不用了”。递过去说 Ecco il passaporto。

### C03/cognome/npc1 — ✅ OK

- **it**：Come si scrive il cognome?
- **zh**：您的姓怎么拼？

### C03/cognome/npc2 — ✅ OK

- **it**：Scusi, come si scrive?
- **zh**：不好意思，怎么拼？

### C03/cognome/choice1 — ✅ OK

- **✔ 正确选项**：Lo scrivo io.

### C03/cognome/choice2 — ✅ OK

- **✘ 错误选项**：Me lo può scrivere?
- **feedback**：这是请对方写下来，可对方正是不知道怎么拼你的姓。你来写：Lo scrivo io。

### C03/cognome/choice3 — ✅ OK

- **✘ 错误选项**：Sì, grazie.
- **feedback**：对方问的是怎么拼，回答 Sì 等于没回答。
