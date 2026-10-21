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
CLEAN = {"top-tab-patch": (0.12, 0.18, 0.88, 0.82)}


def clean(img, inner):
    """The dark marks inside inner covered by the median tone of the light pixels there, softly."""
    import numpy as np
    from PIL import ImageFilter
    w, h = img.size
    x0, y0, x1, y1 = round(inner[0] * w), round(inner[1] * h), round(inner[2] * w), round(inner[3] * h)
    region = img.crop((x0, y0, x1, y1))
    lum = np.asarray(region.convert("L"))
    tone = np.median(np.asarray(region)[lum > np.percentile(lum, 50)], axis=0).astype(np.uint8)
    dark = region.convert("L").point(lambda v, m=float(np.percentile(lum, 50)): 255 if v < m - 18 else 0)
    mask = dark.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1.5))
    fill = Image.new("RGB", region.size, tuple(int(v) for v in tone))
    fill = Image.blend(fill, region.filter(ImageFilter.GaussianBlur(6)), 0.5)
    img.paste(Image.composite(fill, region, mask), (x0, y0))
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    tiles = []
    for name, (picture, box, _) in CROPS.items():
        crop = Image.open(os.path.join(REFS, picture)).convert("RGB").crop(box)
        crop.save(os.path.join(OUT, name + ".png"))
        if name in CLEAN:
            clean(crop.copy(), CLEAN[name]).convert("RGBA").save(os.path.join(OUT, name + "-clean.png"))
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
