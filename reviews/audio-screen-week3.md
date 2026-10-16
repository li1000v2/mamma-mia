# 示范音频粗筛：第 3 周

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-week3.html](audio-screen-week3.html)（在仓库里用浏览器打开）。

## 可疑片段

没有。

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
- 可疑：0 段（原速 0，慢速 0）
- 含双辅音的句子：31 句
- token：输入 163,790，输出 27,378，思考 134,189
- 花费估算：236 次 × $0.004 ≈ $0.94（按实测单价；只重筛新片段时实际花费更少）
