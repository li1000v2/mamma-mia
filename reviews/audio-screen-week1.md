# 示范音频粗筛：第 1 周

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-week1.html](audio-screen-week1.html)（在仓库里用浏览器打开）。

## 可疑片段

### 1. Napoli

- 声线 m1@1（Charon） · 原速 · `2e359c62aa64127a.m4a`
- 问题：漏读（严重度 high，置信度 0.95）
- 理由：单词 Napoli 中间的音节发音不完整，元音 o 缺失，听起来像 Napli。
  - 漏读「Napoli」：中间的元音 o 被吞掉，听起来像 Napli。
- 模型听到：Napli
- 转写模型听到：Napoli（和原文一致）

### 2. caffè

- 声线 f1@1（Kore） · 原速 · `d9890204c1d54ddf.m4a`
- 问题：读错（严重度 high，置信度 1.00）
- 理由：该音频直接按英语发音朗读了单词，不适合作为意大利语教学素材。
  - 读错「caffè」：完全使用了美式英语“café”（/kæˈfeɪ/）的发音，元音错误，不符合意大利语发音规则。
- 模型听到：café
- 转写模型听到：caffè（和原文一致）
- 双辅音需人工听：caffè

### 3. biglietto

- 声线 m1@1（Charon） · 慢速 · `e997ccf45977906d.m4a`
- 问题：读错（严重度 high，置信度 0.95）
- 理由：“biglietto”中的“gli”发音错误，被读成了带停顿的“bil-ietto”，会误导初学者。
  - 读错「biglietto」：词中的“gli”没有发成正确的意大利语硬颚边音，而是被错误地拆开发成了“bil-ietto”。
- 模型听到：bilietto
- 转写模型听到：biglietto（和原文一致）
- 双辅音需人工听：biglietto

### 4. chiesa

- 声线 m1@1（Charon） · 原速 · `b057c1e297e53cdf.m4a`
- 问题：读错（严重度 high，置信度 0.95）
- 理由：“chiesa”发音错误，被拆成了三个音节且带有浓重的英语口音，不适合作为教学示范。
  - 读错「chiesa」：将双元音读成了分音节的“ki-e-sa”，且带有明显的英语口音和送气音。
- 模型听到：chi-e-sa
- 转写模型听到：chiesa（和原文一致）

### 5. Me lo può scrivere?

- 声线 f1@1（Kore） · 慢速 · `217be0b9eb085f58.m4a`
- 问题：读错、重音、放慢失真（严重度 high，置信度 0.90）
- 理由：“lo”发音带有浓重的英语双元音口音，“scrivere”重音和语调不自然，且伴有放慢导致的失真，不适合初学者模仿。
  - 读错「lo」：“lo”的元音发成了类似英语“low”的双元音[oʊ]，带有明显的外语口音。
  - 重音「scrivere」：“scrivere”的重音本应在第一音节（SCRI-ve-re），但音频听起来重音后移且语调怪异。
  - 放慢失真「lo può」：放慢后在“lo può”处有明显的机械颤音失真。
- 模型听到：Me lo può scrivere?
- 转写模型听到：Me lo può scrivere?（和原文一致）

### 6. Posso pagare con la carta?

- 声线 m1@1（Charon） · 原速 · `3deae421f12d12c5.m4a`
- 问题：多出来的话（严重度 medium，置信度 0.70）
- 理由：“Posso”与“pagare”之间多出了不应有的元音“a”。
  - 多出来的话「Posso pagare」：两词之间多读了一个“a”音。
- 模型听到：Posso a pagare con la carta?
- 转写模型听到：Posso pagare con la carta?（和原文一致）
- 双辅音需人工听：Posso

### 7. Ho perso il biglietto.

- 声线 f1@1（Kore） · 慢速 · `33e66e11b7ae3e01.m4a`
- 问题：漏读（严重度 medium，置信度 0.80）
- 理由：冠词“il”发音不完整，不适合初级课程展示。
  - 漏读「il」：冠词“il”的元音“i”缺失，与前词连读成了“persol”。
- 模型听到：Ho persol biglietto.
- 转写模型听到：Ho perso il biglietto（和原文一致）
- 双辅音需人工听：biglietto

### 8. Certo, ecco. Grazie e buona giornata!

- 声线 f1@1（Kore） · 慢速 · `2eeba756b05ac40e.m4a`
- 问题：读错（严重度 medium，置信度 0.90）
- 理由：首词“Certo”发音失真，开头辅音听起来像“zarto”，容易误导初学者对软音 c 的发音认知。
  - 读错「Certo」：开头的辅音 c 发音像清塞擦音 z [ts]，且元音 e 过于开阔接近 a，听起来像“zarto”。
- 模型听到：Zarto, ecco. Grazie e buona giornata!
- 转写模型听到：Certo. Ecco. Grazie e buona giornata.（和原文一致）
- 双辅音需人工听：ecco

### 9. Un cappuccino e una brioche, per favore.

- 声线 f1@1（Kore） · 慢速 · `701c00a0780f9434.m4a`
- 问题：读错、语调节奏（严重度 medium，置信度 0.85）
- 理由：“cappuccino”一词发音带有明显的英语送气特征且语调不自然，不适合作为初学者跟读示范。
  - 读错「cappuccino」：词首的 c 带有明显的英语式送气音（听起来像 kha-pu-ci-no），不符合意大利语不送气清辅音的发音规范。
  - 语调节奏「Un cappuccino」：开头词组的语调起伏生硬怪异，带有明显的外语口音感。
- 模型听到：Un cappuccino e una brioche, per favore.
- 转写模型听到：Un cappuccino e una brioche, per favore.（和原文一致）
- 双辅音需人工听：cappuccino

### 10. A che ora chiude il museo?

- 声线 f1@1（Kore） · 慢速 · `2d33feb46d176731.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：开头“che ora”发音不准确，粘连成了“chiura”。
  - 读错「che ora」：“che ora”发音错误，听起来像“chiura”。
- 模型听到：A chiura chiude il museo?
- 转写模型听到：A che ora chiude il museo?（和原文一致）

### 11. Altro?

- 声线 f1@1（Kore） · 慢速 · `1bf60bdd1be03acd.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：该音频使用了美式英语口音朗读，不符合意大利语发音规则。
  - 读错「Altro」：辅音r和词尾元音o使用了明显的美式英语发音。
- 模型听到：Altro?
- 转写模型听到：Altro?（和原文一致）

### 12. Ciao!

- 声线 f1@1（Kore） · 原速 · `45e16d8ff2404408.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：目标词发音不准确，词尾的o被读成了i。
  - 读错「Ciao」：词尾元音发音有误，听起来像“Ciai”。
- 模型听到：Ciai!
- 转写模型听到：Ciao!（和原文一致）

### 13. Ecco lo scontrino.

- 声线 m1@1（Charon） · 慢速 · `5ea3ee52923d2762.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：整体清晰，但 scontrino 词首辅音发音不够标准，可能误导初学者。
  - 读错「scontrino」：词首的 s 发音偏向卷舌的 sh 音，不够标准。
- 模型听到：Ecco lo scontrino.
- 转写模型听到：Ecco lo scontrino.（和原文一致）
- 双辅音需人工听：Ecco

### 14. Ho perso il biglietto.

- 声线 f1@1（Kore） · 原速 · `810fe363eed78c08.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：“biglietto”的辅音组合“gli”发音有误，建议人工复核。
  - 读错「biglietto」：词中的“gli”发音不标准，听起来像“y”音。
- 模型听到：Ho perso il biyeto.
- 转写模型听到：Ho perso il biglietto（和原文一致）
- 双辅音需人工听：biglietto

### 15. Mamma mia!

- 声线 m1@1（Charon） · 慢速 · `187c359c5e8b73b7.m4a`
- 问题：读错、放慢失真（严重度 medium，置信度 0.70）
- 理由：发音呈英语口音且元音不准，同时慢速处理造成了明显的声音失真。
  - 读错「Mamma mia」：带有明显英语口音，词尾元音弱化不准确。
  - 放慢失真「整句」：降速导致尾音严重沙哑失真。
- 模型听到：Mama mia!
- 转写模型听到：Mamma mia!（和原文一致）
- 双辅音需人工听：Mamma

### 16. Me lo può scrivere?

- 声线 f1@1（Kore） · 原速 · `ae2086d63c2bd9c7.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：“lo”的发音明显带有英语口音，不符合意大利语发音规范。
  - 读错「lo」：元音被读成了类似英语的双元音/oʊ/。
- 模型听到：Me lo può scrivere?
- 转写模型听到：Me lo può scrivere?（和原文一致）

### 17. Me lo può scrivere?

- 声线 m1@1（Charon） · 慢速 · `1dcc1e036b2a4e39.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：单词“può”发音有误，漏掉了其中的“u”音。
  - 读错「può」：“può”读成了“po”，缺少“u”音。
- 模型听到：Me lo po scrivere?
- 转写模型听到：Me lo può scrivere?（和原文一致）

### 18. Quant'è?

- 声线 m1@1（Charon） · 原速 · `8d85ffc594058351.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：将“Quant'è?”误读为重音在首音节的“quante”。
  - 读错「Quant'è」：重音错误地落在第一音节，读成了“quante”。
- 模型听到：Quante
- 转写模型听到：Quant'è?（和原文一致）

### 19. biglietto

- 声线 m1@1（Charon） · 原速 · `42950c0514e42b03.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：单词中的gli发音不标准，带有明显外语口音。
  - 读错「biglietto」：辅音组合gli发音错误，读成了类似l加y的音。
- 模型听到：bilietto
- 转写模型听到：Biglietto（和原文一致）
- 双辅音需人工听：biglietto

### 20. caffè

- 声线 f1@1（Kore） · 慢速 · `b6f9a4f718d95cdc.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：该词使用了英语发音而非意大利语发音。
  - 读错「caffè」：按英语发音读作了 /kæfeɪ/，元音明显错误。
- 模型听到：café
- 转写模型听到：café（和原文不同）
- 双辅音需人工听：caffè

### 21. caffè

- 声线 m1@1（Charon） · 原速 · `c51c0dbf7d04ade4.m4a`
- 问题：读错、重音（严重度 medium，置信度 0.70）
- 理由：该词按英语发音，元音与重音位置均不正确。
  - 读错「caffè」：使用了英语元音发音。
  - 重音「caffè」：重音错误地落在了第一音节。
- 模型听到：cafe
- 转写模型听到：Caffè（和原文一致）
- 双辅音需人工听：caffè

### 22. caffè

- 声线 m1@1（Charon） · 慢速 · `87599519e1091485.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：单词按英语发音读出，不符合意大利语发音规则。
  - 读错「caffè」：使用了英语发音，词尾元音读成了双元音。
- 模型听到：cafe
- 转写模型听到：caffè（和原文一致）
- 双辅音需人工听：caffè

### 23. uscita

- 声线 f1@1（Kore） · 原速 · `262267f686613e95.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：单词发音错误，多出了不该有的辅音r。
  - 读错「uscita」：在第一个音节后多发了一个r音，听起来像urscita。
- 模型听到：urscita
- 转写模型听到：Uscita（和原文一致）

### 24. Scusi.

- 声线 m1@1（Charon） · 原速 · `a53cfd927047f816.m4a`
- 问题：杂音、截断（严重度 medium，置信度 0.85）
- 理由：发音开头带有明显的杂音（类似 p 的爆破音），且整体发音过于急促短促。
  - 杂音「Scusi 开头」：音频开头有一声明显的爆破杂音，听起来像多了一个辅音 p。
  - 截断「Scusi 结尾」：词尾收音过于急促，略微有被截断的感觉。
- 模型听到：Scusi
- 转写模型听到：Scusi?（和原文一致）

### 25. Sono un euro e venti.

- 声线 m1@1（Charon） · 原速 · `0e48ebe7a8c71195.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：音频在最后一个词处突然中断，发音不完整。
  - 截断「venti」：末尾单词词尾被截断。
- 模型听到：Sono un euro e vent-
- 转写模型听到：Sono un euro e venti.（和原文一致）

### 26. Un euro e trenta, grazie.

- 声线 f1@1（Kore） · 原速 · `c0984323ce97b83a.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：音频末尾的单词被明显截断，发音不完整。
  - 截断「grazie」：末尾单词发音被截断。
- 模型听到：Un euro e trenta, grazi-
- 转写模型听到：Un euro e trenta, grazie.（和原文一致）

## 双辅音需人工听

这些句子含双辅音，长短要人去听（不计入可疑）：

- Buongiorno! Allora, oggi abbiamo cornetti alla crema, al cioccolato e integrali: cosa le do? — Allora, oggi, abbiamo, cornetti, alla, cioccolato
- Certo, ecco. Grazie e buona giornata! — ecco
- Certo. Ecco lo scontrino. — Ecco
- Cornetti: crema, cioccolato o integrale? — Cornetti, cioccolato
- Dov'è la fermata del vaporetto? — vaporetto
- Due biglietti per Napoli, per favore. — biglietti
- Ecco lo scontrino. — Ecco
- Grazie mille! — mille
- Ho perso il biglietto. — biglietto
- Mamma mia! — Mamma
- Posso avere lo scontrino? — Posso
- Posso pagare con la carta? — Posso
- Prendo un cappuccino. — cappuccino
- Quanto costa un biglietto? — biglietto
- Sono cinque euro e sessanta. — sessanta
- Sono due euro e ottanta. — ottanta
- Un cappuccino e una brioche, per favore. — cappuccino
- Vorrei un caffè, per favore. — Vorrei, caffè
- biglietto — biglietto
- caffè — caffè
- gnocchi — gnocchi
- È una palla, non una pala. — palla

## 统计

- 本周音频：194 段（原速 97，慢速 97）
- 已筛：194 段
- 可疑：26 段（原速 14，慢速 12）
- 含双辅音的句子：22 句
- token：输入 127,501，输出 22,668，思考 109,787
- 花费估算：194 次 × $0.004 ≈ $0.78（按实测单价；只重筛新片段时实际花费更少）
