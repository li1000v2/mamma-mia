# 示范音频粗筛：第 5 周

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-week5.html](audio-screen-week5.html)（在仓库里用浏览器打开）。

## 可疑片段

### 1. Buonasera, dove andiamo?

- 声线 f1@1（Kore） · 慢速 · `1067636a9ae14764.m4a`
- 问题：读错（严重度 high，置信度 0.95）
- 理由：存在明显的发音错误，Buonasera 被读成了类似 uonasiera，dove 的词首元音也严重偏离标准发音。
  - 读错「Buonasera」：发音明显错误，开头的辅音 b 缺失，且 sera 被错误地读成了 siera。
  - 读错「dove」：元音 o 发音不准，听起来像 duve。
- 模型听到：Uonasiera, duve andiamo?
- 转写模型听到：Buonasera, dove andiamo?（和原文一致）

### 2. Quanto costa questo ombrello? Va bene, lo prendo.

- 声线 f1@1（Kore） · 原速 · `f43d7f2a3c4fd29d.m4a`
- 问题：读错（严重度 high，置信度 0.95）
- 理由：句首核心疑问词“Quanto”发音不完整，听起来像“Qunto”，不适合初学者跟读学习。
  - 读错「Quanto」：开头单词“Quanto”中的元音“a”被吞音或读错，听起来像“Qunto”。
- 模型听到：Qunto costa questo ombrello? Va bene, lo prendo.
- 转写模型听到：Quanto costa questo ombrello? Va bene, lo prendo.（和原文一致）
- 双辅音需人工听：ombrello

### 3. Allora le do qualcosa per il mal di testa. Sono sei euro e trenta.

- 声线 m1@1（Charon） · 慢速 · `7ca5e6d24e9563f2.m4a`
- 问题：重音（严重度 high，置信度 0.95）
- 理由：开头单词“Allora”的重音错误地落在了第一音节，听起来非常不自然，不适合作为初学者教材。
  - 重音「Allora」：重音位置明显错误，读在了第一音节（AL-lo-ra），正确应落在第二音节（al-LO-ra）。
- 模型听到：Allora, le do qualcosa per il mal di testa. Sono sei euro e trenta.
- 转写模型听到：Allora, le do qualcosa per il mal di testa. Sono sei euro e trenta.（和原文一致）
- 双辅音需人工听：Allora

### 4. Cerca il Colosseo? Prenda la metro B, direzione Laurentina: sono quattro fermate.

- 声线 m1@1（Charon） · 慢速 · `3ae2bee28bf246ef.m4a`
- 问题：漏读（严重度 medium，置信度 0.90）
- 理由：音频中“Cerca”和“direzione”的词尾音节出现明显的吞音或缺失，发音不够完整清晰，不适合初学者跟读学习。
  - 漏读「Cerca il」：“Cerca”词尾的元音“a”被吞音，与“il”连读听起来像“Cerch'il”，对初学者不够清晰。
  - 漏读「direzione」：“direzione”词尾的“-ne”发音缺失或严重吞音，听起来像“direzion”。
- 模型听到：Cerch'il Colosseo? Prenda la metro B, direzion Laurentina: sono quattro fermate.
- 转写模型听到：Cerca il Colosseo? Prenda la metro B, direzione Laurentina. Sono quattro fermate.（和原文一致）
- 双辅音需人工听：Colosseo, quattro

### 5. Buonasera! Dove la porto?

- 声线 m1@1（Charon） · 原速 · `5d853b2511678c2c.m4a`
- 问题：漏读（严重度 medium，置信度 0.70）
- 理由：末尾单词“porto”的最后一个元音丢失，影响初学者识别词形。
  - 漏读「porto」：词尾元音“o”发音缺失，听起来像“port”。
- 模型听到：Buonasera! Dove la port?
- 转写模型听到：Buonasera, dove la porto?（和原文一致）

### 6. E da bere?

- 声线 f1@1（Kore） · 慢速 · `a444b4793a6de5b5.m4a`
- 问题：漏读（严重度 medium，置信度 0.70）
- 理由：句末单词 bere 的尾音缺失，不适合初学者跟读。
  - 漏读「bere」：单词 bere 词尾的元音 e 缺失，发音成了 ber。
- 模型听到：E da ber?
- 转写模型听到：E da bere?（和原文一致）

### 7. Allora le do qualcosa per il mal di testa. Sono sei euro e trenta.

- 声线 f1@1（Kore） · 慢速 · `133736d9d3f0b7ff.m4a`
- 问题：读错（严重度 medium，置信度 0.90）
- 理由：前半句发音自然清晰，但第二句中的“euro e”被读成了“eure”，丢失了“euro”的词尾元音“o”，对初学者有误导。
  - 读错「euro e」：“euro e”被连读/误读成了“eure”，完全听不出“euro”词尾的元音“o”。
- 模型听到：Allora le do qualcosa per il mal di testa. Sono sei eure trenta.
- 转写模型听到：Allora le do qualcosa per il mal di testa. Sono sei euro e trenta.（和原文一致）
- 双辅音需人工听：Allora

### 8. Quanto costa fino all'aeroporto?

- 声线 f1@1（Kore） · 原速 · `f94d51e6071a687f.m4a`
- 问题：读错（严重度 medium，置信度 0.75）
- 理由：目标词“aeroporto”的元音和辅音顺序发生颠倒，被读成了“areoporto”。
  - 读错「all'aeroporto」：将“aeroporto”误读为“areoporto”。
- 模型听到：Quanto costa fino all'areoporto?
- 转写模型听到：Quanto costa fino all'aeroporto?（和原文一致）
- 双辅音需人工听：all

### 9. Quanto costa fino all'aeroporto?

- 声线 m1@1（Charon） · 慢速 · `0c105d1a6a17930d.m4a`
- 问题：读错（严重度 medium，置信度 0.75）
- 理由：目标词“all'aeroporto”音节顺序读错，发音成了“all'areoporto”。
  - 读错「all'aeroporto」：将“aeroporto”误读为“areoporto”。
- 模型听到：Quanto costa fino all'areoporto?
- 转写模型听到：Quanto costa fino all'aeroporto?（和原文一致）
- 双辅音需人工听：all

### 10. All'aeroporto di Fiumicino, per favore.

- 声线 m1@1（Charon） · 原速 · `996ed8acc11c36f3.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：“All'aeroporto”开头元音发音有误，其余部分正常。
  - 读错「All'aeroporto」：将“All'aeroporto”误读作“All'ereoporto”。
- 模型听到：All'ereoporto di Fiumicino, per favore.
- 转写模型听到：All'aeroporto di Fiumicino, per favore.（和原文一致）
- 双辅音需人工听：All

### 11. All'aeroporto di Fiumicino, per favore.

- 声线 m1@1（Charon） · 慢速 · `5ff2b0a6afe484eb.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：首词“All'aeroporto”被误读为“All'ereoporto”，其余部分发音正常。
  - 读错「All'aeroporto」：元音发音有误，读成了“All'ereoporto”。
- 模型听到：All'ereoporto di Fiumicino, per favore.
- 转写模型听到：All'aeroporto di Fiumicino, per favore.（和原文一致）
- 双辅音需人工听：All

### 12. Buonasera! Desidera?

- 声线 m1@1（Charon） · 慢速 · `5ed1e9580cd43eb8.m4a`
- 问题：读错、重音（严重度 medium，置信度 0.70）
- 理由：首词发音有误，且第二个词的重音位置明显错误。
  - 读错「Buonasera」：首词辅音发音不准，听起来像“Borasera”。
  - 重音「Desidera」：重音错误地落在词尾，应在第2音节（de-SI-de-ra）。
- 模型听到：Borasera! Desiderà?
- 转写模型听到：Buonasera, desidera?（和原文一致）

### 13. Buonasera, dove andiamo?

- 声线 f1@1（Kore） · 原速 · `73d75e8b85d42dc8.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：首词元音发音不准确。
  - 读错「Buonasera」：“Buo”被误读为“Bue”。
- 模型听到：Buenasera, dove andiamo?
- 转写模型听到：Buonasera, dove andiamo?（和原文一致）

### 14. Buonasera, dove andiamo?

- 声线 m1@1（Charon） · 慢速 · `919ed2f0cfa8dc9a.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：连读处发音有误，丢失了“andiamo”词首的元音“a”。
  - 读错「dove andiamo」：将 dove andiamo 误读为 dovendiamo，吞掉了 andiamo 开头的元音 a。
- 模型听到：Buonasera, dovendiamo?
- 转写模型听到：Buonasera, dove andiamo?（和原文一致）

### 15. Cerca il Colosseo? Prenda la metro B, direzione Laurentina: sono tre fermate.

- 声线 f1@1（Kore） · 原速 · `fa42d65f486e955b.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：开头的“Cerca”发音错误，被读成了另一个词“Circa”。
  - 读错「Cerca」：首词“Cerca”被误读为“Circa”。
- 模型听到：Circa il Colosseo? Prenda la metro B, direzione Laurentina: sono tre fermate.
- 转写模型听到：Cerca il Colosseo? Prenda la metro B, direzione Laurentina. Sono tre fermate.（和原文一致）
- 双辅音需人工听：Colosseo

### 16. Dov'è la polizia?

- 声线 m1@1（Charon） · 慢速 · `f75d5fb54179e5b6.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：单词polizia发音有误，z被错误读成c音。
  - 读错「polizia」：辅音z发音错误，被读成了c的音。
- 模型听到：Dov'è la policia?
- 转写模型听到：Dov'è la polizia?（和原文一致）

### 17. Ecco qua, per il mal di testa. Sono nove euro e sessanta.

- 声线 f1@1（Kore） · 原速 · `5c8dc59b3de8ad2b.m4a`
- 问题：读错、语调节奏（严重度 medium，置信度 0.70）
- 理由：“euro”元音发音有误，且句中存在不自然的拖音。
  - 读错「euro」：“euro”被误读为“auro”。
  - 语调节奏「Sono」：词尾拖音且停顿不自然。
- 模型听到：Ecco qua, per il mal di testa. Sono nove auro e sessanta.
- 转写模型听到：Ecco qua, per il mal di testa. Sono nove euro e sessanta.（和原文一致）
- 双辅音需人工听：Ecco, sessanta

### 18. Mi può fare la ricevuta?

- 声线 m1@1（Charon） · 慢速 · `66b7a837b3c72088.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：“può”一词发音有误，听起来像“po”，其余词汇及语调正常。
  - 读错「può」：“può”读成了“po”，漏掉了原有的/w/音。
- 模型听到：Mi po fare la ricevuta?
- 转写模型听到：Mi può fare la ricevuta?（和原文一致）

### 19. Quanto costa fino all'aeroporto?

- 声线 f1@1（Kore） · 慢速 · `b4d6227c3e7eccb2.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：末尾单词“aeroporto”音节错位，被读成了“areoporto”。
  - 读错「all'aeroporto」：将“aeroporto”误读为“areoporto”。
- 模型听到：Quanto costa fino all'areoporto?
- 转写模型听到：Quanto costa fino all'aeroporto?（和原文一致）
- 双辅音需人工听：all

### 20. Quanto costa fino all'aeroporto?

- 声线 m1@1（Charon） · 原速 · `fe156072f56ebf2e.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：“aeroporto”一词发音错误，读成了“areoporto”。
  - 读错「all'aeroporto」：将“aeroporto”误读为“areoporto”。
- 模型听到：Quanto costa fino all'areoporto?
- 转写模型听到：Quanto costa fino all'aeroporto?（和原文一致）
- 双辅音需人工听：all

### 21. Sì, certo. La polizia però è un po' lontana: in taxi sono venti minuti.

- 声线 m1@1（Charon） · 原速 · `1c7ed9a7b848fec3.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：“polizia”发音有误，辅音读错。
  - 读错「polizia」：“polizia”中的“z”被误读成了“c”（/tʃ/）的音。
- 模型听到：Sì, certo. La policia però è un po' lontana: in taxi sono venti minuti.
- 转写模型听到：Sì, certo. La polizia però è un po' lontana. In taxi sono venti minuti.（和原文一致）

### 22. Sì, certo. La polizia però è un po' lontana: in taxi sono venti minuti.

- 声线 m1@1（Charon） · 慢速 · `962d8ae34cebc270.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：“polizia”一词发音明显错误，不适合初学者跟读。
  - 读错「polizia」：将“polizia”中的“z”误读成了“c”（/tʃ/）的音。
- 模型听到：Sì, certo. La policia però è un po' lontana: in taxi sono venti minuti.
- 转写模型听到：Sì, certo. La polizia però è un po' lontana. In taxi sono venti minuti.（和原文一致）

### 23. Va bene. Prima chiami il 112, poi vada alla polizia. Ma lei sta bene?

- 声线 m1@1（Charon） · 慢速 · `23e970c1156fba7a.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：数字“112”被误读为“centro dodici”，不适合初学者。
  - 读错「112」：将“centododici”误读为“centro dodici”。
- 模型听到：Va bene. Prima chiami il centro dodici, poi vada alla polizia. Ma lei sta bene?
- 转写模型听到：Va bene. Prima chiami il centododici, poi vada alla polizia. Ma lei sta bene?（和原文不同）
- 双辅音需人工听：alla

### 24. Di dov'è?

- 声线 f1@1（Kore） · 慢速 · `8812235e67dd2fc3.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：将dov'è误读为dove，词尾缺少重音。
  - 重音「dov'è」：重音错误地落在do上，读成了dove而非dov'è。
- 模型听到：Di dove
- 转写模型听到：Di dov'è?（和原文一致）

### 25. Mi può chiamare un taxi?

- 声线 m1@1（Charon） · 原速 · `e343ec031601fb4d.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：末尾单词“taxi”重音位置不自然，不符合现代意大利语常见发音。
  - 重音「taxi」：单词重音落在了最后一个音节上，听起来像“taxì”而非标准的“tàxi”。
- 模型听到：Mi può chiamare un taxì?
- 转写模型听到：Mi può chiamare un taxi?（和原文一致）

### 26. Allora, cosa le porto?

- 声线 m1@1（Charon） · 慢速 · `db5c342de7a11677.m4a`
- 问题：杂音（严重度 medium，置信度 0.70）
- 理由：语音内容与重音正确，但词间停顿处有明显杂音。
  - 杂音「Allora 和 cosa 之间」：停顿处有明显的爆破杂音或音频伪影。
- 模型听到：Allora, cosa le porto?
- 转写模型听到：Allora, cosa le porto?（和原文一致）
- 双辅音需人工听：Allora

### 27. Ho perso il treno. A che ora parte il prossimo per Roma?

- 声线 f1@1（Kore） · 原速 · `a14e96f7e3f3c4f4.m4a`
- 问题：杂音（严重度 medium，置信度 0.70）
- 理由：语音发音自然准确，但两句之间存在明显的咔哒杂音。
  - 杂音「两句之间（约1.3秒处）」：在第二句开始前有明显的咔哒杂音。
- 模型听到：Ho perso il treno. A che ora parte il prossimo per Roma?
- 转写模型听到：Ho perso il treno. A che ora parte il prossimo per Roma?（和原文一致）
- 双辅音需人工听：prossimo

### 28. Sono da solo. Avete un tavolo libero?

- 声线 f1@1（Kore） · 慢速 · `511b7ea560342d89.m4a`
- 问题：杂音（严重度 medium，置信度 0.70）
- 理由：整体发音与语调准确自然，仅开头处存在轻微杂音。
  - 杂音「Sono 之前」：音频最开头有一声轻微的多余发声或合成杂音。
- 模型听到：Sono da solo. Avete un tavolo libero?
- 转写模型听到：Sono da solo, avete un tavolo libero?（和原文一致）

### 29. Aiuto!

- 声线 f1@1（Kore） · 慢速 · `e46c3e50a84267a9.m4a`
- 问题：放慢失真（严重度 medium，置信度 0.70）
- 理由：发音正确，但词尾因减速处理产生了明显的不自然颤音失真。
  - 放慢失真「Aiuto」：词尾元音因减速出现明显的颤抖和机械失真。
- 模型听到：Aiuto!
- 转写模型听到：Aiuto!（和原文一致）

### 30. Mi dispiace! Anche il passaporto?

- 声线 f1@1（Kore） · 慢速 · `8092042031e2e8d7.m4a`
- 问题：放慢失真、语调节奏（严重度 medium，置信度 0.70）
- 理由：前半句语调怪异且放慢后出现明显失真，不适合初学者课程。
  - 放慢失真「Mi dispiace」：放慢后气声失真明显，声音机械怪异。
  - 语调节奏「Mi dispiace」：语气过度低沉戏剧化，不自然。
- 模型听到：Mi dispiace! Anche il passaporto?
- 转写模型听到：Mi dispiace, anche il passaporto?（和原文一致）
- 双辅音需人工听：passaporto

### 31. Allora, cosa le porto?

- 声线 f1@1（Kore） · 原速 · `363df4f631fb050d.m4a`
- 问题：其他（严重度 medium，置信度 0.70）
- 理由：音频前后音色不一致，由女声突变为男声。
  - 其他「cosa le porto」：后半句声音突变为男声。
- 模型听到：Allora, cosa le porto?
- 转写模型听到：Allora, cosa le porto?（和原文一致）
- 双辅音需人工听：Allora

## 双辅音需人工听

这些句子含双辅音，长短要人去听（不计入可疑）：

- All'aeroporto di Fiumicino, per favore. — All
- Allora chiami subito il 112, è il numero per le emergenze. Ma lei come si sente? È un po' pallido. — Allora, pallido
- Allora le do qualcosa per il mal di testa. Sono sei euro e trenta. — Allora
- Allora, cosa le porto? — Allora
- Buongiorno! Il primo orario disponibile è alle dieci e quindici. Va bene? — alle
- Buongiorno! Il primo orario disponibile è alle tredici e venti. Va bene? — alle
- Buongiorno! Il primo orario disponibile è alle undici e trenta. Va bene? — alle
- C'è l'acqua alta oggi? — acqua, oggi
- Cerca il Colosseo? Prenda la metro B, direzione Laurentina: sono due fermate. — Colosseo
- Cerca il Colosseo? Prenda la metro B, direzione Laurentina: sono quattro fermate. — Colosseo, quattro
- Cerca il Colosseo? Prenda la metro B, direzione Laurentina: sono tre fermate. — Colosseo
- Certo, lo chiamo subito. Coraggio, e buona fortuna! — Coraggio
- Che bello! — bello
- D'accordo. Oggi c'è traffico: ci vogliono cinquanta minuti. — accordo, Oggi, traffico
- Ecco qua, per il mal di testa. Sono nove euro e sessanta. — Ecco, sessanta
- Ecco, questo è per il mal di testa. Sono sette euro e quaranta. — Ecco, sette
- Fatto: il taxi arriva subito. Coraggio! — Fatto, arriva, Coraggio
- Ha qualcosa per il raffreddore? — raffreddore
- Ho freddo. — freddo
- Ho mal di gola e un po' di febbre. — febbre
- Ho perso il passaporto. — passaporto
- Ho perso il treno. A che ora parte il prossimo per Roma? — prossimo
- Le piace questo cappello? Costa diciotto euro. — cappello, diciotto
- Le piace questo cappello? Costa dodici euro. — cappello
- Le piace questo cappello? Costa quindici euro. — cappello
- Mi dispiace! Anche il passaporto? — passaporto
- Mi hanno rubato il portafoglio. — hanno
- Non ho contanti. Posso pagare con il telefono? — Posso
- Oggi fa freddo. — Oggi, freddo
- Oh no! Le hanno rubato anche il passaporto? — hanno, passaporto
- Perfetto. Con questo traffico ci vogliono quaranta minuti. — Perfetto, traffico
- Quanto costa fino all'aeroporto? — all
- Quanto costa questo ombrello? Va bene, lo prendo. — ombrello
- Tutto bene? Le piace la carbonara? — Tutto
- Va bene. Prima chiami il 112, poi vada alla polizia. Ma lei sta bene? — alla
- Vorrei fare una denuncia. — Vorrei

## 统计

- 本周音频：264 段（原速 132，慢速 132）
- 已筛：264 段
- 可疑：31 段（原速 12，慢速 19）
- 含双辅音的句子：36 句
- token：输入 184,212，输出 32,100，思考 165,082
- 花费估算：264 次 × $0.004 ≈ $1.06（按实测单价；只重筛新片段时实际花费更少）
