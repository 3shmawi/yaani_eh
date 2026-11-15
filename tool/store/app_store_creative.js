// App Store "Header and Search Results" artwork (App Store Connect →
// Product Page Information). fastlane can't upload these, so they're made
// here and uploaded by hand:
//   store/assets/app_store_creative/<ar-SA|en-US>/header.jpg          3840×1646 (21:9)
//   store/assets/app_store_creative/<ar-SA|en-US>/search_results.jpg  3840×2560 (3:2)
// Apple's spec (developer.apple.com → Creative assets specifications,
// checked 2026-11-15): JPEG or PNG, no alpha. Key art stays inside the
// Art Safe Area (header 1646×661 at 1097,493; search results 2168×1030 at
// 836,765); everything else may be cropped on some devices.
// Run after the screens exist (scripts/store_shots.sh calls it).
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '../..');
const file = (p) => path.join(root, p);
const b64 = (p) => 'data:image/png;base64,' + fs.readFileSync(file(p)).toString('base64');
// Fonts inline: a page opened with setContent can't load file:// fonts.
const font = (f) => 'data:font/ttf;base64,' + fs.readFileSync(file('assets/fonts/' + f)).toString('base64');

const TEXT = {
  'ar-SA': { lang: 'ar', dir: 'rtl', title: 'يعني إيه؟', line: 'أي حاجة… بس مفهومة', family: 'Readex' },
  'en-US': { lang: 'en', dir: 'ltr', title: 'Yaani Eh', line: 'Anything, made simple', family: 'Jakarta' },
};

// w×h canvas; safe = [x, y, w, h]; s = type scale for the safe area.
const PLACEMENTS = {
  header: { w: 3840, h: 1646, safe: [1097, 493, 1646, 661], s: 1 },
  search_results: { w: 3840, h: 2560, safe: [836, 765, 2168, 1030], s: 1.35 },
};

const SHOTS = ['2_drink', '1_home', '4_recipe', '6_search'];

function html(t, p) {
  const [sx, sy, sw, sh] = p.safe;
  const phoneH = Math.round(p.h * 0.92);
  const phoneW = Math.round(phoneH * 0.46);
  // Phones fill the cropped side areas, behind a fade, so they're mood only.
  const phones = SHOTS.map((s, i) => {
    const left = i < 2;
    const k = i % 2;
    const x = left ? Math.round(sx - phoneW * (1.05 + k * 0.95)) : Math.round(sx + sw + phoneW * (0.05 + k * 0.95));
    const y = Math.round((p.h - phoneH) / 2 + (k ? phoneH * 0.12 : -phoneH * 0.04));
    const rot = left ? -7 + k * 3 : 7 - k * 3;
    return `<div class="phone" style="left:${x}px;top:${y}px;width:${phoneW}px;height:${phoneH}px;transform:rotate(${rot}deg)">
      <img src="${b64(`build/screens/raw/phone/${t.lang}/${s}.png`)}" alt=""></div>`;
  }).join('');
  const s = p.s;
  return `<!doctype html><html dir="${t.dir}"><head><meta charset="utf-8"><style>
    @font-face{font-family:Readex;src:url(${font('ReadexPro/ReadexPro-700.ttf')});font-weight:700}
    @font-face{font-family:Jakarta;src:url(${font('PlusJakartaSans/PlusJakartaSans-700.ttf')});font-weight:700}
    html,body{margin:0;width:${p.w}px;height:${p.h}px;overflow:hidden}
    body{position:relative;background:linear-gradient(165deg,#5A2C17 0%,#3B1F12 50%,#14100D 100%);
      font-family:${t.family},sans-serif;color:#fff}
    .phone{position:absolute;border-radius:${Math.round(phoneW * 0.14)}px;overflow:hidden;
      border:${Math.round(phoneW * 0.025)}px solid #2A1C14;box-shadow:0 40px 120px rgba(0,0,0,.6)}
    .phone img{width:100%;display:block}
    .fade{position:absolute;inset:0;background:radial-gradient(ellipse ${sw * 0.75}px ${sh * 0.9}px at
      ${sx + sw / 2}px ${sy + sh / 2}px, rgba(59,31,18,.97) 0%, rgba(59,31,18,.9) 55%, rgba(20,16,13,0) 100%)}
    .safe{position:absolute;left:${sx}px;top:${sy}px;width:${sw}px;height:${sh}px;
      display:flex;flex-direction:column;align-items:center;justify-content:center;gap:${Math.round(22 * s)}px;text-align:center}
    .icon{width:${Math.round(230 * s)}px;height:${Math.round(230 * s)}px;border-radius:${Math.round(52 * s)}px;
      box-shadow:0 24px 60px rgba(0,0,0,.45)}
    h1{margin:0;font-size:${Math.round(150 * s)}px;line-height:1.1;font-weight:700}
    .line{font-size:${Math.round(84 * s)}px;line-height:1.2;font-weight:700;color:#EBD9C6}
  </style></head><body>${phones}<div class="fade"></div>
    <div class="safe"><img class="icon" src="${b64('assets/branding/icon.png')}" alt="">
      <h1>${t.title}</h1><div class="line">${t.line}</div></div>
  </body></html>`;
}

(async () => {
  const browser = await chromium.launch();
  for (const [locale, t] of Object.entries(TEXT)) {
    for (const [name, p] of Object.entries(PLACEMENTS)) {
      const page = await browser.newPage({ viewport: { width: p.w, height: p.h } });
      await page.setContent(html(t, p), { waitUntil: 'networkidle' });
      await page.evaluate(() => document.fonts.ready);
      // Fail rather than ship cropped text: the key art must fit the safe area.
      const fits = await page.evaluate(() => {
        const box = document.querySelector('.safe');
        return [...box.children].every((el) => el.scrollWidth <= box.clientWidth) &&
          box.scrollHeight <= box.clientHeight;
      });
      if (!fits) throw new Error(`${locale} ${name}: key art overflows the safe area`);
      const dir = file(`store/assets/app_store_creative/${locale}`);
      fs.mkdirSync(dir, { recursive: true });
      await page.screenshot({ path: path.join(dir, `${name}.jpg`), type: 'jpeg', quality: 92 });
      await page.close();
    }
  }
  await browser.close();
})();
