#!/usr/bin/env python3
"""Tests of dev/tools/dungeon-ground, the dungeon maps' ground, without the game's files: the terrain tiles read from a
WDT, the game's floors matched by their name where several share one box, a part laid by its place kept to the heights
of the parts the game names, and a floor's ground that must hold its bosses and enemies (open water and nothing hold
none). Run by dev/tests/run."""
import csv
import importlib.machinery
import importlib.util
import os
import struct
import sys
import tempfile
from pathlib import Path

import numpy as np
from PIL import Image

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
os.chdir(ROOT)

loader = importlib.machinery.SourceFileLoader("dungeon_ground", str(ROOT / "dev" / "tools" / "dungeon-ground"))
dg = importlib.util.module_from_spec(importlib.util.spec_from_loader("dungeon_ground", loader))
loader.exec_module(dg)
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


def chunk(name, body):
    """A chunk as the game's files hold it: its name backwards, its size, its data."""
    return name[::-1] + struct.pack("<I", len(body)) + body


# --- The terrain tiles, from the WDTs -------------------------------------------------------------

with tempfile.TemporaryDirectory() as folder:
    folder = Path(folder)
    (folder / "wdt").mkdir()
    ids = [0] * (dg.GRID * dg.GRID * 8)
    ids[(31 * dg.GRID + 32) * 8 + 7] = 205048  # row 31, column 32: its minimap texture
    ids[(31 * dg.GRID + 33) * 8] = 77          # a root ADT without a minimap texture: no tile
    (folder / "wdt" / "36.wdt").write_bytes(chunk(b"MVER", struct.pack("<I", 18))
                                            + chunk(b"MAID", struct.pack(f"<{len(ids)}I", *ids)))
    (folder / "wdt" / "34.wdt").write_bytes(chunk(b"MVER", struct.pack("<I", 18)))  # a building alone
    (folder / "tiles.jsonl").write_text('{"key": 1, "minimap": 2}\n')  # another extraction's: not read
    check("tiles: a WDT's minimap textures by row and column", dg.tiles_of(folder), {36: [(31, 32, 205048)]})

# --- The game's floors: by their box, of several with one box by their name -----------------------

TOWER = {"north": -91.6, "south": -193.22, "west": 2256.2, "east": 2103.77}
HALL = {"north": -161.6, "south": -303.21, "west": 2359.98, "east": 2147.56}
with tempfile.TemporaryDirectory() as folder:
    tables = Path(folder)
    with open(tables / "UiMapGroupMember.csv", "w", newline="", encoding="utf-8") as file:
        out = csv.writer(file)
        out.writerow(["ID", "Name_lang", "UiMapGroupID", "UiMapID", "FloorIndex", "RelativeHeightIndex"])
        out.writerow([1, "Dining Hall", 147, 311, 2, 0])
        out.writerow([2, "The Vacant Den", 147, 312, 3, 0])
        out.writerow([3, "Lower Observatory", 147, 313, 4, 0])
    with open(tables / "UiMapAssignment.csv", "w", newline="", encoding="utf-8") as file:
        out = csv.writer(file)
        out.writerow(["UiMin[0]", "UiMin[1]", "UiMax[0]", "UiMax[1]"] + [f"Region[{i}]" for i in range(6)]
                     + ["ID", "UiMapID", "OrderIndex", "MapID", "AreaID", "WMODoodadPlacementID", "WMOGroupID"])
        for row, (ui_map, box, group) in enumerate(((311, HALL, 700), (312, TOWER, 500), (313, TOWER, 600),
                                                     (313, TOWER, 0))):
            region = [box["south"], box["east"], -10000, box["north"], box["west"], 1000000]
            out.writerow([0, 0, 1, 1] + region + [row + 1, ui_map, 0, 33, 0, 0, group])
    floors = [dict(floor=2, name="Dining Hall", **HALL), dict(floor=3, name="The Vacant Den", **TOWER),
              dict(floor=4, name="Lower Observatory", **TOWER)]
    got = dg.assignment(tables, {33: floors})[33]
    check("assignment: each floor its own parts, though two share a box", got["parts"],
          {(700, 0): {2}, (500, 0): {3}, (600, 0): {4}})
    check("assignment: a row of no part, its floor's terrain", got["terrain"], {4})

# --- A part laid by its place: at the heights of the parts the game names --------------------------


def part(unique, building, low, x=-7700.0, y=-1100.0):
    return {"unique": unique, "placement": 1, "place": {"x": x, "y": y, "yaw": 90.0, "scale": 1.0},
            "box": (0.0, 0.0, 0.0, 16.0, 16.0, 20.0), "blocks": {(0, 0): unique}, "sizes": {unique: (32, 32)},
            "low": low, "high": low + 20, "middle": (x, y), "building": building}


lair = {"key": 469, "floors": [{"floor": 1, "name": "Dragonmaw Garrison", "north": -7600.0, "south": -7800.0,
                                "west": -1000.0, "east": -1300.0}], "tiles": []}
parts = [part(15175, 108348, 390.0), part(15176, 108348, 395.0),  # the lair's: named, and one it leaves off
         part(1470, 110553, 198.0),                              # the mountain's below: far under the named
         part(31000, 120000, 400.0)]                             # a building of the game's own at their height
tally = {"named": 0, "not named": 0, "by place": 0, "on no floor": 0, "out of reach": 0}
assigned = {469: {"parts": {(15175, 0): {1}}, "terrain": set()}}
real = dg.parts_of
dg.parts_of = lambda *_: parts
try:
    rows, on = dg.instance(lair, None, {}, assigned, {}, None, None, {}, tally)
finally:
    dg.parts_of = real
check("heights: the named part and the building at its height laid", sorted(row["file"] for row in rows),
      [15175, 31000])
check("heights: the floor's parts given back with its rows", sorted(p["unique"] for p in on[1]), [15175, 31000])
check("heights: the building far below out of reach, the unnamed part on no floor", tally,
      {"named": 1, "not named": 1, "by place": 1, "on no floor": 0, "out of reach": 1})

# --- A floor's ground holds its bosses and enemies -----------------------------------------------


class Pictures:
    def __init__(self, pictures):
        self.pictures = pictures

    def get(self, file):
        return self.pictures.get(file)


floor = {"floor": 1, "width": 200, "height": 100, "north": 100.0, "south": 0.0, "west": 200.0, "east": 0.0}
land = np.random.default_rng(1).integers(60, 160, (100, 200, 3), dtype=np.uint8)  # rough ground, its left half
land[:, 100:] = 19                                                               # open water, flat and dark
ground = np.dstack([land, np.full((100, 200), 255, np.uint8)])
pictures = Pictures({1: Image.fromarray(ground, "RGBA"), 2: Image.new("RGBA", (16, 16), (200, 180, 120, 255))})
rows = [{"floor": 1, "file": 1, "x": 50.0, "y": 100.0, "width": 200.0, "height": 100.0, "yaw": 90, "terrain": True},
        {"floor": 1, "file": 2, "x": 20.0, "y": 40.0, "width": 20.0, "height": 20.0, "yaw": 90}]  # a hall on the water
things = {"bosses": [{"floor": 1, "x": 0.8, "y": 0.8}, {"floor": 2, "x": 0.9, "y": 0.1}],
          "enemies": [{"floor": 1, "x": 0.2, "y": 0.5}, {"floor": 1, "x": 0.7, "y": 0.3}]}
standing = dg.standing(things, floor, rows, pictures)
check("standing: a boss on a hall, an enemy on land, one on open water; another floor's not",
      [(kind, on) for _, _, kind, on in standing], [("boss", True), ("enemy", True), ("enemy", False)])
check("standing: nothing under a thing holds none", [on for *_, on in dg.standing(things, floor, [], pictures)],
      [False, False, False])
check("holds: an enemy of two on open water: the floor keeps its art alone", dg.holds(standing), False)
check("holds: all on its ground", dg.holds(standing[:2]), True)
many = [(0.5, 0.5, "enemy", True)] * 19 + [(0.7, 0.3, "enemy", False)]
check("holds: one enemy of twenty off (OFF): kept", dg.holds(many), True)
check("holds: a boss off: never", dg.holds(many[:19] + [(0.7, 0.3, "boss", False)]), False)
check("holds: a floor with nothing on it", dg.holds([]), True)

# --- Where the art draws nothing: the ground alone ----------------------------------------------

with tempfile.TemporaryDirectory() as folder:
    mapart = Path(folder)
    art = Image.new("RGB", (256, 256), (150, 120, 80))  # plain parchment, one hall drawn on it
    hall = Image.new("RGB", (60, 60), (60, 40, 20))
    hall.paste((200, 180, 140), (3, 3, 57, 57))
    art.paste(hall, (40, 40))
    art.save(mapart / "1.png")
    (mapart / "1.blp").write_bytes((mapart / "1.png").read_bytes())  # Pillow opens it by its content
    floor = {"floor": 1, "width": 256, "height": 256, "tile": 256, "north": 256.0, "south": 0.0, "west": 256.0,
             "east": 0.0}
    entry = {"key": 43, "floors": [floor], "tiles": [{"floor": 1, "row": 0, "column": 0, "file": 1}]}
    pictures = Pictures({41: Image.new("RGBA", (120, 120), (90, 90, 90, 255)),
                         42: Image.new("RGBA", (120, 120), (90, 90, 90, 255))})
    drawn_hall = part(41, 1, 0.0, x=156.0, y=216.0)    # 60 yards square over the art's hall (40 to 100 each way)
    new_cave = part(42, 2, 0.0, x=46.0, y=106.0)       # over plain parchment (150 to 210 each way)
    drawn_hall["sizes"], new_cave["sizes"] = {41: (120, 120)}, {42: (120, 120)}  # 2 texels a yard
    on_hall, in_cave = (70 / 256, 70 / 256, "boss", True), (180 / 256, 180 / 256, "enemy", True)
    check("undrawn: three of four on a part the art draws nothing of",
          dg.undrawn(entry, floor, [drawn_hall, new_cave], [on_hall] + [in_cave] * 3, mapart, pictures), 0.75)
    check("undrawn: all on the art's hall", dg.undrawn(entry, floor, [drawn_hall, new_cave], [on_hall] * 2, mapart,
                                                       pictures), 0.0)
    check("undrawn: a floor without art", dg.undrawn(dict(entry, tiles=[]), floor, [new_cave], [in_cave], mapart,
                                                     pictures), 0.0)

print(f"Dungeon ground: all {checks} checks passed." if not failed else
      f"Dungeon ground: {failed} of {checks} checks failed.")
sys.exit(1 if failed else 0)
