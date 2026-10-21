#!/usr/bin/env python3
"""The decided parts cut out of Saneroki's picks (Doc/guides/interface-style.md, its pictures in
assets/Concept art/UI style/): every element of the harness is made from its crop alone, so it keeps the look
Saneroki chose. A crop's box is (left, top, right, bottom) in its picture's pixels.
  python3 dev/imagegen/sets/interface/refs.py   ->  assets/generated/interface/crops/<part>.png, crops.jpg
"""
import os
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../..")
REFS = os.path.join(ROOT, "assets/Concept art/UI style")
OUT = os.path.join(ROOT, "assets/generated/interface/crops")

# part: (picture, box, what the guide says it is)
CROPS = {
    "title-bar": ("title-bar.png", (272, 60, 754, 124), "the title bar: a slim stitched leather strip, a metal fitting at each end"),
    "edge-left": ("edges-and-buttons.png", (196, 90, 246, 920), "the window's left edge: thin stitched leather binding"),
    "edge-right": ("edges-and-buttons.png", (768, 90, 834, 925), "the window's right edge: the book's edge, a clasp at the side"),
    "corner": ("edges-and-buttons.png", (194, 86, 264, 154), "a top corner of the binding with its metal cap"),
    "patch-wide": ("edges-and-buttons.png", (255, 826, 348, 872), "a hard button: a stitched leather patch"),
    "patch-square": ("guild-board.png", (1438, 30, 1508, 100), "a square leather patch, a piece for buttons of any width"),
    "dropdown-band": ("dropdown-bands.png", (398, 80, 466, 224), "a leather band hanging from the top border"),
    "buckle": ("dropdown-bands.png", (792, 466, 878, 548), "the buckle on the binding"),
    "top-tab-patch": ("top-tabs.png", (352, 101, 472, 137), "a top tab: darker patch style"),
    "top-tabs-patch": ("top-tabs.png", (70, 98, 950, 139), "the row of patch tabs under the title bar"),
    "top-tab-drawn": ("guild-board.png", (420, 122, 522, 167), "a top tab: drawn on the paper"),
    "top-tabs-drawn": ("guild-board.png", (192, 120, 1014, 169), "the row of drawn tabs"),
    "side-tab": ("side-tabs.png", (106, 333, 172, 394), "a side tab: a leather bookmark out of the left edge"),
    "chat-bubble": ("chat-bubble.png", (188, 70, 774, 226), "a chat bubble: paper, pencil outline, the tail"),
    "stat-strip": ("title-bar.png", (226, 203, 338, 280), "a paper strip hanging over the border (a slot's stats)"),
}


# crops whose label is covered in code (the paper of its own tone over the dark letters inside this box,
# fractions of the crop), for parts no seed of the edit painted without it
CLEAN = {"top-tab-patch": (0.12, 0.18, 0.88, 0.82), "title-bar": (0.3, 0.15, 0.7, 0.85)}
# crops whose inside is smoothed in code before the edit paints it anew (marks that the edit kept otherwise):
# the inside blurred to its own leather and a fine grain laid over it
SMOOTH = {"dropdown-band": (0.16, 0.06, 0.84, 0.8)}


def clean(img, inner):
    """The marks inside inner (letters darker or lighter than the part) covered by the part's own tone, softly."""
    import numpy as np
    from PIL import ImageFilter
    w, h = img.size
    x0, y0, x1, y1 = round(inner[0] * w), round(inner[1] * h), round(inner[2] * w), round(inner[3] * h)
    region = img.crop((x0, y0, x1, y1))
    lum = np.asarray(region.convert("L"))
    tone = np.median(np.asarray(region).reshape(-1, 3), axis=0).astype(np.uint8)
    dark = region.convert("L").point(lambda v, m=float(np.percentile(lum, 50)): 255 if abs(v - m) > 14 else 0)  # dark or light letters
    grow = max(5, (h // 18) | 1)                       # filters sized to the part, small crop or large element
    mask = dark.filter(ImageFilter.MaxFilter(grow)).filter(ImageFilter.GaussianBlur(max(1.5, h / 90)))
    grain = np.random.default_rng(7).normal(0, 5, (region.height, region.width, 1))
    fill = Image.fromarray((np.full((region.height, region.width, 3), tone, dtype=np.float32) + grain).clip(0, 255).astype(np.uint8))
    fill = fill.filter(ImageFilter.GaussianBlur(0.6))
    img.paste(Image.composite(fill, region, mask), (x0, y0))
    return img


def smooth(img, inner, seed=1):
    import numpy as np
    from PIL import ImageFilter
    w, h = img.size
    box = (round(inner[0] * w), round(inner[1] * h), round(inner[2] * w), round(inner[3] * h))
    region = img.crop(box).filter(ImageFilter.GaussianBlur(9))
    grain = np.random.default_rng(seed).normal(0, 7, (region.height, region.width, 1))
    region = Image.fromarray((np.asarray(region, dtype=np.float32) + grain).clip(0, 255).astype(np.uint8))
    mask = Image.new("L", region.size, 0)
    from PIL import ImageDraw as D
    D.Draw(mask).rectangle((3, 3, region.width - 4, region.height - 4), fill=255)
    img.paste(region, box[:2], mask.filter(ImageFilter.GaussianBlur(2)))
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    tiles = []
    for name, (picture, box, _) in CROPS.items():
        crop = Image.open(os.path.join(REFS, picture)).convert("RGB").crop(box)
        crop.save(os.path.join(OUT, name + ".png"))
        if name in CLEAN:
            clean(crop.copy(), CLEAN[name]).convert("RGBA").save(os.path.join(OUT, name + "-clean.png"))
        if name in SMOOTH:
            smooth(crop.copy(), SMOOTH[name]).save(os.path.join(OUT, name + "-plain.png"))
        tiles.append((name, crop))
    # one sheet to check the boxes
    w = 300
    sheet = Image.new("RGB", (w * 5, w * ((len(tiles) + 4) // 5)), (40, 40, 40))
    d = ImageDraw.Draw(sheet)
    for i, (name, crop) in enumerate(tiles):
        c = crop.copy()
        c.thumbnail((w - 10, w - 24))
        x, y = (i % 5) * w, (i // 5) * w
        sheet.paste(c, (x + 5, y + 20))
        d.text((x + 5, y + 4), name, fill=(255, 255, 0))
    sheet.save(os.path.join(OUT, "..", "crops.jpg"), quality=90)
    print(f"{len(tiles)} crops in {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
