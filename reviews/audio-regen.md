# 示范音频重新生成

由 `tools/regen_audio.py` 生成，决定记在 `audio-regen-log.json`。处理过 117 条录音（一个声线说一句，原速和慢速一起判）；新版本复筛两次都干净才采用。

- 换成了新版本：73 条
- 保留现在的版本（复筛两次都干净，原来的标记是误报）：41 条
- 仍可疑（几个版本都不干净，留下最好的一版）：0 条
- 改为只用另一个声线（这条录音已删）：3 条

## 改为只用另一个声线

几个版本都读不对、另一个声线干净的句子，在 `tools/tts_voices.json` 的 `lineVoices` 里只留另一个声线。

### All'aeroporto di Fiumicino, per favore.

- 删掉的声线 m1@1（Charon） · 2026-10-16
- 现在的版本复筛：原速被标出（读错），慢速被标出（读错）
- 新版本 1：原速被标出（读错），慢速被标出（读错）
- 新版本 2：原速被标出（读错），慢速被标出（读错）
- 新版本 3：原速被标出（读错），慢速被标出（读错）
- 新版本 4：生成失败（服务按使用条款拒绝请求，HTTP 403）
- 都不干净，留下现在的版本
- 改为只用 Kore（lineVoices），删掉了这条录音

### Sì, prego, da questa parte. Ecco il menù.

- 删掉的声线 m1@1（Charon） · 2026-10-16
- 现在的版本复筛：原速被标出（重音），慢速被标出（读错）
- 新版本 1：原速被标出（重音），慢速干净
- 新版本 2：原速干净，慢速被标出（读错）
- 新版本 3：原速被标出（重音），慢速干净
- 新版本 4：原速被标出（重音），慢速被标出（重音）
- 都不干净，留下新版本 1

### caffè

- 删掉的声线 m1@1（Charon） · 2026-10-16
- 现在的版本复筛：原速被标出（读错、重音），慢速被标出（读错）
- 新版本 1：原速被标出（读错、重音），慢速被标出（读错、重音）
- 新版本 2：原速被标出（读错），慢速被标出（读错）
- 新版本 3：原速被标出（读错），慢速被标出（读错）
- 新版本 4：原速被标出（读错），慢速被标出（读错）
- 都不干净，留下现在的版本

## 换成了新版本

### A che ora apre?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `127612cd330faff5.m4a` · 慢速 `5643d585a70f8417.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### A che ora chiude il museo?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `975d9b2d7fdac27e.m4a` · 慢速 `2d33feb46d176731.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Ah, JoJo! Qui ne vengono tanti. Buona visita!

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `611656146f43d74e.m4a` · 慢速 `8d187e32712de9df.m4a`
- 现在的版本复筛：原速被标出（重音），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Allora le do qualcosa per il mal di testa. Sono sei euro e trenta.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `8977b69cef75f08d.m4a` · 慢速 `133736d9d3f0b7ff.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速被标出（漏读）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Allora le do qualcosa per il mal di testa. Sono sei euro e trenta.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `7180a1e0c8237425.m4a` · 慢速 `7ca5e6d24e9563f2.m4a`
- 现在的版本复筛：原速干净，慢速被标出（重音）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Allora, cosa le porto?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `363df4f631fb050d.m4a` · 慢速 `f07739f1cea83d87.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错、语调节奏）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Andata e ritorno o solo andata?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `6a6311cc7c7c7656.m4a` · 慢速 `f5ed306bfe3d66c9.m4a`
- 现在的版本复筛：原速被标出（重音），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速被标出（读错）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Attenzione! Il treno per Napoli Centrale partirà dal binario tredici anziché dal binario tre.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `0f1ed593dabb0cc9.m4a` · 慢速 `9d42df45136259d6.m4a`
- 现在的版本复筛：原速被标出（读错），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Buonasera!

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `f3466088e9ea5b44.m4a` · 慢速 `94d5e58a807d7bcd.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Buonasera, benvenuto!

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `12fa12e69ac78399.m4a` · 慢速 `cf00462ffe58d699.m4a`
- 现在的版本复筛：原速被标出（读错、截断），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Buonasera, dove andiamo?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `73d75e8b85d42dc8.m4a` · 慢速 `1067636a9ae14764.m4a`
- 现在的版本复筛：原速干净，慢速被标出（截断）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Buone feste!

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `910a4e681f407f34.m4a` · 慢速 `2aa0ff15824163b4.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速被标出（截断），慢速干净
- 新版本 1：原速干净，慢速被标出（放慢失真）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Buongiorno! Mi dica.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `6536a383d9365848.m4a` · 慢速 `3eed0553a758803b.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错、放慢失真）
- 新版本 1：原速干净，慢速被标出（读错）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Buongiorno! Posso aiutarla?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `2bb5a90f1d676636.m4a` · 慢速 `dfa5c5988f16f080.m4a`
- 现在的版本复筛：原速被标出（截断），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Buongiorno! Prego, dica.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `ac588818307b904b.m4a` · 慢速 `2ffd15e126718a7f.m4a`
- 现在的版本复筛：原速被标出（截断），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Buongiorno, biglietto, prego.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `2402c9ea3d43512c.m4a` · 慢速 `9dccced12945a503.m4a`
- 现在的版本复筛：原速被标出（截断），慢速干净
- 新版本 1：原速被标出（读错），慢速被标出（读错）
- 新版本 2：原速被标出（截断），慢速干净
- 新版本 3：原速干净，慢速干净；原速干净，慢速干净

### Cerca il Colosseo? Prenda la metro B, direzione Laurentina: sono quattro fermate.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `64c31abb9a4f2dc9.m4a` · 慢速 `3ae2bee28bf246ef.m4a`
- 现在的版本复筛：原速干净，慢速被标出（放慢失真）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Cerca il Colosseo? Prenda la metro B, direzione Laurentina: sono tre fermate.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `fa42d65f486e955b.m4a` · 慢速 `ee86a4b3550c3237.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速被标出（读错），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Certo! Dove devo premere?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `72bf158dcb0f880d.m4a` · 慢速 `955b47306d61870e.m4a`
- 现在的版本复筛：原速被标出（多出来的话），慢速被标出（多出来的话）
- 新版本 1：原速被标出（重音），慢速被标出（重音）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Certo! Ecco fatto. Va bene così?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `e38dded37c8d3973.m4a` · 慢速 `20bd76ce5e71b3c5.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速被标出（杂音）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Certo, ecco. Grazie e buona giornata!

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `0a4b7176a2d6b969.m4a` · 慢速 `2eeba756b05ac40e.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Che giorno è oggi?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `9f3aa45a4d86e6f1.m4a` · 慢速 `d78580195319fe34.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Chiuso il lunedì.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `deca6797517ea273.m4a` · 慢速 `36f61b4fa662ebae.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速被标出（重音），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Chiuso il lunedì.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `6d47455342f53f27.m4a` · 慢速 `afbfdd974eec3ea4.m4a`
- 现在的版本复筛：原速被标出（重音），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Ci sono ancora posti liberi?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `4979c0733346e8e3.m4a` · 慢速 `b5e4b72b89c24792.m4a`
- 现在的版本复筛：原速被标出（截断），慢速干净
- 新版本 1：原速被标出（截断），慢速被标出（截断）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Dal binario tre. Ecco il biglietto: carrozza dodici, posto sette.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `a4e1edab992ab44a.m4a` · 慢速 `4a1762582f4314bc.m4a`
- 现在的版本复筛：原速干净，慢速被标出（杂音）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Di dov'è?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `9adc61f23b8df103.m4a` · 慢速 `8812235e67dd2fc3.m4a`
- 现在的版本复筛：原速干净，慢速被标出（重音）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Dieci minuti, più o meno.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `a9cb30b26823f231.m4a` · 慢速 `00010eab351fed62.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速被标出（漏读），慢速干净
- 新版本 1：原速被标出（截断），慢速干净
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Dov'è la polizia?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `73937f181ad14f0e.m4a` · 慢速 `f75d5fb54179e5b6.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Dove devo scendere?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `cedabe2ff9eb8e58.m4a` · 慢速 `f3a90493dfcdd4c3.m4a`
- 现在的版本复筛：原速干净，慢速被标出（截断）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Dove devo scendere?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `ef9110cc3f133c6c.m4a` · 慢速 `8cd456f5debcef93.m4a`
- 现在的版本复筛：原速被标出（重音），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### E da bere?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `d1b5a970475eccf5.m4a` · 慢速 `a444b4793a6de5b5.m4a`
- 现在的版本复筛：原速干净，慢速被标出（漏读）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Ecco a lei, e buone feste!

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `2d3fc9aaa6b884e7.m4a` · 慢速 `29da035986fe4f81.m4a`
- 现在的版本复筛：原速被标出（截断），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Ecco a lei, e buone feste!

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `37fb83635e62c5e4.m4a` · 慢速 `c98a3e52f7460bc0.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Ecco qua, per il mal di testa. Sono nove euro e sessanta.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `5c8dc59b3de8ad2b.m4a` · 慢速 `24d541041b17ae95.m4a`
- 现在的版本复筛：原速被标出（读错），慢速被标出（语调节奏、放慢失真）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Ho perso il biglietto.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `810fe363eed78c08.m4a` · 慢速 `33e66e11b7ae3e01.m4a`
- 现在的版本复筛：原速被标出（读错），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速被标出（漏读）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Ho perso il treno. A che ora parte il prossimo per Roma?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `a14e96f7e3f3c4f4.m4a` · 慢速 `78e3a114bd8c4bfb.m4a`
- 现在的版本复筛：原速被标出（杂音），慢速干净
- 新版本 1：原速被标出（语调节奏），慢速被标出（语调节奏）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Ho prenotato una camera a nome di…

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `a0987113b2cf0708.m4a` · 慢速 `08f96620dbf485da.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Il menù, per favore.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `857879aef45e88a5.m4a` · 慢速 `3e575fe9269f7225.m4a`
- 现在的版本复筛：原速被标出（读错、语调节奏），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### L'ingresso? Giri a destra, è lì.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `2089989109dba405.m4a` · 慢速 `7439883bcf02d7e4.m4a`
- 现在的版本复筛：原速被标出（截断），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速被标出（其他）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### L'ingresso? Giri a destra, è lì.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `ee151c4278d22b93.m4a` · 慢速 `ca3a2a3d076c937f.m4a`
- 现在的版本复筛：原速被标出（截断），慢速被标出（重音）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Lo prendo.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `4e2ce327734aa8f3.m4a` · 慢速 `b49e346a2f4b1c2a.m4a`
- 现在的版本复筛：原速被标出（杂音），慢速被标出（多出来的话）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Mamma mia!

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `0dea86fb2b85f4f2.m4a` · 慢速 `187c359c5e8b73b7.m4a`
- 现在的版本复筛：原速干净，慢速被标出（放慢失真）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Me lo può scrivere?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `ae2086d63c2bd9c7.m4a` · 慢速 `217be0b9eb085f58.m4a`
- 现在的版本复筛：原速被标出（读错），慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速被标出（读错），慢速干净
- 新版本 2：原速干净，慢速被标出（读错）
- 新版本 3：原速干净，慢速干净；原速干净，慢速干净

### Mi può fare la ricevuta?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `c5988e4cbae11cdb.m4a` · 慢速 `66b7a837b3c72088.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Napoli

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `2e359c62aa64127a.m4a` · 慢速 `f62e6cd8b6f4f64f.m4a`
- 现在的版本复筛：原速被标出（读错），慢速被标出（读错）
- 新版本 1：原速被标出（读错），慢速干净
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Oggi chiudiamo alle diciannove e trenta.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `f5d778e5920a3718.m4a` · 慢速 `16559a06fd2b2fc0.m4a`
- 现在的版本复筛：原速被标出（漏读），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Oggi chiudiamo alle diciotto.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `a513ddbdeeb3d750.m4a` · 慢速 `f9da519cf1b10342.m4a`
- 现在的版本复筛：原速被标出（截断），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Oggi chiudiamo alle ventuno.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `76186825d5658523.m4a` · 慢速 `b6617f6bdf03367c.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速被标出（截断）
- 新版本 1：原速被标出（截断），慢速干净
- 新版本 2：原速被标出（读错、截断），慢速干净
- 新版本 3：原速干净，慢速干净；原速干净，慢速干净

### Oggi è lunedì.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `89d82110f64a299b.m4a` · 慢速 `2ec0e8d3ba8620db.m4a`
- 现在的版本复筛：原速干净，慢速被标出（重音）
- 新版本 1：原速被标出（重音），慢速干净
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Perfetto, grazie. C'è anche la tassa di soggiorno: sono dodici euro in tutto. Contanti o carta?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `2bbf4ea4edb7a903.m4a` · 慢速 `43d5a8616601ff7c.m4a`
- 现在的版本复筛：原速没筛成，慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Posso pagare con la carta?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `3deae421f12d12c5.m4a` · 慢速 `80fca5122596ab04.m4a`
- 现在的版本复筛：原速被标出（多出来的话），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Quanto costa fino all'aeroporto?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `f94d51e6071a687f.m4a` · 慢速 `b4d6227c3e7eccb2.m4a`
- 现在的版本复筛：原速被标出（读错），慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速被标出（漏读）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Quanto costa fino all'aeroporto?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `fe156072f56ebf2e.m4a` · 慢速 `0c105d1a6a17930d.m4a`
- 现在的版本复筛：原速被标出（读错），慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Scusi, è libero questo posto?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `94757d474122d53b.m4a` · 慢速 `b7ab11442f0f9cd2.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速被标出（语调节奏），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Scusi.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `a53cfd927047f816.m4a` · 慢速 `6d2d47712f0301f3.m4a`
- 现在的版本复筛：原速被标出（杂音），慢速被标出（杂音、重音）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Serve la prenotazione?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `08425edc6ba92927.m4a` · 慢速 `4594999d87862fea.m4a`
- 现在的版本复筛：原速被标出（重音），慢速被标出（重音）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Sono sedici euro, grazie. Ecco il biglietto.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `bc7a1d9b105d31e1.m4a` · 慢速 `9e4f88b5bf693f11.m4a`
- 现在的版本复筛：原速被标出（读错），慢速干净
- 新版本 1：原速被标出（读错），慢速被标出（读错）
- 新版本 2：原速干净，慢速干净；原速被标出（截断），慢速干净
- 新版本 3：原速干净，慢速干净；原速干净，慢速干净

### Sono un euro e venti.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `0e48ebe7a8c71195.m4a` · 慢速 `09f066e947c82a2a.m4a`
- 现在的版本复筛：原速被标出（截断），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Sono un fan di JoJo.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `e64c7b25453116be.m4a` · 慢速 `2bd2b8f1028a4af2.m4a`
- 现在的版本复筛：原速被标出（读错），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Sono un po' stanco.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `8f77ba72762929c7.m4a` · 慢速 `23cfc836b616fec4.m4a`
- 现在的版本复筛：原速被标出（杂音），慢速干净
- 新版本 1：原速干净，慢速被标出（放慢失真）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Stasera le sarde in saor sono buonissime. Ha qualche allergia?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `3bdb07d6ce69a7ac.m4a` · 慢速 `753fecc4a3dcf24b.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速被标出（重音），慢速被标出（重音）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Un euro e trenta, grazie.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `c0984323ce97b83a.m4a` · 慢速 `55b12f70d6068db1.m4a`
- 现在的版本复筛：原速被标出（截断），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Una margherita, per favore.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `f5389980e96ac37e.m4a` · 慢速 `6b96ed202589dccd.m4a`
- 现在的版本复筛：原速被标出（读错），慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Va bene! Sorrida… ecco fatto. Perché proprio qui?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `ade0afef95cc89dd.m4a` · 慢速 `1a04265532f09de7.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错、语调节奏）
- 新版本 1：原速干净，慢速干净；原速干净，慢速被标出（多出来的话）
- 新版本 2：原速被标出（其他、截断），慢速被标出（其他）
- 新版本 3：原速被标出（读错），慢速被标出（读错）
- 新版本 4：原速干净，慢速干净；原速干净，慢速干净

### Va bene, allora niente crostacei. Da bere, un bicchiere di vino?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `d4f1946086786710.m4a` · 慢速 `1653ff1079a318b7.m4a`
- 现在的版本复筛：原速被标出（读错），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Va bene, allora niente crostacei. Da bere, un bicchiere di vino?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `c9a2cb0ae6bb1282.m4a` · 慢速 `339848ccc215b50f.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### Va bene. Prima chiami il 112, poi vada alla polizia. Ma lei sta bene?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `ae07758cce271e1d.m4a` · 慢速 `23e970c1156fba7a.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速被标出（读错）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### Vuole anche qualcosa da bere?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `1dcdef607b77d4f7.m4a` · 慢速 `b58e64661a15a220.m4a`
- 现在的版本复筛：原速干净，慢速被标出（重音）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### biglietto

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `42950c0514e42b03.m4a` · 慢速 `e997ccf45977906d.m4a`
- 现在的版本复筛：原速干净，慢速被标出（读错）
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### caffè

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `d9890204c1d54ddf.m4a` · 慢速 `b6f9a4f718d95cdc.m4a`
- 现在的版本复筛：原速被标出（读错），慢速被标出（读错）
- 新版本 1：原速被标出（读错），慢速被标出（读错）
- 新版本 2：原速干净，慢速干净；原速干净，慢速干净

### chiesa

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `b057c1e297e53cdf.m4a` · 慢速 `f171b921b1730fc2.m4a`
- 现在的版本复筛：原速被标出（读错），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

### È aperto anche oggi?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `eff9efe98e704ac9.m4a` · 慢速 `7d1a75271bab7eb3.m4a`
- 现在的版本复筛：原速被标出（漏读），慢速干净
- 新版本 1：原速干净，慢速干净；原速干净，慢速干净

## 保留现在的版本

### A che ora chiude oggi?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `2b279185c4da2583.m4a` · 慢速 `70bbd66671a58acf.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Ah, JoJo! Allora benvenuto a Roma. Buona visita!

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `939e7b0689638d43.m4a` · 慢速 `0474769e4e14f470.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Aiuto!

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `c319c7b623a97d1f.m4a` · 慢速 `e46c3e50a84267a9.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Allora, cosa le porto?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `a628346a9befebb4.m4a` · 慢速 `db5c342de7a11677.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Altro?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `6da90f9588b90d3c.m4a` · 慢速 `1bf60bdd1be03acd.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Attenzione! Il treno per Napoli Centrale partirà dal binario cinque anziché dal binario tre.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `4a90e1cf51acd42d.m4a` · 慢速 `4cea08ea0ccdc6a0.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Buonasera e benvenuto! Ha una prenotazione?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `27788d85e541647b.m4a` · 慢速 `cedec9759f3c67ea.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Buonasera! Desidera?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `c8553d7bba9d5774.m4a` · 慢速 `5ed1e9580cd43eb8.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Buonasera! Dove la porto?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `5d853b2511678c2c.m4a` · 慢速 `ad96cd78f61d4b4c.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Buonasera, dove andiamo?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `3b08fe9825aa530a.m4a` · 慢速 `919ed2f0cfa8dc9a.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Ciao!

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `45e16d8ff2404408.m4a` · 慢速 `73c44d925efb17f8.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Circa venti minuti: oggi c'è tanta gente!

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `8dbbcfb6ab7a1832.m4a` · 慢速 `1d81810594af2176.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Devo validare il biglietto?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `baa34889be56ccca.m4a` · 慢速 `6c091b27dc9949d5.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Dieci minuti, più o meno.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `e93f1db29f27baaa.m4a` · 慢速 `68f68d4cd7a7a1a6.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Ecco lo scontrino.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `b498e8d8f4b26e4c.m4a` · 慢速 `5ea3ee52923d2762.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Ho fame. C'è una pizzeria qui vicino?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `76d91a1a3c8ff857.m4a` · 慢速 `a0bb47825566ed55.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Il treno partirà dal binario cinque anziché dal binario tre.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `d2b9bf841ca58abb.m4a` · 慢速 `6e8f6bcf5619c547.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### L'ingresso? Giri a sinistra, è lì.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `17d7486efe7d9f7b.m4a` · 慢速 `ca9367f7584c95fa.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### L'ingresso? Vada sempre dritto, è lì.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `18a560ea17edba35.m4a` · 慢速 `7e4414bca104da5e.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Me lo può scrivere?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `415bed1d7ba2d0b1.m4a` · 慢速 `1dcc1e036b2a4e39.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Mi dispiace! Anche il passaporto?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `a4223edf4f9c12f7.m4a` · 慢速 `8092042031e2e8d7.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Mi può chiamare un taxi?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `e343ec031601fb4d.m4a` · 慢速 `0300926b1ea7fb12.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Paga in contanti o con la carta?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `006a926e09d16f93.m4a` · 慢速 `21ba8fe5bc11e23c.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Perfetto, grazie. C'è anche la tassa di soggiorno: sono dodici euro in tutto. Contanti o carta?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `0c7c96b928bb5f7c.m4a` · 慢速 `028b2902f4f13cc0.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Perfetto, grazie. C'è anche la tassa di soggiorno: sono quindici euro in tutto. Contanti o carta?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `6825927206359580.m4a` · 慢速 `da3eb550ec419035.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Perfetto, grazie. C'è anche la tassa di soggiorno: sono quindici euro in tutto. Contanti o carta?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `0b903f79d327751c.m4a` · 慢速 `13e40a6a072c1eb0.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Perfetto, grazie. C'è anche la tassa di soggiorno: sono sedici euro in tutto. Contanti o carta?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `7d0e5b621f4db9b0.m4a` · 慢速 `de461cb913c46abc.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Perfetto, grazie. C'è anche la tassa di soggiorno: sono sedici euro in tutto. Contanti o carta?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `4ee58e31dfb8b684.m4a` · 慢速 `8521ff94bbface9f.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Quant'è?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `8d85ffc594058351.m4a` · 慢速 `4a827745fcea8b70.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Quanto costa questo ombrello? Va bene, lo prendo.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `f43d7f2a3c4fd29d.m4a` · 慢速 `2a0ca6e9d5b7dd1d.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Si può andare a piedi?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `e0b1a38451e59c1c.m4a` · 慢速 `d13e3c1ba99aa1be.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Solo andata o andata e ritorno?

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `f5a6ea71f8d5d2af.m4a` · 慢速 `3fa257d2d5b42527.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Sono da solo. Avete un tavolo libero?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `e8adb1c5a8af8df4.m4a` · 慢速 `511b7ea560342d89.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Sì, certo. La polizia però è un po' lontana: in taxi sono venti minuti.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `1c7ed9a7b848fec3.m4a` · 慢速 `962d8ae34cebc270.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Sì: prenda la prima a destra, poi all'incrocio giri a sinistra. La metro è lì.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `64e27bfc74235fb2.m4a` · 慢速 `5406079a3a8f90c3.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Tutto bene? Desidera un dolce o un caffè?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `991f59d55538ef4d.m4a` · 慢速 `02e37bc2dc9dabd3.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Un cappuccino e una brioche, per favore.

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `145087e271565e7f.m4a` · 慢速 `701c00a0780f9434.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Un'acqua naturale, per favore.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `b2028a01dcb7ee60.m4a` · 慢速 `692263bad120c543.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Una margherita, per favore.

- 声线 m1@1（Charon） · 2026-10-16 · 原速 `8a130810f19a2601.m4a` · 慢速 `5374250437ff4623.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### Va bene, allora niente crostacei. Da bere? Acqua naturale o frizzante?

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `97640039565c110a.m4a` · 慢速 `018e9c26dbb0e9e2.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净

### uscita

- 声线 f1@1（Kore） · 2026-10-16 · 原速 `262267f686613e95.m4a` · 慢速 `a0e179f9176ca5cf.m4a`
- 现在的版本复筛：原速干净，慢速干净；原速干净，慢速干净
