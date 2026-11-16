// Renders tool/brand_video/index.html frame by frame, then muxes the music
// (audio.py) into an MP4. Usage (from the repo root):
//   python3 tool/brand_video/audio.py
//   node tool/brand_video/render.js                 # full video
//   node tool/brand_video/render.js --stills 3,12,30  # PNG stills to check a moment
const { chromium } = require('playwright');
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const FPS = 30;
const DIR = __dirname;
const OUT = path.join(DIR, 'build');
const FRAMES = path.join(OUT, 'frames');
const WORKERS = Number(process.env.WORKERS || 4);
const url = 'file://' + path.join(DIR, 'index.html') + '?render';

async function page(browser) {
  const p = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  await p.goto(url);
  await p.evaluate(() => window.READY);
  return p;
}

async function main() {
  fs.mkdirSync(FRAMES, { recursive: true });
  const browser = await chromium.launch();
  const stillsArg = process.argv.indexOf('--stills');
  if (stillsArg > 0) {
    const p = await page(browser);
    for (const s of process.argv[stillsArg + 1].split(',').map(Number)) {
      await p.evaluate(t => window.render(t), s);
      await p.screenshot({ path: path.join(OUT, `still_${String(s).replace('.', '_')}.png`), clip: { x: 0, y: 0, width: 1080, height: 1920 } });
    }
    await browser.close();
    return;
  }
  const duration = await (await page(browser)).evaluate(() => DURATION);
  const total = Math.round(duration * FPS);
  let next = 0, done = 0;
  await Promise.all(Array.from({ length: WORKERS }, async () => {
    const p = await page(browser);
    while (next < total) {
      const f = next++;
      await p.evaluate(t => window.render(t), f / FPS);
      await p.screenshot({ path: path.join(FRAMES, `${String(f).padStart(5, '0')}.jpg`), type: 'jpeg', quality: 95, clip: { x: 0, y: 0, width: 1080, height: 1920 } });
      if (++done % 150 === 0) console.log(`${done}/${total}`);
    }
  }));
  await browser.close();
  const wav = path.join(OUT, 'yaani_eh_brand.wav');
  const mp4 = path.join(OUT, 'yaani_eh_brand.mp4');
  const args = ['-y', '-loglevel', 'error', '-framerate', String(FPS), '-i', path.join(FRAMES, '%05d.jpg')];
  if (fs.existsSync(wav)) args.push('-i', wav);
  args.push('-c:v', 'libx264', '-preset', 'slow', '-crf', '23', '-tune', 'grain', '-maxrate', '12M', '-bufsize', '24M', '-pix_fmt', 'yuv420p', '-movflags', '+faststart');
  if (fs.existsSync(wav)) args.push('-c:a', 'aac', '-b:a', '192k', '-shortest');
  args.push(mp4);
  execFileSync('ffmpeg', args, { stdio: 'inherit' });
  console.log('wrote', mp4);
}
main().catch(e => { console.error(e); process.exit(1); });
