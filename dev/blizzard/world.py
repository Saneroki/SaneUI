"""A game build's world against the build before it: the terrain files and the client's map tables read as the game
reads them, so a file that only changed its bytes is no change (Doc/guides/blizzard-updates.md, *Patch day*).

  the ground     each map chunk's heights, base height added and only those inside the chunk: the game bakes a chunk's
                 base and its outer ring anew at times (a tile's edge on the deep sea floor jumped 500 yards while no
                 ground moved); less than GROUND yards is no move
  the holes      the chunk's holes in the terrain
  the areas      which area a chunk belongs to
  the water      each chunk's liquid layers: kind, place, mask and levels
  the minimap    the tile's texture: its file, and its bytes where both builds have them
  the placements every building and doodad the object files place: its file, place, turn and scale
  the models     the buildings' and doodads' own files, where a build changed one in place
  the maps       Map, AreaTable and UiMap: what is new, gone or renamed

What it says decides the rest of the patch's world work: walk_maps, the maps whose walking data is made anew;
instances, the instances whose terrain changed (ground, water, a tile added or gone), whose painted maps are painted
again (dev/tools/patchday rerender).
"""
import csv
import filecmp
import struct
from collections import defaultdict
from pathlib import Path

import numpy as np

GRID, CHUNKS = 64, 16                  # tiles along a map's side, map chunks along a tile's
TILE_YARDS = 1600 / 3
GROUND = 1.0                           # yards: the ground moved by less is no change


def pieces(data, start, end):
    """A file's chunks between start and end: (name, where its data begins, its size)."""
    at = start
    while at + 8 <= end:
        size = struct.unpack_from("<I", data, at + 4)[0]
        yield data[at:at + 4][::-1], at + 8, size
        at += 8 + size


def inside():
    """The indexes of a chunk's 145 heights that lie inside it: rows of 9 and of 8 by turns, the outer ring left out."""
    kept, at = [], 0
    for row in range(17):
        count = 8 if row % 2 else 9
        if 0 < row < 16:
            kept += range(at, at + count) if row % 2 else range(at + 1, at + count - 1)
        at += count
    return np.array(kept)


INSIDE = inside()


def tile_of(key):
    """(map, row, column) of a tile's key: map * 4096 + row * 64 + column."""
    map_id, rest = divmod(key, GRID * GRID)
    row, column = divmod(rest, GRID)
    return map_id, row, column


def chunk_holes(data, at):
    """A map chunk's holes as bytes: the fine ones, else the coarse ones, with which kind it is."""
    flags = struct.unpack_from("<I", data, at)[0]
    return (True, data[at + 0x14:at + 0x1C]) if flags & 0x10000 else (False, data[at + 0x3C:at + 0x3E])


def water_layers(data, base, index):
    """A map chunk's liquid layers, each as what the game reads of it."""
    first, count, _ = struct.unpack_from("<III", data, base + index * 12)
    layers = []
    for layer in range(count):
        kind, form, low, top_level, left, top, wide, high, bits, levels = struct.unpack_from(
            "<HHffBBBBII", data, base + first + layer * 24)
        if not wide or not high:
            continue
        mask = data[base + bits:base + bits + (wide * high + 7) // 8] if bits else b""
        corners = (wide + 1) * (high + 1)
        heights = data[base + levels:base + levels + corners * 4] if levels and form in (0, 1, 3) else b""
        layers.append((kind, form, round(low, 2), round(top_level, 2), left, top, wide, high, mask, heights))
    return tuple(sorted(layers))


def read_tile(path):
    """A root terrain file: per map chunk (x, y) its heights (the base added), holes, area and water."""
    data = path.read_bytes()
    chunks, water_at = [], None
    for name, at, size in pieces(data, 0, len(data)):
        if name == b"MCNK":
            chunks.append((at, size))
        elif name == b"MH2O":
            water_at = at
    tile = {}
    for number, (at, size) in enumerate(chunks):
        x, y = struct.unpack_from("<II", data, at + 4)
        base = struct.unpack_from("<f", data, at + 0x70)[0]
        heights = None
        for name, start, _ in pieces(data, at + 128, at + size):
            if name == b"MCVT":
                heights = np.frombuffer(data, "<f4", 145, start) + base
                break
        tile[(x, y)] = dict(heights=heights, holes=chunk_holes(data, at),
                            area=struct.unpack_from("<I", data, at + 0x34)[0],
                            water=water_layers(data, water_at, y * CHUNKS + x) if water_at is not None else ())
    return tile


def compare_tile(old_path, new_path):
    """What changed between two builds of a tile: its chunks counted by what changed in them."""
    old, new = read_tile(old_path), read_tile(new_path)
    change = dict(ground=0, most=0.0, holes=0, areas=0, water=0)
    for place in sorted(set(old) | set(new)):
        before, after = old.get(place), new.get(place)
        if before is None or after is None:
            change["ground"] += 1
            continue
        if before["heights"] is not None and after["heights"] is not None:
            moved = float(np.abs(before["heights"] - after["heights"])[INSIDE].max())
            if moved >= GROUND:
                change["ground"] += 1
                change["most"] = max(change["most"], moved)
        if before["holes"] != after["holes"]:
            change["holes"] += 1
        if before["water"] != after["water"]:
            change["water"] += 1
        if before["area"] != after["area"]:
            change["areas"] += 1
    return change


def object_placements(path):
    """What an object file places: {(kind, what is placed where): (file, box in pixels)}; a place so rounded that the
    game's re-saving does not count, a placement's own number left out (the game renumbers them at will)."""
    data = path.read_bytes()
    found = {}
    for name, at, size in pieces(data, 0, len(data)):
        if name == b"MODF":
            for start in range(at, at + size, 64):
                (file, _, px, py, pz, rx, ry, rz, lx, ly, lz, ux, uy, uz, flags, shown, _,
                 scale) = struct.unpack_from("<II3f3f6fHHHH", data, start)
                what = ("building", file, round(px, 1), round(py, 1), round(pz, 1), round(rx, 1), round(ry, 1),
                        round(rz, 1), flags, shown, scale)
                found[what] = (file, (min(lx, ux), min(lz, uz), max(lx, ux), max(lz, uz)))
        elif name == b"MDDF":
            for start in range(at, at + size, 36):
                file, _, px, py, pz, rx, ry, rz, scale, flags = struct.unpack_from("<II3f3fHH", data, start)
                what = ("doodad", file, round(px, 1), round(py, 1), round(pz, 1), round(rx, 1), round(ry, 1),
                        round(rz, 1), scale, flags)
                found[what] = (file, (px, pz, px, pz))
    return found


def minimap_files(folder):
    """{tile key: its minimap texture's file}, from the build's map files (MAID), wdt_<map>.db2."""
    files = {}
    for path in sorted((folder / "wdt").glob("wdt_*.db2")):
        map_id = int(path.stem.split("_")[1])
        data = path.read_bytes()
        for name, at, size in pieces(data, 0, len(data)):
            if name != b"MAID":
                continue
            for index in range(size // 32):
                row, column = divmod(index, GRID)
                file = struct.unpack_from("<I", data, at + index * 32 + 28)[0]
                if file:
                    files[map_id * GRID * GRID + row * GRID + column] = file
    return files


def read_csv(folder, name):
    path = Path(folder) / f"{name}.csv"
    if not path.is_file():
        return {}
    with open(path, encoding="utf-8", newline="") as file:
        return {row["ID"]: row for row in csv.DictReader(file)}


def changed_names(old, new, name_field, extra=()):
    """A table's rows new, gone and renamed, by the field that names them."""
    def row(key, table):
        return {"id": int(key), "name": table[key].get(name_field, ""), **{e: table[key].get(e, "") for e in extra}}
    return {"new": [row(k, new) for k in sorted(new.keys() - old.keys(), key=int)],
            "gone": [row(k, old) for k in sorted(old.keys() - new.keys(), key=int)],
            "renamed": [{"id": int(k), "was": old[k].get(name_field, ""), "name": new[k].get(name_field, "")}
                        for k in sorted(old.keys() & new.keys(), key=int)
                        if old[k].get(name_field) != new[k].get(name_field)]}


def changed_models(old_folder, new_folder, kind):
    """The files of a kind (wmo, m2) both builds hold and whose bytes differ. A file only one build holds says nothing:
    each extract holds what its own object files place."""
    old, new = old_folder / kind, new_folder / kind
    if not old.is_dir() or not new.is_dir():
        return []
    names = {path.name for path in new.glob(f"*.{kind}")} & {path.name for path in old.glob(f"*.{kind}")}
    changed = [name for name in sorted(names) if not filecmp.cmp(old / name, new / name, shallow=False)]
    return sorted({int(name.split(".")[0].split("_")[0]) for name in changed})


class Zones:
    """A map chunk's area to its zone, the area at the top of its parents, as the new build's AreaTable has them."""

    def __init__(self, tables):
        self.areas = read_csv(tables, "AreaTable")

    def of(self, area):
        row, seen = self.areas.get(str(area)), set()
        while row and row.get("ParentAreaID", "0") not in ("0", "") and row["ID"] not in seen:
            seen.add(row["ID"])
            row = self.areas.get(row["ParentAreaID"]) or row
        return row


def compare_terrain(old_folder, new_folder, zones):
    """Two builds' terrain folders: one record per tile that changed, the moved placements with it; the models."""
    tiles = {}
    old_adt, new_adt = old_folder / "adt", new_folder / "adt"
    old_names = {p.name for p in old_adt.glob("*.adt")}
    new_names = {p.name for p in new_adt.glob("*.adt")}

    def record(key):
        map_id, row, column = tile_of(key)
        return tiles.setdefault(key, dict(key=key, map=map_id, row=row, column=column, ground=0, most=0.0, holes=0,
                                          areas=0, water=0, buildings=0, doodads=0, minimap=False, models=[],
                                          added=False, removed=False, zones=[]))

    for name in sorted(new_names - old_names, key=lambda n: int(n.split(".")[0])):
        key = int(name.split(".")[0])
        entry = record(key)
        entry["added"] = True
    for name in sorted(old_names - new_names, key=lambda n: int(n.split(".")[0])):
        key = int(name.split(".")[0])
        entry = record(key)
        entry["removed"] = True
    for name in sorted(old_names & new_names, key=lambda n: int(n.split(".")[0])):
        if filecmp.cmp(old_adt / name, new_adt / name, shallow=False):
            continue
        change = compare_tile(old_adt / name, new_adt / name)
        if not any(change.values()):
            continue
        entry = record(int(name.split(".")[0]))
        entry.update(change)
        entry["most"] = round(entry["most"], 1)

    old_map, new_map = minimap_files(old_folder), minimap_files(new_folder)
    for key in sorted(old_map.keys() & new_map.keys()):
        old_blp = old_folder / "minimap" / f"{old_map[key]}.blp"
        new_blp = new_folder / "minimap" / f"{new_map[key]}.blp"
        same = old_map[key] == new_map[key]
        if same and old_blp.is_file() and new_blp.is_file():
            same = filecmp.cmp(old_blp, new_blp, shallow=False)
        if not same:
            entry = record(key)
            entry["minimap"] = True

    held = {}   # model file: the tiles that place it, as the new build has them
    old_obj, new_obj = old_folder / "adt-obj0", new_folder / "adt-obj0"
    for path in sorted(new_obj.glob("*.adt"), key=lambda p: int(p.stem)):
        key = int(path.stem)
        placed = object_placements(path)
        for file, _ in placed.values():
            held.setdefault(file, set()).add(key)
        before = old_obj / path.name
        if not before.is_file() or filecmp.cmp(before, path, shallow=False):
            continue
        was = object_placements(before)
        moved = placed.keys() ^ was.keys()
        if moved:
            entry = record(key)
            entry["buildings"] = sum(1 for what in moved if what[0] == "building")
            entry["doodads"] = sum(1 for what in moved if what[0] == "doodad")
    models = dict(buildings=changed_models(old_folder, new_folder, "wmo"),
                  doodads=changed_models(old_folder, new_folder, "m2"))
    for file in models["buildings"] + models["doodads"]:
        for key in held.get(file, ()):
            entry = record(key)
            entry["models"] = sorted({*entry["models"], file})

    for key, entry in tiles.items():
        path = new_adt / f"{key}.adt"
        if path.is_file():
            found = {zones.of(chunk["area"])["AreaName_lang"] for chunk in read_tile(path).values()
                     if zones.of(chunk["area"])}
            entry["zones"] = sorted(found)
    return [tiles[key] for key in sorted(tiles)], models


def by_zone(tiles, new_folder, zones):
    """Per zone: how many of its tiles changed, of how many it has."""
    total = defaultdict(set)
    for path in (new_folder / "adt").glob("*.adt"):
        for chunk in read_tile(path).values():
            row = zones.of(chunk["area"])
            if row:
                total[row["AreaName_lang"]].add(int(path.stem))
    found = {}
    for entry in tiles:
        for name in entry["zones"]:
            zone = found.setdefault(name, dict(zone=name, tiles=0, of=len(total[name]), ground=0, water=0, buildings=0,
                                               doodads=0, most=0.0))
            zone["tiles"] += 1
            zone["ground"] += entry["ground"]
            zone["water"] += entry["water"]
            zone["buildings"] += entry["buildings"]
            zone["doodads"] += entry["doodads"]
            zone["most"] = max(zone["most"], entry["most"])
    return sorted(found.values(), key=lambda z: (-z["tiles"], z["zone"]))


def walking_maps(tiles):
    """The maps whose walking data a change reaches: all but a changed area, which says nothing of where one walks."""
    return sorted({t["map"] for t in tiles if t["ground"] or t["holes"] or t["water"] or t["buildings"] or t["doodads"]
                   or t["models"] or t["added"] or t["removed"]})


def compare(old_folder, new_folder, old_tables, new_tables):
    """The world of two builds, as a dict for world.json. The folders are the builds' raw extracts: adt, adt-obj0, wmo,
    m2, wdt, minimap; the tables the CSV folders. A build's instances stand beside it, <folder>-instances."""
    zones = Zones(new_tables)
    tiles, models = compare_terrain(old_folder, new_folder, zones)
    old_inst, new_inst = old_folder.with_name(old_folder.name + "-instances"), new_folder.with_name(new_folder.name + "-instances")
    instances = []
    if (old_inst / "adt").is_dir() and (new_inst / "adt").is_dir():
        changed, _ = compare_terrain(old_inst, new_inst, zones)
        instances = sorted({t["map"] for t in changed if t["ground"] or t["water"] or t["added"] or t["removed"]})
    maps = changed_names(read_csv(old_tables, "Map"), read_csv(new_tables, "Map"), "MapName_lang", ("Directory", "InstanceType"))
    areas = changed_names(read_csv(old_tables, "AreaTable"), read_csv(new_tables, "AreaTable"), "AreaName_lang", ("ParentAreaID",))
    uimaps = changed_names(read_csv(old_tables, "UiMap"), read_csv(new_tables, "UiMap"), "Name_lang", ("Type", "ParentUiMapID"))
    return dict(maps=maps, areas=areas, uimaps=uimaps, tiles=tiles, zones=by_zone(tiles, new_folder, zones), models=models,
                instances=instances, walk_maps=walking_maps(tiles))


def moved(world):
    """Whether the world moved at all: the tiles, or the maps' lists."""
    return bool(world["tiles"] or world["instances"] or any(world[k][w] for k in ("maps", "areas", "uimaps")
                                                            for w in ("new", "gone", "renamed")))


def named(rows, limit=60):
    shown = ", ".join(f"{row.get('name') or row.get('was')} ({row['id']})" for row in rows[:limit])
    return shown + (f", and {len(rows) - limit} more" if len(rows) > limit else "")


def report(world, title):
    """world.md: the same in words."""
    tiles = world["tiles"]
    count = lambda what: sum(1 for t in tiles if t[what])   # noqa: E731
    lines = [f"# The world: {title}", "",
             f"{len(tiles)} tiles changed: {count('ground')} of ground (the most {max([t['most'] for t in tiles] or [0])} "
             f"yards), {count('water')} of water, {count('holes')} of holes, {count('areas')} of areas, "
             f"{count('minimap')} of minimap textures, {count('buildings')} with buildings placed otherwise, "
             f"{count('doodads')} with doodads, {count('models')} placing a changed model.",
             f"Walking data to make anew: {', '.join(map(str, world['walk_maps'])) or 'none'}. "
             f"Instances whose terrain changed: {', '.join(map(str, world['instances'])) or 'none'}."]
    for key, word in (("maps", "Maps"), ("areas", "Areas"), ("uimaps", "Zone maps")):
        for how in ("new", "gone", "renamed"):
            if world[key][how]:
                lines += ["", f"**{word} {how}:** {named(world[key][how])}"]
    if world["zones"]:
        lines += ["", "## By zone", "", "| Zone | Tiles | Of | Ground chunks | Water chunks | Buildings | Doodads | Most yards |",
                  "| --- | --- | --- | --- | --- | --- | --- | --- |"]
        lines += [f"| {z['zone']} | {z['tiles']} | {z['of']} | {z['ground']} | {z['water']} | {z['buildings']} | "
                  f"{z['doodads']} | {z['most']} |" for z in world["zones"]]
    if tiles:
        lines += ["", "## By tile", "", "| Key | Map | Row | Column | Ground | Most | Water | Holes | Areas | Minimap | Buildings | Doodads | Models |",
                  "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
        lines += [f"| {t['key']} | {t['map']} | {t['row']} | {t['column']} | {t['ground']} | {t['most']} | {t['water']} | "
                  f"{t['holes']} | {t['areas']} | {'yes' if t['minimap'] else ''} | {t['buildings']} | {t['doodads']} | "
                  f"{len(t['models'])} |" for t in tiles]
    return "\n".join(lines) + "\n"
