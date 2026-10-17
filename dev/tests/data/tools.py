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
check("current before a day", masters.current(gear[100], 65000).since, 0)
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
    check("import: a change waits for 1a.6", counts(report, "Gear", "forever").get("later"), 1)
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
