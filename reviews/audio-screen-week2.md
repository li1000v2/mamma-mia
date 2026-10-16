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

### 3. Sì, prego, da questa parte. Ecco il menù.

- 声线 m1@1（Charon） · 慢速 · `e1ec1ebe16f64c84.m4a`
- 问题：重音（严重度 medium，置信度 0.75）
- 理由：末尾单词“menù”重音位置有误，其余发音清晰。
  - 重音「menù」：重音错误地放在了第一音节而非末音节。
- 模型听到：Sì, prego, da questa parte. Ecco il menu.
- 转写模型听到：Sì, prego, da questa parte. Ecco il menu.（和原文一致）
- 双辅音需人工听：Ecco

### 4. Sì, prego, da questa parte. Ecco il menù.

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
- 可疑：4 段（原速 2，慢速 2）
- 含双辅音的句子：32 句
- token：输入 161,327，输出 27,428，思考 136,109
- 花费估算：235 次 × $0.004 ≈ $0.94（按实测单价；只重筛新片段时实际花费更少）
