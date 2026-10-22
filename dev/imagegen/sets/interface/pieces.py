#!/usr/bin/env python3
"""The final pieces (Doc/guides/interface-style.md, *Pieces*): every decided element at 4K, alone on transparency,
trimmed to what it covers, so code can build any of Sane UI's windows from them like a puzzle. Made in code from
the parts at 4K (catalog.py hires: one render each) and from the decided references; nothing is painted here.
  window      #12 cut into its pieces: the top's two ends and its middle (stretched), the bottom's the same, the
              left and right edges (tiles that repeat without a seam), the clasp; the window's paper moved to the
              page's tone, its outside transparent (the background removal's mask, catalog.py masks)
  doll        #3 whole (the character window: its frame, slots and strips), on the page's tone, outside transparent
  parts       the leather patch, the top tabs, the edges, every kit part: their light rims (the pick's background
              left at their edge) taken off
  pencil      #14's pencil lines alone (a box, its top line as a rule)
  paper       the parchment; the stains and the sketches (decorations code lays over the paper)
pieces.json lists each piece: its file, size, and how code lays it (what stretches, what repeats, its margins).
  python3 dev/imagegen/sets/interface/pieces.py   ->  assets/generated/interface/pieces/<piece>.png, pieces.json
"""
import glob, json, os, sys
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "../../../..")
sys.path.insert(0, HERE)
import paper  # noqa: E402

GEN = os.path.join(ROOT, "assets/generated/interface")
HIRES = os.path.join(GEN, "hires")
REFS = os.path.join(ROOT, "assets/Concept art/UI style")
OUT = os.path.join(GEN, "pieces")
SCALE = 2           # the pieces are at 4K: twice the pixels of the picks (a layout pixel at 1080p)

# The window: #12 (clean/frame.png) in its own pixels (the 1080p layout's), cut at SCALE
FRAME_X = (196, 380, 530, 836)         # left end | middle (no rivet, stretched) | right end of the top
FRAME_TOP = (86, 210)                  # the top: strap, ribbon, corner patch, title label, a little paper
FRAME_BOTTOM_X = (196, 262, 748, 836)  # the bottom: its left corner | the page stack (stretched whole) | right corner
FRAME_BOTTOM = (806, 876)              # the bottom: the page's lowest stretch curling onto its stack, the stack, the
                                       # corners (catalog.py bottom painted them as one piece)
PAGE_END = 832                         # about where the page ends on the stack: content stays above it
CAPS = 828                             # where the corner caps begin: above it, outside BINDING, the bottom is left
BINDING = (228, 772)                   # to the edges' tiles (#12's strap, cut there, left a knot on the right one)
EDGES_END = 846                        # the edges' tiles run down to here, under the corner caps
EDGES_START = 106                      # and from here, under the top's corners (above it #12's cover has not begun)
FRAME_LEFT = (196, 240, 300, 600)      # the left edge: x from-to, the plain stretch it repeats (y)
FRAME_RIGHT = (764, 836, 230, 370)     # the right edge, above its clasp
CLASP = (764, 380, 836, 510)
TITLE_AT = (372, 182)                  # where the title label's writing starts
LABEL = (332, 166, 712, 196)           # the title label's inside: its light evened out (the paper that covered its
                                       # writing showed as lighter blocks), its grain kept
CLOSE_AT = (770, 124)                  # the middle of the corner patch on the strap: the close button
TOP_FADE, BOTTOM_FADE = 26, 14         # the top's and bottom's paper fades into the page over so many pixels
FRAME_PAPER = (300, 200, 560, 240)     # a stretch of #12's plain paper, for its tone
DOLL_PAPER = (420, 120, 470, 200)      # the same in #3 (behind the hero's head)

# piece: its part at 4K (hires/<part>.png), a cut-out whose rim is cleaned
PARTS = {"patch": "patch", "tab-arrow": "top-tab-arrow", "tab-arrow-b": "top-tab-arrow-b", "tab-patch": "top-tab-patch",
         "edge-left": "edge-left", "edge-right": "edge-right"}
PARTS.update({k: k for k in [f"kit3-{i:02}" for i in range(1, 12)] + [f"kit4-{i:02}" for i in range(1, 12)]})
RIM = 3             # pixels of a cut-out's rim recoloured from inside it (the pick's light background left there)


def z(box):
    return tuple(v * SCALE for v in box)


def spread(rgb, known, steps, light=False):
    """rgb's colours carried from the known pixels into the unknown ones next to them, a ring per step; light: the
    lighter known pixels count far more (a hole was light metal)."""
    a = rgb.astype(np.float32).copy()
    k = known.astype(np.float32)
    if light:
        k = k * (a.mean(axis=2) / 255) ** 6 + k * 1e-4
    for _ in range(steps):
        if k.min() > 0:
            break
        s, n = np.zeros_like(a), np.zeros_like(k)
        ak = a * k[..., None]
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy or dx:
                    s += np.roll(ak, (dy, dx), (0, 1))
                    n += np.roll(k, (dy, dx), (0, 1))
        new = (k == 0) & (n > 0)
        a[new] = s[new] / n[new][:, None]
        k[new] = n[new] / 8
    return a


def fill_holes(img):
    """A cut-out's holes (pixels the cut keyed out, wholly or in part, inside the shape: light metal taken for the
    background) made solid, their colour carried in from round them; its outer rim stays as it is. Returns the
    picture and whether it had any."""
    a = img.getchannel("A")
    pad = Image.new("L", (img.width + 2, img.height + 2), 0)
    shape = a.point(lambda v: 255 if v > 24 else 0)
    shape = shape.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.MinFilter(5))
    pad.paste(shape, (1, 1))                           # small gaps to the outside closed too
    ImageDraw.floodfill(pad, (0, 0), 128)
    inside = pad.crop((1, 1, img.width + 1, img.height + 1)).point(lambda v: 0 if v == 128 else 255)
    deep = np.asarray(inside.filter(ImageFilter.MinFilter(7))) > 0    # more than the rim's width inside
    known = np.asarray(a) >= 250
    holes = deep & ~known
    if not holes.any():
        return img, False
    rgb = np.asarray(img.convert("RGB"))
    out = np.where(holes[..., None], spread(rgb, known, 200, light=True), rgb).clip(0, 255).astype(np.uint8)
    res = Image.fromarray(out).convert("RGBA")
    alpha = np.asarray(a).copy()
    alpha[holes] = 255
    res.putalpha(Image.fromarray(alpha))
    return res, True


def clean_rim(img, rim=RIM):
    """A cut-out's outer rim (its soft edge and a pixel or two in) coloured from just inside it, so no light or
    grey halo of the pick's background shows round it on any page."""
    a = np.asarray(img.getchannel("A"))
    inner = np.asarray(img.getchannel("A").point(lambda v: 255 if v >= 250 else 0).filter(ImageFilter.MinFilter(2 * rim + 1))) > 0
    band = (a > 0) & ~inner
    if not band.any():
        return img
    rgb = np.asarray(img.convert("RGB"))
    out = np.where(band[..., None], spread(rgb, inner, 2 * rim + 4), rgb).clip(0, 255).astype(np.uint8)
    res = Image.fromarray(out).convert("RGBA")
    res.putalpha(img.getchannel("A"))
    return res


def tone_shift(img, sample):
    """A pick's paper moved to the page's decided tone (paper.TONE), so it meets code's pages without a step; its
    leather and metal (the dark pixels) keep their own colours, the light ones move fully, those between in part."""
    rgba = img.convert("RGBA")
    a = np.asarray(rgba.convert("RGB"), dtype=np.float32)
    x0, y0, x1, y1 = sample
    ref = np.median(a[y0:y1, x0:x1].reshape(-1, 3), axis=0)
    weight = np.clip((a.mean(axis=2, keepdims=True) - 90) / 80, 0, 1)        # 0 for leather, 1 for paper
    a = a * (1 - weight) + a * (np.array(paper.TONE, dtype=np.float32) / ref) * weight
    out = Image.fromarray(a.clip(0, 255).astype(np.uint8)).convert("RGBA")
    out.putalpha(rgba.getchannel("A"))
    return out


def fade(img, side, length):
    """img with its alpha faded to nothing toward a side ('top', 'bottom', 'left', 'right') over length pixels."""
    w, h = img.size
    g = Image.linear_gradient("L")                       # 0 at the top, 255 at the bottom
    ramp = Image.new("L", (w, h), 255)
    if side in ("left", "right"):
        g = g.rotate(90, expand=True).resize((length, h))   # 0 at the right, 255 at the left
        if side == "left":
            g = g.transpose(Image.FLIP_LEFT_RIGHT)
        ramp.paste(g, (0, 0) if side == "left" else (w - length, 0))
    else:
        g = g.resize((w, length))
        if side == "bottom":
            g = g.transpose(Image.FLIP_TOP_BOTTOM)
        ramp.paste(g, (0, 0) if side == "top" else (0, h - length))
    out = img.copy()
    out.putalpha(ImageChops.multiply(img.getchannel("A"), ramp))
    return out


def seamless_x(tile):
    """The tile blended with itself shifted by half across, the shifted copy ruling at its ends: its right end then
    runs on into its left, so repeats join without a seam."""
    w, h = tile.size
    ramp = Image.linear_gradient("L").rotate(90, expand=True).resize((w, h))
    ramp = ramp.point(lambda v: int(255 * min(1, (1 - abs(v - 127.5) / 127.5) * 2.2) ** 1.5))
    return Image.composite(tile, ImageChops.offset(tile, w // 2, 0), ramp)


def seamless_y(tile):
    return seamless_x(tile.rotate(90, expand=True)).rotate(-90, expand=True)


def trim(img, floor=8):
    box = img.getchannel("A").point(lambda v: 255 if v > floor else 0).getbbox()
    return img.crop(box) if box else img


def masked(name, size):
    """The 4K render of a whole pick with its outside transparent (catalog.py masks: the background removal)."""
    img = Image.open(os.path.join(HIRES, name + ".png")).convert("RGB").resize(size, Image.LANCZOS).convert("RGBA")
    img.putalpha(Image.open(os.path.join(HIRES, name + "-mask.png")).convert("L").resize(size, Image.LANCZOS))
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    made = {}

    def save(name, img, how, **extra):
        img.save(os.path.join(OUT, name + ".png"))
        made[name] = {"file": name + ".png", "size": list(img.size), "how": how, **extra}

    # the window, cut along #12's own lines
    f = tone_shift(masked("window", (1024 * SCALE, 1024 * SCALE)), z(FRAME_PAPER))
    lx0_, ly0_, lx1_, ly1_ = z(LABEL)
    inside = f.crop((lx0_, ly0_, lx1_, ly1_))
    a = np.asarray(inside.convert("RGB"), dtype=np.float32)
    light = np.asarray(inside.convert("RGB").filter(ImageFilter.GaussianBlur(4 * SCALE)), dtype=np.float32)
    even = a - light + np.median(light.reshape(-1, 3), axis=0)
    even = Image.fromarray(even.clip(0, 255).astype(np.uint8)).convert("RGBA")
    soft = Image.new("L", inside.size)
    ImageDraw.Draw(soft).rectangle((4 * SCALE, 3 * SCALE, inside.width - 4 * SCALE, inside.height - 3 * SCALE), fill=255)
    f.paste(even, (lx0_, ly0_), soft.filter(ImageFilter.GaussianBlur(2 * SCALE)))
    x0, x1, x2, x3 = z(FRAME_X)
    t0, t1 = z(FRAME_TOP)
    b0, b1 = z(FRAME_BOTTOM)
    for end, (a, b), how in (("left", (x0, x1), "its left end, kept whole"),
                             ("middle", (x1, x2), "its middle, stretched whole between the ends, joined edge to edge (its lines "
                                                 "run along it)"),
                             ("right", (x2, x3), "its right end, kept whole; the close button is its corner patch")):
        save(f"frame-top-{end}", fade(f.crop((a, t0, b, t1)), "bottom", TOP_FADE * SCALE),
             f"the window's top (strap, ribbon, title label): {how}; its paper fades into the page")
    bx0, bx1, bx2, bx3 = z(FRAME_BOTTOM_X)
    for end, (a, b), how in (("left", (bx0, bx1), "its left corner, kept whole"),
                             ("middle", (bx1, bx2), "the page stack, stretched whole between the corners (no repeat, "
                                                    "no cross-fade: its lines run on)"),
                             ("right", (bx2, bx3), "its right corner, kept whole")):
        piece = fade(f.crop((a, b0, b, b1)), "top", BOTTOM_FADE * SCALE)
        if end != "middle":      # the binding above the caps is the edges' (no strap left there)
            keep = Image.new("L", piece.size, 255)
            cut = (0, BINDING[0] * SCALE - a) if end == "left" else (BINDING[1] * SCALE - a, piece.width)
            ImageDraw.Draw(keep).rectangle((cut[0], 0, cut[1], (CAPS - FRAME_BOTTOM[0]) * SCALE), fill=0)
            piece.putalpha(ImageChops.multiply(piece.getchannel("A"), keep.filter(ImageFilter.GaussianBlur(2 * SCALE))))
        save(f"frame-bottom-{end}", piece,
             f"the window's bottom (the page curling onto its stack, the corners): {how}; its paper fades into the "
             f"page; content stays {FRAME_BOTTOM[1] - PAGE_END} layout pixels above its foot")
    lx0, lx1, ly0, ly1 = z(FRAME_LEFT)
    rx0, rx1, ry0, ry1 = z(FRAME_RIGHT)
    save("frame-left", seamless_y(f.crop((lx0, ly0, lx1, ly1))), "the window's left edge: repeats down without a seam")
    save("frame-right", seamless_y(f.crop((rx0, ry0, rx1, ry1))), "the window's right edge: repeats down without a seam")
    save("frame-clasp", f.crop(z(CLASP)), "the clasp, on the right edge's middle")
    made["frame-top-left"]["title_at"] = [TITLE_AT[0] - FRAME_X[0], TITLE_AT[1] - FRAME_TOP[0]]
    made["frame-top-right"]["close_at"] = [CLOSE_AT[0] - FRAME_X[2], CLOSE_AT[1] - FRAME_TOP[0]]

    # the character window, whole
    doll = tone_shift(masked("doll", (1024 * SCALE, 1024 * SCALE)), z(DOLL_PAPER))
    save("doll", doll, "the character window (#3) whole: code fills its slots and strips; not trimmed, so its slots "
                       "stay where compose.py's DOLL has them")

    for name, src in PARTS.items():
        f_ = os.path.join(HIRES, src + ".png")
        if os.path.exists(f_):
            save(name, trim(clean_rim(Image.open(f_).convert("RGBA"))), "a cut-out, kept whole or sliced as code needs")
    made["patch"]["how"] = "every leather button and side tab (#183): three slices across, a quarter each end kept"
    made["tab-arrow"]["how"] = made["tab-arrow-b"]["how"] = ("the interlocking leather arrow tab: three slices across, "
                                                             "the ends (the point and the cut) kept, each tip in the next one's cut")
    if "tab-patch" in made:
        made["tab-patch"]["how"] = "a leather patch tab (#78's row): three slices across, its label in code"

    box = Image.open(os.path.join(GEN, "pencil/pencil-box.png")).convert("RGBA")
    save("pencil-box", box, "#14's pencil box: nine slices, 30 % of its height kept at each corner; drawn at one line "
                            "weight (58 layout pixels high), bigger boxes stretch its sides")
    save("pencil-rule", trim(box.crop((box.width // 6, 0, box.width * 5 // 6, max(4, box.height // 9)))),
         "the pencil box's top line: stretched along, for rules between sections")

    save("paper", Image.open(os.path.join(HIRES, "paper.png")).convert("RGBA"),
         "the parchment: scaled to cover a page and cut, never stretched or repeated; code moves it to the page's tone")
    for f_ in sorted(glob.glob(os.path.join(REFS, "stain*.png")) + glob.glob(os.path.join(REFS, "sketches/*.png"))):
        name = os.path.splitext(os.path.basename(f_))[0]
        save(name, trim(Image.open(f_).convert("RGBA")),
             "a decoration code lays faintly over the paper" if name.startswith("sketch") else "a coffee stain, faint, over the paper")

    json.dump({"scale": "4K: two pixels for each pixel of a 1080p layout", "pieces": made},
              open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    sheet(made)
    print(f"{len(made)} pieces in {os.path.relpath(OUT, ROOT)}")


def sheet(made):
    """One picture of every piece on a checkerboard, to look them over."""
    cell, cols = 360, 8
    rows = (len(made) + cols - 1) // cols
    img = Image.new("RGB", (cols * cell, rows * cell), (60, 56, 52))
    d = ImageDraw.Draw(img)
    for i, name in enumerate(made):
        p = Image.open(os.path.join(OUT, made[name]["file"])).convert("RGBA")
        p.thumbnail((cell - 16, cell - 36))
        x, y = (i % cols) * cell, (i // cols) * cell
        board = Image.new("RGBA", p.size)
        bd = ImageDraw.Draw(board)
        for yy in range(0, p.height, 12):
            for xx in range(0, p.width, 12):
                bd.rectangle((xx, yy, xx + 11, yy + 11), fill=(150, 150, 150, 255) if (xx + yy) // 12 % 2 else (110, 110, 110, 255))
        board.alpha_composite(p)
        img.paste(board.convert("RGB"), (x + 8, y + 26))
        d.text((x + 8, y + 6), name, fill=(240, 220, 160))
    img.save(os.path.join(GEN, "pieces-sheet.jpg"), quality=88)


if __name__ == "__main__":
    main()
