# 示范音频粗筛：第 2 周

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-week2.html](audio-screen-week2.html)（在仓库里用浏览器打开）。

## 可疑片段

### 1. Un'acqua naturale, per favore.

- 声线 m1@1（Charon） · 原速 · `b2028a01dcb7ee60.m4a`
- 问题：读错（严重度 high，置信度 0.95）
- 理由：“Un'acqua”受撇号影响被TTS错误切分，导致重音位置和连读发音明显错误。
  - 读错「Un'acqua」：将本应连读的“Un'acqua”错误拆读成了“Una”和“qua”两个部分，且重音错误地落在了首音节上。
- 模型听到：Una qua naturale, per favore.
- 转写模型听到：Un'acqua naturale, per favore.（和原文一致）
- 双辅音需人工听：acqua

### 2. Va bene, allora niente crostacei. Da bere, un bicchiere di vino?

- 声线 m1@1（Charon） · 慢速 · `339848ccc215b50f.m4a`
- 问题：读错（严重度 medium，置信度 0.90）
- 理由：“Da bere”中的“b”发音不准确，听起来像“v”（Da vere），可能会误导初学者。
  - 读错「Da bere」：“bere”中的辅音 b 发音近似于 v，听起来像“Da vere”。
- 模型听到：Va bene, allora niente crostacei. Da vere, un bicchiere di vino?
- 转写模型听到：Va bene. Allora niente crostacei. Da bere? Un bicchiere di vino?（和原文一致）
- 双辅音需人工听：allora, bicchiere

### 3. Va bene, allora niente crostacei. Da bere, un bicchiere di vino?

- 声线 f1@1（Kore） · 原速 · `d4f1946086786710.m4a`
- 问题：读错（严重度 medium，置信度 0.75）
- 理由：单词“bicchiere”中的元音发音错误，被读成了“bicchiare”。
  - 读错「bicchiere」：将“bicchiere”误读为“bicchiare”。
- 模型听到：Va bene, allora niente crostacei. Da bere, un bicchiare di vino?
- 转写模型听到：Va bene, allora niente crostacei. Da bere, un bicchiere di vino?（和原文一致）
- 双辅音需人工听：allora, bicchiere

### 4. A che ora apre?

- 声线 f1@1（Kore） · 慢速 · `5643d585a70f8417.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：“che ora”发音不清晰且重音异常，不适合初学者。
  - 读错「che ora」：“che ora”元音发音含糊且重音错置，听起来像“chiura”。
- 模型听到：A chiora apre?
- 转写模型听到：A che ora apre?（和原文一致）

### 5. Buonasera e benvenuto! Ha una prenotazione?

- 声线 m1@1（Charon） · 原速 · `27788d85e541647b.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：连词“e”发音不准确，读成了“ei”，其余部分发音自然。
  - 读错「e」：连词“e”被误读为双元音“ei”。
- 模型听到：Buonasera ei benvenuto! Ha una prenotazione?
- 转写模型听到：Buonasera e benvenuto. Ha una prenotazione?（和原文一致）

### 6. Buonasera, benvenuto!

- 声线 f1@1（Kore） · 原速 · `12fa12e69ac78399.m4a`
- 问题：读错、截断（严重度 medium，置信度 0.70）
- 理由：首词元音发音错误，且音频结尾有轻微截断。
  - 读错「Buonasera」：元音发音有误，听起来像Buonasiera。
  - 截断「benvenuto」：词尾的o有轻微截断。
- 模型听到：Buonasiera, benvenuto
- 转写模型听到：Buonasera, benvenuto.（和原文一致）

### 7. Devo validare il biglietto?

- 声线 f1@1（Kore） · 原速 · `baa34889be56ccca.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：“biglietto”中的辅音组合“gli”发音不准确，读成了“li”。
  - 读错「biglietto」：将“gli”错误发音为普通的“li”音。
- 模型听到：Devo validare il bilietto?
- 转写模型听到：Devo validare il biglietto?（和原文一致）
- 双辅音需人工听：biglietto

### 8. Ho prenotato una camera a nome di…

- 声线 m1@1（Charon） · 原速 · `a0987113b2cf0708.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：单词“nome”的元音发音有误，听起来像“nume”。
  - 读错「nome」：“nome”被误读为“nume”。
- 模型听到：Ho prenotato una camera a nume di
- 转写模型听到：Ho prenotato una camera a nome di（和原文一致）

### 9. Buongiorno! Posso aiutarla?

- 声线 f1@1（Kore） · 原速 · `2bb5a90f1d676636.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：首词开头被截断，缺少B音。
  - 截断「Buongiorno」：词首辅音B缺失，听起来像Uongiorno。
- 模型听到：Uongiorno! Posso aiutarla?
- 转写模型听到：Buongiorno, posso aiutarla?（和原文一致）
- 双辅音需人工听：Posso

### 10. Tutto bene? Desidera un dolce o un caffè?

- 声线 f1@1（Kore） · 慢速 · `02e37bc2dc9dabd3.m4a`
- 问题：截断（严重度 medium，置信度 0.70）
- 理由：整体发音清晰，但音频末尾“caffè”的元音收尾过于突兀，存在轻微截断。
  - 截断「caffè」：句末单词“caffè”的尾音被轻微截断。
- 模型听到：Tutto bene? Desidera un dolce o un caffè
- 转写模型听到：Tutto bene? Desidera un dolce o un caffè?（和原文一致）
- 双辅音需人工听：Tutto, caffè

### 11. Il menù, per favore.

- 声线 f1@1（Kore） · 慢速 · `3e575fe9269f7225.m4a`
- 问题：重音（严重度 medium，置信度 0.95）
- 理由：单词 menù 的重音位置错误，重读了第一个音节而非带重音符号的最后一个音节。
  - 重音「menù」：单词 menù 带有重音符号，重音应落在最后一个音节（me-NÙ），但音频中重读了第一个音节（ME-nu）。
- 模型听到：Il menu, per favore.
- 转写模型听到：Il menu, per favore.（和原文一致）

### 12. Va bene, allora niente crostacei. Da bere? Acqua naturale o frizzante?

- 声线 f1@1（Kore） · 慢速 · `018e9c26dbb0e9e2.m4a`
- 问题：重音（严重度 medium，置信度 0.85）
- 理由：整体文本完整清晰，但常用词“allora”出现了明显的重音错位，可能会误导初学者。
  - 重音「allora」：“allora”的重音错误地落在了第一个音节上，听起来像“àllora”，正确重音应在第二个音节“allóra”。
- 模型听到：Va bene, allora niente crostacei. Da bere? Acqua naturale o frizzante?
- 转写模型听到：Va bene, allora niente crostacei. Da bere? Acqua naturale o frizzante?（和原文一致）
- 双辅音需人工听：allora, Acqua, frizzante

### 13. Sì, prego, da questa parte. Ecco il menù.

- 声线 m1@1（Charon） · 慢速 · `e1ec1ebe16f64c84.m4a`
- 问题：重音（严重度 medium，置信度 0.75）
- 理由：末尾单词“menù”重音位置有误，其余发音清晰。
  - 重音「menù」：重音错误地放在了第一音节而非末音节。
- 模型听到：Sì, prego, da questa parte. Ecco il menu.
- 转写模型听到：Sì, prego, da questa parte. Ecco il menu.（和原文一致）
- 双辅音需人工听：Ecco

### 14. Stasera le sarde in saor sono buonissime. Ha qualche allergia?

- 声线 f1@1（Kore） · 原速 · `3bdb07d6ce69a7ac.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：“saor”的重音位置有误，其余部分发音自然流畅。
  - 重音「saor」：重音错误地落在了第一个音节（sà-or），正确发音重音应在尾音节（sa-ór）。
- 模型听到：Stasera le sarde in saor sono buonissime. Ha qualche allergia?
- 转写模型听到：Stasera le sarde in saor sono buonissime. Ha qualche allergia?（和原文一致）
- 双辅音需人工听：buonissime, allergia

### 15. Sì, prego, da questa parte. Ecco il menù.

- 声线 m1@1（Charon） · 原速 · `c037de3950ead8f0.m4a`
- 问题：重音（严重度 medium，置信度 0.70）
- 理由：“menù”一词重音位置错误，不符合带重音符号的标准意大利语发音。
  - 重音「menù」：重音错误地落在了第一音节（读成了 ME-nu），而不是带重音符号的尾音节（me-NÙ）。
- 模型听到：Sì, prego da questa parte. Ecco il menu.
- 转写模型听到：Sì, prego, da questa parte. Ecco il menu.（和原文一致）
- 双辅音需人工听：Ecco

## 双辅音需人工听

这些句子含双辅音，长短要人去听（不计入可疑）：

- Alle quindici e trenta. — Alle
- Allora, tutto bene? Un dolce, un caffè? — Allora, tutto, caffè
- Buongiorno! Posso aiutarla? — Posso
- Certo, si accomodi. Ecco il menù. — accomodi, Ecco
- Devo validare il biglietto? — biglietto
- Dov'è la fermata del vaporetto? — vaporetto
- Dove posso comprare il biglietto? — posso, biglietto
- Ecco a lei: trentasei euro, con il coperto. — Ecco
- Ecco il conto: sono ventotto euro, coperto compreso. — Ecco, ventotto
- Il passaporto, per favore. — passaporto
- Le consiglio gli spaghetti alle vongole. Ha allergie? — spaghetti, alle, allergie
- Le consiglio il risotto al nero di seppia, è tipico di Venezia. Ha allergie o intolleranze? — risotto, seppia, allergie, intolleranze
- No, oggi è chiuso. — oggi
- Per Rialto, la linea uno. E sì, il biglietto si valida prima di salire. — biglietto
- Perfetto, grazie. C'è anche la tassa di soggiorno: sono dodici euro in tutto. Contanti o carta? — Perfetto, tassa, soggiorno, tutto
- Perfetto, grazie. C'è anche la tassa di soggiorno: sono quindici euro in tutto. Contanti o carta? — Perfetto, tassa, soggiorno, tutto
- Perfetto, grazie. C'è anche la tassa di soggiorno: sono sedici euro in tutto. Contanti o carta? — Perfetto, tassa, soggiorno, tutto
- Posso lasciare i bagagli? — Posso
- Prenda la linea due. E il biglietto lo deve validare prima di salire. — biglietto
- Quant'è la tassa di soggiorno? — tassa, soggiorno
- Quanto costa il vaporetto? — vaporetto
- Questo vaporetto va a Rialto? — vaporetto
- Senza formaggio, per favore. — formaggio
- Sono allergico ai crostacei. — allergico
- Stasera le sarde in saor sono buonissime. Ha qualche allergia? — buonissime, allergia
- Sì, prego, da questa parte. Ecco il menù. — Ecco
- Tutto bene? Desidera un dolce o un caffè? — Tutto, caffè
- Un biglietto, per favore. — biglietto
- Un'acqua naturale, per favore. — acqua
- Va bene, allora niente crostacei. Da bere, un bicchiere di vino? — allora, bicchiere
- Va bene, allora niente crostacei. Da bere? Acqua naturale o frizzante? — allora, Acqua, frizzante
- È aperto oggi? — oggi

## 统计

- 本周音频：236 段（原速 118，慢速 118）
- 已筛：235 段，未筛 1 段
- 可疑：15 段（原速 9，慢速 6）
- 含双辅音的句子：32 句
- token：输入 161,157，输出 28,271，思考 140,995
- 花费估算：235 次 × $0.004 ≈ $0.94（按实测单价；只重筛新片段时实际花费更少）
