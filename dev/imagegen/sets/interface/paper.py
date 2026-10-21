#!/usr/bin/env python3
"""The paper of a window as code lays it (Doc/guides/interface-style.md, *Paper*): the picked parchment (paper.png)
scaled to cover the page and cut to it, never stretched or repeated; a soft darker edge; a few of the picked
stains, faint, at spots seeded by the page, so they stay put while it scrolls. Used by compose.py.
  python3 dev/imagegen/sets/interface/paper.py   ->  assets/generated/interface/paper/<size>.png (three sizes)
"""
import glob, os, random
import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../..")
REFS = os.path.join(ROOT, "assets/Concept art/UI style")
TONE = (226, 200, 156)     # the page's mean colour: darker and browner than the parchment as painted (Saneroki:
                           # the paper too bright; #57 of round 1, about (238, 211, 162), closer, and darker still)
EDGE = 0.20                # the soft darker edge round a page
STAIN_EVERY = 700 * 700    # paper per stain
STAIN_ALPHA = 0.30
STAIN_SIZE = (90, 200)     # a stain's longest side in pixels

_paper = None
_stains = None


def source():
    global _paper
    if _paper is None:
        _paper = Image.open(os.path.join(REFS, "paper.png")).convert("RGB")
    return _paper


def stains():
    """The picked stains, each trimmed to what it covers."""
    global _stains
    if _stains is None:
        _stains = []
        for f in sorted(glob.glob(os.path.join(REFS, "stain*.png"))):
            img = Image.open(f).convert("RGBA")
            box = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
            if box:
                _stains.append(img.crop(box))
    return _stains


def page(w, h, seed="page", edge=EDGE, stained=True, tone=TONE):
    """A page of paper w x h: the parchment covering it in the paper's tone, the soft edge, a few stains."""
    src = source()
    k = max(w / src.width, h / src.height)
    big = src.resize((max(w, round(src.width * k)), max(h, round(src.height * k))), Image.BICUBIC)
    left, top = (big.width - w) // 2, (big.height - h) // 2
    img = np.asarray(big.crop((left, top, left + w, top + h)), dtype=np.float32)
    img *= np.array(tone, dtype=np.float32) / np.asarray(src, dtype=np.float32).reshape(-1, 3).mean(axis=0)
    yy, xx = np.mgrid[0:h, 0:w]
    dist = np.minimum.reduce([xx, w - 1 - xx, yy, h - 1 - yy]).astype(np.float32)
    img *= (1 - edge * np.exp(-dist / 26))[..., None]
    out = Image.fromarray(img.clip(0, 255).astype(np.uint8)).convert("RGBA")
    if stained:
        rnd = random.Random(seed)
        pieces = stains()
        for _ in range(max(1, round(w * h / STAIN_EVERY)) if pieces else 0):
            p = rnd.choice(pieces)
            s = rnd.uniform(*STAIN_SIZE) / max(p.size)
            p = p.resize((max(1, int(p.width * s)), max(1, int(p.height * s))), Image.LANCZOS)
            p = p.rotate(rnd.uniform(0, 360), expand=True, resample=Image.BICUBIC)
            a = p.getchannel("A").point(lambda v: int(v * STAIN_ALPHA))
            p.putalpha(a)
            out.alpha_composite(p, (rnd.randint(0, max(0, w - p.width)), rnd.randint(0, max(0, h - p.height))))
    return out


if __name__ == "__main__":
    out = os.path.join(ROOT, "assets/generated/interface/paper")
    os.makedirs(out, exist_ok=True)
    for w, h in [(480, 360), (900, 1400), (1600, 500)]:
        page(w, h, f"{w}x{h}").convert("RGB").save(os.path.join(out, f"page-{w}x{h}.png"))
    print("pages in", os.path.relpath(out, ROOT))
