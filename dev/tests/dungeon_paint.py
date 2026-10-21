#!/usr/bin/env python3
"""Tests of dev/tools/dungeon-paint without ComfyUI and without the game's files: the plan's briefs (every field,
within its limits, no names, a light the Atlas' close level keeps whole), the shared levels' words, the words put
together, image 1 (the floors where they lie, parts moved together, a floor over another lifted, the paper left out),
image 2 cut from the game's pictures, the check's answers read, which paintings come next and in what order, the
run's own copy of its plan, and the status line the GPU runner reads. Run by dev/tests/run."""
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
LIMITS = {"biome": (5, 20), "buildings": (10, 50), "places": (12, 60), "mood": (8, 40), "colours": (4, 15),
          "atmosphere": (15, 55)}
check("plan: the instances' fixed words", sorted(fixed), ["far", "levels", "open", "reference", "sketch", "view"])
check("plan: an instance's middle level is seen straight from above", "straight from above" in fixed["view"], True)
check("plan: the shared middle look leaves the view to each plan", "from above" in shared["middle"]["look"], False)
check("plan: the shared levels", sorted(shared), ["far", "middle"])
check("plan: each level a look and a last sentence", [sorted(shared[level]) for level in ("far", "middle")],
      [["last", "look"], ["last", "look"]])
check("plan: the middle level is pencil on paper", "pencil" in shared["middle"]["look"], True)
check("plan: the far level is no drawing", "not a drawing" in shared["far"]["last"], True)
check("plan: a sketch gives no colours", "colours" in fixed["sketch"] and "never" in fixed["sketch"].lower(), True)
sets = dp.floors_of_set()
check("plan: every instance of the set Dungeons has a brief", sorted(k for k in sets if k not in briefs), [])
zones = __import__("tomllib").loads((ROOT / "dev" / "imagegen" / "maps" / "zones.toml").read_text())
zone = next(iter(zones.values()))
check("plan: the briefs' fields are the zone briefs'", [f for f in LIMITS if f not in zone], [])
names = {word for brief in briefs.values() for word in re.findall(r"[A-Z][a-z']+", brief["name"])}
for key, brief in briefs.items():
    check(f"plan {key}: its fields", sorted(f for f in brief if f != "sketch"), sorted(["name", "kind"] + list(LIMITS)))
    check(f"plan {key}: its kind", brief["kind"] in ("dungeon", "raid"), True)
    check(f"plan {key}: its biome reads after 'This place is'", brief["biome"][:1].islower(), True)
    for field, (low, high) in LIMITS.items():
        count = len(brief[field].split())
        check(f"plan {key}: {field} within {low} to {high} words ({count})", low <= count <= high, True)
    words = " ".join(brief[field] for field in LIMITS)
    # no name of any instance in the words (sentence starts aside: a capital after a full stop is no name)
    inner = re.findall(r"(?<![.;:] )(?<!^)\b([A-Z][a-z']+)", words)
    check(f"plan {key}: no names in the words", sorted(set(inner) & names), [])
    # the close level takes the light as the Atlas takes a zone's: its first sentence, no clause of it dropped
    first = brief["atmosphere"].split(". ")[0].rstrip(".")
    check(f"plan {key}: the Atlas keeps its light whole", at.light_of(brief["atmosphere"]), first)
check("plan: Forever's new dungeons' pictures are sketches", sorted(k for k, b in briefs.items() if b.get("sketch")),
      [2959, 2998, 2999, 3065])

# --- The words -----------------------------------------------------------------------------------

brief = briefs[36]
one = dp.words_of(fixed, shared, brief, 1)
two = dp.words_of(fixed, shared, brief, 2)
check("words: one level has no levels sentence", fixed["levels"] in one, False)
check("words: two levels say so", fixed["levels"] in two, True)
check("words: image 1 first, the far level's last sentence last",
      (one.startswith(fixed["far"]), one.endswith(shared["far"]["last"])), (True, True))
check("words: image 2 right after image 1", one.index(fixed["reference"]) == len(fixed["far"]) + 1, True)
check("words: the far level's look", shared["far"]["look"] in one, True)
check("words: what kind of place", f"This place is {brief['biome']}." in one, True)
check("words: the mood before the levels, the places after", two.index(brief["mood"]) < two.index(fixed["levels"])
      < two.index(brief["places"]), True)
check("words: the colours", f"Its colours: {brief['colours']}." in one, True)
sketched = dp.words_of(fixed, shared, briefs[2959], 2)
check("words: a sketch's own sentence", (fixed["sketch"] in sketched, fixed["reference"] in sketched), (True, False))

# --- Image 1 -------------------------------------------------------------------------------------

check("parts: near floors are one part", len(dp.parts_of([(0, 0, 10, 10), (5, 5, 15, 15), (100, 0, 110, 10)])), 2)
check("levels: a floor over another is lifted, one beside them is not",
      dp.levels_of([(0, 0, 10, 10), (0, 0, 10, 10), (2, 2, 8, 8), (20, 0, 30, 10)]), [0, 1, 2, 0])
check("levels: a large floor over two is one above the higher",
      dp.levels_of([(0, 0, 10, 10), (0, 0, 10, 10), (40, 0, 50, 10), (0, 0, 50, 10)]), [0, 1, 0, 2])
moved = dp.placed([(0, 0, 10, 10), (1000, 0, 1010, 10)])
check("placed: parts far apart moved together", moved[1][0] - moved[0][2] < 100, True)
check("placed: and kept apart", moved[1][0] > moved[0][2], True)
check("placed: one part stays where it is", dp.placed([(0, 0, 10, 10), (5, 0, 15, 10)]),
      [(0, 0, 10, 10), (5, 0, 15, 10)])
paper = Image.new("RGBA", (300, 200), (200, 180, 140, 255))
room = paper.copy()
room.paste((240, 225, 190, 255), (100, 60, 200, 140))
alpha = dp.rooms_of(room).getchannel("A")
check("rooms: a room is kept", alpha.getpixel((150, 100)), 255)
check("rooms: the paper is left out", alpha.getpixel((20, 20)), 0)
sheet = dp.far_input([(1, room, (0, 0, 300, 200)), (2, room, (0, 0, 300, 200)), (3, room, (2000, 0, 2300, 200))])
check("image 1: its size", sheet.size, (dp.WIDTH, dp.HEIGHT))
check("image 1: no alpha", sheet.mode, "RGB")
check("image 1: the game's frame is cut off", dp.frame_box(paper), (15, 20, 285, 190))

# --- Image 2 -------------------------------------------------------------------------------------

with tempfile.TemporaryDirectory() as folder:
    pictures = Path(folder)
    page = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    page.paste((90, 60, 30, 255), (10, 10, 390, 330))
    page.save(pictures / "1-lore.png")
    check("image 2: a journal painting cut to its page, its frame off", dp.reference_of(1, pictures).size,
          (round(0.93 * 380) - round(0.07 * 380), round(0.93 * 320) - round(0.12 * 320)))
    wide = Image.new("RGBA", (300, 170), (0, 0, 0, 0))
    wide.paste((50, 50, 90, 255), (0, 27, 300, 143))
    wide.save(pictures / "2-loading.png")
    check("image 2: a wide loading screen without its bands", dp.reference_of(2, pictures).size, (300, 116))
    check("image 2: none without a picture", dp.reference_of(3, pictures), None)

# --- The check -----------------------------------------------------------------------------------

passes, seen = dp.verdict('Here: {"writing": false, "map_or_drawing": false, "panels": false, "from_above": true, '
                          '"kind": "a sea cave", "is_it": true}')
check("verdict: a good painting passes", (passes, seen["kind"]), (True, "a sea cave"))
check("verdict: writing fails",
      dp.verdict('{"writing": true, "map_or_drawing": false, "panels": false, "is_it": true}')[0], False)
check("verdict: panels fail",
      dp.verdict('{"writing": false, "map_or_drawing": false, "panels": true, "is_it": true}')[0], False)
check("verdict: a view from inside fails (image 2's view copied)",
      dp.verdict('{"writing": false, "map_or_drawing": false, "panels": false, "from_above": false, "is_it": true}')[0],
      False)
check("verdict: the wrong kind of place fails",
      dp.verdict('{"writing": false, "map_or_drawing": false, "panels": false, "from_above": true, "is_it": false}')[0], False)
check("verdict: an answer that cannot be read fails", dp.verdict("no idea")[0], False)
check("look: asks about the brief's place", briefs[36]["biome"] in dp.look_words(briefs[36]), True)

# --- What comes next, the plan's copy, the status ------------------------------------------------

with tempfile.TemporaryDirectory() as folder:
    out = Path(folder)
    check("todo: the first try of every instance first", dp.todo(out, [1, 2], {}, 2, 4),
          [(1, 1), (2, 1), (1, 2), (2, 2)])
    (out / "far").mkdir()
    for seed in (1, 2):
        Image.new("RGB", (4, 4)).save(out / "far" / f"1-{seed}.png")
    marks = {"1-1": {"passes": True}, "1-2": {"passes": False}}
    check("todo: a failed painting is painted again", dp.todo(out, [1], marks, 2, 4), [(1, 3)])
    check("todo: no more than the tries", dp.todo(out, [1], marks, 2, 2), [])
    check("todo: none when enough pass", dp.todo(out, [1], {"1-1": {"passes": True}, "1-2": {"passes": True}}, 2, 4),
          [])
    check("floors: none without paths", dp.floor_numbers(36, sets, {}), [])
    layouts = out / "layouts"
    layouts.mkdir()
    for n in (2, 1):
        Image.new("RGB", (4, 4)).save(layouts / f"2959-{n}.png")
    check("floors: given layouts, in order", dp.floor_numbers(2959, sets, {"layouts": str(layouts)}), [1, 2])

    run = out / "run"
    state = {"paths": {}}
    copy = dp.plan_of(run, state)
    check("plan's copy: its files", sorted(p.name for p in copy.iterdir()),
          sorted(["dungeons.toml", "levels.toml", f"{dp.WORKFLOW}.json", f"{dp.LOOK}.json"]))
    check("plan's copy: the same as the plan", dp.fingerprint(copy), dp.fingerprint())
    with (copy / "levels.toml").open("a") as handle:
        handle.write("\n# a change of the middle level's words alone\n")
    check("plan's copy: the middle level's words do not count", dp.fingerprint(copy), dp.fingerprint())
    text = (copy / "dungeons.toml").read_text().replace(briefs[36]["mood"], "A band of pirates in a mine.")
    (copy / "dungeons.toml").write_text(text)
    check("plan's copy: a brief's change counts", dp.fingerprint(copy) != dp.fingerprint(), True)

    class Args:
        pass

    args = Args()
    args.out = str(out / "empty")
    lines = []
    real_print = print
    dp.print = lambda *parts, **_: lines.append(" ".join(str(p) for p in parts))
    dp.status(args)
    dp.print = real_print
    check("status: never 0 of 0 without inputs", lines[0].startswith(f"0 of {len(briefs) * dp.SEEDS} paintings made"),
          True)
    check("status: the runner's pattern does not match then", re.match(r"^(\d+) of \1 paintings made", lines[0]), None)

print(f"Dungeon paintings: all {checks} checks passed." if not failed
      else f"Dungeon paintings: {failed} of {checks} checks failed.")
sys.exit(1 if failed else 0)
