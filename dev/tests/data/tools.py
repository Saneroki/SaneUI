#!/usr/bin/env python3
"""Tests of the data framework's tools (dev/data, dev/tools/data; Doc/guides/data.md): every rule of the
check caught on a copy of the sample master with that one thing broken, the import's cases, and the real
master up to date with what dev/tools/cvar-labels stages. Run by dev/tests/run."""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SAMPLE = HERE / "sample"
sys.path.insert(0, str(ROOT / "dev" / "data"))

import check as checks  # noqa: E402
import importer  # noqa: E402
import master as masters  # noqa: E402

checks_run = failed = 0


def check(name, got, want):
    global checks_run, failed
    checks_run += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


def loaded(root):
    master = masters.Master(root).load()
    checks.check(master)
    return master


class Copy:
    """A copy of the sample master to break, in a folder of its own."""

    def __enter__(self):
        self.folder = tempfile.mkdtemp(prefix="saneui-data-")
        self.root = Path(self.folder) / "data"
        shutil.copytree(SAMPLE, self.root)
        return self

    def __exit__(self, *_):
        shutil.rmtree(self.folder)

    def path(self, name):
        return self.root / name

    def replace(self, name, old, new):
        path = self.path(name)
        text = path.read_text(encoding="utf-8")
        assert old in text, f"{old!r} not in {name}"
        path.write_text(text.replace(old, new, 1), encoding="utf-8")

    def append(self, name, text):
        path = self.path(name)
        path.write_text(path.read_text(encoding="utf-8") + text, encoding="utf-8")

    def write(self, name, text):
        self.path(name).parent.mkdir(parents=True, exist_ok=True)
        self.path(name).write_text(text, encoding="utf-8")


def caught(name, change, words, level="error"):
    """Breaks one thing in a copy of the sample and checks that the check names it."""
    with Copy() as copy:
        change(copy)
        master = loaded(copy.root)
        found = master.errors if level == "error" else master.warnings
        hit = [text for text in found if words in text]
        check(f"caught: {name}", bool(hit), True)
        if not hit:
            print("   problems were:", *found or ["(none)"], sep="\n   ")


# The sample itself fits ---------------------------------------------------------------------------------
sample = loaded(SAMPLE)
check("sample fits", sample.errors, [])
check("sample warns of nothing", sample.warnings, [])
check("sample's game versions", sample.games, ["forever", "forever-ptr", "forever-beta"])
check("sample's sets", sorted(sample.schemas), ["Folk", "Gear", "Labels"])
check("field order", sample.schemas["Gear"].names[:3], ["name", "quality", "slot"])

# Views and versions
gear = sample.view("Gear", "forever")
check("versions of 100", [(v.since, v.day) for v in gear[100]], [(0, None), (65000, "2026-09-01"), (65100, None)])
check("whole version", gear[100][-1].fields.get("stats"), {"agi": 1, "sta": 3})
check("null clears", "weight" in gear[100][-1].fields, False)
check("fix laid on", gear[101][0].fields["name"], "Tall Boots of Wading")
check("without fixes", sample.view("Gear", "forever", fixes=False)[101][0].fields["name"], "Tall Boots")
beta = sample.view("Gear", "forever-beta")
check("beta stands on live's newest", (beta[100][0].since, beta[100][0].fields["sell"]), (0, 110))
check("beta's own version on top", beta[100][-1].fields["quality"], 2)
check("beta's own entry", 103 in beta, True)
check("live has none of the beta's", 103 in gear, False)
check("gone stays gone in the beta", 3 in sample.view("Folk", "forever-beta"), False)
check("current at a build", masters.current(gear[100], 65050).since, 65000)
check("current at a build, its day not known: the build's newest", masters.current(gear[100], 65000).since, 65000)
check("current before a day", masters.current(gear[100], 65000, "2026-08-31").since, 0)
check("current on the day", masters.current(gear[100], 65000, "2026-09-01").since, 65000)

# Writing gives the same text as read
with Copy() as copy:
    master = loaded(copy.root)
    before = copy.path("Gear/Gear.jsonl").read_text(encoding="utf-8")
    masters.write(master, "Gear", "forever", master.lines[("Gear", "forever")])
    check("written as read", copy.path("Gear/Gear.jsonl").read_text(encoding="utf-8"), before)

# Every rule of the check --------------------------------------------------------------------------------
G = "Gear/Gear.jsonl"
caught("a game version's name", lambda c: c.append("builds.toml", '\n["Forever"]\n'), "no game version's name")
caught("live missing", lambda c: c.replace("builds.toml", "[forever]\n", "[elsewhere]\n"), "[forever] is missing")
caught("a build without patch", lambda c: c.replace("builds.toml", '65100 = { patch = "1.60.2" }', "65100 = { }"), "needs its patch")
caught("a build's bad day", lambda c: c.replace("builds.toml", '"2026-09-01"', '"2026-13-01"'), "is no date")
caught("a source's kind", lambda c: c.replace("sources.toml", 'kind = "hand"', 'kind = "people"'), "'kind' is one of")
caught("a batch's game", lambda c: c.replace("sources.toml", 'game = "forever-beta"', 'game = "other"'), "'game' names the game version")
caught("a batch's build", lambda c: c.replace("sources.toml", "build = 66000", "build = 65100"), "'build' is a build of forever-beta")
caught("a pack's notes", lambda c: c.replace("packs.toml", 'notes = "Sample words."', ""), "needs 'title' and 'notes'")
caught("a type", lambda c: c.replace("Folk/schema.toml", 'title = { type = "text" }', 'title = { type = "string" }'), "is no type")
caught("an enum's values", lambda c: c.replace("Gear/schema.toml", ', values = ["head", "hands", "feet"]', ""), "an enum needs 'values'")
caught("a list of lists", lambda c: c.replace("Gear/schema.toml", 'of = "point"', 'of = "list"'), "a list's 'of' is one of")
caught("a ref's set", lambda c: c.replace("Gear/schema.toml", 'set = "Folk"', 'set = "Nobody"'), "which is no set")
caught("an index on a map", lambda c: c.replace("Gear/schema.toml", 'byFrom = "from"', 'byStats = "stats"'), "cannot be indexed")
caught("a reserved index", lambda c: c.replace("Gear/schema.toml", 'byFrom = "from"', 'replaces = "from"'), "the compiler's")
caught("a schema's pack", lambda c: c.replace("Labels/schema.toml", 'pack = "Words"', 'pack = "Nowhere"'), "is not in packs.toml")
caught("a schema's about", lambda c: c.replace("Labels/schema.toml", 'about = "Made-up words keyed by a name."', ""), "'about' says")
caught("the set's folder", lambda c: c.replace("Labels/schema.toml", 'set = "Labels"', 'set = "Words"'), "the folder")
caught("a stray file in a set", lambda c: c.write("Gear/notes.txt", "x"), "no file of the set")
caught("live named twice", lambda c: c.write("Gear/Gear.forever.jsonl", ""), "live's lines are in Gear.jsonl")
caught("a stray file in the master", lambda c: c.write("readme.md", "x"), "no file of the master")
caught("a line that does not parse", lambda c: c.append(G, "{not json\n"), "does not parse")
caught("no line end", lambda c: c.append("Labels/Labels.jsonl", '{"key":"zz","since":0,"src":["hand"],"label":"Z"}'), "no line end")
caught("keys out of order", lambda c: c.replace(G, '"key":102,"since":65100,"src":["game"]', '"since":65100,"key":102,"src":["game"]'), "keys out of order")
caught("a field not in the schema", lambda c: c.replace(G, '"rare":true', '"shiny":true'), "not in the schema")
caught("a key of the wrong kind", lambda c: c.replace(G, '"key":102', '"key":"102"'), "key is no whole number")
caught("a build not known", lambda c: c.replace(G, '"since":65100,"src":["game"],"weight"', '"since":65200,"src":["game"],"weight"'), "is not in builds.toml")
caught("another game version's build", lambda c: c.replace(G, '"since":65100,"src":["game"],"weight"', '"since":66000,"src":["game"],"weight"'), "the line is in the wrong file")
caught("another game version's batch", lambda c: c.replace(G, '"src":[1,3]', '"src":[2]'), "batch: the line is in the wrong file")
caught("an unknown source", lambda c: c.replace(G, '"src":[1,3]', '"src":[9]'), "is not in sources.toml")
caught("a number written as text", lambda c: c.replace(G, '"src":[1,3]', '"src":["1"]'), "written without quotes")
caught("a source twice", lambda c: c.replace(G, '"src":[1,3]', '"src":[1,1]'), "names a source twice")
caught("a bad day", lambda c: c.replace(G, '"day":"2026-09-01"', '"day":"yesterday"'), "is no date")
caught("a tab in text", lambda c: c.replace("Folk/Folk.jsonl", "Tobin Reed", "Tobin\\tReed"), "holds a tab")
caught("an empty text", lambda c: c.replace("Folk/Folk.jsonl", '"title":"Smith"', '"title":""'), "is empty")
caught("an enum's word", lambda c: c.replace(G, '"slot":"feet"', '"slot":"legs"'), "is not one of")
caught("over a max", lambda c: c.replace(G, '"quality":3', '"quality":9'), "is over its max")
caught("a point's decimals", lambda c: c.replace("Folk/Folk.jsonl", "42.5", "42.55"), "more than one decimal")
caught("a point off the map", lambda c: c.replace("Folk/Folk.jsonl", "63.1", "163.1"), "is no point")
caught("a false bool", lambda c: c.replace(G, '"rare":true', '"rare":false'), "is not true")
caught("an empty list", lambda c: c.replace(G, '"from":[1]', '"from":[]'), "is no list")
caught("a tuple's unknown part", lambda c: c.replace(G, '"what":100', '"who":100'), "has no part")
caught("a map's int key", lambda c: c.replace(G, '"7":2', '"seven":2'), "is no whole number")
caught("a money below 0", lambda c: c.replace(G, '"sell":110', '"sell":-1'), "is no whole number from 0")
caught("lines out of order", lambda c: c.append("Folk/Folk.jsonl", '{"key":2,"since":65000,"src":["game"],"title":"Fisher"}\n'), "out of order")
caught("one build twice", lambda c: c.replace("Folk/Folk.jsonl", '"since":65100,"src":["game"],"gone":true', '"since":0,"src":["game"],"gone":true'), "a second line")
caught("null in a first version", lambda c: c.replace("Folk/Folk.jsonl", '"title":"Smith"', '"title":null'), "cleared (null) in a first version")
caught("a later version that changes nothing", lambda c: c.replace(G, '"stats":{"agi":1,"sta":3},"sell":110', '"stats":{"agi":2,"sta":3},"sell":110'), "does not change")
caught("gone with fields", lambda c: c.replace("Folk/Folk.jsonl", '"gone":true', '"gone":true,"name":"X"'), "holds nothing else")
caught("gone as false", lambda c: c.replace("Folk/Folk.jsonl", '"gone":true', '"gone":false'), "gone is true or left out")
caught("first version gone", lambda c: c.replace("Folk/Folk.jsonl", '{"key":2,"since":0,"src":[1],"name":"Tobin Reed"}', '{"key":2,"since":0,"src":[1],"gone":true}'), "cannot be gone")
caught("replaces later", lambda c: c.replace(G, '"since":65100,"src":["game"],"weight":null', '"since":65100,"src":["game"],"replaces":101,"weight":null'), "first line only")
caught("replaces itself", lambda c: c.replace(G, '"replaces":101', '"replaces":102'), "cannot replace itself")
caught("replaces nothing", lambda c: c.replace(G, '"replaces":101', '"replaces":999'), "which forever does not have")
caught("a ref to nobody", lambda c: c.replace(G, '"from":[1]', '"from":[7]'), "points at Folk 7")
caught("a beta ref live lacks", lambda c: c.replace("Gear/Gear.forever-beta.jsonl", '"quality":4', '"quality":4,"from":[3]'), "which forever-beta does not have")
caught("leaves no value", lambda c: c.replace(G, '"weight":null,"rare":true', '"name":null,"quality":null,"slot":null,"stats":null,"weight":null,"sell":null,"from":null'), "with no value")
caught("a fix of no version", lambda c: c.replace("Gear/fixes.jsonl", '"since":0', '"since":65100'), "matches no version")
caught("a fix the game overtook", lambda c: c.append(G.replace("Gear.jsonl", "fixes.jsonl"), '{"key":100,"since":0,"src":["hand"],"weight":2}\n'), "may be stale", level="warning")
caught("a fix that is no object", lambda c: c.append("Gear/fixes.jsonl", "[1]\n"), "is no object")


def split(copy):
    copy.write("Gear/Gear.101.jsonl", "")
    master = masters.Master(copy.root).load()  # keys from 101 go into the second file once written
    masters.write(master, "Gear", "forever", master.lines[("Gear", "forever")])
    text = copy.path("Gear/Gear.101.jsonl").read_text(encoding="utf-8")
    copy.write("Gear/Gear.101.jsonl", text + '{"key":50,"since":0,"src":[1],"name":"Low"}\n')


caught("a key outside its file's range", split, "outside the file's keys")
with Copy() as copy:
    copy.write("Gear/Gear.101.jsonl", "")
    master = masters.Master(copy.root).load()
    masters.write(master, "Gear", "forever", master.lines[("Gear", "forever")])
    check("split by key range", [json.loads(l)["key"] for l in copy.path("Gear/Gear.jsonl").read_text().splitlines()], [100, 100, 100])
    check("split fits", loaded(copy.root).errors, [])

# The import ---------------------------------------------------------------------------------------------


def stage(copy, *lines):
    path = Path(copy.folder) / "staging.jsonl"
    path.write_text("".join(json.dumps(line) + "\n" for line in lines), encoding="utf-8")
    return importer.read_staging(path)


def counts(report, set_name, game):
    return report.counts.get((set_name, game), {})


with Copy() as copy:
    master = loaded(copy.root)
    staged = stage(copy,
                   {"set": "Folk", "key": 4, "game": "forever", "build": 65100, "src": "game", "fields": {"name": "Wren"}},
                   {"set": "Folk", "key": 1, "game": "forever", "src": 3, "fields": {"name": "Ama Brightwater"}},
                   {"set": "Folk", "key": 2, "game": "forever", "src": "game", "fields": {"name": "Tobin Reed", "title": None}},
                   {"set": "Folk", "key": 5, "game": "forever-beta", "build": 66000, "src": "game", "fields": {"name": "Beta Wren"}},
                   {"set": "Gear", "key": 100, "game": "forever-beta", "build": 66000, "src": "game", "fields": {"quality": 2, "sell": 110}},
                   {"set": "Gear", "key": 100, "game": "forever", "build": 65100, "src": "game", "fields": {"quality": 5}},
                   {"set": "Folk", "key": 6, "game": "forever", "src": "game", "gone": True},
                   {"set": "Folk", "key": 7, "src": "game", "fields": {"name": "No Game"}},
                   {"set": "Folk", "key": 7, "game": "classic", "src": "game", "fields": {"name": "X"}},
                   {"set": "Nobody", "key": 7, "game": "forever", "src": "game", "fields": {"name": "X"}},
                   {"set": "Folk", "key": 7, "game": "forever", "src": "game", "fields": {"age": 3}},
                   {"set": "Folk", "key": 7, "game": "forever", "src": "game", "fields": {"name": ""}},
                   {"set": "Folk", "key": 7, "game": "forever", "src": 9, "fields": {"name": "X"}},
                   {"set": "Folk", "key": 7, "game": "forever", "build": 64000, "src": "game", "fields": {"name": "X"}},
                   {"set": "Folk", "key": 7, "game": "forever", "src": 2, "fields": {"name": "X"}},
                   {"set": "Folk", "key": "7", "game": "forever", "src": "game", "fields": {"name": "X"}})
    staged.append(("staging.jsonl:99", None))
    report = importer.run(master, staged)
    check("import: new and agreeing", counts(report, "Folk", "forever").get("new"), 1)
    check("import: agreeing (also a field the source says is empty)", counts(report, "Folk", "forever").get("agreeing"), 2)
    check("import: beta's new", counts(report, "Folk", "forever-beta").get("new"), 1)
    check("import: beta agrees with its view", counts(report, "Gear", "forever-beta").get("agreeing"), 1)
    check("import: the game at a build the master has, saying otherwise: a conflict", counts(report, "Gear", "forever").get("conflict"), 1)
    refused = sorted(text for case, _, _, _, text in report.listed if case == "refused")
    for words in ("cannot be gone", "names its game version", "no game version", "is no set", "not in the schema",
                  "is empty", "not in sources.toml", "not in builds.toml", "forever-beta's batch", "is no key of Folk",
                  "no JSON object"):
        check(f"import refuses: {words}", any(words in text for text in refused), True)
    check("import: the source added", master.lines[("Folk", "forever")][0].src, [1, 3])
    importer.apply(master, report)
    after = loaded(copy.root)
    check("import: the master fits after", after.errors, [])
    check("import: live's new line", '{"key":4,"since":65100,"src":["game"],"name":"Wren"}' in copy.path("Folk/Folk.jsonl").read_text(), True)
    check("import: the beta's line in its own file", '"name":"Beta Wren"' in copy.path("Folk/Folk.forever-beta.jsonl").read_text(), True)
    check("import: nothing of the beta in live's file", "Beta Wren" in copy.path("Folk/Folk.jsonl").read_text(), False)
    again = importer.run(after, staged[:5])
    check("import again: all agreeing", (counts(again, "Folk", "forever"), again.changed),
          ({"agreeing": 3}, set()))



def taken(*lines, take=False):
    """Stages lines into a fresh copy of the sample master and applies them: (report, the master read again,
    {file: [line, ...]} of the files the import wrote)."""
    with Copy() as copy:
        master = loaded(copy.root)
        report = importer.run(master, stage(copy, *lines), take=take)
        importer.apply(master, report)
        after = loaded(copy.root)
        files = {}
        for set_name, game in report.changed:
            for _, path in after.files[(set_name, game)]:
                files[str(path.relative_to(copy.root))] = [json.loads(raw) for raw in path.read_text(encoding="utf-8").splitlines()]
        return report, after, files


def of(files, name, key):
    return [line for line in files.get(name, []) if line["key"] == key]


def listed(report, case):
    return [text for each, _, _, _, text in report.listed if each == case]


GAME_LINE = {"set": "Gear", "game": "forever", "src": "game"}

# Changed: the game at a newer build, or the same build on a later day
report, after, files = taken({**GAME_LINE, "key": 101, "build": 65100, "fields": {"quality": 3}},
                             {**GAME_LINE, "key": 100, "build": 65100, "day": "2026-10-01", "fields": {"sell": 100, "name": "Plain Gloves"}})
check("import changed: counted", counts(report, "Gear", "forever"), {"changed": 2})
check("import changed: a newer build", of(files, "Gear/Gear.jsonl", 101)[-1], {"key": 101, "since": 65100, "src": ["game"], "quality": 3})
check("import changed: the same build on a later day, only what differs",
      of(files, "Gear/Gear.jsonl", 100)[-1], {"key": 100, "since": 65100, "day": "2026-10-01", "src": ["game"], "sell": 100})
check("import changed: the master fits", after.errors, [])
check("import changed: the view", after.view("Gear", "forever", fixes=False)[100][-1].fields["sell"], 100)

# Changed between two versions: the later one keeps only what it still changes, or goes
report, after, files = taken({**GAME_LINE, "key": 100, "build": 65000, "day": "2026-09-15", "fields": {"weight": None}})
check("import changed between: the later line keeps what it still changes",
      [line["since"] for line in of(files, "Gear/Gear.jsonl", 100)] + [of(files, "Gear/Gear.jsonl", 100)[-1]],
      [0, 65000, 65000, 65100, {"key": 100, "since": 65100, "src": ["game"], "rare": True}])
check("import changed between: fits", after.errors, [])
report, after, files = taken({**GAME_LINE, "key": 100, "build": 65000, "day": "2026-09-15", "fields": {"weight": None, "rare": True}})
check("import changed between: a later line that changes nothing any more goes",
      [line["since"] for line in of(files, "Gear/Gear.jsonl", 100)], [0, 65000, 65000])
check("import changed between: fits too", after.errors, [])

# Conflicts: a batch against the game, two values for one build; listed, not applied; --take mends in place
lines = ({"set": "Gear", "game": "forever", "key": 100, "build": 65100, "src": 1, "fields": {"sell": 99}},
         {**GAME_LINE, "key": 100, "build": 65000, "fields": {"sell": 98}},
         {"set": "Folk", "game": "forever", "key": 2, "src": 1, "fields": {"title": "Fisher"}},
         {"set": "Gear", "game": "forever", "key": 101, "src": 1, "fields": {"flags": None}})
report, after, files = taken(*lines)
check("import conflict: listed, nothing written", (counts(report, "Gear", "forever"), counts(report, "Folk", "forever"), files),
      ({"conflict": 3}, {"conflict": 1}, {}))
check("import conflict: says both values", any("sell: 110 in the master (65100), 99 staged" in text for text in listed(report, "conflict")), True)
check("import conflict: the game at the same build", any("98 staged" in text for text in listed(report, "conflict")), True)
report, after, files = taken(*lines, take=True)
check("import --take: taken", counts(report, "Gear", "forever"), {"taken": 3})
check("import --take: into a later version, with its source",
      of(files, "Gear/Gear.jsonl", 100)[-1], {"key": 100, "since": 65100, "src": ["game", 1], "weight": None, "rare": True, "sell": 99})
check("import --take: the same build", of(files, "Gear/Gear.jsonl", 100)[1]["sell"], 98)
check("import --take: into a first version", of(files, "Folk/Folk.jsonl", 2), [{"key": 2, "since": 0, "src": [1], "name": "Tobin Reed", "title": "Fisher"}])
check("import --take: a field cleared in a first version is left out", "flags" in of(files, "Gear/Gear.jsonl", 101)[0], False)
check("import --take: fits", after.errors, [])

# Older: put in front, the old first version keeps only what differs
report, after, files = taken({**GAME_LINE, "key": 102, "build": 65000, "fields": {"quality": 2, "sell": 5}})
check("import older: a new first version, whole, with replaces",
      of(files, "Gear/Gear.jsonl", 102), [
          {"key": 102, "since": 65000, "src": ["game"], "replaces": 101, "name": "Ünder Cap", "quality": 2, "slot": "head", "sell": 5, "from": [1]},
          {"key": 102, "since": 65100, "src": ["game"], "quality": 3, "sell": None}])
check("import older: counted, fits", (counts(report, "Gear", "forever"), after.errors), ({"older": 1}, []))
report, after, files = taken({"set": "Gear", "game": "forever", "key": 102, "build": 65000, "src": 3, "fields": {"quality": 3}})
check("import older, agreeing: the source added", (counts(report, "Gear", "forever"), of(files, "Gear/Gear.jsonl", 102)[0]["src"]),
      ({"agreeing": 1}, ["game", 3]))
report, after, files = taken({**GAME_LINE, "key": 102, "build": 65000, "gone": True})
check("import older, gone: refused", any("gone before its first version" in text for text in listed(report, "refused")), True)

# Gone: from the game or a person; from a batch refused; agreeing; an entry that comes back
report, after, files = taken({"set": "Folk", "game": "forever", "key": 2, "build": 65100, "src": "game", "gone": True},
                             {"set": "Folk", "game": "forever", "key": 1, "build": 65100, "src": 1, "gone": True},
                             {"set": "Folk", "game": "forever", "key": 3, "build": 65100, "src": "hand", "gone": True},
                             {**GAME_LINE, "key": 100, "build": 65000, "day": "2026-09-15", "gone": True})
check("import gone: counted", (counts(report, "Folk", "forever"), counts(report, "Gear", "forever")),
      ({"gone": 1, "refused": 1, "agreeing": 1}, {"conflict": 1}))
check("import gone: the line", of(files, "Folk/Folk.jsonl", 2)[-1], {"key": 2, "since": 65100, "src": ["game"], "gone": True})
check("import gone: from a batch, refused", any("missing from a source is no proof" in text for text in listed(report, "refused")), True)
check("import gone: agreeing adds the source", of(files, "Folk/Folk.jsonl", 3)[-1]["src"], ["game", "hand"])
check("import gone: not while a later version stands", any("the master has a later version" in text for text in listed(report, "conflict")), True)
check("import gone: fits", after.errors, [])
report, after, files = taken({"set": "Folk", "game": "forever", "key": 3, "build": 65100, "day": "2026-10-01", "src": "game", "fields": {"name": "Hester"}})
check("import: an entry that comes back starts whole", of(files, "Folk/Folk.jsonl", 3)[-1],
      {"key": 3, "since": 65100, "day": "2026-10-01", "src": ["game"], "name": "Hester"})
check("import: it fits", after.errors, [])

# Replaces: written into a new entry's first line; another one for a known entry is a conflict
report, after, files = taken({**GAME_LINE, "key": 104, "build": 65100, "replaces": 100, "fields": {"name": "New Gloves"}},
                             {**GAME_LINE, "key": 102, "build": 65100, "replaces": 100, "fields": {"quality": 3}},
                             {**GAME_LINE, "key": 105, "build": 65100, "replaces": 999, "fields": {"name": "X"}},
                             {**GAME_LINE, "key": 106, "build": 65100, "replaces": 106, "fields": {"name": "X"}})
check("import replaces: in the new entry's first line", of(files, "Gear/Gear.jsonl", 104),
      [{"key": 104, "since": 65100, "src": ["game"], "replaces": 100, "name": "New Gloves"}])
check("import replaces: another for a known entry is a conflict", any("replaces 100; the master names 101" in text for text in listed(report, "conflict")), True)
check("import replaces: refused when the old entry is not there, or is itself",
      (any("replaces 999, which forever does not have" in text for text in listed(report, "refused")),
       any("cannot replace itself" in text for text in listed(report, "refused"))), (True, True))
report, after, files = taken({**GAME_LINE, "key": 102, "build": 65100, "replaces": 100, "fields": {"quality": 3}}, take=True)
check("import replaces --take", (of(files, "Gear/Gear.jsonl", 102)[0]["replaces"], after.errors), (100, []))

# Each game version on its own: a beta build makes a beta version only; live is taken in first
report, after, files = taken({"set": "Folk", "game": "forever-beta", "key": 1, "build": 66000, "src": "game", "fields": {"title": "Master Smith"}},
                             {**GAME_LINE, "key": 101, "build": 65100, "fields": {"quality": 3}},
                             {"set": "Gear", "game": "forever-beta", "key": 101, "src": "game", "fields": {"quality": 3}},
                             {"set": "Gear", "game": "forever-beta", "key": 100, "build": 66000, "src": "game", "fields": {"quality": 1}},
                             {"set": "Folk", "game": "forever", "key": 1, "build": 66000, "src": "game", "fields": {"title": "X"}})
check("import beta: its own file only", (of(files, "Folk/Folk.forever-beta.jsonl", 1), "Folk/Folk.jsonl" in files),
      ([{"key": 1, "since": 66000, "src": ["game"], "title": "Master Smith"}], False))
check("import beta: stands on what the import made of live", counts(report, "Gear", "forever-beta"), {"agreeing": 1, "conflict": 1})
check("import beta: a beta build is no build of live", any("build 66000 is not in builds.toml for forever" in text for text in listed(report, "refused")), True)
check("import beta: fits", after.errors, [])
report, after, files = taken({"set": "Gear", "game": "forever-beta", "key": 101, "src": 2, "fields": {"quality": 5}}, take=True)
check("import beta --take: a correction over live's base is the beta's own line",
      (of(files, "Gear/Gear.forever-beta.jsonl", 101), after.errors), ([{"key": 101, "since": 0, "src": [2], "quality": 5}], []))

# show, diff and stats ------------------------------------------------------------------------------------
import views  # noqa: E402

shown_entry = views.show(sample, "Gear", "100")
check("show: every version with its patch, day and sources", shown_entry[1:4], [
    '  0 [1]: name "Plain Gloves", quality 1, slot "hands", stats {"agi":2,"sta":3}, weight 1.5, sell 120, from [1,2]',
    '  65000 (1.60.0) 2026-09-01 [game]: stats {"agi":1,"sta":3}, sell 110',
    "  65100 (1.60.2) [game]: weight cleared, rare true"])
check("show: the entry now", shown_entry[-1].startswith('  now: name "Plain Gloves", quality 1') and "weight" not in shown_entry[-1], True)
fixed = views.show(sample, "Gear", "101")
check("show: the line as written, then the fix", (fixed[1].startswith('  0 [1, 3]: name "Tall Boots", '), fixed[2],
                                                  fixed[3].startswith('  now: name "Tall Boots of Wading"')),
      (True, '    fixed by hand: name "Tall Boots of Wading"', True))
check("show: the beta's base", views.show(sample, "Gear", "100", "forever-beta")[1:3],
      ["  0: live's newest version, which forever-beta stands on", "  66000 (1.61.0) [game]: quality 2"])
check("show: a text key; a gone entry; none", (views.show(sample, "Labels", "with space")[1], views.show(sample, "Folk", "3")[-1],
                                              views.show(sample, "Gear", "999"), views.show(sample, "Nope", "1")[0][:18]),
      ('  0 [hand]: label "SPACED"', "  now: gone", ["Gear has no '999' in forever."], "'Nope' is no set ("))
check("diff: the newest patch", views.diff(sample, "Gear"), [
    "Gear (forever), patch 1.60.2: 2 changes.",
    '  100 65100 (1.60.2): weight 1.5 → empty; rare empty → true',
    '  102 65100 (1.60.2): new: name "Ünder Cap", quality 3, slot "head", from [1]'])
check("diff: a patch named; gone", views.diff(sample, "Folk", patch="1.60.2"), ["Folk (forever), patch 1.60.2: 1 change.", "  3 65100 (1.60.2): gone"])
check("diff: an older patch", views.diff(sample, "Gear", patch="1.60.0")[1], '  100 65000 (1.60.0) 2026-09-01: stats {"agi":2,"sta":3} → {"agi":1,"sta":3}; sell 120 → 110')
check("diff: within the beta", views.diff(sample, "Gear", "forever-beta"), ["Gear (forever-beta), patch 1.61.0: 1 change.", "  100 66000 (1.61.0): quality 1 → 2"])
check("diff: a patch not known", views.diff(sample, "Gear", patch="9.9.9"), ["No build of forever is 9.9.9 in builds.toml."])
numbers = views.stats(sample)
check("stats: per game version, set and pack", (numbers[0], numbers[2].split(), numbers[5]),
      ("forever:", ["Folk", "Gear", "3", "4", "1", "1", "4", "607", "B"], "  pack Gear: 2 sets, 6 entries, 2.1 KB"))
check("stats: the beta", [line.split()[:7] for line in numbers if line.startswith("  Gear ")][2], ["Gear", "Gear", "4", "5", "1", "0", "2"])

# Compiling ----------------------------------------------------------------------------------------------
import compile as compiler  # noqa: E402


def files_of(folder):
    return {str(path.relative_to(folder)): path.read_bytes() for path in sorted(folder.rglob("*")) if path.is_file()}


def lua_rows(path):
    """Every row of a compiled set file as Lua 5.1 reads it: [(table, key, row)], by running the file with a
    stand-in SaneUI.Core.Data.Add (characters below 32 written as \\ddd)."""
    script = r'''
local rows = {}
SaneUI = { Core = { Data = { Add = function(format, set, header)
    local S = { rows = {}, history = {}, index = {} }
    rows.S, rows.header = S, header
    return S
end } } }
dofile(arg[1])
local function show(s) return (s:gsub("[%z\1-\31\\]", function(c) return string.format("\\%03d", c:byte()) end)) end
local out = {}
for _, part in ipairs({ "rows", "history" }) do
    for key, row in pairs(rows.S[part]) do out[#out + 1] = part .. "\t" .. tostring(key) .. "\t" .. show(row) end
end
for name, index in pairs(rows.S.index) do
    for value, keys in pairs(index) do out[#out + 1] = "index." .. name .. "\t" .. tostring(value) .. "\t" .. show(keys) end
end
table.sort(out)
print(rows.header.game .. "\t" .. rows.header.hash .. "\t" .. rows.header.build)
print(table.concat(out, "\n"))
'''
    result = subprocess.run(["lua5.1", "-", str(path)], input=script, capture_output=True, text=True)
    return result.returncode, result.stdout, result.stderr


def shown(text):
    return "".join(f"\\{ord(c):03d}" if ord(c) < 32 or c == "\\" else c for c in text)


with tempfile.TemporaryDirectory(prefix="saneui-packs-") as folder:
    out = Path(folder)
    made = compiler.compile_packs(sample, out / "one", "forever")
    compiler.compile_packs(sample, out / "two", "forever")
    check("compile: the packs made", [(pack, sets) for pack, sets, _ in made], [("Gear", ["Folk", "Gear"]), ("Words", ["Labels"])])
    check("compile: the same master, the same bytes", files_of(out / "one") == files_of(out / "two"), True)
    gear_pack = out / "one" / "SaneUI_Data_Gear"
    check("compile: the pack's files", sorted(p.name for p in gear_pack.iterdir()),
          ["Folk.lua", "Gear.lua", "LICENSE.txt", "SaneUI_Data_Gear.toc"])
    toc = (gear_pack / "SaneUI_Data_Gear.toc").read_text()
    interface, version = compiler.core_toc()
    for line in (f"## Interface: {interface}", f"## Version: {version}", "## LoadOnDemand: 1", "## Dependencies: SaneUI",
                 "## Group: SaneUI", "## SavedVariables: SaneUIData_Gear", "## X-SaneUI-Sets: Folk, Gear",
                 "## X-SaneUI-Format: 1", "## X-SaneUI-Game: forever", "## Title: Data: Gear"):
        check(f"compile: TOC has {line}", line in toc.splitlines(), True)
    check("compile: TOC lists the sets' files", toc.splitlines()[-2:], ["Folk.lua", "Gear.lua"])
    gear_text = (gear_pack / "Gear.lua").read_text()
    digest = compiler.hashlib.sha256(gear_text.replace(gear_text.split('hash = "')[1][:8], "00000000", 1).encode()).hexdigest()[:8]
    check("compile: the hash is the file's", f'hash = "{digest}"' in gear_text, True)
    check("compile: live's build", 'build = 65100' in gear_text, True)
    check("compile: patch names", 'patches = { [65000] = "1.60.0", [65100] = "1.60.2" }' in gear_text, True)
    check("compile: decoder types", '"map text int", "number", "int", "int", "bool", "list int", "list point", '
          '"list tuple(kind:text,what:int,count:int,text:text)", "map int int"' in gear_text, True)
    check("compile: nothing of the beta in live's packs", any(b"Beta Ring" in data for data in files_of(out / "one").values()), False)
    code, text, problem = lua_rows(gear_pack / "Gear.lua")
    check("compile: Lua 5.1 runs the file", (code, problem), (0, ""))
    got = text.splitlines()
    view = sample.view("Gear", "forever")
    want_rows = [f"rows\t{key}\t{shown(compiler.row(sample.schemas['Gear'], versions[-1]))}" for key, versions in view.items()]
    check("compile: every row read back by Lua as written", all(line in got for line in want_rows), True)
    check("compile: a row", f"rows\t101\t{shown(compiler.row(sample.schemas['Gear'], view[101][-1]))}" in got, True)
    check("compile: the fix in the row", "Tall Boots of Wading" in text and "Tall Boots\\009" not in text, True)
    check("compile: a gone version is a build and a day", compiler.row(sample.schemas["Folk"], sample.view("Folk", "forever")[3][-1]), "65100\t")
    check("compile: history", f"history\t100\t{shown(chr(28).join(compiler.row(sample.schemas['Gear'], v) for v in view[100][:-1]))}" in got, True)
    check("compile: an index", "index.bySlot\thands\t100" in got, True)
    check("compile: an index of a list", f"index.byFrom\t1\t100{shown(chr(30))}102" in got, True)
    check("compile: replaces both ways", ("index.replaces\t102\t101" in got, "index.replacedBy\t101\t102" in got), (True, True))
    code, text, _ = lua_rows(out / "one" / "SaneUI_Data_Words" / "Labels.lua")
    check("compile: text keys", all(f"rows\t{k}\t" in text for k in ("alpha", "end", "with space")), True)
    beta = compiler.compile_packs(sample, out / "beta", "forever-beta")
    check("compile: the beta's packs", [pack for pack, _, _ in beta], ["Gear", "Words"])
    code, text, _ = lua_rows(out / "beta" / "SaneUI_Data_Gear" / "Gear.lua")
    head = text.splitlines()[0].split("\t")
    check("compile: the beta's game and build", (head[0], head[2]), ("forever-beta", "66000"))
    beta_view = sample.view("Gear", "forever-beta")
    check("compile: the beta stands on live's newest", f"history\t100\t{shown(compiler.row(sample.schemas['Gear'], beta_view[100][0]))}" in text
          and beta_view[100][0].fields["sell"] == 110, True)
    check("compile: the beta's own entry", "rows\t103\t0\\009\\009Beta Ring\\0094" in text, True)
    check("compile: no live history in the beta's pack", "\\02865000" in text or "1.60.0" in (out / "beta" / "SaneUI_Data_Gear" / "Gear.lua").read_text(), False)
    with Copy() as copy:
        copy.write("Labels/Labels.jsonl", "")
        (out / "one" / "SaneUI_Data_Old").mkdir()
        made = compiler.compile_packs(loaded(copy.root), out / "one", "forever")
        check("compile: a pack without entries is not made", [pack for pack, _, _ in made], ["Gear"])
        check("compile: packs no longer made are removed", sorted(p.name for p in (out / "one").iterdir()), ["SaneUI_Data_Gear"])
    saved, compiler.CHUNK = compiler.CHUNK, 2
    try:
        compiler.compile_packs(sample, out / "small", "forever")
        small = (out / "small" / "SaneUI_Data_Gear" / "Gear.lua").read_text()
        check("compile: rows cut into Fill functions", small.count("Fill(function()") >= 4, True)
        code, text, problem = lua_rows(out / "small" / "SaneUI_Data_Gear" / "Gear.lua")
        check("compile: cut rows read back", (code, all(line in text.splitlines() for line in want_rows)), (0, True))
    finally:
        compiler.CHUNK = saved
    for product, want in (("wowf", "forever"), ("wow_classic_beta", "forever-beta"), ("wow_unknown", None)):
        place = out / product
        place.mkdir()
        (place / ".flavor.info").write_text(f"Product Flavor!STRING:0\n{product}\n")
        check(f"compile: the game version of a {product} folder", compiler.product_game(place), want)
    check("compile: a folder without .flavor.info", compiler.product_game(out), None)

# The real master is as the game's code says (the CVar labels) -------------------------------------------
with tempfile.TemporaryDirectory(prefix="saneui-staging-") as folder:
    staging = Path(folder) / "cvar-labels.jsonl"
    result = subprocess.run([sys.executable, "-I", str(ROOT / "dev/tools/cvar-labels"), "--staging", str(staging)],
                            capture_output=True, text=True)
    check("cvar-labels stages", result.returncode, 0)
    real = loaded(masters.MASTER)
    check("the real master fits", real.errors, [])
    report = importer.run(real, importer.read_staging(staging))
    check("CVarLabels up to date with references/", (set(counts(report, "CVarLabels", "forever")), report.changed),
          ({"agreeing"}, set()))

print(f"Data tools: {'all ' if not failed else ''}{checks_run - failed} of {checks_run} checks passed.")
sys.exit(1 if failed else 0)
