#!/usr/bin/env python3
"""Tests of dev/tools/walk-data and dev/tools/travel-data without the game's files: the block's encoding, floors
joined into surfaces and rectangles on made-up ground (flat land, a steep speck, a hole, a cliff, a bridge, water),
the openings the game is left to work out and those written, regions too small to keep, a flight's path made
short, and a boat's way (its docks, its leaps, which way a newer one replaced). Run by dev/tests/run."""
import base64
import importlib.machinery
import importlib.util
import os
import sys
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
check("stops a few yards apart are one dock", travel.docks(ship), [(0, 200.0, 0.0), (1, 9100.0, 50.0)])
check("a way high over the sea is a zeppelin's",
      travel.transport([node(0, 0, 0, 0, z=60), node(1, 0, 100, 0, z=80)])["kind"], "zeppelin")
places = {10: [(0, 0.0, 0.0), (1, 500.0, 0.0)], 11: [(0, 5.0, 0.0), (0, 900.0, 0.0), (1, 505.0, 0.0)],
          12: [(0, 0.0, 0.0), (1, 2000.0, 0.0)], 13: [(0, 0.0, 0.0), (1, 2000.0, 0.0)]}
check("a way all of whose docks a way with more docks has is replaced; of two alike, the older",
      travel.replaced(places), {10, 12})

if failed:
    print(f"Walking data: {failed} of {checks} checks failed.")
    sys.exit(1)
print(f"Walking data: all {checks} checks passed.")
