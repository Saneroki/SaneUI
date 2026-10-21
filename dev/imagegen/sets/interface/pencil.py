#!/usr/bin/env python3
"""Pencil lines only (Saneroki, 2026-10-21: tabs, boxes, buttons and lines on the paper are pencil lines and corners
on transparency, so they take the page's own colour). A part drawn on paper (#14's tab, its variants) becomes its
pencil alone: each pixel's darkness against the paper round it is the line's strength, its colour graphite.
  python3 dev/imagegen/sets/interface/pencil.py [picture ...]
    default: the decided drawn tab and the variants of pencil.txt  ->  assets/generated/interface/pencil/<name>.png
"""
import glob, os, sys
import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "../../../..")
OUT = os.path.join(ROOT, "assets/generated/interface/pencil")
LEAD = (34, 27, 21)        # graphite on the dark paper
FLOOR = 34                 # darkness below this against its surroundings is grain or shading, not a line
GAIN = 6.0                 # darkness to line strength: steep, so lines are crisp
LINE = 0.012               # the widest a pencil line is, as a share of the part's height: anything broader
                           # (shading, a shadow, a smudge) is not kept


# parts whose middle holds a label: lines kept only outside this box (fractions of the part)
INSIDE = {"top-tab-drawn-1": (0.13, 0.2, 0.87, 0.8), "pencil-box": (0.13, 0.2, 0.87, 0.8)}


def lines(img, inside=None):
    """The pencil of a part on paper, as graphite with transparency; inside: a box cleared of everything."""
    rgba = img.convert("RGBA")
    shape = np.asarray(rgba.getchannel("A"), dtype=np.float32) / 255
    lum = np.asarray(rgba.convert("L"), dtype=np.float32)
    # only thin dark lines (Saneroki: clean, sharp pencil lines, never smudged shading): each pixel against the
    # lightest pixel within a line's width of it, so broad shading and shadows, as dark as their surroundings
    # there, drop out
    k = max(3, (round(img.height * LINE) * 2 + 1) | 1)
    around = np.asarray(rgba.convert("L").filter(ImageFilter.MaxFilter(k)), dtype=np.float32)
    dark = np.clip((around - lum - FLOOR) * GAIN, 0, 255) * shape
    dark = np.asarray(Image.fromarray(dark.astype(np.uint8)).filter(ImageFilter.MedianFilter(3)), dtype=np.float32)
    out = np.zeros((img.height, img.width, 4), dtype=np.uint8)
    out[..., :3] = LEAD
    if inside:
        h, w = dark.shape
        dark[round(inside[1] * h):round(inside[3] * h), round(inside[0] * w):round(inside[2] * w)] = 0
    out[..., 3] = dark.astype(np.uint8)
    out = Image.fromarray(out, "RGBA")
    box = out.getchannel("A").point(lambda v: 255 if v > 20 else 0).getbbox()
    return out.crop(box) if box else out


def main(paths):
    os.makedirs(OUT, exist_ok=True)
    if not paths:
        paths = [os.path.join(ROOT, "assets/Concept art/UI style/elements/top-tab-drawn-1.png")]
        paths += sorted(glob.glob(os.path.join(ROOT, "assets/generated/interface/variants/pencil-*.png")))
        hires = os.path.join(ROOT, "assets/generated/interface/hires/pencil-box.png")
        if os.path.exists(hires):
            paths.append(hires)
    for p in paths:
        name = os.path.splitext(os.path.basename(p))[0]
        lines(Image.open(p), INSIDE.get(name)).save(os.path.join(OUT, name + ".png"))
        print(name)


if __name__ == "__main__":
    main(sys.argv[1:])
