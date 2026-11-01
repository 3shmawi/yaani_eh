const { chromium } = require('playwright');
const path = require('path');
const [,, html, out, ...jobs] = process.argv;
(async () => {
  const b = await chromium.launch();
  for (const j of jobs) {
    const p = new URLSearchParams(j);
    const w = +p.get('w'), h = +p.get('h');
    const pg = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: w > 700 ? 1 : 2 });
    await pg.goto('file://' + path.resolve(html) + '?' + j);
    await pg.evaluate(() => document.fonts.ready);
    await pg.waitForTimeout(150);
    const name = [p.get('opt'), p.get('state'), p.get('lang'), `${w}x${h}`, 'x' + p.get('ts')].join('_');
    await pg.screenshot({ path: `${out}/${name}.png` });
    await pg.close();
  }
  await b.close();
})();
