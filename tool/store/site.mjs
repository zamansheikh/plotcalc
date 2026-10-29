// Exports web-sized copies of the store assets for the website in docs/
// (GitHub Pages): app screens and Play screenshots as WebP, the social
// card, and the still shown before the YouTube video plays.
// Run after render.mjs and video.mjs (build.sh does).
import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

const here = path.dirname(new URL(import.meta.url).pathname);
const root = path.resolve(here, '../..');
const RAW = process.env.RAW ?? path.join(here, '.cache/raw');
const PLAY = path.join(root, 'store/google-play/bn-BD');
const OUT = path.join(root, 'docs/media');
const run = (cmd, args) => execFileSync(cmd, args, { stdio: ['ignore', 'ignore', 'inherit'] });
const webp = (src, out, width) => run('cwebp', ['-quiet', '-q', '82', '-resize', String(width), '0', src, '-o', out]);

fs.mkdirSync(path.join(OUT, 'screens'), { recursive: true });
fs.mkdirSync(path.join(OUT, 'play'), { recursive: true });
for (const f of fs.readdirSync(RAW).filter((f) => f.endsWith('.png'))) {
  webp(path.join(RAW, f), path.join(OUT, 'screens', f.replace(/^bn-/, '').replace('.png', '.webp')), 600);
}
for (const f of fs.readdirSync(PLAY).filter((f) => /^phone-\d+\.png$/.test(f))) {
  webp(path.join(PLAY, f), path.join(OUT, 'play', f.replace('.png', '.webp')), 540);
}
webp(path.join(root, 'assets/icon/play_store_512.png'), path.join(OUT, 'icon.webp'), 256);
// Link previews (og:image) want a JPEG or PNG.
run('ffmpeg', ['-y', '-loglevel', 'error', '-i', path.join(PLAY, 'feature-graphic.png'), '-q:v', '3', path.join(OUT, 'og.jpg')]);

// The site plays the video from YouTube; this is the still shown before.
const video = path.join(PLAY, 'promo-video.mp4');
if (fs.existsSync(video)) {
  run('ffmpeg', ['-y', '-loglevel', 'error', '-ss', '4', '-i', video, '-frames:v', '1', '-vf', 'scale=1280:-2', '-q:v', '4',
    path.join(OUT, 'promo-poster.jpg')]);
}
for (const f of ['', 'screens', 'play']) {
  const dir = path.join(OUT, f);
  const files = fs.readdirSync(dir).filter((x) => fs.statSync(path.join(dir, x)).isFile());
  const kb = files.reduce((s, x) => s + fs.statSync(path.join(dir, x)).size, 0) / 1024;
  console.log(`docs/media/${f}: ${files.length} files, ${Math.round(kb)} KB`);
}
