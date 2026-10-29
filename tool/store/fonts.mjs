// Downloads the fonts the store assets need into .cache/fonts/:
//   app/   the exact files google_fonts fetches at run time in the app
//          (Inter, JetBrains Mono, Noto Sans Bengali), so the Flutter
//          screen renderer draws text the way a phone does;
//   the Google Fonts repository faces used by the captions (OFL), and
//          Noto Sans Math for fallback_glyphs.py.
import fs from 'node:fs';
import path from 'node:path';

const here = path.dirname(new URL(import.meta.url).pathname);
const root = path.resolve(here, '../..');
const out = path.join(here, '.cache/fonts');
fs.mkdirSync(path.join(out, 'app'), { recursive: true });

async function get(url, file) {
  if (fs.existsSync(file) && fs.statSync(file).size > 0) return;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${res.status} ${url}`);
  fs.writeFileSync(file, Buffer.from(await res.arrayBuffer()));
}

// google_fonts keeps its file table in lib/src/google_fonts_parts/.
const config = JSON.parse(fs.readFileSync(path.join(root, '.dart_tool/package_config.json'), 'utf8'));
const gf = config.packages.find((p) => p.name === 'google_fonts');
const gfRoot = gf.rootUri.startsWith('file:')
  ? new URL(gf.rootUri).pathname
  : path.resolve(root, '.dart_tool', gf.rootUri);
const parts = path.join(gfRoot, 'lib/src/google_fonts_parts');
const sources = fs.readdirSync(parts).map((f) => fs.readFileSync(path.join(parts, f), 'utf8'));

for (const fn of ['inter', 'jetBrainsMono', 'notoSansBengali']) {
  const src = sources.find((s) => s.includes(`static TextStyle ${fn}(`));
  const body = src.slice(src.indexOf(`static TextStyle ${fn}(`));
  const block = body.slice(0, body.indexOf('return googleFontsTextStyle('));
  const family = body.match(/fontFamily: '([^']+)'/)[1];
  const re = /fontWeight: FontWeight\.w(\d+),\s*fontStyle: FontStyle\.(\w+),\s*\): const GoogleFontsFile\(\s*'([0-9a-f]{64})'/g;
  for (const [, w, style, hash] of block.matchAll(re)) {
    if (style !== 'normal' || +w < 300 || +w > 800) continue;
    const variant = w === '400' ? 'regular' : w;
    await get(`https://fonts.gstatic.com/s/a/${hash}.ttf`, path.join(out, 'app', `${family}_${variant}.ttf`));
  }
}

for (const f of ['balooda2/BalooDa2[wght].ttf', 'inter/Inter[opsz,wght].ttf',
  'hindsiliguri/HindSiliguri-Medium.ttf', 'hindsiliguri/HindSiliguri-SemiBold.ttf', 'hindsiliguri/HindSiliguri-Bold.ttf',
  // Symbols a phone takes from its system fonts (fallback_glyphs.py).
  'notosansmath/NotoSansMath-Regular.ttf']) {
  const url = `https://github.com/google/fonts/raw/main/ofl/${f.replace('[', '%5B').replace(']', '%5D')}`;
  await get(url, path.join(out, path.basename(f)));
}
console.log(fs.readdirSync(path.join(out, 'app')).join(' '));
