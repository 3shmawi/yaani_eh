# Brand video

A 62.5 s vertical motion video (1080×1920, 30 fps, with music) that walks through
every feature of «يعني إيه؟» in Egyptian Arabic. It is made in code, from the app's
own tokens (`app_colors.dart`), fonts (`assets/fonts`) and mark
(`assets/branding/splash.png`, cropped to `mark.png`), so it can be rendered again
whenever the app changes.

| Time | Scene | Feature |
|---|---|---|
| 0–5 s | «قريت اسم في المنيو... ومفهمتش هو إيه؟» | the hook: a menu nobody understands |
| 5–10 s | the mark, «يعني إيه؟ — أي حاجة... بس مفهومة» | brand |
| 10–17.5 s | Caramel Frappé → Flat White, the «يعني» line typing | item details / explanations |
| 17.5–25 s | Affogato, syllables + waveform, «زي الباريستا / الأصلي / 0.75×» | pronunciation |
| 25–35 s | Cappuccino poured layer by layer, then «خطوة بخطوة» | recipes |
| 35–42.5 s | «حاجة ساقعة بالشوكولاتة», then `laban w ahwa` | smart search |
| 42.5–50 s | hearts, tab-bar badge, long-press preview | favorites |
| 50–55 s | Wi-Fi off, «تعرف إن…» | offline catalog |
| 55–62.5 s | mark, feature chips, «نزّله دلوقتي» | outro |

## Render
```bash
python3 tool/brand_video/audio.py
```
```bash
node tool/brand_video/render.js
```
Output: `tool/brand_video/build/yaani_eh_brand.mp4` (git-ignored; ~6 min with 4
workers). Check one moment without a full render:
`node tool/brand_video/render.js --stills 13,29.8,48`. Open `index.html` in a
browser to preview it live (click to start the music once the WAV exists).

The music and sound effects are synthesized in `audio.py` (no samples, nothing
to license); 96 BPM, so every scene cut lands on a bar. Timings in `audio.py`
follow the scene times in `index.html`; change both together.
