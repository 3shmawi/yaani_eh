// Frames raw app screens into store screenshots: the header band's
// gradient, a caption on top, the screen below with rounded corners.
//   node tool/store/frame.js <raw dir> <out.png> <W> <H> <lang> <shot>
// Used by scripts/store_shots.sh; fonts are the app's own.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const CAPTIONS = {
  ar: {
    '1_home': ['منيو الكافيه… بس مفهوم', 'كل مشروب بالاسم زي ما هو مكتوب، ويعني إيه'],
    '2_drink': ['يعني إيه؟ بكلام إنت عارفه', 'من غير ولا كلمة غريبة'],
    '3_preview': ['دوس مطوّل… واعرف على طول', 'من غير ما تسيب المنيو'],
    '4_recipe': ['الفنجان بطبقاته بالمقاس', 'شوف فيه إيه قبل ما تطلبه'],
    '5_steps': ['اعمله في البيت', 'خطوة بخطوة، بخط كبير'],
    '6_search': ['دوّر بالوصف', 'اكتب اللي نفسك فيه، مش لازم الاسم'],
    '7_favorites': ['احفظ اللي عجبك', 'على موبايلك، من غير حساب ولا نت'],
  },
  en: {
    '1_home': ['Café menus that make sense', 'Every drink as the menu prints it, and what it is'],
    '2_drink': ['What is it? In plain words', 'No jargon, no other menu words'],
    '3_preview': ['Long-press for a quick look', 'Without leaving the menu'],
    '4_recipe': ["What's in the cup, to scale", 'See it before you order it'],
    '5_steps': ['Make it at home', 'Step by step, in big text'],
    '6_search': ['Search by taste', 'Describe what you want, no name needed'],
    '7_favorites': ['Keep the ones you like', 'On your phone, no account, works offline'],
  },
};

(async () => {
  const [raw, out, W, H, lang, shot] = process.argv.slice(2);
  const w = Number(W), h = Number(H);
  const [title, sub] = CAPTIONS[lang][shot];
  const root = path.resolve(__dirname, '../..');
  const font = (f) => 'file://' + path.join(root, 'assets/fonts', f);
  const img = 'data:image/png;base64,' + fs.readFileSync(path.join(raw, shot + '.png')).toString('base64');
  const landscape = w > h;
  // Caption band takes the top; the screen fills the rest, keeping its ratio.
  const pad = Math.round(Math.min(w, h) * 0.06);
  const titleSize = Math.round(Math.min(w, h) * (landscape ? 0.05 : 0.068));
  const html = `<!doctype html><html dir="${lang === 'ar' ? 'rtl' : 'ltr'}"><head><meta charset="utf-8"><style>
    @font-face{font-family:Readex;src:url(${font('ReadexPro/ReadexPro-700.ttf')});font-weight:700}
    @font-face{font-family:Readex;src:url(${font('ReadexPro/ReadexPro-500.ttf')});font-weight:500}
    @font-face{font-family:Jakarta;src:url(${font('PlusJakartaSans/PlusJakartaSans-700.ttf')});font-weight:700}
    @font-face{font-family:Jakarta;src:url(${font('PlusJakartaSans/PlusJakartaSans-500.ttf')});font-weight:500}
    html,body{margin:0;width:${w}px;height:${h}px;overflow:hidden}
    body{background:linear-gradient(165deg,#5A2C17 0%,#3B1F12 45%,#14100D 100%);
      font-family:${lang === 'ar' ? 'Readex' : 'Jakarta'},sans-serif;color:#fff;
      display:flex;flex-direction:column;align-items:center;box-sizing:border-box;padding:${pad * 1.4}px ${pad}px 0}
    h1{margin:0;font-size:${titleSize}px;line-height:1.25;font-weight:700;text-align:center}
    p{margin:${titleSize * 0.35}px 0 0;font-size:${Math.round(titleSize * 0.5)}px;font-weight:500;color:#EBD9C6;text-align:center}
    .shot{flex:1;min-height:0;margin-top:${pad}px;display:flex;align-items:flex-start;justify-content:center;width:100%}
    .shot img{width:${landscape ? 46 : 84}%;border-radius:${Math.round(Math.min(w, h) * 0.05)}px;
      box-shadow:0 ${pad / 2}px ${pad * 1.5}px rgba(0,0,0,.55);border:${Math.max(4, Math.round(w / 220))}px solid #2A1C14}
  </style></head><body><h1>${title}</h1><p>${sub}</p><div class="shot"><img src="${img}"></div></body></html>`;
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
  await page.setContent(html, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  // No alpha (the App Store rejects transparency); .jpg → JPEG at 90.
  await page.screenshot(
    out.endsWith('.jpg') ? { path: out, type: 'jpeg', quality: 90 } : { path: out },
  );
  await browser.close();
})();
