# 示范音频粗筛：第 3 周

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-week3.html](audio-screen-week3.html)（在仓库里用浏览器打开）。

## 可疑片段

### 1. È aperto anche oggi?

- 声线 m1@1（Charon） · 原速 · `eff9efe98e704ac9.m4a`
- 问题：漏读（严重度 medium，置信度 0.70）
- 理由：aperto的词首元音被吞音，发音不完整。
  - 漏读「aperto」：词首元音a发音缺失，听起来像perto。
- 模型听到：È perto anche oggi?
- 转写模型听到：È aperto anche oggi?（和原文一致）
- 双辅音需人工听：oggi

### 2. È aperto anche oggi?

- 声线 m1@1（Charon） · 慢速 · `7d1a75271bab7eb3.m4a`
- 问题：漏读（严重度 medium，置信度 0.70）
- 理由：È和aperto连读过重导致词首元音a几乎完全缺失。
  - 漏读「È aperto」：aperto词首的元音a被吞音，听起来像perto。
- 模型听到：È perto anche oggi?
- 转写模型听到：È aperto anche oggi?（和原文一致）
- 双辅音需人工听：oggi

### 3. Buone feste!

- 声线 f1@1（Kore） · 慢速 · `2aa0ff15824163b4.m4a`
- 问题：截断、放慢失真（严重度 medium，置信度 0.70）
- 理由：开头辅音疑似被截断，且慢速拉长后音质有明显失真。
  - 截断「Buone」：开头辅音 b 被截断，听起来像 uone。
  - 放慢失真「feste」：慢速处理导致词尾声音发颤失真。
- 模型听到：uone feste

### 4. Chiuso il lunedì.

- 声线 m1@1（Charon） · 原速 · `6d47455342f53f27.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：“lunedì”一词重音位置明显错误，未落在最后一个带重音符号的音节上。
  - 重音「lunedì」：重音错误地落在了第一音节而非尾音节。
- 模型听到：Chiuso il lunedì.
- 转写模型听到：Chiuso il lunedì.（和原文一致）

### 5. Oggi è lunedì.

- 声线 m1@1（Charon） · 慢速 · `2ec0e8d3ba8620db.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：lunedì 的重音位置错误，听起来不自然。
  - 重音「lunedì」：重音未落在词尾音节 -dì 上。
- 模型听到：Oggi è lunedì.
- 转写模型听到：Oggi è lunedì（和原文一致）
- 双辅音需人工听：Oggi

### 6. Sono un po' stanco.

- 声线 m1@1（Charon） · 原速 · `8f77ba72762929c7.m4a`
- 问题：杂音（严重度 medium，置信度 0.70）
- 理由：句首发音带有明显杂音，影响听感。
  - 杂音「Sono」：开头有明显的爆破杂音，听起来像Psono。
- 模型听到：Psono un po' stanco.

### 7. Scusi, è libero questo posto?

- 声线 m1@1（Charon） · 原速 · `94757d474122d53b.m4a`
- 问题：语调节奏（严重度 medium，置信度 0.70）
- 理由：“è”被过度拉长，导致整体语流不自然。
  - 语调节奏「è」：“è”的发音被异常拉长，听起来像犹豫词。
- 模型听到：Scusi, èèè libero questo posto?
- 转写模型听到：Scusi, è libero questo posto?（和原文一致）

## 双辅音需人工听

这些句子含双辅音，长短要人去听（不计入可疑）：

- A che ora chiude oggi? — oggi
- A che ora parte il prossimo treno per Roma? — prossimo
- Attenzione! Il treno per Napoli Centrale partirà dal binario cinque anziché dal binario tre. — Attenzione
- Attenzione! Il treno per Napoli Centrale partirà dal binario tredici anziché dal binario tre. — Attenzione
- Attenzione! Il treno per Napoli Centrale, anziché dal binario tre, partirà dal binario sette. — Attenzione, sette
- Attenzione. Il treno per Napoli Centrale partirà con un ritardo di circa quaranta minuti. Ci scusiamo per il disagio. — Attenzione
- Attenzione. Il treno per Napoli Centrale è in ritardo di circa quindici minuti. Ci scusiamo per il disagio. — Attenzione
- Attenzione. Il treno per Napoli Centrale è in ritardo di circa venticinque minuti. Ci scusiamo per il disagio. — Attenzione
- Buongiorno, biglietto, prego. — biglietto
- Carrozza otto, posto ventidue. — Carrozza, otto
- Certo, entri pure! Oggi però è festa: chiudiamo presto. — Oggi
- Che giorno è oggi? — oggi
- Circa venti minuti: oggi c'è tanta gente! — oggi
- Dal binario tre. Ecco a lei: carrozza sei, posto quattordici. — Ecco, carrozza, quattordici
- Dal binario tre. Ecco il biglietto: carrozza dodici, posto sette. — Ecco, biglietto, carrozza, sette
- Dal binario tre. Ecco il biglietto: carrozza otto, posto ventidue. — Ecco, biglietto, carrozza, otto
- Ecco a lei, e buone feste! — Ecco
- Ecco la sua margherita. Buone feste! — Ecco
- Ho fame. C'è una pizzeria qui vicino? — pizzeria
- Il treno da Roma è in arrivo al binario due. — arrivo
- Oggi chiudiamo alle diciannove e trenta. — Oggi, alle, diciannove
- Oggi chiudiamo alle diciotto. — Oggi, alle, diciotto
- Oggi chiudiamo alle venti. — Oggi, alle
- Oggi chiudiamo alle ventuno. — Oggi, alle
- Oggi è festa? — Oggi
- Oggi è lunedì. — Oggi
- Quanto devo aspettare? — aspettare
- Sì, siamo aperti! Ma oggi è festa e chiudiamo prima. — oggi
- Un biglietto per Napoli, per favore. — biglietto
- Vorrei una pizza a portafoglio. — Vorrei, pizza
- È aperto anche oggi? — oggi

## 统计

- 本周音频：236 段（原速 118，慢速 118）
- 已筛：236 段
- 可疑：7 段（原速 4，慢速 3）
- 含双辅音的句子：31 句
- token：输入 163,660，输出 27,976，思考 138,156
- 花费估算：236 次 × $0.004 ≈ $0.94（按实测单价；只重筛新片段时实际花费更少）
