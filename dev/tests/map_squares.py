#!/usr/bin/env python3
"""Tests of dev/tools/map-squares, the instance maps' close level, without ComfyUI and without the game's files:
the phrases a square keeps of its instance's brief, the words put together, the check against the game's water on
made-up pictures, what stands in the water, the colour pass, the cut where two squares meet and the grid of squares.
Run by dev/tests/run."""
import contextlib
import importlib.machinery
import importlib.util
import io
import os
import sys
import tempfile
import tomllib
from pathlib import Path

from PIL import Image

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
os.chdir(ROOT)

loader = importlib.machinery.SourceFileLoader("map_squares", str(ROOT / "dev" / "tools" / "map-squares"))
ms = importlib.util.module_from_spec(importlib.util.spec_from_loader("map_squares", loader))
loader.exec_module(ms)
np = ms.np
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
check("only: dry drops water and places", ms.only(plants, dry), "Tall oaks and pines, meadows of flowers")
check("only: wet keeps the water", ms.only(plants, wet), "Tall oaks and pines, reeds along the lake shore, meadows of flowers")
check("only: no lava without lava", ms.only("black rock, lava red, rust", dry), "black rock, rust")

fixed = tomllib.loads(ms.WORDS.read_text())
briefs = tomllib.loads((ROOT / "dev" / "imagegen" / "maps" / "dungeons.toml").read_text())
check("close.toml has its edit", isinstance(fixed.get("edit"), str) and len(fixed["edit"]) > 40, True)
for key in ("water", "little", "dry", "lava", "slime", "keep_colours", "last"):
    check(f"close.toml has words.{key}", isinstance(fixed["words"].get(key), str) and len(fixed["words"][key]) > 20, True)
for key, brief in briefs.items():
    check(f"{brief['name']} has its words", all(brief.get(k) for k in ("colours", "atmosphere")), True)


def facts(**more):
    return {"water": 0.0, "lava": 0.0, "slime": 0.0, **more}


mine = briefs["36"]   # the Deadmines
text = ms.words(fixed, mine, facts())
check("words begin with the edit", text.startswith(fixed["edit"]), True)
check("words end with the last", text.endswith(fixed["words"]["last"]), True)
check("words: dry square", fixed["words"]["dry"] in text and fixed["words"]["water"] not in text, True)
check("words: no sentence on the ground", "The ground of image 1" in text, False)
check("words: the brief's light, not its props", ms.light_of(mine["atmosphere"]) in text
      and mine["atmosphere"] not in text, True)
check("words: the colours kept", fixed["words"]["keep_colours"] in text, True)
check("light: colour and haze clauses left out", ms.light_of("Harsh, white-hot sunlight bleaching the red ground, a dusty heat haze, bone-dry. Rest."),
      "Harsh, bone-dry")
puddles = ms.words(fixed, mine, facts(water=0.004))
check("words: a little water", fixed["words"]["little"] in puddles and fixed["words"]["water"] not in puddles, True)
check("words: never the brief's buildings", mine["buildings"] in text, False)
check("words: never the brief's places", mine["places"] in text, False)
lava = ms.words(fixed, mine, facts(lava=0.1))
check("words: lava", fixed["words"]["lava"] in lava and fixed["words"]["dry"] in lava, True)
wet = ms.words(fixed, mine, facts(water=0.2))
check("words: water named", fixed["words"]["water"] in wet and fixed["words"]["dry"] not in wet, True)
check("words: the slime", fixed["words"]["slime"] in ms.words(fixed, mine, facts(slime=0.01)), True)


# --- The check against the game's water ------------------------------------------------------------

side = 512
grey = np.full((side, side, 3), (120, 112, 96), np.uint8)
rng = np.random.default_rng(1)
land = (grey.astype(np.int16) + rng.integers(-30, 30, (side, side, 1))).clip(0, 255).astype(np.uint8)  # rough land
square = {"rgb": land.copy(), "water": np.zeros((side, side), np.uint8)}
square["rgb"][300:460, 60:300] = ms.NAVY
square["water"][300:460, 60:300] = 255
painted = land.copy()
painted[300:460, 60:300] = (40, 90, 130)   # the game's lake, painted as water
check("check: faithful passes", ms.passes(ms.check(square, painted)), True)
added = painted.copy()
added[40:200, 300:480] = (40, 90, 130)     # a lake the game does not have
result = ms.check(square, added)
check("check: added water fails", result["added"] > ms.ADDED and not ms.passes(result), True)
lost = land.copy()                          # the game's lake painted as land
result = ms.check(square, lost)
check("check: lost water fails", result["lost"] > ms.LOST and not ms.passes(result), True)
lagoon = land.copy()
lagoon[300:460, 60:300] = (30, 120, 95)     # the game's lake, painted as an emerald lagoon
check("check: an emerald lagoon is still water", ms.check(square, lagoon)["lost"] <= ms.LOST, True)
dusk = (land.astype(np.int16) * (0.4, 0.5, 0.9)).clip(0, 255).astype(np.uint8)   # a place graded blue, as Duskwood
dusk[300:460, 60:300] = (20, 50, 110)
check("check: a place graded blue is not water", ms.passes(ms.check(square, dusk)), True)

# --- What stands in the water stays ------------------------------------------------------------------

pond = np.zeros((40, 40, 3), np.uint8); pond[:] = (30, 70, 80)       # water as the minimap draws it: cool, dark
pond[10:30, 18:24] = (120, 80, 40)                                    # a pier of warm wood
pond[2:8, 2:8] = (200, 205, 210)                                      # a white dome
mask = np.full((40, 40), 255, np.uint8)
open_ = ms.open_water(pond, mask)
check("open water: the pier is not water", int(open_[20, 21]), 0)
check("open water: the dome is not water", int(open_[5, 5]), 0)
check("open water: the water stays water", int(open_[20, 5]), 255)
muddy = np.zeros((10, 10, 3), np.uint8); muddy[:] = (70, 60, 55)          # a muddy river, a little warm
check("open water: muddy water stays water", int(ms.open_water(muddy, np.full((10, 10), 255, np.uint8))[5, 5]), 255)

# --- The colour pass ----------------------------------------------------------------------------------

rgb = rng.integers(0, 255, (64, 64, 3)).astype(np.uint8)
check("lab: there and back", int(np.abs(ms.to_rgb(ms.to_lab(rgb)).astype(int) - rgb).max()) <= 1, True)
side = 256
orange = (np.array([190, 95, 40]) + rng.integers(-12, 12, (side, side, 1))).clip(0, 255).astype(np.uint8)  # the game's ground
tan = (orange.astype(np.int16) + (25, 45, 60)).clip(0, 255).astype(np.uint8)                              # painted paler
detail = rng.integers(-20, 20, (side, side, 1))
painted = (tan.astype(np.int16) + detail).clip(0, 255).astype(np.uint8)
none = np.zeros((side, side), np.uint8)
ground = {"rgb": orange, "water": none, "lava": none}


def small_lab(x):
    return ms.to_lab(np.asarray(Image.fromarray(x).resize((8, 8), Image.Resampling.BOX)))


def broad_gap(a, b):   # in hue and saturation (a and b of CIELAB)
    return float(np.sqrt(((small_lab(a) - small_lab(b))[..., 1:] ** 2).sum(-1)).mean())


back = ms.colour_of(painted, ground, 0.0)
check("colour pass: the game's broad colour back", broad_gap(back, orange) < broad_gap(painted, orange) / 3, True)
check("colour pass: the painting's brightness kept", float(np.abs(small_lab(back)[..., 0] - small_lab(painted)[..., 0]).mean()) < 1.5, True)
fine = lambda x: x.astype(np.float32).mean(-1) - ms.broad(x.astype(np.float32).mean(-1)[..., None], 6)[..., 0]  # noqa: E731
check("colour pass: the fine detail kept", float(np.corrcoef(fine(back).ravel(), fine(painted).ravel())[0, 1]) > 0.95, True)
check("colour pass: mood 1 keeps land as painted", int(np.abs(ms.colour_of(painted, ground, 1.0).astype(int) - painted).max()) <= 2, True)
half = ms.colour_of(painted, ground, 0.5)
check("colour pass: mood 0.5 halfway", broad_gap(back, orange) < broad_gap(half, orange) < broad_gap(painted, orange), True)
lake = {"rgb": orange.copy(), "water": none.copy(), "lava": none.copy()}
lake["water"][:, :128] = 255
lake["rgb"][:, :128] = ms.NAVY
royal = painted.copy(); royal[:, :128] = (30, 60, 200)       # the model's water, too bright a blue
toward_sea = ms.colour_of(royal, lake, 1.0)
gap = lambda x: float(np.abs(x[40:216, 20:100].reshape(-1, 3).mean(0) - ms.SEA).sum())  # noqa: E731
check("colour pass: water toward the sea's blue at any mood", gap(toward_sea) < gap(royal) / 2, True)
hot = {"rgb": orange.copy(), "water": none.copy(), "lava": none.copy()}
hot["lava"][:, :128] = 255
check("colour pass: lava kept", int(np.abs(ms.colour_of(painted, hot, 0.0)[40:216, 20:90].astype(int) - painted[40:216, 20:90]).max()) <= 2, True)

# --- Joining ----------------------------------------------------------------------------------------

over = ms.SQ - ms.STEP
a = rng.integers(0, 255, (64, over, 3)).astype(np.float32)
b = a.copy()
b[:, : over // 2 + 40] += 90               # b differs from a except near the overlap's right part
w = ms.seam(a, b)
check("seam: weights from 1 to 0", (float(w.max()), float(w.min())), (1.0, 0.0))
check("seam: cut where they agree", bool((w[:, over // 2 + 40 + ms.FEATHER:, 0] < 0.5).all() or (w[:, :over // 2 + 40 - ms.FEATHER, 0] > 0.5).all()), True)
left = np.zeros((32, ms.SQ, 3), np.uint8)
right = np.full((32, ms.SQ, 3), 255, np.uint8)
check("join_two: width", ms.join_two(left, right, True).shape, (32, ms.SQ + ms.STEP, 3))
check("join_two: hard cut in the middle", (int(ms.join_two(left, right, True)[0, ms.STEP + over // 2 - 1, 0]),
                                           int(ms.join_two(left, right, True)[0, ms.STEP + over // 2, 0])), (0, 255))
dim, bright = np.full((64, ms.SQ, 3), 100, np.uint8), np.full((64, ms.SQ, 3), 140, np.uint8)
soft = ms.join_two(dim, bright, False)[32, ms.STEP - over // 2: ms.STEP + 3 * over // 2, 0].astype(int)
check("join_two: two plain squares, one lighter, meet without a step (their light fades across the overlap)",
      int(np.abs(np.diff(soft)).max()) <= 2 and int(soft[0]) == 100 and int(soft[-1]) == 140, True)
check("join_two: the ends of the overlap are the squares' own", (int(ms.join_two(dim, bright, False)[0, ms.STEP - 1, 0]),
                                                                 int(ms.join_two(dim, bright, False)[0, ms.SQ, 0])), (100, 140))
with tempfile.TemporaryDirectory() as folder:
    target = Path(folder) / "sq-1-2.png"
    ms.save_png(Image.new("RGB", (4, 4), (1, 2, 3)), target)
    check("save_png: through a temp file beside the target, none left", sorted(p.name for p in Path(folder).iterdir()), ["sq-1-2.png"])
    check("painting_of: a whole file", ms.painting_of(target)[0, 0].tolist(), [1, 2, 3])
    target.write_bytes(target.read_bytes()[:40])   # cut short by a run killed while saving
    with contextlib.redirect_stderr(io.StringIO()) as told:
        painting = ms.painting_of(target)
    check("painting_of: a file cut short is skipped, told", (painting, "skipped" in told.getvalue()), (None, True))

# --- The grid ---------------------------------------------------------------------------------------

check("squares start on chunks", ms.STEP % ms.CHUNK, 0)
check("squares overlap by an eighth", ms.SQ - ms.STEP, ms.SQ // 8)
check("a square is 16 chunks", ms.SQ // ms.CHUNK, 16)
check("a square is one tile", ms.SQ, ms.PX)

print(f"Map squares: all {checks} checks passed." if not failed else f"Map squares: {failed} of {checks} checks failed.")
sys.exit(1 if failed else 0)
