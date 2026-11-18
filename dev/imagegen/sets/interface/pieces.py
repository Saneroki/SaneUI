#!/usr/bin/env python3
"""The final pieces (Doc/guides/interface-style.md, *Pieces*): every decided element at 4K, alone on transparency,
trimmed to what it covers, so code can build any of SaneUI's windows from them like a puzzle. Made in code from
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
EDGES_START = 106                      # the edges' tiles run from here, under the top's corners (above it #12's
                                       # cover has not begun)
FRAME_LEFT = (196, 240, 300, 600)      # the left edge: x from-to, the plain stretch it repeats (y)
CLASP = (786, 372, 836, 518)           # the clasp with the leather it hangs from (the right edge is the left one
                                       # mirrored, Saneroki, 2026-10-22: one image for the sides and the bottom)
RIGHT_IN = 20                          # #12's book ends 20 pixels before the top's right end: the mirrored right
                                       # edge stands that far in
TITLE_AT = (372, 182)                  # where the title label's writing starts
LABEL = (332, 166, 712, 196)           # the title label's inside: its light evened out (the paper that covered its
                                       # writing showed as lighter blocks), its grain kept
CLOSE_AT = (770, 124)                  # the middle of the corner patch on the strap: the close button
CAPS = {"left": (196, 830, 262, 878), "right": (752, 830, 818, 878)}   # #12's rounded metal caps at its bottom
                                       # corners (Saneroki, 2026-10-22: kept over the mitred corners)
CAP_RING = {"left": 26, "right": 18}   # how thick the metal is along the book's rounded outline (inside the right
                                       # one #12's wider right edge begins)
CAP_TIPS = {"left": (204, 870), "right": (808, 870)}   # each corner's outer tip: the metal is kept within
CAP_REACH = (58, 14)                   # so many pixels of it, fading out over the last ones
TOP_FADE = 26                          # the top's paper fades into the page over so many pixels
EDGE_FADE = 14                         # the edge's paper (the pages' edges) fades into the page over so many
EDGE_MATCH = 0.8                       # how far the edge's paper moves to the page's tone (Saneroki, 2026-10-22:
                                       # its tan met the cream page in a harsh line)
FRAME_PAPER = (300, 200, 560, 240)     # a stretch of #12's plain paper, for its tone
DOLL_PAPER = (420, 120, 470, 200)      # the same in #3 (behind the hero's head)
DOLL_FRAME = (222, 50, 798, 962)       # #3's window at most (its strips over the border included): its painted
                                       # landscape round it is cut off there

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


def match_edge(img, box, k=EDGE_MATCH):
    """The paper beside the binding (the pages' edges, a darker tan than the page) moved toward the page's tone in
    the box (pixels), its grain and its lines kept: each light pixel scaled by the page's tone over the strip's own,
    the leather (dark pixels) untouched."""
    x0, y0, x1, y1 = box
    region = img.crop(box)
    a = np.asarray(region.convert("RGB"), dtype=np.float32)
    lum = a.mean(axis=2)
    paper_ = lum > 130
    if not paper_.any():
        return img
    ref = np.median(a[paper_], axis=0)
    w = (np.clip((lum - 110) / 50, 0, 1) * k)[..., None]
    a = a * (1 - w) + a * (np.array(paper.TONE, dtype=np.float32) / ref) * w
    out = Image.fromarray(a.clip(0, 255).astype(np.uint8)).convert("RGBA")
    out.putalpha(region.getchannel("A"))
    img.paste(out, (x0, y0))
    return img


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


def backdrop(img):
    """The pick's painted backdrop round the window: the dark, cool grey reached from the picture's border (the
    window's leather is warm, its paper light), so its outside is found by its colour too."""
    a = np.asarray(img.convert("RGB"), dtype=np.int16)
    grey = (a.max(axis=2) < 80) & (a[..., 0] - a[..., 2] < 10)
    pad = Image.new("L", (img.width + 2, img.height + 2), 255)
    pad.paste(Image.fromarray(grey.astype(np.uint8) * 255).filter(ImageFilter.MedianFilter(5)), (1, 1))
    ImageDraw.floodfill(pad, (0, 0), 128)
    return pad.crop((1, 1, img.width + 1, img.height + 1)).point(lambda v: 255 if v == 128 else 0)


def masked(name, size, within=None):
    """The 4K render of a whole pick with its outside transparent: what the background removal (catalog.py masks)
    or the backdrop's colour (backdrop: the removal keeps only the hero of #3) calls the window, together."""
    img = Image.open(os.path.join(HIRES, name + ".png")).convert("RGB").resize(size, Image.LANCZOS)
    removal = Image.open(os.path.join(HIRES, name + "-mask.png")).convert("L").resize(size, Image.LANCZOS)
    inside = ImageChops.invert(backdrop(img)).filter(ImageFilter.GaussianBlur(1.2 * SCALE))
    alpha = ImageChops.lighter(removal, inside)
    # only what hangs together with the window (the middle of the picture): islands of the painted backdrop go
    if within:                                         # the window's bounds, where known
        box = Image.new("L", size)
        ImageDraw.Draw(box).rectangle(z(within), fill=255)
        alpha = ImageChops.multiply(alpha, box.filter(ImageFilter.GaussianBlur(2 * SCALE)))
    # thin links to islands broken (shrunk, then grown back on the part that holds the middle)
    k = 9 * SCALE | 1
    solid = alpha.point(lambda v: 255 if v > 128 else 0).filter(ImageFilter.MinFilter(k))
    ImageDraw.floodfill(solid, (size[0] // 2, size[1] // 2), 128)
    window = solid.point(lambda v: 255 if v == 128 else 0).filter(ImageFilter.MaxFilter(k + 2 * SCALE))
    img = img.convert("RGBA")
    img.putalpha(ImageChops.multiply(alpha, window))
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
    # the paper beside both bindings, down the whole window, moved toward the page's tone
    f = match_edge(f, z((FRAME_LEFT[0], FRAME_TOP[0], FRAME_LEFT[1], 1024)))
    f = match_edge(f, z((FRAME_X[3] - RIGHT_IN - (FRAME_LEFT[1] - FRAME_LEFT[0]), FRAME_TOP[0], FRAME_X[3], 1024)))
    x0, x1, x2, x3 = z(FRAME_X)
    t0, t1 = z(FRAME_TOP)
    for end, (a, b), how in (("left", (x0, x1), "its left end, kept whole"),
                             ("middle", (x1, x2), "its middle, stretched whole between the ends, joined edge to edge (its lines "
                                                 "run along it)"),
                             ("right", (x2, x3), "its right end, kept whole; the close button is its corner patch")):
        save(f"frame-top-{end}", fade(f.crop((a, t0, b, t1)), "bottom", TOP_FADE * SCALE),
             f"the window's top (strap, ribbon, title label): {how}; its paper fades into the page")
    lx0, lx1, ly0, ly1 = z(FRAME_LEFT)
    left = fade(seamless_y(f.crop((lx0, ly0, lx1, ly1))), "right", EDGE_FADE * SCALE)   # its paper into the page
    save("frame-left", left, "the window's left edge: repeats down without a seam")
    # the bottom (Saneroki, 2026-10-22): the left edge itself turned a quarter, its leather facing down; the sides
    # meet it in a mitred corner (compose.py)
    save("frame-bottom", left.rotate(90, expand=True), "the window's bottom: the left edge turned a quarter, its "
                                                        "leather facing down; repeats along without a seam; the sides "
                                                        "meet it in mitred corners, cut from the inner corner to the "
                                                        "outer one")
    save("frame-right", left.transpose(Image.FLIP_LEFT_RIGHT), "the window's right edge: the left one mirrored; "
                                                                  "repeats down without a seam")
    save("frame-clasp", fade(fade(fade(f.crop(z(CLASP)), "left", 12 * SCALE), "top", 14 * SCALE), "bottom", 14 * SCALE),
         "the clasp and the leather it hangs from, on the right edge's middle; its right side on the top's right end's")
    # the rounded metal caps of #12's bottom corners: the metal alone (a ring along the book's outline), and the
    # corner's rounded outline, which code cuts the mitred corner to
    outline = Image.open(os.path.join(HIRES, "window-mask.png")).convert("L").resize(f.size, Image.LANCZOS)
    for side, box in CAPS.items():
        inner = outline.filter(ImageFilter.MinFilter(2 * CAP_RING[side] * SCALE + 1)).filter(ImageFilter.GaussianBlur(3 * SCALE))
        ring = ImageChops.subtract(outline, inner)
        cap = f.crop(z(box))
        bx0, by0 = z(box)[:2]
        tx, ty = z(CAP_TIPS[side])
        yy, xx = np.mgrid[0:cap.height, 0:cap.width]
        dist = np.hypot(xx + bx0 - tx, yy + by0 - ty)
        near = np.clip((CAP_REACH[0] * SCALE - dist) / (CAP_REACH[1] * SCALE), 0, 1)
        rise = np.clip(yy / (12 * SCALE), 0, 1)        # and fading in below the box's top
        alpha = np.asarray(ring.crop(z(box)), dtype=np.float32) * near * rise
        cap.putalpha(Image.fromarray(alpha.astype(np.uint8)))
        save(f"frame-cap-{side}", cap, f"the rounded metal cap of the bottom {side} corner (#12's), laid over the mitred "
                                       f"corner; its {'left' if side == 'left' else 'right'} and bottom on the window's")
        shape = Image.new("RGBA", cap.size, (255, 255, 255, 0))
        top = Image.linear_gradient("L").transpose(Image.FLIP_TOP_BOTTOM).resize((cap.width, 16 * SCALE))
        ramp = Image.new("L", cap.size, 0)
        ramp.paste(top, (0, 0))                        # the rounding comes in below the box's top, no step
        shape.putalpha(ImageChops.lighter(outline.crop(z(box)), ramp))
        save(f"frame-corner-{side}", shape, f"the bottom {side} corner's rounded outline: code keeps the frame inside it")
    mitres(save)
    made["frame-top-left"]["title_at"] = [TITLE_AT[0] - FRAME_X[0], TITLE_AT[1] - FRAME_TOP[0]]
    made["frame-top-right"]["close_at"] = [CLOSE_AT[0] - FRAME_X[2], CLOSE_AT[1] - FRAME_TOP[0]]

    # the character window, whole
    doll = tone_shift(masked("doll", (1024 * SCALE, 1024 * SCALE), DOLL_FRAME), z(DOLL_PAPER))
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


def mitres(save):
    """The masks of the mitred bottom corners, for the game (which cuts no picture on a slant): over each corner's box
    (CAPS), the side's part and the bottom's part of the corner, each within the corner's rounded outline, split on
    the line from the inner corner to the outer one, softened by a pixel."""
    for side, box in CAPS.items():
        shape = Image.open(os.path.join(OUT, f"frame-corner-{side}.png")).getchannel("A")
        w, h = shape.size
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        if side == "left":                                        # the outer corner at the box's bottom left
            d = (h - xx - yy) / np.sqrt(2)                        # > 0 on the edge's side of the line
        else:                                                     # the book's right end, RIGHT_IN before the box's end
            ox = (FRAME_X[3] - RIGHT_IN - box[0]) * SCALE
            d = (xx - (ox - h) - yy) / np.sqrt(2)
        edge = np.clip(d + 0.5, 0, 1)
        a = np.asarray(shape, dtype=np.float32)
        for part, k in (("edge", edge), ("bottom", 1 - edge)):
            m = Image.new("RGBA", shape.size, (255, 255, 255, 0))
            m.putalpha(Image.fromarray((a * k).astype(np.uint8)))
            save(f"frame-mitre-{side}-{part}", m, f"a mask (white, alpha): of the bottom {side} corner's box, the "
                 + ("side's part" if part == "edge" else "bottom's part") + " of the mitred corner within its rounded "
                 "outline; the game masks the edge's and the bottom's leather with it under the cap", box=list(box))


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
    if sys.argv[1:] == ["mitres"]:                               # the corner masks alone, the pieces as they are
        listing = json.load(open(os.path.join(OUT, "pieces.json")))

        def keep(name, img, how, **extra):
            img.save(os.path.join(OUT, name + ".png"))
            listing["pieces"][name] = {"file": name + ".png", "size": list(img.size), "how": how, **extra}
        mitres(keep)
        json.dump(listing, open(os.path.join(OUT, "pieces.json"), "w"), indent=1)
    else:
        main()
