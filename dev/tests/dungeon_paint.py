#!/usr/bin/env python3
"""Tests of dev/tools/dungeon-paint without ComfyUI and without the game's files: the plan's briefs (every field,
within its limits, no names), the words put together, the layout's grid, which paintings are left and in what
order, and the status line the GPU runner reads. Run by dev/tests/run."""
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

loader = importlib.machinery.SourceFileLoader("dungeon_paint", str(ROOT / "dev" / "tools" / "dungeon-paint"))
dp = importlib.util.module_from_spec(importlib.util.spec_from_loader("dungeon_paint", loader))
loader.exec_module(dp)
checks = failed = 0


def check(name, got, want):
    global checks, failed
    checks += 1
    if got != want:
        failed += 1
        print(f"FAIL {name}: got {got!r}, want {want!r}")


# --- The plan ------------------------------------------------------------------------------------

fixed, briefs = dp.plan()
LIMITS = {"setting": (8, 40), "layout": (12, 60), "colours": (4, 15), "atmosphere": (10, 40)}
check("plan: the fixed words", sorted(fixed), ["edit", "last", "levels"])
check("plan: the levels sentence counts", "{n}" in fixed["levels"], True)
sets = dp.floors_of_set()
check("plan: every instance of the set Dungeons has a brief", sorted(k for k in sets if k not in briefs), [])
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

# --- The words -----------------------------------------------------------------------------------

brief = briefs[36]
one = dp.words(fixed, brief, 1)
two = dp.words(fixed, brief, 2)
check("words: one level has no levels sentence", "levels side by side" in one, False)
check("words: two levels say so", "2 levels side by side" in two, True)
check("words: the edit first, the last sentence last", (one.startswith(fixed["edit"]), one.endswith(fixed["last"])),
      (True, True))
check("words: the setting before the levels, the layout after", two.index(brief["setting"]) < two.index("2 levels")
      < two.index(brief["layout"]), True)
check("words: the colours", f"Its colours: {brief['colours']}." in one, True)

# --- The layout ----------------------------------------------------------------------------------

floor = Image.new("RGBA", (300, 200), (200, 180, 140, 255))
floor.paste((40, 40, 40, 255), (100, 60, 200, 140))
sheet = dp.layout([floor] * 3)
check("layout: its size", sheet.size, (dp.WIDTH, dp.HEIGHT))
check("layout: the ground is the floors' paper", dp.ground_of([floor]), (200, 180, 140))
check("layout: no alpha", sheet.mode, "RGB")
dark = sheet.convert("L").resize((4, 2))
check("layout: three floors fill a 2 x 2 grid, the last cell empty", dark.getpixel((3, 1)) > dark.getpixel((1, 0)), True)

# --- What is left, and the status ----------------------------------------------------------------

with tempfile.TemporaryDirectory() as folder:
    out = Path(folder)
    check("todo: the first seed of every instance first", dp.todo(out, [1, 2], 2), [(1, 1), (2, 1), (1, 2), (2, 2)])
    Image.new("RGB", (4, 4)).save(out / "1-1.png")
    check("todo: a painting made is not made again", dp.todo(out, [1, 2], 2), [(2, 1), (1, 2), (2, 2)])
    check("levels: none without paths", dp.levels_of(36, sets, {}), 0)
    layouts = out / "layouts"
    layouts.mkdir()
    for n in (1, 2):
        Image.new("RGB", (4, 4)).save(layouts / f"2959-{n}.png")
    check("levels: given layouts count", dp.levels_of(2959, sets, {"layouts": str(layouts)}), 2)

    class Args:
        pass

    args = Args()
    args.out = str(out / "run")
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
