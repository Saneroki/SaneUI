#!/usr/bin/env python3
"""Views put together in code from the decided parts (Doc/guides/interface-style.md), the way the game will draw
them: the leather parts sliced and repeated, the paper from paper.py, pencil lines drawn by code, text in Kalam
with the paper's grain over it, titles and labels pressed into the leather, game icons from references/. Nothing
here is painted by a model except the parts themselves (elements-*.txt, each from its crop of a pick), so the
layout and the look cannot drift. polish.txt then gives each view one light pass by Qwen's edit.
  python3 dev/imagegen/sets/interface/compose.py [view ...]   ->  assets/generated/interface/views/<view>.png
The part used is the first seed of each element unless CHOSEN names another.
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
LEATHER_FONT = "/usr/share/fonts/noto/NotoSerif-Bold.ttf"   # a stand-in: no leather font is decided yet

# element: seed, where seed 1 does not follow its brief (a label or mark left in, the part cut short); "clean":
# the pick's crop with its label covered in code (refs.py), where no seed lost its label
CHOSEN = {"edge-left": 3, "top-tab-drawn": 3, "top-tab-patch": "clean"}
LEAD = (58, 52, 46)            # pencil grey
BG = (24, 21, 18)              # behind the windows
def on_paper(color):
    """A class colour dark enough to read on the paper, its hue kept."""
    lum = 0.3 * color[0] + 0.59 * color[1] + 0.11 * color[2]
    k = min(1.0, 120 / max(lum, 1))
    return tuple(int(v * k) for v in color)


CLASS = {"Warrior": (199, 156, 110), "Mage": (63, 199, 235), "Priest": (230, 230, 230), "Rogue": (255, 244, 104),
         "Druid": (255, 124, 10), "Hunter": (170, 211, 114), "Paladin": (244, 140, 186), "Warlock": (135, 136, 238),
         "Shaman": (0, 112, 221)}


# ---- parts ------------------------------------------------------------------------------------------------

# marks the edit left in an element, covered in code by the element's own paper: (left, top, right, bottom) as
# fractions of the trimmed element
COVER = {"chat-bubble": (0.09, 0.15, 0.215, 0.56)}   # a portrait the edit kept beside the empty icon circle


def part(name):
    """An element as painted (its chosen seed), trimmed to what it covers, its leftover marks covered."""
    if CHOSEN.get(name) == "clean":
        return Image.open(os.path.join(CROPS, name + "-clean.png")).convert("RGBA")
    f = os.path.join(ELEMENTS, f"{name}-{CHOSEN.get(name, 1)}.png")
    img = Image.open(f if os.path.exists(f) else os.path.join(CROPS, name + ".png")).convert("RGBA")
    box = img.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
    img = img.crop(box) if box else img
    if name in COVER:
        l, t, r, b = COVER[name]
        area = (round(l * img.width), round(t * img.height), round(r * img.width), round(b * img.height))
        rgb = np.asarray(img.convert("RGB"))
        tone = tuple(int(v) for v in np.median(rgb[img.height // 2, img.width // 3:img.width // 2], axis=0))
        mask = Image.new("L", img.size)
        ImageDraw.Draw(mask).ellipse(area, fill=255)
        img.paste(Image.new("RGBA", img.size, tone + (255,)), (0, 0), mask.filter(ImageFilter.GaussianBlur(4)))
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


def sketch(img, size, disc=None):
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
    ImageDraw.Draw(out).ellipse((1, 1, size - 2, size - 2), outline=LEAD + (170,), width=2)
    return out


# ---- drawing on paper and leather -------------------------------------------------------------------------

def font(size, weight="Regular"):
    return ImageFont.truetype(KALAM.format(weight), size)


def write(canvas, xy, text, size=20, weight="Regular", color=LEAD, alpha=225, anchor="la"):
    """Kalam in pencil with the paper's grain over it."""
    layer = Image.new("RGBA", canvas.size)
    ImageDraw.Draw(layer).text(xy, text, font=font(size, weight), fill=color + (alpha,), anchor=anchor)
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

class Window:
    """A window of the journal look: leather binding, the title bar on top with its title pressed in, paper
    inside. Side tabs stick out of the left edge, bands hang from the top, patch buttons sit in the bottom
    border; the content goes on self.page, from self.inner."""

    BORDER = 16
    TITLE = 46
    BOTTOM = 18
    MARGIN = 64

    def __init__(self, w, h, title, side_tabs=(), buttons=(), bands=(), seed="window", margin=None):
        self.w, self.h, self.title = w, h, title
        self.MARGIN = M = margin or self.MARGIN
        self.canvas = Image.new("RGBA", (w + 2 * M, h + 2 * M), BG + (255,))
        self.ox, self.oy = M, M
        self.inner = (M + self.BORDER, M + self.TITLE, M + w - self.BORDER, M + h - self.BOTTOM)
        x0, y0, x1, y1 = self.inner
        self.canvas.alpha_composite(paper.page(x1 - x0 + 6, y1 - y0 + 6, seed), (x0 - 3, y0 - 3))
        self.side_tabs, self.buttons, self.bands = side_tabs, buttons, bands

    def finish(self):
        """The leather on top of the paper: edges, bottom, corners, title bar, then tabs, bands, buttons."""
        c, M, w, h = self.canvas, self.MARGIN, self.w, self.h
        for i, (color, ico) in enumerate(self.side_tabs):
            tab = tint(part("side-tab"), color).resize((50, 46), Image.LANCZOS)
            y = M + self.TITLE + 18 + i * 54
            c.alpha_composite(tab, (M - 30, y))
            if ico is not None:
                g = ImageOps.grayscale(ico.convert("RGB")).resize((24, 24), Image.LANCZOS)
                mark = Image.new("RGBA", (24, 24), (30, 18, 10, 0))
                mark.putalpha(ImageOps.invert(g).point(lambda v: int(v * 0.55)))
                c.alpha_composite(mark, (M - 22, y + 11))
        edge = part("edge-left")
        side = three(edge, h - self.TITLE + 4, self.BORDER, horizontal=False, cap=0.06)
        c.alpha_composite(side, (M, M + self.TITLE - 4))
        c.alpha_composite(side.transpose(Image.FLIP_LEFT_RIGHT), (M + w - self.BORDER, M + self.TITLE - 4))
        c.alpha_composite(three(edge.rotate(90, expand=True), w, self.BOTTOM, cap=0.06), (M, M + h - self.BOTTOM))
        cor = part("corner").resize((34, 34), Image.LANCZOS)
        c.alpha_composite(cor.transpose(Image.FLIP_TOP_BOTTOM), (M - 4, M + h - 30))
        c.alpha_composite(cor.rotate(180), (M + w - 30, M + h - 30))
        c.alpha_composite(three(part("title-bar"), w + 8, self.TITLE, cap=0.07), (M - 4, M))
        press(c, (M + w // 2, M + self.TITLE // 2), self.title.upper(), 21)
        for i, (label) in enumerate(("x",)):
            p = part("patch-square").resize((30, 30), Image.LANCZOS)
            c.alpha_composite(p, (M + w - 56, M + 8))
            press(c, (M + w - 41, M + 22), "x", 18)
        for x, label in self.bands:
            band = three(part("dropdown-band"), 92, 34, horizontal=False, cap=0.12)
            c.alpha_composite(band, (M + x, M + self.TITLE - 10))
            press(c, (M + x + 17, M + self.TITLE + 40), label, 13)
        x = M + 26
        for label in self.buttons:
            width = 34 + len(label) * 11
            c.alpha_composite(three(part("patch-wide"), width, 30, cap=0.2), (x, M + h - 24))
            press(c, (x + width // 2, M + h - 9), label, 14)
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
    """The row of tabs under the title bar: 'patch' (darker patches) or 'drawn' (pencil on the paper)."""
    name = "top-tab-patch" if style == "patch" else "top-tab-drawn"
    for i, label in enumerate(labels):
        width = 30 + len(label) * 10
        tab = three(part(name), width, height + (4 if i == active else 0), cap=0.18)
        canvas.alpha_composite(tab, (x, y - (4 if i == active else 0)))
        if style == "patch":
            press(canvas, (x + width // 2, y + height // 2), label, 14)
        else:
            write(canvas, (x + width // 2, y + height // 2 + 2), label, 18, "Bold" if i == active else "Regular", anchor="mm")
        x += width + 2
    return x


def bubble(canvas, x, y, w, name, cls, channel, time, text, flip=False, seed=0):
    """A chat bubble: the painted bubble sliced to w and two lines high, the sketched class icon over its top
    left corner, the name in its class colour with channel and time, the message under it."""
    b = part("chat-bubble")
    if flip:
        b = b.transpose(Image.FLIP_LEFT_RIGHT)
    h = 66
    canvas.alpha_composite(nine(b, w, h, 0.16 if not flip else 0.05, 0.3, 0.05 if not flip else 0.16, 0.36), (x, y))
    tone = tuple(int(v) for v in np.median(np.asarray(canvas.crop((x + w // 3, y + 20, x + w // 2, y + 40)).convert("RGB")).reshape(-1, 3), axis=0))
    tone = tone if sum(tone) > 450 else (226, 214, 190)
    ix = x - 10 if not flip else x + w - 30
    canvas.alpha_composite(sketch(icon(f"ClassIcon_{cls}.blp", 64), 40, tone), (ix, y - 12))
    tx = x + 36 if not flip else x + 14
    write(canvas, (tx, y + 6), name, 17, "Bold", on_paper(CLASS.get(cls, LEAD)), 240)
    nw = ImageDraw.Draw(canvas).textlength(name, font=font(17, "Bold"))
    write(canvas, (tx + nw + 8, y + 9), f"[{channel}]  {time}", 13, "Light")
    write(canvas, (tx, y + 30), text, 16)


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
    left, right = GEAR["left"], GEAR["right"]
    for (sl, _), (name, pattern) in zip([(r, None) for r in DOLL["top"]], [left[0], right[0]]):
        x0, y0, x1, y1 = sl
        c.alpha_composite(icon(pattern, x1 - x0 - 20, 0), (x0 + 10, y0 + 10))
    for side, gear, first in (("left", left[1:], 1), ("right", right[1:], 9)):
        for i, ((sl, st), (name, pattern)) in enumerate(zip(DOLL[side], gear)):
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
    win = Window(W, H, "Bags", side_tabs=[((150, 52, 40), icon("INV_Misc_Bag_0*", 32)), ((70, 110, 60), icon("INV_Misc_Herb_0*", 32)),
                                           ((176, 130, 60), icon("INV_Misc_Coin_0[1-9]*", 32)), ((70, 90, 130), icon("INV_Misc_Key_0*", 32))],
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
        w = min(470, 190 + len(text) * 7)
        x = {"left": x0 + 26, "right": x1 - 26 - w, "middle": (x0 + x1) // 2 - w // 2}[side]
        bubble(c, x, y, w, name, cls, ch, t, text, flip=(side == "right"))
        y += 80
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
        write(c, (x, y + i * 48 + 20), f"{n} · Westfall", 14, "Light", on_paper(CLASS[cls]))
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
        bubble(c, x + 14 + (60 if i % 2 else 0), y + 8 + i * 80, 300, n, cls, "Guild", f"20:4{i}", text, flip=bool(i % 2))
    x, y = panel((cols[2][0], py, cols[2][1], py + 330), "Race to level 60")
    base = py + 290
    for rank, (n, cls, lv, h, px) in enumerate([("Brannoc", "Warrior", 58, 120, 1), ("Elowen", "Druid", 57, 90, 0), ("Mira", "Priest", 55, 66, 2)]):
        bx = cols[2][0] + 70 + px * 150
        box(c, (bx, base - h, bx + 130, base), 160, 2, rank + 40)
        write(c, (bx + 65, base - h + 8), str(rank + 1), 30, "Bold", anchor="ma")
        c.alpha_composite(sketch(icon(f"ClassIcon_{cls}.blp", 64), 52), (bx + 39, base - h - 112))
        write(c, (bx + 65, base - h - 56), n, 18, "Bold", on_paper(CLASS[cls]), anchor="ma")
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
    win = Window(W, H, "Spellbook", side_tabs=[(col, icon(p + ("" if "*" in p else ".blp"), 32)) for col, p in schools],
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
    win = Window(W, H, "Character", side_tabs=[((150, 52, 40), icon("INV_Chest_Plate0*", 32)), ((70, 110, 60), icon("Spell_Nature_*", 32))],
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
        bubble(img, 140 + i * 40, 90 + i * 120, 470, n, cls, ch, t, text)
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
