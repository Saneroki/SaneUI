#!/usr/bin/env python3
"""Tests of dev/tools/map-layers without ComfyUI and without the game's files: where a world point lies in a frame,
the affine data of a linear map, a building's point placed and found again, the words of the middle and far levels
put together from the shared words and a brief, the outline agreement of pictures (one layout or another), the
vision model's answers read, and an instance floor's map art with its title banner painted over. Run by
dev/tests/run."""
import importlib.machinery
import importlib.util
import math
import os
import sys
import tomllib
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
os.chdir(ROOT)

loader = importlib.machinery.SourceFileLoader("map_layers", str(ROOT / "dev" / "tools" / "map-layers"))
ml = importlib.util.module_from_spec(importlib.util.spec_from_loader("map_layers", loader))
loader.exec_module(ml)
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


def near(a, b, slack=1e-6):
    return all(abs(x - y) <= slack for x, y in zip(a, b))


# --- Frames ---------------------------------------------------------------------------------------

check("pixel: the map's middle", near(ml.pixel(0, 0, 1), (ml.CENTRE, ml.CENTRE)), True)
check("pixel: west is left, north is up", near(ml.pixel(100, 100, 2), ((ml.CENTRE - 100) * 2, (ml.CENTRE - 100) * 2)), True)
data = ml.affine(lambda u, v: (2 * u + 3 * v + 5, -u + 4 * v + 7))
check("affine: PIL's data of a linear map", near(data, (2, 3, 5, -1, 4, 7)), True)

place = {"x": 1000.0, "y": -500.0, "yaw": 37.0, "scale": 1.25}
x, y = ml.Indoors.world(place, 12.0, -30.0)
turn = math.radians(37)
bx = -((math.cos(turn) * (x - 1000) + math.sin(turn) * (y + 500)) / 1.25)
by = -((-math.sin(turn) * (x - 1000) + math.cos(turn) * (y + 500)) / 1.25)
check("indoors: a building's point placed and found again (the drawing's inverse)", near((bx, by), (12.0, -30.0), 1e-6), True)

# --- The words ------------------------------------------------------------------------------------

words = tomllib.loads(ml.LEVELS.read_text())
check("words: the levels", sorted(words), ["far", "middle"])
check("words: the middle level's parts", sorted(words["middle"]), ["images", "images_plan", "last", "look", "look_plan"])
check("words: the far level's parts", sorted(words["far"]), ["images", "last", "look", "open"])
check("words: the middle level is pencil on parchment, straight from above",
      all(w in words["middle"]["look"] for w in ("pencil", "parchment", "straight from above")), True)
check("words: both levels are edits of image 1 (they keep its layout)",
      all("Make image 1 look like" in words[level]["look"] and "never where or what anything is" in words[level]["look"]
          for level in ("middle", "far")), True)
check("words: the far level is photorealistic and keeps image 1's layout",
      all(w in words["far"]["look"] for w in ("photorealistic", "image 1", "image 2")), True)
brief = {"biome": "An old gold mine", "buildings": "Timber.", "places": "Tunnels.", "colours": "brown",
         "atmosphere": "Warm lantern light. Dust."}
middle = ml.words_of("middle", words, brief, True)
far = ml.words_of("far", words, brief, True)
check("words: the middle level's pictures first", middle.startswith(words["middle"]["images"]), True)
check("words: the middle level takes no brief", brief["places"] in middle or "This place is" in middle, False)
check("words: no cut-away in the middle level", words["far"]["open"] in middle, False)
check("words: an instance's far level cuts away its roofs", words["far"]["open"] in far, True)
check("words: a zone's far level does not", words["far"]["open"] in ml.words_of("far", words, brief, False), False)
check("words: the kind of place, in lower case", "This place is an old gold mine." in far, True)
check("words: the light is the atmosphere's first sentence", "Its light: Warm lantern light." in far, True)
check("words: the last sentence last", far.endswith(words["far"]["last"]), True)
check("words: another place's map for its manner only",
      ml.words_of("middle", words, dict(brief, _style_only=True), True).startswith(words["middle"]["images_plan"]), True)
check("strength: one a try, the first the strictest",
      all(len(ml.STRENGTH[level]) == ml.TRIES and list(ml.STRENGTH[level]) == sorted(ml.STRENGTH[level])
          for level in ("middle", "far")), True)
check("framed: the frame's width, its height on a multiple of 32",
      ml.framed(Image.new("RGB", (1002, 668))).size, (ml.SIDE, 1376))

# --- The outline check ----------------------------------------------------------------------------

plan = Image.new("RGB", (600, 400), (40, 40, 40))
draw = ImageDraw.Draw(plan)
draw.rectangle((80, 60, 260, 200), fill=(220, 210, 180))
draw.ellipse((330, 150, 520, 330), fill=(200, 190, 160))
draw.line((260, 130, 330, 240), fill=(220, 210, 180), width=18)
same = plan.copy()
check("agreement: a picture with itself", round(ml.agreement(plan, same), 3), 1.0)
moved = ImageChops.offset(plan, 90, 40)
check("agreement: a layout moved agrees less", ml.agreement(moved, plan) < 0.6, True)
redrawn = Image.new("RGB", (600, 400), (230, 220, 200))
draw = ImageDraw.Draw(redrawn)
draw.rectangle((80, 60, 260, 200), outline=(90, 90, 90), width=4)
draw.ellipse((330, 150, 520, 330), outline=(90, 90, 90), width=4)
draw.line((260, 130, 330, 240), fill=(90, 90, 90), width=4)
check("agreement: the same layout drawn as outlines agrees more than a moved one",
      ml.agreement(redrawn, plan) > ml.agreement(moved, plan), True)

# --- The vision model's answers -------------------------------------------------------------------

check("verdict: a pencil map passes",
      ml.verdict("middle", '{"writing": false, "pencil_map": true, "from_above": true}')[0], True)
check("verdict: writing on a map fails",
      ml.verdict("middle", '{"writing": true, "pencil_map": true, "from_above": true}')[0], False)
check("verdict: a far render passes",
      ml.verdict("far", '{"writing": false, "map_or_drawing": false, "panels": false, "from_above": true, "is_it": true}')[0],
      True)
check("verdict: a far render that is a drawing fails",
      ml.verdict("far", '{"writing": false, "map_or_drawing": true, "panels": false, "from_above": true, "is_it": true}')[0],
      False)
check("verdict: an answer that cannot be read fails", ml.verdict("far", "no idea")[0], False)
check("look: the far level asks for the brief's kind of place", brief["biome"] in ml.look_words("far", brief), True)

# --- An instance floor's map art ------------------------------------------------------------------

import tempfile  # noqa: E402

with tempfile.TemporaryDirectory() as folder:
    art = Path(folder)
    tile = Image.new("RGBA", (256, 256), (150, 120, 80, 255))
    ImageDraw.Draw(tile).rectangle((60, 0, 200, 20), fill=(250, 250, 250, 255))   # a banner at the top
    tile.save(art / "1.png")
    (art / "1.blp").write_bytes((art / "1.png").read_bytes())   # Pillow opens it by its content
    floor = {"size": (256, 256), "tile": 256, "tiles": [(0, 0, 1)]}
    picture = ml.floor_art(floor, art)
    check("floor art: its size", picture.size, (256, 256))
    check("floor art: the banner made parchment", picture.getpixel((128, 8)) != (250, 250, 250), True)
    check("floor art: the map kept", picture.getpixel((128, 128)), (150, 120, 80))

print(f"Map layers: all {checks} checks passed." if not failed else f"Map layers: {failed} of {checks} checks failed.")
sys.exit(1 if failed else 0)
