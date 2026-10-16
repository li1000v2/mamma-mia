# 示范音频粗筛：第 3 周

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-week3.html](audio-screen-week3.html)（在仓库里用浏览器打开）。

## 可疑片段

### 1. Dieci minuti, più o meno.

- 声线 f1@1（Kore） · 原速 · `a9cb30b26823f231.m4a`
- 问题：漏读（严重度 high，置信度 0.95）
- 理由：短语“più o meno”中的“o”被完全吞音漏读，不适合作为初学者教材。
  - 漏读「più o meno」：漏读了中间的连词“o”，直接连读成了“più meno”。
- 模型听到：Dieci minuti più meno.
- 转写模型听到：Dieci minuti più o meno（和原文一致）

### 2. Ecco a lei, e buone feste!

- 声线 m1@1（Charon） · 慢速 · `c98a3e52f7460bc0.m4a`
- 问题：读错、漏读（严重度 high，置信度 0.95）
- 理由：开头的“Ecco a”被读成了“equa”，且句末“feste”的词尾元音“e”缺失，发音明显不自然。
  - 读错「Ecco a」：“Ecco a”发音变形严重，听起来像“equa”。
  - 漏读「feste」：词尾的元音“e”被吞掉，听起来像“fest”。
- 模型听到：Equa lei, e buone fest
- 转写模型听到：Ecco a lei, e buone feste.（和原文一致）
- 双辅音需人工听：Ecco

### 3. Una margherita, per favore.

- 声线 f1@1（Kore） · 慢速 · `6b96ed202589dccd.m4a`
- 问题：读错（严重度 high，置信度 1.00）
- 理由：语音将句子读成了西班牙语（Una margarita, por favor），与意大利语目标文本（Una margherita, per favore）完全不符。
  - 读错「margherita」：将意大利语的 margherita 误读成了西班牙语的 margarita。
  - 读错「per favore」：将意大利语的 per favore 误读成了西班牙语的 por favor。
- 模型听到：Una margarita, por favor.
- 转写模型听到：Una margarita, por favor.（和原文不同）

### 4. Buonasera!

- 声线 f1@1（Kore） · 慢速 · `94d5e58a807d7bcd.m4a`
- 问题：读错（严重度 high，置信度 0.90）
- 理由：“Buonasera”中的“na”音节被明显误读成了“ne”，核心元音发音错误，不适合作为初学者示范音频。
  - 读错「Buonasera」：词中“buona”的元音“a”发成了“e”，听起来像“Buonesera”。
- 模型听到：Buonesera
- 转写模型听到：Buonasera（和原文一致）

### 5. A che ora chiude oggi?

- 声线 f1@1（Kore） · 原速 · `2b279185c4da2583.m4a`
- 问题：漏读（严重度 medium，置信度 0.70）
- 理由：音频漏读了目标文本最后的单词“oggi”。
  - 漏读「oggi」：漏读了句末的“oggi”。
- 模型听到：A che ora chiude?
- 转写模型听到：A che ora chiude oggi?（和原文一致）
- 双辅音需人工听：oggi

### 6. Buongiorno! Prego, dica.

- 声线 f1@1（Kore） · 原速 · `ac588818307b904b.m4a`
- 问题：漏读（严重度 medium，置信度 0.70）
- 理由：音频缺失了目标文本中的最后一个词。
  - 漏读「dica」：漏读了末尾的单词“dica”。
- 模型听到：Buongiorno! Prego.
- 转写模型听到：Buongiorno. Prego, dica.（和原文一致）

### 7. Oggi chiudiamo alle diciannove e trenta.

- 声线 f1@1（Kore） · 原速 · `f5d778e5920a3718.m4a`
- 问题：漏读（严重度 medium，置信度 0.70）
- 理由：音频漏读了数字之间的连词“e”，且存在轻微停顿。
  - 漏读「e」：漏读了连词“e”。
- 模型听到：Oggi chiudiamo alle diciannove trenta.
- 转写模型听到：Oggi chiudiamo alle diciannove e trenta.（和原文一致）
- 双辅音需人工听：Oggi, alle, diciannove

### 8. È aperto anche oggi?

- 声线 m1@1（Charon） · 原速 · `eff9efe98e704ac9.m4a`
- 问题：漏读（严重度 medium，置信度 0.70）
- 理由：aperto的词首元音被吞音，发音不完整。
  - 漏读「aperto」：词首元音a发音缺失，听起来像perto。
- 模型听到：È perto anche oggi?
- 转写模型听到：È aperto anche oggi?（和原文一致）
- 双辅音需人工听：oggi

### 9. È aperto anche oggi?

- 声线 m1@1（Charon） · 慢速 · `7d1a75271bab7eb3.m4a`
- 问题：漏读（严重度 medium，置信度 0.70）
- 理由：È和aperto连读过重导致词首元音a几乎完全缺失。
  - 漏读「È aperto」：aperto词首的元音a被吞音，听起来像perto。
- 模型听到：È perto anche oggi?
- 转写模型听到：È aperto anche oggi?（和原文一致）
- 双辅音需人工听：oggi

### 10. Ci sono ancora posti liberi?

- 声线 f1@1（Kore） · 慢速 · `b5e4b72b89c24792.m4a`
- 问题：读错（严重度 medium，置信度 0.75）
- 理由：“sono”一词的元音发音不准确，偏离了标准意大利语发音。
  - 读错「sono」：“sono”中的第一个元音“o”发成了“u”，听起来像“suno”。
- 模型听到：Ci suno ancora posti liberi?
- 转写模型听到：Ci sono ancora posti liberi?（和原文一致）

### 11. Dieci minuti, più o meno.

- 声线 f1@1（Kore） · 慢速 · `00010eab351fed62.m4a`
- 问题：读错（严重度 medium，置信度 0.75）
- 理由：“più o”发音不够清晰，合并成了“pio”。
  - 读错「più o」：“più o”听起来像“pio”，缺失了“u”的音。
- 模型听到：Dieci minuti, pio meno.
- 转写模型听到：Dieci minuti più o meno（和原文一致）

### 12. Attenzione! Il treno per Napoli Centrale partirà dal binario tredici anziché dal binario tre.

- 声线 m1@1（Charon） · 原速 · `0f1ed593dabb0cc9.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：句中第一个“binario”的首字母发音错误，读成了v音。
  - 读错「binario」：第一个“binario”被误读成了“vinario”。
- 模型听到：Attenzione! Il treno per Napoli Centrale partirà dal vinario tredici anziché dal binario tre.
- 转写模型听到：Attenzione, il treno per Napoli Centrale partirà dal binario tredici anziché dal binario tre.（和原文一致）
- 双辅音需人工听：Attenzione

### 13. Che giorno è oggi?

- 声线 f1@1（Kore） · 慢速 · `d78580195319fe34.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：首词“Che”发音有误，听起来像“Chi”。
  - 读错「Che」：将“Che”误读为了“Chi”。
- 模型听到：Chi giorno è oggi?
- 转写模型听到：Che giorno è oggi?（和原文一致）
- 双辅音需人工听：oggi

### 14. Circa venti minuti: oggi c'è tanta gente!

- 声线 m1@1（Charon） · 原速 · `8dbbcfb6ab7a1832.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：首词元音发音有误，听起来像另一个常见词“cerca”。
  - 读错「Circa」：发音听起来像“cerca”而非“circa”。
- 模型听到：Cerca venti minuti: oggi c'è tanta gente!
- 转写模型听到：Circa venti minuti, oggi c'è tanta gente.（和原文一致）
- 双辅音需人工听：oggi

### 15. Paga in contanti o con la carta?

- 声线 m1@1（Charon） · 慢速 · `21ba8fe5bc11e23c.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：首词 Paga 的词尾元音在与 in 连读时变音明显，听感类似 Paghe，可能误导初学者。
  - 读错「Paga」：词尾元音 a 发音更接近 e，听起来像 Paghe。
- 模型听到：Paghe in contanti o con la carta?
- 转写模型听到：Paga in contanti o con la carta?（和原文一致）

### 16. Solo andata o andata e ritorno?

- 声线 m1@1（Charon） · 慢速 · `3fa257d2d5b42527.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：第二个“andata”的词尾元音有误，听起来像“andate”。
  - 读错「andata」：第二个“andata”词尾发音像“andate”。
- 模型听到：Solo andata o andate e ritorno?
- 转写模型听到：Solo andata o andata e ritorno?（和原文一致）

### 17. Una margherita, per favore.

- 声线 f1@1（Kore） · 原速 · `f5389980e96ac37e.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：音频使用了西班牙语发音，导致核心词汇读错。
  - 读错「margherita, per favore」：按西班牙语读成了“margarita, por favor”。
- 模型听到：Una margarita, por favor.
- 转写模型听到：Una margarita, por favor.（和原文不同）

### 18. Ecco a lei, e buone feste!

- 声线 f1@1（Kore） · 原速 · `2d3fc9aaa6b884e7.m4a`
- 问题：截断（严重度 medium，置信度 0.75）
- 理由：音频结尾处被截断，导致最后一个词不完整。
  - 截断「feste」：末尾单词被截断，仅发出一半音节。
- 模型听到：Ecco a lei, e buone fe-
- 转写模型听到：Ecco a lei e buone feste.（和原文一致）
- 双辅音需人工听：Ecco

### 19. Buone feste!

- 声线 f1@1（Kore） · 原速 · `910a4e681f407f34.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：音频末尾被截断，缺失了最后一个元音。
  - 截断「feste」：词尾元音e被截断。
- 模型听到：Buone fest
- 转写模型听到：Buone feste（和原文一致）

### 20. Buongiorno, biglietto, prego.

- 声线 m1@1（Charon） · 原速 · `2402c9ea3d43512c.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：音频末尾的单词未读完即被截断。
  - 截断「prego」：末尾单词被截断。
- 模型听到：Buongiorno, biglietto, pre-
- 转写模型听到：Buongiorno, biglietto prego.（和原文一致）
- 双辅音需人工听：biglietto

### 21. Oggi chiudiamo alle diciotto.

- 声线 m1@1（Charon） · 原速 · `a513ddbdeeb3d750.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：句尾单词diciotto发音未完成即被截断。
  - 截断「diciotto」：末尾音节被截断。
- 模型听到：Oggi chiudiamo alle diciot-
- 转写模型听到：Oggi chiudiamo alle diciotto.（和原文一致）
- 双辅音需人工听：Oggi, alle, diciotto

### 22. Oggi chiudiamo alle ventuno.

- 声线 f1@1（Kore） · 慢速 · `b6617f6bdf03367c.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：音频末尾的“ventuno”被截断，缺少最后一个音节。
  - 截断「ventuno」：句末单词未读完即被截断。
- 模型听到：Oggi chiudiamo alle ventu
- 转写模型听到：Oggi chiudiamo alle ventuno.（和原文一致）
- 双辅音需人工听：Oggi, alle

### 23. Andata e ritorno o solo andata?

- 声线 f1@1（Kore） · 原速 · `6a6311cc7c7c7656.m4a`
- 问题：重音（严重度 medium，置信度 0.75）
- 理由：句首单词“Andata”重音位置明显错误。
  - 重音「Andata (第一个)」：重音错误地落在第一音节，读成了 Àn-da-ta 而非 an-dà-ta。
- 模型听到：Àndata e ritorno o solo andata?
- 转写模型听到：Andata e ritorno o solo andata?（和原文一致）

### 24. Vuole anche qualcosa da bere?

- 声线 m1@1（Charon） · 慢速 · `b58e64661a15a220.m4a`
- 问题：重音（严重度 medium，置信度 0.75）
- 理由：单词“anche”的重音位置明显错误，读成了“anché”。
  - 重音「anche」：重音错误地落在了第二个音节上。
- 模型听到：Vuole anché qualcosa da bere?
- 转写模型听到：Vuole anche qualcosa da bere?（和原文一致）

### 25. Andata e ritorno o solo andata?

- 声线 f1@1（Kore） · 慢速 · `f5ed306bfe3d66c9.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：句首的“Andata”重音位置错误，不符合意大利语发音规则。
  - 重音「Andata (第一个)」：首词重音错误地落在了第一音节（AN-da-ta）。
- 模型听到：Andata e ritorno o solo andata?
- 转写模型听到：Andata e ritorno o solo andata?（和原文一致）

### 26. Attenzione! Il treno per Napoli Centrale partirà dal binario cinque anziché dal binario tre.

- 声线 f1@1（Kore） · 原速 · `4a90e1cf51acd42d.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：“Napoli”一词重音位置明显错误。
  - 重音「Napoli」：重音错误地落在了第二个音节（na-PO-li）。
- 模型听到：Attenzione! Il treno per Napoli Centrale partirà dal binario cinque anziché dal binario tre.
- 转写模型听到：Attenzione, il treno per Napoli Centrale partirà dal binario cinque anziché dal binario tre.（和原文一致）
- 双辅音需人工听：Attenzione

### 27. Chiuso il lunedì.

- 声线 f1@1（Kore） · 原速 · `deca6797517ea273.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：“lunedì”的重音位置错误，未读在尾音节上。
  - 重音「lunedì」：重音错误地落在了第一音节而非最后一个带重音符号的音节。
- 模型听到：Chiuso il lùnedi.
- 转写模型听到：chiuso il lunedì（和原文一致）

### 28. Chiuso il lunedì.

- 声线 m1@1（Charon） · 原速 · `6d47455342f53f27.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：“lunedì”一词重音位置明显错误，未落在最后一个带重音符号的音节上。
  - 重音「lunedì」：重音错误地落在了第一音节而非尾音节。
- 模型听到：Chiuso il lunedì.
- 转写模型听到：Chiuso il lunedì.（和原文一致）

### 29. Il treno partirà dal binario cinque anziché dal binario tre.

- 声线 f1@1（Kore） · 慢速 · `6e8f6bcf5619c547.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：“anziché”一词的重音位置明显有误，未落在带重音符号的末音节上。
  - 重音「anziché」：重音错误地落在了首音节而非末音节。
- 模型听到：Il treno partirà dal binario cinque anziché dal binario tre.
- 转写模型听到：Il treno partirà dal binario cinque anziché dal binario tre（和原文一致）

### 30. Oggi è lunedì.

- 声线 m1@1（Charon） · 慢速 · `2ec0e8d3ba8620db.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：lunedì 的重音位置错误，听起来不自然。
  - 重音「lunedì」：重音未落在词尾音节 -dì 上。
- 模型听到：Oggi è lunedì.
- 转写模型听到：Oggi è lunedì（和原文一致）
- 双辅音需人工听：Oggi

### 31. Dal binario tre. Ecco il biglietto: carrozza dodici, posto sette.

- 声线 f1@1（Kore） · 慢速 · `4a1762582f4314bc.m4a`
- 问题：杂音（严重度 medium，置信度 0.70）
- 理由：“carrozza”前有明显唇齿杂音且发音气声过重，不够自然清晰。
  - 杂音「carrozza」：词前有明显吸气啧声，且该词开头呈气声。
- 模型听到：Dal binario tre. Ecco il biglietto: carrozza dodici, posto sette.
- 转写模型听到：Dal binario tre. Ecco il biglietto. Carrozza dodici, posto sette.（和原文一致）
- 双辅音需人工听：Ecco, biglietto, carrozza, sette

### 32. Sono un po' stanco.

- 声线 m1@1（Charon） · 原速 · `8f77ba72762929c7.m4a`
- 问题：杂音（严重度 medium，置信度 0.70）
- 理由：音频开头存在轻微杂音，其余发音正常。
  - 杂音「Sono」：词首有明显的爆破杂音。
- 模型听到：Psono un po' stanco.
- 转写模型听到：Sono un po' stanco.（和原文一致）

### 33. Ho fame. C'è una pizzeria qui vicino?

- 声线 f1@1（Kore） · 慢速 · `a0bb47825566ed55.m4a`
- 问题：放慢失真（严重度 medium，置信度 0.75）
- 理由：首句中的“fame”语调过于拖沓，且慢放处理导致了明显的机械失真感。
  - 放慢失真「fame」：“fame”被过度拉长，且伴有明显的慢放颤音失真。
- 模型听到：Ho fame. C'è una pizzeria qui vicino?
- 转写模型听到：Ho fame. C'è una pizzeria qui vicino?（和原文一致）
- 双辅音需人工听：pizzeria

### 34. Attenzione! Il treno per Napoli Centrale partirà dal binario cinque anziché dal binario tre.

- 声线 f1@1（Kore） · 慢速 · `4cea08ea0ccdc6a0.m4a`
- 问题：语调节奏（严重度 medium，置信度 0.75）
- 理由：前半部分发音清晰正常，但最后半句音量骤降且节奏突变，需要人工复核。
  - 语调节奏「anziché dal binario tre」：句末音量突然明显降低且语速变快，语调极不自然。
- 模型听到：Attenzione! Il treno per Napoli Centrale partirà dal binario cinque anziché dal binario tre.
- 转写模型听到：Attenzione, il treno per Napoli Centrale partirà dal binario cinque, anziché dal binario tre.（和原文一致）
- 双辅音需人工听：Attenzione

### 35. Scusi, è libero questo posto?

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
- 可疑：35 段（原速 18，慢速 17）
- 含双辅音的句子：31 句
- token：输入 163,548，输出 29,788，思考 147,378
- 花费估算：236 次 × $0.004 ≈ $0.94（按实测单价；只重筛新片段时实际花费更少）
