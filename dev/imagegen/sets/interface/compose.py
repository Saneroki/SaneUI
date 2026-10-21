#!/usr/bin/env python3
"""Views put together in code from the decided parts (Doc/guides/interface-style.md), the way the game will draw
them: the leather parts sliced and repeated, the paper from paper.py, pencil lines drawn by code, text in Kalam
with the paper's grain over it, titles and labels pressed into the leather, game icons from references/. Nothing
here is painted by a model except the parts themselves (elements-*.txt, each from its crop of a pick), so the
layout and the look cannot drift. No model pass runs over a view.
  python3 dev/imagegen/sets/interface/compose.py [view ...]   ->  assets/generated/interface/views/<view>.png
Where each part comes from is in SOURCE.
"""
import glob, math, os, random, sys
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "../../../..")
sys.path.insert(0, HERE)
import paper  # noqa: E402

ELEMENTS = os.path.join(ROOT, "assets/generated/interface/elements")
CROPS = os.path.join(ROOT, "assets/generated/interface/crops")
REFS = os.path.join(ROOT, "assets/Concept art/UI style")
ICONS = os.path.join(ROOT, "references/BlizzardInterfaceArt/Interface/ICONS")
OUT = os.path.join(ROOT, "assets/generated/interface/views")
KALAM = os.path.join(ROOT, "assets/fonts/Kalam/Kalam-{}.ttf")
LEATHER_FONT = "/usr/share/fonts/noto/NotoSerif-Regular.ttf"   # a stand-in: no leather font is decided yet

# Where each part comes from (Saneroki's review of round 1, 2026-10-21; the elements he did not name are archived):
#   a number: that seed of the element; ("crop", file): a crop of a pick from refs.py (cleaned there);
#   ("clean", seed, box): that seed with its label covered in code (box as fractions of the part)
SOURCE = {"edge-left": 3, "edge-right": 1,                   # #13-18 all fine
          "patch-wide": 2,                                   # #23: every leather patch and button
          "top-tab-drawn": ("clean", 1, (0.08, 0.12, 0.92, 0.88)),   # #34: its pencil lines; text by code
          "top-tab-arrow": 1,                                # #39 shaped as an arrow (shape.py, elements-arrow.txt)
          "dropdown-band": 1,                                # a plain band (elements-band.txt)
          "title-bar": ("crop", "title-bar-clean")}          # the pick (#61) itself, its title covered
FALLBACK = {"top-tab-arrow": "top-tab-arrow", "dropdown-band": "dropdown-band-plain"}   # crops until rendered
LEAD = (58, 52, 46)            # pencil grey
BG = (24, 21, 18)              # behind the windows
CLASS = {"Warrior": (199, 156, 110), "Mage": (63, 199, 235), "Priest": (230, 230, 230), "Rogue": (255, 244, 104),
         "Druid": (255, 124, 10), "Hunter": (170, 211, 114), "Paladin": (244, 140, 186), "Warlock": (135, 136, 238),
         "Shaman": (0, 112, 221)}


# ---- parts ------------------------------------------------------------------------------------------------

def part(name):
    """A part from its source (SOURCE), trimmed to what it covers. Only decided parts: anything not in SOURCE is
    refused, so nothing discarded or never named can come in."""
    if name not in SOURCE:
        raise ValueError(f"{name} is not a decided part (Doc/guides/interface-style.md); add it to SOURCE first")
    src = SOURCE[name]
    if isinstance(src, tuple) and src[0] == "crop":
        img = Image.open(os.path.join(CROPS, src[1] + ".png")).convert("RGBA")
    else:
        seed = src[1] if isinstance(src, tuple) else src
        f = os.path.join(ELEMENTS, f"{name}-{seed}.png")
        if not os.path.exists(f):
            f = os.path.join(CROPS, FALLBACK.get(name, name) + ".png")
        img = Image.open(f).convert("RGBA")
    box = img.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
    img = img.crop(box) if box else img
    if isinstance(src, tuple) and src[0] == "clean":
        import refs
        rgb = refs.clean(img.convert("RGB"), src[2])
        rgb.putalpha(img.getchannel("A"))
        img = rgb
    return img


def three(img, length, thick, horizontal=True, cap=0.18):
    """A strip of any length: the ends kept, the middle repeated (not stretched)."""
    if not horizontal:
        return three(img.rotate(90, expand=True), length, thick, True, cap).rotate(-90, expand=True)
    s = thick / img.height
    img = img.resize((max(3, round(img.width * s)), thick), Image.LANCZOS)
    c = max(1, round(img.width * cap))
    left, right, mid = img.crop((0, 0, c, thick)), img.crop((img.width - c, 0, img.width, thick)), img.crop((c, 0, img.width - c, thick))
    out = Image.new("RGBA", (length, thick))
    x = c
    while x < length - c:
        out.alpha_composite(mid.crop((0, 0, min(mid.width, length - c - x), thick)), (x, 0))
        x += mid.width
    out.alpha_composite(left, (0, 0))
    out.alpha_composite(right, (length - c, 0))
    return out


def nine(img, w, h, l, t, r, b):
    """A part stretched to w x h by nine slices: its margins (fractions of the part) drawn at the part's scale
    for that height, the rest stretched."""
    W, H = img.size
    L, T, R, B = round(W * l), round(H * t), round(W * r), round(H * b)
    k = min(h / H, w / W, 1.0) if (T + B) * min(h / H, 1.0) < h else h / (T + B + 2)
    dl, dt, dr, db = round(L * k), round(T * k), round(R * k), round(B * k)
    out = Image.new("RGBA", (w, h))
    xs = [(0, L, 0, dl), (L, W - R, dl, w - dr), (W - R, W, w - dr, w)]
    ys = [(0, T, 0, dt), (T, H - B, dt, h - db), (H - B, H, h - db, h)]
    for sx0, sx1, dx0, dx1 in xs:
        for sy0, sy1, dy0, dy1 in ys:
            if sx1 > sx0 and sy1 > sy0 and dx1 > dx0 and dy1 > dy0:
                out.alpha_composite(img.crop((sx0, sy0, sx1, sy1)).resize((dx1 - dx0, dy1 - dy0), Image.LANCZOS), (dx0, dy0))
    return out


def tint(img, color, keep=0.35):
    """A leather part in another colour (side tabs): its light and grain kept."""
    grey = ImageOps.autocontrast(ImageOps.grayscale(img.convert("RGB")), cutoff=2)
    col = ImageOps.colorize(grey, tuple(int(v * 0.3) for v in color), tuple(min(255, int(v * 1.45)) for v in color), color)
    out = Image.blend(col, img.convert("RGB"), keep).convert("RGBA")
    out.putalpha(img.getchannel("A"))
    return out


def icon(pattern, size, seed=0):
    """A game icon from references/ (the first match of the pattern, or one picked by seed)."""
    files = sorted(glob.glob(os.path.join(ICONS, pattern)))
    if not files:
        return Image.new("RGBA", (size, size), (90, 80, 70, 255))
    img = Image.open(files[seed % len(files)]).convert("RGBA")
    img = img.crop((4, 4, img.width - 4, img.height - 4))  # the game's own rim cut away
    return img.resize((size, size), Image.LANCZOS)


def sketch(img, size, disc=None, ring=True):
    """A game icon drawn as a pencil sketch: its edges as grey strokes in a round, on nothing or on a disc of
    paper of the colour disc."""
    g = ImageOps.grayscale(img.convert("RGB")).resize((size * 2, size * 2), Image.LANCZOS)
    edges = g.filter(ImageFilter.FIND_EDGES).point(lambda v: min(255, int(v * 2.4)))
    shade = ImageOps.invert(g).point(lambda v: int(v * 0.35))
    a = ImageChops.lighter(edges, shade).resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size))
    ImageDraw.Draw(mask).ellipse((1, 1, size - 2, size - 2), fill=255)
    a = ImageChops.multiply(a, mask)
    lines = Image.new("RGBA", (size, size), LEAD + (0,))
    lines.putalpha(a)
    out = Image.new("RGBA", (size, size))
    if disc:
        ImageDraw.Draw(out).ellipse((1, 1, size - 2, size - 2), fill=disc + (255,))
    out.alpha_composite(lines)
    if ring:
        ImageDraw.Draw(out).ellipse((1, 1, size - 2, size - 2), outline=LEAD + (170,), width=2)
    return out


# ---- drawing on paper and leather -------------------------------------------------------------------------

def font(size, weight="Regular"):
    return ImageFont.truetype(KALAM.format(weight), size)


OUTLINE = (34, 28, 22)          # round letters in a colour that is hard to read on the paper


def write(canvas, xy, text, size=20, weight="Regular", color=LEAD, alpha=225, anchor="la", outline=False):
    """Kalam in pencil with the paper's grain over it; outline: a thin dark line round the letters, for colours
    hard to read on the paper (the game's class colours)."""
    layer = Image.new("RGBA", canvas.size)
    ImageDraw.Draw(layer).text(xy, text, font=font(size, weight), fill=color + (alpha,), anchor=anchor,
                               stroke_width=1 if outline else 0, stroke_fill=OUTLINE + (alpha,))
    rnd = np.random.default_rng(abs(hash(text)) % 2**32)
    grain = Image.fromarray((rnd.uniform(0.62, 1.0, (canvas.height, canvas.width)) * 255).astype(np.uint8))
    layer.putalpha(ImageChops.multiply(layer.getchannel("A"), grain.filter(ImageFilter.GaussianBlur(0.6))))
    canvas.alpha_composite(layer)


def press(canvas, xy, text, size=22, anchor="mm", font_file=LEATHER_FONT):
    """Letters pressed into leather: a dark cut with a faint light lip below it."""
    f = ImageFont.truetype(font_file, size)
    d = ImageDraw.Draw(canvas)
    x, y = xy
    d.text((x, y + 1), text, font=f, fill=(225, 190, 145, 70), anchor=anchor)
    d.text((x, y - 1), text, font=f, fill=(10, 6, 3, 120), anchor=anchor)
    d.text((x, y), text, font=f, fill=(48, 30, 18, 215), anchor=anchor)


def line(canvas, a, b, alpha=150, width=2, seed=0):
    """A pencil stroke: two slightly wandering passes."""
    d = ImageDraw.Draw(canvas)
    rnd = random.Random(seed or hash((a, b)))
    for k, al in ((0, alpha), (1, alpha // 2)):
        n = max(2, int(math.dist(a, b) / 40))
        pts = []
        for i in range(n + 1):
            t = i / n
            pts.append((a[0] + (b[0] - a[0]) * t + rnd.uniform(-0.8, 0.8) + k * 0.6,
                        a[1] + (b[1] - a[1]) * t + rnd.uniform(-0.8, 0.8) + k * 0.6))
        d.line(pts, fill=LEAD + (al,), width=width - k, joint="curve")


def box(canvas, rect, alpha=150, width=2, seed=0):
    x0, y0, x1, y1 = rect
    for i, (a, b) in enumerate((((x0, y0), (x1, y0)), ((x1, y0), (x1, y1)), ((x1, y1), (x0, y1)), ((x0, y1), (x0, y0)))):
        line(canvas, a, b, alpha, width, seed * 7 + i + 1)


def slot(canvas, x, y, s, img):
    """A gear or item slot on paper: a pencil square, the icon inside."""
    canvas.alpha_composite(img.resize((s - 8, s - 8), Image.LANCZOS), (x + 4, y + 4))
    box(canvas, (x, y, x + s, y + s), 170, 2, x * 31 + y)


# ---- the window -------------------------------------------------------------------------------------------

# The window's frame is the decided border itself (edges-and-buttons.png, #12; Saneroki: the borders were decided),
# cut out of it at its own scale, never re-painted: its corners with their metal caps as they are, its edges
# repeated from plain stretches of them, the clasp on the right edge, the page stack and the strap along the
# bottom. Boxes in the picture's pixels.
FRAME = "edges-and-buttons.png"
FRAME_CUT = {"tl": (196, 88, 262, 138), "top": (360, 88, 520, 138), "tr": (744, 88, 816, 138),
             "left": (196, 300, 226, 600), "right": (768, 160, 814, 380), "clasp": (768, 384, 836, 506),
             "bl": (196, 826, 262, 928), "bottom": (450, 826, 640, 928), "br": (744, 826, 816, 928)}
TITLE_BAR = ("title-bar.png", (272, 60, 754, 124))     # #61: the title bar, at its own height


class Window:
    """A window of the journal look: #12's frame round the paper (its corners, edges, clasp, page stack and bottom
    strap), #61's title bar laid over its top edge with the title pressed in, brown leather patches (#23) as the
    side tabs and buttons, plain bands hanging from the top. The content goes on the page, from self.inner."""

    MARGIN = 64

    def __init__(self, w, h, title, side_tabs=(), buttons=(), bands=(), seed="window", margin=None):
        self.w, self.h, self.title = w, h, title
        self.MARGIN = M = margin or self.MARGIN
        src = Image.open(os.path.join(REFS, FRAME)).convert("RGBA")
        self.cut = {k: src.crop(v) for k, v in FRAME_CUT.items()}
        # the paper reaches each edge's inner side; the corners, wider than the edges, lie over it
        L, R = self.cut["left"].width, self.cut["right"].width
        T, B = self.cut["top"].height, self.cut["bottom"].height
        self.L, self.T, self.R, self.B = L, T, R, B
        self.canvas = Image.new("RGBA", (w + 2 * M, h + 2 * M), BG + (255,))
        self.inner = (M + L - 4, M + T - 4, M + w - R + 4, M + h - B + 4)
        x0, y0, x1, y1 = self.inner
        self.canvas.alpha_composite(paper.page(x1 - x0, y1 - y0, seed), (x0, y0))
        self.side_tabs, self.buttons, self.bands = side_tabs, buttons, bands

    def frame(self):
        c, M, w, h, k = self.canvas, self.MARGIN, self.w, self.h, self.cut
        L, T, R, B = self.L, self.T, self.R, self.B

        def run(tile, length, horizontal, blend=0.3):
            """The tile repeated over length, each repeat fading into the last over a share of the tile, so
            no seam shows."""
            if not horizontal:
                return run(tile.rotate(90, expand=True), length, True, blend).rotate(-90, expand=True)
            tw, th = tile.size
            o = max(2, int(tw * blend))
            ramp = Image.linear_gradient("L").rotate(90, expand=True).resize((o, th))   # 0 at left, 255 at right
            fade = tile.copy()
            fade.putalpha(ImageChops.multiply(tile.getchannel("A"), Image.new("L", tile.size, 255).copy()))
            a = fade.getchannel("A")
            a.paste(ImageChops.multiply(a.crop((0, 0, o, th)), ramp), (0, 0))
            fade.putalpha(a)
            out = Image.new("RGBA", (length, th))
            out.alpha_composite(tile, (0, 0))
            p = tw - o
            while p < length:
                out.alpha_composite(fade, (p, 0))
                p += tw - o
            return out

        c.alpha_composite(run(k["top"], w, True), (M, M))
        c.alpha_composite(run(k["bottom"], w, True), (M, M + h - B))
        c.alpha_composite(run(k["left"], h - T - B, False), (M, M + T))
        c.alpha_composite(run(k["right"], h - T - B, False), (M + w - R, M + T))
        c.alpha_composite(k["clasp"], (M + w - R, M + (h - k["clasp"].height) // 2))
        c.alpha_composite(k["tl"], (M, M))
        c.alpha_composite(k["tr"], (M + w - k["tr"].width, M))
        c.alpha_composite(k["bl"], (M, M + h - k["bl"].height))
        c.alpha_composite(k["br"], (M + w - k["br"].width, M + h - k["br"].height))

    def finish(self):
        c, M, w, h = self.canvas, self.MARGIN, self.w, self.h
        for i, ico in enumerate(self.side_tabs):
            y = M + self.T + 30 + i * 50
            c.alpha_composite(three(part("patch-wide"), 50, 42, cap=0.2), (M - 32, y))
            if ico is not None:
                g = ImageOps.grayscale(ico.convert("RGB")).resize((22, 22), Image.LANCZOS)
                mark = Image.new("RGBA", (22, 22), (30, 18, 10, 0))
                mark.putalpha(ImageOps.invert(g).point(lambda v: int(v * 0.6)))
                c.alpha_composite(mark, (M - 25, y + 10))
        self.frame()
        pic, box = TITLE_BAR
        bar = Image.open(os.path.join(REFS, pic)).convert("RGBA").crop(box)
        bar_rgb = __import__("refs").clean(bar.convert("RGB"), (0.3, 0.15, 0.7, 0.85))
        bar_rgb.putalpha(bar.getchannel("A"))
        bw = min(w - 60, max(320, len(self.title) * 26 + 220))
        c.alpha_composite(three(bar_rgb, bw, bar.height, cap=0.16), (M + (w - bw) // 2, M - 12))
        press(c, (M + w // 2, M - 12 + bar.height // 2), self.title.upper(), 22)
        c.alpha_composite(three(part("patch-wide"), 34, 30, cap=0.3), (M + w - 54, M + 4))
        press(c, (M + w - 37, M + 18), "x", 17)
        for x, label in self.bands:
            band = three(part("dropdown-band"), 100, 38, horizontal=False, cap=0.12)
            c.alpha_composite(band, (M + x, M + self.T - 16))
            press(c, (M + x + 19, M + self.T + 32), label, 12)
        x = M + self.L + 40
        for label in self.buttons:
            width = 34 + len(label) * 11
            c.alpha_composite(three(part("patch-wide"), width, 32, cap=0.2), (x, M + h - self.B + 6))
            press(c, (x + width // 2, M + h - self.B + 22), label, 14)
            x += width + 8
        return c

    def stat_strip(self, rect, lines, outside=None):
        """A paper strip with a slot's stats; outside: 'left' or 'right' if it hangs over the border."""
        x0, y0, x1, y1 = rect
        strip = nine(part("stat-strip"), x1 - x0, y1 - y0, 0.12, 0.2, 0.12, 0.2)
        self.canvas.alpha_composite(strip, (x0, y0))
        for i, (text, size) in enumerate(lines):
            write(self.canvas, (x0 + 10, y0 + 6 + i * (size + 1)), text, size)


def top_tabs(canvas, x, y, labels, style, active=0, height=34):
    """The row of tabs under the title bar: 'patch' (the arrow patches, #39, each tip in the next one's cut) or
    'drawn' (pencil on the paper, #34); the labels by code (pressed into the patches, Kalam on the paper)."""
    for i, label in enumerate(labels):
        if style == "patch":
            arrow = part("top-tab-arrow")
            d = round(height * 0.5)
            width = 44 + len(label) * 9 + d
            tab = three(arrow, width, height, cap=min(0.3, (d + 10) / (arrow.width * height / arrow.height)))
            canvas.alpha_composite(tab, (x, y))
            press(canvas, (x + (width + d // 2) // 2, y + height // 2), label, 14)
            x += width - d + 1
        else:
            width = 30 + len(label) * 10
            tab = three(part("top-tab-drawn"), width, height + (4 if i == active else 0), cap=0.18)
            canvas.alpha_composite(tab, (x, y - (4 if i == active else 0)))
            write(canvas, (x + width // 2, y + height // 2 + 2), label, 18, "Bold" if i == active else "Regular", anchor="mm")
            x += width + 2
    return x


def bubble(canvas, x, y, w, name, cls, channel, time, text, flip=False, seed=0):
    """A chat bubble drawn as one piece of paper (#41's layout and silhouette): a low rounded body two lines high,
    a round bulge over its top left corner (top right when flipped) holding the sketched class icon, the small
    tail below; one tiny pencil outline round the whole shape. The name in its class colour with an outline,
    the channel and time beside it, the message under it."""
    h, R, pad = 52, 19, 7
    if w is None:   # as wide as its text needs
        meta = f"[{channel}]  {time}"
        top = R + 14 + font(16, "Bold").getlength(name) + 7 + font(12, "Light").getlength(meta)
        w = int(max(top, font(15).getlength(text) + 2 * pad + 8) + pad + 6)
    cx = x + 10 if not flip else x + w - 10           # the bulge's centre
    cy = y + 6
    m = 30                                            # room round the shape on its layer
    L = Image.new("L", (w + 2 * m, h + 2 * m))
    d = ImageDraw.Draw(L)
    d.rounded_rectangle((m, m, m + w, m + h), radius=7, fill=255)
    d.ellipse((cx - x + m - R, cy - y + m - R, cx - x + m + R, cy - y + m + R), fill=255)
    tx0 = m + 18 if not flip else m + w - 18
    sgn = 1 if not flip else -1
    d.polygon([(tx0, m + h - 1), (tx0 + sgn * 14, m + h - 1), (tx0 - sgn * 6, m + h + 11)], fill=255)
    L = L.filter(ImageFilter.GaussianBlur(0.6))
    layer = paper.page(w + 2 * m, h + 2 * m, f"bubble{seed}{name}", edge=0, stained=False)
    layer = Image.blend(layer, Image.new("RGBA", layer.size, (255, 248, 232, 255)), 0.12)
    layer.putalpha(L)
    outline = ImageChops.subtract(L, L.filter(ImageFilter.MinFilter(3)))
    ink = Image.new("RGBA", layer.size, LEAD + (0,))
    ink.putalpha(outline.point(lambda v: int(v * 0.75)))
    layer.alpha_composite(ink)
    canvas.alpha_composite(layer, (x - m, y - m))
    canvas.alpha_composite(sketch(icon(f"ClassIcon_{cls}.blp", 64), 2 * R - 8, ring=False), (cx - R + 4, cy - R + 4))
    nx = x + R + 14 if not flip else x + pad + 4
    write(canvas, (nx, y + 4), name, 16, "Bold", CLASS.get(cls, LEAD), 245, outline=True)
    nw = ImageDraw.Draw(canvas).textlength(name, font=font(16, "Bold"))
    write(canvas, (nx + nw + 7, y + 7), f"[{channel}]  {time}", 12, "Light")
    line(canvas, (x + pad + 2, y + 27), (x + w - pad - 2, y + 27), 60, 1, seed + 3)
    write(canvas, (x + pad + 4, y + 29), text, 15)


# ---- the views --------------------------------------------------------------------------------------------

GEAR = {"left": [("Head", "INV_Helmet_0[1-9]*"), ("Neck", "INV_Jewelry_Necklace_0*"), ("Shoulder", "INV_Shoulder_0*"),
                 ("Back", "INV_Misc_Cape_0*"), ("Chest", "INV_Chest_Plate0*"), ("Shirt", "INV_Shirt_0*"),
                 ("Tabard", "INV_Shirt_GuildTabard*"), ("Wrist", "INV_Bracer_0*")],
        "right": [("Hands", "INV_Gauntlets_0*"), ("Waist", "INV_Belt_0*"), ("Legs", "INV_Pants_0*"), ("Feet", "INV_Boots_0*"),
                  ("Ring", "INV_Jewelry_Ring_0*"), ("Ring", "INV_Jewelry_Ring_1*"), ("Trinket", "INV_Trinket_*"), ("Trinket", "INV_Misc_Gem_*")],
        "bottom": [("Main Hand", "INV_Sword_0*"), ("Off Hand", "INV_Shield_0*"), ("Ranged", "INV_Weapon_Bow_0*")]}
ITEMS = ["Helm of the Grey Watch", "Amulet of Ash", "Pauldrons of the Pass", "Cloak of Dusk", "Ringmail Hauberk",
         "Linen Shirt", "Tabard of the Road", "Bracers of Stone", "Gauntlets of Iron", "Girdle of Thorns",
         "Legguards of the Vale", "Boots of the Fen", "Band of the Tide", "Signet of Embers", "Idol of Dawn",
         "Shard of Night", "Blade of the March", "Oaken Buckler", "Yew Longbow"]


# Where #3 (doll.png) has its slots and strips, in its own pixels: the view is that picture, its painted frame,
# arcs and overhanging strips kept as they are; code only puts the live content into it.
DOLL_ROWS = [198, 280, 362, 443, 523, 603, 683]                 # the tops of the seven rows with strips
ARC = 30                                                         # how far the middle rows move outward, pixels
DOLL = {"top": [(310, 100, 400, 190), (605, 100, 700, 190)],      # the two top slots (no strip)
        "left": [((340, y + 4, 404, y + 68), (230, y, 336, y + 70)) for y in DOLL_ROWS],
        "right": [((614, y + 4, 678, y + 68), (680, y, 786, y + 70)) for y in DOLL_ROWS],
        "weapons": [((302, 792, 398, 878), (260, 895, 413, 943)), ((456, 792, 554, 878), (430, 895, 583, 943)),
                    ((614, 792, 710, 878), (599, 895, 753, 943))],
        "ammo": (722, 826, 766, 868)}


def clean(canvas, rect, seed):
    """A strip's painted writing covered by paper of its own tone: only over the strip's own paper (its light
    pixels, shrunk away from its pencil edge), feathered in."""
    x0, y0, x1, y1 = rect
    w, h = x1 - x0, y1 - y0
    region = canvas.crop(rect).convert("RGB")
    light = region.convert("L").point(lambda v: 255 if v > 150 else 0)
    # the paper is what the light pixels enclose; small dark marks (the writing) inside it count as paper
    paper_mask = light.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.MinFilter(15))
    tone = np.median(np.asarray(region)[np.asarray(light) > 0].reshape(-1, 3), axis=0)
    patch = np.asarray(paper.page(w, h, seed, edge=0, stained=False).convert("RGB"), dtype=np.float32)
    patch = patch * (tone / patch.reshape(-1, 3).mean(axis=0))
    patch = Image.fromarray(patch.clip(0, 255).astype(np.uint8)).convert("RGBA")
    patch.putalpha(paper_mask.filter(ImageFilter.GaussianBlur(2)))
    canvas.alpha_composite(patch, (x0, y0))
    bx = paper_mask.getbbox() or (0, 0, w, h)
    return (x0 + bx[0], y0 + bx[1], x0 + bx[2], y0 + bx[3])   # the strip's paper, for its text


def fit(text, size, width, weight="Regular"):
    """The largest size up to size at which text fits width."""
    while size > 9 and font(size, weight).getlength(text) > width:
        size -= 1
    return size


def stats_in(canvas, rect, lines):
    x0, y0, x1, y1 = rect
    y = y0 + 6
    for text, size in lines:
        size = fit(text, size, x1 - x0 - 16)
        write(canvas, (x0 + 8, y), text, size)
        y += size + 3


def view_character():
    """The character doll: Saneroki's pick itself (doll.png, #3), its frame, the slots in their arcs and the paper
    strips over the leather kept as painted; code puts the live content in: game icons in the slots, each
    strip's writing replaced by the item's stats in Kalam. The hero stands in for the game's live model."""
    c = Image.open(os.path.join(REFS, "doll.png")).convert("RGBA")
    # the arcs (Saneroki, 2026-10-21: the slots in a rounded layout, not straight under each other): each row of
    # slot and strip moves outward, most in the middle rows, so the columns bow round the hero; the gap a moved
    # row leaves next to the hero's frame is filled with the paper of that spot
    shift = {}
    tones = {sgn: tuple(int(v) for v in np.median(np.asarray(c.crop(box).convert("RGB")).reshape(-1, 3), axis=0))
             for sgn, box in ((-1, (372, 269, 402, 278)), (1, (622, 269, 652, 278)))}   # the paper between two rows
    for j, y in enumerate(DOLL_ROWS):
        dx = round(ARC * math.sin(math.pi * (j + 1) / 7))
        shift[j] = dx
        for x0, x1, sgn in ((226, 410, -1), (606, 792, 1)):
            band = (x0, y - 3, x1, y + 73)
            piece = c.crop(band)
            gap = (x1 - dx - 4, band[1], x1, band[3]) if sgn < 0 else (x0, band[1], x0 + dx + 4, band[3])
            fill = paper.page(gap[2] - gap[0], gap[3] - gap[1], f"gap{j}{sgn}", edge=0, stained=False, tone=tones[sgn])
            mask = Image.new("L", fill.size)
            ImageDraw.Draw(mask).rectangle((0, 3, fill.width, fill.height - 4), fill=255)
            fill.putalpha(mask.filter(ImageFilter.GaussianBlur(2)))
            c.alpha_composite(fill, gap[:2])
            c.paste(piece, (x0 + sgn * dx, band[1]))
    left, right = GEAR["left"], GEAR["right"]
    for (sl, _), (name, pattern) in zip([(r, None) for r in DOLL["top"]], [left[0], right[0]]):
        x0, y0, x1, y1 = sl
        c.alpha_composite(icon(pattern, x1 - x0 - 20, 0), (x0 + 10, y0 + 10))
    for side, gear, first in (("left", left[1:], 1), ("right", right[1:], 9)):
        for i, ((sl, st), (name, pattern)) in enumerate(zip(DOLL[side], gear)):
            sgn = -1 if side == "left" else 1
            sl = (sl[0] + sgn * shift[i], sl[1], sl[2] + sgn * shift[i], sl[3])
            st = (st[0] + sgn * shift[i], st[1], st[2] + sgn * shift[i], st[3])
            x0, y0, x1, y1 = sl
            c.alpha_composite(icon(pattern, x1 - x0 - 12, i + 1), (x0 + 6, y0 + 6))
            k = first + i
            stats_in(c, clean(c, st, f"{side}{i}"), [(ITEMS[k], 14), (f"{name} · ilvl {58 + (k * 7) % 9}", 12), (f"+{8 + k % 6} Sta  +{5 + k % 4} Str", 12)])
    for i, ((sl, st), (name, pattern)) in enumerate(zip(DOLL["weapons"], GEAR["bottom"])):
        x0, y0, x1, y1 = sl
        c.alpha_composite(icon(pattern, x1 - x0 - 24, i), (x0 + 12, y0 + 12))
        stats_in(c, clean(c, st, f"weapon{i}"), [(f"{ITEMS[16 + i]}  ·  ilvl {60 + i}", 13), (f"{name}  ·  +12 Str  +9 Sta", 11)])
    x0, y0, x1, y1 = DOLL["ammo"]
    c.alpha_composite(icon("INV_Ammo_Arrow_0*", x1 - x0 - 8), (x0 + 4, y0 + 4))
    return c


def view_bags():
    """Bags and bank (bags-page.png): a condensed page cut into close sections, a pencil-ruled header each, dense
    grids of item icons; tabs down the left change the content."""
    W, H = 900, 760
    win = Window(W, H, "Bags", side_tabs=[icon("INV_Misc_Bag_0*", 32), icon("INV_Misc_Herb_0*", 32),
                                           icon("INV_Misc_Coin_0[1-9]*", 32), icon("INV_Misc_Key_0*", 32)],
                 buttons=["Sort", "Bank", "Junk"], seed="bags")
    c, M = win.canvas, win.MARGIN
    x0, y0, x1, y1 = win.inner
    sections = [("Consumables", "INV_Potion_*", 22), ("Trade goods", "INV_Fabric_*", 15), ("Armour", "INV_Chest_*", 11),
                ("Weapons", "INV_Sword_*", 9), ("Quest items", "INV_Misc_Note_*", 6), ("Junk", "INV_Misc_Bone_*", 8)]
    y, s, cols = y0 + 14, 42, 18
    rnd = random.Random(3)
    for title, pattern, n in sections:
        write(c, (x0 + 18, y), title, 18, "Bold")
        write(c, (x1 - 18, y + 3), f"{n} items", 13, "Light", anchor="ra")
        line(c, (x0 + 16, y + 26), (x1 - 16, y + 26), 120, 1)
        y += 32
        for i in range(n):
            x = x0 + 18 + (i % cols) * (s + 3)
            yy = y + (i // cols) * (s + 3)
            slot(c, x, yy, s, icon(pattern, 64, i * 3))
            if rnd.random() < 0.5:
                write(c, (x + s - 4, yy + s - 17), str(rnd.choice([2, 5, 12, 20])), 13, "Bold", (245, 240, 230), 230, anchor="ra")
        y += ((n + cols - 1) // cols) * (s + 3) + 12
    write(c, (x1 - 18, y1 - 30), "12 g  45 s  3 c", 17, anchor="ra")
    return win.finish()


def view_chat():
    """A chat window (top tabs as patches, top-tabs.png): bubbles on the page, others' at the left, the player's
    own at the right, a few short ones in the middle."""
    W, H = 760, 860
    win = Window(W, H, "Chat", buttons=["Send"], seed="chat")
    c, M = win.canvas, win.MARGIN
    x0, y0, x1, y1 = win.inner
    top_tabs(c, x0 + 6, y0 + 4, ["General", "Guild", "Party", "Whispers", "Trade"], "patch", 1)
    msgs = [("left", "Elowen", "Druid", "Guild", "20:41", "Anyone up for the Deadmines in ten?"),
            ("left", "Brannoc", "Warrior", "Guild", "20:42", "I can tank. Need a healer too."),
            ("right", "Saneroki", "Mage", "Guild", "20:42", "Count me in, bringing water."),
            ("middle", "Mira", "Priest", "Guild", "20:43", "I'll heal!"),
            ("left", "Tolvar", "Hunter", "Guild", "20:44", "Meet at the Sentinel Hill flight point."),
            ("right", "Saneroki", "Mage", "Guild", "20:44", "On my way, five minutes."),
            ("middle", "Brannoc", "Warrior", "Guild", "20:45", "Invites out."),
            ("left", "Elowen", "Druid", "Guild", "20:45", "Got it, thanks!")]
    y = y0 + 64
    for side, name, cls, ch, t, text in msgs:
        w = int(max(font(16, "Bold").getlength(name) + 140, font(15).getlength(text) + 30) + 10)
        x = {"left": x0 + 26, "right": x1 - 26 - w, "middle": (x0 + x1) // 2 - w // 2}[side]
        bubble(c, x, y, w, name, cls, ch, t, text, flip=(side == "right"))
        y += 70
    line(c, (x0 + 18, y1 - 50), (x1 - 120, y1 - 50), 130, 1)
    write(c, (x0 + 22, y1 - 76), "Say something to the guild ...", 16, "Light", alpha=140)
    return win.finish()


def view_guild():
    """The guild window (guild-board.png): the paper top with the emblem, name and member count, the row of drawn
    tabs, the board's panels as pencil frames on the paper (no leather on it), patch buttons at the top right."""
    W, H = 1500, 860
    win = Window(W, H, "Guild", seed="guild")
    c, M = win.canvas, win.MARGIN
    x0, y0, x1, y1 = win.inner
    em = sketch(icon("INV_Shirt_GuildTabard*", 64), 70)
    c.alpha_composite(em, (x0 + 18, y0 + 10))
    write(c, (x0 + 100, y0 + 12), "The Grey Wardens", 30, "Bold")
    write(c, (x0 + 102, y0 + 52), "48 members, 12 online", 17)
    line(c, (x0 + 14, y0 + 90), (x1 - 14, y0 + 90), 120, 1)
    top_tabs(c, x0 + 100, y0 + 92, ["Board", "Members", "Armory", "Loot", "Crafting", "Raids", "Officers"], "drawn", 0)
    py = y0 + 142
    cols = [(x0 + 14, x0 + 470), (x0 + 482, x0 + 900), (x0 + 912, x1 - 14)]

    def panel(rect, title):
        box(c, rect, 140, 2, rect[0] + rect[1])
        write(c, (rect[0] + 12, rect[1] + 8), title, 19, "Bold")
        line(c, (rect[0] + 10, rect[1] + 36), (rect[2] - 10, rect[1] + 36), 110, 1)
        return rect[0] + 14, rect[1] + 44

    x, y = panel((cols[0][0], py, cols[0][1], py + 300), "Looking for help")
    for i, (n, cls, q, lv) in enumerate([("Elowen", "Druid", "The Defias Brotherhood", 18), ("Tolvar", "Hunter", "Wanted: Hogger", 11),
                                          ("Mira", "Priest", "The Missing Diplomat", 25), ("Brannoc", "Warrior", "In Sickness and in Health", 28),
                                          ("Kestrel", "Rogue", "The Tome of Divinity", 22)]):
        write(c, (x, y + i * 48), q, 17)
        write(c, (x, y + i * 48 + 20), f"{n} · Westfall", 14, "Light", CLASS[cls], outline=True)
        write(c, (cols[0][1] - 18, y + i * 48 + 4), f"lvl {lv}", 15, anchor="ra")
    x, y = panel((cols[0][0], py + 312, cols[0][1], y1 - 14), "Planned runs")
    for i, (d, t, open_) in enumerate([("The Deadmines", "20:00", "1 tank · 2 dps"), ("Wailing Caverns", "Wed 19:30", "full"),
                                        ("Shadowfang Keep", "Thu 21:00", "1 heal")]):
        write(c, (x, y + i * 50), d, 17)
        write(c, (x, y + i * 50 + 22), open_, 14, "Light")
        write(c, (cols[0][1] - 18, y + i * 50 + 4), t, 16, "Bold", anchor="ra")
    x, y = panel((cols[1][0], py, cols[1][1], y1 - 14), "Guild chat")
    for i, (n, cls, text) in enumerate([("Elowen", "Druid", "Anyone for the Deadmines?"), ("Brannoc", "Warrior", "I can tank."),
                                        ("Mira", "Priest", "I'll heal!"), ("Tolvar", "Hunter", "Ding 30!"), ("Kestrel", "Rogue", "Grats!")]):
        bubble(c, x + 14 + (60 if i % 2 else 0), y + 8 + i * 74, None, n, cls, "Guild", f"20:4{i}", text, flip=bool(i % 2))
    x, y = panel((cols[2][0], py, cols[2][1], py + 330), "Race to level 60")
    base = py + 290
    for rank, (n, cls, lv, h, px) in enumerate([("Brannoc", "Warrior", 58, 120, 1), ("Elowen", "Druid", 57, 90, 0), ("Mira", "Priest", 55, 66, 2)]):
        bx = cols[2][0] + 70 + px * 150
        box(c, (bx, base - h, bx + 130, base), 160, 2, rank + 40)
        write(c, (bx + 65, base - h + 8), str(rank + 1), 30, "Bold", anchor="ma")
        c.alpha_composite(sketch(icon(f"ClassIcon_{cls}.blp", 64), 52), (bx + 39, base - h - 112))
        write(c, (bx + 65, base - h - 56), n, 18, "Bold", CLASS[cls], anchor="ma", outline=True)
        write(c, (bx + 65, base - h - 34), f"level {lv}", 14, anchor="ma")
    x, y = panel((cols[2][0], py + 342, cols[2][1], y1 - 14), "Offered to the guild")
    for i, (pattern, name, who) in enumerate([("INV_Sword_0*", "Blade of the March", "Brannoc"), ("INV_Misc_Cape_0*", "Cloak of Dusk", "Mira"),
                                              ("INV_Jewelry_Ring_0*", "Band of the Tide", "Kestrel")]):
        slot(c, x, y + i * 54, 44, icon(pattern, 64, i + 5))
        write(c, (x + 56, y + i * 54 + 2), name, 17)
        write(c, (x + 56, y + i * 54 + 22), f"from {who}", 14, "Light")
    return win.finish()


def view_spellbook():
    """A spellbook: the schools as side tabs, two pages of spells (icon, name, rank) divided by a pencil fold,
    a band hanging from the top for the filter overlay."""
    W, H = 900, 760
    schools = [((150, 52, 40), "Spell_Fire_FlameBolt"), ((70, 90, 130), "Spell_Frost_FrostBolt02"), ((110, 70, 130), "Spell_Nature_StarFall"),
               ((176, 130, 60), "Spell_Holy_*")]
    win = Window(W, H, "Spellbook", side_tabs=[icon(p + ("" if "*" in p else ".blp"), 32) for _, p in schools],
                 buttons=["Previous", "Next"], bands=[(W - 150, "Filter")], seed="spellbook")
    c, M = win.canvas, win.MARGIN
    x0, y0, x1, y1 = win.inner
    mid = (x0 + x1) // 2
    line(c, (mid, y0 + 16), (mid, y1 - 16), 90, 2)
    names = ["Fireball", "Fire Blast", "Flamestrike", "Scorch", "Pyroblast", "Blast Wave", "Frostbolt", "Frost Nova",
             "Cone of Cold", "Blizzard", "Ice Barrier", "Ice Block"]
    pats = ["Spell_Fire_FlameBolt.blp", "Spell_Fire_Fireball.blp", "Spell_Fire_SelfDestruct.blp", "Spell_Fire_SoulBurn.blp",
            "Spell_Fire_Fireball02.blp", "Spell_Holy_Excorcism_02.blp", "Spell_Frost_FrostBolt02.blp", "Spell_Frost_FrostNova.blp",
            "Spell_Frost_Glacier.blp", "Spell_Frost_IceStorm.blp", "Spell_Ice_Lament.blp", "Spell_Frost_Frost.blp"]
    for i, (n, p) in enumerate(zip(names, pats)):
        px = x0 + 30 if i < 6 else mid + 30
        py = y0 + 40 + (i % 6) * 100
        slot(c, px, py, 58, icon(p, 64))
        write(c, (px + 72, py + 4), n, 20, "Bold")
        write(c, (px + 72, py + 32), f"Rank {1 + i % 4}  ·  {30 + i * 15} mana", 14, "Light")
    write(c, ((x0 + mid) // 2, y1 - 36), "1", 15, anchor="ma")
    write(c, ((mid + x1) // 2, y1 - 36), "2", 15, anchor="ma")
    return win.finish()


def view_stats():
    """Character stats, with the drawn top tabs: rows of names and values under pencil-ruled headers."""
    W, H = 560, 780
    win = Window(W, H, "Character", side_tabs=[icon("INV_Chest_Plate0*", 32), icon("Spell_Nature_*", 32)],
                 seed="stats")
    c, M = win.canvas, win.MARGIN
    x0, y0, x1, y1 = win.inner
    top_tabs(c, x0 + 10, y0 + 6, ["Stats", "Skills", "Reputation", "Currency"], "drawn", 0)
    groups = [("Attributes", [("Strength", "142"), ("Agility", "87"), ("Stamina", "215"), ("Intellect", "41"), ("Spirit", "58")]),
              ("Melee", [("Damage", "88 – 131"), ("Speed", "2.60"), ("Power", "396"), ("Hit", "+3 %"), ("Crit chance", "6.48 %")]),
              ("Defence", [("Armour", "3,412"), ("Defence", "305"), ("Dodge", "5.21 %"), ("Parry", "6.02 %"), ("Block", "4.10 %")])]
    y = y0 + 64
    for title, rows in groups:
        write(c, (x0 + 22, y), title, 19, "Bold")
        line(c, (x0 + 20, y + 28), (x1 - 20, y + 28), 120, 1)
        y += 36
        for n, v in rows:
            write(c, (x0 + 30, y), n, 17)
            write(c, (x1 - 30, y), v, 17, anchor="ra")
            y += 26
        y += 14
    return win.finish()


def view_bubbles():
    """Chat bubbles floating over the world, two lines each."""
    img = Image.new("RGBA", (900, 520), BG + (255,))
    g = Image.radial_gradient("L").resize((900, 520)).point(lambda v: 255 - v)
    img = Image.composite(Image.new("RGBA", img.size, (58, 52, 44, 255)), img, g)
    for i, (n, cls, ch, t, text) in enumerate([("Elowen", "Druid", "Say", "20:41", "Watch out, there's a patrol!"),
                                                ("Brannoc", "Warrior", "Party", "20:41", "Pulling the next pack."),
                                                ("Mira", "Priest", "Yell", "20:42", "Heals incoming!")]):
        bubble(img, 160 + i * 40, 100 + i * 110, None, n, cls, ch, t, text)
    return img


VIEWS = {"character": view_character, "bags": view_bags, "chat": view_chat, "guild": view_guild,
         "spellbook": view_spellbook, "stats": view_stats, "bubbles": view_bubbles}


def main(names):
    os.makedirs(OUT, exist_ok=True)
    for name in names or VIEWS:
        img = VIEWS[name]().convert("RGB")
        img.save(os.path.join(OUT, name + ".png"))
        print(name, img.size)


if __name__ == "__main__":
    main(sys.argv[1:])
