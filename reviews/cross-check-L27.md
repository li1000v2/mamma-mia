# 交叉校对：L27 打车与去机场

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 6 条：6 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### L27/intro — ✅ OK

<details><summary>intro 原文</summary>

> 句框 Mi può + 动词原形?（您能帮我……吗？）：mi 是“给我、为我”，può 是“您能”。L03 学过 Può ripetere?（您能再说一遍吗？），前面加上 mi，就是请对方为你做事：Mi può chiamare un taxi?（您能帮我叫辆出租车吗？）、Mi può aiutare?（您能帮帮我吗？）。
>
> 打车：在罗马一般去写着 TAXI 的候车点排队，或者请酒店前台、餐厅帮你叫。正规出租车是白色的，车顶有 TAXI 灯牌，车门上有编号；车站、机场里上前拉客的不要跟。上车先说目的地，再加 per favore。
>
> “去／到”某地用 a，a 碰上冠词要合在一起：a + il = al，a + la = alla，a + l' = all'。所以是 all'aeroporto（去机场）、alla stazione（去火车站）。罗马有两个机场：Fiumicino 和 Ciampino，一定要说清是哪个。
>
> 问价：Quanto costa fino a…?（到……要多少钱？），fino a 是“一直到”。罗马市中心去机场常有固定价，上车前问清楚；报价没听清，就请司机写下来。
>
> 发音：先听示范音频，再看下面的提示，标准是音频。
> · può 的 u 要圆唇往前撅；日语的う是扁的，照う读会走样。può 只有一个音节，重音在 ò。
> · taxi 重音在 TA：TA-xi，x 读 ks，不按拼音的 x 读，k 和 s 中间也不加元音。片假名タクシー不可信：k 后面多了个う，最后也不是长音シー。
> · chiamare 的 ch 读 k，不按英语或拼音读 ch。Ciampino 的 ci 像英语 cheese 的 ch；不像的是英语的 ch 常带一口气，意大利语不送气。cia 里的 i 不单独发音：ciam-PI-no。Fiumicino 重音在 CI：fiu-mi-CI-no。
> · aeroporto 是五个音节 a-e-ro-POR-to，a、e 分开读；别照片假名エアポート读。

</details>

⚠️ 最小对立词 al/all：TTS 单独念词时双辅音可能不够长，音频需要人工听。

### L27-01 — ✅ OK

- **it**：Mi può chiamare un taxi?
- **zh**：您能帮我叫辆出租车吗？
- **note**：在酒店前台、餐厅结账时说。chiamare 重音在 MA：chia-MA-re。

### L27-02 — ✅ OK

- **it**：All'aeroporto di Fiumicino, per favore.
- **zh**：请去菲乌米奇诺机场。
- **note**：上车说目的地加 per favore 就行。all' = a + l'。罗马另一个机场是 Ciampino，别说混。per 的 r 后面不加元音，直接接 favore。

补充：Fiumicino 机场的正式名称是 Aeroporto Leonardo da Vinci（达芬奇机场），路牌和机票上常会同时出现这两个名字，不过跟司机说 Fiumicino 最常用。

### L27-03 — ✅ OK

- **it**：Quanto costa fino all'aeroporto?
- **zh**：到机场要多少钱？
- **note**：fino a 是“一直到”，fino a + l' = fino all'。上车前问。罗马市中心去机场常有固定价，可以再问一句 C'è una tariffa fissa?（有固定价吗？）。costa 的 st 中间不加元音。

### L27-04 — ✅ OK

- **it**：Quanto tempo ci vuole?
- **zh**：要多长时间？
- **note**：ci vuole 是“需要（多少时间）”。司机常答 Ci vogliono quaranta minuti（要四十分钟）、Circa mezz'ora（大约半小时）。赶飞机时一定要问。

### L27-05 — ✅ OK

- **it**：Mi può fare la ricevuta?
- **zh**：您能给我开张收据吗？
- **note**：ricevuta 是收据，重音在 VU：ri-ce-VU-ta。想刷卡就先问一句：Posso pagare con la carta? con 的 n 后面不加元音。
