#!/usr/bin/env python3
"""Tests of dev/tools/walk-data and dev/tools/travel-data without the game's files: the block's encoding, floors
joined into surfaces and rectangles on made-up ground (flat land, a steep speck, a hole, a cliff, a bridge, water),
the openings the game is left to work out and those written, regions too small to keep and their order, a flight's
path made short, a boat's way (its docks, on the zone maps too, its leaps, which way a newer one replaced) and a
lift's car (its motion, its ends and rides, its own number kept for its place). And
dev/tools/terrain-art's open sky around an isle that floats (walk-data reads the terrain with it). Run by
dev/tests/run."""
import base64
import importlib.machinery
import importlib.util
import math
import os
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
SIDE, LAND, WATER = walk.SIDE, walk.LAND, walk.WATER
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
