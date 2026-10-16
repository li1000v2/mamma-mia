# 示范音频粗筛：第 1 周

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-week1.html](audio-screen-week1.html)（在仓库里用浏览器打开）。

## 可疑片段

没有。

## 双辅音需人工听

这些句子含双辅音，长短要人去听（不计入可疑）：

- Buongiorno! Allora, oggi abbiamo cornetti alla crema, al cioccolato e integrali: cosa le do? — Allora, oggi, abbiamo, cornetti, alla, cioccolato
- Certo, ecco. Grazie e buona giornata! — ecco
- Certo. Ecco lo scontrino. — Ecco
- Cornetti: crema, cioccolato o integrale? — Cornetti, cioccolato
- Dov'è la fermata del vaporetto? — vaporetto
- Due biglietti per Napoli, per favore. — biglietti
- Ecco lo scontrino. — Ecco
- Grazie mille! — mille
- Ho perso il biglietto. — biglietto
- Mamma mia! — Mamma
- Posso avere lo scontrino? — Posso
- Posso pagare con la carta? — Posso
- Prendo un cappuccino. — cappuccino
- Quanto costa un biglietto? — biglietto
- Sono cinque euro e sessanta. — sessanta
- Sono due euro e ottanta. — ottanta
- Un cappuccino e una brioche, per favore. — cappuccino
- Vorrei un caffè, per favore. — Vorrei, caffè
- biglietto — biglietto
- caffè — caffè
- gnocchi — gnocchi
- È una palla, non una pala. — palla

## 统计

- 本周音频：192 段（原速 96，慢速 96）
- 已筛：192 段
- 可疑：0 段（原速 0，慢速 0）
- 含双辅音的句子：22 句
- token：输入 126,268，输出 20,983，思考 102,603
- 花费估算：192 次 × $0.004 ≈ $0.77（按实测单价；只重筛新片段时实际花费更少）
