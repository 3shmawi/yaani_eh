// Renders the app icon and splash PNGs in assets/branding from the Icon /
// IconForeground artboards of the Design canvas (docs/design.md), with the
// bundled Readex Pro so the «؟» glyph is exact. Needs Playwright + Chromium:
//   node tool/render_branding.js
// then: dart run flutter_launcher_icons && dart run flutter_native_splash:create
const { chromium } = require('playwright');
const path = require('path');
const root = path.resolve(__dirname, '..');
const font = 'file://' + path.join(root, 'assets/fonts/ReadexPro/ReadexPro-700.ttf');
const BUBBLE = 'M392 250 H632 A160 160 0 0 1 792 410 V540 A160 160 0 0 1 700 684 L760 792 L600 700 H392 A160 160 0 0 1 232 540 V410 A160 160 0 0 1 392 250 Z';
const bg = `radial-gradient(ellipse 70% 55% at 80% 10%, rgba(201,135,79,0.75), transparent 70%), linear-gradient(165deg, #5a2c17 0%, #3b1f12 55%, #24120a 100%)`;
// The bubble mark, scaled around the canvas centre (1 = as on the icon).
const mark = (scale, shadow) => `
<svg viewBox="0 0 1024 1024" width="100%" height="100%" style="position:absolute;inset:0">
  <defs><linearGradient id="f" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fffaf5"/><stop offset="1" stop-color="#ebd9c6"/></linearGradient></defs>
  <g transform="translate(512 512) scale(${scale}) translate(-512 -521)">
    ${shadow ? `<path d="${BUBBLE}" fill="#000" fill-opacity="0.25" transform="translate(0 26)"/>` : ''}
    <path d="${BUBBLE}" fill="url(#f)" stroke="#fff" stroke-width="12" stroke-linejoin="round"/>
    <path d="M300 420 A120 120 0 0 1 400 300" fill="none" stroke="#fff" stroke-width="22" stroke-linecap="round" stroke-opacity="0.9"/>
    <text x="512" y="612" text-anchor="middle" font-family="RX" font-weight="700" font-size="330" fill="#9a4a24">؟</text>
  </g>
</svg>`;
const page = (w, h, body, background) => `<!doctype html><html><head><meta charset="utf-8"><style>
@font-face{font-family:RX;src:url('${font}');font-weight:700}
html,body{margin:0;background:transparent}
.c{width:${w}px;height:${h}px;position:relative;overflow:hidden;background:${background || 'transparent'}}
</style></head><body><div class="c">${body}</div></body></html>`;
const out = path.join(root, 'assets/branding') + '/';
const jobs = [
  // Full icon (iOS + legacy Android): gradient + mark exactly as the artboard.
  ['icon.png', 1024, 1024, mark(1, true), bg, false],
  // Adaptive icon: background layer and the mark inside the safe zone.
  ['icon_background.png', 1024, 1024, '', bg, false],
  ['icon_foreground.png', 1024, 1024, mark(0.72, false), null, true],
  // Splash: the mark on transparent (pre-Android 12 + iOS) …
  ['splash.png', 768, 768, mark(0.9, false), null, true],
  // … Android 12 icon: 1152 canvas, mark inside the central 768 circle.
  ['splash_android12.png', 1152, 1152, mark(0.62, false), null, true],
  // The header gradient behind the splash.
  ['splash_background.png', 1242, 2688, '', bg, false],
];
(async () => {
  const browser = await chromium.launch();
  for (const [name, w, h, body, background, transparent] of jobs) {
    const p = await browser.newPage({ viewport: { width: w, height: h } });
    await p.setContent(page(w, h, body, background), { waitUntil: 'load' });
    await p.evaluate(() => document.fonts.ready);
    await p.screenshot({ path: out + name, omitBackground: transparent, clip: { x: 0, y: 0, width: w, height: h } });
    console.log('wrote', name);
    await p.close();
  }
  await browser.close();
})();
