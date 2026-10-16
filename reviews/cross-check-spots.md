# 交叉校对：spots 巡礼点

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-17
- 13 条：13 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### spot/santa-lucia — ✅ OK

- **it**：Stazione di Venezia Santa Lucia
- **zh**：威尼斯圣卢西亚火车站
- **address**：Fondamenta Santa Lucia, 30121 Venezia VE
- **note**：Lucia 的重音在 ci 上，ci 和后面的 a 分成两个音节。
- **phrases**：Dov'è la fermata del vaporetto? · Dove posso comprare il biglietto? · Devo validare il biglietto?

### spot/san-giorgio — ✅ OK

- **it**：Chiesa di San Giorgio Maggiore
- **zh**：圣乔治马焦雷教堂
- **address**：Isola di San Giorgio Maggiore, 30124 Venezia VE
- **phrases**：Quale linea va a San Giorgio? · Si può salire sul campanile? · Posso fare una foto qui?

### spot/capodichino — ✅ OK

- **it**：Aeroporto di Napoli-Capodichino
- **zh**：那不勒斯卡波迪基诺机场
- **address**：Viale Fulco Ruffo di Calabria, 80144 Napoli NA
- **note**：Capodichino 的重音在 chi 上；ch 在 i 前面读 k 的音。
- **pin**：图钉标在航站楼（Terminal 1）。
- **phrases**：Dov'è la fermata dell'autobus per il centro? · Posso fare una foto qui?

补充：那不勒斯机场往返市中心（中央火车站和港口）的机场大巴专线上写的是 Alibus，问路或看路牌时认准这个名字也很方便。

### spot/posillipo — ✅ OK

- **it**：Collina di Posillipo
- **zh**：波西利波山丘
- **address**：Viale Virgilio, 80123 Napoli NA
- **note**：Posillipo 的重音在第二个音节 sil 上，不在最后；ll 是双辅音。
- **pin**：整座山丘是一片住宅区，图钉标在山顶的维吉尔公园（Parco Virgiliano）。
- **phrases**：Come si arriva al Parco Virgiliano? · Si può andare a piedi? · Che bello!

### spot/pompei — ✅ OK

- **it**：Scavi di Pompei
- **zh**：庞贝古城遗址
- **address**：Via Villa dei Misteri, 80045 Pompei NA
- **note**：Pompei 的重音在最后的 pei 上，ei 连着读。
- **pin**：图钉标在 Porta Marina 入口，从 Pompei Scavi – Villa dei Misteri 火车站走几分钟就到。
- **phrases**：Questo treno ferma a Pompei Scavi? · Un biglietto intero, per favore. · Dov'è l'ingresso? · A che ora chiude?

### spot/capri — ✅ OK

- **it**：Isola di Capri
- **zh**：卡普里岛
- **address**：Marina Grande, 80073 Capri NA
- **note**：Capri 的重音在前面的 Ca 上，不在 pri。
- **pin**：图钉标在 Marina Grande 港，从那不勒斯来的船在这里靠岸。
- **phrases**：A che ora parte l'ultimo aliscafo per Napoli? · Un biglietto per Napoli, per favore.

### spot/colosseo — ✅ OK

- **it**：Colosseo
- **zh**：罗马斗兽场
- **address**：Piazza del Colosseo, 1, 00184 Roma RM
- **note**：重音在 se 上；ss 是双辅音。
- **phrases**：Scusi, dov'è il Colosseo? · Quale linea va al Colosseo? · Serve la prenotazione? · Un biglietto intero, per favore.

### bus-to-centre — ✅ OK

- **it**：Dov'è la fermata dell'autobus per il centro?
- **zh**：去市中心的公交车站在哪儿？

### way-to-parco-virgiliano — ✅ OK

- **it**：Come si arriva al Parco Virgiliano?
- **zh**：维吉尔公园怎么去？
- **note**：Come si arriva a…? 是问“怎么去某地”的万能句，换上别的地名也能用。

### train-stops-at-pompei — ✅ OK

- **it**：Questo treno ferma a Pompei Scavi?
- **zh**：这趟火车在庞贝遗址站停吗？
- **note**：Pompei Scavi 是环维苏威铁路（Circumvesuviana）的站名，站牌上写的是 Pompei Scavi – Villa dei Misteri。

### last-boat-to-napoli — ✅ OK

- **it**：A che ora parte l'ultimo aliscafo per Napoli?
- **zh**：回那不勒斯的末班快船几点开？
- **note**：aliscafo 是水翼快船；慢一些的大渡轮叫 traghetto。

### line-to-san-giorgio — ✅ OK

- **it**：Quale linea va a San Giorgio?
- **zh**：哪条线去圣乔治岛？
- **note**：和第 8 课的 Quale linea va a San Marco? 是同一句，只换了地名。

### up-the-bell-tower — ✅ OK

- **it**：Si può salire sul campanile?
- **zh**：可以上钟楼吗？
