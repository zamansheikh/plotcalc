// HTML building blocks for the store graphics: fonts, the brand background,
// a phone mockup and caption blocks. Rendered by Chrome (render.mjs,
// video.mjs), so Bangla is shaped properly.
import { pathToFileURL } from 'node:url';
import path from 'node:path';

const here = path.dirname(new URL(import.meta.url).pathname);
const root = path.resolve(here, '../..');
const url = (p) => pathToFileURL(p).href;
export const fontsDir = path.join(here, '.cache/fonts');
export const iconUrl = url(path.join(root, 'assets/icon/play_store_512.png'));

// The app's own colours (lib/core/theme/app_colors.dart).
export const C = {
  ink: '#0D1108',
  surface: '#151A10',
  lime: '#C8FF5A',
  text: '#F4F1EA',
  soil: '#D4A574',
};

export const css = `
@font-face { font-family: Inter; src: url('${url(path.join(fontsDir, 'Inter[opsz,wght].ttf'))}'); font-weight: 100 900; }
@font-face { font-family: Baloo; src: url('${url(path.join(fontsDir, 'BalooDa2[wght].ttf'))}'); font-weight: 400 800; }
@font-face { font-family: Hind; src: url('${url(path.join(fontsDir, 'HindSiliguri-Medium.ttf'))}'); font-weight: 500; }
@font-face { font-family: Hind; src: url('${url(path.join(fontsDir, 'HindSiliguri-SemiBold.ttf'))}'); font-weight: 600; }
@font-face { font-family: Hind; src: url('${url(path.join(fontsDir, 'HindSiliguri-Bold.ttf'))}'); font-weight: 700; }
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { width: 100%; height: 100%; overflow: hidden; background: ${C.ink}; }
body { -webkit-font-smoothing: antialiased; text-rendering: geometricPrecision; color: ${C.text}; }
.bg {
  position: absolute; inset: 0; overflow: hidden;
  background:
    radial-gradient(70% 45% at 18% 0%, rgba(200,255,90,.22) 0%, rgba(200,255,90,0) 70%),
    radial-gradient(80% 50% at 100% 100%, rgba(212,165,116,.16) 0%, rgba(212,165,116,0) 70%),
    linear-gradient(170deg, #161D0E 0%, ${C.ink} 55%, #080B05 100%);
}
/* The survey grid the app draws plots on. */
.bg::before {
  content: ''; position: absolute; inset: 0;
  background-image:
    linear-gradient(rgba(200,255,90,.09) 1.5px, transparent 1.5px),
    linear-gradient(90deg, rgba(200,255,90,.09) 1.5px, transparent 1.5px),
    linear-gradient(rgba(200,255,90,.04) 1px, transparent 1px),
    linear-gradient(90deg, rgba(200,255,90,.04) 1px, transparent 1px);
  background-size: 180px 180px, 180px 180px, 36px 36px, 36px 36px;
  mask-image: radial-gradient(90% 70% at 30% 20%, #000 0%, transparent 85%);
}
.bg .plot { position: absolute; overflow: visible; }
.bn .title { font-family: Baloo; font-weight: 800; line-height: 1.2; letter-spacing: 0; }
.bn .body, .bn .chip { font-family: Hind; }
.chip {
  display: inline-flex; align-items: center; gap: 14px;
  padding: 12px 28px 12px 20px; border-radius: 999px;
  background: rgba(200,255,90,.10); border: 1.5px solid rgba(200,255,90,.35);
  font-weight: 600; color: ${C.lime};
}
.chip i { width: 14px; height: 14px; border-radius: 50%; background: ${C.lime}; box-shadow: 0 0 0 6px rgba(200,255,90,.18); }
.title { color: ${C.text}; }
.title b { display: block; color: ${C.lime}; font-weight: inherit; }
.body { color: rgba(244,241,234,.72); font-weight: 500; line-height: 1.45; }
.phone {
  position: absolute; background: #050704; padding: var(--bezel);
  border-radius: var(--r);
  box-shadow: 0 70px 120px -30px rgba(0,0,0,.85), 0 30px 60px -20px rgba(0,0,0,.6),
              0 0 0 2px rgba(200,255,90,.16), inset 0 0 0 2px rgba(255,255,255,.08);
}
.phone .screen { position: relative; overflow: hidden; border-radius: calc(var(--r) - var(--bezel)); background: ${C.ink}; }
.phone .screen img.shot { display: block; width: 100%; }
.phone .status {
  height: var(--sb); display: flex; align-items: center; justify-content: space-between;
  padding: 0 calc(var(--sb) * .9); font-family: Inter; font-weight: 600; font-size: calc(var(--sb) * .5);
  color: ${C.text};
}
.phone .punch {
  position: absolute; top: calc(var(--sb) * .26); left: 50%; transform: translateX(-50%);
  width: calc(var(--sb) * .48); height: calc(var(--sb) * .48); border-radius: 50%;
  background: #020301; box-shadow: inset 0 0 0 2px #1A2112;
}
.phone .icons { display: flex; gap: calc(var(--sb) * .22); align-items: center; }
.phone .icons svg { height: calc(var(--sb) * .44); width: auto; }
`;

/** Status bar icons (signal, Wi-Fi, battery). */
function statusIcons(color) {
  return `<span class="icons">
  <svg viewBox="0 0 20 16"><path fill="${color}" d="M1 15h3v-4H1zM6 15h3V8H6zM11 15h3V4h-3zM16 15h3V0h-3z"/></svg>
  <svg viewBox="0 0 22 16"><path fill="${color}" d="M11 16 22 4.6A15.6 15.6 0 0 0 11 0 15.6 15.6 0 0 0 0 4.6z"/></svg>
  <svg viewBox="0 0 30 16"><rect x="1" y="1" width="24" height="14" rx="3.5" fill="none" stroke="${color}" stroke-width="2"/><rect x="4" y="4" width="16" height="8" rx="1.5" fill="${color}"/><rect x="26.5" y="5" width="2.5" height="6" rx="1" fill="${color}"/></svg>
</span>`;
}

/**
 * A phone showing [shotUrl]. [w] is the outer width in px; the screenshot is
 * a 390 x 844 phone, with a status bar added above it.
 */
export function phone({ shotUrl, w, x, y, rotate = 0, style = '', cls = '' }) {
  const bezel = Math.round(w * 0.024);
  const r = Math.round(w * 0.13);
  const sb = Math.round((w - 2 * bezel) * 24 / 390);
  return `<div class="phone ${cls}" style="--bezel:${bezel}px;--r:${r}px;--sb:${sb}px;width:${w}px;left:${x}px;top:${y}px;transform:rotate(${rotate}deg);${style}">
  <div class="screen">
    <div class="status"><span>১০:০৫</span>${statusIcons(C.text)}</div>
    <div class="punch"></div>
    <img class="shot" src="${shotUrl}">
  </div>
</div>`;
}

/**
 * Faint plot outlines in the background, like plots on a survey sheet:
 * [list] of [x, y, size, rotation].
 */
export function plots(list) {
  const shapes = [
    'M8 22 L88 10 L96 78 L14 92 Z',
    'M10 14 L90 20 L84 70 L52 92 L12 74 Z',
    'M6 30 L60 8 L94 40 L70 92 L20 80 Z',
  ];
  return list.map(([x, y, s, rot], i) => `<svg class="plot" viewBox="0 0 100 100" style="left:${x}px;top:${y}px;width:${s}px;height:${s}px;transform:rotate(${rot}deg)">
    <path d="${shapes[i % shapes.length]}" fill="rgba(200,255,90,.035)" stroke="rgba(200,255,90,.22)" stroke-width="${(100 / s) * 2}" stroke-dasharray="${(100 / s) * 10} ${(100 / s) * 7}"/>
    ${shapes[i % shapes.length].match(/\d+ \d+/g).map((p) => { const [cx, cy] = p.split(' '); return `<circle cx="${cx}" cy="${cy}" r="${(100 / s) * 5}" fill="rgba(200,255,90,.35)"/>`; }).join('')}
  </svg>`).join('');
}

/** A caption title: the first line in white, the rest in lime. */
export function title(text) {
  const [first, ...rest] = text.split('\n');
  return rest.length ? `${first}<b>${rest.join('<br>')}</b>` : first;
}

export const doc = (lang, w, h, body) => `<!doctype html><html lang="${lang}"><head><meta charset="utf-8">
<style>${css} body{width:${w}px;height:${h}px}</style></head>
<body class="${lang}">${body}</body></html>`;
