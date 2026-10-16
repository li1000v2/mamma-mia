# 示范音频粗筛：第 4 周

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-week4.html](audio-screen-week4.html)（在仓库里用浏览器打开）。

## 可疑片段

没有。

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
- 可疑：0 段（原速 0，慢速 0）
- 含双辅音的句子：30 句
- token：输入 158,619，输出 26,538，思考 129,549
- 花费估算：232 次 × $0.004 ≈ $0.93（按实测单价；只重筛新片段时实际花费更少）
