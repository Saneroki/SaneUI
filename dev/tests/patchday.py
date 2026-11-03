#!/usr/bin/env python3
"""Tests of dev/tools/patchday without the game's files, on made-up terrain, tables and notes: a ground that moved
against a chunk's base or outer ring baked anew, water, holes, areas and placements; which squares of the Atlas a
change reaches; a client table compared, its noise left out; the patch notes checked and written as text, as a page and
as the database's rows, which fit the real schema, the changes tied to their points; a build's own plain file, folded
shut; a build added to builds.toml; what the master took from a build; the repaint: what is set aside, the job in the
queue, how far it says it is; Core reading the notes and a racial's history; races and classes from the client. Run by
dev/tests/run."""
import csv
import importlib.machinery
import importlib.util
import json
import re
import resource
import shutil
import struct
import subprocess
import sys
import tempfile
import tomllib
from pathlib import Path
from types import SimpleNamespace as Thing

import numpy as np

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(ROOT / "dev" / "blizzard"), str(ROOT / "dev" / "data")]

import clienttables  # noqa: E402
import compile as compiler  # noqa: E402
import master as masters  # noqa: E402
import patchnotes  # noqa: E402
import schema as schemas  # noqa: E402
import world  # noqa: E402

loader = importlib.machinery.SourceFileLoader("patchday", str(ROOT / "dev" / "tools" / "patchday"))
pd = importlib.util.module_from_spec(importlib.util.spec_from_loader("patchday", loader))
loader.exec_module(pd)
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


def piece(name, data):
    return name[::-1] + struct.pack("<I", len(data)) + data


def chunk(x, y, base=100.0, heights=None, area=12, holes=0):
    """A map chunk: its header (x, y, area, coarse holes, base height) and its heights."""
    head = bytearray(128)
    struct.pack_into("<I", head, 0, 0)
    struct.pack_into("<II", head, 4, x, y)
    struct.pack_into("<I", head, 0x34, area)
    struct.pack_into("<H", head, 0x3C, holes)
    struct.pack_into("<f", head, 0x70, base)
    values = list(heights) if heights is not None else [0.0] * 145
    return piece(b"MCNK", bytes(head) + piece(b"MCVT", struct.pack("<145f", *values)))


def tile(path, chunks, water=None):
    data = b"".join(chunks)
    if water is not None:   # one layer on chunk 0: its kind and level
        kind, level = water
        table = bytearray(256 * 12)
        struct.pack_into("<III", table, 0, len(table), 1, 0)
        layer = struct.pack("<HHffBBBBII", kind, 2, level, level, 0, 0, 8, 8, 0, 0)
        data += piece(b"MH2O", bytes(table) + layer)
    path.write_bytes(data)


def placed(path, buildings=(), doodads=()):
    modf = b"".join(struct.pack("<II3f3f6fHHHH", file, unique, x, 0, z, 0, 0, 0, x, 0, z, x + 10, 5, z + 10, 8, 0, 0, 1024)
                    for file, unique, x, z in buildings)
    mddf = b"".join(struct.pack("<II3f3fHH", file, unique, x, 0, z, 0, 0, 0, 1024, 0x40) for file, unique, x, z in doodads)
    path.write_bytes(piece(b"MODF", modf) + piece(b"MDDF", mddf))


def table(folder, name, rows):
    with open(folder / f"{name}.csv", "w", encoding="utf-8", newline="") as out:
        writer = csv.DictWriter(out, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


def tree(folder):
    for part in ("adt", "adt-obj0", "wmo", "m2", "wdt", "tables"):
        (folder / part).mkdir(parents=True, exist_ok=True)
    return folder


temp = Path(tempfile.mkdtemp(prefix="patchday-test-"))
old, new = tree(temp / "wowf-1.60.1.1"), tree(temp / "wowf-1.60.1.2")

# --- one tile at a time -------------------------------------------------------------------------------------------
inner = world.INSIDE[0]
ring = [0.0] * 145
ring[0] = 500.0    # the chunk's corner: its outer ring
moved_inside = [0.0] * 145
moved_inside[inner] = 30.0
small = [0.0] * 145
small[inner] = 0.5


def tile_change(before, after, water_before=None, water_after=None):
    a, b = temp / "a.adt", temp / "b.adt"
    tile(a, before, water_before)
    tile(b, after, water_after)
    return world.compare_tile(a, b)


got = tile_change([chunk(0, 0, base=100)], [chunk(0, 0, base=100, heights=ring)])
check("the outer ring baked anew is no ground", got["ground"], 0)
got = tile_change([chunk(0, 0, base=100)], [chunk(0, 0, base=90, heights=[10.0] * 145)])
check("a base baked anew is no ground", (got["ground"], got["chunks"]), (0, []))
got = tile_change([chunk(0, 0)], [chunk(0, 0, heights=small)])
check("half a yard is no ground", got["ground"], 0)
got = tile_change([chunk(0, 0)], [chunk(0, 0, heights=moved_inside)])
check("the ground moved", (got["ground"], got["most"], got["chunks"]), (1, 30.0, [(0, 0)]))
got = tile_change([chunk(0, 0, holes=0)], [chunk(0, 0, holes=1)])
check("a hole", (got["holes"], got["chunks"]), (1, [(0, 0)]))
got = tile_change([chunk(0, 0, area=12)], [chunk(0, 0, area=13)])
check("an area counts but touches no picture", (got["areas"], got["chunks"]), (1, []))
got = tile_change([chunk(0, 0)], [chunk(0, 0)], (1, 5.0), (1, 9.0))
check("the water", (got["water"], got["chunks"]), (1, [(0, 0)]))
got = tile_change([chunk(0, 0)], [chunk(0, 0)], (1, 5.0), (1, 5.0))
check("the same water", got["water"], 0)

# --- the Atlas' squares -------------------------------------------------------------------------------------------
check("the first chunk: one square", world.squares_of(*world.chunk_box(0, 0, (0, 0))), {(0, 0)})
check("the overlap: two squares", sorted(world.squares_of(1800, 0, 1900, 100)), [(0, 0), (1, 0)])
check("a chunk of the next tile's row", (0, 1) in world.squares_of(*world.chunk_box(1, 0, (0, 0))), True)

# --- two builds -----------------------------------------------------------------------------------------------------
key = 4096 + 30 * 64 + 40   # Kalimdor
same, area_only = 4096 + 30 * 64 + 41, 2991 * 4096 + 5
for folder, heights, area in ((old, None, 12), (new, moved_inside, 12)):
    tile(folder / "adt" / f"{key}.adt", [chunk(0, 0, heights=heights, area=area)])
    tile(folder / "adt" / f"{same}.adt", [chunk(0, 0)])
tile(old / "adt" / f"{area_only}.adt", [chunk(0, 0, area=12)])
tile(new / "adt" / f"{area_only}.adt", [chunk(0, 0, area=13)])
placed(old / "adt-obj0" / f"{key}.adt", [(500, 1, 10.0, 20.0)], [(600, 2, 30.0, 40.0)])
placed(new / "adt-obj0" / f"{key}.adt", [(500, 99, 10.0, 20.0)], [(600, 2, 300.0, 40.0)])   # renumbered; moved
placed(old / "adt-obj0" / f"{same}.adt", [(700, 3, 1.0, 1.0)])
placed(new / "adt-obj0" / f"{same}.adt", [(700, 3, 1.0, 1.0)])
(old / "wmo" / "700.wmo").write_bytes(b"one")
(new / "wmo" / "700.wmo").write_bytes(b"two")
(old / "m2" / "extract.tsv").write_text("x")
(new / "m2" / "extract.tsv").write_text("y")
for folder, extra in ((old, []), (new, [{"ID": "3", "AreaName_lang": "New Crater", "ParentAreaID": "0"}])):
    table(folder / "tables", "AreaTable", [{"ID": "12", "AreaName_lang": "Elwynn Forest", "ParentAreaID": "0"},
                                           {"ID": "13", "AreaName_lang": "Goldshire", "ParentAreaID": "12"}] + extra)
    table(folder / "tables", "Map", [{"ID": "0", "MapName_lang": "Eastern Kingdoms", "Directory": "Azeroth", "InstanceType": "0"}])
    table(folder / "tables", "UiMap", [{"ID": "1429", "Name_lang": "Elwynn Forest", "Type": "3", "ParentUiMapID": "0"}])
found = world.compare(old, new, old / "tables", new / "tables")
tiles = {t["key"]: t for t in found["tiles"]}
check("the tile that moved", (tiles[key]["ground"], tiles[key]["most"]), (1, 30.0))
check("a building only renumbered is none, a doodad moved is", (tiles[key]["buildings"], tiles[key]["doodads"]), (0, 2))
check("the tile that places a changed model", tiles[same]["models"], [700])
check("the changed models", found["models"], {"buildings": [700], "doodads": []})
check("a new area", [a["name"] for a in found["areas"]["new"]], ["New Crater"])
check("a chunk's zone is the top of its parents", tiles[key]["zones"], ["Elwynn Forest"])
check("the squares are the Atlas' continents' alone", found["squares"] and all(s.startswith("1-") for s in found["squares"]), True)
check("an area alone asks for no walking data", found["walk_maps"], [1])
check("the world moved", world.moved(found), True)
text = world.report(found, "a test")
check("the report", ("New Crater" in text, "| Elwynn Forest |" in text), (True, True))

# --- the client's tables --------------------------------------------------------------------------------------------
left, right, out = temp / "left", temp / "right", temp / "out"
for folder in (left, right, out):
    folder.mkdir()
table(left, "ChrRaces", [{"ID": "1", "Name_lang": "Human", "FactionID": "5", "VerifiedBuild": "1"},
                         {"ID": "2", "Name_lang": "Orc", "FactionID": "6", "VerifiedBuild": "1"},
                         {"ID": "3", "Name_lang": "Gone", "FactionID": "6", "VerifiedBuild": "1"}])
table(right, "ChrRaces", [{"ID": "1", "Name_lang": "Human", "FactionID": "7", "VerifiedBuild": "2"},
                          {"ID": "2", "Name_lang": "Orc", "FactionID": "6", "VerifiedBuild": "2"},
                          {"ID": "4", "Name_lang": "New", "FactionID": "8", "VerifiedBuild": "2"}])
table(left, "SpellName", [{"ID": "1", "Name_lang": "Same"}])
table(right, "SpellName", [{"ID": "1", "Name_lang": "Same"}])
table(right, "BrandNew", [{"ID": "1"}])
found = {row["table"]: row for row in clienttables.compare(left, right, out)}
check("a table's counts", [found["ChrRaces"][k] for k in ("new", "gone", "changed", "columns")], [1, 1, 1, ["FactionID"]])
check("its topic", found["ChrRaces"]["topic"], "Characters")
check("an equal table is left out, a new one is said", sorted(found), ["BrandNew", "ChrRaces"])
lines = (out / "tables" / "ChrRaces.tsv").read_text(encoding="utf-8").splitlines()
check("a change names its row, column and values", "1\tHuman\tchanged\tFactionID\t5\t7" in lines, True)
check("the build's own column is noise", any("VerifiedBuild" in line for line in lines), False)
check("the list", (out / "tables.tsv").read_text(encoding="utf-8").count("\n"), 3)

big = temp / "big"
(big / "a").mkdir(parents=True)
(big / "b").mkdir()
(big / "out").mkdir()
table(big / "a", "Numbered", [{"ID": str(i), "Value": str(i * 2)} for i in range(1200)])
table(big / "b", "Numbered", [{"ID": str(i), "Value": str(i * 2 + 2)} for i in range(1200)])   # one row in front, the rest moved
found = {row["table"]: row for row in clienttables.compare(big / "a", big / "b", big / "out")}
check("a table numbered anew is compared by what it holds", [found["Numbered"][k] for k in ("new", "gone", "changed")], [1, 1, 0])
check("Housing has its topic", clienttables.topic("HouseDecor"), "Housing")
check("the game's rules are no spells", clienttables.topic("Cfg_GameRules"), "Other")

# --- the patch notes ------------------------------------------------------------------------------------------------
notes = patchnotes.skeleton("forever", 70801, 70707, "1.60.2", "2026-11-12")
check("Blizzard's sections, General first", (notes["sections"][0]["name"], notes["sections"][-1]["name"]), ("General", "Bug Fixes"))
check("no points yet is a problem", "no point written yet" in patchnotes.problems(notes), True)
classes = next(s for s in notes["sections"] if s["name"] == "Classes")
classes["groups"] = [{"name": "Mage", "points": [{"text": "Blizzard <Blink> cost", "was": "25", "origin": "both", "link": "https://worldofwarcraft.blizzard.com/x",
                                                  "extra": ["Its rank 2 too"], "note": "Hits low levels most"}],
                      "groups": [{"name": "Frost", "points": [{"text": "Frostbolt faster", "origin": "client"}]}]}]
next(s for s in notes["sections"] if s["name"] == "General")["points"] = [{"text": "A server rule", "origin": "blizzard"}]
notes["sane"] = ["The bags follow the new window"]
notes["official"], notes["crosschecked"] = [{"title": "Hotfixes", "url": "https://worldofwarcraft.blizzard.com/n"}], True
check("good notes", patchnotes.problems(notes), [])
broken = json.loads(json.dumps(notes))
broken["sections"][0]["points"] = [{"text": "No origin"}, {"text": "a\ttab", "origin": "both"}, {"origin": "both"}]
check("three problems", len(patchnotes.problems(broken)), 3)

rows = patchnotes.rows(notes)
check("a point's extra and note follow it", [r["kind"] for r in rows], ["point", "point", "extra", "note", "point"])
check("where a point stands", (rows[1]["section"], rows[1]["group"], rows[4]["sub"]), ("Classes", "Mage", "Frost"))
check("a part without value stays out", "was" in rows[0], False)
check("a point knows its class", rows[1]["class"], 8)
sample_facts = {"sets": {"Spells": {"counts": {"new": 0, "changed": 2, "gone": 1},
                                    "changed": [{"key": 1, "name": "Frostbolt faster", "class": 8, "changes": [{"field": "cost", "from": "1", "to": "2"}, {"field": "cooldown", "from": "1", "to": "2"}]},
                                                {"key": 2, "name": "Frostbolt faster", "class": 7, "changes": []}],
                                    "gone": [{"key": 3, "name": "Unnamed anywhere"}]},
                         "Walking": {"counts": {"new": 0, "changed": 9, "gone": 0}}}}
tied = {entry["key"]: entry for entry in patchnotes.changes(notes, sample_facts)}
check("a change is tied to the point that names it, its class's", tied["1"], {"set": "Spells", "key": "1", "how": "changed", "fields": "cost,cooldown", "class": 8, "point": 5})
check("not another class's", "point" in tied["2"], False)
check("nor one no point names", "point" in tied["3"], False)
check("a set of counts alone stands in counts", patchnotes.fields(notes, sample_facts)["counts"], {"Spells": 3, "Walking": 9})
master = masters.Master(masters.MASTER).load()
schema = master.schemas["PatchNotes"]
fields = patchnotes.fields(notes, sample_facts)
values = [schemas.value_problem(next(f for f in schema.fields if f.name == name), value, {}, set()) for name, value in fields.items()]
check("the database's entry fits the real schema", values, [None] * len(values))

text = patchnotes.markdown(notes)
check("text: a value before", "(was 25)" in text, True)
check("text: what we found more", "- Also found: Its rank 2 too" in text, True)
check("text: an empty section is left out", "## Quests" in text, False)
page = patchnotes.document(notes, {"sets": {"Spells": {"counts": {"new": 1, "changed": 0, "gone": 0}, "new": [{"key": 7, "name": "Nova"}]},
                                            "Walking": {"counts": {"new": 0, "changed": 9, "gone": 0}}}})
check("a whole file", page.startswith("<!doctype html>"), True)
check("every level is folded shut", re.search(r"<details[^>]* open", page), None)
check("and its button opens them", 'aria-pressed="false">Expand all</button>' in page, True)
check("a section's link opens it and brings it up", ('href="#classes"' in page, "window.scrollTo" in page, "preventDefault" in page), (True, True, True))
check("it needs nothing outside itself", ("<link" in page, "<script src" in page, "fonts." in page), (False, False, False))
check("one dark theme, whatever the computer's", ("color-scheme: dark" in page, "prefers-color-scheme" in page, "data-theme" in page), (True, False, False))
check("the page has its name", "<title>Forever 1.60.2.70801 Patch Notes</title>" in page, True)
check("the page folds", page.count("<details") >= 5, True)
check("text is escaped", ("&lt;Blink&gt;" in page, "<Blink>" in page), (True, False))
check("the origin's tag links to Blizzard", 'href="https://worldofwarcraft.blizzard.com/x"' in page, True)
check("the day as Blizzard writes it", "November 12, 2026" in page, True)
check("no empty section on the page", 'id="quests"' in page, False)
check("every change stays closed", '<details class="section every" id="every">' in page, True)
check("a set of counts alone", "9 changed" in page, True)
check("it says it is no page of Blizzard's", "Not an official Blizzard page" in page, True)
none = json.loads(json.dumps(notes))
none["official"] = []
check("no notes of Blizzard's is said", "published no notes" in patchnotes.document(none), True)

# --- builds.toml ----------------------------------------------------------------------------------------------------
sample = '# head\n[forever]\n70245 = { patch = "1.60.1" }\n70707 = { patch = "1.60.1", day = "2026-10-31" }\n\n[forever-ptr]\n\n[retail]\n\n[forever-beta]\n70425 = { patch = "1.60.1" }\n'
made = pd.add_build(sample, "forever", 70801, "1.60.2", "2026-11-12")
parsed = tomllib.loads(made)
check("a build at its table's end", list(parsed["forever"]), ["70245", "70707", "70801"])
check("its patch and day", parsed["forever"]["70801"], {"patch": "1.60.2", "day": "2026-11-12"})
check("not twice", pd.add_build(made, "forever", 70801, "1.60.2", "2026-11-12"), made)
made = pd.add_build(sample, "retail", 70688, "12.1.5", "2026-11-01")
check("into an empty table", tomllib.loads(made)["retail"], {"70688": {"patch": "12.1.5", "day": "2026-11-01"}})
check("the other tables stay", list(tomllib.loads(made)["forever-beta"]), ["70425"])

# --- what the master took ---------------------------------------------------------------------------------------------
game_line, batch_line = Thing(src=["game"]), Thing(src=[5])


def version(since, fields, line=game_line, gone=False):
    return Thing(since=since, fields=fields, line=line, gone=gone)


class Master:
    schemas = {"Spells": Thing(fields=[Thing(name="name"), Thing(name="cost")]), "SkillLines": Thing(fields=[]),
               "Walking": Thing(fields=[Thing(name="block")]), "PatchNotes": Thing(fields=[]),
               "Items": Thing(fields=[Thing(name="sell")])}
    views = {"Spells": {1: [version(10, {"name": "Bolt", "cost": 5}), version(20, {"name": "Bolt", "cost": 7})],
                        2: [version(20, {"name": "Nova"})],
                        3: [version(10, {"name": "Old"}), version(20, {}, gone=True)],
                        4: [version(10, {"name": "Batch"}), version(20, {"name": "Batch", "cost": 1}, batch_line)]},
             "SkillLines": {7: [version(10, {"name": "Frost", "class": 8, "spells": [1]})]},
             "Walking": {5: [version(10, {"block": "a"}), version(20, {"block": "b"})]}, "PatchNotes": {},
             "Items": {6: [version(10, {"name": "Brittle Key", "class": 13, "sell": 0}), version(20, {"sell": 17})]}}

    def view(self, name, game):
        return self.views[name]


facts = pd.facts_of(Master(), "forever", 20)
check("what is new, changed and gone", facts["sets"]["Spells"]["counts"], {"new": 1, "changed": 1, "gone": 1})
check("a change, from and to", facts["sets"]["Spells"]["changed"][0]["changes"], [{"field": "cost", "from": "5", "to": "7"}])
check("a spell's class", facts["sets"]["Spells"]["changed"][0]["class"], 8)
check("an item's class is no player's (13 a key, not Evoker)", "class" in facts["sets"]["Items"]["changed"][0], False)
check("a set of counts holds no rows", "changed" in facts["sets"]["Walking"], False)
check("what facts say", "changed 1 Bolt (Mage): cost 5 → 7" in pd.facts_text(facts, "a build"), True)

# --- the repaint ------------------------------------------------------------------------------------------------------
reports = temp / "reports"
folder = reports / "patches" / "forever-1-to-2"
folder.mkdir(parents=True)
pd.TILES, pd.LAYERS, pd.JOBS = temp / "tiles", temp / "layers", temp / "jobs.toml"
pd.ROOT = temp
(pd.TILES / "1").mkdir(parents=True)
(pd.TILES / "1" / "sq-3-4.png").write_bytes(b"old")
(pd.LAYERS / "zone-1429").mkdir(parents=True)
(pd.LAYERS / "zone-1429" / "far.png").write_bytes(b"far")
(pd.LAYERS / "zone-1429" / "far-2.png").write_bytes(b"try")
(pd.LAYERS / "zone-1429" / "far-colours.png").write_bytes(b"input")
(pd.LAYERS / "zone-1429" / "checks.json").write_text(json.dumps({"far-2": 1, "middle-1": 2}))
(pd.LAYERS / "state.json").write_text(json.dumps({"paths": {"continents": "old", "tables": "old", "minimap": "keep"},
                                                  "subjects": [{"name": "zone-1429"}, {"name": "zone-1"}]}))
pd.JOBS.write_text('[[job]]\nname = "worldtiles"\npriority = 10\ncommand = ["x"]\n')
moved_tile = {"ground": 2, "holes": 0, "water": 0, "minimap": False, "zones": ["Elwynn Forest"]}
model_tile = {"ground": 0, "holes": 0, "water": 0, "minimap": False, "zones": ["Elwynn Forest 2"], "models": [700]}
world_facts = {"squares": ["1-3-4", "1-9-9"], "instances": [], "tiles": [moved_tile] * 3 + [model_tile] * 9, "maps": {}, "areas": {},
               "uimaps": {}, "zones": [{"zone": "Elwynn Forest", "tiles": 3, "of": 10, "ground": 6, "water": 0},
                                       {"zone": "Elwynn Forest 2", "tiles": 9, "of": 10, "ground": 0, "water": 0}]}
state_now = {"subjects": [{"name": "zone-1429"}, {"name": "zone-1430"}]}
uimaps_now = temp / "uimaps"
uimaps_now.mkdir()
table(uimaps_now, "UiMap", [{"ID": "1429", "Name_lang": "Elwynn Forest", "Type": "3"}, {"ID": "1430", "Name_lang": "Elwynn Forest 2", "Type": "3"}])
check("a zone counts the tiles its pictures are made from, not those of a changed model",
      pd.zone_subjects(world_facts, state_now, uimaps_now), ["zone-1429"])
(folder / "world.json").write_text(json.dumps(world_facts))
pd.reports = lambda: reports
pd.client_tables = lambda product, version: new / "tables"
pd.Patch = lambda game, place: Thing(game=game, name="forever-1-to-2", folder=folder, build=2, product="wowf", new="2", extract=new)
pd.run_rerender(Thing(game="forever", priority=11))
check("a painted square is set aside", (pd.TILES / "1" / "sq-3-4.png").is_file(), False)
aside = temp / "assets" / "generated" / "replaced" / "2"
check("its picture is kept", (aside / "world-tiles" / "1" / "sq-3-4.png").read_bytes(), b"old")
check("the plan: what was painted", json.loads((folder / "rerender.json").read_text()), {"squares": ["1-3-4"], "subjects": ["zone-1429"]})
check("a zone's far painting and tries go", sorted(p.name for p in (pd.LAYERS / "zone-1429").glob("far*")), ["far-colours.png"])
check("its far checks are forgotten", json.loads((pd.LAYERS / "zone-1429" / "checks.json").read_text()), {"middle-1": 2})
state = json.loads((pd.LAYERS / "state.json").read_text())
check("the maps' inputs read the new build", state["paths"]["continents"], str(new / "adt"))
check("a build without textures keeps the old ones", state["paths"]["minimap"], "keep")
jobs = tomllib.loads(pd.JOBS.read_text())["job"]
check("the job is queued behind the others", [j["name"] for j in jobs], ["worldtiles", "patch-2"])
job = jobs[1]
check("its priority", job["priority"], 11)
check("its command", job["command"], ["dev/tools/patchday", "paint", "forever-1-to-2"])
pd.run_rerender(Thing(game="forever", priority=11))
check("queued once", len(tomllib.loads(pd.JOBS.read_text())["job"]), 2)
plan = json.loads((folder / "rerender.json").read_text())
check("nothing painted yet", pd.painted(plan), 0)
(pd.TILES / "1" / "sq-3-4.png").write_bytes(b"new")
(pd.LAYERS / "zone-1429" / "far.png").write_bytes(b"new")
check("all painted", pd.painted(plan), 2)
check("the runner's pattern reads the status", bool(re.search(job["done"], "2 of 2 squares painted (100.0 %)")), True)
check("not while one is missing", bool(re.search(job["done"], "1 of 2 squares painted (50.0 %)")), False)

# --- a build's file ---------------------------------------------------------------------------------------------------
pd.PATCHNOTES = temp / "Patchnotes"
pd.Patch = lambda game, place: Thing(game=game, name="forever-1-to-2", folder=folder, build=2, product="wowf", new="1.60.2.70801", extract=new)
(folder / "patchnotes.json").write_text(json.dumps(notes), encoding="utf-8")
pd.run_page(Thing(game="forever"))
check("a file for each build and game", [p.name for p in pd.PATCHNOTES.iterdir()], ["Forever-1.60.2.70801.html"])
check("the text stays with the patch", (folder / "patchnotes.md").is_file(), True)

# --- the sets as the game reads them ------------------------------------------------------------------------------------
sets = temp / "sets"
sets.mkdir()
for name in ("PatchNotes", "Racials", "Races", "Classes"):
    (sets / f"{name}.lua").write_text(compiler.set_file(master, master.schemas[name], "forever")[0], encoding="utf-8")
reader = temp / "read.lua"
reader.write_text(f"""
package.path = "{ROOT}/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)
W.build = 70707
W.AddSets("{sets}")
W.LoadCore("{ROOT}")
W.Fire("ADDON_LOADED", "SaneUI")
W.Fire("PLAYER_LOGIN")
W.Wait(0)
local Data = SaneUI.Core.Data
local notes = Data.Set("PatchNotes"):Get(70707)
assert(notes and notes.patch == "1.60.1" and notes.points[1].section == "General", "a build's notes")
local shaman, tied = false, 0
for _, point in ipairs(notes.points) do shaman = shaman or (point.class == 7 and point.group == "Shaman") end
assert(shaman, "a point knows its class")
for _, change in ipairs(notes.changes) do
    if change.point then
        tied = tied + 1
        assert(notes.points[change.point].text, "a change names its point")
    end
end
assert(tied > 0 and notes.counts.Racials > 0, "changes are tied to points, and counted per set")
local builds = Data.Set("PatchNotes"):Keys("byClass", 7)
assert(builds[1] == 70707, "the builds that speak of a class")
local changes = Data.Set("Racials"):Changes(680)
local named = false
for _, change in ipairs(changes) do named = named or (change.field == "name" and change.from == "Axe Specialization" and change.to == "Command") end
assert(named, "a racial's history")
assert(Data.Set("Races"):Get(2).side == "horde" and Data.Set("Classes"):Get(7).name == "Shaman", "races and classes")
io.write("read")
""", encoding="utf-8")


def small():
    resource.setrlimit(resource.RLIMIT_AS, (2_000_000_000, 2_000_000_000))


got = subprocess.run(["lua5.1", str(reader)], capture_output=True, text=True, cwd=ROOT, preexec_fn=small)
check("Core reads the notes, a racial's history and its race", (got.stdout.strip()[-4:], got.stderr[-300:]), ("read", ""))

retail = temp / "retail"
retail.mkdir()
(retail / "PatchNotes.lua").write_text(compiler.set_file(master, master.schemas["PatchNotes"], "retail")[0], encoding="utf-8")
reader.write_text(f"""
package.path = "{ROOT}/dev/tests/?.lua;" .. package.path
local W = require("wowstub")
W.Install(_G)
W.Play("retail")
W.build = 70688
W.AddSets("{retail}")
W.LoadCore("{ROOT}")
W.Fire("ADDON_LOADED", "SaneUI")
W.Fire("PLAYER_LOGIN")
W.Wait(0)
local notes = SaneUI.Core.Data.Set("PatchNotes"):Get(70688)
assert(notes and notes.patch == "12.1.5", "Retail's notes")
local druid = false
for _, point in ipairs(notes.points) do druid = druid or point.class == 11 end
assert(druid, "a point knows its class")
io.write("read")
""", encoding="utf-8")
got = subprocess.run(["lua5.1", str(reader)], capture_output=True, text=True, cwd=ROOT, preexec_fn=small)
check("Retail reads its own notes", (got.stdout.strip()[-4:], got.stderr[-300:]), ("read", ""))

# --- what the client says of races and classes ----------------------------------------------------------------------
loader = importlib.machinery.SourceFileLoader("game_data", str(ROOT / "dev" / "tools" / "game-data"))
gd = importlib.util.module_from_spec(importlib.util.spec_from_loader("game_data", loader))
loader.exec_module(gd)
client = {"ChrRaceRacialAbility": {"680": {"Name_lang": "Orc - Passive - Command", "ChrRacesID": "2", "Description_lang": "Pets deal more",
                                           "DescriptionShort_lang": "|cnWHITE_FONT_COLOR:Command (Passive):|r Pets", "Icon": "5", "Order": "2"},
                                   "696": {"Name_lang": "Skyborne - Alliance - Active - Read Leyline", "ChrRacesID": "95", "Description_lang": "A",
                                           "DescriptionShort_lang": "B", "Icon": "6", "Order": "1"}},
          "ChrRaces": {"2": {"Name_lang": "Orc", "Name_female_lang": "", "ClientFileString": "Orc", "FactionID": "2", "LoreDescription_lang": "L",
                             "PlayableRaceBit": "1", "UiDisplayOrder": "5"},
                       "13": {"Name_lang": "Naga"}},
          "FactionTemplate": {"2": {"FactionGroup": "5"}},
          "ChrClasses": {"7": {"Name_lang": "Shaman", "Filename": "SHAMAN", "Description_lang": "D", "IconFileDataID": "9", "DisplayPower": "0",
                               "ClassColorR": "0", "ClassColorG": "112", "ClassColorB": "222", "ArmorTypeMask": "3"}},
          "Map": {"3217": {"MapName_lang": "Dalaran Skycuter", "Directory": "3217", "InstanceType": "0", "ParentMapID": "-1", "AreaTableID": "0", "MaxPlayers": "0"}},
          "AreaTable": {"2521": {"AreaName_lang": "Verdantis River", "ParentAreaID": "12", "ContinentID": "0", "FactionGroupMask": "0",
                                 "ExplorationLevel": "-1", "MountFlags": "0"}}}
writer = gd.Writer("forever", 70707, None)
tables_of = client.__getitem__
gd.characters(tables_of, writer)
gd.places(tables_of, writer)
staged = {(line["set"], line["key"]): line["fields"] for line in writer.lines}
check("a racial's name, kind and short line", [staged["Racials", 680][k] for k in ("name", "kind", "short")], ["Command", "passive", "Command (Passive): Pets"])
check("a faction's name in a racial is no name", (staged["Racials", 696]["name"], staged["Racials", 696]["kind"]), ("Read Leyline", "active"))
check("a race by its abilities, its side by its template", (staged["Races", 2]["side"], ("Races", 13) in staged), ("horde", False))
check("a class's colour", staged["Classes", 7]["color"], "0070DE")
check("an area below level 0 has no level", "level" in staged["Areas", 2521], False)
spells = Thing(effects={"7": [{"DifficultyID": "1", "EffectIndex": "0"},
                              {"DifficultyID": "0", "EffectIndex": "1", "Effect": "2", "EffectAura": "0", "EffectBasePointsF": "88.5", "EffectRealPointsPerLevel": "0.6",
                               "EffectAuraPeriod": "0", "EffectChainTargets": "3", "EffectMiscValue[0]": "0", "EffectTriggerSpell": "0"}]})
check("a spell's numbers, the normal difficulty's", gd.Spells.effect_list(spells, "7"), [{"index": 1, "effect": 2, "points": 88.5, "perLevel": 0.6, "targets": 3}])

shutil.rmtree(temp, ignore_errors=True)
print(f"patchday: {checks} checks, {failed} failed")
sys.exit(1 if failed else 0)
