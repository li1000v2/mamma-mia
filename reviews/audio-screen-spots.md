# 示范音频粗筛：巡礼点

由 `tools/audio_review.py` 生成。模型 `gemini-4-argon`（thinkingLevel HIGH）听每段音频并对照原文，只列出它认为有问题的片段；这些需要人去听。双辅音长短模型判断不了，不作为可疑理由，含双辅音的句子统一备注“双辅音需人工听”。

逐条点听：[audio-screen-spots.html](audio-screen-spots.html)（在仓库里用浏览器打开）。

## 可疑片段

没有。

## 双辅音需人工听

这些句子含双辅音，长短要人去听（不计入可疑）：

- Chiesa di San Giorgio Maggiore — Maggiore
- Collina di Posillipo — Collina, Posillipo
- Colosseo — Colosseo
- Come si arriva al Parco Virgiliano? — arriva
- Dov'è la fermata dell'autobus per il centro? — dell

## 统计

- 巡礼点音频：26 段（原速 13，慢速 13）
- 已筛：26 段
- 可疑：0 段（原速 0，慢速 0）
- 含双辅音的句子：5 句
- token：输入 17,555，输出 3,022，思考 16,319
- 花费估算：26 次 × $0.004 ≈ $0.10（按实测单价；只重筛新片段时实际花费更少）
