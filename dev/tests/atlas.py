#!/usr/bin/env python3
"""Tests of dev/tools/atlas without ComfyUI and without the game's files: the phrases a square keeps of its
zone's brief, the words put together, the check against the game's water on made-up pictures, the cut where
two squares meet, the grid of squares, ComfyUI's websocket frames and the screen's numbers. Run by
dev/tests/run."""
import importlib.machinery
import importlib.util
import os
import struct
import sys
import tomllib
from pathlib import Path

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
for key in ("water", "dry", "lava", "slime", "last"):
    check(f"atlas.toml has words.{key}", isinstance(fixed["words"].get(key), str) and len(fixed["words"][key]) > 20, True)
KINDS = {"rock", "forest floor", "meadow", "farmland", "snow", "sand", "dirt", "swamp", "blight", "ash and lava", "seabed"}
check("atlas.toml names every kind of ground cover (water and road are said otherwise)", set(fixed["cover"]), KINDS)
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
check("words: the ground cover", "The ground of image 1 is mostly grass, with bare grey and brown rock, crags and scree." in text, True)
check("words: the zone's light, not its props", briefs["1429"]["atmosphere"].split(". ")[0].rstrip(".") in text
      and briefs["1429"]["atmosphere"] not in text, True)
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
