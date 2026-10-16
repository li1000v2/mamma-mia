# 示范音频粗筛：第 5 周

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-week5.html](audio-screen-week5.html)（在仓库里用浏览器打开）。

## 可疑片段

### 1. Va bene. Prima chiami il 112, poi vada alla polizia. Ma lei sta bene?

- 声线 m1@1（Charon） · 慢速 · `23e970c1156fba7a.m4a`
- 问题：读错（严重度 medium，置信度 0.70）
- 理由：数字“112”被误读为“centro dodici”，不适合初学者。
  - 读错「112」：将“centododici”误读为“centro dodici”。
- 模型听到：Va bene. Prima chiami il centro dodici, poi vada alla polizia. Ma lei sta bene?
- 转写模型听到：Va bene. Prima chiami il centododici, poi vada alla polizia. Ma lei sta bene?（和原文不同）
- 双辅音需人工听：alla

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

- 本周音频：262 段（原速 131，慢速 131）
- 已筛：260 段，未筛 2 段
- 可疑：1 段（原速 0，慢速 1）
- 含双辅音的句子：36 句
- token：输入 181,397，输出 29,453，思考 149,633
- 花费估算：260 次 × $0.004 ≈ $1.04（按实测单价；只重筛新片段时实际花费更少）
