# 示范音频粗筛：第 4 周

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-week4.html](audio-screen-week4.html)（在仓库里用浏览器打开）。

## 可疑片段

### 1. Ah, JoJo! Allora benvenuto a Roma. Buona visita!

- 声线 f1@1（Kore） · 原速 · `939e7b0689638d43.m4a`
- 问题：漏读（严重度 high，置信度 1.00）
- 理由：音频开头漏读了“Ah, JoJo!”，直接从“Allora”开始朗读。
  - 漏读「Ah, JoJo!」：漏读了开头的“Ah, JoJo!”。
- 模型听到：Allora benvenuto a Roma. Buona visita!
- 转写模型听到：Ah Giorgio! Allora, benvenuto a Roma! Buona visita!（和原文不同）
- 双辅音需人工听：Allora

### 2. Certo! Dove devo premere?

- 声线 f1@1（Kore） · 原速 · `72bf158dcb0f880d.m4a`
- 问题：多出来的话（严重度 medium，置信度 0.70）
- 理由：两句之间多出了一个明显的犹豫语气词，与目标文本不完全相符。
  - 多出来的话「Certo 之后」：包含了原文中没有的语气词“eh”。
- 模型听到：Certo! Eh, dove devo premere?
- 转写模型听到：Certo, eh dove devo premere?（和原文不同）

### 3. Certo! Dove devo premere?

- 声线 f1@1（Kore） · 慢速 · `955b47306d61870e.m4a`
- 问题：多出来的话（严重度 medium，置信度 0.70）
- 理由：两句之间多出了目标文本中没有的语气词“eh”。
  - 多出来的话「Certo! 之后」：多读了语气词“eh”。
- 模型听到：Certo! Eh, dove devo premere?
- 转写模型听到：Certo, eh dove devo premere?（和原文不同）

### 4. Lo prendo.

- 声线 m1@1（Charon） · 慢速 · `b49e346a2f4b1c2a.m4a`
- 问题：多出来的话（严重度 medium，置信度 0.70）
- 理由：开头包含目标文本之外的哼声，其余发音正常。
  - 多出来的话「开头」：句首有多余的哼声。
- 模型听到：Hm, lo prendo.
- 转写模型听到：Lo prendo.（和原文一致）

### 5. Va bene! Sorrida… ecco fatto. Perché proprio qui?

- 声线 m1@1（Charon） · 慢速 · `1a04265532f09de7.m4a`
- 问题：杂音、读错（严重度 medium，置信度 0.90）
- 理由：音频开头存在杂音伪影，且“proprio”一词漏读了第二个“r”音，不适合作为初学者教材。
  - 杂音「Va bene」：开头“Va”之前有明显的杂音或多余的气声伪影。
  - 读错「proprio」：“proprio”中的第二个辅音“r”缺失，被读成了“propio”，且最后一句音量明显变小。
- 模型听到：Va bene! Sorrida… ecco fatto. Perché propio qui?
- 转写模型听到：Va bene, sorrida. Ecco fatto. Perché proprio qui?（和原文一致）
- 双辅音需人工听：Sorrida, ecco, fatto

### 6. Buongiorno! Mi dica.

- 声线 m1@1（Charon） · 慢速 · `3eed0553a758803b.m4a`
- 问题：读错、放慢失真（严重度 medium，置信度 0.70）
- 理由：开头辅音发音失真，且整体音频有明显的慢速机械失真感。
  - 读错「Buongiorno」：首字母B发音不清，听起来像M。
  - 放慢失真「整句」：慢速处理导致声音沙哑、颤抖且机械感明显。
- 模型听到：Muongiorno! Mi dica.
- 转写模型听到：Buongiorno, mi dica.（和原文一致）

### 7. Sono sedici euro, grazie. Ecco il biglietto.

- 声线 f1@1（Kore） · 原速 · `bc7a1d9b105d31e1.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：单词“grazie”发音有误，缺失了辅音“r”。
  - 读错「grazie」：“grazie”漏掉了“r”音，被读成了“gazie”。
- 模型听到：Sono sedici euro, gazie. Ecco il biglietto.
- 转写模型听到：Sono 16 euro grazie ecco il biglietto（和原文不同）
- 双辅音需人工听：Ecco, biglietto

### 8. Sono un fan di JoJo.

- 声线 m1@1（Charon） · 原速 · `e64c7b25453116be.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：语音将目标词“JoJo”错读成了“Giorgio”。
  - 读错「JoJo」：将“JoJo”误读为了“Giorgio”。
- 模型听到：Sono un fan di Giorgio.
- 转写模型听到：Sono un fan di JoJo（和原文一致）

### 9. Sono un fan di JoJo.

- 声线 m1@1（Charon） · 慢速 · `2bd2b8f1028a4af2.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：末尾词汇被误读为另一个名字。
  - 读错「JoJo」：将 JoJo 误读为 Giorgio。
- 模型听到：Sono un fan di Giorgio.
- 转写模型听到：Sono un fan di Jojo.（和原文一致）

### 10. Sì: prenda la prima a destra, poi all'incrocio giri a sinistra. La metro è lì.

- 声线 m1@1（Charon） · 慢速 · `5406079a3a8f90c3.m4a`
- 问题：截断（严重度 medium，置信度 0.95）
- 理由：整体发音和语调自然，但最后一个词“lì”在结尾处被明显截断，不够完整。
  - 截断「lì」：音频结尾处的“lì”元音尚未发完就被突然截断。
- 模型听到：Sì: prenda la prima a destra, poi all'incrocio giri a sinistra. La metro è lì
- 转写模型听到：Sì, prenda la prima a destra, poi all'incrocio giri a sinistra. La metro è lì.（和原文一致）
- 双辅音需人工听：all

### 11. L'ingresso? Giri a destra, è lì.

- 声线 m1@1（Charon） · 原速 · `ee151c4278d22b93.m4a`
- 问题：截断（严重度 medium，置信度 0.75）
- 理由：音频末尾的“lì”被明显截断，发音不完整。
  - 截断「lì」：句末单词发音未结束即被截断。
- 模型听到：L'ingresso? Giri a destra, è lì-
- 转写模型听到：L'ingresso? Giri a destra, è lì.（和原文一致）
- 双辅音需人工听：ingresso

### 12. Dove devo scendere?

- 声线 f1@1（Kore） · 原速 · `cedabe2ff9eb8e58.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：句末单词“scendere”未完整发音，缺少最后的元音。
  - 截断「scendere」：词尾元音“e”缺失或被截断。
- 模型听到：Dove devo scender
- 转写模型听到：Dove devo scendere?（和原文一致）

### 13. Dove devo scendere?

- 声线 f1@1（Kore） · 慢速 · `f3a90493dfcdd4c3.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：句末单词“scendere”词尾被截断，发音不完整。
  - 截断「scendere」：词尾元音“e”被截断。
- 模型听到：Dove devo scender
- 转写模型听到：Dove devo scendere?（和原文一致）

### 14. L'ingresso? Giri a sinistra, è lì.

- 声线 f1@1（Kore） · 原速 · `17d7486efe7d9f7b.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：音频结尾处的“lì”发音被截断，听起来不完整。
  - 截断「lì」：句末最后一个词的元音被突然截断。
- 模型听到：L'ingresso? Giri a sinistra, è lì.
- 转写模型听到：L'ingresso? Giri a sinistra, è lì.（和原文一致）
- 双辅音需人工听：ingresso

### 15. Si può andare a piedi?

- 声线 m1@1（Charon） · 原速 · `e0b1a38451e59c1c.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：音频末尾被截断，单词piedi发音不完整。
  - 截断「piedi」：末尾单词piedi被截断，缺少最后一个音节。
- 模型听到：Si può andare a pie
- 转写模型听到：Si può andare a piedi?（和原文一致）

### 16. Ah, JoJo! Qui ne vengono tanti. Buona visita!

- 声线 m1@1（Charon） · 原速 · `611656146f43d74e.m4a`
- 问题：重音（严重度 medium，置信度 0.75）
- 理由：动词“vengono”重音位置明显错误。
  - 重音「vengono」：重音错放在第二音节，应在第一音节。
- 模型听到：Ah, JoJo! Qui ne vengono tanti. Buona visita!
- 转写模型听到：Ah, Jojo, qui ne vengono tanti. Buona visita.（和原文一致）

### 17. Dove devo scendere?

- 声线 m1@1（Charon） · 原速 · `ef9110cc3f133c6c.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：首词“Dove”重音位置错误。
  - 重音「Dove」：重音错误地落在了第二个音节，听起来像“dov'è”。
- 模型听到：Dov'è devo scendere?
- 转写模型听到：Dove devo scendere?（和原文一致）

### 18. L'ingresso? Giri a destra, è lì.

- 声线 f1@1（Kore） · 原速 · `2089989109dba405.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：末尾“è lì”的重音和连读处理不当，听起来不自然。
  - 重音「è lì」：末尾的“è lì”重音错误，听起来像单个词“elli”，且尾音略微截断。
- 模型听到：L'ingresso? Giri a destra, elli.
- 转写模型听到：L'ingresso? Giri a destra, è lì.（和原文一致）
- 双辅音需人工听：ingresso

### 19. L'ingresso? Giri a destra, è lì.

- 声线 f1@1（Kore） · 慢速 · `7439883bcf02d7e4.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：末尾“è lì”的重音和语调不正确，听起来像名字“Ellie”。
  - 重音「è lì」：重音错误地落在了“è”上，听起来像单个词“elli”。
- 模型听到：L'ingresso? Giri a destra, elli.
- 转写模型听到：L'ingresso? Giri a destra, è lì.（和原文一致）
- 双辅音需人工听：ingresso

### 20. L'ingresso? Vada sempre dritto, è lì.

- 声线 m1@1（Charon） · 原速 · `18a560ea17edba35.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：“Vada”一词重音位置明显错误。
  - 重音「Vada」：重音错误地落在了第二个音节上，读成了vadà。
- 模型听到：L'ingresso? Vadà sempre dritto, è lì.
- 转写模型听到：L'ingresso? Vada sempre dritto, è lì.（和原文一致）
- 双辅音需人工听：ingresso, dritto

### 21. Serve la prenotazione?

- 声线 m1@1（Charon） · 原速 · `08425edc6ba92927.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：首词重音位置错误，发音不自然。
  - 重音「Serve」：重音错误地放在了第二个音节。
- 模型听到：Serve la prenotazione?
- 转写模型听到：serve la prenotazione（和原文一致）

### 22. Certo! Ecco fatto. Va bene così?

- 声线 f1@1（Kore） · 慢速 · `20bd76ce5e71b3c5.m4a`
- 问题：杂音（严重度 medium，置信度 0.70）
- 理由：整体发音与语调自然，但在“Ecco”前有一处明显的音频杂音。
  - 杂音「Ecco」：“Ecco”一词前有明显的爆破杂音。
- 模型听到：Certo! Ecco fatto. Va bene così?
- 转写模型听到：Certo. Ecco fatto. Va bene così?（和原文一致）
- 双辅音需人工听：Ecco, fatto

### 23. Lo prendo.

- 声线 m1@1（Charon） · 原速 · `4e2ce327734aa8f3.m4a`
- 问题：杂音（严重度 medium，置信度 0.70）
- 理由：音频开头存在多余的人声杂音，但目标短语发音清晰。
  - 杂音「开头」：语音开始前有明显的哼声或轻笑杂音。
- 模型听到：Lo prendo.
- 转写模型听到：Mh, lo prendo.（和原文不同）

## 双辅音需人工听

这些句子含双辅音，长短要人去听（不计入可疑）：

- Ah, JoJo! Allora benvenuto a Roma. Buona visita! — Allora
- Alla fermata Colosseo. Da qui sono due fermate. — Alla, Colosseo
- Alla fermata Colosseo. Da qui sono sei fermate. — Alla, Colosseo
- Alla fermata Colosseo. Da qui sono tre fermate. — Alla, Colosseo
- C'è una fermata della metro qui vicino? — della
- Certo! Ecco fatto. Va bene così? — Ecco, fatto
- Dov'è l'ingresso? — ingresso
- Il Colosseo? Ci va a piedi? — Colosseo
- Il Colosseo? Ha una mappa sul telefono? — Colosseo, mappa
- L'ingresso? Giri a destra, è lì. — ingresso
- L'ingresso? Giri a sinistra, è lì. — ingresso
- L'ingresso? Vada sempre dritto, è lì. — ingresso, dritto
- Me lo può indicare sulla mappa? — sulla, mappa
- Permesso, scendo alla prossima. — Permesso, alla, prossima
- Posso fare una foto qui? — Posso
- Posso provarlo? — Posso
- Quale linea va al Colosseo? — Colosseo
- Quanto costa l'ingresso? — ingresso
- Scusi, dov'è il Colosseo? — Colosseo
- Sono diciotto euro, grazie. Ecco il biglietto. — diciotto, Ecco, biglietto
- Sono sedici euro, grazie. Ecco il biglietto. — Ecco, biglietto
- Sono ventiquattro euro, grazie. Ecco il biglietto. — ventiquattro, Ecco, biglietto
- Sì: prenda la prima a destra, poi all'incrocio giri a sinistra. La metro è lì. — all
- Sì: vada dritto fino al semaforo, poi giri a destra. La metro è lì. — dritto
- Sì: vada sempre dritto e prenda la seconda a sinistra. La metro è lì. — dritto
- Un biglietto intero, per favore. — biglietto
- Va bene! Sorrida… ecco fatto. Perché proprio qui? — Sorrida, ecco, fatto
- Va bene! Uno, due, tre… ecco fatto. Come mai proprio qui? — ecco, fatto
- Vada dritto fino all'incrocio, poi giri a destra. — dritto, all
- Vada sempre dritto. — dritto

## 统计

- 本周音频：232 段（原速 116，慢速 116）
- 已筛：232 段
- 可疑：23 段（原速 14，慢速 9）
- 含双辅音的句子：30 句
- token：输入 158,515，输出 27,950，思考 136,656
- 花费估算：232 次 × $0.004 ≈ $0.93（按实测单价；只重筛新片段时实际花费更少）
