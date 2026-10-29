# Google Play assets

Everything in `store/google-play/bn-BD/` is generated here, in Bangla:

| File | What | Upload to |
| --- | --- | --- |
| `phone-01.png` … `phone-08.png` | 1080 × 1920 phone screenshots, captioned | Main store listing → Phone screenshots |
| `feature-graphic.png` | 1024 × 500 | Main store listing → Feature graphic |
| `promo-video.mp4` | 1920 × 1080, about a minute, Bangla narration and music (not in git); on YouTube at https://youtu.be/OLWfDWof4os | Main store listing → Video (the YouTube link) |

The app icon for the listing is `assets/icon/play_store_512.png`. The
YouTube title, description, chapters and tags are in
`store/google-play/bn-BD/youtube.txt`.

The website (`docs/index.html`, GitHub Pages) uses web-sized copies of the
same screens and screenshots, exported to `docs/media/` by `site.mjs`, and
plays the video from YouTube (the link is in `docs/index.html`).

## Rebuild

```sh
tool/store/build.sh              # everything
tool/store/build.sh --no-video   # screenshots and feature graphic only
ELEVENLABS_KEY_FILE=/path/to/key.txt tool/store/build.sh   # also re-voice changed lines
```

Needs Flutter, Node 20+, Python 3, Google Chrome, ffmpeg and cwebp.

1. `tool/screenshots/store_test.dart` renders the real app screens with demo
   data (five plots of a family's land, a division among three heirs, a
   sheet with a price) at 1170 × 2532. It loads the same font files the app
   downloads at run time (`fonts.mjs`), and `fallback_glyphs.py` adds the
   few symbols a phone takes from its system fonts (∩), so the screens look
   the way they do on a phone.
2. `render.mjs` frames them with the captions in `content.mjs`.
3. `voice.mjs` reads the narration lines in `content.mjs` with ElevenLabs
   (voice *Maksud Bangla – Informative*, model `eleven_v4`). Clips are kept
   in `audio/voice/bn/` by text, so only a changed line costs credits.
   `video.mjs` times each scene to its line and mixes the voice over
   `audio/music-bed.mp3` (made with ElevenLabs Music, also used by
   VarsityKotha), ducked under the voice and levelled to −16 LUFS.

The mouza map in the screenshots is a piece of the CS sheet of Abhirampur
(J.L. 147, Rangpur), `maps/cs-abhirampur.jpg`; the RS sheet in the
প্যান্টোগ্রাফ shot is made from it in the test (turned, rescaled, with plot
103 split).

To change a caption or a line of narration, edit `content.mjs` and rebuild.
