# 示范音频粗筛：出示卡

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-cards.html](audio-screen-cards.html)（在仓库里用浏览器打开）。

## 可疑片段

没有。

## 双辅音需人工听

这些句子含双辅音，长短要人去听（不计入可疑）：

- Arachidi e prodotti a base di arachidi — prodotti
- Crostacei e prodotti a base di crostacei — prodotti
- Frutta a guscio — Frutta
- Latte e prodotti a base di latte (incluso lattosio) — Latte, prodotti, latte, lattosio
- Lupini e prodotti a base di lupini — prodotti
- Molluschi e prodotti a base di molluschi — Molluschi, prodotti, molluschi
- Non posso mangiarli, neanche in piccole quantità. — posso, piccole
- Pesce e prodotti della pesca — prodotti, della
- Può avvisare il cuoco, per favore? — avvisare
- Sedano e prodotti a base di sedano — prodotti
- Semi di sesamo e prodotti a base di semi di sesamo — prodotti
- Senape e prodotti a base di senape — prodotti
- Soia e prodotti a base di soia — prodotti
- Sono allergico a questi alimenti: — allergico
- Uova e prodotti a base di uova — prodotti
- Vorrei andare a questo indirizzo. — Vorrei, indirizzo

## 统计

- 出示卡音频：40 段（原速 20，慢速 20）
- 已筛：40 段
- 可疑：0 段（原速 0，慢速 0）
- 含双辅音的句子：16 句
- token：输入 27,706，输出 4,135，思考 21,013
- 花费估算：40 次 × $0.004 ≈ $0.16（按实测单价；只重筛新片段时实际花费更少）
