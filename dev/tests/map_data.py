#!/usr/bin/env python3
"""Tests of dev/tools/map-data without the game's files, on made-up client tables and terrain: a world position on
the zone map of its terrain's area (also inside a smaller zone's box), in a building turned on its spot (the area
of the part it stands in), on the smallest box where no terrain tells, off every map; the map's percent; Places'
keys kept within half a percent and an entrance's by its instance; the zones' sides and continents; the entrances
of dungeons and raids. Run by dev/tests/run."""
import csv
import importlib.machinery
import importlib.util
import struct
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
loader = importlib.machinery.SourceFileLoader("map_data", str(ROOT / "dev" / "tools" / "map-data"))
md = importlib.util.module_from_spec(importlib.util.spec_from_loader("map_data", loader))
loader.exec_module(md)
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


def write(folder, name, rows):
    with open(folder / f"{name}.csv", "w", encoding="utf-8", newline="") as out:
        writer = csv.DictWriter(out, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def piece(name, data):
    return name[::-1] + struct.pack("<I", len(data)) + data


def assignment(uimap, map_id, area, north, south, west, east):
    row = {"UiMin[0]": 0, "UiMin[1]": 0, "UiMax[0]": 1, "UiMax[1]": 1}
    row.update({f"Region[{i}]": v for i, v in enumerate((south, east, -1e6, north, west, 1e6))})
    row.update(ID=uimap, UiMapID=uimap, OrderIndex=0, MapID=map_id, AreaID=area, WMODoodadPlacementID=0, WMOGroupID=0)
    return row


def world(folder):
    """Two zones on continent 0 (A, and B's smaller box inside A's), two on map 5 without terrain, a zone map the
    world map does not lead to; the terrain's tile (32, 32) all of A's area but one chunk of a city's (the zone
    C), and a building turned by 90 degrees whose part 7 is of the city's area."""
    write(folder, "UiMap", [
        {"Name_lang": "World", "ID": 1, "ParentUiMapID": 0, "Type": 1},
        {"Name_lang": "Land", "ID": 2, "ParentUiMapID": 1, "Type": 2},
        {"Name_lang": "A", "ID": 10, "ParentUiMapID": 2, "Type": 3},
        {"Name_lang": "B", "ID": 20, "ParentUiMapID": 2, "Type": 3},
        {"Name_lang": "C", "ID": 30, "ParentUiMapID": 2, "Type": 3},
        {"Name_lang": "Big isle", "ID": 40, "ParentUiMapID": 1, "Type": 3},
        {"Name_lang": "Small isle", "ID": 50, "ParentUiMapID": 1, "Type": 3},
        {"Name_lang": "Lost", "ID": 60, "ParentUiMapID": 0, "Type": 3},
    ])
    write(folder, "UiMapAssignment", [
        assignment(10, 0, 1, 0, -1000, 0, -1000), assignment(20, 0, 2, -100, -300, -100, -300),
        assignment(30, 0, 3, -400, -600, -400, -600), assignment(40, 5, 4, 100, -100, 100, -100),
        assignment(50, 5, 5, 50, 0, 50, 0), assignment(60, 5, 0, 10, 0, 10, 0),
    ])
    write(folder, "AreaTable", [
        {"ID": 1, "ParentAreaID": 0, "Flags[0]": 0x40, "FactionGroupMask": 2},
        {"ID": 2, "ParentAreaID": 0, "Flags[0]": 0x40, "FactionGroupMask": 0},
        {"ID": 3, "ParentAreaID": 0, "Flags[0]": 0x140, "FactionGroupMask": 4},
        {"ID": 4, "ParentAreaID": 0, "Flags[0]": 0x840, "FactionGroupMask": 0},
        {"ID": 5, "ParentAreaID": 0, "Flags[0]": 0x40, "FactionGroupMask": 6},
        {"ID": 11, "ParentAreaID": 1, "Flags[0]": 0, "FactionGroupMask": 0},
        {"ID": 31, "ParentAreaID": 3, "Flags[0]": 0, "FactionGroupMask": 0},
    ])
    write(folder, "WMOAreaTable", [{"WMOID": 900, "NameSetID": 0, "WMOGroupID": 7, "AreaTableID": 31},
                                   {"WMOID": 900, "NameSetID": 0, "WMOGroupID": 8, "AreaTableID": 0}])
    write(folder, "Map", [
        {"ID": 33, "MapName_lang": "Keep", "InstanceType": 1, "CorpseMapID": 0, "Corpse[0]": -200, "Corpse[1]": -700},
        {"ID": 34, "MapName_lang": "<unused> Keep", "InstanceType": 1, "CorpseMapID": 0, "Corpse[0]": -200, "Corpse[1]": -700},
        {"ID": 35, "MapName_lang": "Hall", "InstanceType": 2, "CorpseMapID": 0, "Corpse[0]": -201, "Corpse[1]": -701},
        {"ID": 36, "MapName_lang": "Nowhere", "InstanceType": 1, "CorpseMapID": 0, "Corpse[0]": 0, "Corpse[1]": 0},
        {"ID": 37, "MapName_lang": "Town", "InstanceType": 0, "CorpseMapID": 0, "Corpse[0]": -200, "Corpse[1]": -700},
    ])
    for part in ("adt", "adt-obj0", "wmo"):
        (folder / part).mkdir()
    key = 32 * md.GRID + 32
    chunks = b""
    for y in range(md.CHUNKS):
        for x in range(md.CHUNKS):
            header = bytearray(128)
            struct.pack_into("<II", header, 4, x, y)
            struct.pack_into("<I", header, 0x34, 31 if (x, y) == (15, 15) else 11)
            chunks += piece(b"MCNK", bytes(header))
    (folder / "adt" / f"{key}.adt").write_bytes(piece(b"MVER", struct.pack("<I", 18)) + chunks)
    # The building at X -100, Y -200, Z 50: its own x runs to the east (-Y), its y to the north (+X).
    px, py, pz = md.HALF + 200, 50.0, md.HALF + 100
    entry = struct.pack("<II3f3f6fHHHH", 4000, 1, px, py, pz, 0, 90, 0, px - 20, py - 10, pz - 20, px + 20, py + 10,
                        pz + 20, 0x8, 0, 0, 0)
    (folder / "adt-obj0" / f"{key}.adt").write_bytes(piece(b"MODF", entry))
    header = bytearray(64)
    struct.pack_into("<I", header, 32, 900)
    (folder / "wmo" / "4000.wmo").write_bytes(piece(b"MOHD", bytes(header)))
    for part, group, box in (("000", 7, (0, 0, 0, 10, 4, 5)), ("001", 8, (-10, -10, -5, 10, 10, 10))):
        group_header = bytearray(68)
        struct.pack_into("<6f", group_header, 12, *box)
        struct.pack_into("<I", group_header, 56, group)
        (folder / "wmo" / f"4000_{part}.wmo").write_bytes(piece(b"MOGP", bytes(group_header)))


def main():
    with tempfile.TemporaryDirectory() as scratch:
        folder = Path(scratch)
        world(folder)
        placer = md.Placer(folder, folder)
        check("on its terrain's zone, inside a smaller box", placer.place(0, -200, -200)[0], 10)
        check("the map's percent", placer.place(0, -250, -750), [10, 75.0, 25.0])
        check("the chunk of another zone's area", placer.place(0, -(md.CHUNK * 15.5), -(md.CHUNK * 15.5))[0], 30)
        check("in the turned building's part", placer.area(0, -98, -205, 51), 31)
        check("beside the part, in the building's box", placer.area(0, -102, -205, 51), 11)
        check("a part of no area", placer.area(0, -100, -195, 51), 11)
        check("no height: the terrain", placer.area(0, -98, -205), 11)
        check("no terrain: the smallest box", placer.place(5, 25, 25)[0], 50)
        check("no terrain, the larger box", placer.place(5, -50, -50)[0], 40)
        check("off every map", placer.place(5, 500, 500), None)
        check("a map the world map does not lead to", 60 in {u for boxes in placer.boxes.values() for _, _, u, _, _ in boxes}, False)
        check("a map's yards", placer.yards([10, 1, 1]), (1000.0, 1000.0))

        places = folder / "Places"
        places.mkdir()
        (places / "Places.jsonl").write_text(
            '{"key":4,"since":0,"src":["hand"],"kind":"mailbox","point":[10,20.0,30.0],"zone":10}\n'
            '{"key":7,"since":0,"src":["hand"],"kind":"raid","point":[10,70.0,20.1],"zone":10,"instance":35}\n', encoding="utf-8")
        keys = md.PlaceKeys(places)
        check("within half a percent: the same place", keys.key("mailbox", [10, 20.3, 30.3]), 4)
        check("farther: a new place", keys.key("mailbox", [10, 21.0, 30.0]), 8)
        check("the new place is known now", keys.key("mailbox", [10, 21.1, 30.0]), 8)
        check("another kind: a new place", keys.key("meetingstone", [10, 20.0, 30.0]), 9)
        check("an entrance by its instance", keys.key("raid", [10, 50.0, 50.0], 35), 7)
        check("another instance at the same gate", keys.key("raid", [10, 70.0, 20.1], 36), 10)

        zones = md.zones(folder)
        check("the zones", sorted(zones), [10, 20, 30, 40, 50])
        check("a side", zones[10], {"name": "A", "side": "alliance", "area": 1, "continent": 2})
        check("contested", zones[20]["side"], "contested")
        check("a sanctuary, no continent", zones[40], {"name": "Big isle", "side": "sanctuary", "area": 4})
        check("both faction groups: no side", "side" in zones[50], False)

        found = md.entrances(folder, placer, md.PlaceKeys(folder / "none"))
        check("the entrances", sorted((v["name"], v["kind"], v["instance"], v["zone"]) for v in found.values()),
              [("Hall", "raid", 35, 10), ("Keep", "dungeon", 33, 10)])
    print(f"Map data: all {checks} checks passed." if not failed else f"Map data: {failed} of {checks} checks failed.")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
