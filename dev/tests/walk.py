#!/usr/bin/env python3
"""Tests of dev/tools/walk-data and dev/tools/travel-data without the game's files: the block's encoding, floors
joined into surfaces and rectangles on made-up ground (flat land, a steep speck, a hole, a cliff, a bridge, water),
buildings and doodads placed as the game places them (turned, tilted; a model's collision, a building's doodad sets,
the object files' placements) and rasterized (a fence, a deck), the openings the game is left to work out and those
written, regions too small to keep and their order, a flight's path made short, a boat's way (its docks, on the zone
maps too, its leaps, which way a newer one replaced) and a lift's car (its motion, its ends and rides, its own number
kept for its place). And dev/tools/terrain-art's open sky around an isle that floats (walk-data reads the terrain with
it). Run by dev/tests/run."""
import base64
import importlib.machinery
import importlib.util
import math
import os
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
check("a block: its format, surfaces, rectangles, openings", (data[0], len(data)), (walk.FORMAT, 4))
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
                      '{"key":1100001,"kind":"lift","path":[{"x":1,"y":2,"map":1,"z":3},{"x":1,"y":2,"z":9}]}\n')
    check("the lifts' ends from the master's set Travel", walk.lifts(master), [(1, 1, 2, 3), (1, 1, 2, 9)])

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

if failed:
    print(f"Walking data: {failed} of {checks} checks failed.")
    sys.exit(1)
print(f"Walking data: all {checks} checks passed.")
