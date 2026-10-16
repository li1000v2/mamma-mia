# 交叉校对：L13 数字 100+、日期与星期

- 模型：gemini-4-argon（思考级别 HIGH），2026-10-16
- 6 条：6 条 OK，0 条建议修改（其中 0 处标为错误）
- 这份报告由 `tools/cross_check.py` 生成，只是机器审校意见：逐条判断后手动改内容文件。改完、确认没问题的句子才能标 `checked`，同时把 `checkedText` 设成它的意大利语原文。

## 逐条结果

### L13/intro — ✅ OK

<details><summary>intro 原文</summary>

> 100 以上：cento（100）、centoventi（120）、duecento（200）、trecento（300）、cinquecento（500）、mille（1000）、duemila（2000）。数字连成一个词写：centoventi、duecentocinquanta（250）。1000 是 mille，2000 起变成 -mila：duemila、tremila。
>
> 日期是 il + 数字 + 月份。只有 1 号用序数词 primo（第一）：il primo dicembre；其余日子直接用基数词：il due、il quindici、il trenta。8 号和 11 号以元音开头，il 要缩成 l'：l'otto、l'undici。
>
> 月份：gennaio, febbraio, marzo, aprile, maggio, giugno, luglio, agosto, settembre, ottobre, novembre, dicembre。
>
> 星期：lunedì（一）、martedì（二）、mercoledì（三）、giovedì（四）、venerdì（五）、sabato（六）、domenica（日）。月份和星期都小写。
>
> 星期前面不加冠词就是“（这个）星期一”：Oggi è lunedì。加上冠词 il lunedì 是“每个星期一”，店门口写的 Chiuso il lunedì 就是“每周一休息”。
>
> 发音（先听示范音频，以音频为准，下面只是帮你找音）：
> - cento、cinque 的 ce、ci 像英语 church 的 ch。哪里不像：后面的 e、i 短而纯，不要滑成英语那样的双元音。
> - 星期一到五的重音都在最后的 dì：lu-ne-DÌ、ve-ner-DÌ；另外两个不一样：SA-ba-to、do-ME-ni-ca。重音靠读得更响，不靠把音调抬高。
> - primo、tre、quattro 里的 pr、tr 中间不加元音：pri 不是 pu-ri。
> - lunedì、uno 的 u 要圆唇往前突，日语的う是扁的，不能直接拿来用。

</details>

### L13-01 — ✅ OK

- **it**：il primo dicembre
- **zh**：12 月 1 日
- **note**：1 号用序数词 primo（第一）；其余日子直接用数字：il due、il tre、il venti。pr 中间不加元音，r 要弹：PRI-mo。

补充：口语中有时也会听到用基数词说 1 号（l'uno dicembre），但用序数词 il primo 是最标准、最常见的说法。

### L13-02 — ✅ OK

- **it**：Che giorno è oggi?
- **zh**：今天几号？／今天星期几？
- **note**：两种意思都能问。回答 Oggi è lunedì（今天星期一）或 Oggi è il quindici（今天 15 号）。

补充：专门问“今天几号”时，意大利人也很常说 Quanti ne abbiamo oggi?（字面“我们今天有几个？”）。

### L13-03 — ✅ OK

- **it**：Oggi è lunedì.
- **zh**：今天星期一。
- **note**：说星期几不加冠词，说日期才加 il。重音在最后：lu-ne-DÌ；lu 的 u 要圆唇。

### L13-04 — ✅ OK

- **it**：Chiuso il lunedì.
- **zh**：每周一休息。
- **note**：店门口、景点门口常见的告示。il lunedì 带冠词，是“每个星期一”。

### L13-05 — ✅ OK

- **it**：Sono centoventi euro.
- **zh**：一共一百二十欧。
- **note**：cento + venti 连成一个词，重音在 VEN：cen-to-VEN-ti。euro 复数不变，读 EU-ro：从 e 滑到圆唇的 u，两个元音都要发出来；外来语ユーロ不可信，开头不是“优”。
