#!/usr/bin/env python3
"""Tests of dev/tools/atlas without ComfyUI and without the game's files: the phrases a square keeps of its
zone's brief, the words put together, the check against the game's water on made-up pictures, the colour
pass, the cut where two squares meet, the grid of squares, ComfyUI's websocket frames and the screen's
numbers. Run by dev/tests/run."""
import importlib.machinery
import importlib.util
import os
import struct
import sys
import tomllib
from pathlib import Path

from PIL import Image

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
os.chdir(ROOT)

loader = importlib.machinery.SourceFileLoader("atlas", str(ROOT / "dev" / "tools" / "atlas"))
at = importlib.util.module_from_spec(importlib.util.spec_from_loader("atlas", loader))
loader.exec_module(at)
np = at.np
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


# --- The words -------------------------------------------------------------------------------------

dry = {"water": 0.0, "lava": 0.0, "slime": 0.0}
wet = {"water": 0.2, "lava": 0.0, "slime": 0.0}
plants = "Tall oaks and pines, reeds along the lake shore, orchards in the north, meadows of flowers."
check("only: dry drops water and places", at.only(plants, dry), "Tall oaks and pines, meadows of flowers")
check("only: wet keeps the water", at.only(plants, wet), "Tall oaks and pines, reeds along the lake shore, meadows of flowers")
check("only: no lava without lava", at.only("black rock, lava red, rust", dry), "black rock, rust")
check("joined one", at.joined(["rock"]), "rock")
check("joined three", at.joined(["meadow", "dirt", "rock"]), "meadow, dirt and rock")

fixed = tomllib.loads(at.WORDS.read_text())
briefs = tomllib.loads(at.BRIEFS.read_text())
for key in ("edit", "sea"):
    check(f"atlas.toml has {key}", isinstance(fixed.get(key), str) and len(fixed[key]) > 40, True)
for key in ("water", "little", "dry", "lava", "slime", "keep_colours", "last"):
    check(f"atlas.toml has words.{key}", isinstance(fixed["words"].get(key), str) and len(fixed["words"][key]) > 20, True)
for uimap, brief in briefs.items():
    if uimap != "sea":
        check(f"{brief['name']} has its words", all(brief.get(k) for k in ("colours", "atmosphere")), True)


def facts(**more):
    base = {"water": 0.0, "lava": 0.0, "slime": 0.0, "zones": [{"uimap": "1429", "name": "Elwynn Forest", "share": 1.0}],
            "cover": {"meadow": 0.7, "road": 0.1, "rock": 0.2}, "buildings": 0.0}
    base.update(more)
    return base


text = at.words(fixed, briefs, facts())
check("words begin with the edit", text.startswith(fixed["edit"]), True)
check("words end with the last", text.endswith(fixed["words"]["last"]), True)
check("words: dry square", fixed["words"]["dry"] in text and fixed["words"]["water"] not in text, True)
check("words: no sentence on the ground", "The ground of image 1" in text, False)
check("words: the zone's light, not its props", at.light_of(briefs["1429"]["atmosphere"]) in text
      and briefs["1429"]["atmosphere"] not in text, True)
check("words: the colours kept", fixed["words"]["keep_colours"] in text, True)
check("light: colour and haze clauses left out", at.light_of("Harsh, white-hot sunlight bleaching the red ground, a dusty heat haze, bone-dry. Rest."),
      "Harsh, bone-dry")
puddles = at.words(fixed, briefs, facts(water=0.004))
check("words: a little water", fixed["words"]["little"] in puddles and fixed["words"]["water"] not in puddles, True)
check("words: never the zone's buildings", briefs["1429"]["buildings"] in text, False)
check("words: never the zone's plants list", briefs["1429"]["plants"] in text, False)
lava = at.words(fixed, briefs, facts(lava=0.1))
check("words: lava", fixed["words"]["lava"] in lava and fixed["words"]["dry"] in lava, True)
wet = at.words(fixed, briefs, facts(zones=[{"uimap": "1453", "name": "Stormwind City", "share": 1.0}], water=0.2))
check("words: water named", fixed["words"]["water"] in wet, True)
open_sea = at.words(fixed, briefs, facts(zones=[], water=1.0))
check("words: the open sea", open_sea.startswith(fixed["sea"]) and briefs["sea"]["water"] in open_sea, True)


# --- The check against the game's water ------------------------------------------------------------

side = 512
grey = np.full((side, side, 3), (120, 112, 96), np.uint8)
rng = np.random.default_rng(1)
land = (grey.astype(np.int16) + rng.integers(-30, 30, (side, side, 1))).clip(0, 255).astype(np.uint8)  # rough land
square = {"rgb": land.copy(), "water": np.zeros((side, side), np.uint8)}
square["rgb"][300:460, 60:300] = at.NAVY
square["water"][300:460, 60:300] = 255
painted = land.copy()
painted[300:460, 60:300] = (40, 90, 130)   # the game's lake, painted as water
check("check: faithful passes", at.passes(at.check(square, painted)), True)
added = painted.copy()
added[40:200, 300:480] = (40, 90, 130)     # a lake the game does not have
result = at.check(square, added)
check("check: added water fails", result["added"] > at.ADDED and not at.passes(result), True)
lost = land.copy()                          # the game's lake painted as land
result = at.check(square, lost)
check("check: lost water fails", result["lost"] > at.LOST and not at.passes(result), True)
lagoon = land.copy()
lagoon[300:460, 60:300] = (30, 120, 95)     # the game's lake, painted as an emerald lagoon
check("check: an emerald lagoon is still water", at.check(square, lagoon)["lost"] <= at.LOST, True)
dusk = (land.astype(np.int16) * (0.4, 0.5, 0.9)).clip(0, 255).astype(np.uint8)   # a zone graded blue, as Duskwood
dusk[300:460, 60:300] = (20, 50, 110)
check("check: a blue zone is not water", at.passes(at.check(square, dusk)), True)

# --- What stands in the water stays ------------------------------------------------------------------

pond = np.zeros((40, 40, 3), np.uint8); pond[:] = (30, 70, 80)       # water as the minimap draws it: cool, dark
pond[10:30, 18:24] = (120, 80, 40)                                    # a pier of warm wood
pond[2:8, 2:8] = (200, 205, 210)                                      # a white dome
mask = np.full((40, 40), 255, np.uint8)
open_ = at.open_water(pond, mask)
check("open water: the pier is not water", int(open_[20, 21]), 0)
check("open water: the dome is not water", int(open_[5, 5]), 0)
check("open water: the water stays water", int(open_[20, 5]), 255)
muddy = np.zeros((10, 10, 3), np.uint8); muddy[:] = (70, 60, 55)          # a muddy river, a little warm
check("open water: muddy water stays water", int(at.open_water(muddy, np.full((10, 10), 255, np.uint8))[5, 5]), 255)

# --- The colour pass ----------------------------------------------------------------------------------

rgb = rng.integers(0, 255, (64, 64, 3)).astype(np.uint8)
check("lab: there and back", int(np.abs(at.to_rgb(at.to_lab(rgb)).astype(int) - rgb).max()) <= 1, True)
side = 256
orange = (np.array([190, 95, 40]) + rng.integers(-12, 12, (side, side, 1))).clip(0, 255).astype(np.uint8)  # the game's ground
tan = (orange.astype(np.int16) + (25, 45, 60)).clip(0, 255).astype(np.uint8)                              # painted paler
detail = rng.integers(-20, 20, (side, side, 1))
painted = (tan.astype(np.int16) + detail).clip(0, 255).astype(np.uint8)
none = np.zeros((side, side), np.uint8)
ground = {"rgb": orange, "water": none, "lava": none}


def small_lab(x):
    return at.to_lab(np.asarray(Image.fromarray(x).resize((8, 8), Image.Resampling.BOX)))


def broad_gap(a, b):   # in hue and saturation (a and b of CIELAB)
    return float(np.sqrt(((small_lab(a) - small_lab(b))[..., 1:] ** 2).sum(-1)).mean())


back = at.colour_of(painted, ground, 0.0)
check("colour pass: the game's broad colour back", broad_gap(back, orange) < broad_gap(painted, orange) / 3, True)
check("colour pass: the painting's brightness kept", float(np.abs(small_lab(back)[..., 0] - small_lab(painted)[..., 0]).mean()) < 1.5, True)
fine = lambda x: x.astype(np.float32).mean(-1) - at.broad(x.astype(np.float32).mean(-1)[..., None], 6)[..., 0]  # noqa: E731
check("colour pass: the fine detail kept", float(np.corrcoef(fine(back).ravel(), fine(painted).ravel())[0, 1]) > 0.95, True)
check("colour pass: mood 1 keeps land as painted", int(np.abs(at.colour_of(painted, ground, 1.0).astype(int) - painted).max()) <= 2, True)
half = at.colour_of(painted, ground, 0.5)
check("colour pass: mood 0.5 halfway", broad_gap(back, orange) < broad_gap(half, orange) < broad_gap(painted, orange), True)
lake = {"rgb": orange.copy(), "water": none.copy(), "lava": none.copy()}
lake["water"][:, :128] = 255
lake["rgb"][:, :128] = at.NAVY
royal = painted.copy(); royal[:, :128] = (30, 60, 200)       # the model's water, too bright a blue
toward_sea = at.colour_of(royal, lake, 1.0)
gap = lambda x: float(np.abs(x[40:216, 20:100].reshape(-1, 3).mean(0) - at.SEA).sum())  # noqa: E731
check("colour pass: water toward the sea's blue at any mood", gap(toward_sea) < gap(royal) / 2, True)
hot = {"rgb": orange.copy(), "water": none.copy(), "lava": none.copy()}
hot["lava"][:, :128] = 255
check("colour pass: lava kept", int(np.abs(at.colour_of(painted, hot, 0.0)[40:216, 20:90].astype(int) - painted[40:216, 20:90]).max()) <= 2, True)

# --- Joining ----------------------------------------------------------------------------------------

over = at.SQ - at.STEP
a = rng.integers(0, 255, (64, over, 3)).astype(np.float32)
b = a.copy()
b[:, : over // 2 + 40] += 90               # b differs from a except near the overlap's right part
w = at.seam(a, b)
check("seam: weights from 1 to 0", (float(w.max()), float(w.min())), (1.0, 0.0))
check("seam: cut where they agree", bool((w[:, over // 2 + 40 + at.FEATHER:, 0] < 0.5).all() or (w[:, :over // 2 + 40 - at.FEATHER, 0] > 0.5).all()), True)
left = np.zeros((32, at.SQ, 3), np.uint8)
right = np.full((32, at.SQ, 3), 255, np.uint8)
check("join_two: width", at.join_two(left, right, True).shape, (32, at.SQ + at.STEP, 3))
check("join_two: hard cut in the middle", (int(at.join_two(left, right, True)[0, at.STEP + over // 2 - 1, 0]),
                                           int(at.join_two(left, right, True)[0, at.STEP + over // 2, 0])), (0, 255))

# --- Packing ------------------------------------------------------------------------------------------

check("ranges", at.ranges([3, 5, 6, 7, 9, 12, 13]), "3,5-7,9,12-13")
check("ranges: one", at.ranges([4]), "4")
lua = at.index_lua({0: {0: {10: [3, 4, 5]}, 1: {5: [1]}}, 1: {0: {2: [7, 9]}}})
check("index: levels", f"levels = {at.LEVELS}," in lua, True)
check("index: a row", '[10] = "3-5",' in lua and '[2] = "7,9",' in lua, True)
check("index: the addon's table", "local _, ns = ..." in lua and "ns.INDEX = {" in lua, True)
P, O, M = at.PAINTED, at.OPEN, at.MISSING
quad = np.array([[P, O, O, O], [O, O, O, O], [M, P, O, O], [O, O, O, O]], np.uint8)
colours = np.zeros((4, 4, 3), np.uint8); colours[:2, :2] = 200
small_rgb, small_kind = at.halved(colours, quad)
check("halved: missing wins, then painted", small_kind.tolist(), [[P, O], [M, O]])
check("halved: colours averaged", int(small_rgb[0, 0, 0]), 200)
check("halved: open sea is the sea's blue", small_rgb[0, 1].tolist(), at.SEA.tolist())
top = np.full((8, 12, 3), 50, np.uint8); bottom = np.full((8, 12, 3), 150, np.uint8)
tk = np.full((8, 12), O, np.uint8); bk = np.full((8, 12), O, np.uint8)
tk[:, :4] = P; bk[:, 4:8] = P; tk[:, 8:] = M
rgb_, kind_ = at.blend_rows(top, bottom, tk, bk)
check("blend rows: painted over sea", (int(rgb_[0, 1, 0]), int(rgb_[0, 5, 0])), (50, 150))
check("blend rows: missing over sea", int(kind_[0, 10]), M)
both_t = rng.integers(20, 80, (64, 6, 3)).astype(np.uint8)
both_b = np.full((64, 6, 3), 220, np.uint8); both_b[24:40] = both_t[24:40]   # the two agree in the middle rows
rgb_, kind_ = at.blend_rows(both_t, both_b, np.full((64, 6), P, np.uint8), np.full((64, 6), P, np.uint8))
check("blend rows: both painted, cut where they agree", (rgb_[0].tolist() == both_t[0].tolist(), int(rgb_[-1, 3, 0])), (True, 220))
blocks = []
pyramid = at.Pyramid(8, lambda level, row, column, rgb: blocks.append((level, row, column, rgb.shape)), block=4, levels=2)
band_rgb = np.zeros((8, 8, 3), np.uint8)
band_kind = np.full((8, 8), O, np.uint8)
band_kind[0:4, 0:4] = P                    # a block of painted ground
band_kind[4:8, 4:8] = P; band_kind[7, 7] = M   # painted, but not whole
pyramid.add(band_rgb[:5], band_kind[:5]); pyramid.add(band_rgb[5:], band_kind[5:])
check("pyramid: whole painted blocks only; a level up, missing ground keeps it out", blocks, [(0, 0, 0, (4, 4, 3))])
blocks.clear()
band_kind[7, 7] = O
pyramid = at.Pyramid(8, lambda level, row, column, rgb: blocks.append((level, row, column, rgb.shape)), block=4, levels=2)
pyramid.add(band_rgb, band_kind)
check("pyramid: then the level up", blocks, [(0, 0, 0, (4, 4, 3)), (0, 1, 1, (4, 4, 3)), (1, 0, 0, (4, 4, 3))])
fake = [b"\x01" * 8 * 16, b"\x02" * 8 * 4, b"\x03" * 8]
blp = at.blp_of(fake, 16)
check("blp: DXT1, no alpha, mipmaps", (blp[:4], blp[8:12]), (b"BLP2", bytes([2, 0, 0, 1])))
offsets = struct.unpack_from("<3I", blp, 20)
check("blp: mipmaps where the header says", [blp[o:o + 1] for o in offsets], [b"\x01", b"\x02", b"\x03"])

# --- The grid, the websocket, the screen --------------------------------------------------------------

check("squares start on chunks", at.STEP % at.CHUNK, 0)
check("squares overlap by an eighth", at.SQ - at.STEP, at.SQ // 8)
check("a square is 16 chunks", at.SQ // at.CHUNK, 16)
check("name", at.name_of(1, 30, 14), "1:30:14")
text_frame = bytes([0x81, 5]) + b"hello"
long_payload = b"x" * 300
long_frame = bytes([0x81, 126]) + struct.pack(">H", 300) + long_payload
masked = bytes([0x81, 0x80 | 2, 1, 2, 3, 4]) + bytes([ord("h") ^ 1, ord("i") ^ 2])
buffer = bytearray(text_frame + long_frame + masked + bytes([0x81, 10]) + b"part")
found = at.frames(buffer)
check("frames: three whole", [(op, len(p)) for op, p in found], [(1, 5), (1, 300), (1, 2)])
check("frames: masked", found[2][1], b"hi")
check("frames: the partial one waits", bytes(buffer), bytes([0x81, 10]) + b"part")
check("clock: minutes", at.clock(125), "2 min 05 s")
check("clock: hours", at.clock(3 * 3600 + 7 * 60), "3 h 07 min")
check("clock: days", at.clock(2 * 86400 + 5 * 3600), "2 d 5 h 00 min")
check("bar: width", len(at.bar(0.37, 40)), 40)
check("bar: full", at.bar(1.0, 10), "█" * 10)

print(f"Atlas: all {checks} checks passed." if not failed else f"Atlas: {failed} of {checks} checks failed.")
sys.exit(1 if failed else 0)
