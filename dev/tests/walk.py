#!/usr/bin/env python3
"""Tests of dev/tools/walk-data, dev/tools/walk-gates and dev/tools/travel-data without the game's files: the block's
encoding, floors joined into surfaces and rectangles on made-up ground (flat land, a steep speck, a hole, a cliff, a
bridge, water), buildings and doodads placed as the game places them (turned, tilted; a model's collision, a
building's doodad sets, the object files' placements) and rasterized (a fence, a deck), the openings the game is left
to work out and those written (each found both ways, on a tile and into the next, on both their rectangles' sides;
none through another floor but one where a tile's parts need it), regions too small to keep and their order (but the
rooms a lift or a portal lands in), a flight's path made short, a boat's way (its docks, on the zone maps too, its
leaps, which way a newer one replaced), a lift's car (its motion, its ends and rides, its own number kept for its
place), a way's side (its towns', by the flight masters near its docks) and a portal (the client's trigger, where a
batch says it brings one). The coarse layer over the walking data (walk-gates): a tile's parts, its gates along each
border, the ways between them (through a door, round a pond a rider will not swim), their numbers, the field; and the
master's layer made from its blocks as they are. And dev/tools/terrain-art's open sky around an isle that floats
(walk-data reads the terrain with it). Run by dev/tests/run."""
import base64
import importlib.machinery
import importlib.util
import json
import math
import os
import re
import struct
import sys
import tempfile
import zlib
from pathlib import Path

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
os.chdir(ROOT)


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    module = importlib.util.module_from_spec(importlib.util.spec_from_loader(name, loader))
    loader.exec_module(module)
    return module


walk = load("walk_data", ROOT / "dev" / "tools" / "walk-data")
travel = load("travel_data", ROOT / "dev" / "tools" / "travel-data")
np = walk.np
SIDE, LAND, WATER, BUILT = walk.SIDE, walk.LAND, walk.WATER, walk.BUILT
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


def decode(data, at=0):
    """CBOR's whole numbers and arrays, as the game's DeserializeCBOR reads them."""
    head = data[at]
    major, info = head >> 5, head & 31
    at += 1
    if info < 24:
        number = info
    else:
        size = {24: 1, 25: 2, 26: 4, 27: 8}[info]
        number = int.from_bytes(data[at:at + size], "big")
        at += size
    if major == 0:
        return number, at
    if major == 1:
        return -1 - number, at
    items = []
    for _ in range(number):
        item, at = decode(data, at)
        items.append(item)
    return items, at


# --- CBOR ------------------------------------------------------------------------------------------
check("a small number is one byte", walk.cbor(5), bytes([5]))
check("a number past 23 takes a byte more", walk.cbor(200), bytes([0x18, 200]))
check("a negative number", walk.cbor(-3), bytes([0x22]))
check("an array of them", decode(walk.cbor([1, [70000, -1, 23]]))[0], [1, [70000, -1, 23]])
check("the tool's own reader (walk-gates' too) gives the value back",
      walk.decode(walk.cbor([1, [70000, -1, 23], []])), [1, [70000, -1, 23], []])


# --- Made-up ground --------------------------------------------------------------------------------
def ground(height=10.0):
    """A tile of flat walkable ground: its alone grid, no columns with buildings, no specks, nothing built."""
    alone = np.full((SIDE, SIDE), height)
    return alone, {}, np.full((SIDE, SIDE), np.nan), np.zeros((SIDE, SIDE), bool)


def cut(alone, found, specks, built):
    rects, owner, columns = walk.rectangles(alone, found, specks, built)
    borders = {}
    links = walk.openings(rects, owner, columns, borders)
    return rects, owner, columns, links, borders


flat = cut(*ground())
check("flat land: squares of the widest side, joined no further", len(flat[0]), (SIDE // walk.WIDEST) ** 2)
check("every floor owned", len(flat[1]), SIDE * SIDE)
check("each square open to its neighbours, four sides inside", sorted(len(v) for v in flat[3].values())[-1], 4)
check("the tile's edges are borders for the next tile", len(flat[4][0]), SIDE)

# A steep speck in the middle of flat land: walked over, the square taken whole.
alone, found, specks, built = ground()
alone[100, 100] = np.nan
specks[100, 100] = 25.0
speck = cut(alone, found, specks, built)
check("a speck of steep ground is taken into its square", len(speck[0]), (SIDE // walk.WIDEST) ** 2)
check("and walked over at the square's height", speck[2][100][100][0][0], 10.0)

# A hole (a cave's mouth): never walked over.
alone, found, specks, built = ground()
alone[100, 100] = np.nan
holed = cut(alone, found, specks, built)
check("a hole is no floor of any rectangle", any(key[:2] == (100, 100) for key in holed[1]), False)
check("so its square is cut smaller", len(holed[0]) > (SIDE // walk.WIDEST) ** 2, True)

# A cliff: the east half 20 yards higher. Two surfaces, no opening between them.
alone, found, specks, built = ground()
alone[:, 128:] = 30.0
cliff = cut(alone, found, specks, built)
surfaces = walk.surfaces(cliff[2])
check("a cliff makes two surfaces", len(surfaces), 2)
crossing = [link for number, links in cliff[3].items() for link in links
            if (cliff[0][number][0] < 128) != (cliff[0][link[3]][0] < 128)]
check("and nothing crosses it", crossing, [])

# A bridge: a deck 8 yards over the ground along row 50, ramps nowhere (a deck alone: its own surface).
alone, found, specks, built = ground()
for column in range(60, 100):
    found[(50, column)] = [(10.0, LAND, True), (18.0, LAND, False)]
    built[50, column] = True
bridge = cut(alone, found, specks, built)
check("a deck over the ground: the ground and the deck, each a surface", len(walk.surfaces(bridge[2])), 2)
check("both floors of a column owned, by different rectangles",
      bridge[1][(50, 70, 0)] != bridge[1][(50, 70, 1)], True)

# Water beside land: two surfaces, open to each other at the shore.
alone, found, specks, built = ground()
for row in range(SIDE):
    for column in range(200, SIDE):
        found[(row, column)] = [(10.0, WATER, False)]
shore = cut(alone, found, specks, built)
kinds = {rect[5] for rect in shore[0]}
check("land and water, in rectangles of their own", kinds, {LAND, WATER})
across = [link for number, links in shore[3].items() for link in links if shore[0][number][5] != shore[0][link[3]][5]]
check("open to each other along the shore", len(across) > 0, True)


# --- Buildings: their slopes, their walls ----------------------------------------------------------
def quad(a, b, c, d):
    """A building's quad as two triangles, its corners in the tile's samples (column, row, height)."""
    return [np.array([a, b, c], float), np.array([a, c, d], float)]


def built_tile(triangles, height=10.0):
    """Flat ground with buildings' triangles on it, as tile() makes it: rectangles, owner, columns, openings,
    borders, and the walls rasterize found."""
    spans, walls = {}, {}
    walk.rasterize(np.array(triangles), spans, walls)
    flat = np.full((SIDE, SIDE), height, np.float32)
    none = np.full((SIDE, SIDE), -np.inf, np.float32)
    alone, found, specks, built = walk.floors(flat, np.zeros((SIDE, SIDE), bool), none, none, spans, walls)
    rects, owner, columns = walk.rectangles(alone, found, specks, built, walls)
    borders = {}
    links = walk.openings(rects, owner, columns, borders, walls)
    return rects, owner, columns, links, borders, walls


def joined(tile, a, b):
    """Whether the floors of samples a and b (row, column; the first floor each) can be walked between on the tile."""
    rects, owner, _, links, _, _ = tile
    parent = list(range(len(rects)))

    def find(node):
        while parent[node] != node:
            node = parent[node]
        return node

    for number, list_ in links.items():
        for *_, target in list_:
            parent[find(number)] = find(target % 65536)
    return find(owner[(*a, 0)]) == find(owner[(*b, 0)])


# Slopes are judged in yards, not in samples across and yards up (where a ramp of 30 degrees was too steep).
rise = walk.SAMPLE * math.tan(math.radians(35))
spans = {}
walk.rasterize(np.array(quad((0, 0, 0), (4, 0, 0), (4, 4, 4 * rise), (0, 4, 4 * rise))), spans, {})
check("a ramp of 35 degrees is walkable", all(walkable for column in spans.values() for *_, walkable in column), True)
steep = walk.SAMPLE * math.tan(math.radians(55))
spans = {}
walk.rasterize(np.array(quad((0, 0, 0), (4, 0, 0), (4, 4, 4 * steep), (0, 4, 4 * steep))), spans, {})
check("one of 55 degrees is not", any(walkable for column in spans.values() for *_, walkable in column), False)

# A wall 5 yards high along column 10.9, off the middle of the samples of column 10: their floors stay, the wall
# stands on their east sides.
wall = quad((10.9, 0, 10), (10.9, 256, 10), (10.9, 256, 15), (10.9, 0, 15))
walled = built_tile(wall)
spans, walls = {}, {}
walk.rasterize(np.array(wall), spans, walls)
check("a wall off a sample's middle takes no floor", (5, 10) in spans, False)
check("it stands on the side whose way it crosses", sorted(side for row, column, side in walls if row == 5), [1])
check("the floors on its two sides are not one way", walk.walled(walls, 5, 10, 1, 10.0, 10.0), True)
check("nor walked between on the tile", joined(walled, (5, 10), (5, 11)), False)
check("a wall through a sample's middle takes its floor",
      built_tile(quad((10.5, 0, 10), (10.5, 256, 10), (10.5, 256, 15), (10.5, 0, 15)))[2][5][10], [])

# The same wall with a door 3.75 yards wide (rows 10.1 to 11.9), its sides in the margins of the samples beside it:
# narrower than two samples, still open.
door = (quad((10.9, 0, 10), (10.9, 10.1, 10), (10.9, 10.1, 15), (10.9, 0, 15))
        + quad((10.9, 11.9, 10), (10.9, 256, 10), (10.9, 256, 15), (10.9, 11.9, 15))
        + quad((10.6, 10.1, 10), (11.2, 10.1, 10), (11.2, 10.1, 15), (10.6, 10.1, 15))
        + quad((10.6, 11.9, 10), (11.2, 11.9, 10), (11.2, 11.9, 15), (10.6, 11.9, 15)))
opened = built_tile(door)
check("a door narrower than two samples: its samples keep their floors",
      all(opened[2][row][column] for row in (10, 11) for column in (10, 11)), True)
check("and the way through it", joined(opened, (10, 10), (10, 11)), True)
check("so both sides of the wall are walked between", joined(opened, (5, 10), (5, 11)), True)

# What stands between two floors side by side: a wall over them, a railing, a sill, a ledge, the risers of stairs, a
# beam overhead.
check("a wall closes the way", walk.stands([(10.0, 15.0)], 10.0, 10.0), True)
check("a railing too", walk.stands([(10.8, 11.2)], 10.0, 10.0), True)
check("a sill does not", walk.stands([(10.0, 10.3)], 10.0, 10.0), False)
check("a ledge two yards high does", walk.stands([(10.0, 12.0)], 10.0, 12.0), True)
check("a stair's steps do not", walk.stands([(10.0, 10.5), (10.5, 11.0), (11.0, 11.5), (11.5, 12.0)], 10.0, 12.0), False)
check("a beam overhead does not", walk.stands([(12.5, 13.0)], 10.0, 10.0), False)

# A wall at the tile's east edge closes the way into the next tile; the next tile's border has none.
edge = built_tile(quad((255.9, 0, 10), (255.9, 256, 10), (255.9, 256, 15), (255.9, 0, 15)))
plain = cut(*ground())
middle = 32 * 64 + 32
tiles = {middle: (edge[0], edge[3], edge[4]), middle + 1: (plain[0], plain[3], plain[4])}
walk.across(tiles)
check("a wall on a tile's edge closes the way into the next tile",
      any(target >= 65536 * 2 for links in tiles[middle][1].values() for *_, target in links), False)
tiles = {middle: (plain[0], {n: list(v) for n, v in plain[3].items()}, plain[4]),
         middle + 1: (plain[0], {n: list(v) for n, v in plain[3].items()}, plain[4])}
walk.across(tiles)
check("without it the tiles are open to each other",
      any(target >= 65536 * 2 for links in tiles[middle][1].values() for *_, target in links), True)


# --- Placed as the game places them: buildings and doodads ------------------------------------------
HALF = walk.HALF
where = dict(at=(100.0, 5.0, 200.0), turn=(0.0, 90.0, 0.0), scale=2.0)
check("turned a quarter about the height: its own x points east, its y north, z up; scaled; moved",
      bool(np.allclose(walk.placed(where, np.array([[[1.0, 0, 0], [0, 1.0, 0], [0, 0, 1.0]]])),
                       [[[HALF - 200, HALF - 102, 5.0], [HALF - 198, HALF - 100, 5.0],
                         [HALF - 200, HALF - 100, 7.0]]])), True)
# A building of the game (tile 7325) turned and tilted on both axes: its own box (MOHD) placed is the box its
# object file keeps for it (MODF), corner for corner.
where = dict(at=(16000.1298828125, 74.25980377197266, 27123.3828125), turn=(-30.000001907348633, 359.5, 19.0),
             scale=1.0)
low = (-71.34767150878906, -107.85765075683594, -25.654861450195312)
high = (45.163021087646484, 107.8576431274414, 34.16815948486328)
box = walk.placed(where, np.array([[[x, y, z] for x in (low[0], high[0]) for y in (low[1], high[1])
                                   for z in (low[2], high[2])]]))[0]
kept = np.array([[HALF - 27191.361328125, HALF - 16111.0458984375, -12.831830978393555],
                 [HALF - 27028.6796875, HALF - 15886.6748046875, 155.23016357421875]])
check("a building tilted 30 and 19 degrees lands in the box the game keeps for it",
      float(max(np.abs(box.min(axis=0) - kept[0]).max(), np.abs(box.max(axis=0) - kept[1]).max())) < 0.01, True)


def chunk(name, data):
    """A chunk of the game's map files: its name backwards, its size, its data."""
    return name[::-1] + struct.pack("<I", len(data)) + data


def m2(positions, indices):
    """A made-up model (M2, in MD21 as the game's are) whose header's collision holds these triangles."""
    header = bytearray(0x100)
    header[:8] = b"MD20" + struct.pack("<I", 274)
    faces = struct.pack(f"<{len(indices)}H", *indices)
    struct.pack_into("<4I", header, 0xD8, len(indices), len(header), len(positions), len(header) + len(faces))
    body = bytes(header) + faces + struct.pack(f"<{len(positions) * 3}f", *[v for p in positions for v in p])
    return b"MD21" + struct.pack("<I", len(body)) + body


with tempfile.TemporaryDirectory() as folder:
    game = Path(folder)
    for name in ("m2", "wmo", "adt-obj0"):
        (game / name).mkdir()
    (game / "m2" / "901.m2").write_bytes(m2([(0, 0, 0), (1, 0, 0), (0, 1, 0)], [0, 1, 2]))
    (game / "m2" / "902.m2").write_bytes(m2([], []))
    check("a model's collision triangles, from its header", walk.model(game, 901).tolist(),
          [[[0, 0, 0], [1, 0, 0], [0, 1, 0]]])
    check("a model without collision has none", len(walk.model(game, 902)), 0)

    # A building whose first doodad set holds the model three times its size 10 yards along its x, and the model as it
    # is (no wider than SMALL: left out), and whose second set holds it turned a quarter about z (the entry's flags in
    # its top byte), four times its size, 5 yards up.
    quarter = math.sqrt(0.5)
    sets = (struct.pack("<20sII4x", b"Set_$DefaultGlobal", 0, 2) + struct.pack("<20sII4x", b"Set_Own", 2, 1))
    entries = (struct.pack("<I3f4ff4B", 0, 10, 0, 0, 0, 0, 0, 1, 3, 0, 0, 0, 0)
               + struct.pack("<I3f4ff4B", 0, 20, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0)
               + struct.pack("<I3f4ff4B", 1 | 0x01000000, 0, 0, 5, 0, 0, quarter, quarter, 4, 0, 0, 0, 0))
    (game / "wmo" / "990.wmo").write_bytes(chunk(b"MVER", struct.pack("<I", 17)) + chunk(b"MODS", sets)
                                          + chunk(b"MODI", struct.pack("<2I", 901, 901)) + chunk(b"MODD", entries))
    check("a building's global doodad set: its model scaled and moved where the entry puts it, a small one left out",
          [part.round(6).tolist() for part in walk.doodads(game, 990, (0,))], [[[[10, 0, 0], [13, 0, 0], [10, 3, 0]]]])
    check("its own set too: turned by the entry's quaternion, scaled, moved",
          walk.doodads(game, 990, (0, 1))[1].round(6).tolist(), [[[0, 0, 5], [0, 4, 5], [-4, 0, 5]]])
    check("both in the building's triangles (no parts of its own here)", len(walk.building(game, 990, (0, 1))), 2)

    # The object file of a tile: a building showing its doodad set 1, the model 901 four times its size, the model as
    # it is (no wider than SMALL), the one without collision, one named instead of its file ID; and Zephras Isle's way
    # of showing several sets (MWDR, MWDS).
    building = struct.pack("<II3f3f3f3fHHHH", 990, 1, 100, 5, 200, 0, 90, 0, 90, 0, 190, 110, 10, 210, 0x8, 1, 0, 1024)
    doodad = struct.pack("<II3f3fHH", 901, 2, 300, 7, 400, 0, 0, 0, 4096, 0x40)
    small = struct.pack("<II3f3fHH", 901, 6, 300, 7, 400, 0, 0, 0, 1024, 0x40)
    bare = struct.pack("<II3f3fHH", 902, 3, 300, 7, 400, 0, 0, 0, 1024, 0x40)
    named = struct.pack("<II3f3fHH", 0, 4, 300, 7, 400, 0, 0, 0, 1024, 0)
    (game / "adt-obj0" / "2080.adt").write_bytes(chunk(b"MVER", struct.pack("<I", 18)) + chunk(b"MODF", building)
                                                 + chunk(b"MDDF", doodad + small + bare + named))
    several = struct.pack("<II3f3f3f3fHHHH", 990, 5, 100, 5, 200, 0, 90, 0, 90, 0, 190, 110, 10, 210, 0x88, 1, 0, 1024)
    (game / "adt-obj0" / "2081.adt").write_bytes(chunk(b"MVER", struct.pack("<I", 18)) + chunk(b"MODF", several)
                                                 + chunk(b"MWDR", struct.pack("<4I", 0, 0, 1, 2))
                                                 + chunk(b"MWDS", struct.pack("<3H", 5, 3, 4)))
    placed = walk.placements(game)[0]
    kinds = sorted((p["kind"], p["file"], p.get("sets")) for p in placed)
    check("the object files' buildings with the doodad sets they show, and the doodads with collision wider than SMALL",
          kinds, [(walk.BUILDING, 990, (0, 1)), (walk.BUILDING, 990, (0, 3, 4)), (walk.DOODAD, 901, None)])
    shown = next(p for p in placed if p["kind"] == walk.DOODAD)
    check("a doodad's box: as far round its place as its model reaches, scaled", shown["box"],
          (HALF - 400 + 4, HALF - 400 - 4, HALF - 300 + 4, HALF - 300 - 4))

# A doodad on a tile (32, 32 of a continent: its north west corner the world's middle): a fence 4 yards long and
# 1.5 high along its x, turned a quarter (so running east to west) in the south of the samples of row 100, round
# column 50; a deck 3 yards over the ground.
def on_tile(world):
    """World corners (north, west, height) in the samples of the tile at the world's middle."""
    return np.stack([-world[..., 1] / walk.SAMPLE, -world[..., 0] / walk.SAMPLE, world[..., 2]], axis=-1)


fence = np.array(quad((-2, 0, 0), (2, 0, 0), (2, 0, 1.5), (-2, 0, 1.5)))
where = dict(at=(HALF + 50 * walk.SAMPLE, 10.0, HALF + 100.8 * walk.SAMPLE), turn=(0.0, 90.0, 0.0), scale=1.0)
fenced = built_tile(list(on_tile(walk.placed(where, fence))))
check("a fence (a doodad) stands between the samples it runs along",
      walk.walled(fenced[5], 100, 50, 2, 10.0, 10.0), True)
check("the floors on its two sides keep, and are walked between round its end",
      joined(fenced, (100, 50), (101, 50)), True)
across = dict(where, at=(HALF + 128 * walk.SAMPLE, 10.0, HALF + 100.8 * walk.SAMPLE), scale=150.0)  # 600 yards long
check("a fence across the whole tile parts its two sides",
      joined(built_tile(list(on_tile(walk.placed(across, fence / (1, 1, 150))))), (100, 50), (101, 50)), False)
deck = np.array(quad((-3, -3, 3), (3, -3, 3), (3, 3, 3), (-3, 3, 3)))
decked = built_tile(list(on_tile(walk.placed(dict(at=(HALF + 50 * walk.SAMPLE, 10.0, HALF + 50 * walk.SAMPLE),
                                                       turn=(0.0, 0.0, 0.0), scale=1.0), deck))))
check("a doodad's deck is a floor over the ground", [floor[0] for floor in decked[2][50][50]], [10.0, 13.0])
ground_at = np.full((SIDE, SIDE), 10.0, np.float32)
holed = np.zeros((SIDE, SIDE), bool)
holed[7, 7] = True
roots = np.array([[(5.2, 5.2, 8.0), (5.8, 5.2, 9.0), (5.5, 5.8, 9.5)],
                  [(5.2, 5.2, 8.0), (5.8, 5.2, 9.0), (5.5, 5.8, 11.0)],
                  [(7.2, 7.2, 8.0), (7.8, 7.2, 9.0), (7.5, 7.8, 9.5)]])
check("a doodad's triangle wholly under the ground is inside the earth; one coming out of it or under a hole is not",
      walk.sunken(roots, ground_at, holed).tolist(), [True, False, False])
none = np.full((SIDE, SIDE), -np.inf, np.float32)
built = walk.floors(ground_at, np.zeros((SIDE, SIDE), bool), none, none,
                    {(5, 5): [(30.0, 31.0, True)], (6, 6): [(9.0, 12.0, False)]}, {(8, 8, 0): [(40.0, 41.0)]})[3]
check("a canopy high over the ground leaves the ground's rules to its columns, a trunk at the ground does not",
      (bool(built[5, 5]), bool(built[8, 8]), bool(built[6, 6])), (False, False, True))


# --- The ground's own triangles ---------------------------------------------------------------------
# The game draws each cell (4.17 yards) as four triangles meeting at its inner height: a bump in a cell's middle 3 yards
# over its corners rises at 55 degrees, too steep however gentle the slopes around it; 1.5 yards, 36 degrees.
cells = walk.ART.CHUNKS * walk.ART.CELLS
side = walk.TILE / cells
outer, inner = np.zeros((cells + 1, cells + 1)), np.zeros((cells, cells))
inner[10, 10] = 3.0
spike = walk.steepness(outer, inner)
per = SIDE // cells  # samples along a cell's side
check("a cell whose triangles rise over 50 degrees is steep under all its samples",
      bool(spike[10 * per:11 * per, 10 * per:11 * per].all()), True)
check("and only there", int(spike.sum()), per * per)
inner[10, 10] = 1.5
check("one whose triangles rise 36 degrees is not", bool(walk.steepness(outer, inner).any()), False)
for degrees, steep in ((45, False), (55, True)):
    rise = math.tan(math.radians(degrees)) * side
    columns_ = np.arange(cells + 1, dtype=float)
    hill = walk.steepness(np.tile(columns_ * rise, (cells + 1, 1)), np.tile((columns_[:-1] + 0.5) * rise, (cells, 1)))
    check(f"a hillside of {degrees} degrees is {'too steep' if steep else 'walked'}", bool(hill.all() if steep else hill.any()),
          steep)

# --- A stair's pieces, a ceiling ---------------------------------------------------------------------
check("the highest span has room", walk.roomy([[9.5, 10.0, True]], 0), True)
check("a floor with ROOM over it has room", walk.roomy([[9.5, 10.0, True], [12.5, 13.0, True]], 0), True)
check("a stair's next piece close over a sloped one is no ceiling",
      walk.roomy([[9.0, 10.0, True], [10.5, 11.5, True]], 0), True)
check("a flat slab close over a flat floor is", walk.roomy([[9.9, 10.0, True], [10.5, 10.6, True]], 0), False)
check("so is a wall's piece close over a ramp", walk.roomy([[9.0, 10.0, True], [10.5, 11.5, False]], 0), False)

# A wall a fifth of a sample off a sample's middle: a narrow stairwell's side, the sample keeps its floor.
check("a wall a fifth of a sample off the middle takes no floor",
      bool(built_tile(quad((10.7, 0, 10), (10.7, 256, 10), (10.7, 256, 15), (10.7, 0, 15)))[2][5][10]), True)

# --- A building's floor, the sky over a floor ------------------------------------------------------------
deck = built_tile(quad((60, 40, 18), (100, 40, 18), (100, 60, 18), (60, 60, 18)))
check("the ground under a deck and the deck: the ground's kind and a building's",
      [(floor[0], floor[1]) for floor in deck[2][50][70]], [(10.0, LAND), (18.0, BUILT)])
check("the sky over the deck, none over the ground under it", [floor[2] for floor in deck[2][50][70]],
      [walk.COVERED, walk.SKY])
city = built_tile(quad((60, 40, 30), (100, 40, 30), (100, 60, 30), (60, 60, 30)))
check("the ground deep under a building is buried", [floor[2] for floor in city[2][50][70]], [walk.BURIED, walk.SKY])
check("the ground beside it under the sky", deck[2][50][20], [(10.0, LAND, True)])

# --- Water: what stands between a floor and the surface keeps it dry ------------------------------------------
flat10 = np.full((SIDE, SIDE), 10.0, np.float32)
none = np.full((SIDE, SIDE), -np.inf, np.float32)
lake = np.full((SIDE, SIDE), 20.0, np.float32)
spans = {(5, 5): [(13.0, 14.0, True)]}  # a tunnel's roof 3 yards over the ground, under the lake
_, found, _, _ = walk.floors(flat10, np.zeros((SIDE, SIDE), bool), lake, none, spans, {})
check("the ground under a tunnel's roof under a lake stays a floor, the lake over the roof is swum",
      [(floor[0], floor[1]) for floor in found[(5, 5)]], [(10.0, LAND), (20.0, WATER)])
check("the ground under the lake alone is swum over", [(floor[0], floor[1]) for floor in found[(6, 6)]], [(20.0, WATER)])
slime = np.full((SIDE, SIDE), 12.0, np.float32)
_, found, _, _ = walk.floors(flat10, np.zeros((SIDE, SIDE), bool), none, slime, {(5, 5): [(15.0, 15.2, True)]}, {})
check("slime closes the ground under it, not a floor over it", [floor[0] for floor in found[(5, 5)]], [15.2])
check("nor the ground around", found[(6, 6)], [])

# --- A building's water, magma and slime -----------------------------------------------------------
check("an old building's liquids: its number plus one, every fourth water, ocean, magma, slime",
      [walk.liquid(number, 0, 0) for number in (0, 1, 2, 3)], [13, 14, 19, 20])
check("an old building's 15: its first tile's", walk.liquid(15, 0, 3), 20)
check("water of a part marked ocean", walk.liquid(0, 0x80000, 0), 14)
check("the table's own number where the building says so; of the first twenty as the game reads them",
      [walk.liquid(number, 0, None) for number in (1344, 5, 7)], [1344, 13, 19])


def chunk(name, payload):
    return name[::-1] + struct.pack("<I", len(payload)) + payload


with tempfile.TemporaryDirectory() as folder:
    folder = Path(folder)
    (folder / "7.wmo").write_bytes(chunk(b"MOHD", bytes(60) + struct.pack("<HH", 0x4, 0)))
    liquid_ = (struct.pack("<4i3fH", 3, 2, 2, 1, 1.0, 2.0, 0.0, 0)
               + b"".join(struct.pack("<4Bf", 0, 0, 0, 0, 5.0) for _ in range(6)) + bytes([0x00, 0x0F]))
    header = bytes(8) + struct.pack("<I", 0x1000) + bytes(40) + struct.pack("<I", 1344) + bytes(12)
    (folder / "7_000.wmo").write_bytes(chunk(b"MOGP", header + chunk(b"MLIQ", liquid_)))
    pooled = walk.pools(folder, 7)
    unit = walk.TILE / cells
    check("a building's water: its tiles that hold it, each at points over it, of its part's liquid type",
          [(len(points), kind) for points, kind in pooled], [(walk.POURED ** 2, 1344)])
    points = pooled[0][0] if pooled else np.zeros((0, 3))
    check("at the water's height, inside its first tile", (bool((points[:, 2] == 5.0).all()),
          bool((points[:, 0] > 1.0).all() and (points[:, 0] < 1.0 + unit).all())), (True, True))

# --- Regions with no sky over them ----------------------------------------------------------------
covered = [[10, 10, 64, 64, 40, LAND, 0]]
check("a region with the sky over none of its floors is left out (the ground under a city, a closed cellar)",
      (0, 0) in walk.regions({0: (covered, {0: []}, {}, set())}), False)
check("one with the sky over some is kept", (0, 0) in walk.regions({0: (covered, {0: []}, {}, {0})}), True)
check("one a lift lands on is kept all the same", (0, 0) in walk.regions({0: (covered, {0: []}, {}, set())}, {(0, 0)}),
      True)
check("one most of whose floors are buried is left out (the ground under a city, open only between its buildings)",
      (0, 0) in walk.regions({0: (covered, {0: []}, {}, {0}, {0: 64 * 64 // 2 + 1})}), False)
check("one less than half buried is kept", (0, 0) in walk.regions({0: (covered, {0: []}, {}, {0}, {0: 64 * 64 // 2})}),
      True)

# --- The block -------------------------------------------------------------------------------------
def blocked(rects, links):
    """Rectangles with a region, as kept() leaves them, written and read back."""
    tiles = {0: ([rect + [1] for rect in rects], links)}
    text = walk.block(tiles[0][0], links, 0, tiles)
    return decode(zlib.decompress(base64.b64decode(text), -15))[0]


rects, owner, columns, links, _ = shore
data = blocked(rects, links)
check("a block: its format, surfaces, rectangles, openings, drops", (data[0], len(data), data[4]), (walk.FORMAT, 5, []))
check("each rectangle five numbers", len(data[2]), 5 * len(rects))
check("the surfaces add up to the rectangles", sum(data[1][0::3]), len(rects))
written = []
at = 0
while at < len(data[3]):
    count = data[3][at]
    written.append(data[3][at + 1:at + 1 + count])
    at += 1 + count
check("an entry of openings per rectangle", len(written), len(rects))
inside = sum(1 for number, list_ in links.items() for link in list_ if rects[link[3]][6] == rects[number][6])
check("openings within a surface are left to the game", sum(len(w) for w in written) < inside, True)
check("openings between land and water are written", sum(1 for w in written if w), len({n for n, l in links.items()
      for link in l if rects[n][5] != rects[link[3]][5] and link[0] in (0, 3)}))


def read(data):
    """A block's openings on its tile as the game reads them (Walk.lua's Read): {rectangle: {(where, neighbour)}}, each
    written on the tile with its way back."""
    opens, at = {}, 0
    for rect in range(len(data[2]) // 5):
        stop = at + 1 + data[3][at]
        at += 1
        while at < stop:
            value = data[3][at]
            target = data[3][at + 3] if value < 0 else value
            at += 4 if value < 0 else 1
            opens.setdefault(rect, set()).add((target % 5, target // 5))
            if target % 5 == 0:
                opens.setdefault(target // 5, set()).add((0, rect))
    return opens


# --- Openings both ways ----------------------------------------------------------------------------
# A deck 3 yards over the ground (row 0, four samples), a floor a yard over the ground south of them (row 1): from it
# both the ground and the deck to the north are one way. Only the opening from the south one is written (block), so
# the deck's must be found from there too, not only the ground's (the lower, first of the two).
rects = [[0, 0, 4, 1, 52, BUILT, 0], [0, 0, 4, 1, 40, LAND, 1], [0, 1, 4, 1, 44, LAND, 2]]
columns = [[[] for _ in range(SIDE)] for _ in range(SIDE)]
owner = {}
for column in range(4):
    columns[0][column] = [(10.0, LAND, True), (13.0, BUILT, True)]
    columns[1][column] = [(11.0, LAND, True)]
    owner[(0, column, 0)], owner[(0, column, 1)], owner[(1, column, 0)] = 1, 0, 2
links = walk.openings(rects, owner, columns, {})
check("two floors in one sample beside a floor: the opening found from each of them, and both ways",
      (links[0], links[1], links[2]), ([[2, 0, 3, 2]], [[2, 0, 3, 2]], [[0, 0, 3, 0], [0, 0, 3, 1]]))
check("so as the game reads the block, the deck keeps its way to the floor beside it",
      read(blocked(rects, links)).get(0), {(0, 2)})
# Into the next tile alike: a floor at the east edge of a tile, the ground and a deck over it at the same place on the
# west edge of the next; each tile takes the first floor one way with its own.
tiles = {middle: ([[255, 5, 1, 1, 44, LAND, 0]], {0: []}, {1: [(5, 11.0, 0, ())]}),
         middle + 1: ([[0, 5, 1, 1, 40, LAND, 0], [0, 5, 1, 1, 52, BUILT, 1]], {0: [], 1: []},
                      {3: [(5, 10.0, 0, ()), (5, 13.0, 1, ())]})}
walk.across(tiles)
check("into the next tile, two floors at one place beside a floor: the opening both ways from each",
      (tiles[middle][1][0], tiles[middle + 1][1][0], tiles[middle + 1][1][1]),
      ([[1, 5, 5, 2 * 65536], [1, 5, 5, 2 * 65536 + 1]], [[3, 5, 5, 4 * 65536]], [[3, 5, 5, 4 * 65536]]))
check("an opening's runs on one side into one neighbour joined where they meet or overlap",
      walk.merged([[2, 4, 6, 9], [0, 1, 1, 3], [2, 0, 3, 9], [2, 5, 8, 9], [2, 10, 11, 9], [2, 2, 2, 7]]),
      [[0, 1, 1, 3], [2, 0, 8, 9], [2, 2, 2, 7], [2, 10, 11, 9]])
check("off a deck onto the ground beside it, not onto the ground under its next sample (through the deck)",
      (walk.through([10.0, 12.5], [10.0], 12.5, 10.0), walk.through([10.0, 12.5], [10.0, 12.5], 12.5, 10.0)),
      (False, True))
check("nor from a stair's step onto the ground under the next step",
      walk.through([10.0, 11.0], [10.0, 12.0], 11.0, 10.0), True)
check("the ground going on under a low roof is one way with itself",
      walk.through([10.0, 12.1], [10.3, 12.4], 10.0, 10.3), False)
# A deck 2.5 yards over the ground (columns 4 to 7 of rows 0 to 7), the ground going on under it. The ground's
# rectangles end where the deck begins, so each opening lies on the sides of both its rectangles, as the game reads it
# from either (Walk.lua adds the other way on the neighbour's facing side) and a line pulled through it keeps to both.
alone, found, specks, built = ground()
for row in range(8):
    for column in range(4, 8):
        found[(row, column)] = [(10.0, LAND, True), (12.5, BUILT, True)]
        built[row, column] = True
rects, owner, columns, links, _ = cut(alone, found, specks, built)
deck, under = owner[(0, 4, 1)], owner[(0, 4, 0)]
check("a deck beginning over the ground: the ground's rectangle beside it ends where the deck begins",
      rects[owner[(0, 3, 0)]][0] + rects[owner[(0, 3, 0)]][2], 4)
check("every opening between rectangles that meet along its side",
      all(walk.meets(rects[n], rects[t], side) for n, runs in links.items() for side, _, _, t in runs), True)
places = {(n, side, p, t) for n, runs in links.items() for side, first, last, t in runs for p in range(first, last + 1)}
check("each with its way back on the neighbour's facing side",
      all((t, (side + 2) % 4, p, n) in places for n, side, p, t in places), True)
check("from the deck onto the ground beside it on its three sides, not under it",
      sorted({side for side, _, _, t in links[deck] if rects[t][5] == LAND}), [1, 2, 3])
check("and the ground under it leads onto it nowhere", deck in {t for *_, t in links[under]}, False)
# A hall 2.5 yards over the ground there, walled round from 12 to 15 yards (its door a wall in the walking data), the
# ground going on under it and its walls: only a way through its floor reaches it. The tile keeps one (bridges).
walls = {}
for row in range(8):
    walls[(row, 4, 3)] = walls[(row, 7, 1)] = [(12.0, 15.0)]
for column in range(4, 8):
    walls[(7, column, 2)] = [(12.0, 15.0)]
rects, owner, columns = walk.rectangles(alone, found, specks, built, walls)
links = walk.openings(rects, owner, columns, {}, walls)
check("a hall walled round, the ground going on under it: no opening onto it",
      any(rects[t][5] == LAND for *_, t in links[owner[(3, 5, 1)]]), False)
check("so one way through its floor is kept, each way round", len(walk.bridges(rects, owner, columns, links, walls)), 2)
rects, owner, columns, links, _ = walk.plan(alone, found, specks, built, walls)
places = {(n, side, p, t) for n, runs in links.items() for side, first, last, t in runs for p in range(first, last + 1)}
check("the hall and the ground under it then one opening apart",
      sum(1 for n, _, _, t in places if rects[n][5] == BUILT and rects[t][5] == LAND), 1)
check("it too on both rectangles' sides, both ways", all(
    walk.meets(rects[n], rects[t], side) and (t, (side + 2) % 4, p, n) in places for n, side, p, t in places), True)

# --- Drops -----------------------------------------------------------------------------------------
def fallen(alone, found, specks, built, level, spans=None, walls=None, hole=None):
    """A tile's rectangles and what its drops are found from (drops' here)."""
    rects, owner, columns = walk.rectangles(alone, found, specks, built, walls)
    hole = np.zeros((SIDE, SIDE), bool) if hole is None else hole
    return rects, owner, (columns, owner, spans or {}, walls or {}, hole, level)


def heights(found):
    return sorted({round(height, 1) for list_ in found.values() for *_, height in list_})


# A cliff: the east half 20 yards higher, upright. Off its edge westward onto the ground at its foot; never up it.
alone, found, specks, built = ground()
alone[:, 128:] = 30.0
rects, owner, here = fallen(alone, found, specks, built, alone.copy())
falls, pending = walk.drops(here, owner)
check("off a cliff: a drop from each of its edge's samples, onto the ground at its foot",
      (sum(len(list_) for list_ in falls.values()), heights(falls)), (SIDE, [20.0]))
check("only off its top, westward", {(rects[number][0], side) for number, list_ in falls.items() for side, *_ in list_},
      {(128, 3)})
check("and each landing beside it", {rects[target][0] + rects[target][2] for list_ in falls.values()
                                    for _, _, target, _ in list_}, {128})
check("the ways off the tile's edges wait for the next tile's samples", len(pending) > 0, True)
joined = walk.runs(falls[owner[(0, 128, 0)]])
check("a rectangle's drops into one rectangle side by side joined, the height in whole yards",
      joined, [[3, 0, walk.WIDEST - 1, owner[(0, 127, 0)], 20]])
check("heights within BAND joined, the greatest kept; past it apart",
      (walk.runs([(1, 5, 9, 20.2), (1, 6, 9, 23.9), (1, 7, 9, 24.1)]), walk.runs([(1, 5, 9, 20.0), (1, 6, 9, 30.0)])),
      ([[1, 5, 7, 9, 25]], [[1, 5, 5, 9, 20], [1, 6, 6, 9, 30]]))
_, flat_owner, flat_here = fallen(*ground(), np.full((SIDE, SIDE), 10.0))
check("a flat tile has none", walk.drops(flat_here, flat_owner)[0], {})

# A mountainside too steep to walk (columns 128 to 135) between a plateau 30 yards high in the west and a field 10
# yards high in the east: one slides down it.
alone, found, specks, built = ground()
level = np.full((SIDE, SIDE), 10.0)
level[:, :128] = 30.0
for column in range(128, 136):
    level[:, column] = 30.0 - (column - 127) * 2.4
alone[:, :128] = 30.0
alone[:, 128:136] = np.nan
specks[:, 128:136] = level[:, 128:136]
rects, owner, here = fallen(alone, found, specks, built, level)
falls, _ = walk.drops(here, owner)
check("down a mountainside too steep to walk: over its steep samples onto the field at its foot",
      (sum(len(list_) for list_ in falls.values()), heights(falls),
       {rects[target][0] for list_ in falls.values() for _, _, target, _ in list_}), (SIDE, [20.0], {136}))
rising = level.copy()
rising[:, 130] = 31.0
def count(spans=None, walls=None, hole=None, level_=None):
    """How many drops the mountainside gives with something on it."""
    hole = np.zeros((SIDE, SIDE), bool) if hole is None else hole
    found_, _ = walk.drops((here[0], owner, spans or {}, walls or {}, hole, level if level_ is None else level_), owner)
    return sum(len(list_) for list_ in found_.values())


ridge = np.zeros((SIDE, SIDE), bool)
ridge[5, 131] = True
check("not where the ground rises on the way (a ridge), over a hole or something built (a tree, a fence)",
      (count(level_=rising), count(hole=ridge), count(spans={(5, 131): [(15.0, 16.0, False)]})), (0, SIDE - 1, SIDE - 1))
check("nor with a roof over the landing", count(spans={(5, 136): [(20.0, 21.0, False)]}), SIDE - 1)
check("nor past a railing at the edge (a wall rising over the floor), nor through a wall into the landing; a wall "
      "under the edge is the cliff's face", [count(walls=walls_) for walls_ in (
          {(5, 127, 1): [(29.0, 31.0)]}, {(5, 136, 3): [(9.0, 13.0)]}, {(5, 127, 1): [(25.0, 29.5)]})],
      [SIDE - 1, SIDE - 1, SIDE])
high = level.copy()
high[:, :128] = 10.0 + walk.FALL + 1
alone_high = alone.copy()
alone_high[:, :128] = 10.0 + walk.FALL + 1
_, high_owner, high_here = fallen(alone_high, found, specks, built, high)
check("nor a fall higher than FALL", walk.drops(high_here, high_owner)[0], {})
wide = np.full((SIDE, SIDE), 10.0)
wide[:, :100] = 80.0
alone_wide, found_wide, specks_wide, built_wide = ground()
alone_wide[:, :100] = 80.0
alone_wide[:, 100:100 + walk.RUN + 1] = np.nan
for column in range(100, 100 + walk.RUN + 1):
    wide[:, column] = 80.0 - (column - 99) * 2.5
specks_wide[:, 100:100 + walk.RUN + 1] = wide[:, 100:100 + walk.RUN + 1]
_, wide_owner, wide_here = fallen(alone_wide, found_wide, specks_wide, built_wide, wide)
check("nor one crossing more than RUN samples", walk.drops(wide_here, wide_owner)[0], {})
# A balcony 8 yards over the ground (columns 4 to 7 of rows 0 to 7, a building's floor), the ground going on under it:
# off its edges onto the ground beside it.
alone, found, specks, built = ground()
for row in range(8):
    for column in range(4, 8):
        found[(row, column)] = [(10.0, LAND, True), (18.0, BUILT, True)]
        built[row, column] = True
rects, owner, here = fallen(alone, found, specks, built, np.full((SIDE, SIDE), 10.0))
falls, _ = walk.drops(here, owner)
check("off a balcony onto the ground beside it, on its three open sides",
      (sorted({side for list_ in falls.values() for side, *_ in list_}), heights(falls)), ([1, 2, 3], [8.0]))

# Across a tile's edge: a plateau 30 yards high at the east edge of one tile, the next tile's ground falling away from
# its west edge (columns 0 to 3) to a field 10 yards high.
alone, found, specks, built = ground()
alone[:, :] = 30.0
west_rects, west_owner, west_here = fallen(alone, found, specks, built, alone.copy())
falls_west, pending_west = walk.drops(west_here, west_owner)
alone, found, specks, built = ground()
level = np.full((SIDE, SIDE), 10.0)
for column in range(4):
    level[:, column] = 30.0 - (column + 1) * 4.0
alone[:, :4] = np.nan
specks[:, :4] = level[:, :4]
east_rects, east_owner, east_here = fallen(alone, found, specks, built, level)
falls_east, pending_east = walk.drops(east_here, east_owner)
tiles = {middle: (west_rects, {}, {}, set(), {}, falls_west, pending_west, walk.strips(west_here)),
         middle + 1: (east_rects, {}, {}, set(), {}, falls_east, pending_east, walk.strips(east_here))}
walk.across_drops(tiles)
crossing = [(side, target // 65536, east_rects[target % 65536][0], round(height, 1))
            for list_ in falls_west.values() for side, _, target, height in list_]
check("across a tile's edge: off the plateau over the next tile's steep samples onto its field",
      (len(crossing), set(crossing)), (SIDE, {(1, 2, 4, 20.0)}))

# Kept into a rectangle of its own region only (regions stay two-way), numbered anew, joined; in the block, one way.
rects = [[0, 0, 64, 64, 120, LAND, 0], [64, 0, 64, 64, 40, LAND, 1], [128, 0, 64, 64, 40, LAND, 2]]
links = {0: [], 1: [], 2: []}
falls = {0: [(1, row, 1, 20.0) for row in range(64)], 1: [(1, row, 2, 0.0) for row in range(3)]}
falls[2] = [(3, row, 0, 20.0) for row in range(64)]
region_of = {(0, 0): 1, (0, 1): 1, (0, 2): 2}
kept_tiles = walk.kept({0: (rects, links, {}, set(), {}, falls, [])}, region_of)
check("a drop kept into a rectangle of its own region, joined; none into another region",
      kept_tiles[0][2], {0: [[1, 0, 63, 1, 20]]})
data = decode(zlib.decompress(base64.b64decode(walk.block(kept_tiles[0][0], kept_tiles[0][1], 0, kept_tiles,
                                                            kept_tiles[0][2])), -15))[0]
check("the block's drops: off which rectangle, its side, its first and last sample, onto which (index x 5 + where), "
      "its height", data[4], [0, 1, 0, 63, 5, 20])

# --- Regions ---------------------------------------------------------------------------------------
small = [[0, 0, 4, 4, 40, LAND, 0], [10, 10, 64, 64, 40, LAND, 1]]
tiles = {0: (small, {0: [], 1: []}, {})}
regions = walk.regions(tiles)
check("a region smaller than SMALLEST is left out", (0, 0) in regions, False)
check("a large one is kept", (0, 1) in regions, True)
kept = walk.kept(tiles, regions)
check("its rectangles numbered anew", len(kept[0][0]), 1)
large = [[10, 10, 64, 64, 40, LAND, 0]]
isle = 2991 * 4096 + 32 * 64 + 32  # a tile of another map (Zephras Isle): its region numbered after the continent's
later_first = {isle: (large, {0: []}, {}), 0: (large, {0: []}, {})}
check("regions numbered in the order of the tiles' keys, not as the tiles were read",
      walk.regions(later_first), {(0, 0): 1, (isle, 0): 2})

# A lift's landing: the region it lands on is kept, however small (Freewind Post's mesa).
check("a small region a lift lands on is kept", (0, 0) in walk.regions(tiles, {(0, 0)}), True)
corner = walk.HALF - 2 * walk.SAMPLE  # the middle of the small rectangle, in the world's yards (tile 0 lies at the corner)
check("a lift's end lands on the floor nearest it at its height",
      walk.landings(tiles, [(0, corner, corner, 10.5), (0, corner, corner, 40.0), (0, 0.0, 0.0, 10.0)]), {(0, 0)})
# The Undercity's: a roof right over the car's top (6.5 yards up), the floor one gets off on 8 yards beside it.
roofed = {0: ([[0, 0, 4, 4, 4 * 16, LAND, 0], [6, 0, 4, 4, 4 * 10, LAND, 1]], {0: [], 1: []}, {})}
check("one gets off level with the car, beside its shaft, not onto the roof over it",
      walk.landings(roofed, [(0, corner, corner, 9.5)]), {(0, 1)})
with tempfile.TemporaryDirectory() as folder:
    master = Path(folder) / "Travel.jsonl"
    master.write_text('{"key":1,"kind":"flight","path":[{"x":1,"y":2,"map":0}]}\n'
                      '{"key":1100001,"kind":"lift","path":[{"x":1,"y":2,"map":1,"z":3},{"x":1,"y":2,"z":9}]}\n'
                      '{"key":1200702,"kind":"portal","path":[{"x":4,"y":5,"map":0,"z":6},{"x":7,"y":8,"z":90}]}\n')
    check("the lifts' and the portals' ends from the master's set Travel, a portal's trigger first", walk.ends(master),
          [(1, 1, 2, 3), (1, 1, 2, 9), (0, 4, 5, 6), (0, 7, 8, 90)])
# The Wizard's Sanctum: a portal from a cellar to a tower's top, each room small and with no sky over it.
top = walk.HALF - 30 * walk.SAMPLE
sanctum = {0: ([[0, 0, 4, 4, 4 * 30, BUILT, 0], [28, 28, 4, 4, 4 * 148, BUILT, 1], [60, 60, 4, 4, 4 * 70, BUILT, 2]],
               {0: [], 1: [], 2: []}, {}, set())}
check("the rooms a portal's two ends lie in are kept however small, a room no way leads to is not",
      sorted(walk.regions(sanctum, walk.landings(sanctum, [(0, corner, corner, 30.5), (0, top, top, 148.6)]))),
      [(0, 0), (0, 1)])

# --- The open sky around an isle that floats (dev/tools/terrain-art) --------------------------------
art = walk.ART
with tempfile.TemporaryDirectory() as folder:
    textures = Path(folder)
    image = art.Image
    west = np.full((512, 512, 3), 90, np.uint8)
    west[:, :200] = 0                          # nothing drawn: the void, out to the map's edge in the west
    east = np.full((512, 512, 3), 90, np.uint8)
    east[200:260, 200:260] = 0                 # a dark place within the land
    image.fromarray(west).save(textures / "1.blp", "PNG")  # read by content: Pillow takes a PNG under that name
    image.fromarray(east).save(textures / "2.blp", "PNG")
    found = {(2991, 10, 10): 1, (2991, 10, 11): 2}
    sky = art.sky(found, textures)
    part = sky.get((2991, 10, 10))
    check("the void joined to the map's edge is sky", part is not None and bool(part[:, :100].all()), True)
    check("the land beside it is none", part is not None and bool(part[:, 100:].any()), False)
    check("a dark place within the land is no sky", (2991, 10, 11) in sky, False)

# --- A flight's path made short ---------------------------------------------------------------------
line = [(0.0, 0.0), (10.0, 0.5), (20.0, 0.0), (30.0, 40.0)]
check("points on a straight run left out, a bend kept", travel.simplified(line), [(0.0, 0.0), (20.0, 0.0), (30.0, 40.0)])

# --- A boat's way: its docks, its leaps, its points made short; replaced by a newer way --------------------
def node(index, world, x, y, z=0.0, flags=0, delay=0):
    return {"NodeIndex": str(index), "ContinentID": str(world), "Loc[0]": str(x), "Loc[1]": str(y), "Loc[2]": str(z),
            "Flags": str(flags), "Delay": str(delay)}


ship = [node(0, 0, 0, 0), node(1, 0, 100, 0), node(2, 0, 200, 0, flags=travel.STOP, delay=60), node(3, 0, 300, 0),
        node(4, 0, 400, 0, flags=travel.TELEPORT), node(5, 0, 5000, 0), node(6, 1, 9000, 50),
        node(7, 1, 9100, 50, z=2.5, flags=travel.STOP, delay=30), node(8, 1, 9100, 60, flags=travel.STOP, delay=30)]
fields = travel.transport(ship)
path = fields["path"]
check("a way near the sea's level is a boat's", fields["kind"], "boat")
check("its points: a straight run made short, the docks and both sides of each leap kept",
      [(p["x"], p["y"]) for p in path], [(0.0, 0.0), (200.0, 0.0), (400.0, 0.0), (5000.0, 0.0), (9000.0, 50.0),
                                         (9100.0, 50.0), (9100.0, 60.0)])
check("the first point names its map, the docks their stays",
      [(p.get("map"), p.get("stay"), p.get("jump")) for p in path],
      [(0, None, None), (None, 60, None), (None, None, None), (None, None, True), (1, None, True), (None, 30, None),
       (None, 30, None)])
check("its length: the yards it moves, its leaps not counted", fields["length"], 510.0)
check("stops a few yards apart are one dock", travel.docks(ship), [(0, 200.0, 0.0, 0.0), (1, 9100.0, 50.0, 2.5)])
check("without a placer no docks on the maps", "docks" in fields, False)


class Placer:
    """map-data's Placer made up: world 0 lies on zone map 10 (x yards to the percent), world 1 on none."""

    def place(self, world, x, y, z=None):
        return [10, round(x / 10, 1), round(y / 10, 1)] if world == 0 else None

    def area(self, world, x, y, z=None):
        return 7 if world == 0 else 9


placed = travel.transport(ship + [node(9, 0, 300, 0, flags=travel.STOP, delay=60)], Placer())
check("its docks on the zone maps, one per dock in the order it comes to them, a dock on no map left out with its area",
      (placed["docks"], placed["dockAreas"]), ([[10, 20.0, 0.0], [10, 30.0, 0.0]], [7, 7]))
check("a way high over the sea is a zeppelin's",
      travel.transport([node(0, 0, 0, 0, z=60), node(1, 0, 100, 0, z=80)])["kind"], "zeppelin")
places = {10: [(0, 0.0, 0.0), (1, 500.0, 0.0)], 11: [(0, 5.0, 0.0), (0, 900.0, 0.0), (1, 505.0, 0.0)],
          12: [(0, 0.0, 0.0), (1, 2000.0, 0.0)], 13: [(0, 0.0, 0.0), (1, 2000.0, 0.0)]}
check("a way all of whose docks a way with more docks has is replaced; of two alike, the older",
      travel.replaced(places), {10, 12})

# --- A lift's car: its motion, its ends, its key kept for the same place ------------------------------------
def frame(ms, z, x=0.0, y=0.0):
    return {"TimeIndex": str(ms), "Pos[0]": str(x), "Pos[1]": str(y), "Pos[2]": str(z)}


# At the top 5 seconds, down 60 yards in 10, at the bottom 5, up in 10; another starting halfway down, stopping at the
# bottom first (its ride down across the round's end); a door rising 5 yards; a car that stops halfway too; one moving
# sideways.
top = [frame(0, 0), frame(5000, 0), frame(6000, -2), frame(14000, -58), frame(15000, -60), frame(20000, -60),
       frame(30000, 0)]
halfway = [frame(0, 0), frame(1800, -55), frame(6800, -55), frame(10300, 41), frame(15200, 41), frame(16700, 0)]
check("a lift's motion: its lowest and highest, its slower ride, its round", travel.lift(top), (-60.0, 0.0, 10.0, 30.0))
check("a car first between its ends: its rides across the round's end", travel.lift(halfway), (-55.0, 41.0, 3.5, 16.7))
check("a door's motion, rising less than a lift: none", travel.lift([frame(0, 0), frame(1000, 5), frame(5000, 5),
                                                                   frame(6000, 0)]), None)
check("a car that stands between its ends too: none",
      travel.lift([frame(0, 0), frame(5000, -30), frame(8000, -30), frame(12000, -60), frame(15000, -60), frame(20000, 0)]),
      None)
check("a car that moves sideways: none", travel.lift([frame(0, 0), frame(5000, -60, x=20.0), frame(10000, 0)]), None)


class Places:
    def place(self, world, x, y, z=None):
        return [1456, round(x / 100, 1), round(y / 100, 1)]


cars = [(4170, 1, -1286.24, 189.72, 130.08), (4171, 1, -1308.38, 185.29, 68.5858), (9, 1, 0.0, 0.0, 0.0)]
lines, left = travel.lifts(cars, {4170: top, 4171: halfway, 9: [frame(0, 0), frame(1000, 2), frame(2000, 0)]},
                           {travel.LIFTS + 3: (1, -1308.0, 185.0)}, Places())
fields = dict(lines)
check("each lift its own number: the master's at its place kept, a new one after the highest",
      [key for key, _ in lines], [travel.LIFTS + 4, travel.LIFTS + 3])
check("its ends in the world's yards, the lower first with its map, each with its height; its ride and round",
      (fields[travel.LIFTS + 4]["path"], fields[travel.LIFTS + 4]["time"], fields[travel.LIFTS + 4]["wait"],
       fields[travel.LIFTS + 4]["length"]),
      ([{"x": -1286.24, "y": 189.72, "map": 1, "z": 70.08}, {"x": -1286.24, "y": 189.72, "z": 130.08}], 10.0, 30.0, 60.0))
check("its ends on the zone maps, for the map's pins", (fields[travel.LIFTS + 4]["from"], fields[travel.LIFTS + 4]["to"]),
      ([1456, -12.9, 1.9], [1456, -12.9, 1.9]))
check("a car the client does not move as a lift left out, and why", left, [(9, "the client does not move it as a lift")])

# --- A way's side: its towns', by the flight masters near its docks ---------------------------------------
def taxi(world, x, y, flags):
    return {"ContinentID": str(world), "Pos[0]": str(x), "Pos[1]": str(y), "Flags": str(flags)}


nodes = {1: taxi(0, 0, 0, travel.ALLIANCE), 2: taxi(0, 5000, 0, travel.ALLIANCE | travel.HORDE),
         3: taxi(1, 0, 0, travel.HORDE), 4: taxi(1, 5000, 0, 0)}
check("a way between a side's town and a port of both: that side's",
      travel.side([(0, 300, 0, 0), (0, 5100, 0, 0)], nodes), "alliance")
check("between towns of both sides, or with no flight master near (one of no side's does not count): none",
      (travel.side([(0, 0, 0, 0), (1, 0, 0, 0)], nodes), travel.side([(1, 5000, 0, 0), (0, 3000, 0, 0)], nodes)),
      (None, None))
check("a dock farther than DOCKSIDE yards from the flight master: no town of its side",
      travel.side([(1, travel.DOCKSIDE + 10, 0, 0)], nodes), None)
check("a transport's side among its fields (its first dock by an Alliance flight master)",
      travel.transport(ship, None, nodes).get("side"), "alliance")

# --- A portal: the client's trigger, where the batch says it brings one ------------------------------------
triggers = {542: {"ContinentID": "1", "Pos[0]": "8799.41", "Pos[1]": "969.787", "Pos[2]": "30.2409"},
            7: {"ContinentID": "0", "Pos[0]": "1", "Pos[1]": "2", "Pos[2]": "3"}}
lines, left = travel.portals([(542, 1, 9946.25, 2612.97, 1316.49), (7, 1, 0.0, 0.0, 0.0), (8, 1, 0.0, 0.0, 0.0)],
                             triggers, Places())
fields = dict(lines)
check("a portal's number: PORTALS and the trigger's", [key for key, _ in lines], [travel.PORTALS + 542])
check("its two ends in the world's yards, the trigger's own first with its map, each with its height; the yards apart",
      (fields[travel.PORTALS + 542]["path"], fields[travel.PORTALS + 542]["length"]),
      ([{"x": 8799.41, "y": 969.787, "map": 1, "z": 30.2409}, {"x": 9946.25, "y": 2612.97, "z": 1316.49}], 2381.1))
check("its ends on the zone maps, for the map's pins", (fields[travel.PORTALS + 542]["from"], fields[travel.PORTALS + 542]["to"]),
      ([1456, 88.0, 9.7], [1456, 99.5, 26.1]))
check("a trigger the client has on another continent, or not at all, left out, and why", left,
      [(7, "the client has it on another continent"), (8, "the client has no such trigger")])

# --- A teleport: a class's spell to a place the server holds, or an item's; where a batch says it brings one ------------
races = {0: "alliance", 1: "horde", 2: "alliance", 4: "horde", 23: None}
check("a race mask's side: one side's races alone, else none (a race of neither, both sides, every race)",
      [travel.race_side(0b101, 0, races), travel.race_side(0b10010, 0, races), travel.race_side(0b111, 0, races),
       travel.race_side(1 << 23 | 1, 0, races), travel.race_side(0, 0, races), travel.race_side(-1, 0, races)],
      ["alliance", "horde", None, None, None, None])
with tempfile.TemporaryDirectory() as folder:
    def write(name, header, rows):
        with open(Path(folder) / f"{name}.csv", "w", encoding="utf-8") as out:
            out.write(",".join(header) + "\n" + "".join(",".join(map(str, row)) + "\n" for row in rows))

    write("SpellName", ["ID", "Name_lang"], [(3561, "Teleport: Stormwind"), (556, "Astral Recall"),
                                              (23453, "Gnomish Transporter"), (777, "Fireball")])
    write("SpellEffect", ["SpellID", "Effect", "ImplicitTarget[1]"], [(3561, travel.TELEPORT_UNITS, travel.AT_PLACE),
                                                                    (556, travel.TELEPORT_UNITS, 9), (23453, 3, 0)])
    write("ChrRaces", ["ID", "PlayableRaceBit", "Alliance"], [(1, 0, 0), (2, 1, 1), (3, 2, 0), (12, -1, 2)])
    write("SkillLineAbility", ["Spell", "ClassMask", "RaceMasks[0]", "RaceMasks[1]"],
          [(3561, 128, 0b101, 0), (556, 64, 0, 0), (777, 128, 0, 0)])
    write("ItemEffect", ["ID", "SpellID"], [(1, 23453), (2, 23453), (3, 777)])
    write("ItemXItemEffect", ["ItemEffectID", "ItemID"], [(1, 260819), (2, 999999), (1, 18986), (3, 5)])
    write("ItemSparse", ["ID"], [(18986,), (260819,), (5,)])
    write("SpellReagents", ["SpellID", "Reagent[0]"], [(3561, 17031), (23453, 0)])
    lines, left = travel.teleports(Path(folder), {3561: (0, -9003.46, 870.031, 29.6206), 777: (1, 0.0, 0.0, 0.0)})
check("the teleports: a class's spell to a place the server holds (not one home, Astral Recall's), and an item's "
      "of ITEM_TELEPORTS; each its number, TELEPORTS and the spell's", [key for key, _ in lines],
      [travel.TELEPORTS + 3561, travel.TELEPORTS + 23453])
fields = dict(lines)
check("a class's: its name, spell, side (its races'), reagent, and where the batch says it brings one",
      fields[travel.TELEPORTS + 3561], {"kind": "teleport", "spell": 3561, "name": "Teleport: Stormwind", "side": "alliance",
                                        "reagent": 17031, "path": [{"x": -9003.46, "y": 870.031, "map": 0, "z": 29.6206}]})
check("an item's: the items of the client that cast it, no side, no reagent, nowhere known yet",
      fields[travel.TELEPORTS + 23453], {"kind": "teleport", "spell": 23453, "name": "Gnomish Transporter",
                                         "items": [18986, 260819]})
check("a place for a spell the client has as no teleport: left out, and why", left, [(777, "the client has it as no teleport")])

# --- The staging file, the options -----------------------------------------------------------------


def staged(key, text):
    """A staging line as the tool writes it: a tile's key, its map and its block."""
    return {"set": "Walking", "key": key, "game": "forever", "build": walk.BUILD, "src": "game",
            "fields": {"map": key // (walk.GRID * walk.GRID), "links": [], "block": text}}


with tempfile.TemporaryDirectory() as folder:
    staging = Path(folder) / "walking.jsonl"
    walk.save(staging, [staged(100, "a"), staged(4096 + 7, "b"), staged(4096 + 9, "c")])
    held = walk.save(staging, [staged(101, "d")], maps={0})
    rows = [json.loads(text) for text in staging.read_text().splitlines()]
    check("staging: a run of one map keeps the file's lines of the other maps, its own written anew, by key",
          ([(row["key"], row["fields"]["block"]) for row in rows], held), ([(101, "d"), (4103, "b"), (4105, "c")], 3))
    walk.save(staging, [staged(5, "e")])
    check("staging: a run of every map holds the file alone", [json.loads(t)["key"] for t in staging.read_text().splitlines()], [5])
    check("staging: written through a temp file beside it, none left", sorted(p.name for p in Path(folder).iterdir()), ["walking.jsonl"])
given = walk.options(["files", "tables"])
check("options: the folders, three workers unless asked (a full run with ten reached the app's memory cap), MEMORY GB",
      (given["folder"], given["tables"], given["processes"], given["memory"], walk.PROCESSES),
      (Path("files"), Path("tables"), 3, walk.MEMORY, 3))
given = walk.options(["files", "tables", "--processes", "5", "--memory", "10", "--maps", "1,2991", "--only", "4100"])
check("options: --processes, --memory, --maps and --only read",
      (given["processes"], given["memory"], given["maps"], given["only"]), (5, 10.0, {1, 2991}, {4100}))
check("options: not the usage's", walk.options(["files"]), None)

# --- The coarse layer (dev/tools/walk-gates) ----------------------------------------------------------
gates = load("walk_gates", ROOT / "dev" / "tools" / "walk-gates")


def layer(blocks):
    """Made-up tiles' blocks (as the set holds them) read, joined and parted as the tool does: {key: tile}, borders."""
    texts = {key: gates.pack(block) for key, block in blocks.items()}
    tiles = {key: dict(gates.read(text), key=key) for key, text in texts.items()}
    gates.resolve(tiles)
    for key, tile in tiles.items():
        tile["part"] = gates.parts(tile, key)
    borders = {(key, side): gates.border(tiles, key, side) for key in tiles for side in (1, 2)}
    return texts, tiles, borders


def made(texts, tiles, borders, key):
    """A tile's field as the tool makes it, read back: [format, check, rects, north, east, south, west, costs, ways
    down]."""
    job = (key, {name: tiles[key][name] for name in ("rects", "kind", "opens", "drops", "part", "key")},
           gates.sides(tiles, borders, key), gates.check_of(texts, key))
    return gates.unpack(gates.field(job)[1])


def pair(costs, x, y):
    """The number of the way between the x-th and the y-th gate (x < y) of a tile's one part, and the rider's for it."""
    size = costs[0]
    number = (x - 1) * (2 * size - x) // 2 + (y - x)
    at = 1 + size + size * (size - 1) // 2
    rides = dict(zip(costs[at + 1::2], costs[at + 2::2]))
    return costs[size + number], rides.get(number)


def parts_of(number):
    """A way's number taken apart, as Gates.lua does: land, up, down, swum."""
    return number % 8192, number // 8192 % 1024, number // 2 ** 23 % 1024, number // 2 ** 33


# Four fields in a row (tiles 2592 to 2595, 10 yards high), each open into the next along all its edge; the second cut in
# two by a wall (columns 128 to 143) but at its north end, a door (rows 0 to 15): the halves one surface, the door
# another, joined by the openings written (Navigation's tests have the same tiles).
row = {2592: [2, [1, 1, 20], [0, 0, 256, 256, 40], [1, 2], []],
       2593: [2, [2, 1, 20, 1, 1, 20], [0, 0, 128, 256, 40, 144, 0, 112, 256, 40, 128, 0, 16, 16, 40],
              [5, -2, 0, 15, 10, 4, 1, 2, 4, -2, 0, 15, 5], []],
       2594: [2, [1, 1, 20], [0, 0, 256, 256, 40], [2, 9, 2], []],
       2595: [2, [1, 1, 20], [0, 0, 256, 256, 40], [1, 4], []]}
texts, tiles, borders = layer(row)
check("a tile's parts: its surfaces joined by the openings between them (the halves and the door one)",
      tiles[2593]["part"], [1, 1, 1])
check("a border's gates: where a part meets the next tile's, cut into even pieces of PIECE samples",
      borders[(2592, 1)], [(0, 63, 1, 1), (64, 127, 1, 1), (128, 191, 1, 1), (192, 255, 1, 1)])
check("the same gates on the next tile's west side, with its part",
      gates.sides(tiles, borders, 2593)[3], [(0, 63, 1), (64, 127, 1), (128, 191, 1), (192, 255, 1)])
walled = made(texts, tiles, borders, 2593)
check("a tile's field: its format, check (its block's and its neighbours'), rectangles, gates side by side",
      (walled[0], walled[1], walled[2], walled[3], walled[4][:3], len(walled[6])),
      (gates.FORMAT, gates.check_of(texts, 2593), 3, [], [0, 63, 1], 12))
check("its one part: its eight gates, a way between each two, no rider's", (walled[7][:9], len(walled[7])),
      ([8, 1, 2, 3, 4, 5, 6, 7, 8], 1 + 8 + 28 + 1))
check("along the east half (the first two east gates' middles 64 samples apart): 133 yards",
      parts_of(pair(walled[7], 1, 2)[0]), (133, 0, 0, 0))
check("from the west side to the east by the door, the line pulled through it (258 samples)",
      parts_of(pair(walled[7], 1, 5)[0]), (538, 0, 0, 0))
check("from the south of the west side, the same door", parts_of(pair(walled[7], 4, 8)[0]), (1034, 0, 0, 0))
check("a tile's check: CRC-32 of its block and its neighbours', a missing one empty",
      gates.check_of(texts, 2592), zlib.crc32(("\n".join([texts[2592], "", texts[2593], "", ""]) + "\n").encode()))
# A pond across a tile (columns 100 to 155, rows 16 to 255, the water's surface 10 yards high) and a land bridge north
# of it (rows 0 to 15), fields east and west of the tile: from the west side's second gate to the east side's (rows 64
# to 127), on foot (a yard swum 1.5) the way swims straight across, 117 of its yards; a rider (3) goes round by the
# bridge, 650 yards dry, kept besides.
pond = {2699: [2, [1, 1, 20], [0, 0, 256, 256, 40], [1, 2], []],
        2700: [2, [3, 1, 20, 1, 2, 20], [0, 0, 100, 256, 40, 100, 0, 56, 16, 40, 156, 0, 100, 256, 40, 100, 16, 56, 240, 40],
               [5, -2, 16, 255, 15, 4, 4, -3, 100, 155, 15, 1, 2, 4, -2, 16, 255, 10], []],
        2701: [2, [1, 1, 20], [0, 0, 256, 256, 40], [1, 14], []]}
texts, tiles, borders = layer(pond)
across = made(texts, tiles, borders, 2700)
foot, ride = pair(across[7], 2, 6)
check("a way that swims: its yards on land and swum; the rider's dry way kept besides",
      (parts_of(foot), ride and parts_of(ride)), ((417, 0, 0, 117), (650, 0, 0, 0)))
check("the packed number holds each part in its own room",
      parts_of(gates.number(1803, 354, 332, 872)), (1803, 354, 332, 872))
check("no drop: no way down", (walled[8], across[8]), ([], []))
# A plateau 30 yards high (columns 0 to 127) and a field 10 yards high (columns 136 to 255) across a tile, a
# mountainside too steep to walk between: a drop off the plateau's east side onto the field, 20 yards. Two parts (no
# walk between them on the tile): ways down from each of the west gates (the plateau's) to each of the east ones, none
# back up.
cliff = {2799: [2, [1, 1, 20], [0, 0, 256, 256, 120], [1, 2], []],
         2800: [2, [1, 1, 20, 1, 1, 20], [0, 0, 128, 256, 120, 136, 0, 120, 256, 40], [1, 4, 1, 2],
                [0, 1, 0, 255, 5, 20]],
         2801: [2, [1, 1, 20], [0, 0, 256, 256, 40], [1, 9], []]}
texts, tiles, borders = layer(cliff)
check("a tile's drops read, one way, off the rectangle they leave", tiles[2800]["drops"], [[(1, 0, 255, 1, 20)], []])
down = made(texts, tiles, borders, 2800)
falls = [down[8][at:at + 4] for at in range(0, len(down[8]), 4)]
check("ways down from each of the plateau's gates (the west side's: 5 to 8) to each of the field's (the east's: 1 to "
      "4), none back up", sorted({(a, b) for a, b, *_ in falls}), [(a, b) for a in range(5, 9) for b in range(1, 5)])
check("straight across, down the drop (8 samples across): its yards with the fall's price, 20 yards down, the rider's "
      "the same", (parts_of(falls[0][2]), falls[0][3] == falls[0][2]) if falls else None,
      ((round(256 * gates.SAMPLE + 20 * gates.DROP), 0, 20, 0), True))
check("the parts' own costs as before: the plateau's four gates, the first two 133 yards apart",
      (down[7][:5], parts_of(down[7][5])), ([4, 5, 6, 7, 8], (133, 0, 0, 0)))
# The same, a ramp at the north end (rows 0 to 15, 20 yards high) joining the plateau and the field: one part. A way
# down kept only where it costs less than the walk: from the plateau's south gate to the field's, not from the north
# one's (the ramp's way is shorter than the drop's yards with its fall).
ramp = {2899: [2, [1, 1, 20], [0, 0, 256, 256, 120], [1, 2], []],
        2900: [2, [1, 1, 20, 1, 1, 20, 1, 1, 20], [0, 0, 128, 256, 120, 128, 0, 8, 16, 80, 136, 0, 120, 256, 40],
               [1, 4, 1, 0, 2, 5, 2], [0, 1, 16, 255, 10, 20]],
        2901: [2, [1, 1, 20], [0, 0, 256, 256, 40], [1, 14], []]}
texts, tiles, borders = layer(ramp)
kept_down = {(a, b) for a, b, *_ in (lambda f: [f[at:at + 4] for at in range(0, len(f), 4)])(made(texts, tiles, borders, 2900)[8])}
check("one part: a way down kept where it costs less than the walk, not where the walk is cheaper, never back up",
      ((8, 4) in kept_down, (5, 1) in kept_down, tiles[2900]["part"], all(a > 4 >= b for a, b in kept_down)),
      (True, False, [1, 1, 1], True))
lua = {name: (ROOT / "src" / "Navigation" / f"{name}.lua").read_text(encoding="utf-8") for name in ("Walk", "Search", "Gates")}
check("walk-data's FORMAT is Walk.lua's, walk-gates' Gates.lua's; walk-gates' FALL Walk.FALL, its DROP Search.DROP",
      [re.search(pattern, lua[name]).group(1) for name, pattern in (
          ("Walk", r"Walk\.FORMAT = (\d+)"), ("Gates", r"Gates\.FORMAT = (\d+)"), ("Walk", r"Walk\.FALL = (\d+)"),
          ("Search", r"Search\.DROP = (\d+)"))],
      [str(walk.FORMAT), str(gates.FORMAT), str(gates.FALL), str(gates.DROP)])
# The master's coarse layer made from its blocks as they are: each tile's check its own block's and its neighbours'
# (after the walking data is made anew, dev/tools/walk-gates and the import, too).
newest = {}
for text in (ROOT / "assets" / "data" / "Walking" / "Walking.jsonl").read_text(encoding="utf-8").splitlines():
    line = json.loads(text)
    if line.get("gone"):
        newest.pop(line["key"], None)
    else:
        newest[line["key"]] = dict(newest.get(line["key"], {}), **{k: v for k, v in line.items() if k in ("block", "gates")})
blocks = {key: entry["block"] for key, entry in newest.items() if "block" in entry}
stale = [key for key, entry in newest.items() if "gates" not in entry or "block" not in entry
         or gates.unpack(entry["gates"])[1] != gates.check_of(blocks, key)]
check("the master's coarse layer: every tile's made from its block and its neighbours' as they are", stale[:5], [])

if failed:
    print(f"Walking data: {failed} of {checks} checks failed.")
    sys.exit(1)
print(f"Walking data: all {checks} checks passed.")
