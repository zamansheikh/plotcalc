// Renders the Google Play graphics with headless Chrome:
//   store/google-play/<locale>/phone-NN.png         1080 x 1920 screenshots
//   store/google-play/<locale>/feature-graphic.png  1024 x 500
// Raw app screens come from tool/screenshots/store_test.dart (path in RAW,
// default tool/store/.cache/raw). Run tool/store/build.sh.
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
import { pathToFileURL } from 'node:url';
import puppeteer from 'puppeteer-core';
import { languages } from './content.mjs';
import { doc, phone, plots, title, iconUrl } from './page.mjs';

const here = path.dirname(new URL(import.meta.url).pathname);
const root = path.resolve(here, '../..');
const RAW = process.env.RAW ?? path.join(here, '.cache/raw');
const OUT = path.join(root, 'store/google-play');
const CHROME = process.env.CHROME ?? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const tmp = path.join(here, '.cache/html');
fs.mkdirSync(tmp, { recursive: true });

const shot = (lang, name) => pathToFileURL(path.join(RAW, `${lang}-${name}.png`)).href;

// Play wants 24-bit PNGs (no alpha channel): Chrome writes RGBA, so the
// file is rewritten as RGB.
async function render(browser, html, w, h, out) {
  const file = path.join(tmp, path.basename(out) + '.html');
  fs.writeFileSync(file, html);
  const page = await browser.newPage();
  await page.setViewport({ width: w, height: h, deviceScaleFactor: 1 });
  await page.goto(pathToFileURL(file).href, { waitUntil: 'load' });
  await page.evaluate(() => document.fonts.ready);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  const rgba = path.join(tmp, path.basename(out));
  await page.screenshot({ path: rgba, type: 'png' });
  await page.close();
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-i', rgba, '-pix_fmt', 'rgb24', out]);
}

function screenshotHtml(lang, s) {
  const text = `
  <div style="position:absolute;left:0;right:0;top:100px;text-align:center;padding:0 80px">
    <div class="chip" style="font-size:34px"><i></i>${s.chip}</div>
    <div class="title" style="font-size:80px;margin-top:30px">${title(s.title)}</div>
    <div class="body" style="font-size:37px;margin:22px auto 0;max-width:880px">${s.body}</div>
  </div>`;
  const phones = s.screens.length === 1
    ? phone({ shotUrl: shot(lang, s.screens[0]), w: 760, x: 160, y: 720 })
    : phone({ shotUrl: shot(lang, s.screens[0]), w: 580, x: 30, y: 770, rotate: -5 })
      + phone({ shotUrl: shot(lang, s.screens[1]), w: 580, x: 470, y: 820, rotate: 5 });
  const bg = plots([[-60, 1180, 420, -8], [760, 1040, 380, 12], [820, 1560, 300, -20]]);
  return doc(lang, 1080, 1920, `<div class="bg">${bg}</div>${text}${phones}`);
}

function featureHtml(lang, L) {
  return doc(lang, 1024, 500, `<div class="bg">${plots([[600, 330, 260, -10], [-70, 360, 200, 14]])}</div>
  <div style="position:absolute;left:58px;top:0;bottom:0;display:flex;flex-direction:column;justify-content:center;width:540px">
    <div style="display:flex;align-items:center;gap:26px">
      <img src="${iconUrl}" style="width:116px;height:116px;border-radius:26px;box-shadow:0 18px 40px -12px rgba(0,0,0,.8),0 0 0 2px rgba(200,255,90,.25)">
      <div>
        <div style="font-family:Baloo;font-weight:800;font-size:62px;line-height:1;letter-spacing:-.01em">PlotCalc</div>
        <div style="font-family:Hind;font-weight:600;font-size:31px;line-height:1.2;margin-top:6px;color:#C8FF5A">প্লটক্যালক</div>
      </div>
    </div>
    <div class="bn" style="margin-top:28px">
      <div class="title" style="font-size:36px;line-height:1.25">${title(L.featureTagline)}</div>
      <div class="body" style="font-size:22px;margin-top:10px">${L.subTagline}</div>
    </div>
  </div>
  ${phone({ shotUrl: shot(lang, '07-division'), w: 232, x: 604, y: 118, rotate: -7 })}
  ${phone({ shotUrl: shot(lang, '05-mouza'), w: 252, x: 752, y: 58, rotate: 6 })}`);
}

const browser = await puppeteer.launch({ executablePath: CHROME, headless: true, args: ['--allow-file-access-from-files', '--font-render-hinting=none'] });
try {
  for (const [lang, L] of Object.entries(languages)) {
    const dir = path.join(OUT, L.playLocale);
    for (const [i, s] of L.shots.entries()) {
      const out = path.join(dir, `phone-${String(i + 1).padStart(2, '0')}.png`);
      await render(browser, screenshotHtml(lang, s), 1080, 1920, out);
      console.log(path.relative(root, out));
    }
    const fg = path.join(dir, 'feature-graphic.png');
    await render(browser, featureHtml(lang, L), 1024, 500, fg);
    console.log(path.relative(root, fg));
  }
} finally {
  await browser.close();
}
