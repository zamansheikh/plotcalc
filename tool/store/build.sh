#!/usr/bin/env bash
# Rebuilds the Google Play assets in store/google-play/bn-BD/ (README.md):
#   1. app screens, rendered by Flutter with demo data
#      (tool/screenshots/store_test.dart)
#   2. framed screenshots and the feature graphic (Chrome)
#   3. the promo video (Chrome frames + ffmpeg), with ElevenLabs narration
#      and music from audio/. Changed narration lines are generated again
#      only when ELEVENLABS_KEY_FILE points at the API key file.
#   4. web-sized copies for the website in docs/media/ (site.mjs)
#
#   tool/store/build.sh            # everything
#   tool/store/build.sh --no-video # skip the video (about two minutes)
# Needs Flutter, Node 20+, Python 3, Google Chrome, ffmpeg and cwebp.
set -euo pipefail
cd "$(dirname "$0")"
here="$PWD"
video=y
[ "${1:-}" = "--no-video" ] && video=n

[ -d node_modules ] || npm install --no-fund --no-audit
node fonts.mjs >/dev/null
if [ ! -x .cache/venv/bin/python ]; then
  python3 -m venv .cache/venv
  .cache/venv/bin/pip install -q fonttools==4.55.3
fi
.cache/venv/bin/python fallback_glyphs.py

# google_fonts cannot fetch in tests and says so for every face; the fonts
# are loaded from .cache/fonts instead, so that noise is dropped.
rm -rf .cache/raw
(cd ../.. && flutter test tool/screenshots/store_test.dart \
  --dart-define=SHOTS_DIR="$here/.cache/raw" \
  --dart-define=FONTS_DIR="$here/.cache/fonts" 2>&1 \
  | grep -v -e google_fonts -e allowRuntimeFetching -e 'Failed to load font' \
    -e 'There is likely something wrong' -e 'If troubleshooting' -e '^$' || true)
[ -s .cache/raw/bn-09-arrange.png ] || { echo "Screen renders failed"; exit 1; }

node render.mjs
if [ "$video" = y ]; then
  [ -n "${ELEVENLABS_KEY_FILE:-}" ] && node voice.mjs
  node video.mjs
fi
node site.mjs
echo "Done: store/google-play/ and docs/media/"
