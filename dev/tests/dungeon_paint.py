#!/usr/bin/env python3
"""Tests of dev/tools/dungeon-paint without ComfyUI and without the game's files: the plan's briefs (every field,
within its limits, no names, a light the Atlas' close level keeps whole), the shared levels' words, the words put
together, image 1's grid, which paintings are left and in what order, the run's own copy of its plan, and the status
line the GPU runner reads. Run by dev/tests/run."""
import importlib.machinery
import importlib.util
import os
import re
import sys
import tempfile
from pathlib import Path

from PIL import Image

sys.dont_write_bytecode = True
HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
os.chdir(ROOT)


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(path))
    found = importlib.util.module_from_spec(importlib.util.spec_from_loader(name, loader))
    loader.exec_module(found)
    return found


dp = load("dungeon_paint", ROOT / "dev" / "tools" / "dungeon-paint")
at = load("atlas", ROOT / "dev" / "tools" / "atlas")
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


# --- The plan ------------------------------------------------------------------------------------

fixed, shared, briefs = dp.plan()
LIMITS = {"mood": (8, 40), "places": (12, 60), "colours": (4, 15), "atmosphere": (15, 55)}
check("plan: the instances' fixed words", sorted(fixed), ["far", "levels", "open", "view"])
check("plan: an instance's middle level is seen straight from above", "straight from above" in fixed["view"], True)
check("plan: the shared middle look leaves the view to each plan", "from above" in shared["middle"]["look"], False)
check("plan: the levels sentence counts", "{n}" in fixed["levels"], True)
check("plan: the shared levels", sorted(shared), ["far", "middle"])
check("plan: each level a look and a last sentence", [sorted(shared[level]) for level in ("far", "middle")],
      [["last", "look"], ["last", "look"]])
check("plan: the middle level is pencil on paper", "pencil" in shared["middle"]["look"], True)
check("plan: the far level is no drawing", "not a drawing" in shared["far"]["last"], True)
sets = dp.floors_of_set()
check("plan: every instance of the set Dungeons has a brief", sorted(k for k in sets if k not in briefs), [])
zones = __import__("tomllib").loads((ROOT / "dev" / "imagegen" / "maps" / "zones.toml").read_text())
check("plan: the briefs' fields are the zone briefs'", all(f in next(iter(zones.values())) for f in LIMITS), True)
names = {word for brief in briefs.values() for word in re.findall(r"[A-Z][a-z']+", brief["name"])}
for key, brief in briefs.items():
    check(f"plan {key}: its fields", sorted(brief), sorted(["name", "kind"] + list(LIMITS)))
    check(f"plan {key}: its kind", brief["kind"] in ("dungeon", "raid"), True)
    for field, (low, high) in LIMITS.items():
        count = len(brief[field].split())
        check(f"plan {key}: {field} within {low} to {high} words", low <= count <= high, True)
    words = " ".join(brief[field] for field in LIMITS)
    # no name of any instance in the words (sentence starts aside: a capital after a full stop is no name)
    inner = re.findall(r"(?<![.;:] )(?<!^)\b([A-Z][a-z']+)", words)
    check(f"plan {key}: no names in the words", sorted(set(inner) & names), [])
    # the close level takes the light as the Atlas takes a zone's: its first sentence, no clause of it dropped
    first = brief["atmosphere"].split(". ")[0].rstrip(".")
    check(f"plan {key}: the Atlas keeps its light whole", at.light_of(brief["atmosphere"]), first)

# --- The words -----------------------------------------------------------------------------------

brief = briefs[36]
one = dp.words_of(fixed, shared, brief, 1)
two = dp.words_of(fixed, shared, brief, 2)
check("words: one level has no levels sentence", "levels side by side" in one, False)
check("words: two levels say so", "2 levels side by side" in two, True)
check("words: image 1 first, the far level's last sentence last",
      (one.startswith(fixed["far"]), one.endswith(shared["far"]["last"])), (True, True))
check("words: the far level's look", shared["far"]["look"] in one, True)
check("words: the mood before the levels, the places after", two.index(brief["mood"]) < two.index("2 levels")
      < two.index(brief["places"]), True)
check("words: the colours", f"Its colours: {brief['colours']}." in one, True)

# --- Image 1 -------------------------------------------------------------------------------------

floor = Image.new("RGBA", (300, 200), (200, 180, 140, 255))
floor.paste((40, 40, 40, 255), (100, 60, 200, 140))
sheet = dp.far_input([(n, floor, True) for n in (1, 2, 3)])
check("image 1: its size", sheet.size, (dp.WIDTH, dp.HEIGHT))
check("image 1: no alpha", sheet.mode, "RGB")
check("image 1: the ground is the floors' paper", dp.ground_of([floor]), (200, 180, 140))
dark = sheet.convert("L").resize((4, 2))
check("image 1: three floors fill a 2 x 2 grid, the last cell empty", dark.getpixel((3, 1)) > dark.getpixel((1, 0)),
      True)
check("image 1: the game's frame is cut off", dp.frame_box(floor), (15, 20, 285, 190))

# --- What is left, the plan's copy, the status ---------------------------------------------------

with tempfile.TemporaryDirectory() as folder:
    out = Path(folder)
    check("todo: the first seed of every instance first", dp.todo(out, [1, 2], 2), [(1, 1), (2, 1), (1, 2), (2, 2)])
    (out / "far").mkdir()
    Image.new("RGB", (4, 4)).save(out / "far" / "1-1.png")
    check("todo: a painting made is not made again", dp.todo(out, [1, 2], 2), [(2, 1), (1, 2), (2, 2)])
    check("floors: none without paths", dp.floor_numbers(36, sets, {}), [])
    layouts = out / "layouts"
    layouts.mkdir()
    for n in (2, 1):
        Image.new("RGB", (4, 4)).save(layouts / f"2959-{n}.png")
    check("floors: given layouts, in order", dp.floor_numbers(2959, sets, {"layouts": str(layouts)}), [1, 2])

    run = out / "run"
    state = {"paths": {}}
    copy = dp.plan_of(run, state)
    check("plan's copy: its files", sorted(p.name for p in copy.iterdir()), ["dungeons.toml", "levels.toml",
                                                                             "workflow.json"])
    check("plan's copy: the same as the plan", dp.fingerprint(copy), dp.fingerprint())
    with (copy / "levels.toml").open("a") as handle:
        handle.write("\n# a change of the middle level's words alone\n")
    check("plan's copy: the middle level's words do not count", dp.fingerprint(copy), dp.fingerprint())
    text = (copy / "dungeons.toml").read_text().replace("A gang of pirates", "A band of pirates")
    (copy / "dungeons.toml").write_text(text)
    check("plan's copy: a brief's change counts", dp.fingerprint(copy) != dp.fingerprint(), True)
    check("plan's copy: read as the plan", dp.plan(copy)[2].keys() == briefs.keys(), True)

    class Args:
        pass

    args = Args()
    args.out = str(out / "empty")
    lines = []
    real_print = print
    dp.print = lambda *parts, **_: lines.append(" ".join(str(p) for p in parts))
    dp.status(args)
    dp.print = real_print
    check("status: never 0 of 0 without inputs", lines[0].startswith(f"0 of {len(briefs) * dp.SEEDS} paintings made"), True)
    check("status: the runner's pattern does not match then", re.match(r"^(\d+) of \1 paintings made", lines[0]), None)

print(f"Dungeon paintings: all {checks} checks passed." if not failed
      else f"Dungeon paintings: {failed} of {checks} checks failed.")
sys.exit(1 if failed else 0)
