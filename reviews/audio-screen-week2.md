# 示范音频粗筛：第 2 周

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-week2.html](audio-screen-week2.html)（在仓库里用浏览器打开）。

## 可疑片段

没有。

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

- 本周音频：234 段（原速 117，慢速 117）
- 已筛：234 段
- 可疑：0 段（原速 0，慢速 0）
- 含双辅音的句子：32 句
- token：输入 160,762，输出 27,196，思考 134,847
- 花费估算：234 次 × $0.004 ≈ $0.94（按实测单价；只重筛新片段时实际花费更少）
