// Store graphics from the app's own icon and screens:
//   store/android/<ar|en-US>/images/featureGraphic.png  1024×500, no alpha
//   store/android/<ar|en-US>/images/icon.png            512×512
//   store/assets/app_store_icon_1024.png                1024×1024, no alpha
//     (the App Store takes its icon from the build; this copy is for
//      reference and for press)
// Run after the screens exist (scripts/store_shots.sh calls it).
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '../..');
const file = (p) => path.join(root, p);
const b64 = (p) => 'data:image/png;base64,' + fs.readFileSync(file(p)).toString('base64');
const font = (f) => 'file://' + file('assets/fonts/' + f);

const TEXT = {
  ar: { dir: 'rtl', title: 'يعني إيه؟', line: 'منيو الكافيه… بس مفهوم', sub: 'كل مشروب بكلام إنت عارفه، وإزاي بيتعمل', family: 'Readex' },
  'en-US': { dir: 'ltr', title: 'Yaani Eh', line: 'Café menus that make sense', sub: 'Every drink in plain words, and how it’s made', family: 'Jakarta' },
};

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1024, height: 500 } });
  for (const [locale, t] of Object.entries(TEXT)) {
    const lang = locale === 'ar' ? 'ar' : 'en';
    const shot = b64(`build/screens/raw/phone/${lang}/1_home.png`);
    const html = `<!doctype html><html dir="${t.dir}"><head><meta charset="utf-8"><style>
      @font-face{font-family:Readex;src:url(${font('ReadexPro/ReadexPro-700.ttf')});font-weight:700}
      @font-face{font-family:Readex;src:url(${font('ReadexPro/ReadexPro-500.ttf')});font-weight:500}
      @font-face{font-family:Jakarta;src:url(${font('PlusJakartaSans/PlusJakartaSans-700.ttf')});font-weight:700}
      @font-face{font-family:Jakarta;src:url(${font('PlusJakartaSans/PlusJakartaSans-500.ttf')});font-weight:500}
      html,body{margin:0;width:1024px;height:500px;overflow:hidden}
      body{background:linear-gradient(165deg,#5A2C17 0%,#3B1F12 50%,#14100D 100%);color:#fff;
        font-family:${t.family},sans-serif;display:flex;align-items:center;gap:56px;padding:0 72px;box-sizing:border-box}
      .txt{flex:1;display:flex;flex-direction:column;gap:14px}
      .icon{width:96px;height:96px;border-radius:22px;box-shadow:0 12px 30px rgba(0,0,0,.4)}
      h1{margin:6px 0 0;font-size:58px;line-height:1.15;font-weight:700}
      .line{font-size:30px;font-weight:700;color:#EBD9C6}
      .sub{font-size:20px;font-weight:500;color:#D9C3AE}
      .phone{width:250px;height:540px;margin-top:120px;border-radius:36px;overflow:hidden;border:6px solid #2A1C14;
        box-shadow:0 20px 50px rgba(0,0,0,.6);transform:rotate(${t.dir === 'rtl' ? 6 : -6}deg)}
      .phone img{width:100%;display:block}
    </style></head><body>
      <div class="txt"><img class="icon" src="${b64('assets/branding/icon.png')}" alt="">
        <h1>${t.title}</h1><div class="line">${t.line}</div><div class="sub">${t.sub}</div></div>
      <div class="phone"><img src="${shot}" alt=""></div>
    </body></html>`;
    await page.setContent(html, { waitUntil: 'networkidle' });
    await page.evaluate(() => document.fonts.ready);
    const dir = file(`store/android/${locale}/images`);
    fs.mkdirSync(dir, { recursive: true });
    await page.screenshot({ path: path.join(dir, 'featureGraphic.png') });
  }
  // Icons: the 1024 master, resized in the browser (no extra tools).
  for (const [out, size] of [
    ['store/android/ar/images/icon.png', 512],
    ['store/android/en-US/images/icon.png', 512],
    ['store/assets/app_store_icon_1024.png', 1024],
  ]) {
    await page.setViewportSize({ width: size, height: size });
    await page.setContent(`<html><body style="margin:0;background:#3B1F12"><img src="${b64('assets/branding/icon.png')}" style="width:${size}px;height:${size}px;display:block"></body></html>`);
    fs.mkdirSync(path.dirname(file(out)), { recursive: true });
    await page.screenshot({ path: file(out) });
  }
  await browser.close();
})();
