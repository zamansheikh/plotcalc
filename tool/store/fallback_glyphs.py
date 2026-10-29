"""Adds a few symbols a phone draws from its system fonts (∩ and ∪, from
Noto Sans Math) to the Noto Sans Bengali files in .cache/fonts/app/, the
app's fallback face. Flutter tests have no system fallback, so without this
those symbols render as a missing-glyph box. Only the test renderer uses
these files; the app is unchanged. Safe to run again.

  .cache/venv/bin/python fallback_glyphs.py
"""
import glob
import os
import sys

from fontTools.ttLib import TTFont

HERE = os.path.dirname(os.path.abspath(__file__))
SYMBOLS = [0x2229, 0x222A]

math = TTFont(os.path.join(HERE, '.cache/fonts/NotoSansMath-Regular.ttf'))
math_cmap = math.getBestCmap()

for path in sorted(glob.glob(os.path.join(HERE, '.cache/fonts/app/NotoSansBengali_*.ttf'))):
    font = TTFont(path)
    cmap = font.getBestCmap()
    missing = [u for u in SYMBOLS if u not in cmap]
    if not missing:
        continue
    if font['head'].unitsPerEm != math['head'].unitsPerEm:
        sys.exit(f'{path}: units per em differ')
    order = font.getGlyphOrder()
    glyf, hmtx = font['glyf'], font['hmtx']
    for u in missing:
        src = math_cmap[u]
        glyph = math['glyf'][src]
        if glyph.isComposite():
            sys.exit(f'U+{u:04X} is a composite glyph in Noto Sans Math')
        name = f'uni{u:04X}'
        order.append(name)
        glyf.glyphs[name] = glyph
        hmtx.metrics[name] = math['hmtx'].metrics[src]
        for table in font['cmap'].tables:
            if table.isUnicode():
                table.cmap[u] = name
    font.setGlyphOrder(order)
    glyf.glyphOrder = order
    font['maxp'].numGlyphs = len(order)
    if font['post'].formatType == 2.0:
        font['post'].extraNames = []
        font['post'].mapping = {}
    font.save(path)
    print(os.path.basename(path), '+', ' '.join(f'U+{u:04X}' for u in missing))
