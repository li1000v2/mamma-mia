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
- 理由：该音频直接使用了美式英语的“cafe”发音，而非意大利语的“caffè”。
  - 读错「caffè」：使用了英语发音（/kæˈfeɪ/），元音与意大利语完全不符。
- 模型听到：cafe
- 转写模型听到：Caffè（和原文一致）
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

### 5. Posso pagare con la carta?

- 声线 m1@1（Charon） · 原速 · `3deae421f12d12c5.m4a`
- 问题：多出来的话（严重度 medium，置信度 0.70）
- 理由：“Posso”与“pagare”之间多出了不应有的元音“a”。
  - 多出来的话「Posso pagare」：两词之间多读了一个“a”音。
- 模型听到：Posso a pagare con la carta?
- 转写模型听到：Posso pagare con la carta?（和原文一致）
- 双辅音需人工听：Posso

### 6. biglietto

- 声线 m1@1（Charon） · 原速 · `42950c0514e42b03.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：单词中的gli发音不标准，带有明显外语口音。
  - 读错「biglietto」：辅音组合gli发音错误，读成了类似l加y的音。
- 模型听到：bilietto
- 转写模型听到：Biglietto（和原文一致）
- 双辅音需人工听：biglietto

### 7. caffè

- 声线 f1@1（Kore） · 慢速 · `b6f9a4f718d95cdc.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：单词按英语发音朗读，元音错误。
  - 读错「caffè」：使用了英语发音而非意大利语发音。
- 模型听到：caffè (pronuncia inglese)
- 转写模型听到：café（和原文不同）
- 双辅音需人工听：caffè

### 8. caffè

- 声线 m1@1（Charon） · 原速 · `c51c0dbf7d04ade4.m4a`
- 问题：读错、重音（严重度 medium，置信度 0.70）
- 理由：该词按英语发音，元音与重音位置均不正确。
  - 读错「caffè」：使用了英语元音发音。
  - 重音「caffè」：重音错误地落在了第一音节。
- 模型听到：cafe
- 转写模型听到：Caffè（和原文一致）
- 双辅音需人工听：caffè

### 9. caffè

- 声线 m1@1（Charon） · 慢速 · `87599519e1091485.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：单词按英语发音读出，不符合意大利语发音规则。
  - 读错「caffè」：使用了英语发音，词尾元音读成了双元音。
- 模型听到：cafe
- 转写模型听到：caffè（和原文一致）
- 双辅音需人工听：caffè

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
- 可疑：9 段（原速 6，慢速 3）
- 含双辅音的句子：22 句
- token：输入 127,521，输出 21,572，思考 105,476
- 花费估算：194 次 × $0.004 ≈ $0.78（按实测单价；只重筛新片段时实际花费更少）
