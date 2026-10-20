#!/usr/bin/env python3
"""UI style: a mockup of the character sheet in the leather look, put together from the chosen pictures, because
an image model does not lay out our twenty slots exactly. On the emptied sheet (sheet-clean.txt): the slots our
sheet has (src/Inventory/Sheet/Slots.lua), the left column and the main and off hand in an arc on the left, the
right column and the ranged and ammo slots on the right, each a light frame in its gear's silhouette
(slots-light.txt) with the game's item icon clipped to its plain inside and the frame's rim over it, its name in
its quality's colour and two stats as lines beside it; the sheet's four tabs (slots.txt) at the bottom, the first
chosen. Writes the sheet filled and empty.
  python3 dev/imagegen/sets/ui-style/compose.py <filled.png> <empty.png>
"""
import math, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops
R = os.path.dirname(os.path.abspath(__file__)) + "/../../../../"
G = R + "assets/generated/ui-style/"
ICONS = R + "references/BlizzardInterfaceArt/Interface/ICONS/"
# slots-light/first/: that list's first run, kept aside before seven of its shapes were asked anew
L1, L2, SL = G + "slots-light/first/", G + "slots-light/", G + "slots/"
# slot: frame picture, icon, item quality colour of its name line
LEFT = [("head", L1+"head-2.png", "INV_Helmet_03", "epic"), ("neck", L1+"neck-3.png", "INV_Jewelry_Necklace_07", "rare"),
        ("shoulder", L2+"shoulder-3.png", "INV_Shoulder_02", "epic"), ("back", L1+"back-3.png", "INV_Misc_Cape_02", "rare"),
        ("chest", L1+"chest-3.png", "INV_Chest_Plate06", "epic"), ("shirt", L1+"shirt-1.png", "INV_Shirt_05", "common"),
        ("tabard", L1+"tabard-2.png", "INV_Shirt_GuildTabard_01", "common"), ("wrist", L2+"wrist-4.png", "INV_Bracer_07", "uncommon"),
        ("mainhand", L2+"mainhand-2.png", "INV_Sword_04", "epic"), ("offhand", L2+"offhand-3.png", "INV_Shield_06", "rare")]
RIGHT = [("hands", L2+"hands-2.png", "INV_Gauntlets_04", "rare"), ("waist", L2+"waist-3.png", "INV_Belt_13", "uncommon"),
         ("legs", L1+"legs-4.png", "INV_Pants_04", "epic"), ("feet", L1+"feet-4.png", "INV_Boots_05", "rare"),
         ("finger", L1+"finger-1.png", "INV_Jewelry_Ring_03", "rare"), ("finger", L1+"finger-1.png", "INV_Jewelry_Ring_14", "epic"),
         ("trinket", L1+"trinket-2.png", "INV_Misc_Orb_02", "rare"), ("trinket", L1+"trinket-2.png", "INV_Jewelry_Talisman_07", "epic"),
         ("ranged", L1+"ranged-4.png", "INV_Weapon_Bow_07", "rare"), ("ammo", L2+"ammo-3.png", "INV_Ammo_Arrow_02", "common")]
TABS = [SL+"tab-equipment-4.png", SL+"tab-skills-4.png", SL+"tab-reputation-1.png", SL+"tab-currency-4.png"]
QUALITY = {"common": (90, 86, 80), "uncommon": (40, 140, 30), "rare": (20, 95, 190), "epic": (135, 55, 190)}
GEMS = [(180, 60, 50), (60, 130, 200), (70, 150, 80), (160, 120, 40)]

def cut(path):
    """The part on its own: the light grey ground flooded away from the corners."""
    img = Image.open(path).convert("RGB")
    w, h = img.size
    flood = img.copy()
    for c in [(0, 0), (w-1, 0), (0, h-1), (w-1, h-1), (w//2, 2), (w//2, h-3), (2, h//2), (w-3, h//2)]:
        if flood.getpixel(c) != (255, 0, 255):
            ImageDraw.floodfill(flood, c, (255, 0, 255), thresh=20)
    bg = Image.eval(ImageChops.difference(flood, Image.new("RGB", (w, h), (255, 0, 255))).convert("L"), lambda v: 255 if v < 4 else 0)
    alpha = ImageChops.invert(bg).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.7))
    part = img.convert("RGBA"); part.putalpha(alpha)
    box = alpha.point(lambda v: 255 if v > 30 else 0).getbbox()
    return part.crop(box)

def inner(part):
    """The plain cream inside of a frame: the cream regions found from a grid of seeds, the largest and those
    near its size joined (a gauntlet's palm and cuff)."""
    rgb = part.convert("RGB"); w, h = rgb.size
    alpha = part.getchannel("A")
    def cream(p): return p[0] > 215 and p[1] > 205 and p[0] - p[2] > 12
    regions, seen = [], Image.new("L", (w, h), 0)
    for gy in range(1, 12):
        for gx in range(1, 12):
            x, y = gx * w // 12, gy * h // 12
            if alpha.getpixel((x, y)) < 250 or seen.getpixel((x, y)) or not cream(rgb.getpixel((x, y))): continue
            flood = rgb.copy()
            ImageDraw.floodfill(flood, (x, y), (255, 0, 255), thresh=28)
            m = Image.eval(ImageChops.difference(flood, Image.new("RGB", (w, h), (255, 0, 255))).convert("L"), lambda v: 255 if v < 4 else 0)
            m = ImageChops.multiply(m, alpha.point(lambda v: 255 if v > 250 else 0))
            seen = ImageChops.lighter(seen, m)
            regions.append((m.histogram()[255], m))
    regions.sort(key=lambda r: -r[0])
    out = regions[0][1]
    for n, m in regions[1:]:
        if n > regions[0][0] * 0.12: out = ImageChops.lighter(out, m)
    return out.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(5))

def icon(name, size):
    ic = Image.open(ICONS + name + ".blp").convert("RGBA")
    w, h = ic.size; k = int(w * 0.07)
    return ic.crop((k, k, w - k, h - k)).resize((size, size), Image.LANCZOS)

def slot(path, iconname, filled, panel=62, most=118):
    part = cut(path)
    m = inner(part)
    ib = m.getbbox(); iw, ih = ib[2] - ib[0], ib[3] - ib[1]
    k = min(panel / math.sqrt(iw * ih), most / max(part.size))
    size = (max(1, int(part.width * k)), max(1, int(part.height * k)))
    part, m = part.resize(size, Image.LANCZOS), m.resize(size, Image.LANCZOS)
    if filled:
        ib = m.point(lambda v: 255 if v > 128 else 0).getbbox(); iw, ih = ib[2] - ib[0], ib[3] - ib[1]
        s = int(min(max(iw, ih), 1.3 * min(iw, ih)) * 1.04)
        ic = icon(iconname, s)
        layer = Image.new("RGBA", part.size, (0, 0, 0, 0))
        layer.paste(ic, ((ib[0] + ib[2] - s) // 2, (ib[1] + ib[3] - s) // 2))
        a = ImageChops.multiply(layer.getchannel("A"), m)
        layer.putalpha(a)
        part = Image.alpha_composite(part, layer)
    return part

def shadow(canvas, part, xy, off=(3, 4), strength=90):
    a = part.getchannel("A").filter(ImageFilter.GaussianBlur(4)).point(lambda v: v * strength // 255)
    sh = Image.new("RGBA", part.size, (40, 25, 15, 0)); sh.putalpha(a)
    canvas.alpha_composite(sh, (xy[0] + off[0], xy[1] + off[1]))
    canvas.alpha_composite(part, xy)

def label(draw, x, y, side, quality, seed):
    """The item's name and two stats beside its slot, as lines: the name in its quality's colour."""
    sgn = -1 if side == "left" else 1
    def line(x0, length, yy, col, wdt):
        xa, xb = (x0 - length, x0) if sgn < 0 else (x0, x0 + length)
        draw.line([(xa, yy), (xb, yy)], fill=col, width=wdt)
    line(x, 86 + seed % 3 * 12, y - 15, QUALITY[quality], 6)
    for i in range(2):
        gy = y + 4 + i * 14
        gx = x + sgn * 5
        g = GEMS[(seed + i) % 4]
        draw.polygon([(gx, gy - 5), (gx + 4, gy), (gx, gy + 5), (gx - 4, gy)], fill=g, outline=(70, 60, 50))
        line(x + sgn * 15, 50 + (seed * 7 + i * 13) % 30, gy, (150, 140, 125), 3)

def main(filled, out):
    canvas = Image.open(G + "sheet-clean/empty-3.png").convert("RGBA")
    draw = ImageDraw.Draw(canvas)
    cx, cy, rx, ry = 864, 446, 640, 392
    for side, slots, a0, a1 in (("left", LEFT, 243, 114), ("right", RIGHT, -63, 66)):
        n = len(slots)
        # even steps along the arc, not in angle
        pts = [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * j / 999)), cy + ry * math.sin(math.radians(a0 + (a1 - a0) * j / 999))) for j in range(1000)]
        run = [0.0]
        for p, q2 in zip(pts, pts[1:]): run.append(run[-1] + math.dist(p, q2))
        for i, (kind, path, ic, q) in enumerate(slots):
            want = run[-1] * i / (n - 1)
            x, y = pts[min(range(1000), key=lambda j: abs(run[j] - want))]
            part = slot(path, ic, filled, panel=60 if kind == "ammo" else 84, most=98)
            shadow(canvas, part, (int(x - part.width / 2), int(y - part.height / 2)))
            if filled and kind not in ("mainhand", "offhand", "ranged", "ammo"):
                # the stats on the inner side, towards the hero; the top two's on the outer side, where the corner is free
                inward = i >= 2
                if (side == "left") == inward: lx, ls = x + part.width / 2 + 12, "right"
                else: lx, ls = x - part.width / 2 - 12, "left"
                label(draw, int(lx), int(y), ls, q, i * 5 + (1 if side == "right" else 0))
    for i, path in enumerate(TABS):
        tab = cut(path); k = 96 / tab.height
        tab = tab.resize((int(tab.width * k), 96), Image.LANCZOS)
        if i > 0:
            dim = tab.convert("RGB").point(lambda v: int(v * 0.72)).convert("RGBA"); dim.putalpha(tab.getchannel("A")); tab = dim
        x = 864 + (i - 1.5) * 124
        if i == 0:
            glow = tab.getchannel("A").filter(ImageFilter.GaussianBlur(10))
            g = Image.new("RGBA", tab.size, (255, 215, 140, 0)); g.putalpha(glow.point(lambda v: v * 170 // 255))
            canvas.alpha_composite(g, (int(x - tab.width / 2), 868))
        shadow(canvas, tab, (int(x - tab.width / 2), 868))
    canvas.convert("RGB").save(out)

if __name__ == "__main__":
    main(True, sys.argv[1]); main(False, sys.argv[2])
