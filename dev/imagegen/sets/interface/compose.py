#!/usr/bin/env python3
"""Views put together in code from the final pieces (pieces.py; Doc/guides/interface-style.md, *Pieces*), the way
the game will draw them: the leather pieces sliced and repeated, the paper from paper.py, pencil lines from #14's
pieces, text in Kalam with the paper's grain over it, titles and labels pressed into the leather, game icons from
the newest export of Blizzard's art (dev/tools/blizzard where). Nothing here is painted by a model, so the layout and the look cannot drift. No model pass runs over a
view. Layouts are in the pixels of a 1080p screen; S turns them into pixels (2 at 4K), and the pieces, made at 4K,
are scaled to it. Each window comes on transparency, so the full screen lays several side by side.
  python3 dev/imagegen/sets/interface/compose.py [--scale N] [view ...]   ->  assets/generated/interface/views/<view>.png
    the views at 1080p (--scale 2: at 4K); the full screen always at 4K (3840 x 2160)
"""
import glob, math, os, random, sys, zlib
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont, ImageOps

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "../../../..")
sys.path.insert(0, HERE)
import paper  # noqa: E402
import pieces  # noqa: E402
from pieces import fade  # noqa: E402

PIECES = os.path.join(ROOT, "assets/generated/interface/pieces")
sys.path.insert(0, os.path.join(ROOT, "dev/blizzard"))
import export as exports  # noqa: E402  (the newest export of Blizzard's interface, never references/)
ICONS = str(exports.required("art") / "Interface" / "ICONS")
OUT = os.path.join(ROOT, "assets/generated/interface/views")
KALAM = os.path.join(ROOT, "assets/fonts/Kalam/Kalam-{}.ttf")
LEATHER_FONT = "/usr/share/fonts/noto/NotoSerif-Regular.ttf"   # a stand-in: no leather font is decided yet

# The decided parts and the piece each is (pieces.py): only decided ones (Doc/guides/interface-style.md)
SOURCE = {"patch": "patch",                  # paper #183: every leather patch and button
          "top-tab-arrow": "tab-arrow",      # the interlocking leather arrow tab
          "pencil-box": "pencil-box",        # #14's pencil lines alone: boxes, tabs
          "pencil-rule": "pencil-rule",      # its top line: rules
          "band": "kit3-09"}                 # kit-3: the band with its buckle, for dropdowns
LEAD = (30, 23, 17)            # pencil grey
BG = (24, 21, 18)              # behind the windows
CLASS = {"Warrior": (199, 156, 110), "Mage": (63, 199, 235), "Priest": (230, 230, 230), "Rogue": (255, 244, 104),
         "Druid": (255, 124, 10), "Hunter": (170, 211, 114), "Paladin": (244, 140, 186), "Warlock": (135, 136, 238),
         "Shaman": (0, 112, 221)}
S = 1                          # pixels per layout pixel: 1 at 1080p, 2 at 4K (main sets it per view)


def z(v):
    """A layout length in pixels."""
    return int(round(v * S))


def zz(*vs):
    return tuple(z(v) for v in vs)


def put(canvas, img, xy):
    """img (already in pixels) laid on the canvas at a layout point."""
    canvas.alpha_composite(img, zz(*xy))


# ---- pieces -----------------------------------------------------------------------------------------------

_pieces = {}


def piece(name):
    """A final piece (pieces.py, at 4K) at this scale."""
    key = (name, S)
    if key not in _pieces:
        img = Image.open(os.path.join(PIECES, name + ".png")).convert("RGBA")
        k = S / pieces.SCALE
        if k != 1:
            img = img.resize((max(1, round(img.width * k)), max(1, round(img.height * k))), Image.LANCZOS)
        _pieces[key] = img
    return _pieces[key]


def part(name):
    """A decided part's piece. Only decided parts: anything not in SOURCE is refused, so nothing discarded or never
    named can come in."""
    if name not in SOURCE:
        raise ValueError(f"{name} is not a decided part (Doc/guides/interface-style.md); add it to SOURCE first")
    return piece(SOURCE[name])


def three(img, length, thick, cap=0.18):
    """A strip of any length (pixels): the ends kept, the middle repeated (not stretched)."""
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
    """A piece stretched to w x h pixels by nine slices: its margins (fractions of the piece) drawn at the piece's
    scale for that height, the rest stretched."""
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


def icon(pattern, size, seed=0):
    """A game icon of Blizzard's art (the first match of the pattern, or one picked by seed), size layout pixels."""
    files = sorted(glob.glob(os.path.join(ICONS, pattern)))
    if not files:
        return Image.new("RGBA", zz(size, size), (90, 80, 70, 255))
    img = Image.open(files[seed % len(files)]).convert("RGBA")
    img = img.crop((4, 4, img.width - 4, img.height - 4))  # the game's own rim cut away
    return img.resize(zz(size, size), Image.LANCZOS)


def sketch(img, size, disc=None, ring=True):
    """A game icon drawn as a pencil sketch: its edges as grey strokes in a round (size layout pixels), on nothing
    or on a disc of paper of the colour disc."""
    px = z(size)
    # the edges found at the layout's size (the icon's own detail), then drawn at the pixels' size
    g = ImageOps.grayscale(img.convert("RGB")).resize((round(size * 2), round(size * 2)), Image.LANCZOS)
    # crisp lines only (Saneroki: clean, sharp pencil lines, no shading): the icon's strongest edges, thresholded
    edges = g.filter(ImageFilter.GaussianBlur(1.2)).filter(ImageFilter.FIND_EDGES)
    a = edges.point(lambda v: 0 if v < 18 else min(255, (v - 18) * 9)).resize((px, px), Image.LANCZOS)
    mask = Image.new("L", (px, px))
    ImageDraw.Draw(mask).ellipse((1, 1, px - 2, px - 2), fill=255)
    a = ImageChops.multiply(a, mask)
    lines = Image.new("RGBA", (px, px), LEAD + (0,))
    lines.putalpha(a)
    out = Image.new("RGBA", (px, px))
    if disc:
        ImageDraw.Draw(out).ellipse((1, 1, px - 2, px - 2), fill=disc + (255,))
    out.alpha_composite(lines)
    if ring:
        ImageDraw.Draw(out).ellipse((1, 1, px - 2, px - 2), outline=LEAD + (170,), width=z(2))
    return out


# ---- drawing on paper and leather -------------------------------------------------------------------------

def font(size, weight="Regular"):
    """Kalam at a layout size."""
    return ImageFont.truetype(KALAM.format(weight), z(size))


OUTLINE = (34, 28, 22)          # round letters in a colour that is hard to read on the paper


def write(canvas, xy, text, size=20, weight="Regular", color=LEAD, alpha=225, anchor="la", outline=False):
    """Kalam in pencil with the paper's grain over it; outline: a thin dark line round the letters, for colours
    hard to read on the paper (the game's class colours)."""
    f, stroke_ = font(size, weight), z(1) if outline else 0
    x, y = zz(*xy)
    x0, y0, x1, y1 = ImageDraw.Draw(canvas).textbbox((x, y), text, font=f, anchor=anchor, stroke_width=stroke_)
    pad = z(4)
    layer = Image.new("RGBA", (x1 - x0 + 2 * pad, y1 - y0 + 2 * pad))
    ImageDraw.Draw(layer).text((x - x0 + pad, y - y0 + pad), text, font=f, fill=color + (alpha,), anchor=anchor,
                               stroke_width=stroke_, stroke_fill=OUTLINE + (alpha,))
    rnd = np.random.default_rng(zlib.crc32(text.encode()))
    grain = Image.fromarray((rnd.uniform(0.62, 1.0, (layer.height, layer.width)) * 255).astype(np.uint8))
    layer.putalpha(ImageChops.multiply(layer.getchannel("A"), grain.filter(ImageFilter.GaussianBlur(0.6 * S))))
    canvas.alpha_composite(layer, (x0 - pad, y0 - pad))


def press(canvas, xy, text, size=22, anchor="mm", font_file=LEATHER_FONT):
    """Letters pressed into leather: a dark cut with a faint light lip below it."""
    f = ImageFont.truetype(font_file, z(size))
    d = ImageDraw.Draw(canvas)
    x, y = zz(*xy)
    d.text((x, y + z(1)), text, font=f, fill=(225, 190, 145, 70), anchor=anchor)
    d.text((x, y - z(1)), text, font=f, fill=(10, 6, 3, 120), anchor=anchor)
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
            pts.append((z(a[0] + (b[0] - a[0]) * t + rnd.uniform(-0.8, 0.8) + k * 0.6),
                        z(a[1] + (b[1] - a[1]) * t + rnd.uniform(-0.8, 0.8) + k * 0.6)))
        d.line(pts, fill=LEAD + (al,), width=max(1, z(width - k)), joint="curve")


def stroke(layer, a, b, alpha, width, rnd, over=0):
    """One sharp pencil stroke from a to b (pixels) as an artist draws it: a slight bow, the ends running a little
    past the corner (over), the pressure lighter at the ends."""
    ax, ay = a
    bx, by = b
    length = math.dist(a, b) or 1
    ux, uy = (bx - ax) / length, (by - ay) / length
    ax, ay, bx, by = ax - ux * over, ay - uy * over, bx + ux * over, by + uy * over
    bow = rnd.uniform(-1, 1) * min(2.0 * S, length / 120)
    n = max(4, int(length / (6 * S)))
    stroke_layer = Image.new("RGBA", layer.size)
    d = ImageDraw.Draw(stroke_layer)
    pts = []
    for i in range(n + 1):
        t = i / n
        off = bow * math.sin(math.pi * t)
        pts.append((ax + (bx - ax) * t - uy * off, ay + (by - ay) * t + ux * off))
    for i in range(n):
        t = (i + 0.5) / n
        press_ = 0.55 + 0.45 * math.sin(math.pi * t)            # lighter where the pencil lands and lifts
        d.line([pts[i], pts[i + 1]], fill=LEAD + (int(alpha * press_),), width=width)
    layer.alpha_composite(stroke_layer)


def block(canvas, x, base, w, h, depth, seed=0):
    """A podium step as an artist's pencil sketch of a real block in perspective (Saneroki, 2026-10-21: clean
    pencil lines only, no shading): its front, its top face going back up to the right, its right side, each edge
    a sharp stroke running a little past its corners, a faint construction line or two, nothing filled in. The
    faces only hide what lies behind them (the paper's own tone), so a step in front covers the one behind."""
    x, base, w, h, depth = zz(x, base, w, h, depth)
    dx, dy = depth, -depth * 0.55
    tone = tuple(int(v) for v in np.median(np.asarray(canvas.crop((x, base - h, x + w, base)).convert("RGB")).reshape(-1, 3), axis=0))
    # drawn on a layer round the block only
    ox, oy = x - 4 * depth, int(base - h + dy - 3 * depth)
    layer = Image.new("RGBA", (w + 8 * depth, h + 6 * depth))

    def p(px, py):
        return (px - ox, py - oy)
    front = [p(x, base - h), p(x + w, base - h), p(x + w, base), p(x, base)]
    top = [p(x, base - h), p(x + dx, base - h + dy), p(x + w + dx, base - h + dy), p(x + w, base - h)]
    side = [p(x + w, base - h), p(x + w + dx, base - h + dy), p(x + w + dx, base + dy), p(x + w, base)]
    for face in (side, top, front):
        ImageDraw.Draw(layer).polygon(face, fill=tone + (255,))
    rnd = random.Random(seed)
    # faint construction lines first: the vanishing direction of the top edges, a little beyond the block
    for q in (top[2], side[2]):
        stroke(layer, q, (q[0] + depth * 1.6, q[1] - depth * 0.9), 40, max(1, z(1)), rnd)
    # the edges: the outline firm, the inner edges lighter
    outline = [(front[3], front[0]), (front[0], top[1]), (top[1], top[2]), (top[2], side[2]), (side[2], front[2]),
               (front[2], front[3])]
    inner = [(front[0], front[1]), (front[1], front[2]), (front[1], top[2])]
    for a, b in outline:
        stroke(layer, a, b, 215, z(2), rnd, over=rnd.uniform(3, 7) * S)
    for a, b in inner:
        stroke(layer, a, b, 165, z(1), rnd, over=rnd.uniform(2, 5) * S)
    # a second, lighter pass over the outline, a hair off, as a sketch has
    for a, b in outline[:3]:
        stroke(layer, (a[0] + rnd.uniform(-1, 1) * S, a[1] + rnd.uniform(-1, 1) * S),
               (b[0] + rnd.uniform(-1, 1) * S, b[1] + rnd.uniform(-1, 1) * S), 70, z(1), rnd, over=rnd.uniform(4, 9) * S)
    canvas.alpha_composite(layer, (ox, oy))


def slot(canvas, x, y, s, img):
    """A gear or item slot on paper: the icon in a pencil box."""
    put(canvas, img.resize(zz(s - 8, s - 8), Image.LANCZOS), (x + 4, y + 4))
    pbox(canvas, (x - 1, y - 1, x + s + 1, y + s + 1))


# ---- the window -------------------------------------------------------------------------------------------

# The window is the decided window itself: #12 (edges-and-buttons.png) cleaned of the strap over its paper and of
# its title label's writing (clean.py), cut by pieces.py at its own lines into pieces: the top (its leather strap
# with the ribbon bookmark, the corner patch and the paper title label), the bottom (the page's end and the stack of
# pages, the corners with their caps), each as two ends and a middle that stretches; the left and right edges as
# tiles that repeat (the right with its clasp). The top's and bottom's paper fades into the page. Lengths in #12's
# pixels, the layout's.
FRAME_T = pieces.FRAME_TOP[1] - pieces.FRAME_TOP[0]
FRAME_B = pieces.FRAME_LEFT[1] - pieces.FRAME_LEFT[0]          # the bottom is the left edge turned
FRAME_L = pieces.FRAME_LEFT[1] - pieces.FRAME_LEFT[0]
FRAME_R = FRAME_L + pieces.RIGHT_IN                            # the right edge (the left one mirrored) and the room
                                                               # right of it to the top's right end
CLASP_W, CLASP_H = pieces.CLASP[2] - pieces.CLASP[0], pieces.CLASP[3] - pieces.CLASP[1]
TITLE_AT = (pieces.TITLE_AT[0] - pieces.FRAME_X[0], pieces.TITLE_AT[1] - pieces.FRAME_TOP[0])
CLOSE_FROM_RIGHT = (pieces.FRAME_X[3] - pieces.CLOSE_AT[0], pieces.CLOSE_AT[1] - pieces.FRAME_TOP[0])
EDGES_HEAD = pieces.EDGES_START - pieces.FRAME_TOP[0]         # the top's height above the edges' start


def butt(left, mid, right, length):
    """A band of any length (pixels) whose middle is stretched whole between its two ends, joined edge to edge: the
    window's top and bottom, whose lines (strap, label, page stack) run on from the ends without a cross-fade."""
    h = left.height
    out = Image.new("RGBA", (length, h))
    mw = length - left.width - right.width
    if mw > 0:
        out.alpha_composite(mid.resize((mw, h), Image.LANCZOS), (left.width, 0))
    out.alpha_composite(left, (0, 0))
    out.alpha_composite(right, (length - right.width, 0))
    return out


def column(tile, length):
    """A vertical edge of any length (pixels) from its tile, repeated (the tile joins itself without a seam)."""
    out = Image.new("RGBA", (tile.width, length))
    for y in range(0, length, tile.height):
        out.alpha_composite(tile, (0, y))
    return out


class Window:
    """A window of the journal look: #12 itself round the page (its pieces), its title in Kalam on #12's paper label,
    the close button on #12's corner patch, buttons of #183's patch on the page's foot, bands with a buckle (kit-3)
    hanging from the top for dropdowns, side tabs of #183's patch. The content goes on the page, from self.content
    (layout pixels). The canvas is transparent round the window (MARGIN on each side, for side tabs that hang out)."""

    MARGIN = 64

    def __init__(self, w, h, title, side_tabs=(), buttons=(), bands=(), seed="window", margin=None):
        self.w, self.h, self.title = w, h, title
        self.MARGIN = M = margin or self.MARGIN
        self.canvas = Image.new("RGBA", zz(w + 2 * M, h + 2 * M))
        # the page: from the edges' inner sides, under the top and bottom's paper
        x0, y0, x1, y1 = (M + FRAME_L - 22, M + FRAME_T - 30, M + w - FRAME_R + 22, M + h - FRAME_B + 22)   # under
        # the edges' paper, which fades into it
        put(self.canvas, paper.page(z(x1 - x0), z(y1 - y0), seed, edge=0), (x0, y0))
        self.content = (M + FRAME_L + 8, M + FRAME_T + 2, M + w - FRAME_R - 8, M + h - FRAME_B - (52 if buttons else 8))
        self.side_tabs, self.buttons, self.bands = side_tabs, buttons, bands

    def finish(self):
        c, M, w, h = self.canvas, self.MARGIN, self.w, self.h
        for i, ico in enumerate(self.side_tabs):
            y = M + FRAME_T + 10 + i * 50
            put(c, part("patch").resize(zz(44, 44), Image.LANCZOS), (M - 30, y))
            if ico is not None:
                g = ImageOps.grayscale(ico.convert("RGB")).resize(zz(22, 22), Image.LANCZOS)
                mark = Image.new("RGBA", g.size, (30, 18, 10, 0))
                mark.putalpha(ImageOps.invert(g).point(lambda v: int(v * 0.6)))
                put(c, mark, (M - 19, y + 11))
        # the edges first, the whole height, so their leather runs on under the top's and bottom's fades
        # the sides from under the top's corners to the foot, the bottom (the left side turned) along the foot, and
        # where they meet a mitred corner: each side owns the half of the corner square on its side of the line
        # from the inner corner to the outer one
        edge_h = z(h - EDGES_HEAD)
        left, right = column(piece("frame-left"), edge_h), column(piece("frame-right"), edge_h)
        span = w - pieces.RIGHT_IN                                       # the book's width, the bottom's length
        bottom = Image.new("RGBA", (z(span), z(FRAME_B)))
        tile = piece("frame-bottom")
        for x in range(0, bottom.width, tile.width):
            bottom.alpha_composite(tile, (x, 0))
        lw, rw, bh = left.width, right.width, bottom.height
        keep = Image.new("L", left.size, 255)
        ImageDraw.Draw(keep).polygon([(0, edge_h), (lw, edge_h - bh), (lw, edge_h)], fill=0)
        left.putalpha(ImageChops.multiply(left.getchannel("A"), keep))
        keep = Image.new("L", right.size, 255)
        ImageDraw.Draw(keep).polygon([(rw, edge_h), (0, edge_h - bh), (0, edge_h)], fill=0)
        right.putalpha(ImageChops.multiply(right.getchannel("A"), keep))
        cut = Image.new("L", bottom.size, 255)
        ImageDraw.Draw(cut).polygon([(0, 0), (lw, 0), (0, bh)], fill=0)
        ImageDraw.Draw(cut).polygon([(bottom.width, 0), (bottom.width - rw, 0), (bottom.width, bh)], fill=0)
        bottom.putalpha(ImageChops.multiply(bottom.getchannel("A"), cut))
        put(c, bottom, (M, M + h - FRAME_B))
        put(c, left, (M, M + EDGES_HEAD))
        put(c, right, (M + span - FRAME_L, M + EDGES_HEAD))
        # the bottom corners rounded as #12's, its metal caps over them
        for side in ("left", "right"):
            box = pieces.CAPS[side]
            cw, ch = box[2] - box[0], box[3] - box[1]
            at = (M, M + h - ch) if side == "left" else (M + w - (pieces.FRAME_X[3] - box[0]), M + h - ch)
            shape = piece(f"frame-corner-{side}").getchannel("A")
            region = c.crop((z(at[0]), z(at[1]), z(at[0]) + shape.width, z(at[1]) + shape.height))
            region.putalpha(ImageChops.multiply(region.getchannel("A"), shape))
            c.paste(region, zz(*at))
            put(c, piece(f"frame-cap-{side}"), at)
        put(c, piece("frame-clasp"), (M + w - CLASP_W, M + (h - CLASP_H) // 2))
        put(c, butt(*(piece(f"frame-top-{e}") for e in ("left", "middle", "right")), z(w)), (M, M))
        # the title on the label, in Kalam; the close button on the corner patch, pressed in
        write(c, (M + TITLE_AT[0], M + TITLE_AT[1]), self.title, 22, "Bold", anchor="lm")
        press(c, (M + w - CLOSE_FROM_RIGHT[0], M + CLOSE_FROM_RIGHT[1]), "x", 17)
        for x, label in self.bands:
            b = part("band")
            b = b.resize((z(44), round(b.height * z(44) / b.width)), Image.LANCZOS)
            put(c, b, (M + x, M + 12))
            press(c, (M + x + 22, M + 12 + b.height / S - 26), label, 11)
        x = M + FRAME_L + 30
        for label in self.buttons:   # the patch stretched by nine slices (its rivets kept), never repeated
            width = 40 + len(label) * 10
            put(c, nine(part("patch"), z(width), z(34), 0.2, 0.2, 0.2, 0.2), (x, M + h - FRAME_B - 44))
            press(c, (x + width // 2, M + h - FRAME_B - 27), label, 14)
            x += width + 8
        return c


PENCIL_H = 58      # #14's pencil box is drawn at this height (its lines' weight); bigger boxes stretch its sides


def pbox(canvas, rect, active=False):
    """A box drawn on the paper from #14's pencil lines (pencil-box), corners kept, sides stretched: transparent
    inside, so it takes the page's colour. Boxes, buttons and tabs on paper are made of it."""
    x0, y0, x1, y1 = zz(*rect)
    p = part("pencil-box")
    k = min(z(PENCIL_H), y1 - y0) / p.height           # one line weight for every box, whatever its size
    p = p.resize((max(8, round(p.width * k)), max(8, round(p.height * k))), Image.LANCZOS)
    m = 0.3                                            # the corners and both lines of #14 kept whole
    piece_ = nine(p, x1 - x0, y1 - y0, m * p.height / p.width, m, m * p.height / p.width, m)
    if active:   # the chosen one: its lines a little stronger
        piece_.putalpha(piece_.getchannel("A").point(lambda v: min(255, int(v * 1.5))))
    canvas.alpha_composite(piece_, (x0, y0))


def prule(canvas, a, b):
    """A pencil rule from a to b: #14's top line (pencil-rule), stretched, at the boxes' line weight."""
    rule = part("pencil-rule")
    t = max(3, round(rule.height * z(PENCIL_H) / part("pencil-box").height))
    length = z(abs(b[0] - a[0]))
    canvas.alpha_composite(rule.resize((max(1, length), t), Image.LANCZOS), (z(min(a[0], b[0])), z(a[1]) - t // 2))


def top_tabs(canvas, x, y, labels, style, active=0, height=34, right=None):
    """The row of tabs under the top (Saneroki, 2026-10-21): 'arrow' (the interlocking leather arrow tabs, each tip
    in the next one's cut, labels pressed in) or 'drawn' (#14's pencil lines on the paper, labels in Kalam). right:
    no tab runs past it."""
    for i, label in enumerate(labels):
        if style == "arrow":
            tab = part("top-tab-arrow")
            d = round(height * tab.width / tab.height * 0.115)          # the point's length at this height
            width = 50 + len(label) * 9 + d
            if right and x + width > right:
                break
            put(canvas, three(tab, z(width), z(height), cap=min(0.3, (d + 12) / (tab.width * height / tab.height))), (x, y))
            press(canvas, (x + (width + d // 2) // 2, y + height // 2), label, 14)
            x += width - d + 1
        else:
            width = 30 + len(label) * 10
            if right and x + width > right:
                break
            pbox(canvas, (x, y - (3 if i == active else 0), x + width, y + height), i == active)
            write(canvas, (x + width // 2, y + height // 2 + 1), label, 18, "Bold" if i == active else "Regular", anchor="mm")
            x += width + 3
    return x


def bubble(canvas, x, y, w, name, cls, channel, time, text, flip=False, seed=0):
    """A chat bubble drawn as one piece of paper (#41's layout and silhouette): a low rounded body two lines high,
    a round bulge over its top left corner (top right when flipped) holding the sketched class icon, the small
    tail below; one tiny pencil outline round the whole shape. The name in its class colour with an outline,
    the channel and time beside it, the message under it."""
    h, R, pad = 52, 19, 7
    if w is None:   # as wide as its text needs
        meta = f"[{channel}]  {time}"
        top = (R + 14) + (font(16, "Bold").getlength(name) + 7 * S + font(12, "Light").getlength(meta)) / S
        w = int(max(top, font(15).getlength(text) / S + 2 * pad + 8) + pad + 6)
    cx = x + 10 if not flip else x + w - 10           # the bulge's centre
    cy = y + 6
    m = 30                                            # room round the shape on its layer
    L = Image.new("L", zz(w + 2 * m, h + 2 * m))
    d = ImageDraw.Draw(L)
    d.rounded_rectangle(zz(m, m, m + w, m + h), radius=z(7), fill=255)
    d.ellipse(zz(cx - x + m - R, cy - y + m - R, cx - x + m + R, cy - y + m + R), fill=255)
    tx0 = m + 18 if not flip else m + w - 18
    sgn = 1 if not flip else -1
    d.polygon([zz(tx0, m + h - 1), zz(tx0 + sgn * 14, m + h - 1), zz(tx0 - sgn * 6, m + h + 11)], fill=255)
    L = L.filter(ImageFilter.GaussianBlur(0.6 * S))
    layer = paper.page(L.width, L.height, f"bubble{seed}{name}", edge=0, stained=False)
    layer = Image.blend(layer, Image.new("RGBA", layer.size, (255, 248, 232, 255)), 0.12)
    layer.putalpha(L)
    outline = ImageChops.subtract(L, L.filter(ImageFilter.MinFilter(2 * max(1, S) + 1)))
    ink = Image.new("RGBA", layer.size, LEAD + (0,))
    ink.putalpha(outline.point(lambda v: int(v * 0.75)))
    layer.alpha_composite(ink)
    put(canvas, layer, (x - m, y - m))
    put(canvas, sketch(icon(f"ClassIcon_{cls}.blp", 64), 2 * R - 8, ring=False), (cx - R + 4, cy - R + 4))
    nx = x + R + 14 if not flip else x + pad + 4
    write(canvas, (nx, y + 4), name, 16, "Bold", CLASS.get(cls, LEAD), 245, outline=True)
    nw = font(16, "Bold").getlength(name) / S
    write(canvas, (nx + nw + 7, y + 7), f"[{channel}]  {time}", 12, "Light")
    line(canvas, (x + pad + 2, y + 27), (x + w - pad - 2, y + 27), 60, 1, seed + 3)
    write(canvas, (x + pad + 4, y + 29), text, 15)
    return w


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


# Where #3 (doll.png) has its slots and strips, in its own pixels (the layout's): the view is that picture, its
# painted frame, arcs and overhanging strips kept as they are; code only puts the live content into it.
DOLL_ROWS = [198, 280, 362, 443, 523, 603, 683]                 # the tops of the seven rows with strips
ARC = 30                                                         # how far the middle rows move outward, pixels
DOLL = {"top": [(310, 100, 400, 190), (605, 100, 700, 190)],      # the two top slots (no strip)
        "left": [((340, y + 4, 404, y + 68), (230, y, 336, y + 70)) for y in DOLL_ROWS],
        "right": [((614, y + 4, 678, y + 68), (680, y, 786, y + 70)) for y in DOLL_ROWS],
        "weapons": [((302, 792, 398, 878), (260, 895, 413, 943)), ((456, 792, 554, 878), (430, 895, 583, 943)),
                    ((614, 792, 710, 878), (599, 895, 753, 943))],
        "ammo": (722, 826, 766, 868)}
DOLL_BOX = (172, 56, 852, 958)          # the window in #3: its frame, the strips over it, its rows' arcs


def clean(canvas, rect, seed):
    """A strip's painted writing covered by paper of its own tone: only over the strip's own paper (its light
    pixels, shrunk away from its pencil edge), feathered in. rect and the strip's paper it returns: layout pixels."""
    x0, y0, x1, y1 = zz(*rect)
    w, h = x1 - x0, y1 - y0
    region = canvas.crop((x0, y0, x1, y1)).convert("RGB")
    lum = np.asarray(region.convert("L"))
    cut = float(np.percentile(lum, 60)) - 22            # the strip's paper, whatever the page's tone
    light = region.convert("L").point(lambda v: 255 if v > cut else 0)
    # the paper is what the light pixels enclose; small dark marks (the writing) inside it count as paper
    paper_mask = light.filter(ImageFilter.MaxFilter(z(9) | 1)).filter(ImageFilter.MinFilter(z(15) | 1))
    tone = np.median(np.asarray(region)[np.asarray(light) > 0].reshape(-1, 3), axis=0)
    patch = np.asarray(paper.page(w, h, seed, edge=0, stained=False).convert("RGB"), dtype=np.float32)
    patch = patch * (tone / patch.reshape(-1, 3).mean(axis=0))
    patch = Image.fromarray(patch.clip(0, 255).astype(np.uint8)).convert("RGBA")
    patch.putalpha(paper_mask.filter(ImageFilter.GaussianBlur(2 * S)))
    canvas.alpha_composite(patch, (x0, y0))
    bx = paper_mask.getbbox() or (0, 0, w, h)
    return ((x0 + bx[0]) / S, (y0 + bx[1]) / S, (x0 + bx[2]) / S, (y0 + bx[3]) / S)


def fit(text, size, width, weight="Regular"):
    """The largest size up to size at which text fits width (layout pixels)."""
    while size > 9 and font(size, weight).getlength(text) / S > width:
        size -= 1
    return size


def stats_in(canvas, rect, lines):
    x0, y0, x1, y1 = rect
    y = y0 + 6
    for text, size in lines:
        size = fit(text, size, x1 - x0 - 16)
        write(canvas, (x0 + 8, y), text, size)
        y += size + 3


def doll_bent(c=None):
    """The doll (the piece doll, #3, or c: a copy of it at this scale) with its two slot columns bent along the
    arc; and how far each row moved outward (layout pixels). The game's doll is made from it too
    (dev/tools/journal-art)."""
    c = (c or piece("doll")).copy()                              # #3 cleaned, on the page's tone, outside transparent
    # the arcs (Saneroki, 2026-10-21: the slots in a rounded layout, not straight under each other): each row of
    # slot and strip moves outward, most in the middle rows, so the columns bow round the hero; the gap a moved
    # row leaves next to the hero's frame is filled with the paper of that spot
    shift = {}
    tones = {sgn: tuple(int(v) for v in np.median(np.asarray(c.crop(zz(*box)).convert("RGB")).reshape(-1, 3), axis=0))
             for sgn, box in ((-1, (372, 269, 402, 278)), (1, (622, 269, 652, 278)))}   # the paper between two rows
    for j in range(len(DOLL_ROWS)):
        shift[j] = round(ARC * math.sin(math.pi * (j + 1) / 7))
    # the two columns bent along the arc as one piece (each pixel row moved by the arc at its height, easing to
    # nothing above the first row and below the last), so the frame's edge curves with them, no steps; the room
    # each leaves beside the hero's frame is paper of that spot
    top, bottom = DOLL_ROWS[0] - 40, DOLL_ROWS[-1] + 110
    knots = [top] + [y + 35 for y in DOLL_ROWS] + [bottom]
    ys = np.arange(z(top), z(bottom))
    dxs = np.rint(np.interp(ys / S, knots, [0] + [shift[j] for j in range(len(DOLL_ROWS))] + [0]) * S).astype(int)
    a = np.asarray(c).copy()
    for (x0, x1), sgn in (((DOLL_BOX[0], 410), -1), ((606, DOLL_BOX[2]), 1)):
        X0, X1 = z(x0), z(x1)
        src = a[ys[0]:ys[-1] + 1, X0:X1].copy()
        fill = np.asarray(paper.page(z(ARC) + 2, len(ys), f"arc{sgn}", edge=0, stained=False, tone=tones[sgn]))
        for r, d in enumerate(dxs):
            y = ys[r]
            if sgn < 0:
                a[y, X0 - d:X1 - d] = src[r]
                a[y, X1 - d:X1] = fill[r, :d]
            else:
                a[y, X0 + d:X1 + d] = src[r]
                a[y, X0:X0 + d] = fill[r, :d]
    return Image.fromarray(a), shift


def view_character():
    """The character doll: Saneroki's pick itself (the piece doll, #3), its frame, the slots in their arcs and the
    paper strips over the leather kept as painted; code puts the live content in: game icons in the slots, each
    strip's writing replaced by the item's stats in Kalam. The hero stands in for the game's live model."""
    c, shift = doll_bent()
    left, right = GEAR["left"], GEAR["right"]
    for sl, (name, pattern) in zip(DOLL["top"], [left[0], right[0]]):
        x0, y0, x1, y1 = sl
        put(c, icon(pattern, x1 - x0 - 20, 0), (x0 + 10, y0 + 10))
    for side, gear, first in (("left", left[1:], 1), ("right", right[1:], 9)):
        for i, ((sl, st), (name, pattern)) in enumerate(zip(DOLL[side], gear)):
            sgn = -1 if side == "left" else 1
            sl = (sl[0] + sgn * shift[i], sl[1], sl[2] + sgn * shift[i], sl[3])
            st = (st[0] + sgn * shift[i], st[1], st[2] + sgn * shift[i], st[3])
            x0, y0, x1, y1 = sl
            put(c, icon(pattern, x1 - x0 - 12, i + 1), (x0 + 6, y0 + 6))
            k = first + i
            stats_in(c, clean(c, st, f"{side}{i}"), [(ITEMS[k], 14), (f"{name} · ilvl {58 + (k * 7) % 9}", 12), (f"+{8 + k % 6} Sta  +{5 + k % 4} Str", 12)])
    for i, ((sl, st), (name, pattern)) in enumerate(zip(DOLL["weapons"], GEAR["bottom"])):
        x0, y0, x1, y1 = sl
        put(c, icon(pattern, x1 - x0 - 24, i), (x0 + 12, y0 + 12))
        stats_in(c, clean(c, st, f"weapon{i}"), [(f"{ITEMS[16 + i]}  ·  ilvl {60 + i}", 13), (f"{name}  ·  +12 Str  +9 Sta", 11)])
    x0, y0, x1, y1 = DOLL["ammo"]
    put(c, icon("INV_Ammo_Arrow_0*", x1 - x0 - 8), (x0 + 4, y0 + 4))
    return c


def view_bags():
    """Bags and bank (bags-page.png): a condensed page cut into close sections, a pencil-ruled header each, dense
    grids of item icons; tabs down the left change the content."""
    W, H = 900, 900
    win = Window(W, H, "Bags", side_tabs=[icon("INV_Misc_Bag_0*", 32), icon("INV_Misc_Herb_0*", 32),
                                           icon("INV_Misc_Coin_0[1-9]*", 32), icon("INV_Misc_Key_0*", 32)],
                 buttons=["Sort", "Bank", "Junk"], seed="bags")
    c = win.canvas
    x0, y0, x1, y1 = win.content
    sections = [("Consumables", "INV_Potion_*", 22), ("Trade goods", "INV_Fabric_*", 15), ("Armour", "INV_Chest_*", 11),
                ("Weapons", "INV_Sword_*", 9), ("Quest items", "INV_Misc_Note_*", 6), ("Junk", "INV_Misc_Bone_*", 8)]
    y, s, cols = y0 + 14, 42, 18
    rnd = random.Random(3)
    for title, pattern, n in sections:
        write(c, (x0 + 18, y), title, 18, "Bold")
        write(c, (x1 - 18, y + 3), f"{n} items", 13, "Light", anchor="ra")
        prule(c, (x0 + 16, y + 26), (x1 - 16, y + 26))
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


CHAT = [("left", "Elowen", "Druid", "Guild", "20:41", "Anyone up for the Deadmines in ten?"),
        ("left", "Brannoc", "Warrior", "Guild", "20:42", "I can tank. Need a healer too."),
        ("right", "Saneroki", "Mage", "Guild", "20:42", "Count me in, bringing water."),
        ("middle", "Mira", "Priest", "Guild", "20:43", "I'll heal!"),
        ("left", "Tolvar", "Hunter", "Guild", "20:44", "Meet at the Sentinel Hill flight point."),
        ("right", "Saneroki", "Mage", "Guild", "20:44", "On my way, five minutes."),
        ("middle", "Brannoc", "Warrior", "Guild", "20:45", "Invites out."),
        ("left", "Elowen", "Druid", "Guild", "20:45", "Got it, thanks!"),
        ("left", "Kestrel", "Rogue", "Guild", "20:46", "Save me a spot for the next run."),
        ("right", "Saneroki", "Mage", "Guild", "20:46", "Will do!"),
        ("left", "Tolvar", "Hunter", "Guild", "20:47", "Anyone selling Silk Cloth?")]


def view_chat(W=760, H=980):
    """A chat window (the interlocking arrow tabs at its top): bubbles on the page, others' at the left, the
    player's own at the right, a few short ones in the middle, as many as the page holds."""
    win = Window(W, H, "Chat", buttons=["Send"], seed="chat")
    c = win.canvas
    x0, y0, x1, y1 = win.content
    top_tabs(c, x0 + 6, y0 + 4, ["General", "Guild", "Party", "Whispers", "Trade"], "arrow", 1, right=x1 - 6)
    y = y0 + 64
    for side, name, cls, ch, t, text in CHAT:
        if y + 60 > y1 - 90:
            break
        w = int(max(font(16, "Bold").getlength(name) / S + 140, font(15).getlength(text) / S + 30) + 10)
        x = {"left": x0 + 26, "right": x1 - 26 - w, "middle": (x0 + x1) // 2 - w // 2}[side]
        bubble(c, x, y, w, name, cls, ch, t, text, flip=(side == "right"))
        y += 70
    prule(c, (x0 + 18, y1 - 50), (x1 - 120, y1 - 50))
    write(c, (x0 + 22, y1 - 76), "Say something to the guild ...", 16, "Light", alpha=140)
    return win.finish()


def view_guild(W=1500, H=1000):
    """The guild window (guild-board.png): the paper top with the emblem, name and member count, the row of drawn
    tabs, the board's panels as pencil frames on the paper (no leather on it). Three columns when it is wide (the
    middle one the guild's chat), two when it is narrow."""
    win = Window(W, H, "Guild", seed="guild")
    c = win.canvas
    x0, y0, x1, y1 = win.content
    put(c, sketch(icon("INV_Shirt_GuildTabard*", 64), 70), (x0 + 18, y0 + 10))
    write(c, (x0 + 100, y0 + 12), "The Grey Wardens", 30, "Bold")
    write(c, (x0 + 102, y0 + 52), "48 members, 12 online", 17)
    prule(c, (x0 + 14, y0 + 90), (x1 - 14, y0 + 90))
    top_tabs(c, x0 + (100 if W >= 1200 else 14), y0 + 92, ["Board", "Members", "Armory", "Loot", "Crafting", "Raids", "Officers"],
             "drawn", 0, right=x1 - 14)
    py = y0 + 142
    wide = W >= 1200
    if wide:
        cols = [(x0 + 14, x0 + 470), (x0 + 482, x0 + 900), (x0 + 912, x1 - 14)]
    else:
        mid = (x0 + x1) // 2
        cols = [(x0 + 14, mid - 6), None, (mid + 6, x1 - 14)]

    def panel(rect, title):
        pbox(c, rect)
        write(c, (rect[0] + 22, rect[1] + 12), title, 19, "Bold")
        y = rect[1] + 12 + font(19, "Bold").getbbox(title)[3] / S + 6    # under the title's letters (Kalam sits low)
        prule(c, (rect[0] + 18, y), (rect[2] - 18, y))
        return rect[0] + 22, y + 8

    def name_size(text, room, size):
        return fit(text, size, room)

    x, y = panel((cols[0][0], py, cols[0][1], py + 300), "Looking for help")
    room = cols[0][1] - x - 70
    for i, (n, cls, q, lv) in enumerate([("Elowen", "Druid", "The Defias Brotherhood", 18), ("Tolvar", "Hunter", "Wanted: Hogger", 11),
                                          ("Mira", "Priest", "The Missing Diplomat", 25), ("Brannoc", "Warrior", "In Sickness and in Health", 28),
                                          ("Kestrel", "Rogue", "The Tome of Divinity", 22)]):
        write(c, (x, y + i * 48), q, name_size(q, room, 17))
        write(c, (x, y + i * 48 + 20), f"{n} · Westfall", 14, "Light", CLASS[cls], outline=True)
        write(c, (cols[0][1] - 18, y + i * 48 + 4), f"lvl {lv}", 15, anchor="ra")
    x, y = panel((cols[0][0], py + 312, cols[0][1], y1 - 14), "Planned runs")
    for i, (d, t, open_) in enumerate([("The Deadmines", "20:00", "1 tank · 2 dps"), ("Wailing Caverns", "Wed 19:30", "full"),
                                        ("Shadowfang Keep", "Thu 21:00", "1 heal"), ("Razorfen Kraul", "Sat 18:00", "2 dps")]):
        if y + i * 50 + 44 > y1 - 20:
            break
        write(c, (x, y + i * 50), d, 17)
        write(c, (x, y + i * 50 + 22), open_, 14, "Light")
        write(c, (cols[0][1] - 18, y + i * 50 + 4), t, 16, "Bold", anchor="ra")
    if wide:
        x, y = panel((cols[1][0], py, cols[1][1], y1 - 14), "Guild chat")
        for i, (n, cls, text) in enumerate([("Elowen", "Druid", "Anyone for the Deadmines?"), ("Brannoc", "Warrior", "I can tank."),
                                            ("Mira", "Priest", "I'll heal!"), ("Tolvar", "Hunter", "Ding 30!"), ("Kestrel", "Rogue", "Grats!")]):
            bubble(c, x + 14 + (60 if i % 2 else 0), y + 8 + i * 74, None, n, cls, "Guild", f"20:4{i}", text, flip=bool(i % 2))
    left_, right_ = cols[2]
    x, y = panel((left_, py, right_, py + 330), "Race to level 60")
    base = py + 290
    cw = (right_ - left_ - 40) // 3                          # three steps across the panel's width
    depth = min(22, cw // 5)
    for px, h in ((0, 90), (1, 120), (2, 66)):              # left to right, so each step covers the side behind it
        block(c, left_ + 20 + px * cw, base, cw - depth, h, depth, px)
    for rank, (n, cls, lv, h, px) in enumerate([("Brannoc", "Warrior", 58, 120, 1), ("Elowen", "Druid", 57, 90, 0), ("Mira", "Priest", 55, 66, 2)]):
        bx = left_ + 20 + px * cw
        mx = bx + (cw - depth) // 2
        write(c, (mx, base - h + 8), str(rank + 1), 30, "Bold", anchor="ma")
        put(c, sketch(icon(f"ClassIcon_{cls}.blp", 64), 52), (mx - 26, base - h - 112))
        write(c, (mx, base - h - 56), n, fit(n, 18, cw - 4, "Bold"), "Bold", CLASS[cls], anchor="ma", outline=True)
        write(c, (mx, base - h - 34), f"level {lv}", 14, anchor="ma")
    x, y = panel((left_, py + 342, right_, y1 - 14), "Offered to the guild")
    for i, (pattern, name, who) in enumerate([("INV_Sword_0*", "Blade of the March", "Brannoc"), ("INV_Misc_Cape_0*", "Cloak of Dusk", "Mira"),
                                              ("INV_Jewelry_Ring_0*", "Band of the Tide", "Kestrel"), ("INV_Misc_Gem_*", "Shard of Night", "Tolvar")]):
        if y + i * 54 + 46 > y1 - 20:
            break
        slot(c, x, y + i * 54, 44, icon(pattern, 64, i + 5))
        write(c, (x + 56, y + i * 54 + 2), name, 17)
        write(c, (x + 56, y + i * 54 + 22), f"from {who}", 14, "Light")
    return win.finish()


def view_spellbook():
    """A spellbook: the schools as side tabs, two pages of spells (icon, name, rank) divided by a pencil fold,
    a band hanging from the top for the filter overlay."""
    W, H = 900, 900
    schools = ["Spell_Fire_FlameBolt", "Spell_Frost_FrostBolt02", "Spell_Nature_StarFall", "Spell_Holy_*"]
    win = Window(W, H, "Spellbook", side_tabs=[icon(p + ("" if "*" in p else ".blp"), 32) for p in schools],
                 buttons=["Previous", "Next"], bands=[(W - 150, "Filter")], seed="spellbook")
    c = win.canvas
    x0, y0, x1, y1 = win.content
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
    W, H = 560, 900
    win = Window(W, H, "Character", side_tabs=[icon("INV_Chest_Plate0*", 32), icon("Spell_Nature_*", 32)],
                 seed="stats")
    c = win.canvas
    x0, y0, x1, y1 = win.content
    top_tabs(c, x0 + 10, y0 + 6, ["Stats", "Skills", "Reputation", "Currency"], "drawn", 0, right=x1 - 6)
    groups = [("Attributes", [("Strength", "142"), ("Agility", "87"), ("Stamina", "215"), ("Intellect", "41"), ("Spirit", "58")]),
              ("Melee", [("Damage", "88 – 131"), ("Speed", "2.60"), ("Power", "396"), ("Hit", "+3 %"), ("Crit chance", "6.48 %")]),
              ("Defence", [("Armour", "3,412"), ("Defence", "305"), ("Dodge", "5.21 %"), ("Parry", "6.02 %"), ("Block", "4.10 %")])]
    y = y0 + 64
    for title, rows in groups:
        write(c, (x0 + 22, y), title, 19, "Bold")
        prule(c, (x0 + 20, y + 28), (x1 - 20, y + 28))
        y += 36
        for n, v in rows:
            write(c, (x0 + 30, y), n, 17)
            write(c, (x1 - 30, y), v, 17, anchor="ra")
            y += 26
        y += 14
    return win.finish()


def backdrop(w, h):
    """What lies behind the windows: the dark of BG, a little lighter in the middle."""
    img = Image.new("RGBA", zz(w, h), BG + (255,))
    g = Image.radial_gradient("L").resize(img.size).point(lambda v: 255 - v)
    return Image.composite(Image.new("RGBA", img.size, (58, 52, 44, 255)), img, g)


def view_bubbles():
    """Chat bubbles floating over the world, two lines each."""
    img = backdrop(900, 520)
    for i, (n, cls, ch, t, text) in enumerate([("Elowen", "Druid", "Say", "20:41", "Watch out, there's a patrol!"),
                                                ("Brannoc", "Warrior", "Party", "20:41", "Pulling the next pack."),
                                                ("Mira", "Priest", "Yell", "20:42", "Heals incoming!")]):
        bubble(img, 160 + i * 40, 100 + i * 110, None, n, cls, ch, t, text)
    return img


FULL = (1920, 1080)        # the full screen's layout: 3840 x 2160 at 4K
GAP = 22                   # between the windows and round them


def view_fullscreen():
    """A full screen at 4K made of the pieces alone: the character window (the doll) at the left, the guild window
    in the middle, the chat window at the right, side by side on the dark; each window as the other views draw it."""
    W, H = FULL
    img = backdrop(W, H)
    doll = view_character().crop(zz(*DOLL_BOX))
    dw, dh = doll.width / S, doll.height / S
    put(img, doll, (GAP, (H - dh) / 2))
    wh = H - 2 * GAP                                   # the windows' height: the screen's, less the gaps
    chat_w = 520
    guild_x = GAP + dw + GAP
    guild_w = W - guild_x - chat_w - 2 * GAP
    M = Window.MARGIN
    put(img, view_guild(int(guild_w), wh), (guild_x - M, GAP - M))
    put(img, view_chat(chat_w, wh), (W - GAP - chat_w - M, GAP - M))
    return img


VIEWS = {"character": view_character, "bags": view_bags, "chat": view_chat, "guild": view_guild,
         "spellbook": view_spellbook, "stats": view_stats, "bubbles": view_bubbles, "fullscreen": view_fullscreen}
SCALE_OF = {"fullscreen": 2}   # views always made at their own scale


def main(args):
    global S
    scale = 1
    if args[:1] == ["--scale"]:
        scale, args = float(args[1]), args[2:]
        scale = int(scale) if scale == int(scale) else scale
    os.makedirs(OUT, exist_ok=True)
    for name in args or VIEWS:
        S = SCALE_OF.get(name, scale)
        paper.SCALE = S
        img = VIEWS[name]()
        if name != "fullscreen":                       # the windows come on transparency: shown on the dark
            under = backdrop(img.width / S, img.height / S)
            under.alpha_composite(img)
            img = under
        img = img.convert("RGB")
        img.save(os.path.join(OUT, name + ".png"))
        print(name, img.size)


if __name__ == "__main__":
    main(sys.argv[1:])
