# 交叉校对：L17 披萨店（那不勒斯）

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 6 条：6 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### L17/intro — ✅ OK

<details><summary>intro 原文</summary>

> 点单还是用 Vorrei… / Prendo…：Vorrei una margherita（我想要一个玛格丽特）。在披萨店说 una margherita 就是一整个披萨，不用再说 pizza；pizza 是阴性词，所以用 una。
>
> 那不勒斯是披萨的故乡，最经典的两款：margherita（番茄、马苏里拉奶酪、罗勒）和 marinara（番茄、大蒜、牛至，没有奶酪）。街边还有 pizza a portafoglio：对折再对折，用纸包着边走边吃，portafoglio 本来是“钱包”。
>
> 店员常问 Qui o da portare via?（在这儿吃还是外带？）。外带说 da portare via，招牌上也常写 da asporto 或 asporto。
>
> 问要等多久：Quanto devo aspettare?（我得等多久？）。devo 是“我得、我必须”，aspettare 是“等”。回答多半是 Dieci minuti（10 分钟）或 Un quarto d'ora（一刻钟，15 分钟）。
>
> 发音（先听示范音频，以音频为准，下面只是帮你找音）：
> - pizza 的 zz 是加长的 ts，要先停一拍：PIZ-za。外来语ピザ不可信：少了这一拍，z 也不是ザ的音。
> - margherita 的 ghe 是硬的 g 加 e，像日语ゲ。哪里不像：日语词中间的ゲ有人会读得带鼻音，这里要读成清楚的 g。重音在 RI：mar-ghe-RI-ta。
> - aspettare 的 sp 中间不加元音，tt 要停一拍：a-spet-TA-re。
> - portare 的 r 要弹，por 后面不加元音：por-TA-re；via 是两个音节：VI-a。
> - devo 的 d 声带要振动；拼音的 d 是清音，不能拿来读。

</details>

### L17-01 — ✅ OK

- **it**：Una margherita, per favore.
- **zh**：请给我一个玛格丽特披萨。
- **note**：margherita 本身就指这款披萨，不用再说 pizza。

### L17-02 — ✅ OK

- **it**：Vorrei una pizza a portafoglio.
- **zh**：我想要一个折起来吃的街头披萨。
- **note**：对折再对折、边走边吃的那不勒斯街头披萨。Vorrei 比 Prendo 客气。

### L17-03 — ✅ OK

- **it**：Qui o da portare via?
- **zh**：在这儿吃还是外带？
- **note**：店员常问的话，听懂就行。

补充：店员有时也会问 Per qui o da portare via? 或 Mangia qui o porta via?，意思一样。

### L17-04 — ✅ OK

- **it**：Da portare via, per favore.
- **zh**：外带，谢谢。
- **note**：在店里吃就说 Qui, per favore。

### L17-05 — ✅ OK

- **it**：Quanto devo aspettare?
- **zh**：要等多久？
- **note**：回答常是 Dieci minuti（10 分钟）或 Un quarto d'ora（一刻钟，15 分钟）。

补充：排队或等餐时也很常问 Quanto c'è da aspettare?（要等多久？）。
