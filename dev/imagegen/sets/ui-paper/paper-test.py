#!/usr/bin/env python3
"""The paper as the game would lay it (Saneroki, 2026-10-21): does it scroll and resize without showing repeats?
A window's paper is three layers, as code would put them together:
  grain   a small tile repeated over the window (made seamless here: blended with itself shifted by half, so its
          edges meet; the seam is measured against the tile's own pixel steps),
  clouds  one picture scaled to cover the window and cut to it (never stretched: soft and large, so scaling
          never shows),
  stains  a few coffee stains with transparency, placed by code at random spots, sizes and turns, about one per
          so much paper, faint (seeded by the window, so they stay put while it scrolls).
  python3 dev/imagegen/sets/ui-paper/paper-test.py [grain seed] [clouds seed]
    ->  assets/generated/ui-paper/paper-test/<size>.png, tile.png (the seamless tile) and tile-2x2.png
"""
import glob, os, random, sys
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageStat

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../..")
SRC = os.path.join(ROOT, "assets/generated/ui-paper/paper")
OUT = os.path.join(ROOT, "assets/generated/ui-paper/paper-test")
TILE = 512                       # the grain tile's size in the game
SIZES = [(480, 360), (900, 1500), (1700, 520)]   # a small window, a long scrolled list, a wide panel
STAIN_EVERY = 900 * 900          # paper per stain
STAIN_ALPHA = 0.35
STAIN_SIZE = (110, 240)          # a stain's longest side in pixels
TONE = (232, 218, 189)           # the paper's mean colour: the clouded paper of the fonts page
EDGE = 0.22                      # the soft darker edge round a window
CLOUDS = 2.0                     # how strongly the clouds show


def seamless(img):
    """Seamless in two steps: blended with itself shifted by half across, the shifted copy ruling at the left and
    right edges (its own seam lies in the middle, where the original rules); then the same up and down."""
    w, h = img.size
    across = Image.linear_gradient("L").rotate(90, expand=True).resize((w, h))   # 0 .. 255 left to right
    across = across.point(lambda v: int(255 * min(1, (1 - abs(v - 127.5) / 127.5) * 2.2) ** 1.5))
    img = Image.composite(img, ImageChops.offset(img, w // 2, 0), across)
    down = across.rotate(90).resize((w, h))
    return Image.composite(img, ImageChops.offset(img, 0, h // 2), down)


def seam(img):
    """Mean step across the wrap seams against the mean step between neighbours inside: near 1 is seamless."""
    g = img.convert("L")
    w, h = g.size
    inner = ImageStat.Stat(ImageChops.difference(g.crop((0, 0, w - 1, h)), g.crop((1, 0, w, h)))).mean[0]
    across = (ImageStat.Stat(ImageChops.difference(g.crop((w - 1, 0, w, h)), g.crop((0, 0, 1, h)))).mean[0] +
              ImageStat.Stat(ImageChops.difference(g.crop((0, h - 1, w, h)), g.crop((0, 0, w, 1)))).mean[0]) / 2
    return across / max(inner, 0.01)


def stains():
    """Each stain cut out of its picture by its alpha, trimmed to what it covers."""
    pieces = []
    for f in sorted(glob.glob(os.path.join(SRC, "stain*.png"))):
        img = Image.open(f).convert("RGBA")
        box = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
        if box:
            pieces.append(img.crop(box))
    return pieces


def window(size, grain, clouds, pieces, seed):
    w, h = size
    paper = Image.new("RGB", size)
    for y in range(0, h, TILE):
        for x in range(0, w, TILE):
            paper.paste(grain, (x, y))
    # the clouds lighten and darken the grain by how far they are from their own mean tone
    k = max(w / clouds.width, h / clouds.height)   # scaled to cover the window and cut, never stretched
    big = clouds.resize((max(w, round(clouds.width * k)), max(h, round(clouds.height * k))), Image.BICUBIC)
    big = big.crop(((big.width - w) // 2, (big.height - h) // 2, (big.width - w) // 2 + w, (big.height - h) // 2 + h))
    cl = np.asarray(big.filter(ImageFilter.GaussianBlur(8)), dtype=np.float32)
    base = np.asarray(paper, dtype=np.float32) + (cl - cl.mean(axis=(0, 1))) * CLOUDS
    base += np.array(TONE, dtype=np.float32) - base.mean(axis=(0, 1))   # the tone set, the grain and clouds kept
    yy, xx = np.mgrid[0:h, 0:w]
    edge = np.minimum.reduce([xx, w - 1 - xx, yy, h - 1 - yy]).astype(np.float32)
    base *= (1 - EDGE * np.exp(-edge / 28))[..., None]                     # the soft darker edge, as code draws it
    paper = Image.fromarray(base.clip(0, 255).astype(np.uint8))
    rnd = random.Random(seed)
    for _ in range(max(1, round(w * h / STAIN_EVERY))) if pieces else []:
        piece = rnd.choice(pieces)
        scale = rnd.uniform(STAIN_SIZE[0], STAIN_SIZE[1]) / max(piece.size)
        p = piece.resize((max(1, int(piece.width * scale)), max(1, int(piece.height * scale))), Image.LANCZOS)
        p = p.rotate(rnd.uniform(0, 360), expand=True, resample=Image.BICUBIC)
        a = p.getchannel("A").point(lambda v: int(v * STAIN_ALPHA))
        paper.paste(p.convert("RGB"), (rnd.randint(-p.width // 3, w - p.width * 2 // 3),
                                       rnd.randint(-p.height // 3, h - p.height * 2 // 3)), a)
    d = ImageDraw.Draw(paper)
    d.text((10, 8), f"{w} x {h}", fill=(70, 60, 50))
    return paper


def main():
    gseed = sys.argv[1] if len(sys.argv) > 1 else "1"
    cseed = sys.argv[2] if len(sys.argv) > 2 else "1"
    os.makedirs(OUT, exist_ok=True)
    raw = Image.open(os.path.join(SRC, f"grain-{gseed}.png")).convert("RGB").resize((TILE, TILE), Image.LANCZOS)
    grain = seamless(raw)
    grain.save(os.path.join(OUT, "tile.png"))
    two = Image.new("RGB", (TILE * 2, TILE * 2))
    for y in (0, TILE):
        for x in (0, TILE):
            two.paste(grain, (x, y))
    two.save(os.path.join(OUT, "tile-2x2.png"))
    print(f"seam: raw {seam(raw):.2f}, made seamless {seam(grain):.2f} (1 = no seam)")
    clouds = Image.open(os.path.join(SRC, f"clouds-{cseed}.png")).convert("RGB")
    pieces = stains()
    for size in SIZES:
        window(size, grain, clouds, pieces, f"{size}").save(os.path.join(OUT, f"window-{size[0]}x{size[1]}.png"))
    print(f"{len(pieces)} stains; windows in {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
