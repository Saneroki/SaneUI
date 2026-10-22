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

import numpy as np
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
check("words: the far level's parts", sorted(words["far"]), ["around", "images", "images_zone", "last", "look", "look_zone", "open"])
check("words: the middle level is pencil on parchment, straight from above",
      all(w in words["middle"]["look"] for w in ("pencil", "parchment", "straight from above")), True)
check("words: both levels are edits of image 1 (they keep its layout)",
      all(w in words[level]["look"] for level, w in (("middle", "Make image 1 look like"), ("far", "Make image 1 a"))), True)
check("words: the middle level keeps its layout exactly", "never where or what anything is" in words["middle"]["look"], True)
check("words: the far level a photograph straight down of where image 1's places lie, a zone's and an instance's",
      all(w in words["far"][look] for w in ("photograph", "straight down", "exactly where image 1 has it", "image 2")
          for look in ("look", "look_zone")), True)
check("words: no view at an angle any more", any("angle" in words[level][part] or "plane" in words[level][part]
                                                for level in words for part in words[level] if isinstance(words[level][part], str)), False)
heights = np.array([[np.nan, 0.0, 10.0], [20.0, 30.0, 40.0]], np.float32)
shades = np.asarray(ml.height_map(heights).convert("L"))
check("height map: the highest ground white, the lowest dark, no terrain black",
      (int(shades[1, 2]), int(shades[0, 1]), int(shades[0, 0])), (255, 40, 0))
check("height map: higher is lighter", bool(shades[0, 1] < shades[0, 2] < shades[1, 0] < shades[1, 1] < shades[1, 2]), True)
classes = Image.fromarray(np.array([[ml.SWIM, ml.WALKED] * 50] * 70, np.uint8))
check("framed: a walking picture keeps its shades (nearest)",
      set(np.unique(np.asarray(ml.framed(classes, Image.Resampling.NEAREST)))) <= {ml.SWIM, ml.WALKED}, True)
deep = ml.sea_of(np.array([[10, 20, 30], [10, 20, 30], [60, 90, 90], [60, 90, 90]], np.uint8))
check("sea: the game's darkest water deep blue, its lighter shallows turquoise",
      (tuple(deep[0]), tuple(deep[-1])), (ml.SEA, ml.SHALLOWS))
brief = {"biome": "An old gold mine", "buildings": "Timber.", "places": "Tunnels.", "colours": "brown",
         "atmosphere": "Warm lantern light. Dust."}
middle = ml.words_of("middle", words, brief, True)
far = ml.words_of("far", words, brief, True)
check("words: the middle level's pictures first", middle.startswith(words["middle"]["images"]), True)
check("words: the middle level takes no brief", brief["places"] in middle or "This place is" in middle, False)
check("words: no cut-away in the middle level", words["far"]["open"] in middle, False)
check("words: an instance's far level cuts away its roofs", words["far"]["open"] in far, True)
check("words: a zone's far level does not", words["far"]["open"] in ml.words_of("far", words, brief, False), False)
check("words: a zone's far level starts from its blurred terrain",
      ml.words_of("far", words, brief, False).startswith(words["far"]["images_zone"]), True)
check("words: the lands around a zone, by direction, before the last sentence",
      "to the east, a dark forest; to the north, hills." in ml.words_of("far", words, brief, False,
                                                                      [("east", "A dark forest"), ("north", "hills")]), True)
zone = {"box": (100.0, 0.0, 100.0, 0.0), "map": 0, "key": 1}
found = {1: (0, (100.0, 0.0, 100.0, 0.0), 0), 2: (0, (100.0, 0.0, 30.0, -70.0), 0), 3: (0, (130.0, 30.0, 100.0, 0.0), 0),
         4: (1, (100.0, 0.0, 30.0, -70.0), 0), 5: (0, (500.0, 400.0, 100.0, 0.0), 0)}
check("around: the zones reaching into a zone's frame, east and north; not itself, another continent's or one out of it",
      sorted(ml.around_of(zone, found, {"1": {}, "2": {}, "3": {}, "4": {}, "5": {}})), [("east", 2), ("north", 3)])
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
check("verdict: a far render the vision model calls a map still passes (it calls every photograph straight down one)",
      ml.verdict("far", '{"writing": false, "map_or_drawing": true, "panels": false, "from_above": true, "is_it": true}')[0],
      True)
check("verdict: a far render with writing fails",
      ml.verdict("far", '{"writing": true, "map_or_drawing": false, "panels": false, "from_above": true, "is_it": true}')[0],
      False)
check("verdict: an answer that cannot be read fails", ml.verdict("far", "no idea")[0], False)
check("look: the far level asks for the brief's kind of place", brief["biome"] in ml.look_words("far", brief), True)
check("look: the middle level asks for tinted parchment", "tinted parchment" in ml.look_words("middle", brief), True)
check("look: the far level asks for a view straight down", "straight down" in ml.look_words("far", brief), True)
check("words: the middle level washed in image 1's own colours, not on cream",
      all("parchment" in words["middle"][part] and "cream" not in words["middle"][part] for part in ("look", "look_plan", "last"))
      and "own colours" in words["middle"]["look"], True)
green = Image.new("RGB", (60, 40), (70, 120, 40))
ImageDraw.Draw(green).rectangle((0, 0, 59, 9), fill=(80, 100, 140))   # a strip of grey-blue sea
check("tone: a green zone's map gives green parchment, its sea left out", ml.tone_of(green), (70, 120, 40))
grass = Image.new("RGB", (40, 40), (60, 130, 40))
check("land tone: a green zone's land gives a greener parchment than the game maps' ochre",
      bool(ml.land_tone(grass, -1)[1] / ml.land_tone(grass, -1)[0] > ml.PARCHMENT[1] / ml.PARCHMENT[0]), True)
check("land tone: a zone of water only keeps the game maps' ochre", ml.land_tone(Image.new("RGB", (8, 8), (40, 80, 140)), -1), ml.PARCHMENT)
leafy = np.asarray(ml.parchment((32, 32), ml.tone_of(green))).reshape(-1, 3).mean(0)
check("parchment: in a green map's tone, green over red and blue", bool(leafy[1] > leafy[0] and leafy[1] > leafy[2]), True)
paper = np.asarray(ml.parchment((64, 64))).reshape(-1, 3).mean(0)
check("parchment: the game maps' yellow-orange, red over green over blue",
      bool(paper[0] > paper[1] > paper[2] and paper[0] - paper[2] > 60), True)

# --- The walking data -----------------------------------------------------------------------------

import base64  # noqa: E402
import zlib  # noqa: E402


def encoded(value):
    """CBOR of whole numbers and arrays, as the walking blocks are written."""
    if isinstance(value, list):
        head, body = 4, b"".join(encoded(item) for item in value)
        size = len(value)
    else:
        head, body, size = (0, b"", value) if value >= 0 else (1, b"", -1 - value)
    if size < 24:
        return bytes([head << 5 | size]) + body
    width = next(n for n in (1, 2, 4, 8) if size < 1 << (8 * n))
    return bytes([head << 5 | {1: 24, 2: 25, 4: 26, 8: 27}[width]]) + size.to_bytes(width, "big") + body


check("cbor: numbers, a negative one and arrays read back",
      ml.cbor(encoded([1, [200, -3, 70000], []]))[0], [1, [200, -3, 70000], []])
packed = zlib.compressobj(9, zlib.DEFLATED, -15)
# one tile: its north half a floor of land, its south half water, a strip at its east edge where nobody walks
data = packed.compress(encoded([1, [1, 1, 0, 1, 2, 0], [0, 0, 240, 128, 0, 0, 128, 240, 128, 0], []])) + packed.flush()
walking = ml.Walking(Path("/nonexistent"))
row, column = 30, 31
walking.blocks[row * ml.GRID + column] = base64.b64encode(data).decode("ascii")
north, west = ml.CENTRE - row * ml.TILE, ml.CENTRE - column * ml.TILE
tile = walking.picture(0, (north, north - ml.TILE, west, west - ml.TILE), 256)
check("walking: a floor of land", tile.getpixel((60, 60)), ml.WALKED)
check("walking: water", tile.getpixel((60, 200)), ml.SWIM)
check("walking: where nobody walks", tile.getpixel((250, 60)), ml.BARRED)
around = walking.picture(0, (north + ml.TILE / 2, north - ml.TILE, west, west - ml.TILE), 256)
check("walking: no data beyond its tiles", around.getpixel((60, 20)), ml.NOWHERE)
shades = np.full((300, 400), ml.WALKED, np.uint8)
shades[150:] = ml.SWIM          # water in the south
shades[30:120, 250:400] = ml.BARRED  # a mountain
shades[200:300, 0:40] = ml.NOWHERE   # beyond the data
guide = np.asarray(ml.guide_of(Image.fromarray(shades)).convert("L")) > 127
check("guide: the shore drawn", guide[146:154, 50:60].any(), True)
check("guide: not the mountain's foot (it came out a lake; the relief holds it)", guide[115:125, 300].any(), False)
check("guide: open land and open water plain", guide[80, 50] or guide[250, 100], False)
check("guide: nothing along the edge of the data", guide[220:280, 36:46].any(), False)
walk = Image.fromarray(shades)
wet = Image.new("RGB", (400, 300), (196, 170, 110))
ImageDraw.Draw(wet).rectangle((0, 150, 399, 299), fill=(40, 90, 150))
dry = Image.new("RGB", (400, 300), (196, 170, 110))
check("water check: the walking data's water painted where it is passes",
      ml.water_check(walk, wet)["lost"] <= ml.FAR_WATER[1] and ml.water_check(walk, wet)["added"] <= ml.FAR_WATER[0], True)
check("water check: its water painted as land fails", ml.water_check(walk, dry)["lost"] > ml.FAR_WATER[1], True)

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
