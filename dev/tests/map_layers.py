#!/usr/bin/env python3
"""Tests of dev/tools/map-layers, the instance maps' three levels, without ComfyUI and without the game's files: where
a world point lies in a frame, the affine data of a linear map, a building's point placed and found again, the words
of the middle and far levels put together from the shared words and a brief, the outline agreement of pictures (one
layout or another), the vision model's answers read, the parchment's tone, the checks file, the run's subjects (its
instances only) and the game's folders it keeps, and an instance floor's map art with its title banner painted over.
Run by dev/tests/run."""
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
check("words: the far level's parts", sorted(words["far"]), ["images", "last", "look", "open"])
check("words: the middle level is pencil on parchment, straight from above",
      all(w in words["middle"]["look"] for w in ("pencil", "parchment", "straight from above")), True)
check("words: both levels are edits of image 1 (they keep its layout)",
      all(w in words[level]["look"] for level, w in (("middle", "Make image 1 look like"), ("far", "Make image 1 a"))), True)
check("words: the middle level keeps its layout exactly", "never where or what anything is" in words["middle"]["look"], True)
check("words: the far level a photograph straight down of where image 1's places lie",
      all(w in words["far"]["look"] for w in ("photograph", "straight down", "exactly where image 1 has it", "image 2")), True)
check("words: no view at an angle any more", any("angle" in words[level][part] or "plane" in words[level][part]
                                                for level in words for part in words[level] if isinstance(words[level][part], str)), False)
brief = {"biome": "An old gold mine", "buildings": "Timber.", "places": "Tunnels.", "colours": "brown",
         "atmosphere": "Warm lantern light. Dust."}
middle = ml.words_of("middle", words, brief)
far = ml.words_of("far", words, brief)
check("words: the middle level's pictures first", middle.startswith(words["middle"]["images"]), True)
check("words: the middle level takes no brief", brief["places"] in middle or "This place is" in middle, False)
check("words: no cut-away in the middle level", words["far"]["open"] in middle, False)
check("words: an instance's far level cuts away its roofs", words["far"]["open"] in far, True)
check("words: the kind of place, in lower case", "This place is an old gold mine." in far, True)
check("words: the light is the atmosphere's first sentence", "Its light: Warm lantern light." in far, True)
check("words: the last sentence last", far.endswith(words["far"]["last"]), True)
check("words: another place's map for its manner only",
      ml.words_of("middle", words, dict(brief, _style_only=True)).startswith(words["middle"]["images_plan"]), True)
check("words: the brief's buildings and places, in order", far.index("Timber.") < far.index("Tunnels.") < far.index("Its colours"), True)
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
check("tone: a green map gives green parchment, its sea left out", ml.tone_of(green), (70, 120, 40))
leafy = np.asarray(ml.parchment((32, 32), ml.tone_of(green))).reshape(-1, 3).mean(0)
check("parchment: in a green map's tone, green over red and blue", bool(leafy[1] > leafy[0] and leafy[1] > leafy[2]), True)
paper = np.asarray(ml.parchment((64, 64))).reshape(-1, 3).mean(0)
check("parchment: the game maps' yellow-orange, red over green over blue",
      bool(paper[0] > paper[1] > paper[2] and paper[0] - paper[2] > 60), True)

import contextlib  # noqa: E402
import io  # noqa: E402

# --- The checks file, the run's subjects and folders --------------------------------------------------------------

import tempfile  # noqa: E402
from types import SimpleNamespace  # noqa: E402

with tempfile.TemporaryDirectory() as folder:
    check("checks: none yet", ml.checks_of(Path(folder)), {})
    ml.save_checks(Path(folder), {"close-1-2": {"seed": 1}})
    check("checks: saved through a temp file beside it (none left) and read back",
          (ml.checks_of(Path(folder)), sorted(p.name for p in Path(folder).iterdir())),
          ({"close-1-2": {"seed": 1}}, ["checks.json"]))
    (Path(folder) / "checks.json").write_text('{"close-1-2": {"se')   # cut short by a run killed while writing
    with contextlib.redirect_stdout(io.StringIO()) as told:
        found = ml.checks_of(Path(folder))
    check("checks: a file cut short counts as empty, told", (found, "not JSON" in told.getvalue()), ({}, True))

with tempfile.TemporaryDirectory() as folder:
    out = Path(folder)
    asked = dict(out=str(out), instances=[], tables=None, instance_files=None, mapart=None)
    try:
        ml.inputs(SimpleNamespace(**asked))
        refused = None
    except SystemExit as stop:
        refused = str(stop)
    check("inputs: the game's folders needed the first time, each named",
          bool(refused) and all(flag in refused for flag in ("--tables", "--instance-files", "--mapart")), True)
    given = dict(tables=str(out / "tables"), instance_files=str(out / "instances"), mapart=str(out / "mapart"))
    ml.inputs(SimpleNamespace(**dict(asked, **given)))
    kept = ml.load_state(out)["paths"]
    check("inputs: the run's state.json remembers them", kept, {k: str(Path(v).resolve()) for k, v in given.items()})
    ml.inputs(SimpleNamespace(**asked))   # then none is asked for
    check("inputs: none needed again", ml.load_state(out)["paths"], kept)
    state = {"paths": kept, "subjects": [{"name": "zone-1429", "kind": "zone", "key": 1429},
                                         {"name": "instance-36", "kind": "instance", "key": 36}]}
    ml.save_state(out, state)
    check("subjects: only the instances, a zone of an earlier run passed over",
          [s["name"] for s in ml.instances_of(ml.load_state(out))], ["instance-36"])
    (out / "instance-36").mkdir()
    (out / "instance-36" / "far.png").write_bytes(b"far")
    (out / "zone-1429").mkdir()
    (out / "zone-1429" / "far.png").write_bytes(b"far")
    with contextlib.redirect_stdout(io.StringIO()) as told:
        ml.status(SimpleNamespace(out=str(out), levels={"far"}))
    check("status: the instances' paintings alone", told.getvalue().split("\n")[0], "1 of 1 paintings made (1 instances)")

# --- An instance floor's map art ------------------------------------------------------------------

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
