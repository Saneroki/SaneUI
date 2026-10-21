#!/usr/bin/env python3
"""Layout guides for Qwen's ControlNet (dev/imagegen/workflows/qwen21-cn-t2i.json): compact panels drawn as
white lines on black, the panel's outline taken round its content (slots, portrait, rows) a few pixels out, so
the panel has no room to spare. The model paints material and detail onto them; guided.txt uses them.
  python3 dev/imagegen/sets/ui-panels/guides.py   ->  assets/generated/ui-panels/guides/<name>.png
"""
import math, os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../../../assets/generated/ui-panels/guides")
S = 1024
SLOT = 74  # an equipment slot


def outline(shapes, pad):
    """The panel round its shapes: their union grown by pad, as a line."""
    mask = Image.new("L", (S, S), 0)
    d = ImageDraw.Draw(mask)
    for kind, box in shapes:
        (d.ellipse if kind == "ellipse" else d.polygon if kind == "polygon" else d.rounded_rectangle)(box, fill=255) \
            if kind != "rect" else d.rounded_rectangle(box, radius=10, fill=255)
    grown = mask.filter(ImageFilter.MaxFilter(pad * 2 + 1)).filter(ImageFilter.GaussianBlur(6)).point(lambda v: 255 if v > 128 else 0)
    edge = ImageChops.subtract(grown, grown.filter(ImageFilter.MinFilter(9)))
    return edge


def draw(name, shapes, pad=26, extra=None):
    img = Image.new("L", (S, S), 0)
    img = ImageChops.lighter(img, outline(shapes, pad))
    d = ImageDraw.Draw(img)
    for kind, box in shapes:
        if kind == "rect":
            d.rounded_rectangle(box, radius=8, outline=255, width=3)
        elif kind == "ellipse":
            d.ellipse(box, outline=255, width=3)
        elif kind == "polygon":
            d.polygon(box, outline=255, width=3)
    if extra:
        extra(d)
    os.makedirs(OUT, exist_ok=True)
    img.convert("RGB").save(os.path.join(OUT, name + ".png"))


def slot(cx, cy, s=SLOT):
    return ("rect", (cx - s / 2, cy - s / 2, cx + s / 2, cy + s / 2))


def figure():
    """The hero's place: a plain portrait area (a drawn figure was painted in as a stick figure)."""
    return [("rect", (440, 150, 584, 800))]


def doll_hug():
    slots = [(512, 70), (412, 170), (612, 170), (370, 270), (654, 270), (362, 370), (662, 370),
             (370, 470), (654, 470), (395, 570), (629, 570), (400, 670), (624, 670), (405, 770), (619, 770),
             (420, 870), (512, 890), (604, 870), (512, 970 - 40)]
    draw("doll-hug", figure() + [slot(x, y, 66) for x, y in slots], pad=18)


def doll_shield():
    shield = [(220, 140), (804, 140), (804, 520), (512, 920), (220, 520)]
    slots = [(290, 210), (290, 300), (290, 390), (290, 480), (734, 210), (734, 300), (734, 390), (734, 480),
             (350, 590), (420, 680), (674, 590), (604, 680), (470, 780), (554, 780), (512, 860)]
    shapes = [("polygon", shield), ("rect", (390, 190, 634, 560))] + [slot(x, y, 66) for x, y in slots]
    draw("doll-shield", shapes, pad=10)


def doll_wings():
    arch = [("rect", (420, 160, 604, 760)), ("ellipse", (420, 70, 604, 254))]
    left = [(512 - 190 - 40 * math.sin(i / 7 * math.pi), 200 + i * 80) for i in range(8)]
    right = [(512 + 190 + 40 * math.sin(i / 7 * math.pi), 200 + i * 80) for i in range(8)]
    weapons = [(430, 850), (512, 870), (594, 850)]
    draw("doll-wings", arch + [slot(x, y, 70) for x, y in left + right + weapons], pad=16)


def doll_hex():
    shapes = []
    def hexagon(cx, cy, r):
        return ("polygon", [(cx + r * math.cos(math.radians(60 * k + 30)), cy + r * math.sin(math.radians(60 * k + 30))) for k in range(6)])
    shapes.append(hexagon(512, 480, 190))
    ring = 300
    for k in range(18):
        a = math.radians(-90 + k * 20)
        shapes.append(hexagon(512 + ring * math.cos(a), 480 + ring * math.sin(a), 52))
    draw("doll-hex", shapes, pad=12)


def doll_strip():
    shapes = [("rect", (392, 60, 632, 300))]
    for i in range(10):
        shapes.append(slot(452 if i % 2 == 0 else 572, 350 + i * 60, 64))
    draw("doll-strip", shapes, pad=14)


def book_fan():
    shapes = []
    for row, r in enumerate((300, 390, 480)):
        for k in range(9 - row):
            a = math.radians(-150 + k * (120 / (8 - row)))
            shapes.append(slot(512 + r * math.cos(a), 760 + r * math.sin(a), 70))
    shapes.append(("rect", (330, 800, 694, 870)))
    draw("book-fan", shapes, pad=16)


def bags():
    shapes = []
    y = 90
    for cat, n in (("a", 22), ("b", 15), ("c", 11), ("d", 18), ("e", 7)):
        shapes.append(("rect", (120, y, 904, y + 26)))
        y += 34
        cols = 11
        for i in range(n):
            shapes.append(slot(156 + (i % cols) * 71, y + 32 + (i // cols) * 71, 64))
        y += 71 * ((n + cols - 1) // cols) + 14
    draw("bags", shapes, pad=10)


if __name__ == "__main__":
    for f in (doll_hug, doll_shield, doll_wings, doll_hex, doll_strip, book_fan, bags):
        f()
    print(sorted(os.listdir(OUT)))
