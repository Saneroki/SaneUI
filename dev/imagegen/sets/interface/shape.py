#!/usr/bin/env python3
"""Parts reshaped in code from the kept elements (Doc/guides/interface-style.md, Saneroki 2026-10-21):
  top-tab-arrow   the patch tab (#39, top-tab-patch-3) as an arrow pointing right: its top and bottom stay, its left
                  end is cut in as a V and its right end runs out into a point, so tabs side by side lock into
                  each other, each tip in the next one's cut. Its label is covered first.
The shape goes to crops/ as the edit's picture (elements-new.txt finishes its cut edges), and a strip of four is
drawn to show how they lock.
  python3 dev/imagegen/sets/interface/shape.py
"""
import os, random, sys
from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "../../../..")
sys.path.insert(0, HERE)
import refs  # noqa: E402

ELEMENTS = os.path.join(ROOT, "assets/generated/interface/elements")
CROPS = os.path.join(ROOT, "assets/generated/interface/crops")
DEPTH = 0.5      # how far the point (and the cut) reaches, as a share of the tab's height


def trimmed(name):
    img = Image.open(os.path.join(ELEMENTS, name + ".png")).convert("RGBA")
    return img.crop(img.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox())


def arrow(tab, depth=DEPTH):
    """The tab with a V cut into its left end and a point at its right: the middle stretched by the point's
    length so the tab keeps its own width between cut and point."""
    w, h = tab.size
    d = round(h * depth)
    # the part's own edge (its rim) is kept along the new diagonal ends: the tab is widened by d, its middle
    # its even middle stretched over the whole length, then cut to the arrow
    cap = round(w * 0.12)                       # the old rounded ends are left out: the new ends replace them
    wide = tab.crop((cap, 0, w - cap, h)).resize((w + d, h), Image.LANCZOS)
    W = w + d
    rnd = random.Random(5)

    def worn(a, b, n=14):
        """An edge from a to b that wanders a little, like worn leather, not a clean cut."""
        pts = [a]
        for i in range(1, n):
            t = i / n
            pts.append((a[0] + (b[0] - a[0]) * t + rnd.uniform(-1, 1) * h * 0.012,
                        a[1] + (b[1] - a[1]) * t + rnd.uniform(-1, 1) * h * 0.012))
        return pts + [b]

    outline = ([(0, 0), (W - d, 0)] + worn((W - d, 0), (W - 1, h / 2)) + worn((W - 1, h / 2), (W - d, h - 1))
               + [(0, h - 1)] + worn((0, h - 1), (d, h / 2)) + worn((d, h / 2), (0, 0)))
    shape = Image.new("L", (W, h))
    ImageDraw.Draw(shape).polygon(outline, fill=255)
    shape = shape.filter(ImageFilter.GaussianBlur(h * 0.006))
    out = Image.new("RGBA", (W, h))
    out.paste(wide, (0, 0), ImageChops.multiply(shape, wide.getchannel("A")))
    # a soft, worn rim along the new ends, darker toward the edge, like the part's own edges
    inner = shape.filter(ImageFilter.MinFilter(max(3, (h // 30) | 1))).filter(ImageFilter.GaussianBlur(h * 0.02))
    rim = ImageChops.subtract(shape, inner)
    dark = Image.new("RGBA", (W, h), (46, 30, 18, 0))
    dark.putalpha(rim.point(lambda v: int(v * 0.55)))
    out.alpha_composite(dark)
    # a row of stitches along each diagonal end, a little in from the edge, as along the top and bottom
    st = ImageDraw.Draw(out)
    inset, step, dash = h * 0.09, h * 0.07, h * 0.035
    for (ax, ay), (bx, by) in (((W - d - inset, inset), (W - 1 - inset * 1.6, h / 2)), ((W - 1 - inset * 1.6, h / 2), (W - d - inset, h - inset)),
                               ((inset, inset), (d + inset * 1.2, h / 2)), ((d + inset * 1.2, h / 2), (inset, h - inset))):
        length = ((bx - ax) ** 2 + (by - ay) ** 2) ** 0.5
        n = int(length / step)
        for i in range(n):
            t0, t1 = i / n, min(1, i / n + dash / length)
            st.line([(ax + (bx - ax) * t0, ay + (by - ay) * t0), (ax + (bx - ax) * t1, ay + (by - ay) * t1)],
                    fill=(196, 160, 112, 200), width=max(2, h // 70))
    return out, d


def main():
    tab = trimmed("top-tab-patch-3")
    rgb = refs.clean(tab.convert("RGB"), refs.CLEAN["top-tab-patch"])
    rgb.putalpha(tab.getchannel("A"))
    shaped, d = arrow(rgb)
    shaped.save(os.path.join(CROPS, "top-tab-arrow.png"))
    small = shaped.resize((round(shaped.width * 60 / shaped.height), 60), Image.LANCZOS)
    dd = round(d * 60 / shaped.height)
    strip = Image.new("RGBA", (4 * (small.width - dd) + dd + 20, 80), (118, 110, 100, 255))
    for i in range(4):
        strip.alpha_composite(small, (10 + i * (small.width - dd), 10))
    strip.convert("RGB").save(os.path.join(CROPS, "..", "arrow-strip.png"))
    print("arrow tab:", shaped.size)


if __name__ == "__main__":
    main()
